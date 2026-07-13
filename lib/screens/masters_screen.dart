import 'package:flutter/material.dart';
import '../utils/app_route.dart';
import '../constants/permissions.dart';
import '../models/auth_models.dart';
import '../services/permission_service.dart';
import 'case_type_master_screen.dart';
import 'generic_master_screen.dart';
import 'location_master_screen.dart';
import 'ot_charge_head_master_screen.dart';
import 'ot_slot_master_screen.dart';
import 'ot_surgery_type_master_screen.dart';
import 'referrer_master_screen.dart';

// ── Color tokens ──────────────────────────────────────────────────────────────
abstract final class _K {
  static const navy   = Color(0xFF1B4F72);
  static const teal   = Color(0xFF1ABC9C);
  static const green  = Color(0xFF27AE60);
  static const orange = Color(0xFFE67E22);
  static const red    = Color(0xFFE74C3C);
  static const purple = Color(0xFF8E44AD);
  static const grey   = Color(0xFF7F8C8D);
  static const dark   = Color(0xFF2C3E50);
  static const bg     = Color(0xFFEAF2F8);
}

// ── Data model ────────────────────────────────────────────────────────────────
class _Item {
  final IconData icon;
  final String label;
  final Color color;
  /// API type slug — null means screen not yet built (shows "coming soon").
  final String? slug;
  final bool hasFavourite;
  final bool hasSeeded;

  const _Item(this.icon, this.label, this.color, {
    this.slug,
    this.hasFavourite = false,
    this.hasSeeded = false,
  });
}

// ── Items ─────────────────────────────────────────────────────────────────────
const _basic = [
  _Item(Icons.folder_open_rounded,      'Case Types', _K.navy, slug: 'case-types'),
  _Item(Icons.location_on_rounded,      'Locations',  _K.green,  slug: 'locations'),
  _Item(Icons.people_alt_rounded,       'Referrers',  _K.orange, slug: 'referrers-crud'),
  _Item(Icons.hourglass_bottom_rounded, 'Durations',  _K.grey,  slug: 'durations'),
];

const _ot = [
  _Item(Icons.remove_red_eye_rounded, 'Lens Options',   _K.dark,   slug: 'lens-options'),
  _Item(Icons.schedule_rounded,       'OT Slots',       _K.navy,   slug: 'ot-slots'),
  _Item(Icons.label_rounded,          'OT Types',       _K.green,   slug: 'ot-types'),
  _Item(Icons.cut_rounded,            'Surgery Types',  _K.orange, slug: 'ot-surgery-types'),
  _Item(Icons.payments_rounded,       'Charge Heads',   _K.teal,   slug: 'ot-charge-heads'),
];

const _clinical = [
  _Item(Icons.assignment_rounded,  'Chief Complaints', _K.red,    slug: 'complaints', hasFavourite: true),
  _Item(Icons.favorite_rounded,    'K/C/O',            _K.orange, slug: 'kcos',       hasFavourite: true),
  _Item(Icons.history_rounded,     'H/O',              _K.teal,   slug: 'hno',        hasFavourite: true),
  _Item(Icons.verified_rounded,    'Diagnoses',        _K.green,  slug: 'diagnoses',  hasFavourite: true),
  _Item(Icons.chat_rounded,        'Advice',           _K.navy,   slug: 'advices',    hasFavourite: true),
];

const _vision = [
  _Item(Icons.visibility_rounded,          'V/N',       _K.teal,   slug: 'vn'),
  _Item(Icons.table_rows_rounded,          'Vn C GL',   _K.navy,   slug: 'vngl'),
  _Item(Icons.view_list_rounded,           'Vn C ST',   _K.navy,   slug: 'vnst'),
  _Item(Icons.visibility_off_rounded,      'PH NV/N',   _K.teal,   slug: 'pnvn'),
  _Item(Icons.center_focus_strong_rounded, 'NR V/N',    _K.teal,   slug: 'nrvn'),
  _Item(Icons.lens_rounded,                'SPH / CYL', _K.navy,   slug: 'sph_cyl',  hasSeeded: true),
  _Item(Icons.open_with_rounded,           'Axis',      _K.grey,   slug: 'axis'),
  _Item(Icons.timeline_rounded,            'NCT (IOP)', _K.orange, slug: 'nct'),
];

