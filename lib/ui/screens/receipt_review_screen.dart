import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/bonny_app.dart';
import '../../models/draft_receipt.dart';
import '../../models/receipt.dart';
import '../../models/receipt_import_queue.dart';
import '../../services/retry_analysis_service.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import '../components/formatters.dart';
import '../components/stat_widgets.dart';

class ReceiptReviewScreen extends StatefulWidget {
  const ReceiptReviewScreen({
    super.key,
    required this.draft,
    this.queue,
    this.extractionError,
    this.onConfirm,
    this.onSkip,
    this.onRetry,
    this.onCancelQueue,
  });

  final DraftReceipt draft;
  final ReceiptImportQueue? queue;
  final String? extractionError;
  final Future<bool> Function(Receipt receipt)? onConfirm;
  final Future<void> Function()? onSkip;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onCancelQueue;

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late DraftReceipt _currentDraft;
  late final TextEditingController _merchant;
  late final TextEditingController _currency;
  late final TextEditingController _total;
  late DateTime _date;
  late List<ReceiptItem> _items;
  late bool _showExtractionError;
  bool _saving = false;
  bool _retrying = false;
  bool _hasUnsavedManualEdits = false;

  bool get _isQueueMode => widget.queue != null;

  @override
  void initState() {
    super.initState();
    _currentDraft = widget.draft;
    _merchant = TextEditingController(text: _currentDraft.merchant);
    _currency = TextEditingController(text: _currentDraft.currency);
    _total = TextEditingController(
      text: _currentDraft.receiptTotal == 0
          ? ''
          : _currentDraft.receiptTotal.toStringAsFixed(2),
    );
    _merchant.addListener(_markEdited);
    _currency.addListener(_markEdited);
    _total.addListener(_markEdited);
    _date = _currentDraft.purchaseDate;
    _items = [..._currentDraft.items];
    _showExtractionError = widget.extractionError != null;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _currency.dispose();
    _total.dispose();
    super.dispose();
  }

  void _markEdited() {
    if (!_hasUnsavedManualEdits) {
      setState(() => _hasUnsavedManualEdits = true);
    }
  }

  ReceiptTotals get _totals => calculateTotals(_items);

