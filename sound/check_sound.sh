#!/usr/bin/env bash
# ==============================================================================
# Script kiểm tra thông số loa hiện tại của Huawei MateBook E 2023
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}==================================================================${NC}"
echo -e "${BLUE}${BOLD}   THÔNG SỐ ÂM THANH HIỆN TẠI - HUAWEI MATEBOOK E 2023           ${NC}"
echo -e "${BLUE}${BOLD}==================================================================${NC}"

# 1. Âm lượng Desktop PipeWire / PulseAudio
SYS_VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "N/A")
echo -e "\n${BOLD}1. Âm lượng hệ thống (PipeWire):${NC} ${GREEN}${SYS_VOL}${NC}"

# 2. Chi tiết ALSA DAC
TWEETER_INFO=$(amixer -c 0 sget Speaker 2>/dev/null | grep -m 1 "\[[0-9]*%\]" | sed 's/^[ \t]*//')
WOOFER_INFO=$(amixer -c 0 sget "Bass Speaker" 2>/dev/null | grep -m 1 "\[[0-9]*%\]" | sed 's/^[ \t]*//')

echo -e "\n${BOLD}2. Cụm Loa Tép Trên (Tweeters - DAC 0x22):${NC}"
echo -e "   -> ${TWEETER_INFO:-Không tìm thấy}"

echo -e "\n${BOLD}3. Cụm Loa Trầm Dưới (Bass Woofers - DAC 0x23):${NC}"
echo -e "   -> ${WOOFER_INFO:-Không tìm thấy}"

# 3. Đối soát đồng bộ
TWEETER_VAL=$(echo "$TWEETER_INFO" | grep -o "Playback [0-9]*" || echo "1")
WOOFER_VAL=$(echo "$WOOFER_INFO" | grep -o "Playback [0-9]*" || echo "2")

if [ "$TWEETER_VAL" = "$WOOFER_VAL" ] && [ -n "$TWEETER_VAL" ]; then
    echo -e "\n   ${GREEN}✓ Trạng thái: Cả 4 loa đang ĐỒNG BỘ 100% (Không bị lệch tiếng)${NC}"
else
    echo -e "\n   ${YELLOW}! Trạng thái: Cụm loa đang có sự chênh lệch mức âm lượng!${NC}"
fi

# 4. Trạng thái Daemon đồng bộ phần cứng
DAEMON_STATUS=$(systemctl is-active huawei-sound-daemon.service 2>/dev/null || echo "inactive")
echo -e "\n${BOLD}4. Dịch vụ tự động đồng bộ phần cứng (Daemon):${NC}"
if [ "$DAEMON_STATUS" = "active" ]; then
    echo -e "   -> ${GREEN}● Đang chạy (Active) - Tự động đồng bộ âm lượng 4 loa tức thời${NC}"
else
    echo -e "   -> ${YELLOW}○ Không chạy (${DAEMON_STATUS})${NC}"
fi

echo -e "\n${BLUE}==================================================================${NC}"
