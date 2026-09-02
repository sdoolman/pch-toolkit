# 🍿 Popcorn Hour Toolkit (`pch-toolkit`)

> Modernize, Jailbreak & Revive your legacy Popcorn Hour (Syabas NMT) devices in 2026+.  
> Powered by **Rust**, **Cloudflare Pages**, and **Modular Crates**.

---

## 🌟 Why `pch-toolkit`?

Tens of thousands of legacy **Popcorn Hour** media players (A-200, A-210, C-200, A-300, C-300) powered by Sigma Designs SMP864x chips are gathering dust. Stock firmware runs outdated 2009 daemons, insecure telnet, and lacks modern streaming protocols.

`pch-toolkit` adopts the **Unix philosophy ("Do one thing and do it well")** by breaking all functionality into independent, ultra-lightweight tools:

| Tool | Binary | Port | Description | RAM |
| :--- | :--- | :--- | :--- | :--- |
| 📱 **Web Remote** | `pch_remote` | `7000` | Zero-latency mobile touch controller & key forwarder | <1 MB |
| 🍿 **Stremio Addon** | `pch_stremio` | `7001` | Direct-Play streaming server with HTTP 206 byte-range seeking | <1 MB |
| 🐍 **MicroPython** | `python` | - | Full static Python 3 runtime for custom scripts & automation | <1 MB |
| 🔑 **Modern SSH** | `dropbear` | `22` | Secure Ed25519 authentication & strict idle timeouts (`TMOUT=3600`) | <1 MB |

---

## 🚀 Quickstart (3 Zero-Friction Setup Paths)

### 🥇 Path 1: 1-Line Terminal Installer (Fastest)
From any computer on your home network:

* **Windows (PowerShell):**
  ```powershell
  irm https://pch-toolkit.pages.dev/install.ps1 | iex
  ```
* **macOS / Linux (Bash):**
  ```bash
  curl -sSL https://pch-toolkit.pages.dev/install.sh | bash
  ```

---

### 🥈 Path 2: USB Flash Drive Drop (Zero Terminal)
1. Download `pch-revive-usb.zip` from the latest [GitHub Release](https://github.com/stavdoo/pch-toolkit/releases).
2. Extract the contents to the root of any FAT32/NTFS USB stick.
3. Plug the USB flash drive into the Popcorn Hour and power it on.

---

### 🥉 Path 3: Hosted Web Controller on Cloudflare Pages
To control your device immediately from any smartphone or laptop:
1. Open [`https://pch-toolkit.pages.dev/controller`](https://pch-toolkit.pages.dev/controller).
2. Enter your Popcorn Hour IP (e.g. `192.168.1.4`).

---

## 📺 Adding Stremio Streaming (Optional)

If you run `pch_stremio`, open **Stremio** $\rightarrow$ **Add-ons** 🧩 $\rightarrow$ Paste your manifest URL:
```text
http://<PCH_IP>:7001/manifest.json
```
Instantly stream local movies and series from `/share/Movies` and `/share/TV Shows` with smooth GPU seeking!

---

## 🛠️ Cargo Workspace Structure & Building

```text
pch-toolkit/
├── Cargo.toml                  # Workspace Root
├── crates/
│   ├── pch-remote/             # 📱 Dedicated Web Remote Daemon (Port 7000)
│   └── pch-stremio/            # 🍿 Dedicated Stremio Direct-Play Server (Port 7001)
├── web/                        # 🌐 Cloudflare Pages Static Controller
│   ├── controller.html         # Canonical touch remote UI
│   └── _headers                # CORS & Private Network Access headers
├── bootstrap/                  # 🚀 Zero-friction install scripts
│   ├── install.ps1
│   ├── install.sh
│   └── start_app.sh
└── toolchain/                  # ⚙️ MIPS Cross-compilation scripts
    └── build.sh
```

### Building Tools Independently:
```bash
# Build all tools into dist/bin
./toolchain/build.sh all

# Or build individual tools:
./toolchain/build.sh remote         # Only pch_remote
./toolchain/build.sh stremio        # Only pch_stremio
./toolchain/build.sh micropython    # Only python 3 runtime
```

---

## 📄 License
MIT License. Open-source and free for all Popcorn Hour enthusiasts.
