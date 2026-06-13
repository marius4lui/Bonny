import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/bonny_app.dart';
import '../../models/report.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/stat_widgets.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final ExportService _export = ExportService();

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final report = app.monthlyReport(_month);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          AppHeader(
            title: 'Monthly Report',
            subtitle: monthLabel(_month),
            trailing: IconButton.filledTonal(
              onPressed: report.receipts.isEmpty ? null : () => _share(report),
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Share report',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel(_month),
                      style: context.text.bodyLarge,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: report.receipts.isEmpty
                ? const BonnyCard(
                    child: EmptyState(
                      icon: Icons.pie_chart_rounded,
                      title: 'No report yet',
                      message:
                          'Save receipts for this month to generate a shareable summary.',
                    ),
                  )
                : Column(
                    children: [
                      BonnyCard(
                        color: context.colors.cardTint,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthLabel(report.month),
                              style: context.text.headlineMedium,
                            ),
                            const SizedBox(height: 18),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.35,
                              children: [
                                StatTile(
                                  label: 'Receipts',
                                  value: '${report.receipts.length}',
                                ),
                                StatTile(
                                  label: 'Items',
                                  value: '${report.itemCount}',
                                ),
                                StatTile(
                                  label: 'Reimbursable',
                                  value: money(report.reimbursableTotal),
                                  accent: context.colors.secondaryAccent,
                                ),
                                StatTile(
                                  label: 'Excluded',
                                  value: money(report.excludedTotal),
                                  accent: context.colors.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _CategoryBreakdown(report: report),
                      const SizedBox(height: 18),
                      _ItemAggregateCard(
                        title: 'Excluded Items',
                        empty: 'No excluded items this month.',
                        items: report.excludedItems,
                        showTotals: true,
                      ),
                      const SizedBox(height: 18),
                      if (app.settings.showItemFrequency)
                        _ItemAggregateCard(
                          title: 'Top Purchased Items',
                          empty: 'No item frequency yet.',
                          items: report.itemFrequency.take(8).toList(),
                          showTotals: false,
                        ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _share(report),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Generate Export'),
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
        ],
      ),
    );
  }

  Future<void> _share(MonthlyReport report) async {
    await SharePlus.instance.share(
      ShareParams(
        text: _export.buildMonthlySummary(report),
        subject: 'Bonny ${monthLabel(report.month)}',
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final max = report.categoryTotals.isEmpty
        ? 1.0
        : report.categoryTotals.first.total;
    return BonnyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Category Breakdown'),
          const SizedBox(height: 16),
          if (report.categoryTotals.isEmpty)
            Text('No categories yet.', style: context.text.bodyMedium)
          else
            for (final category in report.categoryTotals)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.category,
                            style: context.text.bodyLarge,
                          ),
                        ),
                        Text(
                          money(category.total),
                          style: context.text.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: category.total / max,
                        minHeight: 8,
                        backgroundColor: context.colors.secondarySurface,
                        valueColor: AlwaysStoppedAnimation(
                          context.colors.primaryAccent,
                        ),
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

class _ItemAggregateCard extends StatelessWidget {
  const _ItemAggregateCard({
    required this.title,
    required this.empty,
    required this.items,
    required this.showTotals,
  });

  final String title;
  final String empty;
  final List<ItemAggregate> items;
  final bool showTotals;

  @override
  Widget build(BuildContext context) {
    return BonnyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(empty, style: context.text.bodyMedium),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${item.count}x', style: context.text.labelMedium),
                    if (showTotals) ...[
                      const SizedBox(width: 12),
                      Text(money(item.total), style: context.text.bodyLarge),
                    ],
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
