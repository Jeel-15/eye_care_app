import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/permissions.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../widgets/app_drawer.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'patients_screen.dart';
import 'clinical_queue_screen.dart';
import 'masters_screen.dart';
import 'reports_screen.dart';
import 'share_history_screen.dart';
import 'medicines_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';
import 'foc_screen.dart';
import 'roles_screen.dart';
import 'doctor_dashboard_screen.dart';
import '../utils/app_route.dart';

// ── Pre-computed alpha variants ───────────────────────────────────────────────
const _white94 = Color(0xF0FFFFFF);   // nav bar frosted-glass background
const _black10 = Color(0x1A000000);   // nav bar drop shadow
const _navyA12 = Color(0x1F1B4F72);  // active nav item pill

class HomeScreen extends StatefulWidget {
  final UserInfo user;
  final HospitalInfo hospital;

  const HomeScreen({super.key, required this.user, required this.hospital});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<int, Widget> _builtPages   = {};
  final Set<int>         _visitedPages = {0};

  // One controller per page — drives per-page cross-fade + scale.
  // Forward = page coming in (fade 0→1, scale 0.96→1.0).
  // Reverse = page going out (fade 1→0, scale 1.0→0.96).
  late final List<AnimationController> _pageCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageCtrl = List.generate(5, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: i == 0 ? 1.0 : 0.0,   // page 0 starts fully visible
    ));
  }

  @override
  void dispose() {
    for (final c in _pageCtrl) c.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _silentRefresh();
  }

  Future<void> _silentRefresh() async {
    try {
      final user = await AuthService.instance.refreshSession();
      if (!mounted) return;
      if (user == null) {
        PermissionService.instance.clear();
        Navigator.of(context).pushReplacement(
          appRoute(const LoginScreen()),
        );
        return;
      }
      PermissionService.instance.load(user.role);
      final visible = _visibleNavItems.map((c) => c.screenIndex).toSet();
      if (!visible.contains(_currentIndex)) {
        setState(() => _currentIndex = 0);
      } else {
        setState(() {});
      }
    } catch (_) {
      // Network error — keep existing permissions, don't disrupt user
    }
  }

  bool get _isDoctorUser => widget.user.role?.slug == 'doctor';

  List<_NavConfig> get _visibleNavItems {
    final p = PermissionService.instance;
    return [
      const _NavConfig(0, Icons.home_rounded, 'Home'),
      if (p.can(Perm.opdPatientView))
        const _NavConfig(1, Icons.people_alt_rounded, 'Patients'),
      if (p.can(Perm.masterCaseTypes) || p.can(Perm.masterEyeExam) || p.can(Perm.masterLocations))
        const _NavConfig(2, Icons.tune_rounded, 'Masters'),
      if (!_isDoctorUser && p.can(Perm.reportsView))
        const _NavConfig(3, Icons.bar_chart_rounded, 'Reports'),
      if (p.can(Perm.opdExamPrimary) || p.can(Perm.opdExamSecondary))
        const _NavConfig(4, Icons.queue_rounded, 'Queue'),
    ];
  }

  void _goTo(int index) {
    if (index == _currentIndex) return;
    _pageCtrl[_currentIndex].reverse();   // old page: fade out + scale back
    _pageCtrl[index].forward();           // new page: fade in + scale forward
    setState(() {
      _visitedPages.add(index);
      _currentIndex = index;
    });
  }

  Widget _buildPage(int i) {
    switch (i) {
      case 0:
        if (_isDoctorUser) {
          return DoctorDashboardScreen(
            user: widget.user,
            hospital: widget.hospital,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          );
        }
        return DashboardScreen(
          user: widget.user,
          hospital: widget.hospital,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 1:
        return PatientsScreen(
          user: widget.user,
          hospital: widget.hospital,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 2:
        return MastersScreen(
          user: widget.user,
          hospital: widget.hospital,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 3:
        return ReportsScreen(
          user: widget.user,
          hospital: widget.hospital,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 4:
        return ClinicalQueueScreen(
          user: widget.user,
          hospital: widget.hospital,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _logout() async {
    PermissionService.instance.clear();
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      appRoute(const LoginScreen()),
    );
  }

  void _onDrawerNavigate(String label) {
    switch (label) {
      case 'Dashboard':
        _goTo(0);
      case 'Patients':
        _goTo(1);
      case 'Share History':
        Navigator.push(
          context,
          appRoute(ShareHistoryScreen(user: widget.user, hospital: widget.hospital)),
        );
      case 'Queue Dashboard':
        _goTo(4);
      case 'Reports':
        _goTo(3);
      case 'Medicines':
        Navigator.push(context, appRoute(MedicinesScreen(user: widget.user, hospital: widget.hospital, initialTab: 4)));
      case 'Medicine Groups':
        Navigator.push(context, appRoute(MedicinesScreen(user: widget.user, hospital: widget.hospital, initialTab: 5)));
      case 'Medicine Types':
        Navigator.push(context, appRoute(MedicinesScreen(user: widget.user, hospital: widget.hospital, initialTab: 1)));
      case 'Medicine Categories':
        Navigator.push(context, appRoute(MedicinesScreen(user: widget.user, hospital: widget.hospital, initialTab: 2)));
      case 'Route of Admin.':
        Navigator.push(context, appRoute(MedicinesScreen(user: widget.user, hospital: widget.hospital, initialTab: 3)));
      case 'Dosages':
        Navigator.push(context, appRoute(MedicinesScreen(user: widget.user, hospital: widget.hospital, initialTab: 0)));
      case 'My Profile':
        Navigator.push(context, appRoute(ProfileScreen(user: widget.user, hospital: widget.hospital)));
      case 'Settings':
        Navigator.push(context, appRoute(SettingsScreen(user: widget.user, hospital: widget.hospital)));
      case 'Masters':
        Navigator.push(context, appRoute(MastersScreen(user: widget.user, hospital: widget.hospital)));
      case 'Users':
        Navigator.push(context, appRoute(UsersScreen(user: widget.user, hospital: widget.hospital)));
      case 'FOC Requests':
        Navigator.push(context, appRoute(FocScreen(user: widget.user, hospital: widget.hospital)));
      case 'Roles & Permissions':
        Navigator.push(context, appRoute(RolesScreen(user: widget.user, hospital: widget.hospital)));
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — Coming Soon'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1B4F72),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: const Color(0xFFEBF5FB),
      drawer: AppDrawer(
        user: widget.user,
        hospital: widget.hospital,
        onLogout: _logout,
        onNavigate: _onDrawerNavigate,
      ),
      body: Stack(
        children: List.generate(5, (i) {
          if (!_visitedPages.contains(i)) return const SizedBox.shrink();
          final page = _builtPages.putIfAbsent(i, () => _buildPage(i));
          return AnimatedBuilder(
            animation: _pageCtrl[i],
            child: page,
            builder: (context, child) {
              final v = _pageCtrl[i].value;
              // Ease the raw controller value so scale feels springy
              final curved = Curves.easeOutCubic.transform(v);
              return Opacity(
                opacity: curved.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.96 + 0.04 * curved,
                  alignment: Alignment.topCenter,
                  child: IgnorePointer(
                    ignoring: i != _currentIndex,
                    child: child,
                  ),
                ),
              );
            },
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: _white94,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _black10,
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: _visibleNavItems
                      .map((c) => _NavItem(
                            icon: c.icon,
                            label: c.label,
                            active: _currentIndex == c.screenIndex,
                            onTap: () => _goTo(c.screenIndex),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

// ── Bottom nav config (screen index + display metadata) ──────────────────────

class _NavConfig {
  final int screenIndex;
  final IconData icon;
  final String label;
  const _NavConfig(this.screenIndex, this.icon, this.label);
}

// ── Bottom nav item ───────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1B4F72);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _pressed ? 0.82 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.active ? _navyA12 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.active ? primary : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                color: widget.active ? primary : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
