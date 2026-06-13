import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class RuleTestCard extends StatefulWidget {
  const RuleTestCard({super.key, required this.keywords});

  final List<String> keywords;

  @override
  State<RuleTestCard> createState() => _RuleTestCardState();
}

class _RuleTestCardState extends State<RuleTestCard> {
  final _controller = TextEditingController(text: 'Fanta Orange 1L');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _match {
    final value = _controller.text.toLowerCase();
    for (final keyword in widget.keywords) {
      if (keyword.trim().isNotEmpty && value.contains(keyword.toLowerCase())) {
        return keyword;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final match = _match;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rule test', style: context.text.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Product name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (match == null ? colors.secondaryAccent : colors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  match == null
                      ? Icons.check_circle_rounded
                      : Icons.block_rounded,
                  color: match == null
                      ? colors.secondaryAccent
                      : colors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    match == null
                        ? 'Included by default'
                        : 'Excluded automatically. Matched keyword: $match',
                    style: context.text.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
