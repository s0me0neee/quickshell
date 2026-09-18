//! Prints one JSON forecast on stdout, then exits.
//!
//! Adapted from `deskdock-weather`, which does the same NOAA walk but hands the
//! result to the dock firmware over protobuf. This one drops that, and the
//! generated NOAA client with it: the whole exchange is three GETs and some
//! serde_json, so a client crate would be a lot of build for one field.
//!
//! The shell runs this on a long timer and caches the last good answer, so
//! failing is cheap — say so in the JSON and let the bar keep what it has.

use std::time::Duration;

use chrono::{DateTime, Local};
use serde_json::{Value, json};

/// NOAA asks for a User-Agent naming the app *and a way to reach whoever runs
/// it*; generic ones are the first they throttle. The contact half is nobody's
/// to invent, so it comes from the environment.
const CONTACT_VAR: &str = "QS_WEATHER_CONTACT";

/// Skips the geolocation lookup. Wanted whenever the public IP is somewhere the
/// body isn't — a VPN exit, mostly. Format: `37.77,-122.42`.
const LATLON_VAR: &str = "QS_WEATHER_LATLON";

/// How many hours of the forecast to hand over. The card shows a handful; the
/// rest is weight in a file the shell re-reads.
const HOURS: usize = 12;

struct Place {
    city: String,
    latitude: f64,
    longitude: f64,
}

fn main() {
    let json = match run() {
        Ok(value) => value,
        Err(e) => json!({ "ok": false, "error": e.to_string() }),
    };
    println!("{json}");
}

fn run() -> Result<Value, Box<dyn std::error::Error>> {
    let client = reqwest::blocking::Client::builder()
        .user_agent(user_agent())
        .timeout(Duration::from_secs(20))
        .build()?;

    let place = locate(&client)?;
    let point = point(&client, &place)?;
    // NOAA's own name for the point, not the IP database's: the latter reports
    // whatever coarse range the ISP registered ("The Bronx" for an address
    // elsewhere, most famously), and only NOAA's label is guaranteed
    // to describe the grid the forecast actually is for.
    let city = match noaa_name(&point) {
        name if !name.is_empty() => name,
        _ => place.city,
    };
    let hourly_url = forecast_url(&point)?;
    let forecast: Value = client.get(&hourly_url).send()?.error_for_status()?.json()?;

    let periods = forecast["properties"]["periods"]
        .as_array()
        .ok_or("forecast had no periods")?;

    let hours: Vec<Value> = periods.iter().map(hour).collect::<Result<_, _>>()?;

    // The period covering the wall clock now, not `periods[0]`: a forecast held
    // across an hour boundary, or a clock that disagrees with NOAA's, both make
    // the first period the past. Falls back to the first when all are ahead.
    let now = Local::now();
    let current = hours
        .iter()
        .take_while(|h| started(h).is_some_and(|t| t <= now))
        .last()
        .or_else(|| hours.first())
        .ok_or("forecast was empty")?;

    Ok(json!({
        "ok": true,
        "city": city,
        "updated": Local::now().to_rfc3339(),
        "now": current,
        "hourly": hours.iter().take(HOURS).collect::<Vec<_>>(),
    }))
}

fn user_agent() -> String {
    let name = concat!("qs-weather/", env!("CARGO_PKG_VERSION"));
    match std::env::var(CONTACT_VAR).ok().as_deref().map(str::trim) {
        Some(contact) if !contact.is_empty() => format!("{name} ({contact})"),
        _ => name.to_string(),
    }
}

/// Where the forecast is for: the override if there is one, else whatever the
/// public IP looks like from outside.
fn locate(client: &reqwest::blocking::Client) -> Result<Place, Box<dyn std::error::Error>> {
    if let Ok(raw) = std::env::var(LATLON_VAR) {
        let (lat, lon) = raw.split_once(',').ok_or("QS_WEATHER_LATLON wants lat,lon")?;
        return Ok(Place {
            city: String::new(),
            latitude: lat.trim().parse()?,
            longitude: lon.trim().parse()?,
        });
    }

    // ip-api is IPv4-only, so letting it read our address gets the IPv4 one, which the
    // ISP files under the Bronx. The IPv6 address places correctly, so ask for it
    // (api64 falls back to IPv4 without v6) and hand it over, as deskdock does
    let ip = client
        .get("https://api64.ipify.org")
        .send()?
        .error_for_status()?
        .text()?;
    let geo: Value = client
        .get(format!(
            "http://ip-api.com/json/{}?fields=status,message,country,city,lat,lon",
            ip.trim()
        ))
        .send()?
        .error_for_status()?
        .json()?;

    if geo["status"] != "success" {
        return Err(format!("could not place this machine: {}", geo["message"]).into());
    }
    if geo["country"] != "United States" {
        return Err("NOAA only forecasts the United States".into());
    }

    Ok(Place {
        city: geo["city"].as_str().unwrap_or_default().to_string(),
        latitude: geo["lat"].as_f64().ok_or("no latitude")?,
        longitude: geo["lon"].as_f64().ok_or("no longitude")?,
    })
}

