import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PetAvatar extends StatelessWidget {
  final String? imagePath;
  final String species;
  final double size;
  final double borderRadius;
  final bool allowPreview;

  const PetAvatar({
    super.key,
    required this.species,
    this.imagePath,
    this.size = 48,
    this.borderRadius = 14,
    this.allowPreview = false,
  });

  static const Map<String, IconData> avatarIcons = {
    'avatar:dog': Icons.pets,
    'avatar:cat': Icons.cruelty_free,
    'avatar:bird': Icons.flutter_dash,
    'avatar:rabbit': Icons.pest_control_rodent,
    'avatar:fish': Icons.water,
    'avatar:turtle': Icons.shield_outlined,
    'avatar:star': Icons.star_border,
    'avatar:favorite': Icons.favorite_border,
  };

  void _showImagePreview(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                file,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    final isCustomFile = imagePath != null &&
        !imagePath!.startsWith('avatar:') &&
        imagePath!.isNotEmpty;

    if (isCustomFile) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        content = GestureDetector(
          onTap: allowPreview ? () => _showImagePreview(context, file) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallback(context),
            ),
          ),
        );
      } else {
        content = _buildFallback(context);
      }
    } else if (imagePath != null && imagePath!.startsWith('avatar:')) {
      final icon = avatarIcons[imagePath] ?? Icons.pets;
      content = Center(
        child: Icon(
          icon,
          size: size * 0.52,
          color: AppColors.txt(context),
        ),
      );
    } else {
      content = _buildFallback(context);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfElevated(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.brd(context),
          width: 1.2,
        ),
      ),
      child: content,
    );
  }

  Widget _buildFallback(BuildContext context) {
    IconData icon;
    switch (species.toLowerCase()) {
      case 'dog':
        icon = Icons.pets;
        break;
      case 'cat':
        icon = Icons.cruelty_free;
        break;
      case 'bird':
        icon = Icons.flutter_dash;
        break;
      case 'rabbit':
        icon = Icons.pest_control_rodent;
        break;
      case 'fish':
        icon = Icons.water;
        break;
      default:
        icon = Icons.pets;
    }

    return Center(
      child: Icon(
        icon,
        size: size * 0.52,
        color: AppColors.txt(context),
      ),
    );
  }
}
