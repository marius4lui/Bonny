import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ExclusionChipEditor extends StatefulWidget {
  const ExclusionChipEditor({
    super.key,
    required this.keywords,
    required this.onChanged,
  });

  final List<String> keywords;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ExclusionChipEditor> createState() => _ExclusionChipEditorState();
}

class _ExclusionChipEditorState extends State<ExclusionChipEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    final exists = widget.keywords.any(
      (entry) => entry.toLowerCase() == keyword.toLowerCase(),
    );
    if (!exists) widget.onChanged([...widget.keywords, keyword]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final keyword in widget.keywords)
                InputChip(
                  label: Text(keyword),
                  onDeleted: () => widget.onChanged(
                    widget.keywords.where((entry) => entry != keyword).toList(),
                  ),
                  backgroundColor: context.colors.secondarySurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add keyword',
                    prefixIcon: Icon(Icons.block_rounded),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add keyword',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
