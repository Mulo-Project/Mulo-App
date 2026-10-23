import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/cover/cover_paint.dart';
import '../bloc/cover_cubit.dart';
import 'cover_picker.dart';

/// 이미지 페이지가 닫히며 돌려주는 결과: 맞춘 이미지([applied]) · 기본 이미지로 되돌리기([reverted]) · 이미지 지우기([removed]).
class CoverEditResult {
  const CoverEditResult.applied(CoverArt this.art)
    : reverted = false,
      removed = false;
  const CoverEditResult.reverted()
    : art = null,
      reverted = true,
      removed = false;
  const CoverEditResult.removed()
    : art = null,
      reverted = false,
      removed = true;

  final CoverArt? art;

  /// 기본 이미지로 되돌렸다 (받기는 유튜브 썸네일).
  final bool reverted;

  /// 이미지를 지워 이미지 없이 둔다.
  final bool removed;
}

/// 커버로 쓸 이미지를 고르고 확대 · 위치를 맞추는 화면 (곡 · 앨범 · 재생목록 · 받기가 모두 이 페이지 하나를 쓴다). 끌어서 옮기고, 두 손가락 · 마우스 휠 ·
/// 막대로 크기를 바꾼다. [art]가 null이면 빈 화면에서 시작해 안의 "이미지 불러오기"로 기기 사진이나
/// 웹 이미지를 고른다. "적용"을 누르면 맞춘 값을 담은 커버를 돌려주고, 닫으면 null.
///
/// [initialQuery]는 웹 이미지 고르기에서 처음부터 검색해 둘 말. [canRevert]면 "기본 이미지로" 버튼이,
/// [canRemove]면 "이미지 지우기" 버튼이 보인다 (눌러 확인하면 [CoverEditResult.reverted] · [CoverEditResult.removed]로 닫힌다). 이미지가 없으면 불러오기 버튼과 안내만 보이고
/// 확대 · 회전 · 적용은 숨는다.
Future<CoverEditResult?> showCoverEditor(
  BuildContext context,
  CoverArt? art, {
  String initialQuery = '',
  bool canRevert = false,
  bool canRemove = false,
}) => Navigator.of(context, rootNavigator: true).push<CoverEditResult>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => CoverEditorPage(
      art: art,
      initialQuery: initialQuery,
      canRevert: canRevert,
      canRemove: canRemove,
    ),
  ),
);

class CoverEditorPage extends StatefulWidget {
  const CoverEditorPage({
    super.key,
    this.art,
    this.initialQuery = '',
    this.canRevert = false,
    this.canRemove = false,
  });

  final CoverArt? art;
  final String initialQuery;
  final bool canRevert;
  final bool canRemove;

  @override
  State<CoverEditorPage> createState() => _CoverEditorPageState();
}

class _CoverEditorPageState extends State<CoverEditorPage> {
  CoverArt? _art;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  ui.Image? _image;
  bool _failed = false;
  CoverTransform _t = CoverTransform.identity;

