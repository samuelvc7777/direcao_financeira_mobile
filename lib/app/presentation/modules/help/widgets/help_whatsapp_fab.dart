import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HelpWhatsAppFab extends StatelessWidget {
  const HelpWhatsAppFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'help-whatsapp-fab',
      onPressed: onPressed,
      backgroundColor: AppColors.emerald,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.chat_bubble_rounded),
      label: const Text(
        'WhatsApp',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
