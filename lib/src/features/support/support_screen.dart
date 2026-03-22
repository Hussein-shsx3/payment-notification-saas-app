import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _sendError;
  String? _whatsAppDisplay;
  String? _waDigits;
  List<Map<String, dynamic>> _messages = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(showFullScreenLoading: true));
  }

  String _formatMessageDate(BuildContext context, String? raw) {
    final d = raw == null ? null : DateTime.tryParse(raw);
    if (d == null) return '';
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(d);
  }

  Future<void> _load({bool showFullScreenLoading = false}) async {
    final api = context.read<AuthProvider>().api;
    final l10n = AppLocalizations.of(context)!;
    if (showFullScreenLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final cfg = await api.get('/support/config');
      if (cfg.statusCode >= 200 && cfg.statusCode < 300) {
        final body = jsonDecode(cfg.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        final wa = data?['whatsApp']?.toString().trim();
        if (wa != null && wa.isNotEmpty) {
          _whatsAppDisplay = wa;
          _waDigits = wa.replaceAll(RegExp(r'\D'), '');
        }
      }
      final res = await api.get('/support/messages?limit=100');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final container = body['data'] as Map<String, dynamic>;
        final list = (container['data'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) {
          setState(() {
            _messages = list;
            _error = null;
          });
        }
      } else {
        if (mounted) setState(() => _error = l10n.supportLoadError);
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.supportLoadError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.post('/support/messages', body: {'body': text});
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _controller.clear();
        await _load(showFullScreenLoading: false);
      } else if (mounted) {
        setState(() => _sendError = l10n.supportSendFailed);
      }
    } catch (_) {
      if (mounted) setState(() => _sendError = l10n.supportSendFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openWa() async {
    final d = _waDigits;
    if (d == null || d.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$d');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.supportRefresh,
            onPressed: _loading ? null : () => _load(showFullScreenLoading: false),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : RefreshIndicator(
              color: const Color(0xFF06B6D4),
              onRefresh: () => _load(showFullScreenLoading: false),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.supportHelpText,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                    ),
                    if (_whatsAppDisplay != null && _waDigits != null && _waDigits!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF022C22).withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF065F46).withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.supportWhatsAppIntro,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFD1FAE5), height: 1.35),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.supportWhatsAppHint,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6EE7B7)),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _openWa,
                              icon: const Icon(Icons.chat, size: 18),
                              label: Text(_whatsAppDisplay!),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF22D3EE)),
                        const SizedBox(width: 8),
                        Text(
                          l10n.supportConversation,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    if (_messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          l10n.supportEmptyThread,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _messages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final fromAdmin = m['from'] == 'admin';
                            final meta = fromAdmin ? l10n.supportTeam : l10n.supportYou;
                            final when = _formatMessageDate(context, m['createdAt']?.toString());
                            final line = when.isEmpty ? meta : '$meta · $when';
                            return Align(
                              alignment: fromAdmin
                                  ? AlignmentDirectional.centerEnd
                                  : AlignmentDirectional.centerStart,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.sizeOf(context).width * 0.88,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: fromAdmin
                                        ? const Color(0xFF0E7490).withValues(alpha: 0.22)
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        (m['body'] ?? '').toString(),
                                        style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0), height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: l10n.supportTypeMessage,
                        filled: true,
                        fillColor: const Color(0xFF020617),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: const Color(0xFF020617),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_sending ? l10n.loading : l10n.supportSend),
                    ),
                    if (_sendError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _sendError!,
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
                        ),
                      ),
                    TextButton(
                      onPressed: _loading ? null : () => _load(showFullScreenLoading: false),
                      child: Text(l10n.supportRefresh),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
