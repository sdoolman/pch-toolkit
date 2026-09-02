use std::io::Write;
use std::net::TcpStream;
use crate::media::MediaScanner;

pub fn send_json(stream: &mut TcpStream, body: &str) {
    let resp = format!(
        "HTTP/1.1 200 OK\r\n\
         Content-Type: application/json; charset=utf-8\r\n\
         Access-Control-Allow-Origin: *\r\n\
         Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n\
         Access-Control-Allow-Private-Network: true\r\n\
         Content-Length: {}\r\n\
         Connection: close\r\n\r\n{}",
        body.len(),
        body
    );
    let _ = stream.write_all(resp.as_bytes());
}

pub struct StremioHandler;

impl StremioHandler {
    pub fn handle_manifest(stream: &mut TcpStream) {
        let manifest = r#"{
            "id": "org.pch.stremio.local",
            "name": "Popcorn Hour Storage",
            "version": "1.0.0",
            "description": "Direct Play local streaming from Popcorn Hour storage",
            "resources": ["catalog", "stream", "meta"],
            "types": ["series", "movie"],
            "catalogs": [
                {"type": "series", "id": "pch_series", "name": "Popcorn Hour TV Shows"},
                {"type": "movie", "id": "pch_movies", "name": "Popcorn Hour Movies"}
            ],
            "idPrefixes": ["tt", "pch_"]
        }"#;
        send_json(stream, manifest);
    }

    pub fn handle_catalog(path: &str, stream: &mut TcpStream) {
        if path.starts_with("/catalog/series/") {
            let catalog = r#"{"metas":[{"id":"tt7772588","type":"series","name":"For All Mankind","poster":"https://images.metahub.space/poster/medium/tt7772588/img","posterShape":"poster"}]}"#;
            send_json(stream, catalog);
        } else {
            send_json(stream, "{\"metas\":[]}");
        }
    }

    pub fn handle_meta(path: &str, stream: &mut TcpStream) {
        let episodes = MediaScanner::scan_tv_shows();
        let mut videos_json = String::new();

        for (i, ep) in episodes.iter().enumerate() {
            if i > 0 {
                videos_json.push(',');
            }
            videos_json.push_str(&format!(
                r#"{{"id":"{}","title":"Episode {}","season":{},"episode":{},"released":"2020-01-01T00:00:00.000Z"}}"#,
                ep.stream_id, ep.episode, ep.season, ep.episode
            ));
        }

        let meta = format!(
            r#"{{"meta":{{"id":"tt7772588","type":"series","name":"For All Mankind","poster":"https://images.metahub.space/poster/medium/tt7772588/img","posterShape":"poster","videos":[{}]}}}}"#,
            videos_json
        );
        send_json(stream, &meta);
    }

    pub fn handle_stream(path: &str, stream: &mut TcpStream) {
        let episodes = MediaScanner::scan_tv_shows();
        let sid = path.split('/').last().unwrap_or("").replace(".json", "");
        let mut stream_json = String::new();

        for ep in &episodes {
            if ep.stream_id == sid {
                let stream_url = format!(
                    "http://192.168.1.4:7001/videos/{}",
                    ep.rel_path.replace(' ', "%20")
                );
                stream_json = format!(
                    r#"{{"streams":[{{"title":"⚡ Popcorn Hour Direct Play (1080p)\n{}","url":"{}"}}]}}"#,
                    ep.filename, stream_url
                );
                break;
            }
        }

        if stream_json.is_empty() {
            stream_json = "{\"streams\":[]}".to_string();
        }

        send_json(stream, &stream_json);
    }
}