const _anterior = [
  _Item(Icons.water_drop_rounded,           'SAC',         _K.teal,   slug: 'sac',       hasFavourite: true),
  _Item(Icons.visibility_off_rounded,       'Lid',         _K.grey,   slug: 'lid',       hasFavourite: true),
  _Item(Icons.circle_rounded,               'Conjunctiva', _K.red,    slug: 'conj',      hasFavourite: true),
  _Item(Icons.radio_button_checked_rounded, 'Cornea',      _K.navy,   slug: 'cornea',    hasFavourite: true),
  _Item(Icons.layers_rounded,               'A/C',         _K.teal,   slug: 'ac',        hasFavourite: true),
  _Item(Icons.adjust_rounded,               'Iris',        _K.orange, slug: 'iris',      hasFavourite: true),
  _Item(Icons.fiber_manual_record_rounded,  'Pupil',       _K.dark,   slug: 'pupil',     hasFavourite: true),
  _Item(Icons.camera_rounded,               'Lens',        _K.green,  slug: 'lens',      hasFavourite: true),
  _Item(Icons.open_in_full_rounded,         'E/M',         _K.grey,   slug: 'em',        hasFavourite: true),
  _Item(Icons.verified_user_rounded,        'Cover Test',  _K.green,  slug: 'covertest', hasFavourite: true),
];

