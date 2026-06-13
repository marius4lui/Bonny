import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/bonny_app.dart';
import '../../models/debug_log.dart';
import '../../services/retry_analysis_service.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import '../components/empty_state.dart';
import 'receipt_review_screen.dart';

class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen> {
  final TextEditingController _queueFilter = TextEditingController();

  @override
  void dispose() {
    _queueFilter.dispose();
    super.dispose();
  }

  String? get _queueId =>
      _queueFilter.text.trim().isEmpty ? null : _queueFilter.text.trim();

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Debug Console',
                subtitle: app.settings.debugModeEnabled
                    ? 'Local diagnostics are enabled'
                    : 'Debug Mode is disabled',
                trailing: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _shareBundle(context),
                            icon: const Icon(Icons.ios_share_rounded),
                            label: const Text('Export Bundle'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () => _confirmClear(context),
                          icon: const Icon(Icons.delete_sweep_rounded),
                          tooltip: 'Clear debug logs',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _queueFilter,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Filter by queueId',
                        prefixIcon: Icon(Icons.filter_alt_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: context.colors.primaryAccent,
                unselectedLabelColor: context.colors.secondaryText,
                indicatorColor: context.colors.primaryAccent,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Requests'),
                  Tab(text: 'AI Extraction'),
                  Tab(text: 'Storage'),
                  Tab(text: 'Rules'),
                  Tab(text: 'Errors'),
                  Tab(text: 'Retries'),
                  Tab(text: 'App Info'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OverviewTab(queueId: _queueId),
                    _LogTab(
                      types: const [DebugLogType.request],
                      queueId: _queueId,
                      emptyTitle: 'No requests logged',
                      emptyMessage: 'OpenRouter calls will appear here.',
                      action: _CopyLatestButton(
                        label: 'Copy Failed',
                        icon: Icons.copy_rounded,
                        entry: app.debugLog.latestFailedRequest(),
                      ),
                    ),
                    _LogTab(
                      types: const [
                        DebugLogType.extraction,
                        DebugLogType.queueExtraction,
                      ],
                      queueId: _queueId,
                      emptyTitle: 'No extraction traces',
                      emptyMessage:
                          'Receipt extraction traces will appear here.',
                      action: _CopyLatestButton(
                        label: 'Copy Latest',
                        icon: Icons.copy_rounded,
                        entry: app.debugLog.latestExtraction(),
                      ),
                    ),
                    _LogTab(
                      types: const [DebugLogType.storage],
                      queueId: _queueId,
                      emptyTitle: 'No storage operations',
                      emptyMessage: 'Local reads and writes will appear here.',
                    ),
                    _LogTab(
                      types: const [DebugLogType.rule],
                      queueId: _queueId,
                      emptyTitle: 'No rule matches',
                      emptyMessage: 'Exclusion-rule matches will appear here.',
                    ),
                    _LogTab(
                      types: const [DebugLogType.error],
                      queueId: _queueId,
                      emptyTitle: 'No errors',
                      emptyMessage:
                          'Captured exceptions and stack traces will appear here.',
                      action: _CopyLatestButton(
                        label: 'Copy Latest',
                        icon: Icons.copy_rounded,
                        entry: app.debugLog.latestError(),
                      ),
                    ),
                    _RetryLogTab(queueId: _queueId),
                    _LogTab(
                      types: const [
                        DebugLogType.app,
                        DebugLogType.importQueue,
                        DebugLogType.queueReview,
                      ],
                      queueId: _queueId,
                      emptyTitle: 'No app info',
                      emptyMessage:
                          'App/session and queue lifecycle information will appear here.',
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

  Future<void> _shareBundle(BuildContext context) async {
    final app = AppStateScope.of(context);
    await SharePlus.instance.share(
      ShareParams(text: app.exportDebugBundle(), subject: 'Bonny debug bundle'),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final app = AppStateScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear debug logs?'),
        content: const Text(
          'This removes the local debug history from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await app.clearDebugLogs();
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({this.queueId});

  final String? queueId;

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final entries = app.debugEntries(queueId: queueId);
    final requests = app.debugEntries(
      type: DebugLogType.request,
      queueId: queueId,
    );
    final failures = entries.where((entry) => entry.isFailure).length;
    final extractions = app.debugEntries(
      types: const [DebugLogType.extraction, DebugLogType.queueExtraction],
      queueId: queueId,
    );
    final errors = app.debugEntries(type: DebugLogType.error, queueId: queueId);
    final queueEvents = app.debugEntries(
      types: const [DebugLogType.importQueue, DebugLogType.queueReview],
      queueId: queueId,
    );
    final retries = app.debugEntries(
      type: DebugLogType.retry,
      queueId: queueId,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
      children: [
        BonnyCard(
          color: context.colors.cardTint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Local Debug Mode', style: context.text.headlineMedium),
              const SizedBox(height: 8),
              Text(
                app.settings.debugModeEnabled
                    ? 'Diagnostics are stored locally and exported only when you share them.'
                    : 'Turn on Debug Mode in Settings to start logging.',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill('Entries', '${entries.length}'),
                  _MetricPill('Requests', '${requests.length}'),
                  _MetricPill('Extractions', '${extractions.length}'),
                  _MetricPill('Errors', '${errors.length}'),
                  _MetricPill('Failures', '$failures'),
                  _MetricPill('Queue', '${queueEvents.length}'),
                  _MetricPill('Retries', '${retries.length}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        BonnyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Onboarding State', style: context.text.titleLarge),
              const SizedBox(height: 12),
              _CheckLine(
                'onboardingCompleted: ${app.settings.onboardingCompleted}',
              ),
              _CheckLine(
                'onboardingCompletedAt: ${app.settings.onboardingCompletedAt?.toIso8601String() ?? 'not set'}',
              ),
              _CheckLine(
                'onboardingSkipped: ${app.settings.onboardingSkipped}',
              ),
              _CheckLine(
                'onboardingLastStep: ${app.settings.onboardingLastStep}',
              ),
              _CheckLine(
                'apiSetupCompleted: ${app.settings.apiSetupCompleted}',
              ),
              _CheckLine(
                'initialRulesConfigured: ${app.settings.initialRulesConfigured}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        BonnyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sanitization', style: context.text.titleLarge),
              const SizedBox(height: 12),
              _CheckLine('API keys and bearer tokens are redacted.'),
              _CheckLine('Base64 receipt images are replaced with metadata.'),
              _CheckLine('Debug data stays on device unless exported.'),
              _CheckLine('No backend, analytics, or cloud logging is used.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (entries.isNotEmpty)
          BonnyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest Event', style: context.text.titleLarge),
                const SizedBox(height: 12),
                _LogEntryTile(entry: entries.first),
              ],
            ),
          ),
      ],
    );
  }
}

class _RetryLogTab extends StatefulWidget {
  const _RetryLogTab({this.queueId});

  final String? queueId;

  @override
  State<_RetryLogTab> createState() => _RetryLogTabState();
}

class _RetryLogTabState extends State<_RetryLogTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final entries = app
        .debugEntries(type: DebugLogType.retry, queueId: widget.queueId)
        .where((entry) {
          if (_filter == 'successful') return entry.data['status'] == 'success';
          if (_filter == 'failed') return entry.data['status'] == 'failed';
          return true;
        })
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
      children: [
        Wrap(
          spacing: 8,
          children: [
            _RetryFilterChip('Retries', 'all', _filter, _setFilter),
            _RetryFilterChip(
              'Retry Successful',
              'successful',
              _filter,
              _setFilter,
            ),
            _RetryFilterChip('Retry Failed', 'failed', _filter, _setFilter),
          ],
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          const BonnyCard(
            child: EmptyState(
              icon: Icons.refresh_rounded,
              title: 'No retries logged',
              message: 'Retry and re-analysis attempts will appear here.',
            ),
          )
        else
          for (final entry in entries) ...[
            BonnyCard(child: _LogEntryTile(entry: entry)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
  }
}

class _RetryFilterChip extends StatelessWidget {
  const _RetryFilterChip(
    this.label,
    this.value,
    this.selected,
    this.onSelected,
  );

  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onSelected(value),
      selectedColor: context.colors.primaryAccent.withValues(alpha: 0.14),
      backgroundColor: context.colors.secondarySurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _LogTab extends StatelessWidget {
  const _LogTab({
    required this.types,
    required this.emptyTitle,
    required this.emptyMessage,
    this.queueId,
    this.action,
  });

  final List<String> types;
  final String? queueId;
  final String emptyTitle;
  final String emptyMessage;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final entries = app.debugEntries(types: types, queueId: queueId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
      children: [
        if (action != null) ...[action!, const SizedBox(height: 14)],
        if (entries.isEmpty)
          BonnyCard(
            child: EmptyState(
              icon: Icons.terminal_rounded,
              title: emptyTitle,
              message: emptyMessage,
            ),
          )
        else
          for (final entry in entries) ...[
            BonnyCard(child: _LogEntryTile(entry: entry)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final DebugLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final encoded = const JsonEncoder.withIndent('  ').convert(entry.toJson());
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: entry.isFailure
              ? context.colors.danger.withValues(alpha: 0.12)
              : context.colors.secondarySurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          _icon(entry.type),
          color: entry.isFailure
              ? context.colors.danger
              : context.colors.primaryAccent,
        ),
      ),
      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${entry.type} · ${entry.timestamp.toLocal()}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        onPressed: () => _copy(context, encoded),
        icon: const Icon(Icons.copy_rounded),
        tooltip: 'Copy JSON',
      ),
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.secondarySurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colors.border),
          ),
          child: SelectableText(
            encoded,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        if (entry.type == DebugLogType.request ||
            entry.type == DebugLogType.extraction ||
            entry.type == DebugLogType.queueExtraction) ...[
          const SizedBox(height: 12),
          _RetryDebugEntryButton(entry: entry),
        ],
      ],
    );
  }

  IconData _icon(String type) {
    return switch (type) {
      DebugLogType.request => Icons.http_rounded,
      DebugLogType.extraction => Icons.auto_awesome_rounded,
      DebugLogType.storage => Icons.storage_rounded,
      DebugLogType.rule => Icons.rule_rounded,
      DebugLogType.error => Icons.error_outline_rounded,
      DebugLogType.app => Icons.info_outline_rounded,
      _ => Icons.terminal_rounded,
    };
  }
}

class _RetryDebugEntryButton extends StatefulWidget {
  const _RetryDebugEntryButton({required this.entry});

  final DebugLogEntry entry;

  @override
  State<_RetryDebugEntryButton> createState() => _RetryDebugEntryButtonState();
}

class _RetryDebugEntryButtonState extends State<_RetryDebugEntryButton> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final imagePath = _findImagePath(widget.entry.data);
    final isExtraction =
        widget.entry.type == DebugLogType.extraction ||
        widget.entry.type == DebugLogType.queueExtraction;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _running || imagePath == null
            ? null
            : () => _retry(imagePath),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(
          imagePath == null
              ? 'Original image unavailable'
              : _running
              ? 'Re-analyzing...'
              : isExtraction
              ? 'Re-run Extraction'
              : 'Retry This Request',
        ),
      ),
    );
  }

  Future<void> _retry(String imagePath) async {
    setState(() => _running = true);
    final app = AppStateScope.of(context);
    final isExtraction =
        widget.entry.type == DebugLogType.extraction ||
        widget.entry.type == DebugLogType.queueExtraction;
    final draft = await app.retryAnalysis(
      imagePath: imagePath,
      source: isExtraction
          ? RetrySource.debugExtraction
          : RetrySource.debugRequest,
      retryOfRequestId: widget.entry.data['requestId']?.toString(),
      retryOfExtractionId: widget.entry.data['extractionId']?.toString(),
    );
    if (!mounted) return;
    setState(() => _running = false);
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retry failed. No draft was changed.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiptReviewScreen(draft: draft)),
    );
  }

  String? _findImagePath(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final direct = value['imagePath'];
      if (direct is String && direct.trim().isNotEmpty) return direct;
      final queue = value['queueMetadata'];
      if (queue is Map) {
        final queued = queue['imagePath'];
        if (queued is String && queued.trim().isNotEmpty) return queued;
      }
      for (final entry in value.values) {
        final found = _findImagePath(entry);
        if (found != null) return found;
      }
    }
    if (value is List) {
      for (final entry in value) {
        final found = _findImagePath(entry);
        if (found != null) return found;
      }
    }
    return null;
  }
}

class _CopyLatestButton extends StatelessWidget {
  const _CopyLatestButton({
    required this.label,
    required this.icon,
    required this.entry,
  });

  final String label;
  final IconData icon;
  final DebugLogEntry? entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: entry == null
            ? null
            : () {
                final encoded = const JsonEncoder.withIndent(
                  '  ',
                ).convert(entry!.toJson());
                _copy(context, encoded);
              },
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.secondarySurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.border),
      ),
      child: Text('$label $value', style: context.text.labelMedium),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: context.colors.secondaryAccent,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Copied sanitized debug JSON.')));
}
