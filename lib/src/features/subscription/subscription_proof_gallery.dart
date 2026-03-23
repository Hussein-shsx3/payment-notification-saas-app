import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/format/app_date_format.dart';

class SubscriptionProofItem {
  const SubscriptionProofItem({
    required this.id,
    required this.url,
    this.uploadedAtIso,
    this.reviewedAtIso,
  });

  final String id;
  final String url;
  final String? uploadedAtIso;
  final String? reviewedAtIso;

  static List<SubscriptionProofItem> parseList(Map<String, dynamic> data) {
    final raw = data['subscriptionPaymentProofHistory'];
    if (raw is List && raw.isNotEmpty) {
      final out = <SubscriptionProofItem>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final url = m['url']?.toString().trim() ?? '';
        if (url.isEmpty) continue;
        out.add(
          SubscriptionProofItem(
            id: m['id']?.toString() ?? '',
            url: url,
            uploadedAtIso: m['uploadedAt']?.toString(),
            reviewedAtIso: m['reviewedAt']?.toString(),
          ),
        );
      }
      return out;
    }
    final u = data['subscriptionPaymentProofUrl']?.toString().trim();
    if (u != null && u.isNotEmpty) {
      return [
        SubscriptionProofItem(
          id: 'legacy',
          url: u,
          uploadedAtIso: data['subscriptionPaymentProofUploadedAt']?.toString(),
          reviewedAtIso: data['subscriptionPaymentProofReviewedAt']?.toString(),
        ),
      ];
    }
    return [];
  }
}

/// Compact thumbnails with per-item show/hide full preview (admin-style).
class SubscriptionProofGallery extends StatelessWidget {
  const SubscriptionProofGallery({
    super.key,
    required this.items,
    required this.expandedById,
    required this.onToggle,
  });

  final List<SubscriptionProofItem> items;
  final Map<String, bool> expandedById;
  final void Function(String id) onToggle;

  static const _cyan = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.subscriptionProofGalleryHeading,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.subscriptionProofGalleryHint,
          style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final id = item.id.isNotEmpty ? item.id : item.url;
          final expanded = expandedById[id] ?? false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onToggle(id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: expanded ? _cyan.withOpacity(0.5) : const Color(0xFF334155),
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Image.network(
                                item.url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const ColoredBox(
                                    color: Color(0xFF1E293B),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _cyan,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xFF1E293B),
                                  child: Icon(Icons.broken_image_outlined, color: Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.uploadedAtIso != null &&
                                    item.uploadedAtIso!.isNotEmpty)
                                  Text(
                                    l10n.subscriptionProofUploadedLabel(
                                      formatDateTimeDmyFromIso(item.uploadedAtIso!),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  item.reviewedAtIso != null && item.reviewedAtIso!.isNotEmpty
                                      ? l10n.subscriptionProofReviewedByAdmin(
                                          formatDateTimeDmyFromIso(item.reviewedAtIso!),
                                        )
                                      : l10n.subscriptionProofAwaitingAdmin,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: item.reviewedAtIso != null &&
                                            item.reviewedAtIso!.isNotEmpty
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFFBBF24),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      expanded ? Icons.expand_less : Icons.expand_more,
                                      size: 18,
                                      color: _cyan,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      expanded
                                          ? l10n.subscriptionProofItemHideFull
                                          : l10n.subscriptionProofItemShowFull,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _cyan,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 240),
                            child: Image.network(
                              item.url,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: CircularProgressIndicator(color: _cyan),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(l10n.subscriptionProofImageError),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
