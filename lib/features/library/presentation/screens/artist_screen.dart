import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/decorate_sheet.dart';
import '../bloc/library_cubit.dart';
import '../widgets/play_shuffle_row.dart';
import '../widgets/lazy_track_list.dart';
import '../widgets/track_list_tile.dart';

/// 아티스트 화면: 아티스트의 곡 목록과 전체 재생.
/// [artist]는 곡에 저장된 아티스트 이름 그대로이고, 빈 문자열이면 "알 수 없는 아티스트"이다.
class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key, required this.artist});

  final String artist;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final all = context.select((LibraryCubit c) => c.state).tracks;
    // 보관함 목록은 추가일 최신순이라서 아티스트 안에서는 제목 순으로 보여 준다.
    final tracks = [
      for (final t in all)
        if (t.artist == artist) t,
    ]..sort((a, b) => a.title.compareTo(b.title));
    final name = artist.isEmpty ? l10n.unknownArtist : artist;
    final key = CoverKey.artist(artist);

    return SafeArea(
      bottom: false,
      child: LazyTrackList(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        header: [
          AppTopBar(
            title: name,
            leading: const AppBackButton(),
            actions: [
              // 이 묶음의 곡을 모두 재생목록에 담는다 (곡 메뉴의 "재생목록에 추가"와 같은 화면).
              CircleIconButton(
                icon: AppIcons.playlistAdd,
                tooltip: l10n.trackMenuAddToPlaylist,
                onPressed: tracks.isEmpty
                    ? null
                    : () => context.push(
                        Routes.playlistPick,
                        extra: [for (final t in tracks) t.id],
                      ),
              ),
              CircleIconButton(
                icon: AppIcons.sparkle,
                tooltip: l10n.decorateArtistTooltip,
                onPressed: () => showDecorateSheet(
                  context,
                  coverKey: key,
                  title: name,
                  tone: toneFor(name),
                  icon: AppIcons.person,
                ),
              ),
            ],
          ),
          if (tracks.isEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.artistNotFound,
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
                    radius: 48,
                    image: coverImageOf(context, key),
                    tone: toneFor(name),
                    color: coverColorOf(context, key),
                    icon: AppIcons.person,
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
                          l10n.songCount(tracks.length),
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
            PlayShuffleRow(tracks: tracks),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        trackCount: tracks.length,
        trackBuilder: (context, i) =>
            TrackListTile(track: tracks[i], queue: tracks, index: i),
      ),
    );
  }
}
