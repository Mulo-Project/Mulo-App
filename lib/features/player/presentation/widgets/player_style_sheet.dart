import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/player_style_cubit.dart';

/// 재생 화면의 더 보기 메뉴에서 여는 "플레이어 테마" 시트.
/// 고르면 바로 적용되고, 시트 뒤의 재생 화면이 그대로 미리 보기가 된다.
Future<void> showPlayerStyleSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      barrierColor: Colors.transparent,
      showDragHandle: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.md)),
      ),
      builder: (_) => const _PlayerStyleSheet(),
    );

class _PlayerStyleSheet extends StatelessWidget {
  const _PlayerStyleSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final current = context.watch<PlayerStyleCubit>().state;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.playerStyleTitle, style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
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
    PlayerStyle.vinyl => Icons.album_rounded,
    PlayerStyle.square => Icons.crop_square_rounded,
    PlayerStyle.fullBleed => Icons.fullscreen_rounded,
    PlayerStyle.arc => Icons.data_usage_rounded,
  };
}

String playerStyleName(AppLocalizations l10n, PlayerStyle style) =>
    switch (style) {
      PlayerStyle.vinyl => l10n.playerStyleVinyl,
      PlayerStyle.square => l10n.playerStyleSquare,
      PlayerStyle.fullBleed => l10n.playerStyleFullBleed,
      PlayerStyle.arc => l10n.playerStyleArc,
    };
