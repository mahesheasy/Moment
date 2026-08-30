import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum SetupPermissionKind { camera, photos, contacts, notifications }

class SetupPermissionItem {
  const SetupPermissionItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final SetupPermissionKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class AppPermissionsService {
  const AppPermissionsService();

  static const items = [
    SetupPermissionItem(
      kind: SetupPermissionKind.camera,
      title: 'Camera Access',
      subtitle: 'To capture and share moments.',
      icon: Icons.photo_camera_rounded,
      color: Color(0xFFFF2D78),
    ),
    SetupPermissionItem(
      kind: SetupPermissionKind.photos,
      title: 'Gallery Access',
      subtitle: 'To access your photos and videos.',
      icon: Icons.photo_library_rounded,
      color: Color(0xFF9B5CFF),
    ),
    SetupPermissionItem(
      kind: SetupPermissionKind.contacts,
      title: 'Contacts Access',
      subtitle: 'To find and connect with friends.',
      icon: Icons.contacts_rounded,
      color: Color(0xFF2ED8C3),
    ),
    SetupPermissionItem(
      kind: SetupPermissionKind.notifications,
      title: 'Notifications Access',
      subtitle: 'To send you pings and updates.',
      icon: Icons.notifications_rounded,
      color: Color(0xFFFF8A3D),
    ),
  ];

  Future<PermissionStatus> request(SetupPermissionKind kind) async {
    switch (kind) {
      case SetupPermissionKind.camera:
        return Permission.camera.request();
      case SetupPermissionKind.photos:
        if (Platform.isAndroid) {
          final photos = await Permission.photos.request();
          if (photos.isGranted || photos.isLimited) return photos;
          return Permission.storage.request();
        }
        return Permission.photos.request();
      case SetupPermissionKind.contacts:
        return Permission.contacts.request();
      case SetupPermissionKind.notifications:
        return Permission.notification.request();
    }
  }

  Future<bool> isGranted(SetupPermissionKind kind) async {
    switch (kind) {
      case SetupPermissionKind.camera:
        return Permission.camera.isGranted;
      case SetupPermissionKind.photos:
        if (Platform.isAndroid) {
          final photos = await Permission.photos.status;
          if (photos.isGranted || photos.isLimited) return true;
          return Permission.storage.isGranted;
        }
        final status = await Permission.photos.status;
        return status.isGranted || status.isLimited;
      case SetupPermissionKind.contacts:
        return Permission.contacts.isGranted;
      case SetupPermissionKind.notifications:
        return Permission.notification.isGranted;
    }
  }
}
