#!/usr/bin/env python3
"""
Huawei MateBook E 2023 - 4-Speaker Audio Diagnostic & Verification Tool
Tests:
  1. All 4 speakers (Quad chord, 6s)
  2. Left Cluster Only (Top & Bottom Left, 5s)
  3. Right Cluster Only (Top & Bottom Right, 5s)
  4. Dynamic Stereo Spatial Sweep (Left -> Center -> Right, 7s)
"""

import sys
import time
import wave
import struct
import math
import subprocess
import os

FS = 48000

def generate_wav(path, duration, left_fn, right_fn):
    n_samples = int(FS * duration)
    with wave.open(path, 'w') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(FS)
        frames = bytearray()
        for i in range(n_samples):
            t = i / FS
            sl = int(left_fn(t) * 26000)
            sr = int(right_fn(t) * 26000)
            # Clip
            sl = max(-32767, min(32767, sl))
            sr = max(-32767, min(32767, sr))
            frames.extend(struct.pack('<hh', sl, sr))
        wf.writeframes(frames)

def play_audio(path):
    print(f"  -> Đang phát: {os.path.basename(path)}...")
    try:
        subprocess.run(["pw-play", path], check=True)
    except Exception:
        try:
            subprocess.run(["aplay", "-D", "default", path], check=True)
        except Exception as e:
            print(f"[-] Lỗi khi phát: {e}")

def main():
    print("==========================================================")
    print("  Huawei MateBook E 2023 - Kiểm tra hệ thống 4 loa Stereo")
    print("==========================================================")

    tmp_dir = "/tmp/matebook_sound_test"
    os.makedirs(tmp_dir, exist_ok=True)

    chord_fn = lambda t: 0.4 * math.sin(2 * math.pi * 220 * t) + \
                         0.3 * math.sin(2 * math.pi * 440 * t) + \
                         0.2 * math.sin(2 * math.pi * 880 * t) + \
                         0.1 * math.sin(2 * math.pi * 1760 * t)

    # 1. All 4 Speakers
    f1 = f"{tmp_dir}/test1_all4.wav"
    generate_wav(f1, 6.0, chord_fn, chord_fn)

    # 2. Left Only
    f2 = f"{tmp_dir}/test2_left.wav"
    generate_wav(f2, 5.0, chord_fn, lambda t: 0.0)

    # 3. Right Only
    f3 = f"{tmp_dir}/test3_right.wav"
    generate_wav(f3, 5.0, lambda t: 0.0, chord_fn)

    # 4. Sweep
    def sweep_l(t):
        if t < 3.0: return chord_fn(t) * (1.0 - 0.3 * (t / 3.0))
        elif t < 5.0: return chord_fn(t) * (0.7 * (1.0 - (t - 3.0) / 2.0))
        else: return chord_fn(t)

    def sweep_r(t):
        if t < 3.0: return chord_fn(t) * (0.7 * (t / 3.0))
        elif t < 5.0: return chord_fn(t) * (0.7 + 0.3 * ((t - 3.0) / 2.0))
        else: return chord_fn(t)

    f4 = f"{tmp_dir}/test4_sweep.wav"
    generate_wav(f4, 7.0, sweep_l, sweep_r)

    print("\n[Bước 1/4] Phát đồng thanh CẢ 4 LOA (6 giây)...")
    play_audio(f1)
    time.sleep(1)

    print("\n[Bước 2/4] Phát chỉ KÊNH TRÁI - 2 loa bên Trái (5 giây)...")
    play_audio(f2)
    time.sleep(1)

    print("\n[Bước 3/4] Phát chỉ KÊNH PHẢI - 2 loa bên Phải (5 giây)...")
    play_audio(f3)
    time.sleep(1)

    print("\n[Bước 4/4] Phát hiệu ứng Stereo quét Trái sang Phải (7 giây)...")
    play_audio(f4)

    print("\n==========================================================")
    print("  ✓ Hoàn tất chu trình kiểm tra!")
    print("==========================================================")

if __name__ == "__main__":
    main()
