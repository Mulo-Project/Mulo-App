import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../icons/app_icons.dart';
import '../tokens/app_dimens.dart';
import 'app_sheet.dart';
import 'buttons.dart';
import 'section_card.dart';

/// 색 고르기 결과: [color]가 null이면 자동 색.
class ColorPick {
  const ColorPick(this.color);

  final Color? color;
}

/// 색 칸: 지금 색을 작은 견본과 값으로 보여 주고, 누르면 [showColorPickerSheet]를 연다.
/// 고르면 [onChanged]로 색, 자동을 고르면 null이 온다. [selected]가 null이면 자동.
class ColorEntry extends StatelessWidget {
  const ColorEntry({
    super.key,
    required this.title,
    required this.selected,
    required this.onChanged,
    required this.autoLabel,
    required this.clearLabel,
    required this.applyLabel,
    this.coverLabel,
    this.cover,
    this.optionLabel,
  });

  final String title;
  final Color? selected;
  final ValueChanged<Color?> onChanged;

  /// 색을 안 정했을 때 칸에 보이는 글 (예: "자동").
  final String autoLabel;

  /// 시트의 "색 지우기" 버튼 글.
  final String clearLabel;
  final String applyLabel;

  /// [cover]에서 뽑은 색 후보 줄의 제목. [cover]가 없으면 후보 줄은 없다.
  final String? coverLabel;

  /// 이 항목의 커버 이미지. 있으면 시트에서 이 이미지의 색을 후보로 보여 준다.
  final ImageProvider? cover;

  /// 견본의 접근성 라벨 (예: "색 3"). 없으면 번호만.
  final String Function(int index)? optionLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected;
    return SettingRow(
      title: title,
      description: color == null ? autoLabel : colorHex(color),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.sm - 4),
              border: Border.all(color: p.outline),
            ),
            child: color == null
                ? Icon(
                    AppIcons.refresh,
                    size: AppSizes.iconSm,
                    color: p.onSurfaceMuted,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(AppIcons.chevronRight, color: p.onSurfaceMuted),
        ],
      ),
      onTap: () async {
        final pick = await showColorPickerSheet(
          context,
          title: title,
          initial: color,
          clearLabel: clearLabel,
          applyLabel: applyLabel,
          coverLabel: coverLabel,
          cover: cover,
          optionLabel: optionLabel,
        );
        if (pick != null) onChanged(pick.color);
      },
    );
  }
}

/// `#RRGGBB` 글.
String colorHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// 색 고르기 바텀 시트: 채도 · 명도 영역 + 색상 막대 + HEX 입력 + 기본 견본.
/// "적용"은 고른 색을, "자동"은 null 색을 돌려준다. 닫으면 null(바꾸지 않음).
Future<ColorPick?> showColorPickerSheet(
  BuildContext context, {
  required String title,
  required Color? initial,
  required String clearLabel,
  required String applyLabel,
  String? coverLabel,
  ImageProvider? cover,
  String Function(int index)? optionLabel,
}) => showAppSheet<ColorPick>(
  context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheet) => _ColorSheet(
    title: title,
    initial: initial,
    clearLabel: clearLabel,
    applyLabel: applyLabel,
    coverLabel: coverLabel,
    cover: cover,
    optionLabel: optionLabel,
  ),
);

/// 기본 견본 (색상 순). 흰 글자가 읽히는 중간 밝기.
const colorPresets = <Color>[
  Color(0xFFE5484D),
  Color(0xFFF76B15),
  Color(0xFFF5A524),
  Color(0xFF3FA34D),
  Color(0xFF12A594),
  Color(0xFF0090C8),
  Color(0xFF3E63DD),
  Color(0xFF7C5CE0),
  Color(0xFFC13DB5),
  Color(0xFFE5467B),
  Color(0xFF8B6B4E),
  Color(0xFF5B6475),
];

class _ColorSheet extends StatefulWidget {
  const _ColorSheet({
    required this.title,
    required this.initial,
    required this.clearLabel,
    required this.applyLabel,
    required this.coverLabel,
    required this.cover,
    required this.optionLabel,
  });

  final String title;
  final Color? initial;
  final String clearLabel;
  final String applyLabel;
  final String? coverLabel;
  final ImageProvider? cover;
  final String Function(int index)? optionLabel;

  @override
  State<_ColorSheet> createState() => _ColorSheetState();
}

