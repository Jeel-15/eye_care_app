import 'package:flutter/material.dart';
import '../services/simple_master_service.dart';

class GenericMasterScreen extends StatefulWidget {
  final String title;

  /// API path relative to hospitalApiUrl — e.g. 'masters/detail/complaints'
  final String apiPath;
  final Color accentColor;
  final IconData icon;
  final bool hasFavourite;
  final bool hasSeeded;

  const GenericMasterScreen({
    super.key,
    required this.title,
    required this.apiPath,
    required this.accentColor,
    this.icon = Icons.list_rounded,
    this.hasFavourite = false,
    this.hasSeeded = false,
  });

  @override
  State<GenericMasterScreen> createState() => _GenericMasterScreenState();
}

class _GenericMasterScreenState extends State<GenericMasterScreen> {
  static const _navy   = Color(0xFF1B4F72);
  static const _red    = Color(0xFFDC3545);
  static const _bg     = Color(0xFFEAF2F8);

  List<SimpleMasterItem> _all = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  List<SimpleMasterItem> get _filtered => _query.isEmpty
      ? _all
      : _all
          .where((i) => i.value.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await SimpleMasterService.instance.fetchAll(widget.apiPath);
      if (mounted) setState(() { _all = items; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFav(SimpleMasterItem item) async {
    try {
      final newFav = await SimpleMasterService.instance
          .toggleFavourite(widget.apiPath, item.id);
      if (!mounted) return;
      setState(() {
        final idx = _all.indexWhere((i) => i.id == item.id);
        if (idx != -1) _all[idx] = item.copyWith(isFavourite: newFav);
        _all.sort((a, b) {
          if (a.isFavourite == b.isFavourite) return a.value.compareTo(b.value);
          return a.isFavourite ? -1 : 1;
        });
      });
    } catch (_) {}
  }

  Future<void> _delete(SimpleMasterItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete "${item.value}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await SimpleMasterService.instance.delete(widget.apiPath, item.id);
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  void _openSheet({SimpleMasterItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MasterSheet(
        title: item == null ? 'Add ${widget.title}' : 'Edit ${widget.title}',
        initialValue: item?.value ?? '',
        initialFav: item?.isFavourite ?? false,
        hasFavourite: widget.hasFavourite,
        accentColor: widget.accentColor,
        onSave: (value, isFav) async {
          if (item == null) {
            await SimpleMasterService.instance
                .create(widget.apiPath, value, isFavourite: isFav);
          } else {
            await SimpleMasterService.instance
                .update(widget.apiPath, item.id, value, isFavourite: isFav);
          }
          await _load();
        },
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : _navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            tooltip: 'Add',
            onPressed: () => _openSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _navy.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(color: _navy.withValues(alpha: 0.05), blurRadius: 8)
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A3A52)),
          decoration: InputDecoration(
            hintText: 'Search ${widget.title.toLowerCase()}...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon:
                const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: _red.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _navy, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 72),
          Center(
            child: Column(
              children: [
                Icon(widget.icon,
                    size: 56, color: _navy.withValues(alpha: 0.15)),
                const SizedBox(height: 12),
                Text(
                  _query.isNotEmpty
                      ? 'No results for "$_query"'
                      : 'No ${widget.title.toLowerCase()} yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: _navy,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
        itemCount: items.length,
        itemBuilder: (_, i) => _ItemRow(
          index: i,
          item: items[i],
          hasFavourite: widget.hasFavourite,
          accentColor: widget.accentColor,
          onEdit: () => _openSheet(item: items[i]),
          onDelete: () => _delete(items[i]),
          onToggleFav: () => _toggleFav(items[i]),
        ),
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final int index;
  final SimpleMasterItem item;
  final bool hasFavourite;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFav;

  const _ItemRow({
    required this.index,
    required this.item,
    required this.hasFavourite,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF1B4F72).withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4F72).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Serial number badge
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Value text
            Expanded(
              child: Text(
                item.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A3A52),
                ),
              ),
            ),
            // Favourite toggle
            if (hasFavourite)
              GestureDetector(
                onTap: onToggleFav,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    item.isFavourite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 22,
                    color: item.isFavourite
                        ? const Color(0xFFE67E22)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            // Seeded → lock icon, no actions
            if (item.isSeeded)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.lock_outline_rounded,
                    size: 18, color: Color(0xFF94A3B8)),
              )
            else ...[
              _Btn(
                icon: Icons.edit_outlined,
                color: const Color(0xFFE67E22),
                onTap: onEdit,
              ),
              const SizedBox(width: 2),
              _Btn(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFDC3545),
                onTap: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── Add / Edit bottom sheet ───────────────────────────────────────────────────

class _MasterSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final bool initialFav;
  final bool hasFavourite;
  final Color accentColor;
  final Future<void> Function(String value, bool isFavourite) onSave;

  const _MasterSheet({
    required this.title,
    required this.initialValue,
    required this.initialFav,
    required this.hasFavourite,
    required this.accentColor,
    required this.onSave,
  });

  @override
  State<_MasterSheet> createState() => _MasterSheetState();
}

class _MasterSheetState extends State<_MasterSheet> {
  static const _navy = Color(0xFF1B4F72);

  late final TextEditingController _ctrl;
  late bool _fav;
  bool _saving = false;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _fav  = widget.initialFav;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = _ctrl.text.trim();
    if (v.isEmpty) {
      setState(() => _fieldError = 'Value is required');
      return;
    }
    setState(() { _saving = true; _fieldError = null; });
    try {
      await widget.onSave(v, _fav);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC3545),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_rounded,
                      size: 16, color: widget.accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A3A52),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Value field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TextFormField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Value',
                errorText: _fieldError,
                filled: true,
                fillColor: const Color(0xFFF0F6FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                ),
              ),
            ),
          ),
          // Favourite toggle
          if (widget.hasFavourite)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SwitchListTile(
                dense: true,
                title: const Text(
                  'Mark as Favourite',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A3A52)),
                ),
                subtitle: Text(
                  _fav ? 'Appears at top of list' : 'Standard order',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                secondary: Icon(
                  _fav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: _fav
                      ? const Color(0xFFE67E22)
                      : const Color(0xFF94A3B8),
                ),
                value: _fav,
                activeThumbColor: _navy,
                activeTrackColor: _navy.withValues(alpha: 0.35),
                onChanged: (v) => setState(() => _fav = v),
              ),
            ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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
