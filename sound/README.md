# Bộ Driver Âm Thanh 4 Loa cho Huawei MateBook E 2023 (Linux)
### (Huawei MateBook E 2023 `DRR-WXX` Quad-Speaker Linux Audio Driver)

Dự án này cung cấp driver hoàn chỉnh, tự động kích hoạt toàn bộ hệ thống **4 loa (2 loa tép trên + 2 loa trầm dưới)** trên laptop lai **Huawei MateBook E 2023 (`DRR-WXX`)** chạy Linux (Ubuntu, Debian, Fedora, Arch...).

---

## 💻 Thiết bị hỗ trợ
* **Model:** Huawei MateBook E 2023 (Mã máy: `DRR-WXX`, Bo mạch: `DRR_WXX_PCB`)
* **CPU:** Intel Core i7-1260U / i5-1230U (Intel Alder Lake-P Smart Sound Technology)
* **HDA Codec:** Conexant / Senary CX11970 (Vendor ID: `0x14f120d0`, Subsystem: `0x1ec93e65`)
* **Smart Amps:** 2x FourSemi FS2119 Class-D SmartPAs trên I2C Bus:
  * Địa chỉ `0x69`: Phụ trách 2 loa bên **Trái** (Ch1: Loa tép trên Trái, Ch2: Loa trầm dưới Trái)
  * Địa chỉ `0x6b`: Phụ trách 2 loa bên **Phải** (Ch1: Loa tép trên Phải, Ch2: Loa trầm dưới Phải)

---

## 🚀 Hướng dẫn cài đặt nhanh (1 dòng lệnh)

Mở Terminal trong thư mục này và chạy:

```bash
sudo ./install.sh
```

Script sẽ tự động:
1. Cài đặt các gói phụ thuộc (`python3`, `python3-smbus2`, `python3-libgpiod`, `alsa-utils`, `i2c-tools`).
2. Nạp firmware cấu hình SmartPA (`fs2119_config.dat`) và patch Codec Conexant CX11970 (`huawei-diracr.fw`).
3. Cài đặt background daemon (`huawei-sound-daemon.py`) và sleep hook (`huawei-sound-sleep.sh`).
4. Kích hoạt systemd service chạy ngầm tự khởi động cùng máy, đồng bộ âm lượng 4 loa thời gian thực và khôi phục khi thức dậy từ chế độ Sleep.

---

## 🎧 Kiểm tra âm thanh sau khi cài đặt

Để kiểm tra âm thanh cả 4 loa và độ tách bạch stereo Trái/Phải:

```bash
python3 test_speakers.py
```

---

## 🗑️ Gỡ bỏ cài đặt (Uninstall)

Nếu muốn khôi phục về trạng thái gốc của hệ thống:

```bash
sudo ./uninstall.sh
```

---

## ⚙️ Cấu trúc thư mục

```
huawei-matebook-e-2023-sound/
├── install.sh                  # Script cài đặt tự động 1 chạm
├── uninstall.sh                # Script gỡ bỏ driver
├── test_speakers.py            # Công cụ kiểm tra âm thanh 4 loa stereo
├── README.md                   # Tài liệu hướng dẫn sử dụng
├── firmware/
│   ├── fs2119_config.dat       # Firmware cấu hình chip FS2119 (Mode 0, 3)
│   └── huawei-diracr.fw        # Patch HDA Verbs cho CX11970
├── modprobe/
│   └── huawei-sound.conf       # Cấu hình ALSA kernel options
├── daemon/
│   └── huawei-sound-daemon.py  # Daemon điều khiển I2C & GPIO FourSemi + ALSA Real-time Sync
├── systemd/
│   └── huawei-sound-daemon.service # Service tự khởi động ngầm
└── sleep/
    └── huawei-sound-sleep.sh   # Hook tự động khôi phục sau khi Sleep
```

---

## 🔬 Giải mã kỹ thuật chính (Technical Highlights)

1. **Trình tự cấp nguồn GPIO:**
   - Dòng GPIO 72 (`QPIN`): Kích hoạt điện áp nguồn chính.
   - Dòng GPIO 179 (`PPIN`): Kéo xuống mức thấp (Active-Low) để mở chip FS2119.
2. **Thanh ghi `0x30` (`FS210X_30H_DACCTRL`):**
   - Giá trị chuẩn: `0x222c`.
   - Bit 4 = 0: Unmute Kênh 1 (Loa trên).
   - Bit 8 = 0: Unmute Kênh 2 (Loa dưới).
3. **Thanh ghi âm lượng `0x39` & `0x3a`:**
   - Đặt `0xf000` (Mức Gain 0 dB tối đa, không bị méo tiếng).
4. **Đồng bộ âm lượng thời gian thực (Real-time ALSA Sync):**
   - Bộ giải mã Conexant CX11970 chia làm 2 DAC độc lập: DAC `0x22` (Speaker) và DAC `0x23` (Bass Speaker).
   - Daemon tích hợp luồng lắng nghe sự kiện ALSA (`amixer events`) để tự động đồng bộ tức thời 1:1 giữa Speaker và Bass Speaker.
   - Khi chỉnh âm lượng trên bàn phím hay giao diện, cả 4 loa cùng tăng/giảm đồng thanh; ở mức thấp nhất âm thanh êm dịu, không bị kẹt loa trầm ở công suất tối đa.
