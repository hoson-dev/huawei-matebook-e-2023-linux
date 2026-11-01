#!/usr/bin/env bash
# ==============================================================================
# Script cài đặt tổng hợp Driver Huawei MateBook E 2023 trên Linux
# Bao gồm:
#   1. Driver Màn hình OLED DSI (Sửa lỗi đen màn hình)
#   2. Driver Âm thanh 4 Loa Stereo (Sửa lỗi mất tiếng / chỉ 2 loa)
# ==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}==================================================================${NC}"
echo -e "${BLUE}${BOLD}   TRÌNH CÀI ĐẶT DRIVER TỔNG HỢP - HUAWEI MATEBOOK E 2023        ${NC}"
echo -e "${BLUE}${BOLD}==================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI] Vui lòng chạy script này với quyền root:${NC}"
    echo "  sudo ./install-all.sh"
    exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\nChọn tác vụ cài đặt:"
echo "  1) Cài đặt TẤT CẢ (Màn hình OLED + Âm thanh 4 loa) [Khuyên dùng]"
echo "  2) Chỉ cài đặt Driver Màn hình OLED DSI (Fix đen màn hình - Yêu cầu Kernel 7.0+)"
echo "  3) Chỉ cài đặt Driver Âm thanh 4 Loa Stereo (Hoạt động trên mọi Kernel)"
echo "  4) Thoát"
read -rp "Lựa chọn của bạn [1-4] (Mặc định: 1): " CHOICE
CHOICE=${CHOICE:-1}

case "$CHOICE" in
    1)
        echo -e "\n${BOLD}===> [1/2] Đang cài đặt Driver Màn hình OLED DSI...${NC}"
        DISPLAY_STATUS=0
        bash "$DIR/display/install.sh" || DISPLAY_STATUS=$?

        if [ "$DISPLAY_STATUS" -ne 0 ]; then
            echo -e "\n${YELLOW}------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}[LƯU Ý] Driver Màn hình tạm thời chưa cài được do cần Kernel 7.0+.${NC}"
            echo -e "${YELLOW}------------------------------------------------------------------${NC}"
            read -rp "Bạn có muốn tiếp tục cài đặt Driver Âm thanh 4 Loa Stereo không? [Y/n]: " CONT
            CONT=${CONT:-Y}
            if [[ "$CONT" =~ ^[Yy]$ ]]; then
                echo -e "\n${BOLD}===> [2/2] Đang cài đặt Driver Âm thanh 4 Loa Stereo...${NC}"
                bash "$DIR/sound/install.sh"
            fi
        else
            echo -e "\n${BOLD}===> [2/2] Đang cài đặt Driver Âm thanh 4 Loa Stereo...${NC}"
            bash "$DIR/sound/install.sh"
            echo -e "\n${GREEN}${BOLD}==================================================================${NC}"
            echo -e "${GREEN}${BOLD}  HOÀN TẤT CÀI ĐẶT CẢ MÀN HÌNH VÀ ÂM THANH!                      ${NC}"
            echo -e "${GREEN}${BOLD}==================================================================${NC}"
            echo -e "Hãy khởi động lại máy để toàn bộ driver có hiệu lực:"
            echo -e "    ${GREEN}sudo reboot${NC}\n"
        fi
        ;;
    2)
        echo -e "\n${BOLD}===> Đang cài đặt Driver Màn hình OLED DSI...${NC}"
        bash "$DIR/display/install.sh"
        ;;
    3)
        echo -e "\n${BOLD}===> Đang cài đặt Driver Âm thanh 4 Loa Stereo...${NC}"
        bash "$DIR/sound/install.sh"
        ;;
    *)
        echo "Hủy bỏ."
        exit 0
        ;;
esac
