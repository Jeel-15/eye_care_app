import 'package:flutter/material.dart';
import '../utils/app_route.dart';
import '../models/auth_models.dart';
import '../models/medicine_models.dart';
import '../services/medicine_service.dart';
import 'medicine_group_form_screen.dart';

// ── Color constants ────────────────────────────────────────────────────────────

abstract final class _C {
  static const navy    = Color(0xFF1B4F72);
  static const teal    = Color(0xFF2C6E99);
  static const success = Color(0xFF1F9D55);
  static const danger  = Color(0xFFD94841);
  static const muted   = Color(0xFF6B7D93);
  static const text    = Color(0xFF18324A);
  static const bg      = Color(0xFFF6FAFD);

  static final navyA06   = navy.withValues(alpha: 0.06);
  static final navyA10   = navy.withValues(alpha: 0.10);
  static final navyA12   = navy.withValues(alpha: 0.12);
  static final mutedA60  = muted.withValues(alpha: 0.60);
  static final successA12 = success.withValues(alpha: 0.12);
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.navyA10),
      boxShadow: [BoxShadow(color: _C.navyA06, blurRadius: 8, offset: const Offset(0, 2))],
    );

// ═════════════════════════════════════════════════════════════════════════════
// DETAIL SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class MedicineGroupDetailScreen extends StatefulWidget {
  final UserInfo user;
  final HospitalInfo hospital;
  final int groupId;

  const MedicineGroupDetailScreen({
    super.key,
    required this.user,
    required this.hospital,
    required this.groupId,
  });

  @override
  State<MedicineGroupDetailScreen> createState() => _MedicineGroupDetailScreenState();
}

class _MedicineGroupDetailScreenState extends State<MedicineGroupDetailScreen> {
  MedGroup? _group;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final g = await MedicineService.instance.fetchGroup(widget.groupId);
      if (mounted) setState(() { _group = g; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _pushEdit() async {
    final refreshed = await Navigator.push<bool>(
      context,
      appRoute(MedicineGroupFormScreen(
        user: widget.user,
        hospital: widget.hospital,
        existing: _group,
      )),
    );
    if (refreshed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _group?.name ?? 'Group Detail',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_group != null)
            IconButton(
              onPressed: _pushEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.navy))
          : _error != null
              ? _ErrorWidget(message: _error!, onRetry: _load)
              : _group != null
                  ? _buildBody(_group!)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildBody(MedGroup group) {
    return RefreshIndicator(
      onRefresh: _load,
      color: _C.navy,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _C.navy),
                          ),
                          if (group.groupCode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              group.groupCode!,
                              style: TextStyle(fontSize: 13, color: _C.mutedA60, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _C.navyA12, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${group.itemsCount} med${group.itemsCount == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _C.navy),
                      ),
                    ),
                  ],
                ),
                if (group.diagnosisValue != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_outlined, size: 14, color: _C.success),
                      const SizedBox(width: 5),
                      Text(
                        group.diagnosisValue!,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.success),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Items
          if (group.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: _cardDeco(),
              child: Center(
                child: Text(
                  'No medicines in this group.',
                  style: TextStyle(color: _C.mutedA60, fontSize: 14),
                ),
              ),
            )
          else
            Container(
              decoration: _cardDeco(),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: _C.navyA06,
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text('Medicine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _C.navy)),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text('Dosage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _C.navy)),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text('Duration', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _C.navy)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Route', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _C.navy)),
                        ),
                        const SizedBox(
                          width: 40,
                          child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _C.navy), textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                  ...group.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _C.navyA10),
                        ),
                        color: i.isEven ? Colors.white : _C.navyA06,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.medicineName ?? '-',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.text),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.dosageText ?? '-',
                              style: TextStyle(fontSize: 12, color: _C.mutedA60),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.duration ?? '-',
                              style: TextStyle(fontSize: 12, color: _C.mutedA60),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.routeName ?? '-',
                              style: TextStyle(fontSize: 12, color: _C.mutedA60),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _C.navy),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pushEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Group', style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.navy,
                side: BorderSide(color: _C.navyA10, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: _C.mutedA60),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _C.muted, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.navy, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
}
