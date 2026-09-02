#!/bin/sh
# Popcorn Hour (Syabas NMT) Modernization Boot Script
mkdir -p /var/run /etc/dropbear /root /share/bin /share/Apps/local/bin
chmod 755 /root
sed -i "s#/root:/bin/true#/root:/bin/sh#" /etc/passwd 2>/dev/null
mkdir -p /dev/pts 2>/dev/null
mount -t devpts devpts /dev/pts 2>/dev/null || true
chmod 666 /dev/tty /dev/ptmx /dev/console 2>/dev/null || true
chmod 666 /dev/pts/* 2>/dev/null || true

# 1. Kill bloatware legacy daemons
killall -9 transmission-daemon smbd nmbd upnpapp mDNSResponderPosix mDNSNetMonitor 2>/dev/null || true

# 2. Install new binaries from USB / Storage
for pkg in busybox curl nano jq python pch_remote pch_stremio pch_daemon; do
    if [ -f /share/$pkg ]; then
        cp -f /share/$pkg /share/Apps/local/bin/$pkg
        chmod 755 /share/Apps/local/bin/$pkg
        rm -f /share/$pkg
    fi
done

# 3. Create busybox & core symlinks
for cmd in wget tree which xargs diff patch nc top ps; do
    ln -sf /share/Apps/local/bin/busybox /share/Apps/local/bin/$cmd
    ln -sf /share/Apps/local/bin/busybox /bin/$cmd 2>/dev/null
    ln -sf /share/Apps/local/bin/busybox /usr/bin/$cmd 2>/dev/null
done
ln -sf /share/Apps/local/bin/curl /bin/curl 2>/dev/null
ln -sf /share/Apps/local/bin/nano /bin/nano 2>/dev/null
ln -sf /share/Apps/local/bin/busybox /bin/busybox 2>/dev/null

# 4. Strict Session Environment (TMOUT=3600)
if ! grep -q "TMOUT=" /etc/profile 2>/dev/null; then
    echo "export PATH=/share/Apps/local/bin:/share/Apps/local/sbin:/share/dropbear/bin:/share/dropbear/sbin:/share/bin:\$PATH" >> /etc/profile
    echo "export LD_LIBRARY_PATH=/share/Apps/local/lib:/share/lib:\$LD_LIBRARY_PATH" >> /etc/profile
    echo "export TMOUT=3600" >> /etc/profile
    echo "readonly TMOUT" >> /etc/profile
fi

if ! grep -q "TMOUT=" /root/.profile 2>/dev/null; then
    echo "export PATH=/share/Apps/local/bin:/share/Apps/local/sbin:/share/dropbear/bin:/share/dropbear/sbin:/share/bin:\$PATH" >> /root/.profile
    echo "export LD_LIBRARY_PATH=/share/Apps/local/lib:/share/lib:\$LD_LIBRARY_PATH" >> /root/.profile
    echo "export TMOUT=3600" >> /root/.profile
    echo "readonly TMOUT" >> /root/.profile
    echo "alias ll='ls -la'" >> /root/.profile
fi

# 5. Start Modern SSH (Dropbear)
killall -9 dropbear 2>/dev/null
/share/dropbear/sbin/dropbear -p 0.0.0.0:22 -K 20 -I 1800 -W 65536 -r /share/dropbear/etc/dropbear/dropbear_rsa_host_key -r /share/dropbear/etc/dropbear/dropbear_ecdsa_host_key -r /share/dropbear/etc/dropbear/dropbear_ed25519_host_key -B

# 6. Start Web Remote Daemon (Port 7000)
killall -9 pch_remote 2>/dev/null || true
if [ -f /share/Apps/local/bin/pch_remote ]; then
    /share/Apps/local/bin/pch_remote >/dev/null 2>&1 &
fi

# 7. Start Stremio Media Server (Port 7001 - optional)
killall -9 pch_stremio 2>/dev/null || true
if [ -f /share/Apps/local/bin/pch_stremio ]; then
    /share/Apps/local/bin/pch_stremio >/dev/null 2>&1 &
fi

# 8. Background Watchdog: clean orphaned subshells
(while true; do sleep 600; for p in $(ps -o pid,ppid,comm | awk '$2=="1" && $3=="sh" && $1!="1" && $1!="1302" && $1!="1435" {print $1}'); do kill -9 $p 2>/dev/null || true; done; done) >/dev/null 2>&1 &
