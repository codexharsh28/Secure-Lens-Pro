import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/utils/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _breachController = TextEditingController();

  bool _loadingScore = true;
  bool _loadingMessage = false;
  bool _loadingUrl = false;
  bool _loadingBreach = false;

  int _score = 0;
  String _level = 'Moderate';
  bool _scoreAvailable = false;
  bool _scoreHasActivity = false;

  Map<String, dynamic>? _messageResult;
  Map<String, dynamic>? _urlResult;
  Map<String, dynamic>? _breachResult;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    try {
      final result = await _apiService.getCyberScore();
      if (!mounted) return;
      setState(() {
        _score = (result['cyber_score'] ?? 0) as int;
        _level = (result['level'] ?? 'Moderate').toString();
        _scoreAvailable = true;
        _scoreHasActivity = result['has_activity'] == true;
        _loadingScore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scoreAvailable = false;
        _loadingScore = false;
      });
    }
  }

  Future<void> _scanMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _loadingMessage = true);
    try {
      final result = await _apiService.scanEmail(content);
      if (!mounted) return;
      setState(() => _messageResult = result);
      _loadScore();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messageResult = {
          'risk_level': 'error',
          'summary': 'We could not analyze this message right now.',
        };
      });
    } finally {
      if (mounted) setState(() => _loadingMessage = false);
    }
  }

  Future<void> _scanUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _loadingUrl = true);
    try {
      final result = await _apiService.scanUrl(url);
      if (!mounted) return;
      setState(() => _urlResult = result);
      _loadScore();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _urlResult = {
          'risk_level': 'error',
          'summary': 'We could not analyze this URL right now.',
        };
      });
    } finally {
      if (mounted) setState(() => _loadingUrl = false);
    }
  }

  Future<void> _checkBreach() async {
    final identifier = _breachController.text.trim();
    if (identifier.isEmpty) return;

    setState(() => _loadingBreach = true);
    try {
      final result = await _apiService.checkBreach(identifier);
      if (!mounted) return;
      setState(() => _breachResult = result);
      _loadScore();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _breachResult = {
          'error': true,
          'message': 'We could not check breach exposure right now.',
        };
      });
    } finally {
      if (mounted) setState(() => _loadingBreach = false);
    }
  }

  _AlertTone _toneFromScan(Map<String, dynamic>? result) {
    final level = (result?['risk_level'] ?? '').toString().toLowerCase();
    if (level == 'error') return _AlertTone.neutral;

    if (level.contains('high') ||
        level.contains('critical') ||
        level.contains('phishing') ||
        level.contains('danger')) {
      return _AlertTone.danger;
    }
    if (level.contains('warning') ||
        level.contains('medium') ||
        level.contains('suspicious')) {
      return _AlertTone.warning;
    }
    if (level.contains('safe') || level.contains('low') || level.contains('clear')) {
      return _AlertTone.safe;
    }
    return _AlertTone.neutral;
  }

  _AlertTone _toneFromBreach(Map<String, dynamic>? result) {
    if (result == null) return _AlertTone.neutral;
    if (result['error'] == true || result['is_simulated'] == true) {
      return _AlertTone.neutral;
    }
    return (result['exposed'] ?? false) == true
        ? _AlertTone.danger
        : _AlertTone.safe;
  }

  String _breachTitle(Map<String, dynamic>? result) {
    if (result == null) return 'BREACH CHECK';
    if (result['error'] == true) return 'CHECK UNAVAILABLE';
    if (result['is_simulated'] == true) return 'SIMULATED DEMO RESULT';

    final exposed = (result['exposed'] ?? false) == true;
    final count = (result['breach_count'] ?? 0) as int;

    if (!exposed) {
      return result['is_simulated'] == true
          ? 'NO SAMPLE MATCH'
          : 'NO EXPOSURE DETECTED';
    }

    if (count <= 1) {
      return '1 BREACH RECORD FOUND';
    }

    return '$count BREACH RECORDS FOUND';
  }

  String _breachSubtitle(Map<String, dynamic>? result) {
    if (result == null) {
      return 'Breach check completed.';
    }

    final message = (result['message'] ?? '').toString().trim();
    final recommendation = (result['recommendation'] ?? '').toString().trim();

    final breachesRaw = result['breaches'];
    final breaches = breachesRaw is List
        ? breachesRaw
            .whereType<Map>()
            .map((item) => (item['name'] ?? '').toString().trim())
            .where((name) => name.isNotEmpty)
            .toList()
        : <String>[];

    final parts = <String>[];

    if (message.isNotEmpty) {
      parts.add(message);
    }

    if (breaches.isNotEmpty) {
      parts.add('Breaches: ${breaches.join(', ')}.');
    }

    if (recommendation.isNotEmpty) {
      parts.add(recommendation);
    }

    if (parts.isEmpty) {
      return 'Breach check completed.';
    }

    return parts.join('\n\n');
  }

  String _deviceStatus() {
    if (!_scoreAvailable) return 'Unavailable';
    if (!_scoreHasActivity) return 'No Scan Data';
    if (_score >= 85) return 'Lower Risk Activity';
    if (_score >= 65) return 'Review Activity';
    return 'High Risk Activity';
  }

  Color _deviceStatusColor() {
    if (!_scoreAvailable || !_scoreHasActivity) return const Color(0xFFD3C3BC);
    if (_score >= 85) return const Color(0xFFFFD4A6);
    if (_score >= 65) return const Color(0xFFFFC980);
    return const Color(0xFFFF8B82);
  }

  String _threatStatus() {
    final tones = [
      _toneFromScan(_messageResult),
      _toneFromScan(_urlResult),
      _toneFromBreach(_breachResult),
    ];

    if (tones.contains(_AlertTone.danger)) return 'High Alert';
    if (tones.contains(_AlertTone.warning)) return 'Attention Needed';
    if (_messageResult?['risk_level'] == 'error' ||
        _urlResult?['risk_level'] == 'error' ||
        _breachResult?['error'] == true) {
      return 'Check Unavailable';
    }
    if (_messageResult != null || _urlResult != null || _breachResult != null) {
      return 'No High Risk Found';
    }
    return 'Monitoring';
  }

  Color _threatColor() {
    final value = _threatStatus();
    if (value == 'High Alert') return const Color(0xFFFF8B82);
    if (value == 'Attention Needed') return const Color(0xFFFFC980);
    return const Color(0xFFFFCEB6);
  }

  void _showInfo(String title, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF342E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFD3C3BC),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _urlController.dispose();
    _breachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    final horizontalPadding = Responsive.horizontalPadding(context);
    final isTablet = Responsive.isTablet(context);

    final messageTone = _toneFromScan(_messageResult);
    final urlTone = _toneFromScan(_urlResult);
    final breachTone = _toneFromBreach(_breachResult);

    return Scaffold(
      backgroundColor: const Color(0xFF221E1D),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF302A28), Color(0xFF221E1D)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = isTablet ? 680.0 : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 12 : 14,
                      horizontalPadding,
                      18,
                    ),
                    children: [
                      Text(
                        'Home Dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.titleSize(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      _InfoCard(
                        glow: true,
                        compact: compact,
                        onTap: () => _showInfo(
                          'Activity Score',
                          'This prototype score summarizes recorded scan activity. It is not a measure of your device or overall security.',
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Activity Score',
                              style: TextStyle(
                                color: const Color(0xFFFFE6D9),
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _loadingScore
                                  ? 'Loading...'
                                  : _scoreAvailable
                                      ? _scoreHasActivity
                                          ? _score.toString() + ' - ' + _level.toUpperCase()
                                          : 'No Scan Data'
                                      : 'Unavailable',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFFFCDB6),
                                fontSize: compact ? 18 : 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InfoCard(
                        compact: compact,
                        onTap: () => _showInfo(
                          'Activity Status',
                          'This is a label derived from recent scan activity. It does not measure or control the security of your device.',
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Activity Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 14 : 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _deviceStatus(),
                                    style: TextStyle(
                                      color: _deviceStatusColor(),
                                      fontSize: compact ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: compact ? 44 : 50,
                              height: compact ? 44 : 50,
                              decoration: BoxDecoration(
                                color: _deviceStatusColor().withOpacity(0.85),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                !_scoreAvailable || !_scoreHasActivity
                                    ? Icons.info_outline_rounded
                                    : _deviceStatus() == 'High Risk Activity'
                                        ? Icons.priority_high_rounded
                                        : Icons.check_rounded,
                                color: const Color(0xFF31260D),
                                size: compact ? 24 : 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InfoCard(
                        compact: compact,
                        onTap: () => _showInfo(
                          'Threat Detection',
                          'This section summarizes the latest risk state inferred from your message scan, URL scan, and breach monitoring activity.',
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Threat Detection',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 14 : 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _threatStatus(),
                                    style: TextStyle(
                                      color: _threatColor(),
                                      fontSize: compact ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: compact ? 40 : 44,
                              height: compact ? 40 : 44,
                              decoration: BoxDecoration(
                                color: _threatColor().withOpacity(0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _threatStatus() == 'High Alert'
                                    ? Icons.error_rounded
                                    : _threatStatus() == 'Attention Needed'
                                        ? Icons.warning_amber_rounded
                                        : Icons.shield_rounded,
                                color: _threatColor(),
                                size: compact ? 20 : 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        compact: compact,
                        title: 'Message Scan',
                        child: Column(
                          children: [
                            _InputBox(
                              compact: compact,
                              controller: _messageController,
                              hint: 'Paste suspicious message or email...',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 10),
                            _PrimaryButton(
                              compact: compact,
                              text: _loadingMessage ? 'Analyzing...' : 'Analyze Message',
                              onTap: _loadingMessage ? null : _scanMessage,
                            ),
                            if (_messageResult != null) ...[
                              const SizedBox(height: 12),
                              _ScanResultCard(
                                compact: compact,
                                tone: messageTone,
                                title: (_messageResult?['risk_level'] ?? 'Result')
                                    .toString()
                                    .toUpperCase(),
                                subtitle: (_messageResult?['summary'] ?? 'Scan completed.')
                                    .toString(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        compact: compact,
                        title: 'URL Scan',
                        child: Column(
                          children: [
                            _InputBox(
                              compact: compact,
                              controller: _urlController,
                              hint: 'Paste suspicious URL...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            _PrimaryButton(
                              compact: compact,
                              text: _loadingUrl ? 'Analyzing...' : 'Analyze URL',
                              onTap: _loadingUrl ? null : _scanUrl,
                            ),
                            if (_urlResult != null) ...[
                              const SizedBox(height: 12),
                              _ScanResultCard(
                                compact: compact,
                                tone: urlTone,
                                title: (_urlResult?['risk_level'] ?? 'Result')
                                    .toString()
                                    .toUpperCase(),
                                subtitle: (_urlResult?['summary'] ?? 'Scan completed.')
                                    .toString(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        compact: compact,
                        title: 'Breach Monitoring',
                        child: Column(
                          children: [
                            _InputBox(
                              compact: compact,
                              controller: _breachController,
                              hint: 'Enter email for breach check...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            _PrimaryButton(
                              compact: compact,
                              text: _loadingBreach ? 'Checking...' : 'Check Breach',
                              onTap: _loadingBreach ? null : _checkBreach,
                            ),
                            if (_breachResult != null) ...[
                              const SizedBox(height: 12),
                              _ScanResultCard(
                                compact: compact,
                                tone: breachTone,
                                title: _breachTitle(_breachResult),
                                subtitle: _breachSubtitle(_breachResult),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _AlertTone { danger, warning, safe, neutral }

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.child,
    required this.compact,
    this.glow = false,
    this.onTap,
  });

  final Widget child;
  final bool compact;
  final bool glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 14 : 16,
        compact ? 14 : 18,
        compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: glow ? const Color(0xFF5B4740) : const Color(0xFF3B3432),
        borderRadius: BorderRadius.circular(compact ? 20 : 22),
        border: Border.all(
          color: glow ? const Color(0xAAEAA27F) : const Color(0xFF7C6F6A),
          width: 1.2,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFFF2A47F).withOpacity(0.18),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFF2A47F).withOpacity(0.06),
                  blurRadius: 14,
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return box;

    return InkWell(
      borderRadius: BorderRadius.circular(compact ? 20 : 22),
      onTap: onTap,
      child: box,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.compact,
  });

  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF342E2C),
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(
          color: const Color(0xAAF2A47F),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2A47F).withOpacity(0.10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.compact,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B3432),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF7C6F6A)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 14 : 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFFC7B9B2),
            fontSize: compact ? 13.5 : 15,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(compact ? 14 : 16),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.onTap,
    required this.compact,
  });

  final String text;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 48 : 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFE68F66), Color(0xFFF6B493)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2A47F).withOpacity(0.24),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF2B2524),
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final _AlertTone tone;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = switch (tone) {
      _AlertTone.danger => (
          border: const Color(0x66FF8B82),
          glow: const Color(0x22FF8B82),
          bg: const Color(0xFF4A2F2D),
          text: const Color(0xFFFFA49C),
          icon: Icons.error_rounded,
        ),
      _AlertTone.warning => (
          border: const Color(0x66FFD79A),
          glow: const Color(0x22FFD79A),
          bg: const Color(0xFF4A3B2D),
          text: const Color(0xFFFFD4A6),
          icon: Icons.warning_amber_rounded,
        ),
      _AlertTone.safe => (
          border: const Color(0x66F2A47F),
          glow: const Color(0x22F2A47F),
          bg: const Color(0xFF3D3532),
          text: const Color(0xFFFFCEB6),
          icon: Icons.verified_rounded,
        ),
      _AlertTone.neutral => (
          border: const Color(0xFF7C6F6A),
          glow: Colors.transparent,
          bg: const Color(0xFF3B3432),
          text: const Color(0xFFFFCEB6),
          icon: Icons.info_outline_rounded,
        ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.border, width: 1.15),
        boxShadow: [
          BoxShadow(
            color: style.glow,
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 32 : 36,
            height: compact ? 32 : 36,
            decoration: BoxDecoration(
              color: style.text.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              style.icon,
              color: style.text,
              size: compact ? 18 : 20,
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: style.text,
                    fontSize: compact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 12 : 12.8,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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
