#!/bin/bash
set -e

# ==============================================================================
# Huawei MateBook E 2023 (DRR-WXX) Audio Driver Uninstaller
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "[-] Lỗi: Vui lòng chạy script với quyền root:"
  echo "    sudo ./uninstall.sh"
  exit 1
fi

echo "=========================================================="
echo "  Gỡ bỏ Driver Âm thanh Huawei MateBook E 2023"
echo "=========================================================="

echo "[1/4] Dừng và vô hiệu hoá systemd service..."
systemctl stop huawei-sound-daemon.service 2>/dev/null || true
systemctl disable huawei-sound-daemon.service 2>/dev/null || true
rm -f /etc/systemd/system/huawei-sound-daemon.service
systemctl daemon-reload

echo "[2/4] Xoá các file daemon và sleep hook..."
rm -f /usr/local/bin/huawei-sound-daemon.py
rm -f /lib/systemd/system-sleep/huawei-sound-sleep.sh

echo "[3/4] Xoá file cấu hình modprobe..."
rm -f /etc/modprobe.d/huawei-sound.conf

echo "[4/4] Xoá firmware đã cài..."
rm -f /lib/firmware/fs2119_config.dat
rm -f /lib/firmware/huawei-diracr.fw

echo "=========================================================="
echo "  ✓ Đã gỡ bỏ hoàn toàn driver thành công!"
echo "=========================================================="