  double get _receiptTotal {
    return _parseDouble(_total.text) ?? _totals.total;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final app = AppStateScope.of(context);
    final receipt = Receipt.create(
      imagePath: _currentDraft.imagePath,
      merchant: _merchant.text,
      purchaseDate: _date,
      currency: _currency.text,
      receiptTotal: _receiptTotal,
      items: _items,
    );
    await app.logManualEdit(
      action: 'confirm_save',
      before: _draftJson(),
      after: receipt.toJson(),
    );
    try {
      if (widget.onConfirm != null) {
        final saved = await widget.onConfirm!(receipt);
        if (!saved && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not save this receipt. Try again or skip.'),
            ),
          );
        }
        return;
      }
      await app.saveReceipt(receipt);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receipt saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    if (_retrying) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() {
        _date = date;
        _hasUnsavedManualEdits = true;
      });
    }
  }

  Future<void> _editItem([ReceiptItem? item]) async {
    if (_retrying) return;
    final app = AppStateScope.of(context);
    final edited = await showModalBottomSheet<ReceiptItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemEditor(item: item),
    );
    if (edited == null) return;
    final withRules = app.applyExclusionRules([edited]).first;
    final before = item?.toJson() ?? <String, dynamic>{};
    var after = withRules.toJson();
    setState(() {
      if (item == null) {
        _items.add(withRules);
      } else {
        final index = _items.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          _items[index] = withRules.copyWith(id: item.id);
          after = _items[index].toJson();
        }
      }
      _hasUnsavedManualEdits = true;
    });
    await app.logManualEdit(
      action: item == null ? 'add_item' : 'edit_item',
      before: before,
      after: after,
    );
  }

  Future<void> _toggleItem(ReceiptItem item, bool reimbursable) async {
    if (_retrying) return;
    final app = AppStateScope.of(context);
    final before = item.toJson();
    Map<String, dynamic> after = {};
    setState(() {
      final index = _items.indexWhere((entry) => entry.id == item.id);
      if (index >= 0) {
        _items[index] = item.copyWith(
          reimbursable: reimbursable,
          excludeReason: reimbursable ? null : 'Manual exclusion',
          clearExcludeReason: reimbursable,
        );
        after = _items[index].toJson();
        _hasUnsavedManualEdits = true;
      }
    });
    await app.logManualEdit(
      action: 'toggle_item',
      before: before,
      after: after,
    );
  }

  Future<void> _deleteItem(ReceiptItem item) async {
    if (_retrying) return;
    final app = AppStateScope.of(context);
    setState(() {
      _items.removeWhere((entry) => entry.id == item.id);
      _hasUnsavedManualEdits = true;
    });
    await app.logManualEdit(
      action: 'delete_item',
      before: item.toJson(),
      after: {},
    );
  }

  Map<String, dynamic> _draftJson() {
    return {
      'imagePath': _currentDraft.imagePath,
      'merchant': _currentDraft.merchant,
      'purchaseDate': _currentDraft.purchaseDate.toIso8601String(),
      'currency': _currentDraft.currency,
      'receiptTotal': _currentDraft.receiptTotal,
      'items': _currentDraft.items.map((item) => item.toJson()).toList(),
      'extractionId': _currentDraft.extractionId,
    };
  }

  Future<void> _retryAnalysis({RetrySource? source}) async {
    if (_retrying) return;
    final app = AppStateScope.of(context);
    if (_hasUnsavedManualEdits) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Retry analysis?'),
          content: const Text(
            'Retrying will replace the current AI draft and may discard your edits. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Retry Anyway'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _retrying = true);
    final queue = widget.queue;
    final draft = await app.retryAnalysis(
      imagePath: _currentDraft.imagePath,
      source:
          source ??
          (queue == null ? RetrySource.singleReview : RetrySource.queueReview),
      oldDraft: _currentDraft,
      queueId: queue?.id,
      queueIndex: queue?.currentIndex,
      queueTotal: queue?.totalCount,
      retryOfExtractionId: _currentDraft.extractionId,
    );
    if (!mounted) return;
    if (draft == null) {
      setState(() => _retrying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retry failed. Your current draft was not changed.'),
        ),
      );
      return;
    }
    _replaceDraft(draft);
    setState(() => _retrying = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Analysis refreshed')));
  }

  void _replaceDraft(DraftReceipt draft) {
    _currentDraft = draft;
    _merchant.text = draft.merchant;
    _currency.text = draft.currency;
    _total.text = draft.receiptTotal == 0
        ? ''
        : draft.receiptTotal.toStringAsFixed(2);
    _date = draft.purchaseDate;
    _items = [...draft.items];
    _showExtractionError = false;
    _hasUnsavedManualEdits = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final queue = widget.queue;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 112),
          children: [
            AppHeader(
              title: 'Review Receipt',
              subtitle: _isQueueMode
                  ? 'Check this receipt before continuing.'
                  : 'Review before saving',
              trailing: _isQueueMode
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded),
                      onSelected: (value) {
                        if (value == 'cancel') _confirmCancelQueue();
                        if (value == 'retry') _retryAnalysis();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'retry',
                          child: Text('Retry with AI'),
                        ),
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancel Import'),
                        ),
                      ],
                    )
                  : PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded),
                      onSelected: (value) {
                        if (value == 'retry') _retryAnalysis();
                        if (value == 'close') Navigator.of(context).pop();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'retry',
                          child: Text('Retry with AI'),
                        ),
                        PopupMenuItem(value: 'close', child: Text('Cancel')),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  if (queue != null) ...[
                    _QueueProgress(queue: queue),
                    const SizedBox(height: 18),
                  ],
                  if (_showExtractionError) ...[
                    _ExtractionErrorCard(
                      message: widget.extractionError!,
                      onRetry: () => _retryAnalysis(
                        source: widget.queue == null
                            ? RetrySource.failedState
                            : RetrySource.failedState,
                      ),
                      onEditManually: () {
                        setState(() => _showExtractionError = false);
                      },
                      onSkip: widget.onSkip,
                      onCancelQueue: widget.onCancelQueue,
                      retrying: _retrying,
                      isQueueMode: _isQueueMode,
                    ),
                    const SizedBox(height: 18),
                  ],
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      color: colors.secondarySurface,
                      child: _currentDraft.imagePath.isEmpty
                          ? Icon(
                              Icons.receipt_long_rounded,
                              size: 56,
                              color: colors.mutedText,
                            )
                          : Image.file(
                              File(_currentDraft.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.receipt_long_rounded,
                                size: 56,
                                color: colors.mutedText,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  BonnyCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _merchant,
                          enabled: !_retrying,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Merchant',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _retrying ? null : _pickDate,
                                borderRadius: BorderRadius.circular(16),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date',
                                  ),
                                  child: Text(
                                    DateFormat.yMMMd().format(_date),
                                    style: context.text.bodyLarge,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 112,
                              child: TextField(
                                controller: _currency,
                                enabled: !_retrying,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _total,
                          enabled: !_retrying,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Receipt Total',
                          ),
                          onChanged: (_) => setState(() {
                            _hasUnsavedManualEdits = true;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BonnyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          title: 'Items',
                          action: IconButton.filledTonal(
                            onPressed: _retrying ? null : () => _editItem(),
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Add item',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No items yet. Add them manually.',
                                style: context.text.bodyMedium,
                              ),
                            ),
                          )
                        else
                          for (final item in _items)
                            _ItemRow(
                              item: item,
                              currency: _currency.text.trim().isEmpty
                                  ? 'EUR'
                                  : _currency.text.trim(),
                              onTap: () => _editItem(item),
                              onDelete: () {
                                _deleteItem(item);
                              },
                              onToggle: (value) {
                                _toggleItem(item, value);
                              },
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BonnyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: 'Calculated Totals'),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.86,
                          children: [
                            StatTile(
                              label: 'Receipt',
                              value: money(_receiptTotal, _currency.text),
                            ),
                            StatTile(
                              label: 'Included',
                              value: money(
                                _totals.reimbursable,
                                _currency.text,
                              ),
                              accent: colors.secondaryAccent,
                            ),
                            StatTile(
                              label: 'Excluded',
                              value: money(_totals.excluded, _currency.text),
                              accent: colors.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 8, 22, 18),
        child: _retrying
            ? const _RetryLoadingFooter()
            : _isQueueMode
            ? Row(
                children: [
                  _FooterIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Retry analysis',
                    onPressed: _saving ? null : () => _retryAnalysis(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FooterIconButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Skip receipt',
                    onPressed: _saving ? null : widget.onSkip,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        widget.queue!.isLast
                            ? 'Save & Finish'
                            : 'Save & Continue',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _retryAnalysis(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Analysis'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Confirm and Save'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmCancelQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel import?'),
        content: const Text('Already saved receipts will stay saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Import'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onCancelQueue?.call();
  }
}

class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            side: BorderSide(color: context.colors.border),
            foregroundColor: context.colors.primaryText,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _QueueProgress extends StatelessWidget {
  const _QueueProgress({required this.queue});

  final ReceiptImportQueue queue;

  @override
  Widget build(BuildContext context) {
    return BonnyCard(
      padding: const EdgeInsets.all(16),
      color: context.colors.cardTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            queue.progressLabel.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: context.colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: queue.progressPercent,
              minHeight: 8,
              backgroundColor: context.colors.secondarySurface,
              valueColor: AlwaysStoppedAnimation(context.colors.primaryAccent),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < queue.totalCount; i++)
                _ProgressDot(
                  label: '${i + 1}',
                  state: i < queue.currentIndex
                      ? _DotState.done
                      : i == queue.currentIndex
                      ? _DotState.current
                      : _DotState.pending,
                ),
            ],
          ),
          if ((queue.retryCountsByImagePath[queue.currentImagePath] ?? 0) >
              3) ...[
            const SizedBox(height: 12),
            Text(
              'This receipt has been retried several times. Consider editing manually.',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _DotState { done, current, pending }

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.label, required this.state});

  final String label;
  final _DotState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCurrent = state == _DotState.current;
    final isDone = state == _DotState.done;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCurrent
            ? colors.primaryAccent
            : isDone
            ? colors.secondaryAccent.withValues(alpha: 0.16)
            : colors.secondarySurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isCurrent
              ? colors.primaryAccent
              : isDone
              ? colors.secondaryAccent
              : colors.border,
        ),
      ),
      child: Text(
        label,
        style: context.text.labelMedium?.copyWith(
          color: isCurrent ? colors.inverseText : colors.primaryText,
        ),
      ),
    );
  }
}

class _ExtractionErrorCard extends StatelessWidget {
  const _ExtractionErrorCard({
    required this.message,
    required this.onEditManually,
    this.onRetry,
    this.onSkip,
    this.onCancelQueue,
    this.retrying = false,
    this.isQueueMode = false,
  });

  final String message;
  final VoidCallback onEditManually;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onSkip;
  final Future<void> Function()? onCancelQueue;
  final bool retrying;
  final bool isQueueMode;

  @override
  Widget build(BuildContext context) {
    return BonnyCard(
      borderColor: context.colors.warning.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: context.colors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Extraction needs attention',
                  style: context.text.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: context.text.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: retrying ? null : onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retrying ? 'Retrying...' : 'Retry Analysis'),
              ),
              OutlinedButton.icon(
                onPressed: onEditManually,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Manually'),
              ),
              if (isQueueMode)
                OutlinedButton.icon(
                  onPressed: retrying ? null : onSkip,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Skip Receipt'),
                ),
              if (isQueueMode)
                TextButton(
                  onPressed: retrying ? null : onCancelQueue,
                  child: const Text('Cancel Import'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetryLoadingFooter extends StatelessWidget {
  const _RetryLoadingFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.secondarySurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: context.colors.primaryAccent,
            ),
          ),
          const SizedBox(width: 12),
          Text('Re-analyzing receipt...', style: context.text.bodyLarge),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.currency,
    required this.onTap,
    required this.onDelete,
    required this.onToggle,
  });

  final ReceiptItem item;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.secondarySurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.reimbursable
                  ? context.colors.border
                  : context.colors.warning.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.reimbursable
                    ? Icons.check_circle_rounded
                    : Icons.block_rounded,
                color: item.reimbursable
                    ? context.colors.secondaryAccent
                    : context.colors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.quantity != null)
                          '${item.quantity!.toStringAsFixed(item.quantity! % 1 == 0 ? 0 : 2)}x',
                        item.category ?? 'Other',
                        if (item.excludeReason != null) item.excludeReason!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                money(item.totalPrice, currency),
                style: context.text.bodyLarge,
              ),
              Switch.adaptive(
                value: item.reimbursable,
                onChanged: onToggle,
                activeTrackColor: context.colors.secondaryAccent,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete item',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({this.item});

  final ReceiptItem? item;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _totalPrice;
  late final TextEditingController _category;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _quantity = TextEditingController(text: item?.quantity?.toString() ?? '');
    _unitPrice = TextEditingController(
      text: item?.unitPrice?.toStringAsFixed(2) ?? '',
    );
    _totalPrice = TextEditingController(
      text: item?.totalPrice.toStringAsFixed(2) ?? '',
    );
    _category = TextEditingController(text: item?.category ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    _totalPrice.dispose();
    _category.dispose();
    super.dispose();
  }

  void _save() {
    final item = ReceiptItem.create(
      name: _name.text,
      quantity: _parseDouble(_quantity.text),
      unitPrice: _parseDouble(_unitPrice.text),
      totalPrice: _parseDouble(_totalPrice.text),
      category: _category.text,
      reimbursable: widget.item?.reimbursable ?? true,
      excludeReason: widget.item?.excludeReason,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 68,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.colors.mutedText.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.item == null ? 'Add Item' : 'Edit Item',
                style: context.text.headlineMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Item name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit price',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _totalPrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Line total'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Save Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double? _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
