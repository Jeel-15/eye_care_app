import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

/// The 3 severe, whole-screen-blocking failure moments this app actually
/// hits (see `base_service.dart`'s `parseApiResponse`) — distinct from the
/// small inline `AppErrorState` used for ordinary per-section load
/// failures. Each reads its own hero illustration, status chip and copy;
/// [generic] is the fallback for anything that doesn't match one of the
/// other three's known message shape.
enum AppErrorKind { connectionLost, recordNotFound, serverError, generic }

AppErrorKind _detectKind(String message) {
  final m = message.toLowerCase();
  if (m.contains('socketexception') ||
      m.contains('timeoutexception') ||
      m.contains('failed host lookup') ||
      m.contains('connection refused') ||
      m.contains('network is unreachable') ||
      m.contains('no internet')) {
    return AppErrorKind.connectionLost;
  }
  if (m.contains('record not found')) return AppErrorKind.recordNotFound;
  if (m.contains('server error')) return AppErrorKind.serverError;
  return AppErrorKind.generic;
}

/// Full-screen takeover for a severe, whole-screen load failure — app
/// launch/home/dashboard failing to load, or a single record (opened by
/// ID) turning out to be gone. Reserved for moments like these; an
/// in-page list/section that fails to load still uses the small inline
/// `AppErrorState`, not this.
///
/// [message] is whatever the catch block already has (same string every
/// existing call site already passes to `AppErrorState`) — the error kind
/// is auto-detected from it unless [kind] is given explicitly. Drop-in
/// replacement: swap `AppErrorState(message: e, onRetry: _load)` for
/// `AppFullScreenError(message: e, onRetry: _load)`.
class AppFullScreenError extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  final AppErrorKind? kind;
  /// Shown as a small pill under the description — e.g. "Last searched:
  /// #MRD-90421" for a not-found record, or an incident ref for a server
  /// error. Omitted entirely when null.
  final String? infoPillText;
  final IconData? infoPillIcon;
  /// Secondary action below the primary button — e.g. "Return to Home" /
  /// "Continue Offline". Omitted when null (just the primary button shows).
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  const AppFullScreenError({
    super.key,
    required this.message,
    required this.onRetry,
    this.kind,
    this.infoPillText,
    this.infoPillIcon,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  @override
  State<AppFullScreenError> createState() => _AppFullScreenErrorState();
}

class _AppFullScreenErrorState extends State<AppFullScreenError> with TickerProviderStateMixin {
  // One slow, repeating "ambient" clock drives every float/twinkle/pulse
  // below (via sin() at different phase offsets) instead of a controller
  // per element — cheaper, and it's what keeps the whole scene feeling like
  // one living illustration rather than several unrelated loops.
  late final AnimationController _ambient;
  // Plays once — the icon badge pops in and the sheet slides up from
  // under the fold, matching the reference's own entrance feel instead of
  // the content just appearing instantly.
  late final AnimationController _entrance;
  late final Animation<double> _entranceCurve;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _entranceCurve = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    _entrance.forward();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedKind = widget.kind ?? _detectKind(widget.message);
    final config = _kindConfig(resolvedKind, widget.message);

    // No `Scaffold` of its own — every call site already has one (its own
    // AppBar, e.g. "Dashboard"), this is a `body:`-slot drop-in replacement
    // for the plain inline `AppErrorState`.
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: _Hero(kind: resolvedKind, config: config, ambient: _ambient, entrance: _entranceCurve),
          ),
          Expanded(
            flex: 6,
            child: AnimatedBuilder(
              animation: _entranceCurve,
              builder: (context, child) {
                final t = _entranceCurve.value;
                return Transform.translate(
                  offset: Offset(0, (1 - t) * 28),
                  child: Opacity(opacity: t.clamp(0, 1), child: child),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Color(0x1A001E50), blurRadius: 40, offset: Offset(0, -16)),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textDisabled.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _StatusChip(text: config.chipText, color: config.accent),
                      const SizedBox(height: 14),
                      Text(
                        config.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.darkNavy, height: 1.15),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        config.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
                      ),
                      if (widget.infoPillText != null) ...[
                        const SizedBox(height: 16),
                        _InfoPill(icon: widget.infoPillIcon ?? Icons.info_outline_rounded, text: widget.infoPillText!),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: _PressScale(
                          onTap: widget.onRetry,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(config.primaryIcon, size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(config.primaryLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.secondaryLabel != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _PressScale(
                            onTap: widget.onSecondary,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.textDisabled.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(widget.secondaryIcon ?? Icons.home_outlined, size: 18, color: AppColors.darkNavy),
                                  const SizedBox(width: 8),
                                  Text(widget.secondaryLabel!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkNavy)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ErrorKindConfig _kindConfig(AppErrorKind k, String message) {
    switch (k) {
      case AppErrorKind.connectionLost:
        return _ErrorKindConfig(
          accent: AppColors.orange,
          chipText: 'OFFLINE · NO CONNECTION',
          title: 'Connection Lost',
          description: 'We lost signal with the hospital network. Check your internet and try again.',
          primaryIcon: Icons.refresh_rounded,
          primaryLabel: 'Try Again',
        );
      case AppErrorKind.recordNotFound:
        return _ErrorKindConfig(
          accent: AppColors.purple,
          chipText: '404 · NOT FOUND',
          title: 'Record Not Found',
          description: 'This record may have been moved, deleted, or does not exist under your current hospital.',
          primaryIcon: Icons.refresh_rounded,
          primaryLabel: 'Retry',
        );
      case AppErrorKind.serverError:
        return _ErrorKindConfig(
          accent: AppColors.red,
          chipText: 'HTTP 500 · SERVER ERROR',
          title: 'Server Taking a Quick Nap',
          description: 'Our server ran into a problem on its end. Your data is safe — please try again in a moment.',
          primaryIcon: Icons.refresh_rounded,
          primaryLabel: 'Try Again',
        );
      case AppErrorKind.generic:
        return _ErrorKindConfig(
          accent: AppColors.textSecondary,
          chipText: 'SOMETHING WENT WRONG',
          title: 'Unable to Load',
          description: message,
          primaryIcon: Icons.refresh_rounded,
          primaryLabel: 'Try Again',
        );
    }
  }
}

class _ErrorKindConfig {
  final Color accent;
  final String chipText;
  final String title;
  final String description;
  final IconData primaryIcon;
  final String primaryLabel;
  const _ErrorKindConfig({
    required this.accent,
    required this.chipText,
    required this.title,
    required this.description,
    required this.primaryIcon,
    required this.primaryLabel,
  });
}

// ── Hero illustration ───────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final AppErrorKind kind;
  final _ErrorKindConfig config;
  final Animation<double> ambient;
  final Animation<double> entrance;
  const _Hero({required this.kind, required this.config, required this.ambient, required this.entrance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.blueLight],
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([ambient, entrance]),
        builder: (context, _) {
          final t = ambient.value; // 0..1 looping
          return Stack(
            alignment: Alignment.center,
            children: [
              ..._ambientDots(t),
              Transform.scale(
                scale: Curves.easeOutBack.transform(entrance.value.clamp(0, 1)),
                child: _centerpiece(t),
              ),
            ],
          );
        },
      ),
    );
  }

  double _bob(double t, double phase, double amplitude) => math.sin((t + phase) * 2 * math.pi) * amplitude;

  List<Widget> _ambientDots(double t) {
    final positions = <(double dx, double dy, double size, double phase)>[
      (0.18, 0.22, 7, 0.0),
      (0.82, 0.28, 5, 0.3),
      (0.14, 0.72, 6, 0.55),
      (0.86, 0.68, 8, 0.15),
      (0.50, 0.12, 4, 0.7),
    ];
    return [
      for (final p in positions)
        Align(
          alignment: Alignment(p.$1 * 2 - 1, p.$2 * 2 - 1),
          child: Transform.translate(
            offset: Offset(0, _bob(t, p.$4, 6)),
            child: Opacity(
              opacity: (0.35 + 0.45 * ((math.sin((t + p.$4) * 2 * math.pi) + 1) / 2)).clamp(0.0, 1.0),
              child: Container(
                width: p.$3,
                height: p.$3,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _centerpiece(double t) {
    switch (kind) {
      case AppErrorKind.connectionLost:
        return _ConnectionLostMascot(t: t);
      case AppErrorKind.recordNotFound:
        return _RecordNotFoundMascot(t: t);
      case AppErrorKind.serverError:
        return _ServerErrorMascot(t: t);
      case AppErrorKind.generic:
        return _GenericMascot(t: t, accent: config.accent);
    }
  }
}

/// The soft blurred shadow every illustration casts on the "ground" — reads
/// as a physical object floating/bobbing above it rather than a flat icon.
Widget _mascotShadow(double width) => ImageFiltered(
  imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 4),
  child: Container(
    width: width,
    height: 16,
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(40)),
  ),
);

/// Wraps one of the real reference illustrations (ported 1:1 from the
/// client-supplied Stitch design — see
/// `assets/illustrations/*.svg` and PROJECT_TRACKER.md) in the same
/// shadow + gentle bob every kind shares, instead of each kind inventing
/// its own stage.
Widget _svgMascot({required double t, required String asset, required double width, required double shadowWidth, double bobAmplitude = 8}) {
  final bob = math.sin(t * 2 * math.pi) * bobAmplitude;
  return SizedBox(
    width: width + 20,
    height: width + 30,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(bottom: 8, child: _mascotShadow(shadowWidth)),
        Transform.translate(
          offset: Offset(0, bob),
          child: SvgPicture.asset(asset, width: width, height: width),
        ),
      ],
    ),
  );
}

class _ConnectionLostMascot extends StatelessWidget {
  final double t;
  const _ConnectionLostMascot({required this.t});

  @override
  Widget build(BuildContext context) =>
      _svgMascot(t: t, asset: 'assets/illustrations/connection_lost.svg', width: 190, shadowWidth: 110);
}

class _RecordNotFoundMascot extends StatelessWidget {
  final double t;
  const _RecordNotFoundMascot({required this.t});

  @override
  Widget build(BuildContext context) =>
      _svgMascot(t: t, asset: 'assets/illustrations/record_not_found.svg', width: 210, shadowWidth: 120, bobAmplitude: 6);
}

class _ServerErrorMascot extends StatelessWidget {
  final double t;
  const _ServerErrorMascot({required this.t});

  @override
  Widget build(BuildContext context) =>
      _svgMascot(t: t, asset: 'assets/illustrations/server_maintenance.svg', width: 200, shadowWidth: 128, bobAmplitude: 6);
}

class _GenericMascot extends StatelessWidget {
  final double t;
  final Color accent;
  const _GenericMascot({required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    final bob = math.sin(t * 2 * math.pi) * 7;
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(bottom: 10, child: _mascotShadow(84)),
          Transform.translate(
            offset: Offset(0, bob),
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.error_outline_rounded, size: 46, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet chrome ─────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny tactile press-scale wrapper for the two buttons — kept local
/// (not importing the app-wide `PressScaleWrapper`) to avoid coupling this
/// standalone widget file to another widget file's internals.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
