#!/usr/bin/env bash
# ==============================================================================
# Script kiểm tra trạng thái driver Huawei MateBook E 2023 DSI (OLED Display)
# ==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}==================================================================${NC}"
echo -e "${BLUE}${BOLD}   KIỂM TRA TRẠNG THÁI DRIVER OLED DSI (HUAWEI MATEBOOK E 2023)  ${NC}"
echo -e "${BLUE}${BOLD}==================================================================${NC}"

KERNEL_VER="$(uname -r)"
echo -e "\n${BOLD}1. Kernel hiện tại:${NC} ${KERNEL_VER}"

# 1. Kiểm tra DKMS
echo -e "\n${BOLD}2. Trạng thái DKMS:${NC}"
DKMS_STATUS="$(dkms status 2>/dev/null | grep matebook-e-dsi || true)"
if [ -n "$DKMS_STATUS" ]; then
    echo -e "${GREEN}${DKMS_STATUS}${NC}"
else
    echo -e "${RED}[CHƯA CÀI ĐẶT] Không tìm thấy module matebook-e-dsi trong DKMS!${NC}"
fi

# 2. Kiểm tra checksum phiên bản module i915
echo -e "\n${BOLD}3. Đối soát phiên bản module i915 (Running vs Installed):${NC}"
RUNNING_VER="$(cat /sys/module/i915/srcversion 2>/dev/null || echo 'N/A')"
INSTALLED_VER="$(modinfo -F srcversion i915 2>/dev/null || echo 'N/A')"

echo "  - Running kernel i915 srcversion   : ${RUNNING_VER}"
echo "  - Installed disk i915 srcversion   : ${INSTALLED_VER}"

if [ "$RUNNING_VER" != "N/A" ] && [ "$RUNNING_VER" = "$INSTALLED_VER" ]; then
    echo -e "  -> ${GREEN}✓ Module i915 đang tải TRÙNG KHỚP với bản DKMS trên đĩa (Đã có patch DSI).${NC}"
else
    echo -e "  -> ${YELLOW}! Khác nhau hoặc chưa reboot. Nếu vừa cài xong, hãy khởi động lại máy.${NC}"
fi

# 3. Kiểm tra cổng màn hình DSI
echo -e "\n${BOLD}4. Trạng thái kết nối màn hình OLED DSI:${NC}"
DSI_PATH=$(ls /sys/class/drm/card*-DSI-1/status 2>/dev/null | head -n 1 || true)
if [ -n "$DSI_PATH" ]; then
    STATUS=$(cat "$DSI_PATH" 2>/dev/null || echo "unknown")
    if [ "$STATUS" = "connected" ]; then
        echo -e "  - Cổng DSI-1: ${GREEN}CONNECTED (Màn hình OLED đang hoạt động!)${NC}"
    else
        echo -e "  - Cổng DSI-1: ${YELLOW}${STATUS}${NC}"
    fi
else
    echo -e "  - ${YELLOW}Không tìm thấy cổng DSI-1 trong /sys/class/drm/.${NC}"
fi

# 4. Độ phân giải hiện tại (nếu trong X11/Wayland)
if command -v xrandr >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
    echo -e "\n${BOLD}5. Độ phân giải màn hình:${NC}"
    xrandr | grep -A 1 "DSI-1" || true
fi

echo -e "\n${BLUE}==================================================================${NC}"
