import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/cover_color_sheet.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/library_cubit.dart';
import '../widgets/track_list_tile.dart';

/// 앨범 화면: 앨범에 속한 곡 목록과 전체 재생.
/// [album]은 곡에 저장된 앨범 이름 그대로이고, 빈 문자열이면 "알 수 없는 앨범"이다.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.album});

  final String album;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final all = context.select((LibraryCubit c) => c.state).tracks;
    // 보관함 목록은 추가일 최신순이라서 앨범 안에서는 제목 순으로 보여 준다.
    final tracks = [
      for (final t in all)
        if (t.album == album) t,
    ]..sort((a, b) => a.title.compareTo(b.title));
    final name = album.isEmpty ? l10n.unknownAlbum : album;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            title: name,
            leading: CircleIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: l10n.actionBack,
              onPressed: () => context.pop(),
            ),
            actions: [
              CircleIconButton(
                icon: Icons.palette_rounded,
                tooltip: l10n.albumColorTooltip,
                onPressed: () => showCoverColorSheet(
                  context,
                  colorKey: CoverKey.album(album),
                  title: name,
                  tone: toneFor(name),
                ),
              ),
            ],
          ),
          if (tracks.isEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.albumNotFound,
                style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              ),
            )
          else ...[
            Padding(
              padding: AppSpacing.screen,
              child: Row(
                children: [
                  ArtworkBox(
                    size: 96,
                    radius: AppRadii.md,
                    tone: toneFor(name),
                    color: coverColorOf(context, CoverKey.album(album)),
                    icon: Icons.album_rounded,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: text.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${artistOf(l10n, tracks.first)} · ${l10n.songCount(tracks.length)}',
                          style: text.bodyMedium?.copyWith(
                            color: p.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.screen,
              child: PillButton(
                label: l10n.actionPlay,
                icon: Icons.play_arrow_rounded,
                onPressed: () =>
                    context.read<NowPlayingCubit>().playQueue(tracks),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final (i, t) in tracks.indexed)
              TrackListTile(
                track: t,
                queue: tracks,
                index: i,
                showAlbum: false,
              ),
          ],
        ],
      ),
    );
  }
}
