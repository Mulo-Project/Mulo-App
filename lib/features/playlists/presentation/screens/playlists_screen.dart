import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/playlist.dart';
import '../bloc/playlists_cubit.dart';
import '../widgets/new_playlist_sheet.dart';
import '../widgets/playlist_card.dart';

/// 재생목록 (상세 기능: 재생목록 관리 #20, 유튜브 재생목록 가져오기 #22).
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lists = context.watch<PlaylistsCubit>().state;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            large: true,
            title: l10n.navPlaylists,
            subtitle: l10n.playlistsSubtitle,
            actions: [
              CircleIconButton(
                icon: Icons.add_rounded,
                tooltip: l10n.playlistsNew,
                emphasized: true,
                onPressed: () => showNewPlaylistSheet(context),
              ),
            ],
          ),
          Padding(
            padding: AppSpacing.screen,
            child: PillButton(
              label: l10n.playlistsImport,
              icon: Icons.link_rounded,
              variant: PillVariant.tonal,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (lists.isEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.playlistsEmpty,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.palette.onSurfaceMuted),
              ),
            )
          else
            Padding(
              padding: AppSpacing.screen,
              child: _PlaylistGrid(lists: lists),
            ),
        ],
      ),
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  const _PlaylistGrid({required this.lists});

  final List<Playlist> lists;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final pl in lists)
              SizedBox(
                width: w,
                child: AspectRatio(
                  aspectRatio: PlaylistCard.aspectRatio,
                  child: PlaylistCard(playlist: pl),
                ),
              ),
          ],
        );
      },
    );
  }
}
