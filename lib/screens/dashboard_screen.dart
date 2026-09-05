import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_route.dart';
import '../widgets/app_animations.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_section_header.dart';
import '../constants/permissions.dart';
import '../models/auth_models.dart';
import '../models/dashboard_models.dart';
import '../models/ot_appointment_models.dart';
import '../models/patient_models.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/permission_service.dart';
import '../utils/currency_format.dart';
import '../utils/refreshable.dart';
import '../widgets/retry_network_image.dart';
import '../widgets/skeleton.dart';
import 'ot_appointment_list_screen.dart';
import 'opd_bill_screen.dart';
import 'patient_checkin_screen.dart';
import 'patient_form_screen.dart';
import 'patients_screen.dart';
import 'clinical_queue_screen.dart';
import 'reports_screen.dart';
import 'medicines_screen.dart';
import 'users_screen.dart';
import 'settings_screen.dart';
import 'masters_screen.dart';
import 'ot_home_dashboard_screen.dart';
import 'ot_reports_screen.dart';
import 'share_history_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

class DashboardScreen extends StatefulWidget {
  final UserInfo user;
  final HospitalInfo hospital;
  final VoidCallback? onMenuTap;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.hospital,
    this.onMenuTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin
    implements Refreshable {
  DashboardData? _data;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Timer? _timer;
  late final AnimationController _countCtrl;
  late final Animation<double> _countAnim;

  @override

  void initState() {
    super.initState();
    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _countAnim = CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut);
    _fetch();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _data != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Future<void> refreshSilently() => _fetch();

  Future<void> _fetch() async {
    // Show cached data instantly while fetching fresh in background
    if (_data == null) {
      final cached = await DashboardService.instance.getCached();
      if (cached != null && mounted) {
        setState(() { _data = cached; _loading = false; });
        _countCtrl.forward(from: 0);
      } else if (mounted) {
        setState(() { _loading = true; _error = null; });
      }
    }
    if (mounted) setState(() { _refreshing = true; _error = null; });
    try {
      final fresh = await DashboardService.instance.fetchDashboard();
      if (!mounted) return;
      if (_data == null || _isDifferent(_data!, fresh)) {
        setState(() { _data = fresh; _loading = false; _refreshing = false; });
        _countCtrl.forward(from: 0);
      } else {
        setState(() { _loading = false; _refreshing = false; });
      }
    } catch (e) {
      if (!mounted) return;
      if (_data == null) {
        setState(() { _error = e.toString(); _loading = false; _refreshing = false; });
      } else {
        setState(() { _refreshing = false; });
      }
    }
  }

  bool _isDifferent(DashboardData a, DashboardData b) =>
      a.todayPatients            != b.todayPatients            ||
      a.pendingExams             != b.pendingExams              ||
      a.primaryQueueCount        != b.primaryQueueCount        ||
      a.secondaryQueueCount      != b.secondaryQueueCount      ||
      a.revenueToday             != b.revenueToday             ||
      a.revenueMonth             != b.revenueMonth             ||
      a.primaryQueue.length      != b.primaryQueue.length      ||
      a.receptionists.length     != b.receptionists.length     ||
      a.doctorCards.length       != b.doctorCards.length       ||
      a.pendingShareRequestsCount != b.pendingShareRequestsCount ||
      a.accountantPendingCount  != b.accountantPendingCount    ||
      a.wardPendingCount        != b.wardPendingCount          ||
      a.otAssistantPendingCount != b.otAssistantPendingCount   ||
      a.dischargePendingCount   != b.dischargePendingCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _loading && _data == null
          ? _buildSkeleton()
          : _error != null && _data == null
              ? _buildError()
              : Stack(
                  children: [
                    RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetch,
                      child: _buildBody(),
                    ),
                    if (_refreshing)
                      LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        color: AppColors.primary,
                      ),
                  ],
                ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  /// Same brand-mark logic as app_drawer.dart's _buildBrandMark() — kept
  /// deliberately separate (not shared) since this is a temporary
  /// diagnostic placement, not yet a confirmed permanent design decision.
  /// See LOGO_403_INVESTIGATION.md.
  Widget _buildHospitalAvatar(String initials) {
    final live = AuthService.instance.cachedHospital;
    final logoUrl = live?.logoUrl ?? widget.hospital.logoUrl;
    final logoNobgUrl = live?.logoNobgUrl ?? widget.hospital.logoNobgUrl;
    final logoSidebarStyle = live?.logoSidebarStyle ?? widget.hospital.logoSidebarStyle;

    if (logoUrl.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withValues(alpha: 0.20),
        child: Text(
          initials,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
    }

    final useNobg = logoSidebarStyle == 'white' && logoNobgUrl.isNotEmpty;
    final logoSrc = useNobg ? logoNobgUrl : logoUrl;
    // Testing a senior dev's hypothesis: maybe /storage/* isn't fully
    // public and expects the same Bearer token as API calls. See
    // LOGO_403_INVESTIGATION.md.
    final token = AuthService.instance.cachedToken;
    final image = RetryNetworkImage(
      url: logoSrc,
      fit: BoxFit.contain,
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      fallbackBuilder: (_) => Text(
        initials,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );

    return CircleAvatar(
      radius: 18,
      backgroundColor: logoSidebarStyle == 'original_blur' ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: useNobg
            ? ColorFiltered(colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop), child: image)
            : image,
      ),
    );
  }

