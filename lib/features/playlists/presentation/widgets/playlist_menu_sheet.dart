import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/cover_sheet.dart';
import '../../domain/entities/playlist.dart';
import '../bloc/playlists_cubit.dart';
import 'playlist_card.dart';

/// 이미지 바꾸기 시트 (카드의 이미지 버튼 · 설정 메뉴에서 공통으로 연다).
Future<void> showPlaylistCoverSheet(BuildContext context, Playlist pl) =>
    showCoverSheet(
      context,
      coverKey: CoverKey.playlist(pl.id),
      title: pl.name,
      tone: playlistToneOf(pl),
    );

/// 재생목록 설정 메뉴: 이미지 바꾸기, (이미지가 없으면) 카드 색 고르기.
Future<void> showPlaylistMenuSheet(BuildContext context, String playlistId) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    // 탭 틀(미니 플레이어 · 탭 바) 위에 뜨도록 최상위 내비게이터에서 연다.
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (_) => _PlaylistMenu(playlistId: playlistId),
  );
}

class _PlaylistMenu extends StatelessWidget {
  const _PlaylistMenu({required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final pl = context.select<PlaylistsCubit, Playlist?>(
      (c) => c.state.where((e) => e.id == playlistId).firstOrNull,
    );
    if (pl == null) return const SizedBox.shrink();
    final hasImage = context.select<CoverCubit, bool>(
      (c) => c.state.containsKey(CoverKey.playlist(playlistId)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                pl.name,
                style: text.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              _MenuRow(
                icon: Icons.image_rounded,
                label: l10n.playlistMenuImage,
                onTap: () {
                  Navigator.of(context).pop();
                  showPlaylistCoverSheet(context, pl);
                },
              ),
              if (!hasImage) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.playlistMenuColor, style: text.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ColorDot(
                      label: l10n.playlistColorAuto,
                      tone: toneFor(pl.id),
                      auto: true,
                      selected: pl.colorIndex == null,
                      onTap: () =>
                          context.read<PlaylistsCubit>().setColor(pl.id, null),
                    ),
                    for (final tone in GlowTone.values)
                      _ColorDot(
                        label: l10n.playlistColorOption(_toneName(l10n, tone)),
                        tone: tone,
                        selected: pl.colorIndex == tone.index,
                        onTap: () => context.read<PlaylistsCubit>().setColor(
                          pl.id,
                          tone.index,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _toneName(AppLocalizations l10n, GlowTone tone) => switch (tone) {
  GlowTone.primary => l10n.playlistColorPrimary,
  GlowTone.secondary => l10n.playlistColorSecondary,
  GlowTone.tertiary => l10n.playlistColorTertiary,
};

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: p.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: p.onSurface),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카드 색 고르기 동그라미. 자동은 새로고침 표시.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
    this.auto = false,
  });

  final String label;
  final GlowTone tone;
  final bool selected;
  final bool auto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final glow = context.tokens.glow(tone);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: glow,
              ),
              border: Border.all(
                color: selected ? p.accent : p.outline,
                width: selected ? 3 : 1,
              ),
            ),
            child: auto
                ? Icon(Icons.autorenew_rounded, size: 20, color: p.onGlow)
                : (selected
                      ? Icon(Icons.check_rounded, size: 20, color: p.onGlow)
                      : null),
          ),
        ),
      ),
    );
  }
}
