import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_item_widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/playlists_cubit.dart';
import 'playlist_menu.dart';

/// 화면에 보여 줄 이름. 좋아요 목록은 저장된 이름이 없어서 번역된 이름으로 바꾼다.
String playlistNameOf(AppLocalizations l10n, Playlist pl) =>
    pl.isFavorites ? l10n.playlistFavorites : pl.name;

/// 색을 안 골랐을 때 카드의 자동 톤: 좋아요는 보조 색, 나머지는 재생목록마다 다르게.
GlowTone playlistToneOf(Playlist pl) =>
    pl.isFavorites ? GlowTone.secondary : toneFor(pl.id);

/// 재생목록 카드: 얇은 테두리 안에 커버(이미지나 색) · 이름 · 곡 수. 대표곡은 카드가 아니라 재생목록 상세 안에서 보여 준다.
/// 이 재생목록에 담을 곡을 받는 중이면 아래에 진행 줄이 붙는다.
///
/// 기본(둘러보기)에서는 누르면 재생목록 상세로 가고, ⋮ · 길게 누르기 · 오른쪽 클릭은 팝업 메뉴를 연다.
/// [selected]를 주면 담기 선택 모드: 메뉴 대신 체크 표시가 붙고 [onTap]으로 고른다.
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    this.selected,
    this.already = false,
    this.onTap,
  });

  final Playlist playlist;

  /// null이면 둘러보기, 아니면 담기 선택 모드에서 고른 상태.
  final bool? selected;

  /// 선택 모드에서 이미 곡이 담겨 있는 재생목록.
  final bool already;

  /// 기본은 상세로 이동.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final l10n = context.l10n;
    final image = coverImageOf(context, CoverKey.playlist(playlist.id));
    final color = coverColorOf(context, CoverKey.playlist(playlist.id));
    final browsing = selected == null;

    return _PointerMenu(
      enabled: browsing,
      onMenu: (pos) => showPlaylistMenu(context, playlist, globalPosition: pos),
      child: Material(
        color: p.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(
            color: selected == true ? p.accent : p.outline,
            width: selected == true ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap:
              onTap ?? () => context.push(Routes.playlistDetail(playlist.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 윗면: 재생목록 커버 (이미지나 색). 좋아요는 하트, 선택 모드는 체크.
              AspectRatio(
                aspectRatio: 1.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverCard(
                      radius: 0,
                      image: image,
                      tone: playlistToneOf(playlist),
                      color: color,
                      child: playlist.isFavorites && image == null
                          ? Center(
                              child: Icon(
                                AppIcons.favorite,
                                size: 40,
                                color: p.onGlow.withValues(alpha: .9),
                              ),
                            )
                          : null,
                    ),
                    if (!browsing)
                      Positioned(
                        top: AppSpacing.xxs,
                        right: AppSpacing.xxs,
                        child: _SelectMark(selected: selected!),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.xxs,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        playlistNameOf(l10n, playlist),
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (browsing)
                      Builder(
                        builder: (btn) => SizedBox.square(
                          dimension: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            tooltip: l10n.playlistMenuTooltip,
                            onPressed: () => showPlaylistMenu(btn, playlist),
                            icon: Icon(AppIcons.more, color: p.onSurfaceMuted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  already
                      ? l10n.playlistPickAlready
                      : l10n.songCount(playlist.trackCount),
                  style: text.bodySmall,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _DownloadingStrip(playlist: playlist),
            ],
          ),
        ),
      ),
    );
  }
}

/// 길게 누르기 · 오른쪽 클릭의 화면 좌표를 메뉴에 넘긴다.
class _PointerMenu extends StatefulWidget {
  const _PointerMenu({
    required this.enabled,
    required this.onMenu,
    required this.child,
  });

  final bool enabled;
  final ValueChanged<Offset> onMenu;
  final Widget child;

  @override
  State<_PointerMenu> createState() => _PointerMenuState();
}

class _PointerMenuState extends State<_PointerMenu> {
  Offset _last = Offset.zero;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (e) => _last = e.position,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => widget.onMenu(_last),
        onSecondaryTap: () => widget.onMenu(_last),
        child: widget.child,
      ),
    );
  }
}

class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Icon(
        selected ? AppIcons.checkCircle : AppIcons.radioOff,
        size: 26,
        color: selected ? p.accent : p.onGlow,
      ),
    );
  }
}

/// 이 재생목록에 담을 곡을 받는 중이면 카드 아래에 그 곡과 진행 막대를 보인다 (아니면 아무것도 없다).
class _DownloadingStrip extends StatelessWidget {
  const _DownloadingStrip({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final dl = context.select<DownloadQueueCubit, DownloadItem?>(
      (c) => c.state.activeFor(playlist.id),
    );
    if (dl == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppDivider(),
        _DownloadingRow(item: dl, minHeight: 30),
      ],
    );
  }
}

/// 받기 줄: 받는 곡 제목 · 진행 막대 · 상태(%).
class _DownloadingRow extends StatelessWidget {
  const _DownloadingRow({required this.item, required this.minHeight});

  final DownloadItem item;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: text.labelSmall?.copyWith(color: p.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            ProgressLine(value: item.progress, height: 4),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              downloadStatusText(context.l10n, item),
              style: text.labelSmall?.copyWith(color: p.accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
