import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/bonny_app.dart';
import '../../models/draft_receipt.dart';
import '../../models/receipt.dart';
import '../../models/receipt_import_queue.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import '../components/skeleton_loader.dart';
import 'import_complete_sheet.dart';
import 'main_shell.dart';
import 'receipt_review_screen.dart';

class AddReceiptScreen extends StatefulWidget {
  const AddReceiptScreen({super.key, this.initialCamera = false});

  final bool initialCamera;

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _startedInitialCamera = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialCamera && !_startedInitialCamera) {
      _startedInitialCamera = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pick(ImageSource.camera),
      );
    }
  }

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 92);
    if (image == null || !mounted) return;
    await _extract(image.path);
  }

  Future<void> _pickMultiple() async {
    final images = await _picker.pickMultiImage(imageQuality: 92);
    if (images.isEmpty || !mounted) return;
    if (images.length == 1) {
      await _extract(images.single.path);
      return;
    }

    final paths = images.map((image) => image.path).toList();
    final app = AppStateScope.of(context);
    app.startReceiptQueue(paths);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected ${images.length} receipts.')),
    );
    await _processCurrentQueueImage();
  }

  Future<void> _extract(String imagePath) async {
    final app = AppStateScope.of(context);
    if (!app.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add your OpenRouter API key in Settings before extracting.',
          ),
        ),
      );
      _openReview(app.manualDraft(imagePath));
      return;
    }

    final draft = await app.extractDraft(imagePath);
    if (!mounted) return;
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            app.extractionError ??
                'Extraction failed. You can still fill it manually.',
          ),
        ),
      );
      _openReview(app.manualDraft(imagePath));
      return;
    }
    _openReview(draft);
  }

  void _openReview(dynamic draft) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReceiptReviewScreen(draft: draft)),
    );
  }

  Future<void> _processCurrentQueueImage() async {
    final app = AppStateScope.of(context);
    var queue = app.markQueueProcessing();
    if (queue == null || !mounted) return;

    final metadata = app.activeQueueMetadata();
    final draft = await app.extractDraft(
      queue.currentImagePath,
      queueMetadata: metadata,
    );
    if (!mounted) return;

    String? extractionError;
    DraftReceipt reviewDraft;
    if (draft == null) {
      app.markQueueExtractionFailed();
      extractionError =
          app.extractionError ??
          'Extraction failed. You can retry, edit manually, or skip.';
      reviewDraft = app.manualDraft(queue.currentImagePath);
    } else {
      reviewDraft = draft;
    }

    queue = app.markQueueReviewing() ?? queue;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptReviewScreen(
          draft: reviewDraft,
          queue: queue,
          extractionError: extractionError,
          onConfirm: _confirmQueueReceipt,
          onSkip: _skipQueueReceipt,
          onRetry: _retryQueueReceipt,
          onCancelQueue: _cancelQueue,
        ),
      ),
    );
  }

  Future<bool> _confirmQueueReceipt(Receipt receipt) async {
    final app = AppStateScope.of(context);
    final queue = app.activeImportQueue;
    if (queue == null) return false;
    try {
      await app.saveReceipt(receipt);
      app.recordQueueSavedReceipt(receipt.id);
      if (!mounted) return true;
      Navigator.of(context).pop();
      await _advanceQueueAfterCurrent();
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
      return false;
    }
  }

  Future<void> _skipQueueReceipt() async {
    final app = AppStateScope.of(context);
    final queue = app.activeImportQueue;
    if (queue == null) return;
    app.skipCurrentQueueReceipt();
    if (!mounted) return;
    Navigator.of(context).pop();
    await _advanceQueueAfterCurrent();
  }

  Future<void> _retryQueueReceipt() async {
    if (!mounted) return;
    Navigator.of(context).pop();
    await _processCurrentQueueImage();
  }

  Future<void> _cancelQueue() async {
    final app = AppStateScope.of(context);
    app.cancelQueue();
    app.clearQueue();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _advanceQueueAfterCurrent() async {
    final app = AppStateScope.of(context);
    final next = app.advanceQueueOrComplete();
    if (next == null || !mounted) return;
    if (next.status == ReceiptImportQueueStatus.completed) {
      await _showImportComplete(next);
      return;
    }
    await _processCurrentQueueImage();
  }

  Future<void> _showImportComplete(ReceiptImportQueue queue) async {
    final app = AppStateScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ImportCompleteSheet(
        queue: queue,
        onViewReceipts: () {
          Navigator.of(context).pop();
          app.clearQueue();
          MainShellController.selectTab(1);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onOpenMonthlyReport: () {
          Navigator.of(context).pop();
          app.clearQueue();
          MainShellController.selectTab(2);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: app,
          builder: (context, _) {
            if (app.isExtracting) {
              final queue = app.activeImportQueue;
              return ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                children: [
                  AppHeader(
                    title: 'Add Receipt',
                    subtitle: queue == null
                        ? 'Reading your receipt'
                        : '${queue.progressLabel} · Reading receipt',
                  ),
                  const SizedBox(height: 20),
                  const SkeletonLoader(),
                  const SizedBox(height: 20),
                  Text(
                    'Extracting merchant, totals, and line items. You will review everything before saving.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium,
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                AppHeader(
                  title: 'Add Receipt',
                  subtitle: 'Scan or import a photo',
                  trailing: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      _ActionCard(
                        icon: Icons.document_scanner_rounded,
                        title: 'Take Photo',
                        subtitle: 'Use the camera for a fresh receipt.',
                        primary: true,
                        onTap: () => _pick(ImageSource.camera),
                      ),
                      const SizedBox(height: 14),
                      _ActionCard(
                        icon: Icons.photo_rounded,
                        title: 'Choose from Gallery',
                        subtitle: 'Pick a saved receipt image.',
                        onTap: () => _pick(ImageSource.gallery),
                      ),
                      const SizedBox(height: 14),
                      _ActionCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Import Multiple Images',
                        subtitle: 'Select several receipt photos.',
                        onTap: _pickMultiple,
                      ),
                      const SizedBox(height: 20),
                      BonnyCard(
                        color: context.colors.cardTint,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tips for better scanning',
                              style: context.text.titleLarge,
                            ),
                            const SizedBox(height: 14),
                            const _Tip('Keep the receipt fully visible'),
                            const _Tip('Use good lighting'),
                            const _Tip('Avoid blur, glare, and heavy folds'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: BonnyCard(
        color: primary ? colors.hero : colors.surface,
        borderColor: primary ? colors.heroSecondary : colors.border,
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primary
                    ? colors.inverseText.withValues(alpha: 0.12)
                    : colors.secondarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: primary ? colors.inverseText : colors.primaryAccent,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleLarge?.copyWith(
                      color: primary ? colors.inverseText : colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: primary ? colors.mutedText : colors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: primary ? colors.inverseText : colors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

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