  AppBar _buildAppBar() {
    final name = widget.user.name.trim();
    final initials = name.isNotEmpty
        ? name.split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onMenuTap,
        child: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.menu_rounded, color: Colors.white),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hospital.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            widget.user.role?.name ?? 'Dashboard',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHospitalAvatar(initials),
              if ((_data?.pendingShareRequestsCount ?? 0) > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53E3E),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_data!.pendingShareRequestsCount}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Skeleton (first-ever load, no cache) ─────────────────────────────────

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _skeletonBlock(height: 16, width: 130, radius: 6),
        const SizedBox(height: 10),
        _skeletonScrollRow(),
        const SizedBox(height: 10),
        _skeletonScrollRow(),
        const SizedBox(height: 20),
        _skeletonBlock(height: 220, radius: 16),
        const SizedBox(height: 16),
        _skeletonBlock(height: 160, radius: 18),
        const SizedBox(height: 16),
        _skeletonBlock(height: 120, radius: 16),
      ],
    );
  }

  Widget _skeletonScrollRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: List.generate(4, (i) => Padding(
          padding: EdgeInsets.only(right: i < 3 ? 10.0 : 0),
          child: _skeletonBlock(width: 152, height: 100),
        )),
      ),
    );
  }

  Widget _skeletonBlock({double? width, required double height, double radius = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return AppErrorState(
      message: _error ?? 'Could not load dashboard',
      onRetry: _fetch,
    );
  }

  // ── Main body ─────────────────────────────────────────────────────────────

  Widget _buildNoPermissionsBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.40)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Permissions Configured',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your role has no feature permissions assigned. Please contact your administrator.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting hero card ────────────────────────────────────────────────────

  Widget _buildGreetingCard(DashboardData d) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final firstName = widget.user.name.trim().split(RegExp(r'\s+')).first;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final now = DateTime.now();
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _heroPill(Icons.calendar_today_rounded, dateStr),
                    _heroPill(Icons.people_alt_rounded, '${d.isDoctor ? d.myTodayPatients : d.todayPatients} patients'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _countAnim,
                  builder: (_, _) => Text(
                    '${((d.isDoctor ? d.myPrimaryPending : d.primaryQueueCount) * _countAnim.value).round()}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'In Queue',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final p = PermissionService.instance;
    final hasNoPermissions = !p.isSuper &&
        !p.canModule('opd') &&
        !p.canModule('ot') &&
        !p.canModule('master') &&
        !p.canModule('settings') &&
        !p.canModule('reports');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        _buildGreetingCard(d),
        if (hasNoPermissions) _buildNoPermissionsBanner(),
        if (d.subscriptionDaysLeft != null && d.subscriptionDaysLeft! <= 14)
          _buildSubscriptionBanner(d.subscriptionDaysLeft!),
        const AppSectionHeader(title: "Today's Overview"),
        if (p.isSuper) ...[
          _buildHospitalAdminCards(d),
        ] else ...[
          _buildStatsRow1(d),
          const SizedBox(height: 10),
          _buildStatsRow2(d),
        ],
        if (d.isReceptionist && d.receptionistStats != null) ...[
          const SizedBox(height: 10),
          _buildReceptionistStatsRow(d.receptionistStats!),
        ],
        if (d.isReceptionist) ...[
          const SizedBox(height: 20),
          _TodayPatientsWidget(user: widget.user, hospital: widget.hospital),
        ],
        const SizedBox(height: 20),
        _buildPrimaryQueue(d),
        if (!d.isDoctor && p.can(Perm.reportsView)) ...[
          const SizedBox(height: 16),
          _buildRevenueCard(d),
        ],
        if (p.isSuper && d.receptionists.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildReceptionTable(d),
        ],
        const SizedBox(height: 20),
        _buildQuickActions(),
      ],
    );
  }

  // ── Subscription banner ───────────────────────────────────────────────────

  Widget _buildSubscriptionBanner(int days) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Subscription expires in $days day${days == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const Text(
            'Renew →',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
          ),
        ],
      ),
    );
  }

  // ── Stat card rows ────────────────────────────────────────────────────────

  /// Hospital Admin's own 8-card set — web gives the tenant's Hospital
  /// Admin (`is_super`) a completely different, simpler dashboard than
  /// every other role (`index.blade.php:1610-1725`, comment: "Hospital
  /// admin: only these 8 cards"). Mutually exclusive with
  /// `_buildStatsRow1`/`_buildStatsRow2` — see DASHBOARD_PARITY_FIX_PLAN.md
  /// Phase 7.
  Widget _buildHospitalAdminCards(DashboardData d) {
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _statCard(label: 'Total Today Patients', value: '${d.todayPatients}', icon: Icons.people_alt_rounded, iconBg: AppColors.primary, rawCount: d.todayPatients),
          const SizedBox(width: 10),
          _statCard(label: 'Total Collection', value: _fmtRupee(d.revenueToday), icon: Icons.account_balance_wallet_rounded, iconBg: AppColors.green),
          const SizedBox(width: 10),
          PressScaleWrapper(
            onTap: () => _push(ReportsScreen(user: widget.user, hospital: widget.hospital)),
            child: _statCard(label: 'Report', value: '—', icon: Icons.bar_chart_rounded, iconBg: AppColors.secondary, badge: 'Summary'),
          ),
          const SizedBox(width: 10),
          _statCard(label: 'Doctor', value: '${d.totalDoctors}', icon: Icons.person_rounded, iconBg: AppColors.blue, rawCount: d.totalDoctors),
        ]),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _statCard(label: 'Reception', value: '${d.totalReceptions}', icon: Icons.headset_mic_rounded, iconBg: AppColors.teal, rawCount: d.totalReceptions),
          const SizedBox(width: 10),
          _statCard(label: 'Primary / Second', value: '${d.todayPrimary}/${d.todaySecondary}', icon: Icons.remove_red_eye_rounded, iconBg: AppColors.teal),
          const SizedBox(width: 10),
          _statCard(label: 'OT Total', value: '${d.otTotalToday}', icon: Icons.local_hospital_rounded, iconBg: AppColors.purple, rawCount: d.otTotalToday),
          if (d.pendingShareRequestsCount != null) ...[
            const SizedBox(width: 10),
            _statCard(label: 'Incoming Requests', value: '${d.pendingShareRequestsCount}', icon: Icons.send_rounded, iconBg: AppColors.secondary, rawCount: d.pendingShareRequestsCount),
          ],
        ]),
      ),
    ]);
  }

  Widget _buildStatsRow1(DashboardData d) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard(
            label: d.isOtDoctor ? 'My OT Today' : d.isDoctor ? 'My Patients' : "Today's Patients",
            value: '${d.isDoctor ? d.myTodayPatients : d.todayPatients}',
            icon: d.isOtDoctor ? Icons.medical_services_rounded : Icons.person_2_rounded,
            iconBg: AppColors.purple,
            badge: d.isOtDoctor ? 'OT' : 'OPD',
            rawCount: d.isDoctor ? d.myTodayPatients : d.todayPatients,
          ),
          if (!d.isOtDoctor) ...[
            const SizedBox(width: 10),
            _statCard(
              label: 'Pending Exams',
              value: '${d.pendingExams}',
              icon: Icons.pending_actions_rounded,
              iconBg: AppColors.orange,
              badge: 'In queue',
              rawCount: d.pendingExams,
            ),
            const SizedBox(width: 10),
            _statCard(
              label: 'OPD Queue',
              value: '${d.isDoctor ? d.myPrimaryPending : d.primaryQueueCount}/${d.isDoctor ? d.mySecondaryPending : d.secondaryQueueCount}',
              icon: Icons.groups_rounded,
              iconBg: AppColors.teal,
              badge: 'Primary / Secondary',
            ),
          ],
          ..._otSlotCards(d),
        ],
      ),
    );
  }

  /// Web swaps the generic "OT Appointment" card for a role-specific
  /// pending-count card for Accountant/Ward Management/OT Assistant/
  /// Discharge Counter — mirrors `Hospital\DashboardController.php:386-460`
  /// + `index.blade.php`'s `@if/@elseif` chain exactly (each field is null
  /// unless that role is logged in, so this is a plain first-match swap).
  /// See DASHBOARD_PARITY_FIX_PLAN.md Phase 4.
  List<Widget> _otSlotCards(DashboardData d) {
    if (d.accountantPendingCount != null) {
      return [
        const SizedBox(width: 10),
        _statCard(label: 'Pending Patients', value: '${d.accountantPendingCount}', icon: Icons.hourglass_bottom_rounded, iconBg: AppColors.orange, badge: 'OT payment', rawCount: d.accountantPendingCount),
        const SizedBox(width: 10),
        _statCard(label: 'Refunds', value: '${d.accountantRefundsCount ?? 0}', icon: Icons.replay_rounded, iconBg: const Color(0xFFC0392B), badge: 'Surgery refused', rawCount: d.accountantRefundsCount),
        const SizedBox(width: 10),
        _statCard(label: 'Completed', value: '${d.accountantCompletedCount ?? 0}', icon: Icons.check_circle_rounded, iconBg: AppColors.green, badge: 'Verified+', rawCount: d.accountantCompletedCount),
      ];
    }
    if (d.wardPendingCount != null) {
      return [
        const SizedBox(width: 10),
        _statCard(label: 'Pending Patient', value: '${d.wardPendingCount}', icon: Icons.hourglass_bottom_rounded, iconBg: AppColors.orange, badge: 'Ward entry', rawCount: d.wardPendingCount),
      ];
    }
    if (d.otAssistantPendingCount != null) {
      return [
        const SizedBox(width: 10),
        _statCard(label: 'Pending Patient', value: '${d.otAssistantPendingCount}', icon: Icons.hourglass_bottom_rounded, iconBg: AppColors.orange, badge: 'Ready for OT', rawCount: d.otAssistantPendingCount),
      ];
    }
    if (d.dischargePendingCount != null) {
      return [
        const SizedBox(width: 10),
        _statCard(label: 'Pending Patient', value: '${d.dischargePendingCount}', icon: Icons.hourglass_bottom_rounded, iconBg: AppColors.orange, badge: 'Discharge', rawCount: d.dischargePendingCount),
      ];
    }
    return [
      const SizedBox(width: 10),
      _statCard(label: 'OT Appointment', value: '${d.otToday}', icon: Icons.medical_services_rounded, iconBg: AppColors.teal, badge: '${d.otOperated} confirmed', rawCount: d.otToday),
    ];
  }

  Widget _buildStatsRow2(DashboardData d) {
    final p = PermissionService.instance;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (!d.isReceptionist) ...[
            _statCard(
              label: 'Registrations',
              value: '${d.todayRegistrations}',
              icon: Icons.fact_check_rounded,
              iconBg: AppColors.primary,
              badge: 'W:${d.todayWalkin} P:${d.todayPhone}',
              rawCount: d.todayRegistrations,
            ),
            const SizedBox(width: 10),
          ],
          if (!d.isDoctor && p.can(Perm.reportsView)) ...[
            const SizedBox(width: 10),
            _statCard(
              label: 'Revenue Today',
              value: _fmtRupee(d.revenueToday),
              icon: Icons.currency_rupee_rounded,
              iconBg: AppColors.green,
              badge: '${_fmtRupee(d.revenueMonth)} mo',
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconBg,
    String? badge,
    int? rawCount,
  }) {
    return Container(
      width: 152,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent color strip
              Container(width: 4, color: iconBg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconBg.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, size: 18, color: iconBg),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: iconBg.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: iconBg),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      rawCount != null
                          ? AnimatedBuilder(
                              animation: _countAnim,
                              builder: (_, _) => Text(
                                '${(rawCount * _countAnim.value).round()}',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1),
                              ),
                            )
                          : Text(
                              value,
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1),
                            ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Primary Queue ─────────────────────────────────────────────────────────

  Widget _buildPrimaryQueue(DashboardData d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Text(
                  'Primary Queue',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    '${d.isDoctor ? d.primaryQueue.length : d.primaryQueueCount} waiting',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green),
                  ),
                ),
                const Spacer(),
                PressScaleWrapper(
                  onTap: () => Navigator.of(context).push(appRoute(
                    ClinicalQueueScreen(user: widget.user, hospital: widget.hospital),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Text(
                      'View All →',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (d.primaryQueue.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No patients in queue right now',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: d.primaryQueue.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 16),
              itemBuilder: (_, i) =>
                  _queueItem(d.primaryQueue[i], i + 1, d.waitThresholds),
            ),
        ],
      ),
    );
  }

  Widget _queueItem(QueuePatient p, int rank, WaitThresholds t) {
    final wait = p.waitMinutes();
    final waitColor = _waitColor(wait, t);

    final parts = <String>[];
    if (p.age != null) parts.add('${p.age}y');
    if (p.gender != null) parts.add(_genderShort(p.gender!));
    final ageGender = parts.join('/');

    final initials = p.fullName.trim().isNotEmpty
        ? p.fullName.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : '#';
    final avatarColors = [AppColors.purple, AppColors.green, AppColors.teal, AppColors.orange, AppColors.secondary, AppColors.primary];
    final avatarColor = avatarColors[(rank - 1) % avatarColors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          // Rank circle
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 9),
          // Patient avatar
          CircleAvatar(
            radius: 19,
            backgroundColor: avatarColor.withValues(alpha: 0.14),
            child: Text(
              initials,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: avatarColor),
            ),
          ),
          const SizedBox(width: 10),
          // Name + code
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.fullName.isNotEmpty ? p.fullName : '—',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [p.patientCode, if (ageGender.isNotEmpty) ageGender].join(' · '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (p.hasHistory)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.history_rounded, size: 15, color: AppColors.secondary.withValues(alpha: 0.65)),
            ),
          if (p.doctorPatientNo != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Dr#${p.doctorPatientNo}',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          // Wait pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: waitColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(
              _fmtWait(wait),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: waitColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Revenue card ──────────────────────────────────────────────────────────

  Widget _buildRevenueCard(DashboardData d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_rupee_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Revenue Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  _dateLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _revenueRow('Today', d.revenueToday, highlight: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24, height: 1),
          ),
          _revenueRow('This Month', d.revenueMonth),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24, height: 1),
          ),
          _revenueRow('This Year', d.revenueYear),
        ],
      ),
    );
  }

  Widget _revenueRow(String label, double amount, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.70),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _fmtRupeeFull(amount),
          style: TextStyle(
            fontSize: highlight ? 22 : 16,
            fontWeight: FontWeight.w900,
            color: highlight ? const Color(0xFFFBBF24) : Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ── Reception performance table ───────────────────────────────────────────

  Widget _buildReceptionTable(DashboardData d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Reception Performance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: const [
                Expanded(flex: 3, child: _TH('Staff')),
                Expanded(flex: 1, child: _TH('Walks', right: true)),
                Expanded(flex: 2, child: _TH('Gross', right: true)),
                Expanded(flex: 2, child: _TH('Net', right: true)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: d.receptionists.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 16),
            itemBuilder: (_, i) => _receptionRow(d.receptionists[i]),
          ),
        ],
      ),
    );
  }

  Widget _receptionRow(ReceptionistStat r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  child: Text(
                    r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${r.todayCount}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtRupee(r.todayGross),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtRupee(r.todayNet),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions grid ────────────────────────────────────────────────────

  void _push(Widget screen) {
    Navigator.of(context).push(appRoute(screen));
  }

  // Only caller was the FOC quick action, disabled at client's request.
  // void _comingSoon(String label) {
  //   showAppSnackBar(context, '$label — Coming Soon', duration: const Duration(seconds: 2));
  // }

  // ── Receptionist-specific stats row ──────────────────────────────────────

  Widget _buildReceptionistStatsRow(ReceptionistStats rs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard(
            label: 'My Patients Today',
            value: '${rs.myPatientsToday}',
            icon: Icons.person_pin_rounded,
            iconBg: AppColors.purple,
            badge: 'Today',
            rawCount: rs.myPatientsToday,
          ),
          const SizedBox(width: 10),
          _statCard(
            label: "Today's Collection",
            value: _fmtRupee(rs.todayCollection),
            icon: Icons.currency_rupee_rounded,
            iconBg: AppColors.green,
            badge: 'Revenue',
          ),
          const SizedBox(width: 10),
          _statCard(
            label: 'Pending Phone',
            value: '${rs.pendingPhoneCheckin}',
            icon: Icons.phone_missed_rounded,
            iconBg: AppColors.orange,
            badge: 'Check-in',
            rawCount: rs.pendingPhoneCheckin,
          ),
          const SizedBox(width: 10),
          _statCard(
            label: 'My Walk-ins',
            value: '${rs.myWalkin}',
            icon: Icons.directions_walk_rounded,
            iconBg: AppColors.secondary,
            badge: 'Mine',
            rawCount: rs.myWalkin,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final u = widget.user;
    final h = widget.hospital;
    final p = PermissionService.instance;
    final actions = <_QA>[
      // OPD
      if (p.can(Perm.opdPatientRegister))
        _QA(Icons.person_add_rounded,       'New Walk-in',    AppColors.purple,
            () => _push(PatientFormScreen(mode: PatientFormMode.addWalkIn, user: u, hospital: h))),
      if (p.can(Perm.opdPatientRegisterPhone))
        _QA(Icons.phone_rounded,            'Phone Patient',  AppColors.secondary,
            () => _push(PatientFormScreen(mode: PatientFormMode.addPhone,  user: u, hospital: h))),
      if (p.can(Perm.opdPatientView))
        _QA(Icons.people_alt_rounded,       'Patient List',   AppColors.teal,
            () => _push(PatientsScreen(user: u, hospital: h))),
      // Queue & OT
      if (p.can(Perm.opdExamPrimary) || p.can(Perm.opdExamSecondary))
        _QA(Icons.queue_rounded,            'Clinical Queue', AppColors.green,
            () => _push(ClinicalQueueScreen(user: u, hospital: h))),
      if (p.canModule('ot'))
        _QA(Icons.medical_services_rounded, 'OT Dashboard',   AppColors.teal,
            () => _push(const OtHomeDashboardScreen())),
      if (p.can(Perm.reportsView) && p.canModule('ot'))
        _QA(Icons.insights_rounded,         'OT Reports',     AppColors.purple,
            () => _push(const OtReportsScreen())),
      if (p.can(Perm.opdPatientView))
        _QA(Icons.share_rounded,            'Share History',  AppColors.orange,
            () => _push(ShareHistoryScreen(user: u, hospital: h, initialTab: 0))),
      // Finance & Catalog
      if (p.can(Perm.reportsView))
        _QA(Icons.bar_chart_rounded,        'Reports',        const Color(0xFF7C3AED),
            () => _push(ReportsScreen(user: u, hospital: h))),
      if (p.can(Perm.masterMedicines))
        _QA(Icons.medication_rounded,       'Medicines',      const Color(0xFFDB2777),
            () => _push(MedicinesScreen(user: u, hospital: h, initialTab: 4))),
      if (p.can(Perm.masterCaseTypes) || p.can(Perm.masterEyeExam) || p.can(Perm.masterLocations))
        _QA(Icons.tune_rounded,             'Masters',        const Color(0xFF0891B2),
            () => _push(MastersScreen(user: u, hospital: h))),
      // Admin
      if (p.can(Perm.masterDoctors) || p.can(Perm.masterReceptions) || p.can(Perm.masterOtStaff))
        _QA(Icons.manage_accounts_rounded,  'Users',          AppColors.secondary,
            () => _push(UsersScreen(user: u, hospital: h))),
      if (p.can(Perm.settingsHospital))
        _QA(Icons.settings_rounded,         'Settings',       const Color(0xFF475569),
            () => _push(SettingsScreen(user: u, hospital: h))),
      // FOC disabled at client's request — see foc_screen.dart.
      // if (p.can(Perm.opdFocCreate) || p.can(Perm.opdFocAccept))
      //   _QA(Icons.money_off_rounded,        'FOC',            const Color(0xFFD97706),
      //       () => _comingSoon('FOC')),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Quick Actions'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final qa = actions[i];
            return AnimatedListItem(
              index: i,
              child: PressScaleWrapper(
              onTap: qa.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: qa.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(qa.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      qa.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            );
          },
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtRupee(double amount) => formatMoneyCompact(amount, widget.hospital.currencySymbol);

  String _fmtRupeeFull(double amount) => formatMoney(amount, widget.hospital.currencySymbol);

  String _fmtWait(int minutes) {
    if (minutes < 1) return 'Just in';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  Color _waitColor(int minutes, WaitThresholds t) {
    if (minutes < t.rGreen) return AppColors.waitGreen;
    if (minutes < t.rOrange) return AppColors.waitOrange;
    return AppColors.waitRed;
  }

  String _genderShort(String gender) {
    if (gender.toLowerCase() == 'male') return 'M';
    if (gender.toLowerCase() == 'female') return 'F';
    return gender.isNotEmpty ? gender[0].toUpperCase() : '';
  }

  String _dateLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

// ── Receptionist "Today Added Patients" widget ─────────────────────────────
// Mirrors web's receptionist-dashboard "Today Added Patients" table,
// including today's still-open OT appointments (pre-registration leads)
// merged in. Reuses Patient/OtAppointmentItem models directly so its rows
// can hand off straight to the existing check-in/print/OT-edit screens.
// See WEB_PULL_2026_08_07_APP_PARITY_AUDIT.md §9 / FIX_PLAN TASK 5.1.

class _TodayPatientsWidget extends StatefulWidget {
  final UserInfo user;
  final HospitalInfo hospital;

  const _TodayPatientsWidget({required this.user, required this.hospital});

  @override
  State<_TodayPatientsWidget> createState() => _TodayPatientsWidgetState();
}

class _TodayPatientsWidgetState extends State<_TodayPatientsWidget> {
  TodayPatientsData? _data;
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({String searchContact = ''}) async {
    if (_data == null) setState(() => _loading = true);
    try {
      final data = await DashboardService.instance.fetchTodayPatients(searchContact: searchContact);
      if (!mounted) return;
      setState(() { _data = data; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(searchContact: v.trim()));
  }

  Future<void> _openCheckIn(Patient p) async {
    final result = await Navigator.of(context).push<bool>(
      appRoute(PatientCheckinScreen(user: widget.user, hospital: widget.hospital, patient: p)),
    );
    if (result == true && mounted) _load(searchContact: _searchCtrl.text.trim());
  }

  void _openPrint(Patient p) {
    Navigator.of(context).push(
      appRoute(OpdBillScreen(user: widget.user, hospital: widget.hospital, patient: p)),
    );
  }

  void _openOtAppointment(OtAppointmentItem item) {
    Navigator.of(context).push(appRoute(
      OtAppointmentFormScreen(item: item, onSaved: () => _load(searchContact: _searchCtrl.text.trim())),
    ));
  }

  Future<void> _openWalkInFromOt(OtAppointmentItem item) async {
    final result = await Navigator.of(context).push<bool>(
      appRoute(PatientFormScreen(
        mode: PatientFormMode.addWalkIn,
        user: widget.user,
        hospital: widget.hospital,
        prefillOt: item,
      )),
    );
    if (result == true && mounted) _load(searchContact: _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final rows = _data?.rows ?? const <TodayPatientRow>[];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Text(
                  'Today Added Patients',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    '${rows.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by contact number...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (_loading)
            const AppSkeletonList(count: 3, itemHeight: 56)
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
            )
          else if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No patients added today', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 16),
              itemBuilder: (_, i) => rows[i].isOt ? _otRow(rows[i].otAppointment!) : _patientRow(rows[i].patient!),
            ),
        ],
      ),
    );
  }

  // ── OT appointment row ──────────────────────────────────────────────────

  Widget _otRow(OtAppointmentItem item) {
    final statusColor = switch (item.status) {
      'confirmed' => AppColors.primary,
      'completed' => AppColors.teal,
      _ => AppColors.orange,
    };
    return InkWell(
      onTap: () => _openOtAppointment(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.purple.withValues(alpha: 0.14),
              child: Text(
                _initials(item.fullName, fallback: 'OT'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.purple),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName.isNotEmpty ? item.fullName : '—',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Text(
                        'OT Appt',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.purple),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(item.appointmentNumber, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Text(_cap(item.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              color: AppColors.purple,
              tooltip: 'Walk-In',
              visualDensity: VisualDensity.compact,
              onPressed: () => _openWalkInFromOt(item),
            ),
          ],
        ),
      ),
    );
  }

  // ── Patient row ──────────────────────────────────────────────────────────

  Widget _patientRow(Patient p) {
    final wait = _waitMinutes(p);
    final waitColor = _waitColor4(wait, _data!.thresholds);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            child: Text(
              _initials(p.fullName, fallback: '#'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.secondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.fullName.isNotEmpty ? p.fullName : '—',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [p.patientCode, p.type == 'phone' ? 'Phone' : 'Walk-in', if (p.doctor != null) p.doctor!.name].join(' · '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (p.secondaryDoneAt != null)
            _miniBadge('Done', AppColors.teal)
          else if (p.primaryDoneAt != null)
            _miniBadge('Primary Done', AppColors.primary)
          else
            _miniBadge('Waiting', AppColors.orange),
          const SizedBox(width: 6),
          if (p.secondaryDoneAt != null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.teal),
            )
          else if (p.type == 'phone' && p.checkedInAt == null)
            IconButton(
              icon: const Icon(Icons.login_rounded, size: 18),
              color: AppColors.primary,
              tooltip: 'Check In',
              visualDensity: VisualDensity.compact,
              onPressed: () => _openCheckIn(p),
            )
          else
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: waitColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(_fmtWaitLocal(wait), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: waitColor)),
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 18),
                color: AppColors.primaryA50,
                tooltip: 'Print',
                visualDensity: VisualDensity.compact,
                onPressed: () => _openPrint(p),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );

  int _waitMinutes(Patient p) {
    final ref = p.checkedInAt ?? p.createdAt;
    if (ref == null) return 0;
    return DateTime.now().difference(ref).inMinutes.clamp(0, 99999);
  }

  // 4-tier wait color (green/orange/red/fire) — matches web's wait-fire tier
  // beyond the red threshold, which the shared 3-tier `_waitColor` above
  // (Primary Queue widget) doesn't have.
  Color _waitColor4(int minutes, TodayPatientsThresholds t) {
    if (minutes < t.rGreen) return AppColors.waitGreen;
    if (minutes < t.rOrange) return AppColors.waitOrange;
    if (minutes < t.rRed) return AppColors.waitRed;
    return AppColors.redDark;
  }

  String _fmtWaitLocal(int minutes) {
    if (minutes < 1) return 'Just in';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _initials(String name, {required String fallback}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.map((w) => w[0]).take(2).join().toUpperCase();
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Local data class for quick actions ────────────────────────────────────────

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QA(this.icon, this.label, this.color, this.onTap);
}

// ── Table header widget ───────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final bool right;
  const _TH(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
      ),
    );
  }
}
