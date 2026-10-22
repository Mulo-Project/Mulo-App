import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/lyrics_settings_cubit.dart';

/// 테마 시트의 "가사" 탭: 모양(목록 · 가운데 한 줄)은 하나만, 커버 배경은 모양과 따로 켜고 끈다.
/// 고르면 바로 적용되고, 시트 뒤의 재생 화면이 그대로 미리 보기가 된다.
class LyricsThemeOptions extends StatelessWidget {
  const LyricsThemeOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LyricsSettingsCubit>();
    final settings = context.watch<LyricsSettingsCubit>().state;
    return Row(
      children: [
        Expanded(
          child: _Option(
            icon: AppIcons.lineSpacing,
            label: l10n.lyricsThemeList,
            selected: settings.theme == LyricsTheme.list,
            onTap: () => cubit.setTheme(LyricsTheme.list),
          ),
        ),
        Expanded(
          child: _Option(
            icon: AppIcons.lyrics,
            label: l10n.lyricsThemeCentered,
            selected: settings.theme == LyricsTheme.centered,
            onTap: () => cubit.setTheme(LyricsTheme.centered),
          ),
        ),
        Expanded(
          child: _Option(
            icon: AppIcons.photoLibrary,
            label: l10n.lyricsThemeCover,
            selected: settings.coverBackground,
            onTap: () => cubit.setCoverBackground(!settings.coverBackground),
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? p.accent : p.onSurface.withValues(alpha: .08),
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected ? p.onAccent : p.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: text.labelMedium?.copyWith(
                color: selected ? p.onSurface : p.onSurfaceMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
