import 'dart:io';
import 'package:flutter/material.dart';

/// Resolve URL dengan base API jika perlu
String? resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  return url;
}

/// CircleAvatar foto profil yang aman.
/// - Ada foto: coba load network/file image; kalau gagal/404 otomatis fallback ke asset
/// - Tidak ada foto: langsung pakai Image.asset (tidak bisa gagal diam-diam)
class ProfileAvatar extends StatefulWidget {
  final double radius;
  final String? photoPath;
  final String fallbackAsset;

  const ProfileAvatar({
    super.key,
    required this.radius,
    this.photoPath,
    this.fallbackAsset = 'assets/icons/profile_empty.png',
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _imageError = false;

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) {
      _imageError = false;
    }
  }

  bool get _hasPhoto =>
      widget.photoPath != null && widget.photoPath!.isNotEmpty;

  ImageProvider<Object>? get _imageProvider {
    if (!_hasPhoto) return null;
    if (widget.photoPath!.startsWith('http')) return NetworkImage(widget.photoPath!);
    if (File(widget.photoPath!).existsSync()) return FileImage(File(widget.photoPath!));
    return null;
  }

  Widget _fallback() => CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.asset(
            widget.fallbackAsset,
            width: widget.radius * 2,
            height: widget.radius * 2,
            fit: BoxFit.cover,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_imageError) return _fallback();

    final provider = _imageProvider;
    if (provider == null) return _fallback();

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: provider,
      onBackgroundImageError: (_, __) {
        if (mounted) setState(() => _imageError = true);
      },
    );
  }
}

/// Evict URL dari Flutter image cache (panggil saat foto dihapus/diganti)
void evictImageCache(String? url) {
  if (url == null || !url.startsWith('http')) return;
  PaintingBinding.instance.imageCache.evict(NetworkImage(url));
}