  // 손가락 · 포인터를 대고 있는 동안의 기준값.
  CoverTransform _startT = CoverTransform.identity;
  Offset _startFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    final art = widget.art;
    if (art != null) _load(art);
  }

  /// [art]의 이미지를 새로 불러온다 (먼저 보던 이미지는 놓는다).
  void _load(CoverArt art) {
    _release();
    _art = art;
    _image = null;
    _failed = false;
    _t = art.transform;
    final listener = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _image = info.image);
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    final stream = sourceImageOfCoverArt(art).resolve(ImageConfiguration.empty);
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _release() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  Future<void> _choose(CoverPickSource source) async {
    final picked = await chooseCoverImage(
      context,
      source,
      initialQuery: widget.initialQuery,
    );
    if (picked != null && mounted) setState(() => _load(picked));
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  /// 확대 · 위치 · 회전을 처음 상태로 (확인 후).
  Future<void> _resetTransform() async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.coverEditResetTitle,
      body: l10n.coverEditResetBody,
      confirmLabel: l10n.coverEditResetConfirm,
      cancelLabel: l10n.actionCancel,
    );
    if (ok && mounted) _set(CoverTransform.identity);
  }

  /// 고른 이미지를 지우고 기본 이미지로 (확인 후 닫는다).
  Future<void> _revert() async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.coverRevertTitle,
      body: l10n.coverRevertBody,
      confirmLabel: l10n.coverReset,
      cancelLabel: l10n.actionCancel,
    );
    if (ok && mounted) {
      Navigator.of(context).pop(const CoverEditResult.reverted());
    }
  }

  /// 이미지를 지운다 (확인 후 닫는다). 이미지 없이 둔다.
  Future<void> _remove() async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.coverRemoveTitle,
      body: l10n.coverRemoveBody,
      confirmLabel: l10n.coverRemove,
      cancelLabel: l10n.actionCancel,
    );
    if (ok && mounted) {
      Navigator.of(context).pop(const CoverEditResult.removed());
    }
  }

  void _set(CoverTransform t) => setState(() => _t = t.clamped());

  void _zoomTo(double scale) => _set(
    CoverTransform(scale: scale, dx: _t.dx, dy: _t.dy, rotation: _t.rotation),
  );

  void _rotateTo(double degrees) => _set(
    CoverTransform(scale: _t.scale, dx: _t.dx, dy: _t.dy, rotation: degrees),
  );

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
              ),
              // 이미지 불러오기는 위쪽에 둔다 (기기 사진 | 웹 이미지).
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        key: const ValueKey('cover-edit-device'),
                        label: l10n.coverSourceDevice,
                        icon: AppIcons.photoLibrary,
                        variant: PillVariant.tonal,
                        onPressed: () => _choose(CoverPickSource.device),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: PillButton(
                        key: const ValueKey('cover-edit-web'),
                        label: l10n.coverSourceWeb,
                        icon: AppIcons.globe,
                        variant: PillVariant.tonal,
                        onPressed: () => _choose(CoverPickSource.web),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: AppSpacing.screen,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final side = math.min(box.maxWidth, box.maxHeight);
                        final frameSide = side * _Viewport.cropFraction;
                        return SizedBox.square(
                          dimension: side,
                          child: _art == null
                              // 이미지가 없음을 아이콘 + 문구로 가운데에 보여 준다 (공용 안내).
                              ? EmptyState(
                                  key: const ValueKey('cover-edit-empty'),
                                  icon: AppIcons.imageBroken,
                                  iconSize: 72,
                                  title: l10n.coverEditEmpty,
                                )
                              : _failed
                              ? EmptyState(
                                  icon: AppIcons.imageBroken,
                                  title: l10n.coverEditLoadFailed,
                                )
                              : !ready
                              ? const LoadingState()
                              : _Viewport(
                                  image: _image!,
                                  transform: _t,
                                  side: side,
                                  onStart: (focal) {
                                    _startT = _t;
                                    _startFocal = focal;
                                  },
                                  onUpdate: (focal, scale, rotation) => _set(
                                    CoverTransform(
                                      scale: _startT.scale * scale,
                                      rotation: _startT.rotation + rotation,
                                      dx:
                                          _startT.dx +
                                          (focal.dx - _startFocal.dx) /
                                              frameSide,
                                      dy:
                                          _startT.dy +
                                          (focal.dy - _startFocal.dy) /
                                              frameSide,
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
              // 이미지가 있을 때만 확대 · 회전 · 적용을 보인다.
              if (_art != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _RangeBar(
                    value: _t.scale,
                    min: CoverTransform.minScale,
                    max: CoverTransform.maxScale,
                    valueText: '${_t.scale.toStringAsFixed(1)}x',
                    enabled: ready,
                    label: '${l10n.coverEditZoomOut} / ${l10n.coverEditZoomIn}',
                    onChanged: _zoomTo,
                  ),
                ),
                // 회전: 90° 단위 버튼 둘과 미세 각도 막대.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 막대 가운데 위에 지금 각도를 돌아간 아이콘과 숫자로 보여 준다.
                      Row(
                        key: const ValueKey('cover-edit-angle'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: _t.rotation * math.pi / 180,
                            child: Icon(
                              AppIcons.arrowUp,
                              size: 18,
                              color: ready ? p.accent : p.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${_t.rotation.round()}°',
                            style: text.labelLarge?.copyWith(
                              color: ready ? p.accent : p.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                      _RangeBar(
                        value: _t.rotation,
                        min: -180,
                        max: 180,
                        centerMark: true,
                        valueText: '${_t.rotation.round()}°',
                        enabled: ready,
                        label: l10n.coverEditRotation,
                        // 0° 가까이에서는 0°에 붙는다.
                        onChanged: (v) =>
                            _rotateTo(v.abs() < 4 ? 0 : v.roundToDouble()),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          key: const ValueKey('cover-edit-rotate-left'),
                          label: l10n.coverEditRotateLeft,
                          icon: AppIcons.restart,
                          variant: PillVariant.tonal,
                          onPressed: ready
                              ? () => _rotateTo(_t.rotation - 90)
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: PillButton(
                          key: const ValueKey('cover-edit-rotate-right'),
                          label: l10n.coverEditRotateRight,
                          icon: AppIcons.restart,
                          variant: PillVariant.tonal,
                          onPressed: ready
                              ? () => _rotateTo(_t.rotation + 90)
                              : null,
                        ),
                      ),
                    ],
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
                // 되돌리기 둘(위치 · 기본 이미지)은 한 줄에 같은 모양 버튼으로 둔다 (둘 다 확인을 묻는다).
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    0,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      PillButton(
                        key: const ValueKey('cover-edit-reset-position'),
                        label: l10n.coverEditResetPosition,
                        icon: AppIcons.restart,
                        variant: PillVariant.tonal,
                        compact: true,
                        onPressed: ready ? _resetTransform : null,
                      ),
                      if (widget.canRevert)
                        PillButton(
                          key: const ValueKey('cover-edit-revert'),
                          label: l10n.coverReset,
                          icon: AppIcons.restart,
                          variant: PillVariant.tonal,
                          compact: true,
                          onPressed: _revert,
                        ),
                      if (widget.canRemove)
                        PillButton(
                          key: const ValueKey('cover-edit-remove'),
                          label: l10n.coverRemove,
                          icon: AppIcons.delete,
                          variant: PillVariant.tonal,
                          compact: true,
                          onPressed: _remove,
                        ),
                    ],
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
                          ? () => Navigator.of(context).pop(
                              CoverEditResult.applied(_art!.withTransform(_t)),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 편집 미리보기: 가운데 정사각형 **자르기 칸**([cropFraction])이 실제 커버이고, 칸 밖으로 나간 그림은
/// 어둡게 보여 어디가 잘리는지 알 수 있다. 실제 커버와 같은 계산([paintCover])으로 칸 안을 그린다.
class _Viewport extends StatelessWidget {
  const _Viewport({
    required this.image,
    required this.transform,
    required this.side,
    required this.onStart,
    required this.onUpdate,
    required this.onWheel,
  });

  /// 미리보기 한 변 가운데 자르기 칸이 차지하는 비율.
  static const cropFraction = 0.72;

  final ui.Image image;
  final CoverTransform transform;
  final double side;
  final ValueChanged<Offset> onStart;
  final void Function(Offset focal, double scale, double rotationDeg) onUpdate;
  final ValueChanged<double> onWheel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) onWheel(e.scrollDelta.dy);
      },
      child: GestureDetector(
        onScaleStart: (d) => onStart(d.focalPoint),
        onScaleUpdate: (d) =>
            onUpdate(d.focalPoint, d.scale, d.rotation * 180 / math.pi),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: CustomPaint(
            size: Size.square(side),
            painter: _CropPainter(
              image,
              transform,
              background: p.surfaceHigh,
              dim: p.background.withValues(alpha: .65),
              border: p.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(
    this.image,
    this.transform, {
    required this.background,
    required this.dim,
    required this.border,
  });

  final ui.Image image;
  final CoverTransform transform;
  final Color background;
  final Color dim;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    final side = size.width * _Viewport.cropFraction;
    final frame = Rect.fromLTWH(
      (size.width - side) / 2,
      (size.height - side) / 2,
      side,
      side,
    );
    canvas
      ..clipRect(all)
      ..drawRect(all, Paint()..color = background)
      // 칸 안 바탕은 실제 커버처럼 검정이다 (그림이 덮지 못한 곳).
      ..drawRect(frame, Paint()..color = coverEmptyColor)
      ..save()
      ..translate(frame.left, frame.top);
    paintCoverImage(canvas, side, image, transform);
    canvas
      ..restore()
      // 칸 밖은 어둡게: 여기 보이는 그림은 잘려 나간다.
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(all)
          ..addRect(frame),
        Paint()..color = dim,
      )
      ..drawRect(
        frame,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image ||
      old.transform != transform ||
      old.background != background ||
      old.dim != dim ||
      old.border != border;
}

/// 값 막대: 왼쪽 끝 = [min], 오른쪽 끝 = [max]. 끌거나 눌러서 바꾼다 (확대 · 회전에 쓴다).
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    this.centerMark = false,
    required this.value,
    required this.min,
    required this.max,
    required this.valueText,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final String valueText;
  final bool enabled;
  final String label;
  final ValueChanged<double> onChanged;

  /// 가운데(기준값)에 눈금을 그린다 (회전 0°).
  final bool centerMark;

  static const _thumb = 20.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final span = max - min;
    final fraction = ((value - min) / span).clamp(0.0, 1.0);
    return Semantics(
      slider: true,
      label: label,
      value: valueText,
      child: LayoutBuilder(
        builder: (context, box) {
          void update(double x) => onChanged(
            min +
                ((x - _thumb / 2) / (box.maxWidth - _thumb)).clamp(0.0, 1.0) *
                    span,
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
                  if (centerMark)
                    Positioned(
                      left: box.maxWidth / 2 - 1,
                      child: Container(
                        width: 2,
                        height: 14,
                        color: p.onSurfaceMuted,
                      ),
                    ),
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
