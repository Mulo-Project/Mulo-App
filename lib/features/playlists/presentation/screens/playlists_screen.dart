import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../app/router.dart';
import '../bloc/playlists_cubit.dart';
import '../widgets/new_playlist_sheet.dart';
import '../widgets/playlist_grid.dart';

/// 재생목록 (상세 기능: 재생목록 관리 #20, 유튜브 재생목록 가져오기 #22).
/// 좋아요 목록이 맨 앞에 항상 있다. 카드를 누르면 재생목록 상세로 간다.
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
              // 직접 만든 재생목록이 둘 이상일 때만 순서를 바꿀 수 있다.
              if (lists.where((p) => !p.isFavorites).length > 1)
                CircleIconButton(
                  icon: AppIcons.sort,
                  tooltip: l10n.playlistReorder,
                  onPressed: () => context.push(Routes.playlistReorder),
                ),
              CircleIconButton(
                icon: AppIcons.add,
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
              icon: AppIcons.link,
              variant: PillVariant.tonal,
              onPressed: () => context.push(Routes.playlistImport),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (lists.isNotEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: PlaylistGrid(lists: lists),
            ),
          // 좋아요 목록 말고 직접 만든 재생목록이 없을 때의 안내.
          if (lists.every((p) => p.isFavorites))
            EmptyState(title: l10n.playlistsEmpty),
        ],
      ),
    );
  }
}
