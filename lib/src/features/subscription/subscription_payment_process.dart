import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Formal explanation of how subscription payment and verification work.
class SubscriptionPaymentProcess extends StatelessWidget {
  const SubscriptionPaymentProcess({super.key});

  static const _cyan = Color(0xFF06B6D4);
  static const _muted = Color(0xFF94A3B8);
  static const _title = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      l10n.subscriptionPaymentProcessStep1,
      l10n.subscriptionPaymentProcessStep2,
      l10n.subscriptionPaymentProcessStep3,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cyan.withOpacity(0.35)),
              ),
              child: const Icon(Icons.payments_outlined, color: _cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.subscriptionPaymentProcessHeading,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.2,
                  color: _title,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.subscriptionPaymentProcessIntro,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: _muted,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StepRow(index: i + 1, text: steps[i]),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});

  final int index;
  final String text;

  static const _cyan = Color(0xFF06B6D4);
  static const _muted = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _cyan.withOpacity(0.55), width: 1.25),
            color: const Color(0xFF1E293B),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: _cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.42,
                color: _muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
