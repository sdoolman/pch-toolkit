use std::fs::File;
use std::io::{Read, Seek, SeekFrom, Write};
use std::net::TcpStream;
use crate::media::MEDIA_ROOT;

pub struct RangeStreamer;

impl RangeStreamer {
    pub fn handle_video_stream(path: &str, range_start: u64, range_end: Option<u64>, is_range: bool, stream: &mut TcpStream) {
        let raw_path = &path[8..];
        let decoded_path = raw_path.replace("%20", " ");
        let full_path = format!("{}/{}", MEDIA_ROOT, decoded_path);

        let mut file = match File::open(&full_path) {
            Ok(f) => f,
            Err(_) => {
                let _ = stream.write_all(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
                return;
            }
        };

        let file_size = match file.metadata() {
            Ok(m) => m.len(),
            Err(_) => return,
        };

        let end = match range_end {
            Some(e) if e < file_size => e,
            _ => file_size - 1,
        };

        let chunk_len = end.saturating_sub(range_start) + 1;

        let hdr = if is_range {
            format!(
                "HTTP/1.1 206 Partial Content\r\n\
                 Content-Type: video/x-matroska\r\n\
                 Accept-Ranges: bytes\r\n\
                 Access-Control-Allow-Origin: *\r\n\
                 Access-Control-Allow-Private-Network: true\r\n\
                 Content-Range: bytes {}-{}/{}\r\n\
                 Content-Length: {}\r\n\
                 Connection: close\r\n\r\n",
                range_start, end, file_size, chunk_len
            )
        } else {
            format!(
                "HTTP/1.1 200 OK\r\n\
                 Content-Type: video/x-matroska\r\n\
                 Accept-Ranges: bytes\r\n\
                 Access-Control-Allow-Origin: *\r\n\
                 Access-Control-Allow-Private-Network: true\r\n\
                 Content-Length: {}\r\n\
                 Connection: close\r\n\r\n",
                file_size
            )
        };

        let _ = stream.write_all(hdr.as_bytes());

        if file.seek(SeekFrom::Start(range_start)).is_ok() {
            let mut left = chunk_len;
            let mut buf = [0u8; 64 * 1024];
            while left > 0 {
                let to_read = (left as usize).min(buf.len());
                match file.read(&mut buf[..to_read]) {
                    Ok(0) => break,
                    Ok(r) => {
                        if stream.write_all(&buf[..r]).is_err() {
                            break;
                        }
                        left -= r as u64;
                    }
                    Err(_) => break,
                }
            }
        }
    }
}
