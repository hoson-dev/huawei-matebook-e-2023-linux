# Huawei MateBook E 2023 - Driver Màn Hình OLED MIPI DSI (Fix Lỗi Đen Màn Hình Trên Linux)

Bộ driver DKMS sửa lỗi **Đen màn hình (Black Screen)** trên máy tính bảng lai 2-trong-1 **Huawei MateBook E 2023 (DRR-W56 / DRR-WXX)** khi cài đặt Linux (Ubuntu, Debian, Fedora, Arch Linux, Linux Mint, Pop!_OS,...).

---

## 1. Nguyên nhân lỗi đen màn hình (Black Screen)

Màn hình OLED 12.6 inch (độ phân giải 3072x1920 @ 60/120Hz) trên Huawei MateBook E 2023 sử dụng giao tiếp **Intel MIPI DSI dual-link command mode**.

Kernel Linux mặc định (upstream) chưa có cấu hình panel timing và chuỗi khởi tạo xung nhịp riêng cho panel Huawei. Cụ thể hàm `gen11_dsi_deconfigure_transcoder()` trong driver `i915` tắt cờ `DSI_PERIODIC_FRAME_UPDATE_ENABLE` khi khởi tạo nhưng không bật lại, khiến panel OLED không nhận được khung hình và màn hình tắt ngúm (tối đen hoàn toàn), mặc dù máy vẫn đang chạy bình thường.

Bộ driver này sử dụng cơ chế **DKMS** (Dynamic Kernel Module Support) để thay thế module `i915.ko`, khôi phục chuỗi cập nhật khung hình định kỳ và khởi tạo chính xác cổng `DSI-1`. Nhờ DKMS, driver sẽ tự động biên dịch lại mỗi khi hệ thống cập nhật kernel mới.

---

## 2. Cách truy cập vào máy khi màn hình đang bị đen

Nếu bạn vừa cài đặt Linux và màn hình máy đang bị đen hoàn toàn, hãy chọn 1 trong 3 cách sau để truy cập vào hệ thống trước khi cài đặt:

### Cách 1: Dùng màn hình ngoài qua cổng Type-C (Nhanh & Tiện nhất)
- Cắm máy vào màn hình rời hoặc TV qua cáp USB-C / HDMI Hub. 
- Màn hình ngoài sẽ hiển thị bình thường. Bạn chỉ cần mở Terminal trên màn hình ngoài để thao tác.

### Cách 2: Khởi động tạm thời với tùy chọn `nomodeset` trong GRUB
1. Khởi động lại máy, giữ phím `Shift` hoặc `Esc` để hiện menu GRUB (nếu GRUB không tự hiện).
2. Tại dòng Linux đầu tiên, nhấn phím **`e`** trên bàn phím để chỉnh sửa cấu hình boot.
3. Tìm dòng bắt đầu bằng `linux` (thường kết thúc bằng `quiet splash`).
4. Thêm dấu cách và gõ `nomodeset` vào cuối dòng đó.
   - Ví dụ: `... quiet splash nomodeset`
5. Nhấn **`F10`** (hoặc `Ctrl + X`) để boot vào hệ thống. Màn hình máy sẽ sáng lên ở chế độ đồ họa an toàn (framebuffer cơ bản).

> **LƯU Ý:** `nomodeset` chỉ là giải pháp tạm thời để vào máy cứu hộ. Sau khi cài xong driver DKMS này, bạn **CẦN XOÁ** `nomodeset` khỏi `/etc/default/grub` (nếu có thêm vào đó) để driver i915 mới kích hoạt được màn hình OLED.

### Cách 3: Truy cập từ xa qua SSH
- Nếu máy đã kết nối Wi-Fi/mạng LAN, bạn có thể dùng điện thoại hoặc một máy tính khác SSH vào máy để thực thi lệnh.

---

## 3. Cài đặt Driver (1-Click Tự Động)

Mở Terminal trong thư mục `matebook-e-dsi-dkms` và chạy script cài đặt tự động:

```bash
cd matebook-e-dsi-dkms
sudo ./install.sh
```

### Script cài đặt sẽ tự động:
1. Phát hiện hệ điều hành (Ubuntu/Debian, Arch Linux, Fedora, v.v.).
2. Tự động tải và cài đặt các phụ thuộc cần thiết (`dkms`, `build-essential`, `linux-headers-$(uname -r)`).
3. Đăng ký mã nguồn vào `/usr/src/matebook-e-dsi-1.0.0/`.
4. Biên dịch module `i915` đã được vá lỗi DSI.
5. Cài đặt module vào kernel đang sử dụng.
6. Tự động cập nhật `initramfs` (qua `update-initramfs`, `mkinitcpio`, hoặc `dracut`).

Sau khi cài đặt thành công, khởi động lại máy:
```bash
sudo reboot
```

Màn hình OLED 3072x1920 sẽ sáng lên và hoạt động hoàn hảo!

---

## 4. Kiểm tra trạng thái hoạt động

Sau khi khởi động lại, bạn có thể kiểm tra trạng thái hoạt động của driver bất kỳ lúc nào bằng lệnh:

```bash
./check_status.sh
```

Lệnh sẽ hiển thị:
- Trạng thái DKMS (`installed`)
- Đối soát mã checksum `srcversion` giữa module đang chạy và bản DKMS trên đĩa
- Trạng thái kết nối màn hình OLED (`DSI-1 connected`)
- Độ phân giải hiện tại (3072x1920)

---

## 5. Gỡ bỏ driver (Khôi phục driver gốc)

Nếu bạn muốn gỡ bỏ driver và đưa hệ thống quay lại driver gốc của Linux:

```bash
sudo ./uninstall.sh
sudo reboot
```

---

## 6. Cấu trúc thư mục

```text
matebook-e-dsi-dkms/
├── install.sh                     # Script cài đặt tự động 1-click
├── uninstall.sh                   # Script gỡ bỏ sạch sẽ
├── check_status.sh                # Script kiểm tra trạng thái driver & cổng DSI-1
├── README.md                      # Hướng dẫn chi tiết
├── matebook-e-dsi.patch           # Patch DSI cho driver i915
├── PKGBUILD                       # File đóng gói cho Arch Linux
├── zz-matebook-e-dsi-initramfs.hook # Pacman hook tái tạo initramfs cho Arch
└── src/                           # Toàn bộ mã nguồn driver i915 đã patch
    ├── Makefile
    ├── dkms.conf
    └── drivers/
        ├── gpu/drm/i915/
        └── platform/x86/intel_ips.h
```

---

## Tham khảo & Lời cảm ơn
- Patch dựa trên nghiên cứu và chia sẻ của cộng đồng Arch Linux cho MateBook E 2023 (DRR-W56): [Arch Linux Forum Thread #303555](https://bbs.archlinux.org/viewtopic.php?id=303555).
