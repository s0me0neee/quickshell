// Ranks launcher candidates, and nothing else.
//
// The shell owns the data: Quickshell already parses desktop entries properly (icons,
// actions, execute()), so QML sends the corpus over once when the launcher opens and a
// query per keystroke. This just scores and hands back ids, best first.
//
// One process for the life of the launcher window, not one per keystroke. JSON lines
// both ways, because app names contain every separator a tab-delimited format would pick.
//
//   in   {"set":[{"id":"firefox.desktop","text":"Firefox  web browser"}, ...]}
//   in   {"q":"fire","limit":40}
//   out  {"ids":["firefox.desktop", ...]}

use std::io::{self, BufRead, Write};

use nucleo_matcher::pattern::{CaseMatching, Normalization, Pattern};
use nucleo_matcher::{Config, Matcher, Utf32Str};
use serde_json::{json, Value};

struct Item {
    id: String,
    text: String,
}

fn main() {
    let stdin = io::stdin();
    let mut out = io::stdout();
    let mut matcher = Matcher::new(Config::DEFAULT);
    let mut items: Vec<Item> = Vec::new();

    for line in stdin.lock().lines() {
        let Ok(line) = line else { break };
        let Ok(msg) = serde_json::from_str::<Value>(&line) else { continue };

        if let Some(set) = msg.get("set").and_then(Value::as_array) {
            items = set.iter().filter_map(read_item).collect();
            continue;
        }

        let Some(query) = msg.get("q").and_then(Value::as_str) else { continue };
        let limit = msg.get("limit").and_then(Value::as_u64).unwrap_or(40) as usize;

        let ids = rank(&mut matcher, &items, query, limit);
        if writeln!(out, "{}", json!({ "ids": ids })).is_err() {
            break;
        }
        // The shell is waiting on this line to draw the next frame, so don't sit in the
        // buffer until the next write fills it
        let _ = out.flush();
    }
}

fn read_item(value: &Value) -> Option<Item> {
    Some(Item {
        id: value.get("id")?.as_str()?.to_owned(),
        text: value.get("text")?.as_str()?.to_owned(),
    })
}

fn rank(matcher: &mut Matcher, items: &[Item], query: &str, limit: usize) -> Vec<String> {
    // An empty query isn't a match of everything — it's "no opinion". The caller
    // already sorted the corpus the way it wants to show it, so hand that back.
    if query.trim().is_empty() {
        return items.iter().take(limit).map(|i| i.id.clone()).collect();
    }

    let pattern = Pattern::parse(query, CaseMatching::Ignore, Normalization::Smart);
    let mut buf = Vec::new();
    let mut scored: Vec<(u32, usize)> = Vec::with_capacity(items.len());

    for (idx, item) in items.iter().enumerate() {
        let haystack = Utf32Str::new(&item.text, &mut buf);
        if let Some(score) = pattern.score(haystack, matcher) {
            scored.push((score, idx));
        }
    }

    // Best score first; ties keep the caller's order, so equally good matches stay in
    // whatever order it considered meaningful rather than shuffling between keystrokes
    scored.sort_by(|a, b| b.0.cmp(&a.0).then(a.1.cmp(&b.1)));
    scored
        .into_iter()
        .take(limit)
        .map(|(_, idx)| items[idx].id.clone())
        .collect()
}
