import 'package:flutter/material.dart';

import '../../domain/entities/help_video_entity.dart';

enum PremiumPlan { monthly, yearly }

class PremiumAccessBanner extends StatefulWidget {
  const PremiumAccessBanner({
    super.key,
    required this.onViewSubscription,
    this.onStartTrial,
    this.onRestoreSubscription,
    this.demoVideo,
    this.onWatchDemoVideo,
  });

  final VoidCallback onViewSubscription;
  final ValueChanged<PremiumPlan>? onStartTrial;
  final VoidCallback? onRestoreSubscription;
  final HelpVideoEntity? demoVideo;
  final VoidCallback? onWatchDemoVideo;

  @override
  State<PremiumAccessBanner> createState() => _PremiumAccessBannerState();
}

class _PremiumAccessBannerState extends State<PremiumAccessBanner> {
  PremiumPlan selectedPlan = PremiumPlan.monthly;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth <= 360 ? 12.0 : 18.0;
          final availableWidth = constraints.maxWidth - horizontalPadding * 2;
          final cardWidth = availableWidth < 260
              ? 260.0
              : (availableWidth > 430 ? 430.0 : availableWidth);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              12 + (bottomPadding == 0 ? 0 : 4),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: cardWidth,
                  child: _PremiumTrialCard(
                    selectedPlan: selectedPlan,
                    onSelectPlan: (plan) {
                      setState(() {
                        selectedPlan = plan;
                      });
                    },
                    onStartTrial: widget.onStartTrial == null
                        ? null
                        : () => widget.onStartTrial!(selectedPlan),
                    onViewPlans: widget.onViewSubscription,
                    onRestoreSubscription: widget.onRestoreSubscription,
                    demoVideo: widget.demoVideo,
                    onWatchDemoVideo: widget.onWatchDemoVideo,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumTrialCard extends StatelessWidget {
  const _PremiumTrialCard({
    required this.selectedPlan,
    required this.onSelectPlan,
    required this.onViewPlans,
    this.onStartTrial,
    this.onRestoreSubscription,
    this.demoVideo,
    this.onWatchDemoVideo,
  });

  final PremiumPlan selectedPlan;
  final ValueChanged<PremiumPlan> onSelectPlan;
  final VoidCallback? onStartTrial;
  final VoidCallback onViewPlans;
  final VoidCallback? onRestoreSubscription;
  final HelpVideoEntity? demoVideo;
  final VoidCallback? onWatchDemoVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(31),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF030712)],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFF94A3B8).withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 86,
            offset: const Offset(0, 34),
          ),
          BoxShadow(
            color: const Color(0xFF4361EE).withValues(alpha: 0.12),
            blurRadius: 42,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _CardGlowDecorations()),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TopPremiumRow(),
              const SizedBox(height: 16),
              const _TrialHero(),
              if (demoVideo != null) ...[
                const SizedBox(height: 14),
                _DemoVideoPreview(video: demoVideo!, onTap: onWatchDemoVideo),
              ],
              const SizedBox(height: 16),
              const _PlansHeader(),
              const SizedBox(height: 10),
              _PlanTile(
                title: 'Mensal',
                description: 'Ideal para começar sem compromisso.',
                price: 'R\$ 24,99',
                period: '/mês',
                selected: selectedPlan == PremiumPlan.monthly,
                onTap: () => onSelectPlan(PremiumPlan.monthly),
              ),
              const SizedBox(height: 10),
              _PlanTile(
                title: 'Anual',
                description: 'Também começa com 7 dias grátis.',
                price: 'R\$ 249,00',
                period: '/ano',
                badge: 'MELHOR VALOR',
                selected: selectedPlan == PremiumPlan.yearly,
                onTap: () => onSelectPlan(PremiumPlan.yearly),
              ),
              const SizedBox(height: 16),
              const _FeatureList(),
              const SizedBox(height: 18),
              _StartTrialButton(onPressed: onStartTrial),
              const SizedBox(height: 12),
              _SecondaryActionsRow(
                onViewPlans: onViewPlans,
                onRestoreSubscription: onRestoreSubscription,
              ),
              const SizedBox(height: 13),
              Text(
                'Usuários novos têm 7 dias grátis. Depois, continuam no plano escolhido: R\$ 24,99/mês ou R\$ 249,00/ano.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 11.2,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoVideoPreview extends StatelessWidget {
  const _DemoVideoPreview({required this.video, required this.onTap});

  final HelpVideoEntity video;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                const Color(0xFF4361EE).withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF93C5FD).withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      video.resolvedThumbnailUrl,
                      width: 118,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 118,
                        height: 74,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      width: 118,
                      height: 74,
                      color: Colors.black.withValues(alpha: 0.26),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF111827),
                        size: 31,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veja o app em acao',
                      style: TextStyle(
                        color: const Color(0xFF93C5FD).withValues(alpha: 0.92),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Toque para assistir ao video demonstrativo.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardGlowDecorations extends StatelessWidget {
  const _CardGlowDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -75,
          top: -75,
          child: _GlowCircle(
            size: 178,
            color: const Color(0xFF4361EE).withValues(alpha: 0.055),
            borderColor: const Color(0xFF4361EE).withValues(alpha: 0.20),
          ),
        ),
        Positioned(
          left: -30,
          top: -40,
          child: _GlowCircle(
            size: 170,
            color: const Color(0xFF4361EE).withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          right: -40,
          bottom: -40,
          child: _GlowCircle(
            size: 160,
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
    this.borderColor,
  });

  final double size;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
    );
  }
}

