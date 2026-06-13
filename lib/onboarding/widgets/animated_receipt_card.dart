import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AnimatedReceiptCard extends StatefulWidget {
  const AnimatedReceiptCard({super.key, this.compact = false});

  final bool compact;

  @override
  State<AnimatedReceiptCard> createState() => _AnimatedReceiptCardState();
}

class _AnimatedReceiptCardState extends State<AnimatedReceiptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final height = widget.compact ? 170.0 : 220.0;
    final receipt = Container(
      width: widget.compact ? 170 : 210,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: colors.primaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bonny',
                  style: context.text.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ReceiptLine(widthFactor: 0.88),
          const SizedBox(height: 10),
          const _ReceiptLine(widthFactor: 0.62),
          const SizedBox(height: 10),
          const _ReceiptLine(widthFactor: 0.76),
          const Spacer(),
          Row(
            children: [
              Text('Total', style: context.text.labelMedium),
              const Spacer(),
              Text('€24.80', style: context.text.headlineMedium),
            ],
          ),
        ],
      ),
    );
    if (reduced) return receipt;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset =
            (Curves.easeInOut.transform(_controller.value) - 0.5) * 10;
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: receipt,
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: context.colors.secondarySurface,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
