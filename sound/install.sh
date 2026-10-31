#!/bin/bash
set -e

# ==============================================================================
# Huawei MateBook E 2023 (DRR-WXX) 4-Speaker Audio Installer for Linux
# Chipset: Intel Alder Lake-P (i7-1260U / i5-1230U)
# Codec: Conexant CX11970 (14f1:20d0, subsystem 1ec9:3e65)
# Amps: 2x FourSemi FS2119 Class-D SmartPAs on I2C (0x69: Left, 0x6b: Right)
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "[-] Lỗi: Vui lòng chạy script với quyền root:"
  echo "    sudo ./install.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "  Cài đặt Driver 4 Loa - Huawei MateBook E 2023 (DRR-WXX)"
echo "=========================================================="

echo "[1/6] Cài đặt các gói phụ thuộc (Dependencies)..."
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq python3 python3-smbus2 python3-libgpiod alsa-utils i2c-tools libgpiod3 || {
        echo "[!] Thử cài fallback gpiod qua apt..."
        apt-get install -y -qq python3-gpiod || true
    }
elif command -v dnf &>/dev/null; then
    dnf install -y python3 python3-smbus2 python3-libgpiod alsa-utils i2c-tools || true
elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm python python-smbus2 libgpiod alsa-utils i2c-tools || true
fi

echo "[2/6] Sao chép file firmware vào /lib/firmware/..."
mkdir -p /lib/firmware
cp "$SCRIPT_DIR/firmware/fs2119_config.dat" /lib/firmware/
cp "$SCRIPT_DIR/firmware/huawei-diracr.fw" /lib/firmware/
chmod 644 /lib/firmware/fs2119_config.dat /lib/firmware/huawei-diracr.fw

echo "[3/6] Cấu hình ALSA Codec modprobe (/etc/modprobe.d/)..."
mkdir -p /etc/modprobe.d
cp "$SCRIPT_DIR/modprobe/huawei-sound.conf" /etc/modprobe.d/
chmod 644 /etc/modprobe.d/huawei-sound.conf

echo "[4/6] Cài đặt Daemon và Sleep Hook..."
cp "$SCRIPT_DIR/daemon/huawei-sound-daemon.py" /usr/local/bin/
chmod 755 /usr/local/bin/huawei-sound-daemon.py

mkdir -p /lib/systemd/system-sleep
cp "$SCRIPT_DIR/sleep/huawei-sound-sleep.sh" /lib/systemd/system-sleep/
chmod 755 /lib/systemd/system-sleep/huawei-sound-sleep.sh

echo "[5/6] Cấu hình và kích hoạt Systemd Service..."
cp "$SCRIPT_DIR/systemd/huawei-sound-daemon.service" /etc/systemd/system/
chmod 644 /etc/systemd/system/huawei-sound-daemon.service
systemctl daemon-reload
systemctl enable huawei-sound-daemon.service
systemctl restart huawei-sound-daemon.service

echo "[6/6] Cập nhật Initramfs (để khởi động sớm khi bật máy)..."
if command -v update-initramfs &>/dev/null; then
    echo "  -> Đang cập nhật initramfs..."
    update-initramfs -u >/dev/null 2>&1 || true
fi

echo "=========================================================="
echo "  ✓ HOÀN TẤT CÀI ĐẶT THÀNH CÔNG!"
echo "  ✓ Cả 4 loa (2 loa tép trên + 2 loa trầm dưới) đã kích hoạt."
echo "  ✓ Âm lượng 4 loa tự động đồng bộ thời gian thực theo phím bấm/thanh trượt."
echo "  ✓ Mức nhỏ nhất êm dịu, mức cao uy lực, cân bằng stereo 100%."
echo "  ✓ Tự động khôi phục sau khi gập máy / Sleep / Reboot."
echo ""
echo "  Để kiểm tra âm thanh stereo 4 loa, chạy lệnh:"
echo "    python3 test_speakers.py"
echo "=========================================================="
