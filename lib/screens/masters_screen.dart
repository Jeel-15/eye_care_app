import 'package:flutter/material.dart';
import '../utils/app_route.dart';
import '../constants/app_colors.dart';
import '../widgets/app_animations.dart';
import '../widgets/app_item_grid.dart';
import '../widgets/app_section_card.dart';
import '../constants/permissions.dart';
import '../models/auth_models.dart';
import '../services/permission_service.dart';
import 'case_type_master_screen.dart';
import 'generic_master_screen.dart';
import 'location_master_screen.dart';
import 'ot_charge_head_master_screen.dart';
import 'ot_lens_inventory_master_screen.dart';
import 'ot_lens_option_master_screen.dart';
import 'ot_lens_power_master_screen.dart';
import 'ot_package_master_screen.dart';
import 'ot_slot_master_screen.dart';
import 'ot_surgery_type_master_screen.dart';
import 'ot_type_master_screen.dart';
import 'referrer_master_screen.dart';


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
final _basic = [
  _Item(Icons.folder_open_rounded,      'Case Types', AppColors.primary, slug: 'case-types'),
  _Item(Icons.location_on_rounded,      'Locations',  AppColors.green,  slug: 'locations'),
  _Item(Icons.people_alt_rounded,       'Referrers',  AppColors.orange, slug: 'referrers-crud'),
  _Item(Icons.hourglass_bottom_rounded, 'Durations',  Color(0xFF7F8C8D),  slug: 'durations'),
];

final _ot = [
  _Item(Icons.remove_red_eye_rounded, 'Lens Options',   Color(0xFF2C3E50),   slug: 'lens-options'),
  _Item(Icons.schedule_rounded,       'OT Slots',       AppColors.primary,   slug: 'ot-slots'),
  _Item(Icons.label_rounded,          'OT Types',       AppColors.green,   slug: 'ot-types'),
  _Item(Icons.cut_rounded,            'Surgery Types',  AppColors.orange, slug: 'ot-surgery-types'),
  _Item(Icons.payments_rounded,       'Charge Heads',   AppColors.teal,   slug: 'ot-charge-heads'),
  _Item(Icons.inventory_2_rounded,    'Lens Inventory', AppColors.blue,   slug: 'ot-lens-inventory'),
  _Item(Icons.lens_rounded,           'Lens Powers',    AppColors.purple, slug: 'ot-lens-powers'),
  _Item(Icons.card_giftcard_rounded,  'Packages',       AppColors.tealDark, slug: 'ot-packages'),
];

final _clinical = [
  _Item(Icons.assignment_rounded,  'Chief Complaints', Color(0xFFE74C3C),    slug: 'complaints', hasFavourite: true),
  _Item(Icons.favorite_rounded,    'K/C/O',            AppColors.orange, slug: 'kcos',       hasFavourite: true),
  _Item(Icons.history_rounded,     'H/O',              AppColors.teal,   slug: 'hno',        hasFavourite: true),
  _Item(Icons.verified_rounded,    'Diagnoses',        AppColors.green,  slug: 'diagnoses',  hasFavourite: true),
  _Item(Icons.chat_rounded,        'Advice',           AppColors.primary,   slug: 'advices',    hasFavourite: true),
];

final _vision = [
  _Item(Icons.visibility_rounded,          'V/N',       AppColors.teal,   slug: 'vn'),
  _Item(Icons.table_rows_rounded,          'Vn C GL',   AppColors.primary,   slug: 'vngl'),
  _Item(Icons.view_list_rounded,           'Vn C ST',   AppColors.primary,   slug: 'vnst'),
  _Item(Icons.visibility_off_rounded,      'PH NV/N',   AppColors.teal,   slug: 'pnvn'),
  _Item(Icons.center_focus_strong_rounded, 'NR V/N',    AppColors.teal,   slug: 'nrvn'),
  _Item(Icons.lens_rounded,                'SPH / CYL', AppColors.primary,   slug: 'sph_cyl',  hasSeeded: true),
  _Item(Icons.open_with_rounded,           'Axis',      Color(0xFF7F8C8D),   slug: 'axis'),
  _Item(Icons.timeline_rounded,            'NCT (IOP)', AppColors.orange, slug: 'nct'),
];

final _anterior = [
  _Item(Icons.water_drop_rounded,           'SAC',         AppColors.teal,   slug: 'sac',       hasFavourite: true),
  _Item(Icons.visibility_off_rounded,       'Lid',         Color(0xFF7F8C8D),   slug: 'lid',       hasFavourite: true),
  _Item(Icons.circle_rounded,               'Conjunctiva', Color(0xFFE74C3C),    slug: 'conj',      hasFavourite: true),
  _Item(Icons.radio_button_checked_rounded, 'Cornea',      AppColors.primary,   slug: 'cornea',    hasFavourite: true),
  _Item(Icons.layers_rounded,               'A/C',         AppColors.teal,   slug: 'ac',        hasFavourite: true),
  _Item(Icons.adjust_rounded,               'Iris',        AppColors.orange, slug: 'iris',      hasFavourite: true),
  _Item(Icons.fiber_manual_record_rounded,  'Pupil',       Color(0xFF2C3E50),   slug: 'pupil',     hasFavourite: true),
  _Item(Icons.camera_rounded,               'Lens',        AppColors.green,  slug: 'lens',      hasFavourite: true),
  _Item(Icons.open_in_full_rounded,         'E/M',         Color(0xFF7F8C8D),   slug: 'em',        hasFavourite: true),
  _Item(Icons.verified_user_rounded,        'Cover Test',  AppColors.green,  slug: 'covertest', hasFavourite: true),
];

