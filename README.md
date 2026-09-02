# 🍿 Popcorn Hour Toolkit (`pch-toolkit`)

> Bring your old Popcorn Hour back to life with a modern phone remote, secure SSH, and lightweight tools.  
> Works on **Popcorn Hour A-200, A-210, C-200, and C-300**.

---

## 🌟 Why this project?

Got an old Popcorn Hour gathering dust in a drawer?

These classic media players still have great video hardware that plays 1080p movies smoothly. However, the original 2009 software has some common frustrations today:
* 📱 **Lost or broken physical remote?** Replacement remotes are hard to find or expensive.
* 🔒 **Outdated security:** The box only has insecure telnet from 2009.
* 🐢 **Heavy background services:** Legacy transmission and samba daemons eat up the box's limited RAM.

**`pch-toolkit` fixes all of that:**
1. **📱 Phone Web Remote:** Control your Popcorn Hour from any smartphone, tablet, or laptop browser over your home Wi-Fi — zero app installs needed.
2. **🔑 Modern SSH:** Adds fast, secure Dropbear SSH (with key login and auto-logout after 1 hour of inactivity).
3. **⚡ Ultra-Lightweight (Powered by Rust):** Replaces heavy old scripts with tiny, memory-safe binaries that use **less than 1 MB of RAM** and won't crash or slow down the player.

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
* **Clean Environment:** Automatically loads modern command paths and aliases.
* **Auto-Logout Safety:** Sessions automatically disconnect after 1 hour of inactivity (`TMOUT=3600`) so connections don't get stuck in the background.

---

## 💡 How It Works (For the Curious)

The Popcorn Hour runs an old embedded Linux kernel (**Linux 2.6.22**). Modern languages like Go crash on this old kernel because they require newer system calls. Modern C/C++ often fails due to missing shared library versions.

We solved this by compiling **Rust** statically against `musl libc`:
* **Zero Dependencies:** The compiled programs contain everything they need in a single file (~490 KB).
* **Super Low Memory:** Runs with under 1 MB of RAM, leaving all system resources free for video playback.
* **Rock Solid:** Memory-safe with zero memory leaks.

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

Individual tools:
```bash
./toolchain/build.sh remote         # Builds only the Web Remote daemon
./toolchain/build.sh stremio        # Builds the optional Stremio media server
./toolchain/build.sh micropython    # Builds a standalone Python 3 runtime
```

---

## ⚖️ License & Disclaimer

* **License:** [MIT License](LICENSE). Free and open-source.
* **Clean Code:** This project does not contain or distribute any copyrighted Syabas or Sigma Designs software. All tools are built from scratch.
* **Disclaimer:** *Popcorn Hour* and *Syabas* are trademarks of Cloud Media / Syabas Technology. This is an independent community project and is not affiliated with or endorsed by Syabas Technology or Cloud Media.
