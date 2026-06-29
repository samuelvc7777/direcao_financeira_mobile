import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.height = 64,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.obscureText = false,
    this.onTogglePassword,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final double height;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final VoidCallback? onTogglePassword;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refreshBorder);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_refreshBorder)
      ..dispose();
    super.dispose();
  }

  void _refreshBorder() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF);
    final borderColor = _focusNode.hasFocus
        ? accent
        : isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: _focusNode.hasFocus ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      textCapitalization: widget.textCapitalization,
                      textInputAction: widget.textInputAction,
                      onSubmitted: widget.onSubmitted,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        height: 1.1,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hint,
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onTogglePassword != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: widget.onTogglePassword,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 40,
                ),
                icon: Icon(
                  widget.obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  size: 21,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
