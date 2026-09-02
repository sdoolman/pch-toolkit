#!/usr/bin/env python3
"""
Popcorn Hour Preservation - Internet Archive Uploader
Uploads the complete 2.1 GB firmware, recovery, and CSI package archive to archive.org.

Usage:
  1. Install internetarchive:
       pip install internetarchive
  2. Configure your free archive.org credentials:
       ia configure
  3. Run this script:
       python toolchain/archive_org_sync.py
"""

import os
import sys

def main():
    try:
        import internetarchive as ia
    except ImportError:
        print("[!] The 'internetarchive' Python library is required.")
        print("    Install it via: pip install internetarchive")
        print("    Then configure it via: ia configure")
        sys.exit(1)

    identifier = "popcorn-hour-firmware-vault"
    title = "Popcorn Hour (Syabas / Cloud Media) Firmware & Recovery Vault"
    description = (
        "Complete historical digital preservation archive for Popcorn Hour Networked Media Tank (NMT) "
        "players, including emergency USB unbricking recovery images, bridge firmwares, final production "
        "firmwares for all models (A-100 through VTEN), and Community Software Installer (CSI) packages."
    )
    
    metadata = {
        'title': title,
        'mediatype': 'software',
        'creator': 'Syabas / Cloud Media',
        'collection': 'opensource_media',
        'description': description,
        'subject': ['popcorn hour', 'syabas', 'nmt', 'firmware', 'unbricking', 'recovery', 'smp8643']
    }

    files_to_upload = []

    # 1. Download root firmware archives
    root_downloads = os.path.expanduser(r"~\Downloads")
    for f in [
        'A200_recovery_091114.zip',
        'c200_recovery_090729.zip',
        '02-02-100428-19-POP-411-000.zip',
        '02-04-101106-21-POP-411-000.zip',
        '03-04-120807-21-POP-411-000.zip',
        'A200_A210_03-05-130708-21-POP-411-000.7z'
    ]:
        p = os.path.join(root_downloads, f)
        if os.path.exists(p):
            files_to_upload.append(p)

    # 2. Fleet firmwares & CSI packages
    warez_nmt = os.path.join(root_downloads, 'WAREZ', 'nmtcsi')
    if os.path.exists(warez_nmt):
        for root, _, files in os.walk(warez_nmt):
            if '.git' in root: continue
            for f in files:
                files_to_upload.append(os.path.join(root, f))

    print(f"[*] Found {len(files_to_upload)} files to upload to archive.org ({identifier})...")
    print(f"[*] Uploading...")
    
    try:
        ia.upload(
            identifier,
            files=files_to_upload,
            metadata=metadata,
            verbose=True
        )
        print(f"\n[✓] All files successfully uploaded to:")
        print(f"    https://archive.org/details/{identifier}")
    except Exception as e:
        print(f"\n[!] Upload failed: {e}")

if __name__ == '__main__':
    main()
