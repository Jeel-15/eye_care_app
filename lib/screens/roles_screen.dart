import 'package:flutter/material.dart';
import '../utils/app_route.dart';
import '../constants/permissions.dart';
import '../widgets/app_animations.dart';
import '../models/auth_models.dart';
import '../models/role_models.dart';
import '../services/permission_service.dart';
import '../services/roles_service.dart';

abstract final class _C {
  static const navy  = Color(0xFF1B4F72);
  static const teal  = Color(0xFF1ABC9C);
  static const green = Color(0xFF27AE60);
  static const red   = Color(0xFFDC3545);

  static final navyA08  = navy.withValues(alpha: 0.08);
  static final greenA10 = green.withValues(alpha: 0.10);
}

// ─────────────────────────────────────────────────────────────────────────────
// Roles list screen
// ─────────────────────────────────────────────────────────────────────────────

class RolesScreen extends StatefulWidget {
  final UserInfo user;
  final HospitalInfo hospital;
  final VoidCallback? onMenuTap;

  const RolesScreen({
    super.key,
    required this.user,
    required this.hospital,
    this.onMenuTap,
  });

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final _p = PermissionService.instance;

  bool _loading = false;
  String? _error;
  List<RoleModel> _roles = [];

  bool get _canManage => _p.can(Perm.masterRoles);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final roles = await RolesService.instance.fetchRoles();
      if (mounted) setState(() { _roles = roles; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _confirmDelete(RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Role'),
        content: Text('Delete role "${role.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await RolesService.instance.deleteRole(role.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role "${role.name}" deleted.'),
            backgroundColor: _C.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: _C.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: _C.navy,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Roles & Permissions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          Text(widget.hospital.name,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load),
        ],
        leading: widget.onMenuTap != null
            ? IconButton(
                icon: const Icon(Icons.menu), onPressed: widget.onMenuTap)
            : null,
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              backgroundColor: _C.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Role'),
              onPressed: () => _openRoleEditor(context, null),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: _C.red, size: 48),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: _C.red)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      );
    }
    if (_roles.isEmpty) {
      return const Center(
        child: Text('No roles found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        itemCount: _roles.length,
        itemBuilder: (_, i) => AnimatedListItem(index: i, child: _buildRoleCard(_roles[i])),
      ),
    );
  }

  Widget _buildRoleCard(RoleModel role) {
    Color roleColor;
    try {
      final hex = role.color.replaceFirst('#', '');
      roleColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      roleColor = _C.navy;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _canManage
            ? () => _openRoleEditor(context, role)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Color dot
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, color: roleColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Role info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(role.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _C.navy)),
                  if (role.isSuper) ...[
                    const SizedBox(width: 6),
                    _badge('Super Admin', _C.teal),
                  ],
                  if (role.isSystem) ...[
                    const SizedBox(width: 6),
                    _badge('System', Colors.grey),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  '${role.usersCount} user${role.usersCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (role.description != null && role.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(role.description!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
              ]),
            ),
            // Actions
            if (_canManage)
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: _C.navy,
                  tooltip: 'Edit',
                  onPressed: () => _openRoleEditor(context, role),
                ),
                if (role.isDeletable)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: _C.red,
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(role),
                  ),
              ]),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Future<void> _openRoleEditor(BuildContext context, RoleModel? existing) async {
    final result = await Navigator.push<bool>(
      context,
      appRoute(RoleEditorScreen(
        hospital: widget.hospital,
        existing: existing,
      )),
    );
    if (result == true) _load();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role editor — create or edit with permission checkboxes
// ─────────────────────────────────────────────────────────────────────────────

class RoleEditorScreen extends StatefulWidget {
  final HospitalInfo hospital;
  final RoleModel? existing;

  const RoleEditorScreen({
    super.key,
    required this.hospital,
    this.existing,
  });

  @override
  State<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends State<RoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _loading = true;
  bool _saving  = false;
  String? _error;

  // Permissions: module → list of items (mutable, isGranted toggled by user)
  Map<String, List<RolePermissionItem>> _permissions = {};

  bool get _isEdit => widget.existing != null;
  bool get _isSuper => widget.existing?.isSuper ?? false;
  bool get _isSystem => widget.existing?.isSystem ?? false;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description ?? '';
    }
    _loadPermissions();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isEdit) {
        // Load role with its current permission assignments
        final role = await RolesService.instance.fetchRole(widget.existing!.id);
        if (mounted) setState(() { _permissions = _deepCopy(role.permissions); _loading = false; });
      } else {
        // Load all available permissions (none granted yet)
        final all = await RolesService.instance.fetchAllPermissions();
        if (mounted) setState(() { _permissions = _deepCopy(all.modules); _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Map<String, List<RolePermissionItem>> _deepCopy(
      Map<String, List<RolePermissionItem>> src) {
    return {
      for (final e in src.entries)
        e.key: e.value.map((p) => p.copyWith()).toList(),
    };
  }

  List<int> get _grantedIds => _permissions.values
      .expand((list) => list)
      .where((p) => p.isGranted)
      .map((p) => p.id)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (_isEdit) {
        await RolesService.instance.updateRole(
          id: widget.existing!.id,
          name: _isSystem ? null : _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          permissionIds: _isSuper ? null : _grantedIds,
        );
      } else {
        await RolesService.instance.createRole(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          permissionIds: _grantedIds,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: _C.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: _C.navy,
        foregroundColor: Colors.white,
        title: Text(
          _isEdit ? 'Edit Role' : 'New Role',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, color: _C.red, size: 48),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: _C.red)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadPermissions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ]),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildNameCard(),
                      const SizedBox(height: 16),
                      if (!_isSuper) ..._buildPermissionCards(),
                      if (_isSuper)
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              const Icon(Icons.verified_user,
                                  color: _C.teal, size: 28),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Super Admin bypasses all permission checks — '
                                  'permissions cannot be edited for this role.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNameCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextFormField(
            controller: _nameCtrl,
            enabled: !_isSystem,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Role name is required' : null,
            decoration: InputDecoration(
              labelText: 'Role Name',
              hintText: 'e.g. Nurse',
              border: const OutlineInputBorder(),
              helperText: _isSystem ? 'System role name cannot be changed.' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildPermissionCards() {
    return _permissions.entries.map((entry) {
      final module = entry.key;
      final perms  = entry.value;
      final grantedCount = perms.where((p) => p.isGranted).length;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1.5,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: grantedCount > 0,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Row(children: [
                Text(
                  _moduleLabel(module),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: _C.navy, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: grantedCount > 0 ? _C.greenA10 : _C.navyA08,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$grantedCount / ${perms.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            grantedCount > 0 ? _C.green : Colors.grey.shade600),
                  ),
                ),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                // Toggle-all button
                TextButton(
                  onPressed: () {
                    final allGranted = perms.every((p) => p.isGranted);
                    setState(() {
                      for (var i = 0; i < perms.length; i++) {
                        perms[i] = perms[i].copyWith(isGranted: !allGranted);
                      }
                    });
                  },
                  child: Text(
                    perms.every((p) => p.isGranted) ? 'None' : 'All',
                    style: const TextStyle(fontSize: 12, color: _C.navy),
                  ),
                ),
                const Icon(Icons.expand_more, color: _C.navy),
              ]),
              children: perms.asMap().entries.map((e) {
                final idx  = e.key;
                final perm = e.value;
                return CheckboxListTile(
                  dense: true,
                  value: perm.isGranted,
                  activeColor: _C.navy,
                  title: Text(perm.label,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: perm.description.isNotEmpty
                      ? Text(perm.description,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600))
                      : null,
                  onChanged: (val) {
                    setState(() {
                      perms[idx] = perms[idx].copyWith(isGranted: val ?? false);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _moduleLabel(String module) {
    const labels = {
      'opd': 'OPD',
      'ot': 'OT (Operation Theatre)',
      'master': 'Masters',
      'settings': 'Settings',
      'reports': 'Reports',
    };
    return labels[module] ??
        module[0].toUpperCase() + module.substring(1);
  }
}
