import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Matches server `subscriptionPlanPreference`: week | month | year.
enum SubscriptionPlanOption {
  week,
  month,
  year,
}

extension SubscriptionPlanOptionApi on SubscriptionPlanOption {
  String get apiValue {
    switch (this) {
      case SubscriptionPlanOption.week:
        return 'week';
      case SubscriptionPlanOption.month:
        return 'month';
      case SubscriptionPlanOption.year:
        return 'year';
    }
  }

  static SubscriptionPlanOption? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw.trim().toLowerCase()) {
      case 'week':
        return SubscriptionPlanOption.week;
      case 'month':
        return SubscriptionPlanOption.month;
      case 'year':
        return SubscriptionPlanOption.year;
      default:
        return null;
    }
  }
}

class SubscriptionPlanPicker extends StatelessWidget {
  const SubscriptionPlanPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    this.busy = false,
  });

  final SubscriptionPlanOption? selected;
  final ValueChanged<SubscriptionPlanOption> onSelect;
  final bool busy;

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
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: _slateMuted,
          ),
        ),
        const SizedBox(height: 18),
        _PlanTile(
          title: l10n.subscriptionPlanWeekTitle,
          subtitle: l10n.subscriptionPlanWeekSubtitle,
          icon: Icons.view_week_outlined,
          selected: selected == SubscriptionPlanOption.week,
          onTap: busy ? null : () => onSelect(SubscriptionPlanOption.week),
        ),
        const SizedBox(height: 12),
        _PlanTile(
          title: l10n.subscriptionPlanMonthTitle,
          subtitle: l10n.subscriptionPlanMonthSubtitle,
          icon: Icons.calendar_month_outlined,
          selected: selected == SubscriptionPlanOption.month,
          badge: l10n.subscriptionPlanMonthBadge,
          emphasize: true,
          onTap: busy ? null : () => onSelect(SubscriptionPlanOption.month),
        ),
        const SizedBox(height: 12),
        _PlanTile(
          title: l10n.subscriptionPlanYearTitle,
          subtitle: l10n.subscriptionPlanYearSubtitle,
          icon: Icons.event_outlined,
          selected: selected == SubscriptionPlanOption.year,
          onTap: busy ? null : () => onSelect(SubscriptionPlanOption.year),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
    this.emphasize = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;
  final bool emphasize;

  static const _cyan = Color(0xFF06B6D4);
  static const _slateCard = Color(0xFF0F172A);
  static const _slateBorder = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _cyan : _slateBorder;
    final borderWidth = selected ? 2.0 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
            color: _slateCard,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _cyan.withOpacity(0.18),
                      blurRadius: emphasize ? 20 : 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _cyan.withOpacity(0.12),
                      _slateCard,
                    ],
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
                  color: selected
                      ? _cyan.withOpacity(0.2)
                      : const Color(0xFF1E293B),
                  border: Border.all(
                    color: selected
                        ? _cyan.withOpacity(0.45)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Icon(
                  icon,
                  color: selected ? _cyan : const Color(0xFFCBD5E1),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 2),
                  child: Icon(
                    Icons.check_circle,
                    color: _cyan,
                    size: 26,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
