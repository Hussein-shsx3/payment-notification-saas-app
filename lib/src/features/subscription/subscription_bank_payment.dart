import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Palestine bank payment number for subscription transfers (copy-friendly).
const String kPalestineBankPaymentNumber = '0599641683';

class SubscriptionBankPayment extends StatelessWidget {
  const SubscriptionBankPayment({super.key});

  static const _cyan = Color(0xFF06B6D4);
  static const _muted = Color(0xFF94A3B8);
  static const _border = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withOpacity(0.35)),
        color: const Color(0xFF0C1222),
        boxShadow: [
          BoxShadow(
            color: _cyan.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cyan.withOpacity(0.3)),
                ),
                child: const Icon(Icons.account_balance_outlined, color: _cyan, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.subscriptionBankPaymentHeading,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFFF1F5F9),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.subscriptionBankPaymentBody,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _muted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF020617),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    kPalestineBankPaymentNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: kPalestineBankPaymentNumber),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.subscriptionBankCopied),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18, color: _cyan),
                  label: Text(
                    l10n.subscriptionBankCopyCta,
                    style: const TextStyle(color: _cyan, fontWeight: FontWeight.w600),
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
