# Huawei MateBook E 2023 (DRR-W56 / DRR-WXX) - Linux Support Guide & Drivers

Dự án hỗ trợ hoàn thiện Linux cho dòng máy tính bảng lai 2-trong-1 **Huawei MateBook E 2023 (Model DRR-W56 / DRR-WXX)**.

Khắc phục triệt để 2 vấn đề lớn nhất của dòng máy này khi cài đặt các bản phân phối Linux (Ubuntu, Debian, Fedora, Arch Linux, Linux Mint, Pop!_OS,...):
1. 🖥️ **Màn hình OLED:** Sửa lỗi **đen màn hình (Black Screen)** khi khởi động bằng DKMS driver patch Intel MIPI DSI.
2. 🔊 **Hệ thống 4 loa:** Kích hoạt đầy đủ **4 loa stereo (2 loa tép + 2 loa trầm)**, chất âm trong trẻo, âm lượng lớn chuẩn Hi-Fi, tự động kích hoạt sau khi Sleep/Wake, đồng bộ âm lượng phần cứng ALSA chống lệch loa.

---

## 🚀 Cài đặt nhanh (Quick Start)

Clone repository này về máy và chạy script cài đặt tổng hợp:

```bash
git clone https://github.com/hoson-dev/huawei-matebook-e-2023-linux.git
cd huawei-matebook-e-2023-linux
sudo ./install-all.sh
```

Menu sẽ cho bạn lựa chọn:
- `1` : Cài đặt tất cả (cả Màn hình OLED và Âm thanh 4 loa) **[Khuyên dùng]**
- `2` : Chỉ cài Driver Màn hình OLED DSI
- `3` : Chỉ cài Driver Âm thanh 4 Loa Stereo

Sau khi cài đặt xong, khởi động lại máy:
```bash
sudo reboot
```

---

## 📁 Cấu trúc Repository

```text
huawei-matebook-e-2023-linux/
├── install-all.sh       # Menu cài đặt tổng hợp tất cả driver
├── README.md            # Tài liệu hướng dẫn chính
├── display/             # Gói Driver Màn hình OLED MIPI DSI (Fix Đen Màn Hình)
│   ├── install.sh       # Script cài đặt DKMS driver màn hình
│   ├── uninstall.sh     # Gỡ bỏ và khôi phục driver i915 gốc
│   ├── check_status.sh  # Kiểm tra trạng thái cổng DSI-1 & DKMS
│   ├── README.md        # Hướng dẫn chi tiết & cách cứu hộ khi đen màn
│   └── src/             # Mã nguồn module i915 đã patch
└── sound/               # Gói Driver Âm thanh 4 Loa Stereo
    ├── install.sh       # Script cài đặt driver âm thanh & daemon
    ├── uninstall.sh     # Gỡ bỏ sạch sẽ driver âm thanh
    ├── test_speakers.py # Script kiểm tra âm thanh từng loa
    ├── README.md        # Hướng dẫn chi tiết cấu hình âm thanh
    ├── firmware/        # Firmware DSP FS2119 / CS35L41
    ├── modprobe/        # Cấu hình ALSA HDA snd-hda-intel
    ├── sleep/           # Script khôi phục SmartPA khi Sleep/Wake
    ├── daemon/          # Python ALSA Hardware Volume Sync Daemon
    └── systemd/         # Systemd services tự khởi động cùng máy
```

---

## 🖥️ Chi tiết: Sửa lỗi Đen Màn Hình (Display Driver)

Màn hình OLED 3072x1920 của MateBook E 2023 sử dụng giao tiếp **Intel MIPI DSI command mode**. Kernel Linux mặc định chưa kích hoạt `DSI_PERIODIC_FRAME_UPDATE_ENABLE` khiến màn hình không nhận khung hình và tắt ngúm.

Gói trong thư mục `display/` sử dụng DKMS để thay thế module `i915.ko`, giúp màn hình sáng lên và hoạt động ở đúng độ phân giải native 3072x1920 @ 60/120Hz.

> **Nếu màn hình máy đang bị đen:**
> 1. Cắm ra màn hình rời qua cổng Type-C (màn ngoài luôn lên bình thường).
> 2. Hoặc tại menu GRUB, nhấn phím `e` rồi thêm `nomodeset` vào cuối dòng `linux ... quiet splash` để vào giao diện an toàn tạm thời.
> 3. Xem chi tiết tại [display/README.md](display/README.md).

---

## 🔊 Chi tiết: Kích hoạt Hệ thống 4 Loa (Sound Driver)

MateBook E 2023 sử dụng chip âm thanh Realtek ALC245 kết hợp cùng 2 ampli thông minh SmartPA FS2119 / CS35L41 qua giao tiếp I2C:
- **Loa trên (Tweeter / 0x14):** 2 loa tép (trên đỉnh máy).
- **Loa dưới (Bass Woofer / 0x17):** 2 loa trầm (đáy máy).

Gói trong thư mục `sound/` giải quyết triệt để:
- Nạp đầy đủ firmware DSP SmartPA.
- Cấu hình ALSA `alc245-huawei-matebook-e` nạp GPIO bật nguồn ampli.
- Chạy daemon đồng bộ phần cứng ALSA chống hiện tượng lệch loa khi vặn nhỏ âm lượng.
- Tự động nạp lại DSP sau khi máy ngủ (Sleep/Resume).
- Xem chi tiết tại [sound/README.md](sound/README.md).

---

## 🛠️ Yêu cầu hệ thống
- **Dòng máy:** Huawei MateBook E 2023 (DRR-W56, DRR-W76 hoặc các phiên bản tương đương).
- **Hệ điều hành:** Ubuntu 22.04+, Debian 12+, Arch Linux, Fedora 39+, Linux Mint 21+, Pop!_OS,...
- **Kernel:** Linux 6.x / 7.x (Generic hoặc OEM).

---

## 📜 Giấy phép & Lời cảm ơn
- Patch DSI dựa trên nghiên cứu và chia sẻ của cộng đồng Arch Linux ([Arch Linux BBS #303555](https://bbs.archlinux.org/viewtopic.php?id=303555)).
- Mã nguồn driver tuân thủ giấy phép GPL-2.0.
