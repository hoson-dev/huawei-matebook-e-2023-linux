#!/usr/bin/env python3
"""
Huawei MateBook E 2023 (DRR-WXX) Audio Amplifier Daemon
Reverse-engineered from Windows 11 drivers:
  - MultiPADriver.sys & config.dat (FourSemi FS2119 SmartPA amps on I2C bus)
  - Conexant / Senary CX11970 HDA codec
Features:
  - GPIO line 72 & 179 sequencing
  - FS2119 Mode 0 & Mode 3 register configuration
  - Slot 0x222c unmuting both Top Tweeters and Bottom Woofers
  - Real-time ALSA sync loop: mirrors Speaker volume/mute to Bass Speaker
    ensuring all 4 speakers stay perfectly balanced at all volume levels
"""
import os
import sys
import time
import signal
import struct
import threading
import subprocess
import smbus2
import gpiod
from gpiod.line import Direction, Value

DAT_PATH = '/lib/firmware/fs2119_config.dat'
PA_ADDRS = [0x69, 0x6b]

def log(msg):
    print(f"[huawei-sound-daemon] {msg}", flush=True)

def wait_for_device(path, timeout=15):
    start = time.time()
    while time.time() - start < timeout:
        if os.path.exists(path):
            return True
        time.sleep(0.5)
    return False

def get_i2c_bus_id():
    try:
        for dev in os.listdir('/sys/bus/i2c/devices/'):
            if 'HWSP0001' in dev:
                target = os.readlink(os.path.join('/sys/bus/i2c/devices', dev))
                for p in target.split('/'):
                    if p.startswith('i2c-') and p[4:].isdigit():
                        return int(p[4:])
        for dev in os.listdir('/sys/bus/i2c/devices/'):
            if dev.startswith('i2c-') and dev[4:].isdigit():
                target = os.readlink(os.path.join('/sys/bus/i2c/devices', dev))
                if '0000:00:15.0' in target:
                    return int(dev[4:])
    except Exception:
        pass
    return 2

def get_hwdep_path():
    for c in range(4):
        p = f"/dev/snd/hwC{c}D0"
        codec_info = f"/proc/asound/card{c}/codec#0"
        if os.path.exists(codec_info):
            try:
                with open(codec_info, 'r', errors='ignore') as f:
                    if "CX11970" in f.read():
                        return p, c
            except Exception:
                pass
        if os.path.exists(p):
            return p, c
    return "/dev/snd/hwC0D0", 0

def apply_hda_verbs():
    hwdep, card_idx = get_hwdep_path()
    if not os.path.exists(hwdep):
        return
    verbs = [
        # Conexant CX11970 Oceanside I2S transmitter & Merge Mode (per Windows INF)
        ("0x1c", "0x410", "0x62"),  # Merge Port A & Port B
        ("0x1c", "0x390", "0x00"),  # I2S transmitter override
        ("0x1c", "0xcc0", "0xc4"),  # I2S enable
        ("0x1c", "0x9f0", "0x83d"), # Stream enable
        # Speaker 1 Pin 0x1d (DAC 0x22)
        ("0x1d", "0x70c", "0x02"),  # EAPD enable
        ("0x1d", "0x707", "0x40"),  # Pin Output enable
        ("0x22", "0x3b0", "0x4a"),  # DAC 0x22 Gain max (74 / 0dB)
        # Speaker 2 Pin 0x26 (DAC 0x23)
        ("0x26", "0x70c", "0x02"),  # EAPD enable
        ("0x26", "0x707", "0x40"),  # Pin Output enable
        ("0x23", "0x3b0", "0x4a"),  # DAC 0x23 Gain max (74 / 0dB)
    ]
    for nid, verb, param in verbs:
        try:
            subprocess.run(["hda-verb", hwdep, nid, verb, param], capture_output=True, check=False)
        except Exception:
            pass

def sync_alsa_loop(card_idx=0):
    log(f"Starting real-time ALSA volume synchronizer on card {card_idx}...")
    cmd = ["stdbuf", "-oL", "amixer", f"-c{card_idx}", "events"]
    # Initial sync
    try:
        out = subprocess.check_output(['amixer', f'-c{card_idx}', 'cget', 'numid=3'], text=True)
        for l in out.splitlines():
            if ': values=' in l:
                val = l.split(': values=')[1].strip()
                subprocess.run(['amixer', f'-c{card_idx}', 'cset', 'numid=5', val], capture_output=True)
                break
    except Exception:
        pass

    while True:
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True, bufsize=1)
            for line in proc.stdout:
                if 'numid=3' in line or "name='Speaker Playback Volume'" in line:
                    out = subprocess.check_output(['amixer', f'-c{card_idx}', 'cget', 'numid=3'], text=True)
                    for l in out.splitlines():
                        if ': values=' in l:
                            val = l.split(': values=')[1].strip()
                            subprocess.run(['amixer', f'-c{card_idx}', 'cset', 'numid=5', val], capture_output=True)
                            break
                elif 'numid=4' in line or "name='Speaker Playback Switch'" in line:
                    out = subprocess.check_output(['amixer', f'-c{card_idx}', 'cget', 'numid=4'], text=True)
                    for l in out.splitlines():
                        if ': values=' in l:
                            val = l.split(': values=')[1].strip()
                            subprocess.run(['amixer', f'-c{card_idx}', 'cset', 'numid=6', val], capture_output=True)
                            break
        except Exception as e:
            log(f"ALSA sync loop error: {e}")
            time.sleep(2)

