import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationMasterScreen extends StatefulWidget {
  final Color accentColor;

  const LocationMasterScreen({
    super.key,
    this.accentColor = const Color(0xFF27AE60),
  });

  @override
  State<LocationMasterScreen> createState() => _LocationMasterScreenState();
}

class _LocationMasterScreenState extends State<LocationMasterScreen> {
  static const _navy = Color(0xFF1B4F72);
  static const _red  = Color(0xFFDC3545);
  static const _bg   = Color(0xFFEAF2F8);

  List<LocationItem> _all = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  List<LocationItem> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((i) =>
        i.city.toLowerCase().contains(q) ||
        (i.district ?? '').toLowerCase().contains(q) ||
        (i.state ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await LocationService.instance.fetchAll();
      if (mounted) {
        setState(() { _all = items; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Locations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Read-only — managed by platform',
              child: Icon(Icons.lock_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildCount(),
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
          boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A3A52)),
          decoration: const InputDecoration(
            hintText: 'Search city, district, or state...',
            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded,
                color: Color(0xFF94A3B8), size: 20),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCount() {
    if (_loading || _error != null) return const SizedBox.shrink();
    final count = _filtered.length;
    final total = _all.length;
    final label = _query.isNotEmpty
        ? '$count of $total locations'
        : '$total locations';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label,
            style: TextStyle(
              fontSize: 11.5,
              color: _navy.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
            )),
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
      return ListView(children: [
        const SizedBox(height: 72),
        Center(
          child: Column(children: [
            Icon(Icons.location_on_rounded,
                size: 56, color: _navy.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty
                  ? 'No results for "$_query"'
                  : 'No locations found.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      ]);
    }

    return RefreshIndicator(
      color: _navy,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 40),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final sub = item.subtitle;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _navy.withValues(alpha: 0.08)),
                boxShadow: [BoxShadow(
                  color: _navy.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )],
              ),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 36, height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.location_on_rounded,
                        size: 18, color: widget.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.city,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A3A52),
                            )),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sub,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _navy.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