class _TopPremiumRow extends StatelessWidget {
  const _TopPremiumRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4361EE).withValues(alpha: 0.22),
                const Color(0xFF10B981).withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFAEBBFF),
            size: 27,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD6A93A).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFD6A93A).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6A93A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD6A93A).withValues(alpha: 0.55),
                      blurRadius: 14,
                    ),
                    BoxShadow(
                      color: const Color(0xFFD6A93A).withValues(alpha: 0.09),
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PREMIUM',
                style: TextStyle(
                  color: Color(0xFFE8C66B),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrialHero extends StatelessWidget {
  const _TrialHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.16),
            const Color(0xFF4361EE).withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF5EEAD4).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF72F0C4),
                size: 16,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'TESTE GRÁTIS PARA NOVOS USUÁRIOS',
                  style: TextStyle(
                    color: Color(0xFF72F0C4),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            '7 dias grátis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Comece agora, explore todos os recursos premium e escolha o melhor plano para continuar depois.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansHeader extends StatelessWidget {
  const _PlansHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Escolha seu plano',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'ambos com teste grátis',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.44),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.description,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String description;
  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      const Color(0xFF4361EE).withValues(alpha: 0.18),
                      const Color(0xFF4361EE).withValues(alpha: 0.07),
                    ],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.045),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6366F1).withValues(alpha: 0.44)
                  : const Color(0xFF94A3B8).withValues(alpha: 0.13),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _PlanRadio(selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.48),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        period,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -10,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanRadio extends StatelessWidget {
  const _PlanRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFF4361EE) : Colors.transparent,
        border: Border.all(
          color: selected
              ? const Color(0xFF8EA2FF)
              : Colors.white.withValues(alpha: 0.22),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FeatureItem(
          text: 'Controle completo de corridas, ganhos, cartões e despesas.',
        ),
        SizedBox(height: 11),
        _FeatureItem(
          text: 'Dados salvos com segurança mesmo durante o bloqueio.',
        ),
        SizedBox(height: 11),
        _FeatureItem(text: 'Cancele quando quiser antes do teste acabar.'),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.16),
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF75EFC2),
            size: 15,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 13.5,
              height: 1.32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartTrialButton extends StatelessWidget {
  const _StartTrialButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.22),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
          ),
          child: const Text(
            'COMEÇAR TESTE GRÁTIS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionsRow extends StatelessWidget {
  const _SecondaryActionsRow({
    required this.onViewPlans,
    required this.onRestoreSubscription,
  });

  final VoidCallback onViewPlans;
  final VoidCallback? onRestoreSubscription;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TextActionButton(label: 'Ver planos', onTap: onViewPlans),
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
        ),
        _TextActionButton(
          label: 'Já tenho assinatura',
          onTap: onRestoreSubscription,
        ),
      ],
    );
  }
}

class _TextActionButton extends StatelessWidget {
  const _TextActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.56),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
