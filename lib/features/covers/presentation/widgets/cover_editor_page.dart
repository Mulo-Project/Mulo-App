import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/cover_cubit.dart';

/// 커버로 쓸 이미지의 확대 · 위치를 맞추는 화면. 끌어서 옮기고, 두 손가락 · 마우스 휠 ·
/// 막대로 크기를 바꾼다. "적용"을 누르면 맞춘 값을 담은 [art]를 돌려주고, 닫으면 null.
Future<CoverArt?> showCoverEditor(BuildContext context, CoverArt art) =>
    Navigator.of(context, rootNavigator: true).push<CoverArt>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CoverEditorPage(art: art),
      ),
    );

class CoverEditorPage extends StatefulWidget {
  const CoverEditorPage({super.key, required this.art});

  final CoverArt art;

  @override
  State<CoverEditorPage> createState() => _CoverEditorPageState();
}

class _CoverEditorPageState extends State<CoverEditorPage> {
  late final ImageStream _stream = sourceImageOfCoverArt(widget.art)
      .resolve(ImageConfiguration.empty);
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) {
      if (mounted) setState(() => _image = info.image);
    },
    onError: (_, _) {
      if (mounted) setState(() => _failed = true);
    },
  );

  ui.Image? _image;
  bool _failed = false;
  late CoverTransform _t = widget.art.transform;

  // 손가락 · 포인터를 대고 있는 동안의 기준값.
  CoverTransform _startT = CoverTransform.identity;
  Offset _startFocal = Offset.zero;

  double get _aspect => _image == null ? 1 : _image!.width / _image!.height;

  @override
  void initState() {
    super.initState();
    _stream.addListener(_listener);
  }

  @override
  void dispose() {
    _stream.removeListener(_listener);
    super.dispose();
  }

  void _set(CoverTransform t) => setState(() => _t = t.clamped(_aspect));

  void _zoomTo(double scale) =>
      _set(CoverTransform(scale: scale, dx: _t.dx, dy: _t.dy));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final ready = _image != null;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.coverEditTitle,
                leading: CircleIconButton(
                  icon: AppIcons.close,
                  tooltip: l10n.actionBack,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  CircleIconButton(
                    icon: AppIcons.restart,
                    tooltip: l10n.coverEditReset,
                    onPressed: ready
                        ? () => _set(CoverTransform.identity)
                        : null,
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.screen,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final side = math.min(box.maxWidth, box.maxHeight);
                        return SizedBox.square(
                          dimension: side,
                          child: _failed
                              ? Center(
                                  child: Text(
                                    l10n.coverEditLoadFailed,
                                    style: text.bodyMedium?.copyWith(
                                      color: p.onSurfaceMuted,
                                    ),
                                  ),
                                )
                              : !ready
                              ? const Center(child: CircularProgressIndicator())
                              : _Viewport(
                                  image: _image!,
                                  transform: _t,
                                  side: side,
                                  onStart: (focal) {
                                    _startT = _t;
                                    _startFocal = focal;
                                  },
                                  onUpdate: (focal, scale) => _set(
                                    CoverTransform(
                                      scale: _startT.scale * scale,
                                      dx:
                                          _startT.dx +
                                          (focal.dx - _startFocal.dx) / side,
                                      dy:
                                          _startT.dy +
                                          (focal.dy - _startFocal.dy) / side,
                                    ),
                                  ),
                                  onWheel: (dy) =>
                                      _zoomTo(_t.scale * math.exp(-dy / 400)),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: _ZoomBar(
                  value: _t.scale,
                  enabled: ready,
                  label: '${l10n.coverEditZoomOut} / ${l10n.coverEditZoomIn}',
                  onChanged: _zoomTo,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.coverEditHint,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: l10n.coverEditApply,
                    icon: AppIcons.check,
                    onPressed: ready
                        ? () =>
                              Navigator.of(context)
                                  .pop(widget.art.withTransform(_t))
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 정사각형 미리보기. 실제 커버와 같은 계산([CoverTransform.visibleRect])으로 그린다.
class _Viewport extends StatelessWidget {
  const _Viewport({
    required this.image,
    required this.transform,
    required this.side,
    required this.onStart,
    required this.onUpdate,
    required this.onWheel,
  });

  final ui.Image image;
  final CoverTransform transform;
  final double side;
  final ValueChanged<Offset> onStart;
  final void Function(Offset focal, double scale) onUpdate;
  final ValueChanged<double> onWheel;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) onWheel(e.scrollDelta.dy);
      },
      child: GestureDetector(
        onScaleStart: (d) => onStart(d.focalPoint),
        onScaleUpdate: (d) => onUpdate(d.focalPoint, d.scale),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: CustomPaint(
            size: Size.square(side),
            painter: _CropPainter(image, transform),
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.transform);

  final ui.Image image;
  final CoverTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    final r = transform.visibleRect(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(r.left, r.top, r.side, r.side),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.transform != transform;
}

/// 확대 막대: 왼쪽 끝 = 원래 크기, 오른쪽 끝 = 최대. 끌거나 눌러서 바꾼다.
class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.value,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final double value;
  final bool enabled;
  final String label;
  final ValueChanged<double> onChanged;

  static const _span = CoverTransform.maxScale - CoverTransform.minScale;
  static const _thumb = 20.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fraction = ((value - CoverTransform.minScale) / _span).clamp(
      0.0,
      1.0,
    );
    return Semantics(
      slider: true,
      label: label,
      value: '${value.toStringAsFixed(1)}x',
      child: LayoutBuilder(
        builder: (context, box) {
          void update(double x) => onChanged(
            CoverTransform.minScale +
                ((x - _thumb / 2) / (box.maxWidth - _thumb)).clamp(0.0, 1.0) *
                    _span,
          );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (d) => update(d.localPosition.dx) : null,
            onHorizontalDragUpdate: enabled
                ? (d) => update(d.localPosition.dx)
                : null,
            child: SizedBox(
              height: 32,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: ShapeDecoration(
                      color: p.surfaceHigh,
                      shape: const StadiumBorder(),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: _thumb / 2 + (box.maxWidth - _thumb) * fraction,
                    decoration: ShapeDecoration(
                      color: p.accent,
                      shape: const StadiumBorder(),
                    ),
                  ),
                  Positioned(
                    left: (box.maxWidth - _thumb) * fraction,
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
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
