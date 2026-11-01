#!/usr/bin/env bash
# ==============================================================================
# Script cài đặt DKMS Driver Huawei MateBook E 2023 DSI (Intel OLED Display)
# Hỗ trợ: Ubuntu, Debian, Linux Mint, Arch Linux, Fedora, Pop!_OS,...
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}==================================================================${NC}"
echo -e "${BLUE}${BOLD}   CÀI ĐẶT DRIVER MÀN HÌNH OLED DSI CHO HUAWEI MATEBOOK E 2023   ${NC}"
echo -e "${BLUE}${BOLD}==================================================================${NC}"

# 1. Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI] Vui lòng chạy script này với quyền root:${NC}"
    echo "  sudo ./install.sh"
    exit 1
fi

MODULE_NAME="matebook-e-dsi"
MODULE_VERSION="1.0.0"
SRC_DEST="/usr/src/${MODULE_NAME}-${MODULE_VERSION}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_VER="$(uname -r)"
KERNEL_MAJOR="$(echo "$KERNEL_VER" | cut -d. -f1)"
KERNEL_MINOR="$(echo "$KERNEL_VER" | cut -d. -f2)"

# 2. Kiểm tra phiên bản Kernel (Driver yêu cầu Linux Kernel 7.0+)
if [ "$KERNEL_MAJOR" -lt 7 ]; then
    echo -e "\n${YELLOW}${BOLD}[CẢNH BÁO TƯƠNG THÍCH KERNEL]${NC}"
    echo -e "Hệ thống đang chạy Kernel: ${RED}${KERNEL_VER}${NC}"
    echo "Module i915 patch DSI cho Huawei MateBook E 2023 yêu cầu ${GREEN}Linux Kernel 7.0 trở lên${NC}."
    echo "(Do cấu trúc Intel Display DRM đã thay đổi hoàn toàn từ Kernel 7.0,"
    echo " việc cố biên dịch trên Kernel 6.x như Linux Mint 22 / Ubuntu 24.04 sẽ bị lỗi 'bad exit status: 2')."
    echo ""
    echo -e "${BOLD}👉 HƯỚNG DẪN NÂNG CẤP LÊN KERNEL 7.0+ TRÊN UBUNTU / LINUX MINT:${NC}"
    echo "1. Cài đặt công cụ Mainline Kernel Installer:"
    echo "   sudo add-apt-repository -y ppa:cappelikan/ppa"
    echo "   sudo apt update && sudo apt install -y mainline"
    echo "2. Mở ứng dụng 'Mainline' -> Chọn cài đặt Kernel 7.0.x (hoặc mới nhất) -> Khởi động lại máy."
    echo "3. Sau khi boot vào Kernel 7.0+, chạy lại script này sẽ thành công 100%."
    echo ""
    read -rp "Bạn có muốn tiếp tục thử biên dịch trên kernel hiện tại không? [y/N]: " TRY_COMPILE
    TRY_COMPILE=${TRY_COMPILE:-N}
    if [[ ! "$TRY_COMPILE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Đã tạm dừng cài đặt driver màn hình. Hãy nâng cấp kernel và thử lại sau.${NC}"
        exit 2
    fi
fi

# 3. Kiểm tra mã nguồn trong thư mục gói
if [ ! -d "$DIR/src" ] || [ ! -f "$DIR/src/dkms.conf" ]; then
    echo -e "${RED}[LỖI] Không tìm thấy thư mục mã nguồn $DIR/src hợp lệ!${NC}"
    exit 1
fi

# 4. Tự động kiểm tra và cài đặt phụ thuộc (DKMS, Kernel Headers, Trình biên dịch)
echo -e "\n${BOLD}[1/6] Kiểm tra các gói phụ thuộc (DKMS, Kernel Headers, GCC)...${NC}"
HEADERS_DIR="/lib/modules/${KERNEL_VER}/build"

install_deps_debian() {
    echo "Phát hiện hệ điều hành họ Debian/Ubuntu..."
    apt-get update -y
    apt-get install -y dkms build-essential "linux-headers-${KERNEL_VER}" || apt-get install -y dkms build-essential linux-headers-generic
}

install_deps_arch() {
    echo "Phát hiện hệ điều hành họ Arch Linux..."
    pacman -Sy --noconfirm --needed dkms base-devel linux-headers
}

install_deps_fedora() {
    echo "Phát hiện hệ điều hành họ Fedora/RHEL..."
    dnf install -y dkms "kernel-devel-${KERNEL_VER}" "kernel-headers-${KERNEL_VER}" gcc make || dnf install -y dkms kernel-devel kernel-headers gcc make
}

if ! command -v dkms >/dev/null 2>&1 || [ ! -d "$HEADERS_DIR" ] || ! command -v make >/dev/null 2>&1; then
    echo -e "${YELLOW}Đang tiến hành cài đặt phụ thuộc hệ thống...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        install_deps_debian
    elif command -v pacman >/dev/null 2>&1; then
        install_deps_arch
    elif command -v dnf >/dev/null 2>&1; then
        install_deps_fedora
    else
        echo -e "${YELLOW}[CẢNH BÁO] Không nhận diện được trình quản lý gói. Vui lòng đảm bảo dkms và linux-headers đã được cài đặt.${NC}"
    fi
fi

if [ ! -d "$HEADERS_DIR" ]; then
    echo -e "${RED}[LỖI] Không tìm thấy kernel headers tại ${HEADERS_DIR}!${NC}"
    echo "Vui lòng cài đặt kernel headers tương ứng với kernel đang chạy (${KERNEL_VER}) rồi chạy lại script."
    exit 1
fi
echo -e "${GREEN}✓ Các gói phụ thuộc và Kernel Headers đã sẵn sàng.${NC}"

# 5. Dọn dẹp bản đăng ký cũ trong DKMS (nếu có)
echo -e "\n${BOLD}[2/6] Dọn dẹp bản đăng ký cũ trong DKMS...${NC}"
dkms remove -m "${MODULE_NAME}/${MODULE_VERSION}" --all 2>/dev/null || true
rm -rf "${SRC_DEST}"

# 6. Sao chép mã nguồn vào /usr/src/
echo -e "\n${BOLD}[3/6] Sao chép mã nguồn driver vào ${SRC_DEST}...${NC}"
cp -r "$DIR/src" "${SRC_DEST}"
chmod -R 755 "${SRC_DEST}"

# 7. Đăng ký và biên dịch DKMS
echo -e "\n${BOLD}[4/6] Đăng ký module vào DKMS...${NC}"
dkms add -m "${MODULE_NAME}" -v "${MODULE_VERSION}"

echo -e "\n${BOLD}Đang biên dịch module i915 patch DSI cho kernel ${KERNEL_VER}...${NC}"
if ! dkms build -m "${MODULE_NAME}" -v "${MODULE_VERSION}"; then
    echo -e "\n${RED}${BOLD}==================================================================${NC}"
    echo -e "${RED}${BOLD}  BIÊN DỊCH MODULE THẤT BẠI TRÊN KERNEL: ${KERNEL_VER}           ${NC}"
    echo -e "${RED}${BOLD}==================================================================${NC}"
    
    MAKE_LOG="/var/lib/dkms/${MODULE_NAME}/${MODULE_VERSION}/build/make.log"
    if [ -f "$MAKE_LOG" ]; then
        echo -e "\n${YELLOW}=== 15 dòng lỗi cuối cùng từ make.log ===${NC}"
        tail -n 15 "$MAKE_LOG"
        echo -e "${YELLOW}=========================================${NC}"
    fi

    echo -e "\n${BOLD}[NGUYÊN NHÂN]:${NC}"
    echo "Kernel ${KERNEL_VER} không tương thích với mã nguồn driver i915 này (yêu cầu Kernel 7.0+)."
    echo ""
    echo -e "${BOLD}[GIẢI PHÁP KHẮC PHỤC]:${NC}"
    echo "Nâng cấp lên Linux Kernel 7.0+ bằng Mainline Kernel Installer:"
    echo "  sudo add-apt-repository -y ppa:cappelikan/ppa"
    echo "  sudo apt update && sudo apt install -y mainline"
    echo "Mở ứng dụng Mainline, chọn cài Kernel 7.0.x và khởi động lại máy."
    
    # Dọn dẹp module lỗi
    dkms remove -m "${MODULE_NAME}/${MODULE_VERSION}" --all 2>/dev/null || true
    rm -rf "${SRC_DEST}"
    exit 2
fi

echo -e "\n${BOLD}[5/6] Cài đặt module i915 mới vào kernel ${KERNEL_VER}...${NC}"
dkms install -m "${MODULE_NAME}" -v "${MODULE_VERSION}" --force

# Cài đặt pacman hook cho Arch Linux nếu có thư mục hooks
if [ -d "/usr/share/libalpm/hooks" ] && [ -f "$DIR/zz-matebook-e-dsi-initramfs.hook" ]; then
    echo "Cài đặt pacman hook zz-matebook-e-dsi-initramfs.hook..."
    cp "$DIR/zz-matebook-e-dsi-initramfs.hook" "/usr/share/libalpm/hooks/"
fi

# 8. Cập nhật initramfs
echo -e "\n${BOLD}[6/6] Cập nhật initramfs...${NC}"
if command -v update-initramfs >/dev/null 2>&1; then
    echo "-> Đang thực thi: update-initramfs -u -k all"
    update-initramfs -u -k all
elif command -v mkinitcpio >/dev/null 2>&1; then
    echo "-> Đang thực thi: mkinitcpio -P"
    mkinitcpio -P
elif command -v dracut >/dev/null 2>&1; then
    echo "-> Đang thực thi: dracut --regenerate-all --force"
    dracut --regenerate-all --force
else
    echo -e "${YELLOW}[CẢNH BÁO] Không tìm thấy update-initramfs / mkinitcpio / dracut. Hãy cập nhật initramfs thủ công!${NC}"
fi

echo -e "\n${GREEN}${BOLD}==================================================================${NC}"
echo -e "${GREEN}${BOLD}  CÀI ĐẶT THÀNH CÔNG DRIVER MATEBOOK E DSI (INTEL OLED)!         ${NC}"
echo -e "${GREEN}${BOLD}==================================================================${NC}"

# Kiểm tra cảnh báo nomodeset
if grep -q "nomodeset" /etc/default/grub 2>/dev/null; then
    echo -e "\n${YELLOW}${BOLD}[LƯU Ý CỰC KỲ QUAN TRỌNG VỀ GRUB]${NC}"
    echo -e "Phát hiện tham số ${RED}'nomodeset'${NC} trong /etc/default/grub."
    echo "Nếu bạn đã thêm tùy chọn này để cứu hộ màn hình đen trước đó,"
    echo "hãy XÓA 'nomodeset' khỏi /etc/default/grub rồi chạy:"
    echo "    sudo update-grub"
    echo "thì driver i915 mới kích hoạt được màn hình OLED khi khởi động!"
fi

echo -e "\n${BOLD}Bây giờ bạn hãy khởi động lại máy để áp dụng:${NC}"
echo -e "    ${GREEN}sudo reboot${NC}\n"