const _posterior = [
  _Item(Icons.panorama_fish_eye_rounded,   'Disc', Color(0xFF7F8C8D), slug: 'disc', hasFavourite: true),
  _Item(Icons.signal_cellular_alt_rounded, 'F/R',  Color(0xFF7F8C8D), slug: 'fr',   hasFavourite: true),
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

    // Basic masters — each item gated by its own permission.
    // Referrers and Durations have no dedicated slug: shown to anyone with any basic master perm.
    final basicVisible = <_Item>[
      if (p.can(Perm.masterCaseTypes)) _basic[0],
      if (p.can(Perm.masterLocations)) _basic[1],
      if (p.can(Perm.masterCaseTypes) || p.can(Perm.masterLocations)) _basic[2],
      if (p.can(Perm.masterCaseTypes) || p.can(Perm.masterLocations)) _basic[3],
    ];
    final showBasic = basicVisible.isNotEmpty;

    // OT masters — each item gated by its own permission.
    // Lens Options has no dedicated slug: shown to anyone with any OT master perm.
    final otVisible = <_Item>[
      if (p.isSuper || p.can(Perm.masterOtSlots) || p.can(Perm.masterOtTypes) || p.can(Perm.masterOtCharges) || p.can(Perm.masterOtInventory))
        _ot[0], // Lens Options
      if (p.can(Perm.masterOtSlots))     _ot[1], // OT Slots
      if (p.can(Perm.masterOtTypes))     _ot[2], // OT Types
      if (p.can(Perm.masterOtTypes))     _ot[3], // Surgery Types
      if (p.can(Perm.masterOtCharges))   _ot[4], // Charge Heads
      if (p.can(Perm.masterOtInventory)) _ot[5], // Lens Inventory
      if (p.can(Perm.masterOtInventory)) _ot[6], // Lens Powers
      if (p.can(Perm.masterOtInventory)) _ot[7], // Packages
    ];
    final showOt      = otVisible.isNotEmpty;
    final showEyeExam = p.can(Perm.masterEyeExam);

    var visibleCount = 0;
    if (showBasic)   visibleCount += basicVisible.length;
    if (showOt)      visibleCount += otVisible.length;
    if (showEyeExam) visibleCount += _clinical.length + _vision.length +
        _anterior.length + _posterior.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.38),
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
                  AppSectionCard(
                    icon: Icons.grid_3x3_rounded,
                    title: 'Basic Masters',
                    color: AppColors.primary,
                    count: basicVisible.length,
                    child: _grid(context, basicVisible),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── OT ───────────────────────────────────────────────────
                if (showOt) ...[
                  AppSectionCard(
                    icon: Icons.local_hospital_rounded,
                    title: 'OT Masters',
                    color: AppColors.purple,
                    count: otVisible.length,
                    child: _grid(context, otVisible),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Eye Exam ─────────────────────────────────────────────
                if (showEyeExam) ...[
                  AppSectionCard(
                    icon: Icons.remove_red_eye_rounded,
                    title: 'Eye Exam Masters',
                    color: AppColors.teal,
                    count: _clinical.length + _vision.length +
                        _anterior.length + _posterior.length,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubGroup(
                            icon: Icons.assignment_outlined, label: 'Clinical'),
                        const SizedBox(height: 10),
                        _grid(context, _clinical),
                        _divider(),
                        _SubGroup(
                            icon: Icons.visibility_outlined,
                            label: 'Vision Values'),
                        const SizedBox(height: 10),
                        _grid(context, _vision),
                        _divider(),
                        _SubGroup(
                            icon: Icons.center_focus_weak_rounded,
                            label: 'Anterior Segment (O/E)'),
                        const SizedBox(height: 10),
                        _grid(context, _anterior),
                        _divider(),
                        _SubGroup(
                            icon: Icons.panorama_fish_eye_rounded,
                            label: 'Posterior Segment (Fundus)'),
                        const SizedBox(height: 10),
                        _grid(context, _posterior),
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
                size: 56, color: AppColors.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'No Access',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary.withValues(alpha: 0.50)),
            ),
            const SizedBox(height: 6),
            Text(
              'Your role has no master data permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary.withValues(alpha: 0.35)),
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
      showAppSnackBar(ctx, '${item.label} — Coming Soon', duration: const Duration(seconds: 2));
      return;
    }
    final screen = switch (item.slug) {
      'case-types'     => CaseTypeMasterScreen(accentColor: item.color),
      'referrers-crud' => ReferrerMasterScreen(accentColor: item.color),
      'ot-slots'        => OtSlotMasterScreen(accentColor: item.color),
      'ot-charge-heads'   => OtChargeHeadMasterScreen(accentColor: item.color),
      'ot-surgery-types'  => OtSurgeryTypeMasterScreen(accentColor: item.color),
      'lens-options'      => OtLensOptionMasterScreen(accentColor: item.color),
      'ot-types'          => OtTypeMasterScreen(accentColor: item.color),
      'ot-lens-inventory' => OtLensInventoryMasterScreen(accentColor: item.color),
      'ot-lens-powers'    => OtLensPowerMasterScreen(accentColor: item.color),
      'ot-packages'       => OtPackageMasterScreen(accentColor: item.color),
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

  static Widget _grid(BuildContext context, List<_Item> items) => AppItemGrid(
        items: items.map((i) => AppGridItem(icon: i.icon, label: i.label, color: i.color, onTap: () => _open(context, i))).toList(),
      );
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
        color: AppColors.surfaceFill,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: AppColors.primaryA70),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary.withValues(alpha: 0.80),
                letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }
}
