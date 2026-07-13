import 'package:flutter/material.dart';
import '../utils/app_route.dart';
import '../constants/permissions.dart';
import '../widgets/app_animations.dart';
import '../models/auth_models.dart';
import '../services/permission_service.dart';
import '../services/user_service.dart';
import 'user_form_screen.dart';

// ── Pre-computed alpha variants ───────────────────────────────────────────────
const _navy    = Color(0xFF1B4F72);
const _textSub = Color(0xFF64748B);
// white
const _white65 = Color(0xA6FFFFFF);
const _white55 = Color(0x8CFFFFFF);
const _white18 = Color(0x2EFFFFFF);
const _white15 = Color(0x26FFFFFF);
const _white12 = Color(0x1FFFFFFF);
// navy alphas
const _navyA18 = Color(0x2E1B4F72);
const _navyA07 = Color(0x121B4F72);
const _navyA05 = Color(0x0D1B4F72);
// textSub alphas
const _textSubA80 = Color(0xCC64748B);
const _textSubA70 = Color(0xB364748B);
const _textSubA65 = Color(0xA664748B);
const _textSubA50 = Color(0x8064748B);

class UsersScreen extends StatefulWidget {
  final UserInfo user;
  final HospitalInfo hospital;

  const UsersScreen({super.key, required this.user, required this.hospital});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const _navy   = Color(0xFF1B4F72);
  static const _bg     = Color(0xFFEAF2F8);
  static const _textSub = Color(0xFF64748B);

  final _searchCtrl  = TextEditingController();
  final _scrollCtrl  = ScrollController();

  List<HospitalUserModel> _users  = [];
  int  _currentPage = 1;
  int  _lastPage    = 1;
  int  _total       = 0;
  bool _loading     = true;
  bool _loadingMore = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error   = null;
        _currentPage = 1;
      });
    }

    try {
      final resp = await UserService.instance.fetchUsers(
        page:   _currentPage,
        search: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        if (refresh || _currentPage == 1) {
          _users = resp.users;
        } else {
          _users.addAll(resp.users);
        }
        _currentPage = resp.currentPage;
        _lastPage    = resp.lastPage;
        _total       = resp.total;
        _loading     = false;
        _error       = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error   = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() => _loadingMore = true);
    _currentPage++;
    try {
      final resp = await UserService.instance.fetchUsers(
        page:   _currentPage,
        search: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(resp.users);
        _lastPage    = resp.lastPage;
        _total       = resp.total;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String value) {
    _search = value;
    _load(refresh: true);
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      appRoute(UserFormScreen(
        user:     widget.user,
        hospital: widget.hospital,
      )),
    );
    if (result == true) _load(refresh: true);
  }

  Future<void> _openEdit(HospitalUserModel u) async {
    final result = await Navigator.push<bool>(
      context,
      appRoute(UserFormScreen(
        user:       widget.user,
        hospital:   widget.hospital,
        editUser:   u,
      )),
    );
    if (result == true) _load(refresh: true);
  }

  Future<void> _confirmDelete(HospitalUserModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User',
            style: TextStyle(fontWeight: FontWeight.w800, color: _navy)),
        content: Text(
          'Delete "${u.name}"? This action cannot be undone.',
          style: const TextStyle(color: _textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await UserService.instance.deleteUser(u.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${u.name}" deleted successfully'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _load(refresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _toggleStatus(HospitalUserModel u) async {
    try {
      final newStatus = await UserService.instance.toggleStatus(u.id);
      if (!mounted) return;
      setState(() {
        final idx = _users.indexWhere((x) => x.id == u.id);
        if (idx >= 0) {
          _users[idx] = HospitalUserModel(
            id:              u.id,
            name:            u.name,
            email:           u.email,
            contact:         u.contact,
            status:          newStatus,
            role:            u.role,
            focPermission:   u.focPermission,
            lastLoginAt:     u.lastLoginAt,
            doctorType:      u.doctorType,
            doctorPrefix:    u.doctorPrefix,
            registrationNo:  u.registrationNo,
            experienceYears: u.experienceYears,
            signatureUrl:    u.signatureUrl,
            profilePhotoUrl: u.profilePhotoUrl,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PermissionService.instance;
    if (!p.can(Perm.masterDoctors) &&
        !p.can(Perm.masterReceptions) &&
        !p.can(Perm.masterOtStaff)) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Users',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 56,
                    color: _navy.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text('No Access',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: _navy.withValues(alpha: 0.50))),
                const SizedBox(height: 6),
                Text('You do not have permission to manage users.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _navy.withValues(alpha: 0.35))),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Users',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (!_loading && _error == null)
              Text(
                '$_total member${_total == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _white65,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _white15,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            ),
            tooltip: 'Add User',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _navy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: _white12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _white18),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name, email or contact...',
            hintStyle: TextStyle(
              color: _white55,
              fontSize: 13,
            ),
            prefixIcon: Icon(Icons.search_rounded,
                color: _white65, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: _white65),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _navy),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 52, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSub, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _load(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts_rounded,
                size: 64, color: _navyA18),
            const SizedBox(height: 16),
            Text(
              _search.isEmpty
                  ? 'No users yet.\nTap + to add the first user.'
                  : 'No users match "$_search"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSubA70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _navy,
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        itemCount: _users.length + (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _users.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: _navy)),
            );
          }
          return AnimatedListItem(
            index: i,
            child: RepaintBoundary(
              child: _UserCard(
                user: _users[i],
                onEdit:   () => _openEdit(_users[i]),
                onDelete: () => _confirmDelete(_users[i]),
                onToggleStatus: () => _toggleStatus(_users[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final HospitalUserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  static const _navy = Color(0xFF1B4F72);

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = user.role?.parsedColor ?? _navy;
    final isActive  = user.status == 'active';
    final initials  = _initials(user.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _navyA07),
        boxShadow: [
          BoxShadow(
            color: _navyA05,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: roleColor.withValues(alpha: 0.20)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Main Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _navy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onToggleStatus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSubA80,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (user.role != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: roleColor.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                user.role!.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (user.role?.isDoctorRole == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            user.doctorPrefix != null
                                ? 'Dr. ${user.doctorPrefix}'
                                : 'Doctor',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      if (user.contact.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.phone_rounded,
                            size: 11,
                            color: _textSubA50),
                        const SizedBox(width: 2),
                        Text(
                          user.contact,
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSubA65,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: _navy,
                  onTap: onEdit,
                ),
                const SizedBox(height: 6),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
