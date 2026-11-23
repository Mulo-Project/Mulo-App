import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../lyrics/presentation/widgets/lyrics_theme_sheet.dart';
import '../bloc/player_style_cubit.dart';

/// 재생 화면의 더 보기 메뉴에서 여는 "플레이어 테마" 시트. "플레이어" · "가사" 탭으로 가사 테마도 여기서 고른다.
/// 고르면 바로 적용되고, 시트 뒤의 재생 화면이 그대로 미리 보기가 된다.
///
/// 시트가 떠 있는 동안 높이를 [playerStyleSheetHeight]에 알려, 재생 화면이 그만큼
/// 줄어들어 시트 위에 화면 전체가 보이게 한다.
Future<void> showPlayerStyleSheet(BuildContext context) => showAppSheet<void>(
  context,
  showDragHandle: false,
  barrierColor: Colors.transparent,
  builder: (_) => const _PlayerStyleSheet(),
).whenComplete(() => playerStyleSheetHeight.value = 0);

/// 플레이어 테마 시트가 가리는 아래쪽 높이 (시트가 없으면 0).
final playerStyleSheetHeight = ValueNotifier<double>(0);

/// 재생 화면이 커버 대신 가사를 보여 주고 있는가. 테마 시트의 "가사" 탭이 켜면 화면도 가사로 바뀐다.
final playerShowLyrics = ValueNotifier<bool>(false);

class _PlayerStyleSheet extends StatefulWidget {
  const _PlayerStyleSheet();

  @override
  State<_PlayerStyleSheet> createState() => _PlayerStyleSheetState();
}

class _PlayerStyleSheetState extends State<_PlayerStyleSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = context.watch<PlayerStyleCubit>().state;
    final lyricsTab = playerShowLyrics.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject();
      if (mounted && box is RenderBox && box.hasSize) {
        playerStyleSheetHeight.value = box.size.height;
      }
    });
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(l10n.playerStyleTitle),
            const SizedBox(height: AppSpacing.sm),
            SegmentedPills<bool>(
              values: const [false, true],
              selected: lyricsTab,
              expand: true,
              labelOf: (lyrics) =>
                  lyrics ? l10n.themeTabLyrics : l10n.themeTabPlayer,
              onChanged: (lyrics) =>
                  setState(() => playerShowLyrics.value = lyrics),
            ),
            const SizedBox(height: AppSpacing.md),
            if (lyricsTab)
              const LyricsThemeOptions()
            else
              Row(
                children: [
                  for (final style in PlayerStyle.values)
                    Expanded(
                      child: _StyleOption(
                        style: style,
                        selected: style == current,
                        onTap: () =>
                            context.read<PlayerStyleCubit>().select(style),
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

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final PlayerStyle style;
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
                _icon,
                size: 26,
                color: selected ? p.onAccent : p.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              playerStyleName(context.l10n, style),
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

  IconData get _icon => switch (style) {
    PlayerStyle.square => AppIcons.square,
    PlayerStyle.fullBleed => AppIcons.fullscreen,
    PlayerStyle.arc => AppIcons.usage,
  };
}

String playerStyleName(AppLocalizations l10n, PlayerStyle style) =>
    switch (style) {
      PlayerStyle.square => l10n.playerStyleSquare,
      PlayerStyle.fullBleed => l10n.playerStyleFullBleed,
      PlayerStyle.arc => l10n.playerStyleArc,
    };
