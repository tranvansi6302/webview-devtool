# EJSC WebView Bridge - Hướng dẫn Nhà phát triển (Official SDK)

Tài liệu đặc tả hệ thống **Bridge API** chuẩn hóa giữa Flutter (Native) và WebView (Mini App).

---

## 🛠️ Quy tắc Phản hồi chuẩn (Standard Response)

Tất cả các API được gọi qua SDK đều trả về một đối tượng JSON duy nhất. Định dạng này được đảm bảo đồng nhất từ tầng Native cho đến Mini App.

```json
{
  "success": true, 
  "data": { ... } // Chứa dữ liệu thực tế hoặc Error Object {code, message}
}
```

---

## 📋 Bảng tổng quan API (Quick Reference)

| Nhóm API          | Tên API                                          | Mô tả ngắn gọn                       |
| :----------------- | :------------------------------------------------ | :--------------------------------------- |
| **Location** | [`getLocation`](#getlocation)                      | Lấy tọa độ GPS (Kinh độ/Vĩ độ). |
|                    | [`getUserLocation`](#getuserlocation)              | Lấy tọa độ kèm địa chỉ thô.     |
|                    | [`openNativeMap`](#opennativemap)                  | Mở ứng dụng bản đồ gốc.           |
| **UI/UX**    | [`showToast`](#showtoast)                          | Hiển thị thông báo Toast.            |
|                    | [`alert` / `confirm`](#alert--confirm)           | Hộp thoại thông báo/xác nhận.      |
|                    | [`prompt`](#prompt)                                | Hộp thoại nhập văn bản.             |
|                    | [`showLoading`](#showloading--hideloading)         | Hiển thị hiệu ứng chờ.              |
|                    | [`showActionSheet`](#showactionsheet)              | Menu lựa chọn từ dưới lên.         |
|                    | [`triggerHapticFeedback`](#triggerhapticfeedback)  | Tạo rung phản hồi vật lý.           |
| **Nav**      | [`openDeeplink`](#opendeeplink)                    | Mở màn hình nội bộ Super App.       |
|                    | [`openPublicDeepLink`](#openpublicdeeplink)        | Mở liên kết URL bên ngoài.          |
|                    | [`shareApp`](#shareapp)                            | Chia sẻ Mini App.                       |
|                    | [`openInAppBrowser`](#openinappbrowser)            | Mở trình duyệt web trong app.         |
| **Media**    | [`chooseImage`](#chooseimage--choosemedia)         | Chọn/Chụp ảnh từ thiết bị.         |
|                    | [`previewImage`](#previewimage)                    | Xem ảnh toàn màn hình.               |
|                    | [`scan`](#scan)                                    | Quét mã QR / Barcode.                  |
|                    | [`addCalendarEvent`](#addcalendarevent)            | Thêm sự kiện vào lịch máy.         |
| **Security** | [`bioMetrics.isSupported`](#biometricsissupported) | Kiểm tra hỗ trợ sinh trắc học.      |
|                    | [`bioMetrics.localAuth`](#biometricslocalauth)     | Xác thực Vân tay/Khuôn mặt.         |

---

## 📘 Danh mục API chi tiết (API Reference)

### 1. Định vị & Bản đồ (Location Services)

#### `getLocation`

- **Mô tả**: Lấy tọa độ GPS hiện tại của thiết bị (Kinh độ & Vĩ độ).
- **Tham số (Input)**:
  - `type`: `0` (Wifi/Cellular), `1` (GPS).
  - Tùy chỉnh UI: `permissionTitle`, `permissionMessage`, `confirmText`, `cancelText`.
- **Kết quả trả về (Output)**:

```json
{
  "success": true, 
  "data": { "latitude": 21.0285, "longitude": 105.8542 }
}
```

#### `getUserLocation`

- **Mô tả**: Lấy tọa độ hiện tại kèm theo địa chỉ thô (Reverse Geocoding).
- **Tham số (Input)**:
  - `enableHighAccuracy`: `true` để bật GPS chính xác cao.
  - `fallbackAddress`: Địa chỉ mặc định hiển thị nếu lỗi.
- **Kết quả trả về (Output)**:

```json
{
  "success": true, 
  "data": {
    "lat": 21.0285, "lng": 105.8542, 
    "address": "Hoàn Kiếm, Hà Nội"
  }
}
```

#### `openNativeMap`

- **Mô tả**: Mở ứng dụng bản đồ gốc (Google/Apple Maps).
- **Tham số (Input)**:
  - `lat`, `lng` hoặc `address`.
  - `label`: Nhãn hiển thị vị trí.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

### 2. Tương tác & Giao diện (Interaction)

#### `showToast`

- **Mô tả**: Hiển thị thông báo ngắn tự động biến mất.
- **Tham số (Input)**: `content`, `type`, `position`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

#### `alert` / `confirm`

- **Mô tả**: Hiển thị hộp thoại thông báo hoặc xác nhận.
- **Tham số (Input)**: `title`, `content`, `confirmButtonText`, `cancelButtonText`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {"confirm": true}}
```

#### `prompt`

- **Mô tả**: Hiển thị hộp thoại yêu cầu nhập văn bản.
- **Tham số (Input)**: `title`, `placeholder`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {"ok": true, "inputValue": "..."}}
```

#### `showLoading` / `hideLoading`

- **Mô tả**: Hiển thị hoặc ẩn vòng xoay chờ.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

#### `showActionSheet`

- **Mô tả**: Hiển thị menu chọn lựa từ dưới lên.
- **Tham số (Input)**: `items`, `destructiveBtnIndex`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {"index": 0}}
```

#### `triggerHapticFeedback`

- **Mô tả**: Tạo hiệu ứng rung phản hồi vật lý.
- **Tham số (Input)**: `style`: `success`, `error`, `light`, `medium`, `heavy`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

### 3. Điều hướng (Navigation)

#### `openDeeplink`

- **Mô tả**: Điều hướng tới màn hình Native nội bộ.
- **Tham số (Input)**: `url` (ejsc://...), `title`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

#### `openPublicDeepLink`

- **Mô tả**: Mở liên kết URL bên ngoài.
- **Tham số (Input)**: `url`, `inAppBrowser`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

#### `shareApp`

- **Mô tả**: Mở trình chia sẻ của hệ thống.
- **Tham số (Input)**: `title`, `description`, `url`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

#### `openInAppBrowser`

- **Mô tả**: Mở trình duyệt web trong app.
- **Tham số (Input)**: `url`, `errorMessage`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

### 4. Thiết bị & Phương tiện (Media & Device)

#### `chooseImage` / `chooseMedia`

- **Mô tả**: Chọn ảnh/video từ thư viện hoặc Camera.
- **Tham số (Input)**: `count`, `sourceType`, `imageQuality`.
- **Kết quả trả về (Output)**:

```json
{
  "success": true, 
  "data": { "filePaths": ["..."], "tempFilePaths": ["..."] }
}
```

#### `previewImage`

- **Mô tả**: Xem ảnh toàn màn hình.
- **Tham số (Input)**: `urls`, `current`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

#### `scan`

- **Mô tả**: Mở camera để quét mã QR Code.
- **Tham số (Input)**: `title`, `hintText`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {"result": "..."}}
```

#### `addCalendarEvent`

- **Mô tả**: Thêm sự kiện vào ứng dụng Lịch.
- **Tham số (Input)**: `title`, `startDate`, `endDate`, `location`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

### 5. Bảo mật Sinh trắc học (Biometric)

#### `bioMetrics.isSupported`

- **Mô tả**: Kiểm tra hỗ trợ Vân tay/Khuôn mặt.
- **Kết quả trả về (Output)**:

```json
{
  "success": true, 
  "data": { "isSupported": true, "mode": ["fingerprint", "face"] }
}
```

#### `bioMetrics.localAuth`

- **Mô tả**: Xác thực người dùng bằng sinh trắc học.
- **Tham số (Input)**: `content`.
- **Kết quả trả về (Output)**:

```json
{"success": true, "data": {}}
```

---

## 📂 Cấu trúc dự án Native (Dành cho Maintainer)

### 🚀 Thành phần Cốt lõi

- `lib/bridge/bridge_manager.dart`: Điều phối tin nhắn Web <-> Native.
- `lib/bridge/bridge_injector.dart`: Tiêm JS SDK (`window.ejsc`) vào WebView.
- `lib/bridge/handlers/`: Toàn bộ logic thực thi của các API (mỗi file là một nhóm).

---

## 🎨 Cấu hình Tràn viền (Edge-to-Edge)

Để WebView hiển thị tràn viền (phía dưới Status Bar), cấu hình trong `lib/main.dart`:

```dart
SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ),
);
```

---

> [!IMPORTANT]
> **Xử lý lỗi**: Nếu `success: false`, `data` sẽ chứa mã lỗi chuẩn:

```json
{ 
  "success": false, 
  "data": { 
    "code": "PERMISSION_DENIED", 
    "message": "Người dùng từ chối quyền truy cập." 
  } 
}
```

### ⚠️ Danh sách Mã lỗi chuẩn (Error Codes)

- `PERMISSION_DENIED`: Từ chối cấp quyền truy cập.
- `USER_CANCELLED`: Người dùng chủ động hủy bỏ thao tác.
- `NOT_SUPPORTED`: Thiết bị không có phần cứng hỗ trợ.
- `INVALID_PARAMS`: Tham số truyền vào không đúng định dạng.
- `STORAGE_ERROR`: Lỗi liên quan đến bộ nhớ (đầy, không thể ghi).
- `UNKNOWN_ERROR`: Các lỗi phát sinh chưa được định nghĩa.

---

## 💤 Thành phần phụ trợ chỉ phục vụ quá trình phát triển (Development & Helpers)

Trong quá trình phát triển, các thành phần sau hỗ trợ hạ tầng và giao diện phụ:

- **`lib/main.dart`**: Khởi tạo ứng dụng, cấu hình Theme và splash screen.
- **`lib/screens/landing_screen.dart`**: Giao diện nhập IP Simulator và quản lý lịch sử kết nối.
- **`lib/bridge/nav_sync_service.dart`**: Dịch vụ đồng bộ hóa điều hướng (Navigation Sync) phục vụ gỡ lỗi.
- **`lib/bridge/native_logger.dart`**: Hệ thống Logger in ra Terminal với màu sắc phân biệt theo cấp độ (Info/Warn/Error).
- **`lib/utils/` & `lib/widgets/`**: Các widget tiện ích dùng chung như Scanner Overlay, Error View, và Loading View.

---
