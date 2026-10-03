import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/library_cubit.dart';
import '../widgets/play_shuffle_row.dart';
import '../widgets/track_list_tile.dart';

/// 장르 화면: 장르에 속한 곡 목록과 재생 · 셔플.
/// [genre]는 곡에 저장된 장르 그대로이고, 빈 문자열이면 "알 수 없는 장르"이다.
class GenreScreen extends StatelessWidget {
  const GenreScreen({super.key, required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final all = context.select((LibraryCubit c) => c.state).tracks;
    // 보관함 목록은 추가일 최신순이라서 장르 안에서는 제목 순으로 보여 준다.
    final tracks = [
      for (final t in all)
        if (t.genre.trim() == genre) t,
    ]..sort((a, b) => a.title.compareTo(b.title));
    final name = genreOf(l10n, genre);

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
          ),
          if (tracks.isEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.genreNotFound,
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
                    tone: toneFor(genre),
                    icon: Icons.category_rounded,
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
            for (final (i, t) in tracks.indexed)
              TrackListTile(track: t, queue: tracks, index: i),
          ],
        ],
      ),
    );
  }
}
