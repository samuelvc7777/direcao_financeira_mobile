import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';

class SettingsProfileAvatar extends StatelessWidget {
  const SettingsProfileAvatar({
    super.key,
    required this.name,
    required this.photoBase64,
    required this.onTap,
    required this.isBusy,
  });

  final String name;
  final String? photoBase64;
  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.royalBlue.withValues(alpha: 0.92),
                      AppColors.royalBlue.withValues(alpha: 0.62),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _AvatarContent(
                    initials: initials.isEmpty ? 'SV' : initials,
                    photoBase64: photoBase64,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Icon(
                    isBusy ? Icons.hourglass_top_rounded : Icons.edit_rounded,
                    size: 13,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.initials,
    required this.photoBase64,
    required this.colorScheme,
  });

  final String initials;
  final String? photoBase64;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final photo = photoBase64?.trim();
    if (photo != null && photo.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(photo),
          fit: BoxFit.cover,
          width: 72,
          height: 72,
        );
      } catch (_) {
        // Se a foto armazenada estiver corrompida, voltamos para as iniciais.
      }
    }

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
