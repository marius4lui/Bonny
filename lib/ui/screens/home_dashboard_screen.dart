import 'package:flutter/material.dart';

import '../../app/bonny_app.dart';
import '../../onboarding/onboarding_flow_screen.dart';
import '../../onboarding/onboarding_step.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/receipt_row.dart';
import '../components/segmented_pill.dart';
import '../components/stat_widgets.dart';
import 'add_receipt_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _segment = 0;

  DateTime get _month {
    final now = DateTime.now();
    if (_segment == 1) return DateTime(now.year, now.month - 1);
    return DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final report = app.monthlyReport(_month);
    final recent = app.receipts.take(3).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const AppHeader(
            title: 'Bonny',
            subtitle: 'Clean receipt tracking',
            trailing: ThemeToggle(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: SegmentedPill(
              values: const ['This Month', 'Last Month', 'Custom'],
              selectedIndex: _segment,
              onChanged: (index) =>
                  setState(() => _segment = index == 2 ? 0 : index),
            ),
          ),
          if (!app.hasApiKey) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _ApiSetupReminder(app: app),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _HeroSummaryCard(report: report),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: BonnyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Quick Insights'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      InsightPill(
                        icon: Icons.receipt_long_rounded,
                        label: '${report.receipts.length} receipts',
                      ),
                      InsightPill(
                        icon: Icons.shopping_cart_rounded,
                        label: '${report.itemCount} items',
                      ),
                      InsightPill(
                        icon: Icons.block_rounded,
                        label: '${report.excludedItems.length} excluded',
                      ),
                      InsightPill(
                        icon: Icons.inventory_2_rounded,
                        label: report.itemFrequency.isEmpty
                            ? 'No top item yet'
                            : 'Top item: ${report.itemFrequency.first.name}',
                        color: context.colors.secondaryAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: BonnyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Recent Receipts'),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No receipts yet',
                      message:
                          'Scan your first receipt, import from gallery, or explore the demo preview.',
                      action: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AddReceiptScreen(initialCamera: true),
                              ),
                            ),
                            icon: const Icon(Icons.document_scanner_rounded),
                            label: const Text('Scan'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddReceiptScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Import'),
                          ),
                          TextButton.icon(
                            onPressed: () => _showDemoReceipt(context, app),
                            icon: const Icon(Icons.science_rounded),
                            label: const Text('Try demo'),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final receipt in recent) ReceiptRow(receipt: receipt),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiSetupReminder extends StatelessWidget {
  const _ApiSetupReminder({required this.app});

  final dynamic app;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BonnyCard(
      color: colors.warning.withValues(alpha: 0.10),
      borderColor: colors.warning.withValues(alpha: 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: colors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI extraction is not configured',
                  style: context.text.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add your OpenRouter API key to scan receipts automatically.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingFlowScreen(
                        replay: true,
                        initialStep: OnboardingStep.apiSetup,
                      ),
                    ),
                  ),
                  child: const Text('Set up API'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingFlowScreen(replay: true),
                    ),
                  ),
                  child: const Text('Learn Bonny'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showDemoReceipt(BuildContext context, dynamic app) async {
  await app.markDemoModeStarted();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: BonnyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Demo receipt'),
              const SizedBox(height: 10),
              Text('Lidl · €11.84', style: context.text.headlineMedium),
              const SizedBox(height: 12),
              for (final item in const [
                'Latte Macch. Vanille',
                'Maracuja Nektar',
                'Fanta Orange · excluded',
                'Pfand 0,25',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(item, style: context.text.bodyMedium),
                ),
              const SizedBox(height: 8),
              Text(
                'Demo data is a preview only and was not saved.',
                style: context.text.labelMedium,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.report});

  final dynamic report;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colors.primaryAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Summary', style: context.text.titleLarge),
                    const SizedBox(height: 3),
                    Text(
                      monthLabel(report.month),
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.cardTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt total', style: context.text.labelMedium),
                      const SizedBox(height: 6),
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          money(report.receiptTotal),
                          style: context.text.headlineLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.hero,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colors.inverseText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.check_circle_rounded,
                  label: 'Reimbursable',
                  value: money(report.reimbursableTotal),
                  color: colors.secondaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.block_rounded,
                  label: 'Excluded',
                  value: money(report.excludedTotal),
                  color: colors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.inventory_2_rounded,
                  label: 'Items',
                  value: '${report.itemCount}',
                  color: colors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AddReceiptScreen(initialCamera: true),
                    ),
                  ),
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: const Text('Scan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.hero,
                    foregroundColor: colors.inverseText,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddReceiptScreen()),
                  ),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Import'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryText,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium,
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.text.titleLarge?.copyWith(
                color: colors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
