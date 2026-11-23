import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/design/design.dart';
import '../core/l10n/l10n.dart';
import '../features/settings/presentation/screens/settings_screen.dart'
    show presetLabel;
import '../features/theme/domain/entities/theme_settings.dart';
import '../features/theme/presentation/bloc/theme_cubit.dart';

/// 테마 미리보기 중에 탭 틀 아래(탭 바 위)에 뜨는 바.
/// 모드 · 색을 바꿔 가며 실제 화면들을 둘러보고, 적용하거나 취소한다.
class ThemePreviewBar extends StatelessWidget {
  const ThemePreviewBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final ctrl = context.read<ThemeCubit>();
    final preset = context.select((ThemeCubit c) => c.state.preset);
    final mode = context.select((ThemeCubit c) => c.state.mode);
    final brightness = Theme.of(context).brightness;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.settingsThemePreview} · ${l10n.themePreviewHint}',
              style: text.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedPills<AppThemeMode>(
              expand: true,
              values: AppThemeMode.values,
              selected: mode,
              labelOf: (m) => switch (m) {
                AppThemeMode.dark => l10n.appearanceDark,
                AppThemeMode.light => l10n.appearanceLight,
              },
              onChanged: ctrl.previewMode,
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in ThemePreset.values)
                    ThemeSwatch(
                      preview: item.paletteFor(brightness),
                      label: presetLabel(l10n, item),
                      selected: item == preset,
                      size: 40,
                      onTap: () => ctrl.previewPreset(item),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: l10n.actionCancel,
                    compact: true,
                    variant: PillVariant.outline,
                    onPressed: ctrl.cancelPreview,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: PillButton(
                    label: l10n.themePreviewApply,
                    compact: true,
                    onPressed: ctrl.applyPreview,
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
