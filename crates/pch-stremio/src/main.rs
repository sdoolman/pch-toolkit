mod media;
mod streamer;
mod stremio;

use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::thread;

use streamer::RangeStreamer;
use stremio::StremioHandler;

const PORT: u16 = 7001;

fn main() {
    let bind_addr = format!("0.0.0.0:{}", PORT);
    let listener = match TcpListener::bind(&bind_addr) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("[!] Failed to bind pch-stremio on {}: {}", bind_addr, e);
            std::process::exit(1);
        }
    };

    println!("[*] Popcorn Hour Stremio Direct-Play Server running on port {}", PORT);

    for stream in listener.incoming() {
        if let Ok(mut stream) = stream {
            thread::spawn(move || {
                handle_client(&mut stream);
            });
        }
    }
}

fn handle_client(stream: &mut TcpStream) {
    let mut buf = [0u8; 4096];
    let n = match stream.read(&mut buf) {
        Ok(n) if n > 0 => n,
        _ => return,
    };

    let req_str = String::from_utf8_lossy(&buf[..n]);
    let mut lines = req_str.lines();
    let req_line = match lines.next() {
        Some(l) => l,
        None => return,
    };

    let parts: Vec<&str> = req_line.split_whitespace().collect();
    if parts.len() < 2 {
        return;
    }

    let method = parts[0];
    let path = parts[1];

    if method == "OPTIONS" {
        send_cors_preflight(stream);
        return;
    }

    let mut range_start = 0u64;
    let mut range_end = None;
    let mut is_range = false;

    for line in lines {
        if line.to_lowercase().starts_with("range: bytes=") {
            is_range = true;
            let val = &line[13..].trim();
            let rparts: Vec<&str> = val.split('-').collect();
            if let Ok(s) = rparts[0].parse::<u64>() {
                range_start = s;
            }
            if rparts.len() > 1 && !rparts[1].is_empty() {
                if let Ok(e) = rparts[1].parse::<u64>() {
                    range_end = Some(e);
                }
            }
        }
    }

    if path == "/" || path == "/manifest.json" {
        StremioHandler::handle_manifest(stream);
        return;
    }

    if path.starts_with("/catalog/") {
        StremioHandler::handle_catalog(path, stream);
        return;
    }

    if path.starts_with("/meta/") {
        StremioHandler::handle_meta(path, stream);
        return;
    }

    if path.starts_with("/stream/") {
        StremioHandler::handle_stream(path, stream);
        return;
    }

    if path.starts_with("/videos/") {
        RangeStreamer::handle_video_stream(path, range_start, range_end, is_range, stream);
        return;
    }

    let _ = stream.write_all(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
}

fn send_cors_preflight(stream: &mut TcpStream) {
    let resp = "HTTP/1.1 204 No Content\r\n\
                Access-Control-Allow-Origin: *\r\n\
                Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n\
                Access-Control-Allow-Headers: Content-Type, Range\r\n\
                Access-Control-Allow-Private-Network: true\r\n\
                Access-Control-Max-Age: 86400\r\n\
                Connection: close\r\n\r\n";
    let _ = stream.write_all(resp.as_bytes());
}
