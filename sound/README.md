# Huawei MateBook E 2023 - Quad-Speaker Stereo Audio Driver (Linux)

Complete audio driver package enabling all **4 speakers (2 top tweeters + 2 bottom woofers)** on the **Huawei MateBook E 2023 (`DRR-WXX`)** 2-in-1 laptop running Linux (Ubuntu, Debian, Fedora, Arch Linux, Linux Mint, Pop!_OS, etc.).

---

## 💻 Hardware Specifications

* **Model:** Huawei MateBook E 2023 (`DRR-WXX`, Motherboard: `DRR_WXX_PCB`)
* **CPU:** 12th Gen Intel Core i7-1260U / i5-1230U (Intel Alder Lake-P Smart Sound Technology)
* **Audio Codec:** Conexant / Senary CX11970 (Vendor ID: `0x14f120d0`, Subsystem: `0x1ec93e65`)
* **Smart Amplifiers:** 2× FourSemi FS2119 Class-D SmartPAs on I2C bus:
  * Address `0x69`: Controls **Left** speakers (Ch1: Top Tweeter, Ch2: Bottom Woofer)
  * Address `0x6b`: Controls **Right** speakers (Ch1: Top Tweeter, Ch2: Bottom Woofer)

---

## 🚀 Quick Start (Automated 1-Click Install)

Open a terminal in this directory and run:

```bash
cd sound
sudo ./install.sh
```

### The script automatically:
1. Installs system dependencies (`python3`, `python3-smbus2`, `python3-libgpiod`, `alsa-utils`, `i2c-tools`).
2. Deploys SmartPA DSP configuration firmware (`fs2119_config.dat`) and Conexant CX11970 HDA verb patches (`huawei-diracr.fw`) to `/lib/firmware/`.
3. Sets up ALSA kernel options in `/etc/modprobe.d/huawei-sound.conf`.
4. Installs the background hardware sync daemon (`/usr/local/bin/huawei-sound-daemon.py`) and systemd sleep hook (`/usr/lib/systemd/system-sleep/huawei-sound-sleep.sh`).
5. Enables and starts the `huawei-sound-daemon.service` systemd unit to start automatically on boot.

---

## 🎧 Speaker Testing & Channel Verification

Verify all 4 speakers and stereo channel separation by running the interactive test:

```bash
python3 test_speakers.py
```

This plays pure frequency tones across all 4 discrete speaker channels (Top Left, Bottom Left, Top Right, Bottom Right) to confirm balanced stereo imaging.

---

## 🗑️ Uninstallation

To completely remove the audio drivers, services, and restore default system audio:

```bash
sudo ./uninstall.sh
```

---

## ⚙️ Directory Structure

```text
sound/
├── install.sh                  # Automated 1-click installer
├── uninstall.sh                # Clean uninstaller
├── test_speakers.py            # 4-speaker stereo testing script
├── README.md                   # Documentation
├── firmware/
│   ├── fs2119_config.dat       # FourSemi FS2119 DSP firmware (Modes 0 & 3)
│   └── huawei-diracr.fw        # HDA verb patch for Conexant CX11970
├── modprobe/
│   └── huawei-sound.conf       # ALSA snd-hda-intel kernel options
├── daemon/
│   └── huawei-sound-daemon.py  # I2C/GPIO initialization & ALSA real-time sync daemon
├── systemd/
│   └── huawei-sound-daemon.service # Systemd background service unit
└── sleep/
    └── huawei-sound-sleep.sh   # Systemd suspend/resume hook script
```

---

## 🔬 Technical Highlights

1. **GPIO Power Sequencing:**
   - GPIO Line 72 (`QPIN`): Energizes main amplifier supply rail.
   - GPIO Line 179 (`PPIN`): Pulled Active-Low to enable and initialize the FS2119 chips.
2. **Amplifier Register `0x30` (`FS210X_30H_DACCTRL`):**
   - Configured to `0x222c`.
   - Bit 4 = 0: Unmutes Channel 1 (Top Tweeter).
   - Bit 8 = 0: Unmutes Channel 2 (Bottom Woofer).
3. **Volume Registers `0x39` & `0x3a`:**
   - Set to `0xf000` (0 dB optimal unity gain, preventing audio clipping).
4. **Real-time ALSA Hardware Volume Sync:**
   - The CX11970 codec employs two distinct DACs: DAC `0x22` (Speaker) and DAC `0x23` (Bass Speaker).
   - Standard PipeWire/PulseAudio desktop mixers only adjust DAC `0x22`.
   - The included daemon runs an efficient ALSA event listener thread (`amixer events`) that instantly synchronizes `cset numid=5,6` with `numid=3,4` in hardware. This ensures volume adjustments remain balanced across all 4 speakers without channel mismatch, even at whisper-quiet levels (< 25%).
