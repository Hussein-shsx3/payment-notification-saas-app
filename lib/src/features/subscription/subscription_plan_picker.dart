import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Default list prices in ILS (Israeli new shekels). Change here to match your business.
const double kSubscriptionPriceWeekIls = 5;
const double kSubscriptionPriceMonthIls = 18;

String _formatIls(double amount) {
  if (amount == amount.roundToDouble()) {
    return '₪${amount.toInt()}';
  }
  return '₪${amount.toStringAsFixed(2)}';
}

/// Read-only pricing cards (no tap) — shows salary/plan price in ₪ like a typical pricing page.
class SubscriptionPlanPricing extends StatelessWidget {
  const SubscriptionPlanPricing({super.key});

  static const _slateMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.subscriptionPlansHeading,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.subscriptionPlansSubheading,
          style: const TextStyle(fontSize: 13, height: 1.4, color: _slateMuted),
        ),
        const SizedBox(height: 18),
        _PricingCard(
          title: l10n.subscriptionPlanWeekTitle,
          subtitle: l10n.subscriptionPlanWeekSubtitle,
          icon: Icons.view_week_outlined,
          priceIls: kSubscriptionPriceWeekIls,
          periodLabel: l10n.subscriptionPlanPerWeek,
          emphasize: false,
        ),
        const SizedBox(height: 12),
        _PricingCard(
          title: l10n.subscriptionPlanMonthTitle,
          subtitle: l10n.subscriptionPlanMonthSubtitle,
          icon: Icons.calendar_month_outlined,
          priceIls: kSubscriptionPriceMonthIls,
          periodLabel: l10n.subscriptionPlanPerMonth,
          badge: l10n.subscriptionPlanMonthBadge,
          emphasize: true,
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.priceIls,
    required this.periodLabel,
    this.badge,
    this.emphasize = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double priceIls;
  final String periodLabel;
  final String? badge;
  final bool emphasize;

  static const _cyan = Color(0xFF06B6D4);
  static const _slateCard = Color(0xFF0F172A);
  static const _slateBorder = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    final borderColor = emphasize ? _cyan.withOpacity(0.65) : _slateBorder;
    final borderWidth = emphasize ? 1.5 : 1.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        color: _slateCard,
        boxShadow: [
          BoxShadow(
            color: emphasize
                ? _cyan.withOpacity(0.14)
                : Colors.black.withOpacity(0.22),
            blurRadius: emphasize ? 18 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: emphasize
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_cyan.withOpacity(0.08), _slateCard],
              )
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: emphasize ? 18 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: emphasize
                  ? _cyan.withOpacity(0.18)
                  : const Color(0xFF1E293B),
              border: Border.all(
                color: emphasize
                    ? _cyan.withOpacity(0.4)
                    : const Color(0xFF334155),
              ),
            ),
            child: Icon(
              icon,
              color: emphasize ? _cyan : const Color(0xFFCBD5E1),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: emphasize ? 16.5 : 15,
                          color: const Color(0xFFF1F5F9),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _cyan.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _cyan.withOpacity(0.5)),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: _cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatIls(priceIls),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: emphasize ? 28 : 24,
                        letterSpacing: -0.5,
                        color: emphasize ? _cyan : const Color(0xFFF8FAFC),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        periodLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
