import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

class CyberScoreScreen extends StatefulWidget {
  const CyberScoreScreen({super.key});

  @override
  State<CyberScoreScreen> createState() => _CyberScoreScreenState();
}

class _CyberScoreScreenState extends State<CyberScoreScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _score;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _api.getCyberScore();
      if (mounted) setState(() => _score = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (_score?['cyber_score'] as num?)?.toInt();
    final level = (_score?['level'] ?? '').toString();
    final factors = (_score?['factors'] as Map?)?.cast<String, dynamic>() ?? {};
    final hasActivity = _score?['has_activity'] == true;
    return Scaffold(
      backgroundColor: const Color(0xFF221E1D),
      appBar: AppBar(
        title: const Text('Cyber Score'),
        backgroundColor: const Color(0xFF302A28),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _busy ? null : _loadScore, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Recent activity summary',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'This prototype score reflects recorded scans from the last 30 days. It is an activity summary, not a certified measure of your security.',
              style: TextStyle(color: Color(0xFFD3C3BC), height: 1.45),
            ),
            const SizedBox(height: 20),
            if (_busy)
              const Center(child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              _ScorePanel(title: 'Score unavailable', body: _error!)
            else ...[
              _ScorePanel(
                title: !hasActivity
                    ? 'No scan activity yet'
                    : score == null
                    ? 'No score available'
                    : score.toString() + ' / 100 · ' + level.toUpperCase(),
                body: hasActivity
                    ? 'The score is calculated from your recorded scan results. Safe scan counts and chatbot usage do not prove that an account is secure.'
                    : 'Run a message or URL check to create an activity summary. This score is not a certified measure of your security.',
              ),
              const SizedBox(height: 18),
              _FactorRow(label: 'High-risk scans', value: factors['high_risk_events']),
              _FactorRow(label: 'Caution-level scans', value: factors['medium_risk_events']),
              _FactorRow(label: 'Safer scans', value: factors['safe_events']),
              _FactorRow(label: 'High-risk breach events', value: factors['breach_hits']),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4740),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xAAEAA27F)),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFCDB6), fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFE6D9), height: 1.45)),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.label, required this.value});
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3431),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFE8DDD8)))),
          Text((value ?? 0).toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
