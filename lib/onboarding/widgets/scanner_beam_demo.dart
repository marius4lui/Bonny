import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ScannerBeamDemo extends StatefulWidget {
  const ScannerBeamDemo({super.key});

  @override
  State<ScannerBeamDemo> createState() => _ScannerBeamDemoState();
}

class _ScannerBeamDemoState extends State<ScannerBeamDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
    return Container(
      height: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.hero,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.heroSecondary),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.inverseText,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lidl',
                    style: context.text.titleLarge?.copyWith(
                      color: colors.hero,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final width in [92.0, 72.0, 104.0, 64.0])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: width,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.mutedText.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '€11.84',
                    style: context.text.headlineMedium?.copyWith(
                      color: colors.hero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!reduced)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Positioned(
                  left: 8,
                  right: 122,
                  top: 20 + _controller.value * 202,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.secondaryAccent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: colors.secondaryAccent.withValues(alpha: 0.65),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 148,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _ExtractedField(label: 'Merchant', value: 'Lidl'),
                  SizedBox(height: 10),
                  _ExtractedField(label: 'Total', value: '€11.84'),
                  SizedBox(height: 10),
                  _ExtractedField(label: 'Items', value: '10'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtractedField extends StatelessWidget {
  const _ExtractedField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.inverseText.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.inverseText.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: colors.mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.text.bodyLarge?.copyWith(color: colors.inverseText),
          ),
        ],
      ),
    );
  }
}