class SoundHardware:
    def __init__(self):
        self.req = None
        self.bus = None
        self.bus_id = 2
        self.modes = {}

    def init_gpio(self):
        log("Configuring GPIO lines (QPIN 72, PPIN 179) per Windows driver...")
        if not wait_for_device("/dev/gpiochip0", timeout=10):
            log("Error: /dev/gpiochip0 not available")
            sys.exit(1)

        chip = gpiod.Chip("/dev/gpiochip0")
        lines_to_req = {
            72:  gpiod.LineSettings(direction=Direction.OUTPUT, output_value=Value.INACTIVE),
            179: gpiod.LineSettings(direction=Direction.OUTPUT, output_value=Value.ACTIVE),
        }
        self.req = chip.request_lines(consumer="huawei_sound", config=lines_to_req)
        time.sleep(0.01)

        # Step 0: GPIO 72 (Power rail on)
        self.req.set_value(72, Value.ACTIVE)
        time.sleep(0.020)
        # Step 1: GPIO 179 (Active low power enable)
        self.req.set_value(179, Value.INACTIVE)
        time.sleep(0.020)
        log("GPIO power sequencing completed. Lines held active.")

    def write_reg(self, addr, reg, val, width):
        try:
            if width == 1:
                self.bus.write_byte_data(addr, reg, val & 0xff)
            elif width == 2:
                self.bus.write_i2c_block_data(addr, reg, [(val >> 8) & 0xff, val & 0xff])
            elif width == 4:
                self.bus.write_i2c_block_data(addr, reg, [
                    (val >> 24) & 0xff, (val >> 16) & 0xff, (val >> 8) & 0xff, val & 0xff
                ])
        except Exception as e:
            log(f"Error writing [0x{addr:02x}] reg 0x{reg:02x}: {e}")

    def load_modes(self):
        if not os.path.exists(DAT_PATH):
            log(f"Warning: {DAT_PATH} not found")
            return
        with open(DAT_PATH, 'rb') as f:
            raw = f.read()

        ints = struct.unpack(f'<{len(raw)//4}I', raw[:len(raw) - len(raw)%4])
        idx = 1
        for m in range(ints[0]):
            mode_id = ints[idx]
            num_subs = ints[idx+1]
            idx += 2
            self.modes[mode_id] = []
            for s in range(num_subs):
                sub_id = ints[idx]
                count = ints[idx+1]
                chunk = ints[idx+2 : idx+2+count]
                idx += 2 + count
                items = []
                for i in range(0, count, 7):
                    it = chunk[i:i+7]
                    if len(it) == 7:
                        items.append(it)
                self.modes[mode_id].append(items)

    def apply_mode_writes(self, mid):
        if mid not in self.modes:
            return
        for sub_id, items in enumerate(self.modes[mid]):
            addr = PA_ADDRS[sub_id]
            for it in items:
                reg, mask, val, delay, f4, f5, width = it
                if f4 == 0 and reg != 0 and width in (1, 2, 4):
                    self.write_reg(addr, reg, val, width)
                    if delay > 0:
                        time.sleep(delay / 1000.0)

    def init_amps(self):
        self.bus_id = get_i2c_bus_id()
        log(f"Initializing I2C bus {self.bus_id}...")
        if not wait_for_device(f"/dev/i2c-{self.bus_id}", timeout=10):
            log(f"Error: /dev/i2c-{self.bus_id} not available")
            sys.exit(1)
        if self.bus is None:
            self.bus = smbus2.SMBus(self.bus_id)

        self.load_modes()

        # Step 1: Base chip configuration (Mode 0)
        self.apply_mode_writes(0)

        # Step 2: Playback Scene (Mode 3)
        self.apply_mode_writes(3)

        # Step 3: Channel Slots & Volume unmute
        self.unmute_amps()
        log("FS2119 amplifiers configured and unmuted.")

    def unmute_amps(self):
        slot = int(os.environ.get('FS2119_SLOT', '0x222c'), 16)
        log(f'Unmuting FS2119 amplifiers (slot=0x{slot:04x})...')
        for addr in PA_ADDRS:
            self.write_reg(addr, 0x39, 0x0000, 2)
            self.write_reg(addr, 0x3a, 0x0000, 2)
            self.write_reg(addr, 0x11, 0x0300, 2)
            self.write_reg(addr, 0x30, slot, 2)
            self.write_reg(addr, 0x39, 0xf000, 2)
            self.write_reg(addr, 0x3a, 0xf000, 2)

    def check_pll(self):
        try:
            d1 = self.bus.read_i2c_block_data(0x69, 0x05, 2)
            d2 = self.bus.read_i2c_block_data(0x6b, 0x05, 2)
            v1 = (d1[0] << 8) | d1[1]
            v2 = (d2[0] << 8) | d2[1]
            return (v1, v2)
        except Exception:
            return (None, None)

def main():
    running = True
    def sig_handler(sig, frame):
        nonlocal running
        log("Exiting on signal...")
        running = False
        sys.exit(0)

    signal.signal(signal.SIGTERM, sig_handler)
    signal.signal(signal.SIGINT, sig_handler)

    hw = SoundHardware()
    hw.init_gpio()
    hw.init_amps()
    apply_hda_verbs()

    _, card_idx = get_hwdep_path()
    # Start ALSA volume sync thread
    sync_thread = threading.Thread(target=sync_alsa_loop, args=(card_idx,), daemon=True)
    sync_thread.start()

    log("Daemon running and holding hardware active with ALSA sync...")

    last_check = time.time()
    while running:
        time.sleep(1.0)
        if time.time() - last_check > 5.0:
            last_check = time.time()
            v1, v2 = hw.check_pll()
            try:
                m1 = hw.bus.read_i2c_block_data(0x69, 0x11, 2)
                if (m1[0] << 8) | m1[1] != 0x0300:
                    hw.unmute_amps()
                    apply_hda_verbs()
            except Exception:
                pass

if __name__ == '__main__':
    main()
