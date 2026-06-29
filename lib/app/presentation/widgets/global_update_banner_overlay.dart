import 'dart:ui';

import 'package:flutter/material.dart';

class GlobalUpdateBannerOverlay extends StatelessWidget {
  const GlobalUpdateBannerOverlay({
    super.key,
    required this.show,
    required this.child,
    required this.onUpdate,
    required this.onCancel,
    this.forceUpdate = false,
    this.badgeText = 'PLAY STORE',
  });

  final bool show;
  final Widget child;
  final VoidCallback onUpdate;
  final VoidCallback onCancel;
  final bool forceUpdate;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.62)),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: _UpdateBannerCard(
                    badgeText: badgeText.trim().isEmpty
                        ? 'PLAY STORE'
                        : badgeText.trim(),
                    forceUpdate: forceUpdate,
                    onUpdate: onUpdate,
                    onCancel: onCancel,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateBannerCard extends StatelessWidget {
  const _UpdateBannerCard({
    required this.badgeText,
    required this.forceUpdate,
    required this.onUpdate,
    required this.onCancel,
  });

  final String badgeText;
  final bool forceUpdate;
  final VoidCallback onUpdate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: Color(0xFF16A34A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Badge(text: badgeText),
                            Text(
                              'ATUALIZACAO RECOMENDADA',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nova versao disponivel',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Atualize para receber melhorias, correcoes importantes e mais estabilidade no Direcao Financeira.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onUpdate,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('ATUALIZAR AGORA'),
              ),
              if (!forceUpdate) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Agora nao'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'A atualizacao sera aberta pela Play Store. Voce pode continuar usando esta versao por enquanto.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF16A34A)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF15803D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
