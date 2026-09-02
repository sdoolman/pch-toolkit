# 🍿 Popcorn Hour Toolkit (`pch-toolkit`)

> Modernize, Jailbreak & Develop for legacy Popcorn Hour (Syabas NMT) devices using modern **Rust** and static cross-compilation.  
> Tested on **Popcorn Hour A-200 / A-210 / C-200** (Sigma Designs SMP8643, MIPS32r2, Linux 2.6.22).

---

## 💡 The Novelty: Modern Rust on Linux 2.6.22 (MIPS)

Legacy embedded network media players like the **Popcorn Hour A-200/A-210/C-200** (powered by Sigma Designs SMP864x MIPS chips) run on ancient Linux kernels (**Linux 2.6.22.19**) with legacy glibc 2.3.

Most modern languages fail to run out of the box:
* **Go $\ge 1.15$ Fails:** The Go runtime runtime's `netpoll` unconditionally calls the `epoll_create1` syscall (introduced in Linux 2.6.27). On Linux 2.6.22, Go binaries crash immediately on startup with a kernel panic / undefined syscall.
* **Modern C/C++ Toolchains Fail:** Modern dynamic binaries fail due to missing GLIBC symbols (`GLIBC_2.14`, `GLIBC_2.28`).
* **🦀 Rust with Musl Static Linking Succeeds:** By compiling modern Rust against `musl` (`mipsel-unknown-linux-musl`) with `target-feature=+crt-static`, `-no-pie`, and `-Z build-std=std,panic_abort`, we produce **100% standalone static binaries** that execute flawlessly on Linux 2.6.22 with **<1 MB RAM consumption**, zero garbage collection pauses, and full memory safety.

---

## 🛠️ Toolchain Guide: How to Compile Rust for MIPS Linux 2.6

### 1. Prerequisites
You need a Linux host or WSL2 (Ubuntu 22.04/24.04) with Rust nightly:
```bash
# 1. Install Rust Nightly & source component
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default nightly
rustup component add rust-src

# 2. Download musl MIPSEL cross-compiler
wget -q https://musl.cc/mipsel-linux-muslsf-cross.tgz
sudo tar -xf mipsel-linux-muslsf-cross.tgz -C /opt
export PATH="/opt/mipsel-linux-muslsf-cross/bin:$PATH"
```

### 2. Configure Cargo for Musl Static Linking
In `.cargo/config.toml`:
```toml
[unstable]
build-std = ["std", "panic_abort"]

[target.mipsel-unknown-linux-musl]
linker = "/opt/mipsel-linux-muslsf-cross/bin/mipsel-linux-muslsf-gcc"
rustflags = [
    "-C", "target-feature=+crt-static",
    "-C", "link-arg=-static",
    "-C", "link-arg=-no-pie"
]
```

### 3. Setup Compiler Unwinder Objects
Musl-cross needs access to GCC's static unwind helper:
```bash
RUSTLIB="$(rustc --print sysroot)/lib/rustlib/mipsel-unknown-linux-musl/lib"
mkdir -p "$RUSTLIB/self-contained"

GCC_DIR=$(dirname $(mipsel-linux-muslsf-gcc -print-libgcc-file-name))
MUSL_LIB=$(dirname $(mipsel-linux-muslsf-gcc -print-file-name=libc.a))

cp -f "$MUSL_LIB"/crt*.o "$RUSTLIB/self-contained/" 2>/dev/null || true
cp -f "$GCC_DIR"/crt*.o "$RUSTLIB/self-contained/" 2>/dev/null || true
cp -f "$MUSL_LIB"/libc.a "$RUSTLIB/self-contained/" 2>/dev/null || true
cp -f "$GCC_DIR"/libgcc_eh.a "$RUSTLIB/self-contained/libunwind.a" 2>/dev/null || true
```

### 4. Build Your Crates
```bash
# Build standalone Web Remote daemon (~490 KB static binary)
cargo +nightly build -p pch-remote --target mipsel-unknown-linux-musl --release

# Strip symbol table for minimum footprint
mipsel-linux-muslsf-strip -s target/mipsel-unknown-linux-musl/release/pch-remote
```

---

## 📡 Remote Installation & Over-the-Network Jailbreak Guide

Popcorn Hour stock firmware exposes:
1. **FTP on Port 21** (Credentials: `nmt:1234`) mapped to `/opt/sybhttpd/localhost.drives/USB_DRIVE` (or internal HDD `/share`).
2. **Telnet on Port 23** (Passwordless root shell).
3. **NMT Startup Hook**: Any executable shell script placed at `/share/start_app.sh` is automatically executed on boot.

### ⚡ 1-Line Remote Installer:
You do not need serial cables or hardware modifications. From any computer on the local network:

* **Windows (PowerShell):**
  ```powershell
  irm https://raw.githubusercontent.com/sdoolman/pch-toolkit/main/bootstrap/install.ps1 | iex
  ```
* **macOS / Linux (Bash):**
  ```bash
  curl -sSL https://raw.githubusercontent.com/sdoolman/pch-toolkit/main/bootstrap/install.sh | bash
  ```

### 💾 Alternative: USB Flash Drive Boot
Extract `bootstrap/start_app.sh` and the pre-compiled binary (`pch_remote`) to the root of a FAT32/NTFS USB flash drive and power on the Popcorn Hour.

---

## 📦 What's Included in this Repository

```text
pch-toolkit/
├── Cargo.toml                  # Cargo Workspace Root
├── crates/
│   ├── pch-remote/             # 📱 Standalone Web Remote Controller Daemon (Port 7000)
│   └── pch-stremio/            # 🍿 Standalone Stremio Direct-Play Server (Port 7001)
├── web/                        # 🌐 Clean Touch Controller HTML (Host on GitHub Pages, Cloudflare, or local)
│   ├── controller.html         # Canonical touch remote UI with keyboard shortcuts & haptics
│   └── _headers                # CORS & Private Network Access headers
├── bootstrap/                  # 🚀 Zero-friction automated installers
│   ├── install.ps1             # Windows remote over-the-network bootstrapper
│   ├── install.sh              # macOS/Linux remote bootstrapper
│   └── start_app.sh            # On-device boot script, daemon manager & watchdog
└── toolchain/                  # 🛠️ Automated build scripts
    └── build.sh                # Multi-target compiler (remote, stremio, micropython)
```

---

## 📱 Web Remote Control Architecture

The included `pch-remote` daemon runs directly on the device:
* **Port 7000**: Serves the mobile touch remote UI at `http://<PCH_IP>:7000/controller`.
* **API Relay**: Forwards key presses directly to Syabas's local loopback HTTP interface (`127.0.0.1:8008/system?arg0=send_key&arg1=<key>`).
* **Hosting Flexibility**: Because `pch-remote` returns standard `Access-Control-Allow-Origin: *` and Private Network Access headers, the web UI can be served directly from the PCH, loaded locally as a `file:///` page, or hosted on any static service like **GitHub Pages** or **Cloudflare Pages**.

---

## ⚖️ Legal & Licensing Notice

* **Clean-Room Open Source:** `pch-toolkit` is an independent open-source project licensed under the [MIT License](LICENSE).
* **Zero Proprietary Code:** This repository contains **no** proprietary Syabas or Sigma Designs binary code, firmware dumps, or copyrighted assets. All tools are built from scratch using open-source Rust, musl libc, and public community interfaces.
* **Trademark Disclaimer:** *Popcorn Hour* and *Syabas* are trademarks of Cloud Media / Syabas Technology. This project is not affiliated with, sponsored by, or endorsed by Syabas Technology or Cloud Media.
