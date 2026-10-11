import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  Map<String, dynamic>? _messageResult;
  Map<String, dynamic>? _urlResult;
  String? _error;
  bool _messageBusy = false;
  bool _urlBusy = false;

  Future<void> _scanMessage() async {
    setState(() { _messageBusy = true; _error = null; });
    try {
      final result = await _api.scanEmail(_messageController.text.trim());
      if (mounted) setState(() => _messageResult = result);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _messageBusy = false);
    }
  }

  Future<void> _scanUrl() async {
    setState(() { _urlBusy = true; _error = null; });
    try {
      final result = await _api.scanUrl(_urlController.text.trim());
      if (mounted) setState(() => _urlResult = result);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _urlBusy = false);
    }
  }

  String _friendlyError(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('Bad state: ', '');

  @override
  void dispose() {
    _messageController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF221E1D),
      appBar: AppBar(
        title: const Text('Safety Scanner'),
        backgroundColor: const Color(0xFF302A28),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            const Text('Check before you click',
                style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Paste suspicious text or a link. The result is an AI-assisted assessment, so verify important requests independently.',
              style: TextStyle(color: Color(0xFFD3C3BC), height: 1.45),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _ResultCard(title: 'Could not complete the scan', body: _error!, risk: 'error'),
            ],
            const SizedBox(height: 22),
            _InputCard(
              title: 'Message or email',
              hint: 'Paste the message text here',
              controller: _messageController,
              maxLines: 5,
              busy: _messageBusy,
              onScan: _scanMessage,
              result: _messageResult,
            ),
            const SizedBox(height: 16),
            _InputCard(
              title: 'Website link',
              hint: 'https://example.com',
              controller: _urlController,
              maxLines: 1,
              busy: _urlBusy,
              onScan: _scanUrl,
              result: _urlResult,
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.title,
    required this.hint,
    required this.controller,
    required this.maxLines,
    required this.busy,
    required this.onScan,
    required this.result,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final bool busy;
  final VoidCallback onScan;
  final Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3431),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C6F6A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA99B95)),
              filled: true,
              fillColor: const Color(0xFF292422),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onScan,
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.shield_moon_outlined),
              label: Text(busy ? 'Checking…' : 'Check safety'),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              title: (result!['risk_level'] ?? 'unknown').toString().toUpperCase() + ' RISK',
              body: (result!['summary'] ?? 'No explanation was returned.').toString(),
              risk: (result!['risk_level'] ?? '').toString(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.body, required this.risk});

  final String title;
  final String body;
  final String risk;

  @override
  Widget build(BuildContext context) {
    final color = risk == 'high' || risk == 'error'
        ? const Color(0xFFFF8A80)
        : risk == 'medium'
            ? const Color(0xFFFFC980)
            : const Color(0xFF9DD6A8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF292422),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Color(0xFFE8DDD8), height: 1.45)),
        ],
      ),
    );
  }
}
