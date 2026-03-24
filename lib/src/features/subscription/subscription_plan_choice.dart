/// User-selected subscription period (week or month). Sent as `subscriptionPlanPreference` to the API.
enum SubscriptionPlanChoice {
  week,
  month,
}

extension SubscriptionPlanChoiceApi on SubscriptionPlanChoice {
  String get apiValue => name;
}

SubscriptionPlanChoice? tryParseSubscriptionPlanChoice(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  switch (raw.trim().toLowerCase()) {
    case 'week':
      return SubscriptionPlanChoice.week;
    case 'month':
      return SubscriptionPlanChoice.month;
    default:
      return null;
  }
}
