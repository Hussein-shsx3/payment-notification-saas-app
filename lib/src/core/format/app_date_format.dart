import 'package:intl/intl.dart';

/// Day/month/year (e.g. 16/04/2026), not month/day/year.
String formatDateDmyFromIso(String? iso) {
  if (iso == null || iso.isEmpty) return '--';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '--';
  return DateFormat('dd/MM/yyyy').format(dt.toLocal());
}

/// Date and time in day/month/year order.
String formatDateTimeDmyFromIso(String? iso) {
  if (iso == null || iso.isEmpty) return '--';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '--';
  return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
}
