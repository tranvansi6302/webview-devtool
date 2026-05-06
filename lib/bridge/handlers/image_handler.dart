import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import '../bridge_manager.dart';
import '../native_logger.dart';
import '../bridge_constants.dart';

/**
 * Handler xử lý các tác vụ liên quan đến hình ảnh.
 */
class ImageBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'chooseImage';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final List<dynamic> sourceTypeList =
        params['sourceType'] ?? ['album', 'camera'];
    final int count = params['count'] ?? 1;

    NativeLogger.info('Yêu cầu chọn ảnh: count=$count, source=$sourceTypeList');

    ImageSource? source;
    // Nếu chỉ có một nguồn (camera hoặc album), mở trực tiếp.
    // Nếu có cả hai, hiển thị menu chọn cho người dùng.
    if (sourceTypeList.length == 1) {
      source = sourceTypeList.first == 'camera'
          ? ImageSource.camera
          : ImageSource.gallery;
    } else {
      source = await _showSourcePicker(context, params);
    }

    if (source == null)
      throw BridgeException(
        BridgeError.userCancelled,
        'Người dùng đã hủy chọn ảnh.',
      );

    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      NativeLogger.info('Đang mở Camera...');
      // Chụp ảnh mới từ camera
      final file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: (params['maxWidth'] as num?)?.toDouble() ?? 1280,
        maxHeight: (params['maxHeight'] as num?)?.toDouble() ?? 1280,
        imageQuality: params['imageQuality'] ?? params['quality'] ?? 85,
      );
      if (file != null) NativeLogger.info('Chụp ảnh thành công: ${file.path}');
      return await _processFile(file);
    } else {
      if (count > 1) {
        NativeLogger.info('Đang mở Thư viện (nhiều ảnh)...');
        // Chọn nhiều ảnh từ thư viện
        final List<XFile> files = await picker.pickMultiImage(
          maxWidth: (params['maxWidth'] as num?)?.toDouble() ?? 1280,
          maxHeight: (params['maxHeight'] as num?)?.toDouble() ?? 1280,
          imageQuality: params['imageQuality'] ?? params['quality'] ?? 85,
        );
        NativeLogger.info('Đã chọn ${files.length} ảnh');
        if (files.isEmpty)
          throw BridgeException(
            BridgeError.userCancelled,
            'Người dùng đã hủy chọn ảnh.',
          );
        final List<Map<String, dynamic>> result = [];
        for (var f in files) {
          result.add(await _fileToMap(f));
        }
        return {
          'tempFilePaths': result.map((e) => e['path']).toList(),
          'tempFiles': result,
        };
      } else {
        NativeLogger.info('Đang mở Thư viện (1 ảnh)...');
        // Chọn một ảnh duy nhất từ thư viện
        final file = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: (params['maxWidth'] as num?)?.toDouble() ?? 1280,
          maxHeight: (params['maxHeight'] as num?)?.toDouble() ?? 1280,
          imageQuality: params['imageQuality'] ?? params['quality'] ?? 85,
        );
        return await _processFile(file);
      }
    }
  }

  /** Hiển thị menu chọn nguồn ảnh/video chuyên nghiệp */
  Future<ImageSource?> _showSourcePicker(BuildContext context, Map<String, dynamic> params) {
    final double customFontSize = (params['fontSize'] as num?)?.toDouble() ?? 13.0;
    final double customItemHeight = (params['itemHeight'] as num?)?.toDouble() ?? 40.0;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 35,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (params['title'] != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    params['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: customFontSize + 2,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.blue, size: customFontSize + 5),
                ),
                title: Text(
                  params['cameraText'] ?? 'Chụp ảnh',
                  style: TextStyle(fontSize: customFontSize, fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded, color: Colors.orange, size: customFontSize + 5),
                ),
                title: Text(
                  params['albumText'] ?? 'Chọn từ thư viện',
                  style: TextStyle(fontSize: customFontSize, fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const Divider(height: 12),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(
                  params['cancelText'] ?? 'Hủy bỏ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent, 
                    fontWeight: FontWeight.bold,
                    fontSize: customFontSize,
                  ),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  /** Xử lý tệp tin sau khi chọn và đóng gói vào định dạng trả về */
  Future<Map<String, dynamic>> _processFile(XFile? file) async {
    if (file == null)
      throw BridgeException(
        BridgeError.userCancelled,
        'Người dùng đã hủy chọn ảnh.',
      );
    final data = await _fileToMap(file);
    return {
      'tempFilePaths': [data['path']],
      'tempFiles': [data],
    };
  }

  /** Chuyển đổi XFile sang Map chứa thông tin chi tiết và dữ liệu Base64 */
  Future<Map<String, dynamic>> _fileToMap(XFile file) async {
    Uint8List bytes = await file.readAsBytes();
    int size = bytes.length;
    final extension = file.path.split('.').last.toLowerCase();

    // Nếu tệp tin vẫn quá lớn (> 3MB), thực hiện nén cưỡng bức để đảm bảo hiệu năng truyền tải
    if (size > 3 * 1024 * 1024) {
      NativeLogger.info(
        'File quá lớn (${(size / 1024 / 1024).toStringAsFixed(2)}MB), bắt đầu nén cưỡng bức...',
      );
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        // Giảm kích thước xuống tối đa 1024px
        final resized = img.copyResize(decoded, width: 1024);
        bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 75));
        size = bytes.length;
        NativeLogger.info(
          'Nén thành công: ${(size / 1024 / 1024).toStringAsFixed(2)}MB',
        );
      }
    }

    final base64Data = base64Encode(bytes);

    // Xác định MIME type dựa trên phần mở rộng tệp
    String mimeType = 'image/jpeg';
    if (extension == 'png') mimeType = 'image/png';
    if (extension == 'gif') mimeType = 'image/gif';
    if (extension == 'webp') mimeType = 'image/webp';

    return {
      'path': file.path, // Đường dẫn tuyệt đối trên máy
      'size': size, // Dung lượng (bytes)
      'name': file.name, // Tên tệp
      'lastModified':
          DateTime.now().millisecondsSinceEpoch, // Thời gian sửa đổi cuối
      'base64': 'data:$mimeType;base64,$base64Data', // Dữ liệu ảnh dạng Base64
      'fileType': 'image', // Loại tệp
    };
  }
}

class CaptureImageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'captureImage';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: params['quality'] ?? 85,
    );

    if (file == null)
      throw BridgeException(
        BridgeError.userCancelled,
        'Người dùng đã hủy chụp ảnh.',
      );

    // Sử dụng chung logic xử lý từ ImageBridgeHandler (copy lại hoặc gọi static)
    // Để đơn giản tôi sẽ copy lại logic xử lý cơ bản
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    return {'path': file.path, 'base64': 'data:image/jpeg;base64,$base64Data'};
  }
}

class MediaBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'chooseMedia';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final List mediaType = params['mediaType'] ?? ['image'];
    final List sourceType = params['sourceType'] ?? ['album'];

    ImageSource? source;
    if (sourceType.length == 1) {
      source = sourceType.first == 'camera'
          ? ImageSource.camera
          : ImageSource.gallery;
    } else {
      source = await ImageBridgeHandler()._showSourcePicker(context, params);
    }

    if (source == null)
      throw BridgeException(BridgeError.userCancelled, 'Người dùng đã hủy.');

    // NATIVE MEDIA PICKER HANDLES PERMISSIONS AUTOMATICALLY

    final int maxDuration = params['maxDuration'] ?? 60; // Mặc định 60 giây

    final picker = ImagePicker();
    if (mediaType.contains('video')) {
      NativeLogger.info('Đang chọn Video (maxDuration: ${maxDuration}s)...');
      final file = await picker.pickVideo(
        source: source,
        maxDuration: Duration(seconds: maxDuration),
      );
      if (file == null)
        throw BridgeException(BridgeError.userCancelled, 'Người dùng đã hủy.');

      final int size = await file.length();
      NativeLogger.info(
        'Đã chọn Video: ${file.path} (${(size / 1024 / 1024).toStringAsFixed(2)}MB)',
      );

      return {
        'tempFilePaths': [file.path],
        'tempFiles': [
          {
            'path': file.path,
            'fileType': 'video',
            'size': size,
            'name': file.name,
            'lastModified': DateTime.now().millisecondsSinceEpoch,
          },
        ],
      };
    } else {
      if (source == ImageSource.camera) {
        final file = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: (params['maxWidth'] as num?)?.toDouble() ?? 1280,
          maxHeight: (params['maxHeight'] as num?)?.toDouble() ?? 1280,
          imageQuality: params['imageQuality'] ?? params['quality'] ?? 85,
        );
        if (file == null)
          throw BridgeException(
            BridgeError.userCancelled,
            'Người dùng đã hủy.',
          );
        final data = await _fileToMap(file);
        return {
          'tempFilePaths': [data['path']],
          'tempFiles': [data],
        };
      } else {
        final files = await picker.pickMultiImage(
          maxWidth: (params['maxWidth'] as num?)?.toDouble() ?? 1280,
          maxHeight: (params['maxHeight'] as num?)?.toDouble() ?? 1280,
          imageQuality: params['imageQuality'] ?? params['quality'] ?? 85,
        );
        if (files.isEmpty)
          throw BridgeException(
            BridgeError.userCancelled,
            'Người dùng đã hủy.',
          );
        final List<Map<String, dynamic>> tempFiles = [];
        for (var f in files) {
          tempFiles.add(await _fileToMap(f));
        }
        return {
          'tempFilePaths': tempFiles.map((e) => e['path']).toList(),
          'tempFiles': tempFiles,
        };
      }
    }
  }

  Future<Map<String, dynamic>> _fileToMap(XFile file) async {
    Uint8List bytes = await file.readAsBytes();
    int size = bytes.length;
    final extension = file.path.split('.').last.toLowerCase();

    // Nếu file vẫn > 3MB, tiến hành nén cưỡng bức bằng thư viện 'image'
    if (size > 3 * 1024 * 1024) {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 1024);
        bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 75));
        size = bytes.length;
      }
    }

    final base64Data = base64Encode(bytes);
    String mimeType = 'image/jpeg';
    if (extension == 'png') mimeType = 'image/png';

    return {
      'path': file.path,
      'size': size,
      'name': file.name,
      'lastModified': DateTime.now().millisecondsSinceEpoch,
      'base64': 'data:$mimeType;base64,$base64Data',
      'fileType': 'image',
    };
  }
}

class PreviewImageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'previewImage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final List<String> urls = List<String>.from(params['urls'] ?? []);
    final int current = params['current'] ?? 0;
    final String title = params['title'] ?? 'Xem ảnh';

    if (urls.isEmpty) throw BridgeException(BridgeError.invalidParams, 'Danh sách urls không được để trống.');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImagePreviewScreen(
          urls: urls,
          initialIndex: current,
          title: title,
        ),
      ),
    );
    return {'success': true};
  }
}

class _ImagePreviewScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String title;

  const _ImagePreviewScreen({
    required this.urls,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.title} (${_currentIndex + 1}/${widget.urls.length})',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final url = widget.urls[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: url.startsWith('http') 
                ? NetworkImage(url) 
                : FileImage(File(url)) as ImageProvider,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: url),
          );
        },
        itemCount: widget.urls.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class SaveImageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'saveImage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String url = params['url'] ?? '';
    if (url.isEmpty) throw BridgeException(BridgeError.invalidParams, 'URL không được để trống.');

    // Kiểm tra quyền lưu ảnh
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final request = await Gal.requestAccess();
      if (!request) {
        final openSettings = await _showPermissionDialog(
          context,
          message: params['permissionMessage'] ?? 'Ứng dụng cần quyền truy cập Thư viện ảnh để lưu ảnh. Vui lòng cấp quyền trong Cài đặt.',
          title: params['permissionTitle'],
          cancelText: params['cancelText'],
          confirmText: params['confirmText'],
        );
        if (openSettings) {
          await openAppSettings();
        }
        throw BridgeException(BridgeError.permissionDenied, params['deniedMessage'] ?? 'Bạn cần cấp quyền truy cập thư viện để lưu ảnh');
      }
    }

    try {
      final response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(response.data);
      await Gal.putImageBytes(bytes);
      return {'success': true};
    } catch (e) {
      throw BridgeException(BridgeError.internalError, 'Lỗi khi lưu ảnh: $e');
    }
  }

  Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String message,
    String? title,
    String? cancelText,
    String? confirmText,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title ?? 'Cấp quyền truy cập'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(cancelText ?? 'Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmText ?? 'Mở Cài đặt'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class GetImageInfoHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getImageInfo';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String src = params['src'] ?? '';
    if (src.isEmpty) throw BridgeException(BridgeError.invalidParams, 'Đường dẫn ảnh (src) không được để trống.');

    final File file = File(src);
    if (!await file.exists()) throw BridgeException(BridgeError.internalError, 'Không tìm thấy tệp tin ảnh.');

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw BridgeException(BridgeError.internalError, 'Không thể giải mã hình ảnh.');

    return {
      'width': image.width,
      'height': image.height,
      'type': src.split('.').last,
      'path': src,
    };
  }
}

class CompressImageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'compressImage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String src = params['src'] ?? '';
    final int quality = params['quality'] ?? 80;
    
    if (src.isEmpty) throw BridgeException(BridgeError.invalidParams, 'Đường dẫn ảnh (src) không được để trống.');
    final file = File(src);
    if (!await file.exists()) throw BridgeException(BridgeError.internalError, 'Không tìm thấy tệp tin ảnh.');

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw BridgeException(BridgeError.internalError, 'Không thể giải mã hình ảnh.');

    final compressedBytes = img.encodeJpg(image, quality: quality);
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return {
      'tempFilePath': tempFile.path,
      'size': compressedBytes.length,
    };
  }
}
