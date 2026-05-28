import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Botão com efeito de escala ao pressionar (micro-interação premium).
/// Usado para dar feedback tátil e visual ao usuário.
class ScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool enableHaptic;

  const ScaleButton({
    super.key,
    required this.onTap,
    required this.child,
    this.enableHaptic = true,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.enableHaptic) {
          HapticFeedback.lightImpact();
        }
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
