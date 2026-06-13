import 'package:flutter/material.dart';

import '../../services/openrouter_service.dart';
import '../../theme/app_theme.dart';

enum ApiSetupStatus { notConfigured, saved, testing, connected, failed }

class ApiKeySetupCard extends StatelessWidget {
  const ApiKeySetupCard({
    super.key,
    required this.controller,
    required this.status,
    required this.obscureText,
    required this.onToggleObscure,
    required this.onSave,
    required this.onTest,
    required this.maskedKey,
    this.errorText,
    this.warningText,
  });

  final TextEditingController controller;
  final ApiSetupStatus status;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final VoidCallback onSave;
  final VoidCallback onTest;
  final String maskedKey;
  final String? errorText;
  final String? warningText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.lock_rounded, color: colors.primaryAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API Key', style: context.text.titleLarge),
                    const SizedBox(height: 3),
                    Text(
                      'Stored securely on this device.',
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            obscureText: obscureText,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'OpenRouter API Key',
              hintText: 'sk-or-v1-...',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                tooltip: obscureText ? 'Show key' : 'Hide key',
              ),
            ),
          ),
          if (warningText != null) ...[
            const SizedBox(height: 10),
            Text(
              warningText!,
              style: context.text.labelMedium?.copyWith(color: colors.warning),
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              errorText!,
              style: context.text.labelMedium?.copyWith(color: colors.danger),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: status == ApiSetupStatus.testing ? null : onSave,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Key'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status == ApiSetupStatus.testing ? null : onTest,
                  icon: status == ApiSetupStatus.testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt_rounded),
                  label: Text(
                    status == ApiSetupStatus.testing ? 'Checking' : 'Test',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.cardTint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _MetadataRow(label: 'Saved key', value: maskedKey),
                const SizedBox(height: 8),
                const _MetadataRow(label: 'Provider', value: 'OpenRouter'),
                const SizedBox(height: 8),
                const _MetadataRow(
                  label: 'Model',
                  value: OpenRouterService.model,
                ),
                const SizedBox(height: 8),
                const _MetadataRow(
                  label: 'Purpose',
                  value: 'Receipt image analysis',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ApiSetupStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, color, icon) = switch (status) {
      ApiSetupStatus.notConfigured => (
        'Not configured',
        colors.mutedText,
        Icons.radio_button_unchecked_rounded,
      ),
      ApiSetupStatus.saved => (
        'Saved',
        colors.info,
        Icons.check_circle_rounded,
      ),
      ApiSetupStatus.testing => (
        'Checking',
        colors.warning,
        Icons.sync_rounded,
      ),
      ApiSetupStatus.connected => (
        'Connected',
        colors.success,
        Icons.verified_rounded,
      ),
      ApiSetupStatus.failed => ('Failed', colors.danger, Icons.error_rounded),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(label, style: context.text.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: context.text.labelMedium),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: context.text.labelMedium?.copyWith(
              color: context.colors.primaryText,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
