import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';
import '../breach/breach_monitoring_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../scanner/scanner_screen.dart';
import '../score/cyber_score_screen.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = const [
    DashboardScreen(),
    ScannerScreen(),
    BreachMonitoringScreen(),
    ChatbotScreen(),
    CyberScoreScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_filled, label: 'Home'),
    _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    _NavItem(icon: Icons.shield_outlined, label: 'Breach'),
    _NavItem(icon: Icons.forum_rounded, label: 'AI Chat'),
    _NavItem(icon: Icons.insights_rounded, label: 'Score'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF221E1D),
      body: _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 14,
          0,
          compact ? 12 : 14,
          bottomInset > 0 ? 8 : 12,
        ),
        child: Container(
          height: bottomInset > 0 ? (compact ? 84 : 88) : (compact ? 74 : 80),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2725),
            borderRadius: BorderRadius.circular(compact ? 22 : 26),
            border: Border.all(color: const Color(0xFF675B57)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF2A47F).withOpacity(0.10),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.symmetric(
                      horizontal: compact ? 2 : 4,
                      vertical: compact ? 8 : 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0x33E39A75)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(compact ? 16 : 18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: selected ? (compact ? 24 : 30) : (compact ? 18 : 24),
                          height: 3,
                          margin: EdgeInsets.only(bottom: compact ? 6 : 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFF6B493)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFF6B493).withOpacity(0.35),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        Icon(
                          item.icon,
                          color: selected
                              ? const Color(0xFFFFDDCE)
                              : const Color(0xFFC7B9B2),
                          size: compact ? 20 : 22,
                        ),
                        SizedBox(height: compact ? 2 : 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFFFDDCE)
                                    : const Color(0xFFC7B9B2),
                                fontSize: compact ? 9.4 : 10,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
