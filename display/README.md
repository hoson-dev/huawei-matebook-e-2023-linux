# Huawei MateBook E 2023 - OLED MIPI DSI Display Driver (Black Screen Fix)

DKMS kernel module driver resolving the **Black Screen on Boot** issue on the **Huawei MateBook E 2023 (`DRR-W56` / `DRR-WXX`)** across Linux distributions (Ubuntu, Debian, Fedora, Arch Linux, Linux Mint, Pop!_OS, etc.).

---

## 1. Root Cause Analysis & Kernel Requirements

> [!IMPORTANT]
> **Kernel Version Requirement:** This driver requires **Linux Kernel 7.0 or newer**.
> If your system is running an older kernel (e.g. stock Ubuntu 24.04 or Linux Mint 22 with Kernel 6.8), the DKMS build will fail with `bad exit status: 2` because Intel DRM graphics underwent a complete architectural redesign in Kernel 7.0 (`struct intel_display`).
> 
> **How to upgrade kernel on Ubuntu / Linux Mint:**
> ```bash
> sudo add-apt-repository -y ppa:cappelikan/ppa
> sudo apt update && sudo apt install -y mainline
> ```
> Launch **Mainline**, install Kernel 7.0.x, reboot, and run `./install.sh`.

The 12.6-inch OLED panel (3072 × 1920 @ 60/120 Hz) on the Huawei MateBook E 2023 interfaces directly with the Intel Alder Lake Iris Xe Graphics via **Intel MIPI DSI dual-link command mode**.

In upstream Linux kernels, the Intel DRM driver (`i915`):
- Executes `gen11_dsi_deconfigure_transcoder()`, which clears the `DSI_PERIODIC_FRAME_UPDATE_ENABLE` bit on initialization.
- Never restores this bit during normal operation.
- In command mode, the panel relies on periodic updates to generate vblank intervals. Without this bit enabled, frames cease immediately, causing the OLED panel to remain **completely pitch-black**, even though the system boots and runs normally in the background.

This package provides a **DKMS (Dynamic Kernel Module Support)** module that patches the `i915` driver, restores the periodic frame update bit, and correctly activates `DSI-1`. Being a DKMS module, it automatically rebuilds whenever your system upgrades to a new kernel version.

---

## 2. How to Access Your System When the Screen is Black

If your internal screen is currently black after a fresh Linux install, choose one of these 3 rescue options:

### Option 1: External Monitor via USB-C / HDMI (Fastest & Easiest)
- Connect your MateBook E to an external monitor or TV via a USB-C cable or USB-C to HDMI adapter.
- External video output works out-of-the-box. Open a terminal on the external monitor to execute the installation.

### Option 2: Temporary Boot with `nomodeset` in GRUB
1. Reboot the device. Hold `Shift` or press `Esc` to access the GRUB boot menu.
2. Highlight your default Linux kernel entry and press **`e`** to edit boot parameters.
3. Locate the line beginning with `linux` (typically ending with `quiet splash`).
4. Append `nomodeset` to the end of that line:
   ```text
   ... quiet splash nomodeset
   ```
5. Press **`F10`** (or `Ctrl + X`) to boot. The system will start using basic framebuffer graphics mode.

> **CRITICAL NOTE:** `nomodeset` is strictly for temporary rescue access. Once you have installed this DKMS driver, you **MUST REMOVE** `nomodeset` from `/etc/default/grub` (and run `sudo update-grub`) so that the Intel `i915` driver can load and initialize the OLED panel natively.

### Option 3: Remote SSH Access
- If connected to Wi-Fi or local network, access the terminal remotely via SSH from another computer or mobile phone.

---

## 3. Automated 1-Click Installation

Open a terminal inside this directory and run:

```bash
cd display
sudo ./install.sh
```

### The installer automatically:
1. Detects your distribution package manager (`apt`, `pacman`, `dnf`).
2. Checks and installs required dependencies (`dkms`, `build-essential`, `linux-headers-$(uname -r)`).
3. Registers the source tree to `/usr/src/matebook-e-dsi-1.0.0/`.
4. Compiles the patched `i915` module via DKMS.
5. Installs the module into your current kernel.
6. Regenerates the initramfs (`update-initramfs`, `mkinitcpio`, or `dracut`).
7. Checks `/etc/default/grub` and warns if `nomodeset` is still lingering.

After installation completes, reboot:
```bash
sudo reboot
```

Your OLED panel will light up at native 3072×1920 resolution!

---

## 4. Diagnostics & Verification

After rebooting, check driver status anytime by running:

```bash
./check_status.sh
```

The script will report:
- DKMS status (`installed`)
- Module `srcversion` checksum comparison (Running vs Installed)
- Connector status (`DSI-1 connected`)
- Current active display resolution & refresh rate

---

## 5. Uninstallation (Restore Stock Driver)

To remove the DKMS module and return to the stock kernel `i915` driver:

```bash
sudo ./uninstall.sh
sudo reboot
```

---

## 6. Directory Layout

```text
display/
├── install.sh                     # Automated 1-click installer
├── uninstall.sh                   # Clean uninstaller
├── check_status.sh                # Hardware diagnostic tool
├── README.md                      # Documentation
├── matebook-e-dsi.patch           # Unified DSI timing patch
├── PKGBUILD                       # Arch Linux packaging file
├── zz-matebook-e-dsi-initramfs.hook # Arch Linux pacman initramfs hook
└── src/                           # Pre-patched i915 source tree
    ├── Makefile
    ├── dkms.conf
    └── drivers/
        ├── gpu/drm/i915/
        └── platform/x86/intel_ips.h
```

---

## 👤 Author & Maintainer
- **hoson** ([GitHub](https://github.com/hoson-dev) | [𝕏 / Twitter: @hoson.dn](https://x.com/hoson.dn))

