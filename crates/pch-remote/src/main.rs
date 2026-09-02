use std::fs;
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::thread;

const PORT: u16 = 7000;

fn main() {
    let bind_addr = format!("0.0.0.0:{}", PORT);
    let listener = match TcpListener::bind(&bind_addr) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("[!] Failed to bind pch-remote on {}: {}", bind_addr, e);
            std::process::exit(1);
        }
    };

    println!("[*] Popcorn Hour Web Remote Daemon running on port {}", PORT);

    for stream in listener.incoming() {
        if let Ok(mut stream) = stream {
            thread::spawn(move || {
                handle_client(&mut stream);
            });
        }
    }
}

fn handle_client(stream: &mut TcpStream) {
    let mut buf = [0u8; 2048];
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

    // Key Forwarding Relay API
    if path.starts_with("/api/key") {
        if let Some(pos) = path.find("key=") {
            let key = &path[pos + 4..];
            let key = key.split('&').next().unwrap_or("enter");
            forward_key_to_syb(key);
        }
        send_json(stream, "{\"status\":\"ok\"}");
        return;
    }

    // Serve Web Remote HTML
    if path == "/" || path == "/remote" || path == "/controller" || path == "/remote_controller" || path == "/remote.html" {
        serve_remote_html(stream);
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

fn send_json(stream: &mut TcpStream, body: &str) {
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

fn serve_remote_html(stream: &mut TcpStream) {
    let local_file = "/share/remote.html";
    if let Ok(content) = fs::read(local_file) {
        let hdr = format!(
            "HTTP/1.1 200 OK\r\n\
             Content-Type: text/html; charset=utf-8\r\n\
             Access-Control-Allow-Origin: *\r\n\
             Access-Control-Allow-Private-Network: true\r\n\
             Content-Length: {}\r\n\
             Connection: close\r\n\r\n",
            content.len()
        );
        let _ = stream.write_all(hdr.as_bytes());
        let _ = stream.write_all(&content);
    } else {
        let body = "<h1>Popcorn Hour Web Remote</h1><p>remote.html not found on /share</p>";
        let hdr = format!(
            "HTTP/1.1 200 OK\r\n\
             Content-Type: text/html; charset=utf-8\r\n\
             Content-Length: {}\r\n\
             Connection: close\r\n\r\n{}",
            body.len(),
            body
        );
        let _ = stream.write_all(hdr.as_bytes());
    }
}

fn forward_key_to_syb(key: &str) {
    if let Ok(mut syb) = TcpStream::connect("127.0.0.1:8008") {
        let req = format!(
            "GET /system?arg0=send_key&arg1={} HTTP/1.0\r\nHost: 127.0.0.1:8008\r\nConnection: close\r\n\r\n",
            key
        );
        let _ = syb.write_all(req.as_bytes());
    }
}
