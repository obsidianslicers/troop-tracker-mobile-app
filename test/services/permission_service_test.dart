import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tt_mobile_app/services/permission_service.dart';

class _FakePermissions extends Fake
    with MockPlatformInterfaceMixin
    implements PermissionHandlerPlatform {
  PermissionStatus status = PermissionStatus.granted;
  final List<Permission> requested = [];
  int settingsOpened = 0;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    requested.addAll(permissions);
    return {for (final permission in permissions) permission: status};
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }
}

void main() {
  late _FakePermissions permissions;

  setUp(() => PermissionHandlerPlatform.instance = permissions = _FakePermissions());

  test('requestCamera asks for the camera and reports a grant', () async {
    expect(await PermissionService.requestCamera(), isTrue);
    expect(permissions.requested, [Permission.camera]);
  });

  test('requestCamera reports a denial', () async {
    permissions.status = PermissionStatus.denied;

    expect(await PermissionService.requestCamera(), isFalse);
  });

  test('requestPhotos asks for the photo library and reports a grant', () async {
    expect(await PermissionService.requestPhotos(), isTrue);
    expect(permissions.requested, [Permission.photos]);
  });

  test('requestPhotos reports a permanent denial', () async {
    permissions.status = PermissionStatus.permanentlyDenied;

    expect(await PermissionService.requestPhotos(), isFalse);
  });

  test('openSettings opens the app settings', () async {
    await PermissionService.openSettings();

    expect(permissions.settingsOpened, 1);
  });
}