const _posterior = [
  _Item(Icons.panorama_fish_eye_rounded,   'Disc', _K.grey, slug: 'disc', hasFavourite: true),
  _Item(Icons.signal_cellular_alt_rounded, 'F/R',  _K.grey, slug: 'fr',   hasFavourite: true),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class MastersScreen extends StatelessWidget {
  final UserInfo user;
  final HospitalInfo hospital;
  final VoidCallback? onMenuTap;

  const MastersScreen({
    super.key,
    required this.user,
    required this.hospital,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = PermissionService.instance;
    final isDoctor = user.role?.slug == 'doctor';

    final showBasic   = !isDoctor && (p.can(Perm.masterCaseTypes) || p.can(Perm.masterLocations));
    final showOt      = p.isSuper;
    final showEyeExam = p.can(Perm.masterEyeExam);

    var visibleCount = 0;
    if (showBasic)   visibleCount += _basic.length;
    if (showOt)      visibleCount += _ot.length;
    if (showEyeExam) visibleCount += _clinical.length + _vision.length +
        _anterior.length + _posterior.length;

    return Scaffold(
      backgroundColor: _K.bg,
      appBar: AppBar(
        backgroundColor: _K.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: onMenuTap,
        ),
        title: const Text(
          'Master Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _K.teal,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _K.teal.withValues(alpha: 0.38),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$visibleCount items',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Basic ────────────────────────────────────────────────
                if (showBasic) ...[
                  _SectionCard(
                    icon: Icons.grid_3x3_rounded,
                    title: 'Basic Masters',
                    color: _K.navy,
                    count: _basic.length,
                    child: _Grid(items: _basic, onTap: (i) => _open(context, i)),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── OT ───────────────────────────────────────────────────
                if (showOt) ...[
                  _SectionCard(
                    icon: Icons.local_hospital_rounded,
                    title: 'OT Masters',
                    color: _K.purple,
                    count: _ot.length,
                    child: _Grid(items: _ot, onTap: (i) => _open(context, i)),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Eye Exam ─────────────────────────────────────────────
                if (showEyeExam) ...[
                  _SectionCard(
                    icon: Icons.remove_red_eye_rounded,
                    title: 'Eye Exam Masters',
                    color: _K.teal,
                    count: _clinical.length + _vision.length +
                        _anterior.length + _posterior.length,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubGroup(
                            icon: Icons.assignment_outlined, label: 'Clinical'),
                        const SizedBox(height: 10),
                        _Grid(
                            items: _clinical,
                            onTap: (i) => _open(context, i)),
                        _divider(),
                        _SubGroup(
                            icon: Icons.visibility_outlined,
                            label: 'Vision Values'),
                        const SizedBox(height: 10),
                        _Grid(
                            items: _vision, onTap: (i) => _open(context, i)),
                        _divider(),
                        _SubGroup(
                            icon: Icons.center_focus_weak_rounded,
                            label: 'Anterior Segment (O/E)'),
                        const SizedBox(height: 10),
                        _Grid(
                            items: _anterior,
                            onTap: (i) => _open(context, i)),
                        _divider(),
                        _SubGroup(
                            icon: Icons.panorama_fish_eye_rounded,
                            label: 'Posterior Segment (Fundus)'),
                        const SizedBox(height: 10),
                        _Grid(
                            items: _posterior,
                            onTap: (i) => _open(context, i)),
                      ],
                    ),
                  ),
                ],

                // ── No access ────────────────────────────────────────────
                if (!showBasic && !showOt && !showEyeExam)
                  _buildNoAccess(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 56, color: _K.navy.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'No Access',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _K.navy.withValues(alpha: 0.50)),
            ),
            const SizedBox(height: 6),
            Text(
              'Your role has no master data permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: _K.navy.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, thickness: 1, color: Color(0x111B4F72)),
      );

  static void _open(BuildContext ctx, _Item item) {
    if (item.slug == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('${item.label} — Coming Soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: item.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    final screen = switch (item.slug) {
      'case-types'     => CaseTypeMasterScreen(accentColor: item.color),
      'referrers-crud' => ReferrerMasterScreen(accentColor: item.color),
      'ot-slots'        => OtSlotMasterScreen(accentColor: item.color),
      'ot-charge-heads'   => OtChargeHeadMasterScreen(accentColor: item.color),
      'ot-surgery-types'  => OtSurgeryTypeMasterScreen(accentColor: item.color),
      'locations'         => LocationMasterScreen(accentColor: item.color),
      _ => GenericMasterScreen(
        title: item.label,
        apiPath: 'masters/detail/${item.slug}',
        accentColor: item.color,
        icon: item.icon,
        hasFavourite: item.hasFavourite,
        hasSeeded: item.hasSeeded,
      ),
    };
    Navigator.push(ctx, appRoute(screen));
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int count;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFF1B4F72).withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4F72).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header band ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                bottom: BorderSide(
                    color: color.withValues(alpha: 0.12), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Pill icon badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Count chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Sub-group label ───────────────────────────────────────────────────────────
class _SubGroup extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SubGroup({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FB),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFF1B4F72), width: 3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: const Color(0xFF1B4F72).withValues(alpha: 0.70)),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B4F72).withValues(alpha: 0.80),
                letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }
}

// ── 3-column grid ─────────────────────────────────────────────────────────────
class _Grid extends StatelessWidget {
  final List<_Item> items;
  final void Function(_Item) onTap;
  const _Grid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = (constraints.maxWidth - 20) / 3;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final item in items)
            SizedBox(width: w, child: _Card(item: item, onTap: onTap)),
        ],
      );
    });
  }
}

// ── Item card ─────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final _Item item;
  final void Function(_Item) onTap;
  const _Card({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = item.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(16),
        splashColor: c.withValues(alpha: 0.12),
        highlightColor: c.withValues(alpha: 0.07),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: c.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.09),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Top accent gradient bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c, c.withValues(alpha: 0.35)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                c.withValues(alpha: 0.14),
                                c.withValues(alpha: 0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: c.withValues(alpha: 0.18)),
                          ),
                          child: Icon(item.icon, color: c, size: 22),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A3A52),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 12,
                          color: c.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
