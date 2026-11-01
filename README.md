# Huawei MateBook E 2023 (DRR-W56 / DRR-WXX) Linux Support Guide & Drivers

[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](https://opensource.org/licenses/GPL-2.0)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://kernel.org)
[![Device](https://img.shields.io/badge/Hardware-Huawei%20MateBook%20E%202023-brightgreen.svg)]()
[![Tested on](https://img.shields.io/badge/Kernel-6.x%20%7C%207.x-success.svg)]()
[![Author](https://img.shields.io/badge/Author-hoson-181717?style=flat&logo=github)](https://github.com/hoson-dev)
[![Twitter / X](https://img.shields.io/badge/%F0%9D%95%8F%20(Twitter)-%40hoson.dn-000000?style=flat&logo=x&logoColor=white)](https://x.com/hoson.dn)

Complete hardware enablement guide and automated driver suite for the **Huawei MateBook E 2023 2-in-1 (`DRR-W56` / `DRR-WXX`)** on Linux (Ubuntu, Debian, Arch Linux, Fedora, Linux Mint, Pop!_OS, etc.).

This repository resolves the two major obstacles when running Linux on this device:
1. 🖥️ **OLED MIPI DSI Display (Black Screen Fix):** Fixes the pitch-black display issue on boot with an automated DKMS driver that patches Intel `i915` periodic command mode frame updates.
2. 🔊 **Quad-Speaker Hi-Fi Audio (4 Speakers Enabled):** Fully activates all 4 speakers (2 top tweeters + 2 bottom woofers via dual FourSemi FS2119 SmartPAs), complete with an ALSA real-time hardware volume sync daemon and suspend/resume support.

---

## 💻 Hardware Specifications

| Component | Specification |
| :--- | :--- |
| **Model** | Huawei MateBook E 2023 (`DRR-W56` / `DRR-W76` / `DRR-WXX`) |
| **Board** | `DRR_WXX_PCB` |
| **Processor** | 12th Gen Intel Core i7-1260U / i5-1230U (Alder Lake-P) |
| **Display Panel** | 12.6" OLED (3072 × 1920 @ 60/120 Hz) connected via Intel MIPI DSI |
| **Audio Codec** | Conexant / Senary CX11970 (`0x14f120d0`, Subsystem: `0x1ec93e65`) |
| **Smart Amplifiers** | 2× FourSemi FS2119 Class-D SmartPAs on I2C (`0x69` Left, `0x6b` Right) |

---

## 🚀 Quick Start (Automated All-in-One Installer)

Clone this repository and run the master installer:

```bash
git clone https://github.com/hoson-dev/huawei-matebook-e-2023-linux.git
cd huawei-matebook-e-2023-linux
sudo ./install-all.sh
```

The interactive menu will prompt:
- `1` : **Install ALL (Display OLED + Quad-Speaker Audio) [Recommended]**
- `2` : Install OLED DSI Display Driver only (Black screen fix)
- `3` : Install Quad-Speaker Audio Driver only

After installation completes, reboot your device:
```bash
sudo reboot
```

---

## 📁 Repository Structure

```text
huawei-matebook-e-2023-linux/
├── install-all.sh       # Master installer for both display and audio
├── README.md            # Main documentation
├── display/             # OLED MIPI DSI Display Driver (Black Screen Fix)
│   ├── install.sh       # Automated DKMS installer
│   ├── uninstall.sh     # Clean uninstaller (restores stock i915)
│   ├── check_status.sh  # Diagnostic script for DKMS and DSI-1 status
│   ├── README.md        # Detailed display documentation & recovery steps
│   ├── matebook-e-dsi.patch # DSI command mode periodic update patch
│   └── src/             # Ready-to-build i915 driver source tree
└── sound/               # Quad-Speaker Stereo Audio Driver
    ├── install.sh       # Automated audio installer & service setup
    ├── uninstall.sh     # Clean audio uninstaller
    ├── test_speakers.py # 4-speaker stereo channel verification test
    ├── README.md        # Detailed audio documentation & architecture
    ├── firmware/        # DSP binary configurations (fs2119_config.dat, huawei-diracr.fw)
    ├── modprobe/        # ALSA snd-hda-intel module configurations
    ├── sleep/           # Systemd suspend/resume hook script
    ├── daemon/          # Real-time ALSA hardware volume synchronizer daemon
    └── systemd/         # Systemd service unit definitions
```

---

## 🖥️ Display: OLED MIPI DSI (Black Screen Fix)

### ⚠️ Kernel Compatibility Requirement
> [!IMPORTANT]
> - **Display Driver:** Requires **Linux Kernel 7.0 or newer** (e.g. Ubuntu 26.04+, Arch Linux, modern Fedora).
> - **Reason:** Intel DRM graphics underwent a complete architectural redesign in Kernel 7.0 (introducing `struct intel_display`). The DSI patch requires this modern display pipeline. Attempting to compile on older kernels (such as stock Ubuntu 24.04 or Linux Mint 22 on Kernel 6.8) will fail with DKMS `bad exit status: 2`.
> - **For Ubuntu 24.04 / Linux Mint 22 users:** You can easily upgrade your kernel to 7.0+ using the Ubuntu Mainline Kernel Installer:
>   ```bash
>   sudo add-apt-repository -y ppa:cappelikan/ppa
>   sudo apt update && sudo apt install -y mainline
>   ```
>   Launch **Mainline**, install the latest **7.0.x** kernel build, reboot into the new kernel, and run `./install-all.sh`.
> - **Audio Driver:** The Quad-Speaker Audio driver (`sound/`) is independent and works on **ALL** kernel versions (6.x, 7.x, etc.).

### The Problem
The MateBook E 2023 uses a high-resolution 12.6" OLED display driven over **Intel MIPI DSI dual-link command mode**. 
In upstream Linux kernels, `gen11_dsi_deconfigure_transcoder()` in the `i915` driver clears the periodic frame update bit during initialization and never re-enables it. Because command-mode panels require periodic updates to generate vblank interrupts, the panel stops receiving frames, resulting in a **completely pitch-black screen** while the OS continues to run normally in the background.

### How to Access the System if You Have a Black Screen
If you have just installed Linux and your screen is currently black, choose one of these 3 access methods:
1. **External Monitor via USB-C (Recommended):** Connect an external monitor or TV via USB-C / HDMI. External outputs work out-of-the-box. Open a terminal and run the installer.
2. **Boot with `nomodeset` in GRUB:**
   - At the GRUB boot menu, press **`e`** to edit the boot parameters.
   - Locate the line starting with `linux` (typically ending with `quiet splash`).
   - Append `nomodeset` to the end of the line.
   - Press **`F10`** (or `Ctrl + X`) to boot into basic safe graphics mode.
   - *Note: After installing the DKMS driver, remove `nomodeset` from `/etc/default/grub` so `i915` can drive the OLED panel natively.*
3. **SSH Access:** Connect via SSH over local Wi-Fi or USB tethering from another machine or phone.

### Verification
Run [`display/check_status.sh`](display/check_status.sh) to verify that DKMS is active, kernel module versions match, and `DSI-1` is connected at native 3072×1920.

See [display/README.md](display/README.md) for full technical documentation.

---

## 🔊 Audio: Quad-Speaker Stereo System

### The Problem
Stock Linux kernels only detect the 2 top tweeters through the primary ALSA DAC, leaving the 2 bottom bass woofers completely silent. Furthermore, the external FourSemi FS2119 SmartPAs require precise GPIO power sequencing and I2C registers to unmute. When software mixers attempt to adjust volume, the two independent DACs (`0x22` and `0x23`) drift apart, causing imbalanced audio at lower volume levels.

### The Solution
The package in [`sound/`](sound/):
- Powers on the SmartPAs using GPIO 72 (`QPIN`) and GPIO 179 (`PPIN`).
- Loads the DSP firmware configurations into the dual FS2119 chips over I2C (`0x69` & `0x6b`).
- Runs a lightweight background daemon that listens to ALSA hardware mixer events (`amixer events`) and synchronizes the bass speaker DAC 1:1 with the master speaker DAC in real time.
- Restores DSP parameters automatically upon waking from Sleep (S3/Modern Standby).

### Speaker Verification
Test each speaker and channel separation by running:
```bash
python3 sound/test_speakers.py
```

See [sound/README.md](sound/README.md) for full technical documentation.

---

## 📦 Standalone Distribution Packages

If you want to share individual driver packages without cloning the entire repository, pre-packaged `.zip` and `.tar.gz` archives are available under [Releases v1.0.0](https://github.com/hoson-dev/huawei-matebook-e-2023-linux/releases/tag/v1.0.0):
- `matebook-e-dsi-dkms.zip` / `matebook-e-dsi-dkms.tar.gz` (~2.6 MB)
- `huawei-matebook-e-2023-sound.zip` / `huawei-matebook-e-2023-sound.tar.gz` (~13 KB)

---

## 👤 Author & Maintainer

Maintained with ❤️ by **hoson**:
- 🌐 **GitHub:** [@hoson-dev](https://github.com/hoson-dev)
- 𝕏 **Twitter / X:** [@hoson.dn](https://x.com/hoson.dn)

Feel free to connect or drop a message if you find this project helpful or need assistance!

## 🤝 Contributing & Feedback
Contributions, issues, and pull requests are warmly welcome! If you test this on other MateBook E models or Linux distributions, please report your findings.

## 📄 License & Acknowledgments
- Display DSI patch based on research from the [Arch Linux Community Forum #303555](https://bbs.archlinux.org/viewtopic.php?id=303555).
- Released under the [GNU General Public License v2.0 (GPL-2.0)](LICENSE).
