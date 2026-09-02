use std::fs;
use std::path::Path;

pub const MEDIA_ROOT: &str = "/share";

#[derive(Debug, Clone)]
pub struct MediaEpisode {
    pub show_title: String,
    pub season: u32,
    pub episode: u32,
    pub filename: String,
    pub rel_path: String,
    pub stream_id: String,
}

pub struct MediaScanner;

impl MediaScanner {
    pub fn scan_tv_shows() -> Vec<MediaEpisode> {
        let mut episodes = Vec::new();
        let tv_root = format!("{}/TV Shows", MEDIA_ROOT);
        let path = Path::new(&tv_root);

        if !path.exists() || !path.is_dir() {
            return episodes;
        }

        if let Ok(shows) = fs::read_dir(path) {
            for show_entry in shows.flatten() {
                if let Ok(ft) = show_entry.file_type() {
                    if ft.is_dir() {
                        let show_name = show_entry.file_name().to_string_lossy().to_string();
                        Self::scan_show_seasons(&show_entry.path(), &show_name, &mut episodes);
                    }
                }
            }
        }
        episodes
    }

    fn scan_show_seasons(show_dir: &Path, show_name: &str, out: &mut Vec<MediaEpisode>) {
        if let Ok(entries) = fs::read_dir(show_dir) {
            for entry in entries.flatten() {
                let p = entry.path();
                if p.is_dir() {
                    let season_name = entry.file_name().to_string_lossy().to_string();
                    let season_num = Self::parse_season_num(&season_name);
                    Self::scan_season_episodes(&p, show_name, season_num, &season_name, out);
                }
            }
        }
    }

    fn scan_season_episodes(season_dir: &Path, show_name: &str, season_num: u32, season_dir_name: &str, out: &mut Vec<MediaEpisode>) {
        if let Ok(files) = fs::read_dir(season_dir) {
            for file_entry in files.flatten() {
                let p = file_entry.path();
                if p.is_file() {
                    let fname = file_entry.file_name().to_string_lossy().to_string();
                    if fname.ends_with(".mkv") || fname.ends_with(".mp4") || fname.ends_with(".avi") {
                        let ep_num = Self::parse_episode_num(&fname);
                        let rel_path = format!("TV Shows/{}/{}/{}", show_name, season_dir_name, fname);
                        let stream_id = format!("tt7772588:{}:{}", season_num, ep_num);

                        out.push(MediaEpisode {
                            show_title: show_name.to_string(),
                            season: season_num,
                            episode: ep_num,
                            filename: fname,
                            rel_path,
                            stream_id,
                        });
                    }
                }
            }
        }
    }

    fn parse_season_num(name: &str) -> u32 {
        let name_lower = name.to_lowercase();
        if let Some(pos) = name_lower.find("season") {
            let num_part = &name_lower[pos + 6..].trim();
            if let Ok(n) = num_part.split_whitespace().next().unwrap_or("1").parse::<u32>() {
                return n;
            }
        }
        1
    }

    fn parse_episode_num(name: &str) -> u32 {
        let upper = name.to_uppercase();
        if let Some(pos) = upper.find('E') {
            let after = &upper[pos + 1..];
            let digits: String = after.chars().take_while(|c| c.is_ascii_digit()).collect();
            if let Ok(n) = digits.parse::<u32>() {
                return n;
            }
        }
        1
    }
}
