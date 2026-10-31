#!/usr/bin/env bash
# ==============================================================================
# Script gỡ bỏ DKMS Driver Huawei MateBook E 2023 DSI (Khôi phục driver gốc)
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}==================================================================${NC}"
echo -e "${BLUE}${BOLD}         GỠ BỎ DRIVER MATEBOOK E DSI (KHÔI PHỤC DRIVER GỐC)       ${NC}"
echo -e "${BLUE}${BOLD}==================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI] Vui lòng chạy script này với quyền root:${NC}"
    echo "  sudo ./uninstall.sh"
    exit 1
fi

MODULE_NAME="matebook-e-dsi"
MODULE_VERSION="1.0.0"

echo -e "\n${BOLD}[1/3] Gỡ bỏ module ${MODULE_NAME}/${MODULE_VERSION} khỏi DKMS...${NC}"
dkms remove -m "${MODULE_NAME}/${MODULE_VERSION}" --all 2>/dev/null || true

echo -e "\n${BOLD}[2/3] Xoá mã nguồn tại /usr/src/${MODULE_NAME}-${MODULE_VERSION}...${NC}"
rm -rf "/usr/src/${MODULE_NAME}-${MODULE_VERSION}"
rm -f "/usr/share/libalpm/hooks/zz-matebook-e-dsi-initramfs.hook"

echo -e "\n${BOLD}[3/3] Cập nhật lại initramfs về driver i915 gốc của hệ thống...${NC}"
if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u -k all
elif command -v mkinitcpio >/dev/null 2>&1; then
    mkinitcpio -P
elif command -v dracut >/dev/null 2>&1; then
    dracut --regenerate-all --force
fi

echo -e "\n${GREEN}${BOLD}==================================================================${NC}"
echo -e "${GREEN}${BOLD}  ĐÃ GỠ BỎ THÀNH CÔNG! HỆ THỐNG ĐÃ TRỞ VỀ DRIVER I915 MẶC ĐỊNH.   ${NC}"
echo -e "${GREEN}${BOLD}==================================================================${NC}"
echo -e "Hãy khởi động lại máy: ${GREEN}sudo reboot${NC}\n"
