# 🍿 Popcorn Hour Toolkit (`pch-toolkit`)

> Bring your old Popcorn Hour back to life with a modern phone remote, secure SSH, and lightweight essentials.  
> Works on **Popcorn Hour A-200, A-210, C-200, and C-300**.

---

## 🌟 Why this project?

Got an old Popcorn Hour gathering dust in a drawer?

These classic media players still have great video hardware that plays 1080p movies smoothly. However, the original 2009 software has some common frustrations today:
* 📱 **Lost or broken physical remote?** Replacement remotes are hard to find or expensive.
* 🔒 **Outdated security:** The box only has insecure telnet from 2009.
* 🐢 **Heavy background services:** Legacy transmission and samba daemons eat up the box's limited RAM.

**`pch-toolkit` modernizes your player with a complete suite of lightweight, statically linked tools:**

| Tool | What it does | Size |
| :--- | :--- | :--- |
| **📱 `pch_remote`** | Lightweight **Web Remote Daemon** (port 7000) written in memory-safe Rust. | ~490 KB |
| **🔑 `dropbear`** | Modern **SSH server** with key login and 1-hour automatic idle logout. | ~450 KB |
| **🧰 `busybox`** | Modern **core utilities** (`wget`, `tar`, `top`, `grep`, `nc`, `tree`, `awk`, etc.). | ~1.8 MB |
| **🌐 `curl`** | Modern **HTTP client** for fetching scripts, files, and triggering webhooks. | ~950 KB |
| **📝 `nano`** | Friendly **terminal text editor** (no need to wrestle with ancient vi). | ~700 KB |
| **🐍 `python`** | Standalone **MicroPython 3 runtime** for automation scripts. | ~315 KB |
| **🎬 `pch_stremio`** | *(Optional)* Direct-Play **Stremio v3 streaming server** (port 7001). | ~510 KB |

---

## 🚀 Quickstart: Revive your Popcorn Hour in 1 Minute

You do not need to open the device or solder any cables. As long as your Popcorn Hour is connected to your home network (via Ethernet or Wi-Fi), pick whichever method you prefer:

---

### Option 1: 1-Line Command (Fastest)

Open your computer terminal and paste the command below:

* **On Windows (PowerShell):**
  ```powershell
  irm https://raw.githubusercontent.com/sdoolman/pch-toolkit/main/bootstrap/install.ps1 | iex
  ```
* **On Mac or Linux (Terminal):**
  ```bash
  curl -sSL https://raw.githubusercontent.com/sdoolman/pch-toolkit/main/bootstrap/install.sh | bash
  ```

*The script will ask for your Popcorn Hour's IP address (e.g. `192.168.1.4`), copy the tools over, and start everything automatically.*

---

### Option 2: USB Flash Drive (No Computer Terminal Needed)

1. Download [`pch-revive-usb.zip`](https://github.com/sdoolman/pch-toolkit/releases/latest/download/pch-revive-usb.zip) from the latest release.
2. Extract the files directly to any standard USB flash drive (FAT32 or NTFS).
3. Plug the USB flash drive into your Popcorn Hour and turn it on.
4. The device will automatically run the setup on startup.

---

## 📱 How to Use the Phone Web Remote

Once installed, you have two easy ways to open the remote control:

### 1. Hosted Web Remote (Recommended)
Open this link on your phone or PC browser:  
👉 **[https://sdoolman.github.io/pch-toolkit/controller.html](https://sdoolman.github.io/pch-toolkit/controller.html)**

Type your Popcorn Hour IP address in the top box (it remembers it for next time). Every button press sends the command directly over your home Wi-Fi to your player.

### 2. Directly from your Device
You can also open the remote hosted right on your Popcorn Hour:
```text
http://<YOUR_PCH_IP>:7000/controller
```

---

## 🔑 Modern SSH Access

Once set up, you can securely connect to your Popcorn Hour from your computer:

```bash
ssh root@<YOUR_PCH_IP>
```
* **Clean Environment:** Automatically loads modern command paths and aliases for `nano`, `curl`, `busybox`, and `python`.
* **Auto-Logout Safety:** Sessions automatically disconnect after 1 hour of inactivity (`TMOUT=3600`) so connections don't get stuck in the background.

---

## 💡 How It Works (For the Curious)

The Popcorn Hour runs an embedded Linux kernel (**Linux 2.6.22** on a MIPS SMP8643 processor). Modern languages like Go crash on this old kernel because they require newer system calls. Modern C/C++ often fails due to missing shared library versions.

We solved this by compiling all tools statically against `musl libc`:
* **Zero Dependencies:** Every compiled program contains everything it needs in a single static file.
* **Super Low Memory:** Uses minimal RAM, leaving all system resources free for video playback.
* **Rock Solid:** No library conflicts or missing symbol errors.

---

## 💾 Firmware, Bridge & Emergency Recovery Guide

Looking for original Syabas firmware, the critical A-200/A-210 bridge update, or emergency recovery tools?

Because Cloud Media's official update servers are permanently offline, we document and reference verified firmware archives and un-bricking packages:

* 🚨 **Emergency USB Unbricking Images:** Rescue soft-bricked units stuck on boot or blinking orange/red LEDs using `recovery-image.bin`.
* 🌉 **Required Bridge Firmware:** Step-by-step upgrade path (`02-04-101106-21-POP-411-000`) required for older units.
* 🏁 **Complete Fleet Coverage:** Reference tables and checksums for 15 Popcorn Hour models (A-100 through VTEN).
* 📖 **Read the Complete Guide:** See [docs/firmware-and-recovery.md](docs/firmware-and-recovery.md) for upgrade flowcharts, recovery steps, and archive mirrors.

---

## 🛠️ For Developers: Building from Source

If you want to compile the binaries yourself or build your own custom tools:

### Requirements
* Linux or WSL2 (Ubuntu)
* Rust Nightly (`rustup default nightly && rustup component add rust-src`)

### Compile All Tools
```bash
# Clone the repository
git clone https://github.com/sdoolman/pch-toolkit.git
cd pch-toolkit

# Build all tools into dist/bin/
./toolchain/build.sh all
```

Build individual tools:
```bash
./toolchain/build.sh remote         # Builds Rust Web Remote daemon
./toolchain/build.sh busybox        # Builds BusyBox coreutils
./toolchain/build.sh dropbear       # Builds Dropbear SSH server
./toolchain/build.sh curl           # Builds static Curl client
./toolchain/build.sh nano           # Builds static Nano text editor
./toolchain/build.sh micropython    # Builds MicroPython 3 runtime
./toolchain/build.sh stremio        # Builds Rust Stremio media server
```

---

## ⚖️ License & Disclaimer

* **License:** [MIT License](LICENSE). Free and open-source.
* **Clean Code:** This project does not contain or distribute any copyrighted Syabas or Sigma Designs software. All tools are built from scratch.
* **Disclaimer:** *Popcorn Hour* and *Syabas* are trademarks of Cloud Media / Syabas Technology. This is an independent community project and is not affiliated with or endorsed by Syabas Technology or Cloud Media.
