import 'package:permission_handler/permission_handler.dart';

/// Handles runtime permission requests for camera and photo library access.
/// These permissions are required when the user uploads a file via the WebView.
abstract final class PermissionService {
  /// Requests camera permission. Returns true if granted.
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Requests photo library access. Returns true if granted.
  /// On Android 13+ this maps to READ_MEDIA_IMAGES; on older versions,
  /// READ_EXTERNAL_STORAGE. permission_handler handles the difference.
  static Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Opens the OS app settings screen so the user can manually grant
  /// a permission that was previously denied.
  static Future<void> openSettings() => openAppSettings();
}