class _ColorSheetState extends State<_ColorSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial ?? colorPresets[6]);
  late final _hex = TextEditingController(text: colorHex(_hsv.toColor()));

  Color get _color => _hsv.toColor();

  /// 커버 이미지에서 뽑은 색 후보 (뽑는 중이거나 못 뽑으면 비어 있다).
  List<Color> _fromCover = const [];

  @override
  void initState() {
    super.initState();
    _extractCover();
  }

  /// 분위기 따라가기와 같은 추출기(Material Color Utilities)로 커버의 주색을 뽑는다.
  /// 큰 이미지는 줄여서 읽는다. 못 뽑으면 후보 줄을 보이지 않는다.
  Future<void> _extractCover() async {
    final cover = widget.cover;
    if (cover == null) return;
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: ResizeImage(cover, width: 128),
      );
      final found = <Color>[];
      for (final c in [scheme.primary, scheme.secondary]) {
        if (!found.any((f) => f.toARGB32() == c.toARGB32())) found.add(c);
      }
      if (mounted) setState(() => _fromCover = found);
    } catch (_) {
      // 후보 없이 직접 고를 수 있다.
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor next) {
    setState(() => _hsv = next);
    _hex.text = colorHex(next.toColor());
  }

  void _onHex(String value) {
    final v = value.trim().replaceFirst('#', '');
    if (v.length != 6) return;
    final n = int.tryParse(v, radix: 16);
    if (n == null) return;
    setState(() => _hsv = HSVColor.fromColor(Color(0xFF000000 | n)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final color = _color;
    final hsl = HSLColor.fromColor(color);
    final r = (color.r * 255).round(), g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final k = 1 - [color.r, color.g, color.b].reduce((a, c) => a > c ? a : c);
    String pct(double v) => '${(v * 100).round()}%';
    String cmyk() {
      if (k >= 1) return '0%, 0%, 0%, 100%';
      final c = (1 - color.r - k) / (1 - k);
      final m = (1 - color.g - k) / (1 - k);
      final y = (1 - color.b - k) / (1 - k);
      return '${pct(c)}, ${pct(m)}, ${pct(y)}, ${pct(k)}';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetTitle(widget.title),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 5,
                    child: _SatValField(hsv: _hsv, onChanged: _set),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _HueSlider(hsv: _hsv, onChanged: _set),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, c) in colorPresets.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xs),
                    _Swatch(
                      label: widget.optionLabel?.call(i + 1) ?? '${i + 1}',
                      color: c,
                      selected: c.toARGB32() == color.toARGB32(),
                      onTap: () => _set(HSVColor.fromColor(c)),
                    ),
                  ],
                ],
              ),
            ),
            if (_fromCover.isNotEmpty && widget.coverLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(widget.coverLabel!, style: text.labelMedium),
                  const SizedBox(width: AppSpacing.sm),
                  for (final c in _fromCover) ...[
                    _Swatch(
                      label: widget.coverLabel!,
                      color: c,
                      selected: c.toARGB32() == color.toARGB32(),
                      onTap: () => _set(HSVColor.fromColor(c)),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _ValueBox(
              label: 'HEX',
              child: TextField(
                controller: _hex,
                onChanged: _onHex,
                textAlign: TextAlign.center,
                style: text.bodyLarge,
                cursorColor: p.accent,
                maxLength: 7,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _ValueBox(
                    label: 'RGB',
                    child: _Value('$r, $g, $b'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ValueBox(label: 'CMYK', child: _Value(cmyk())),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _ValueBox(
                    label: 'HSV',
                    child: _Value(
                      '${_hsv.hue.round()}°, ${pct(_hsv.saturation)}, ${pct(_hsv.value)}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ValueBox(
                    label: 'HSL',
                    child: _Value(
                      '${hsl.hue.round()}°, ${pct(hsl.saturation)}, ${pct(hsl.lightness)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    key: const ValueKey('color-auto'),
                    label: widget.clearLabel,
                    icon: AppIcons.close,
                    variant: PillVariant.tonal,
                    // 정해 둔 색이 없으면 지울 것이 없다.
                    onPressed: widget.initial == null
                        ? null
                        : () => Navigator.of(context).pop(const ColorPick(null)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: PillButton(
                    key: const ValueKey('color-apply'),
                    label: widget.applyLabel,
                    icon: AppIcons.check,
                    onPressed: () =>
                        Navigator.of(context).pop(ColorPick(_color)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 라벨이 테두리에 걸린 값 칸 (HEX · RGB 등).
class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: p.outline),
          ),
          child: child,
        ),
        Positioned(
          left: AppSpacing.sm,
          top: -8,
          child: Container(
            color: p.surface,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(label, style: text.labelSmall),
          ),
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: Theme.of(context).textTheme.bodyMedium,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadii.sm - 4),
                border: Border.all(
                  color: selected ? p.accent : p.outline,
                  width: selected ? 2 : 1,
                ),
              ),
              child: selected
                  ? Icon(AppIcons.check, size: AppSizes.iconSm, color: p.onGlow)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// 채도(가로) · 명도(세로) 영역. 끌거나 눌러서 고른다.
class _SatValField extends StatelessWidget {
  const _SatValField({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        void pick(Offset o) => onChanged(
          hsv
              .withSaturation((o.dx / w).clamp(0.0, 1.0))
              .withValue(1 - (o.dy / h).clamp(0.0, 1.0)),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => pick(d.localPosition),
          onPanUpdate: (d) => pick(d.localPosition),
          onTapDown: (d) => pick(d.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFFFFF),
                          HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xFF000000)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: hsv.saturation * w - 11,
                  top: (1 - hsv.value) * h - 11,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.onGlow, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 색상(hue) 막대. 끌거나 눌러서 고른다.
class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  static final _hues = [
    for (var h = 0; h <= 360; h += 30)
      HSVColor.fromAHSV(1, h.toDouble() % 360, 1, 1).toColor(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        void pick(double dx) {
          final h = (dx / w).clamp(0.0, 1.0) * 360;
          onChanged(hsv.withHue(h >= 360 ? 359.9 : h));
        }

        return Semantics(
          slider: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition.dx),
            onHorizontalDragStart: (d) => pick(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
            child: SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(colors: _hues),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (hsv.hue / 360 * w - 12).clamp(-4.0, w - 20),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: p.onGlow, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 고른 색을 화면 뒤 위쪽에 그라데이션으로 깐다 (색이 없으면 아무것도 깔지 않는다).
/// 글자가 읽히도록 너무 밝은 색은 눌러서 쓴다.
class ColorBackdrop extends StatelessWidget {
  const ColorBackdrop({super.key, required this.color, required this.child});

  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = color;
    final hsl = c == null ? null : HSLColor.fromColor(c);
    final base = hsl?.withLightness(hsl.lightness.clamp(.25, .5)).toColor();
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 420,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: AppMotion.medium,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (base ?? const Color(0x00000000)).withValues(
                      alpha: base == null ? 0 : .55,
                    ),
                    (base ?? const Color(0x00000000)).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