/// NOAA resolves a coordinate to a grid square first, and only that square knows
/// its own forecast URL.
fn point(
    client: &reqwest::blocking::Client,
    place: &Place,
) -> Result<Value, Box<dyn std::error::Error>> {
    let url = format!(
        "https://api.weather.gov/points/{:.4},{:.4}",
        place.latitude, place.longitude
    );
    Ok(client.get(&url).send()?.error_for_status()?.json()?)
}

fn forecast_url(point: &Value) -> Result<String, Box<dyn std::error::Error>> {
    point["properties"]["forecastHourly"]
        .as_str()
        .map(String::from)
        .ok_or_else(|| "NOAA gave no hourly forecast for this point".into())
}

/// NOAA's `relativeLocation`: the city it files the point under, e.g.
/// "New York, NY". Empty wherever NOAA has no name for the place.
fn noaa_name(point: &Value) -> String {
    let rel = &point["properties"]["relativeLocation"]["properties"];
    let city = rel["city"].as_str().unwrap_or_default();
    let state = rel["state"].as_str().unwrap_or_default();
    if city.is_empty() {
        String::new()
    } else if state.is_empty() {
        city.to_string()
    } else {
        format!("{city}, {state}")
    }
}

fn hour(period: &Value) -> Result<Value, Box<dyn std::error::Error>> {
    Ok(json!({
        "time": period["startTime"].as_str().ok_or("period had no startTime")?,
        "temperature": period["temperature"].as_f64().ok_or("period had no temperature")?,
        "unit": period["temperatureUnit"].as_str().unwrap_or("F"),
        "short": period["shortForecast"].as_str().unwrap_or_default(),
        "condition": condition(period["icon"].as_str().unwrap_or_default()),
        "humidity": period["relativeHumidity"]["value"].as_f64().unwrap_or(0.0),
        // NOAA sends null whenever there is no chance of rain, which is most
        // periods most of the time. That means zero, not a broken forecast
        "precipitation": period["probabilityOfPrecipitation"]["value"].as_f64().unwrap_or(0.0),
        "wind": wind_speed(period["windSpeed"].as_str().unwrap_or_default()),
        "windDirection": period["windDirection"].as_str().unwrap_or_default(),
    }))
}

fn started(hour: &Value) -> Option<DateTime<Local>> {
    hour["time"].as_str()?.parse::<DateTime<Local>>().ok()
}

/// NOAA's icon field is a URL like `.../icons/land/day/rain_showers,40?size=small`.
/// The shell draws its own glyphs, so all that is wanted is `day/rain_showers`.
fn condition(icon: &str) -> String {
    let path = icon.split('?').next().unwrap_or_default();
    let mut parts = path.rsplit('/');
    let Some(last) = parts.next() else {
        return String::new();
    };
    // A period can be split between two conditions, e.g. `.../rain,40/snow,60`
    let name = last.split(',').next().unwrap_or_default();
    match parts.next() {
        Some(when @ ("day" | "night")) => format!("{when}/{name}"),
        _ => name.to_string(),
    }
}

/// `windSpeed` is prose, not data: `"6 mph"` most of the time, `"8 to 12 mph"`
/// wherever the grid straddles a gradient. The last number is the upper bound,
/// which is the one you would feel.
fn wind_speed(raw: &str) -> f64 {
    raw.split_whitespace()
        .rev()
        .find_map(|w| w.parse::<f64>().ok())
        .unwrap_or(0.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_a_ranged_wind_speed() {
        assert_eq!(wind_speed("6 mph"), 6.0);
        assert_eq!(wind_speed("8 to 12 mph"), 12.0);
        assert_eq!(wind_speed(""), 0.0);
    }

    #[test]
    fn reads_noaa_s_place_name() {
        let point = json!({
            "properties": {
                "relativeLocation": {
                    "properties": { "city": "New York", "state": "NY" }
                }
            }
        });
        assert_eq!(noaa_name(&point), "New York, NY");

        let no_state = json!({
            "properties": {
                "relativeLocation": { "properties": { "city": "Somewhere" } }
            }
        });
        assert_eq!(noaa_name(&no_state), "Somewhere");

        assert_eq!(noaa_name(&json!({})), "");
    }

    #[test]
    fn strips_the_icon_url_to_a_condition() {
        assert_eq!(
            condition("https://api.weather.gov/icons/land/day/skc?size=small"),
            "day/skc"
        );
        assert_eq!(
            condition("https://api.weather.gov/icons/land/night/rain_showers,40?size=medium"),
            "night/rain_showers"
        );
        assert_eq!(condition(""), "");
    }
}
