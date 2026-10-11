import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

class BreachMonitoringScreen extends StatefulWidget {
  const BreachMonitoringScreen({super.key});

  @override
  State<BreachMonitoringScreen> createState() => _BreachMonitoringScreenState();
}

class _BreachMonitoringScreenState extends State<BreachMonitoringScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _emailController = TextEditingController();
  Map<String, dynamic>? _result;
  String? _error;
  bool _busy = false;

  Future<void> _check() async {
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _api.checkBreach(_emailController.text.trim());
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exposed = _result?['exposed'] == true;
    return Scaffold(
      backgroundColor: const Color(0xFF221E1D),
      appBar: AppBar(
        title: const Text('Breach Demo'),
        backgroundColor: const Color(0xFF302A28),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4A382F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAA27F)),
              ),
              child: const Text(
                'Hackathon demo only: results come from a simulated sample dataset. This feature does not search real breach records.',
                style: TextStyle(color: Color(0xFFFFE6D9), height: 1.45, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email address',
                labelStyle: const TextStyle(color: Color(0xFFD3C3BC)),
                filled: true,
                fillColor: const Color(0xFF3A3431),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _check,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.manage_search_rounded),
              label: Text(_busy ? 'Checking…' : 'Run demo check'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ResultPanel(title: 'Check failed', body: _error!, exposed: false),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultPanel(
                title: exposed ? 'Sample match' : 'No sample match',
                body: (_result!['message'] ?? '').toString(),
                exposed: exposed,
              ),
              const SizedBox(height: 10),
              Text(
                (_result!['recommendation'] ?? '').toString(),
                style: const TextStyle(color: Color(0xFFD3C3BC), height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.title, required this.body, required this.exposed});
  final String title;
  final String body;
  final bool exposed;

  @override
  Widget build(BuildContext context) {
    final color = exposed ? const Color(0xFFFF8A80) : const Color(0xFF9DD6A8);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3431),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Color(0xFFE8DDD8), height: 1.45)),
        ],
      ),
    );
  }
}
