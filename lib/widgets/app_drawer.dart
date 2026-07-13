import 'package:flutter/material.dart';
import '../constants/permissions.dart';
import '../models/auth_models.dart';
import '../services/permission_service.dart';

class AppDrawer extends StatelessWidget {
  final UserInfo user;
  final HospitalInfo hospital;
  final VoidCallback onLogout;
  final void Function(String label)? onNavigate;

  const AppDrawer({
    super.key,
    required this.user,
    required this.hospital,
    required this.onLogout,
    this.onNavigate,
  });

  static const _navy = Color(0xFF1B4F72);
  static const _textSub = Color(0xFF64748B);
  static const _bgColor = Color(0xFFF3F4F7);

  @override
  Widget build(BuildContext context) {
    final p = PermissionService.instance;
    final isDoctor = user.role?.slug == 'doctor';

    final opdItems = [
      if (p.can(Perm.opdPatientView)) ...[
        const _Item(Icons.people_outline_rounded, 'Patients'),
        const _Item(Icons.share_outlined, 'Share History'),
      ],
      if (p.can(Perm.opdFocCreate) || p.can(Perm.opdFocAccept))
        const _Item(Icons.receipt_long_rounded, 'FOC Requests'),
    ];

    final clinicalItems = [
      if (p.can(Perm.opdExamPrimary) || p.can(Perm.opdExamSecondary))
        const _Item(Icons.queue_rounded, 'Queue Dashboard'),
    ];

    final otItems = [
      if (p.can(Perm.otBookingCreate) || p.can(Perm.otPatientList))
        const _Item(Icons.event_note_rounded, 'OT Bookings'),
      if (p.can(Perm.otPaymentRecord))
        const _Item(Icons.account_balance_wallet_rounded, 'Accountant / Billing'),
      if (p.can(Perm.otWardEntry))
        const _Item(Icons.bed_rounded, 'Ward Management'),
      if (p.can(Perm.otSurgeryRecord))
        const _Item(Icons.local_hospital_rounded, 'Doctor Dashboard'),
      if (p.can(Perm.otLensRecord) || p.can(Perm.otLensImplant) || p.can(Perm.otPatientList))
        const _Item(Icons.handyman_rounded, 'Assistant Dashboard'),
      if (p.can(Perm.otBillingManage))
        const _Item(Icons.receipt_long_rounded, 'Discharge & Invoices'),
    ];

    final reportsItems = [
      if (!isDoctor && p.can(Perm.reportsView))
        const _Item(Icons.bar_chart_rounded, 'Reports'),
    ];

    final medicineItems = [
      if (p.can(Perm.masterMedicines)) ...[
        const _Item(Icons.local_pharmacy_rounded, 'Medicines'),
        const _Item(Icons.label_rounded, 'Medicine Types'),
        const _Item(Icons.folder_rounded, 'Medicine Categories'),
        const _Item(Icons.alt_route_rounded, 'Route of Admin.'),
        const _Item(Icons.science_rounded, 'Dosages'),
      ],
    ];

    final configItems = [
      if (!isDoctor && (p.can(Perm.masterCaseTypes) || p.can(Perm.masterEyeExam) || p.can(Perm.masterLocations)))
        const _Item(Icons.tune_rounded, 'Masters'),
      if (!isDoctor && p.can(Perm.settingsHospital))
        const _Item(Icons.settings_outlined, 'Settings'),
      if (!isDoctor && p.can(Perm.masterRoles))
        const _Item(Icons.admin_panel_settings_rounded, 'Roles & Permissions'),
      if (!isDoctor && (p.can(Perm.masterDoctors) || p.can(Perm.masterReceptions) || p.can(Perm.masterOtStaff)))
        const _Item(Icons.manage_accounts_rounded, 'Users'),
    ];

    return Drawer(
      width: 296,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              children: [
                _buildDashboardTile(context),
                // OPD + Clinical side-by-side
                if (opdItems.isNotEmpty || clinicalItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (opdItems.isNotEmpty)
                        Expanded(
                          child: _SmallAccordion(
                            title: 'OPD',
                            items: opdItems,
                            onNavigate: (l) => _go(context, l),
                          ),
                        ),
                      if (opdItems.isNotEmpty && clinicalItems.isNotEmpty)
                        const SizedBox(width: 10),
                      if (clinicalItems.isNotEmpty)
                        Expanded(
                          child: _SmallAccordion(
                            title: 'Clinical',
                            items: clinicalItems,
                            onNavigate: (l) => _go(context, l),
                          ),
                        ),
                    ],
                  ),
                ],
                // OT / Surgery
                if (otItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _FullAccordion(
                    icon: Icons.calendar_month_rounded,
                    label: 'Department Hub',
                    sublabel: 'OT / SURGERY',
                    items: otItems,
                    onNavigate: (l) => _go(context, l),
                  ),
                ],
                // Reports
                if (reportsItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _FullAccordion(
                    icon: Icons.analytics_rounded,
                    label: 'Reports',
                    items: reportsItems,
                    onNavigate: (l) => _go(context, l),
                  ),
                ],
                // Medicines
                if (medicineItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _FullAccordion(
                    icon: Icons.medication_rounded,
                    label: 'Medicines',
                    items: medicineItems,
                    onNavigate: (l) => _go(context, l),
                  ),
                ],
                // Config
                if (configItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _FullAccordion(
                    icon: Icons.settings_rounded,
                    label: 'Config',
                    items: configItems,
                    onNavigate: (l) => _go(context, l),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  void _go(BuildContext context, String label) {
    Navigator.pop(context);
    if (onNavigate != null) {
      onNavigate!(label);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label — Coming Soon'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final initials = hospital.name.isNotEmpty
        ? hospital.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    return Container(
      color: _navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'HOSPITAL WORKSPACE',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.60),
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dashboard active tile ─────────────────────────────────────────────────

  Widget _buildDashboardTile(BuildContext context) {
    return Container(
      decoration: _clusterDeco(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onNavigate?.call('Dashboard');
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.grid_view_rounded, color: _navy, size: 20),
                SizedBox(width: 12),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    // Compute user initials for the profile row avatar
    final nameParts = user.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final words     = nameParts.where((p) => !(p.length <= 4 && p.endsWith('.'))).toList();
    final effective = words.isEmpty ? nameParts : words;
    final initials  = effective.isEmpty
        ? '?'
        : effective.length == 1
            ? effective[0].substring(0, effective[0].length >= 2 ? 2 : 1).toUpperCase()
            : '${effective[0][0]}${effective[1][0]}'.toUpperCase();

    return Container(
      color: const Color(0xFFEDEEF1),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              // My Profile row
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _navy.withValues(alpha: 0.07)),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate?.call('My Profile');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        // Avatar with initials
                        Container(
                          width: 36, height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _navy.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _navy.withValues(alpha: 0.10)),
                          ),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: _navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _navy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user.role != null)
                                Text(
                                  user.role!.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSub.withValues(alpha: 0.80),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: _textSub.withValues(alpha: 0.40)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'LOGOUT ACCOUNT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: BorderSide(color: _navy.withValues(alpha: 0.15)),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'EYE-SAAS V2.4.0-STABLE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _textSub.withValues(alpha: 0.55),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cluster card decoration ───────────────────────────────────────────────────

BoxDecoration _clusterDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFF1B4F72).withValues(alpha: 0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1B4F72).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

// ── Nav item data ─────────────────────────────────────────────────────────────

class _Item {
  final IconData icon;
  final String label;
  const _Item(this.icon, this.label);
}

// ── Small 2-column accordion (OPD & Clinical) ─────────────────────────────────

class _SmallAccordion extends StatefulWidget {
  final String title;
  final List<_Item> items;
  final void Function(String) onNavigate;

  const _SmallAccordion({
    required this.title,
    required this.items,
    required this.onNavigate,
  });

  @override
  State<_SmallAccordion> createState() => _SmallAccordionState();
}

class _SmallAccordionState extends State<_SmallAccordion> {
  bool _open = false;

  static const _navy = Color(0xFF1B4F72);
  static const _textSub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _clusterDeco(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — taps to toggle
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: _navy,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.expand_more_rounded, size: 18, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
          // Sub-items
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.items
                    .map(
                      (item) => InkWell(
                        onTap: () => widget.onNavigate(item.label),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          child: Row(
                            children: [
                              Icon(item.icon, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _textSub,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ── Full-width accordion ───────────────────────────────────────────────────────

class _FullAccordion extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final List<_Item> items;
  final void Function(String) onNavigate;

  const _FullAccordion({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.items,
    required this.onNavigate,
  });

  @override
  State<_FullAccordion> createState() => _FullAccordionState();
}

class _FullAccordionState extends State<_FullAccordion> {
  bool _open = false;

  static const _navy = Color(0xFF1B4F72);
  static const _textSub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _clusterDeco(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header — taps to toggle
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 22,
                    color: _textSub.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.sublabel != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.sublabel!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: _textSub.withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: _navy,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _navy,
                            ),
                          ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sub-items panel
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF1B4F72).withValues(alpha: 0.07),
                  ),
                ),
                color: const Color(0xFFFAFAFC),
              ),
              child: Column(
                children: widget.items.map(_buildSubItem).toList(),
              ),
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem(_Item item) {
    return InkWell(
      onTap: () => widget.onNavigate(item.label),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 16, 10),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 12),
            Icon(item.icon, size: 15, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
