import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../config/app_theme.dart';

/// User Avatar Widget
/// Displays user avatar with automatic fallback to initials on error
/// Handles network errors gracefully (e.g., 403 Forbidden from Firebase Storage)
class UserAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _imageLoadError = false;

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state if avatar URL changes
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _imageLoadError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = widget.avatarUrl != null &&
                       widget.avatarUrl!.isNotEmpty &&
                       !_imageLoadError;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? AppTheme.primaryColor,
      backgroundImage: hasValidUrl
          ? NetworkImage(widget.avatarUrl!)
          : null,
      onBackgroundImageError: hasValidUrl
          ? (exception, stackTrace) {
              // Handle image load errors (e.g., 403 Forbidden)
              // Use post-frame callback to avoid setState during build/paint
              print('Avatar image load error: $exception');
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _imageLoadError = true;
                  });
                }
              });
            }
          : null,
      child: !hasValidUrl
          ? Text(
              _getInitials(widget.fallbackText),
              style: TextStyle(
                fontSize: widget.fontSize ?? widget.radius * 0.8,
                color: widget.textColor ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  /// Extract initials from name (first letter of first and last name)
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
