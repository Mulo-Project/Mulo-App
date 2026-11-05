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
/// 좋아요 목록이 맨 앞에 항상 있다. 카드를 누르면 재생목록 상세로 가고, 길게 눌러 끌면 순서가 바뀐다.
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
                icon: AppIcons.add,
                tooltip: l10n.playlistsNew,
                emphasized: true,
                onPressed: () => showNewPlaylistSheet(context),
              ),
            ],
          ),
          Padding(
            padding: AppSpacing.screen,
            // 가져오기는 보조 동작이라 가로를 채우지 않고 작게 왼쪽에 둔다 (목록이 먼저 보이게).
            child: Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                label: l10n.playlistsImport,
                icon: AppIcons.link,
                variant: PillVariant.tonal,
                compact: true,
                onPressed: () => context.push(Routes.playlistImport),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (lists.isNotEmpty)
            Padding(
              padding: AppSpacing.screen,
              // 카드를 길게 눌러 끌면 순서가 바뀐다 (메뉴는 카드의 ⋮).
              child: PlaylistGrid(
                lists: lists,
                onReorder: context.read<PlaylistsCubit>().reorder,
              ),
            ),
          // 좋아요 목록 말고 직접 만든 재생목록이 없을 때의 안내.
          if (lists.every((p) => p.isFavorites))
            EmptyState(title: l10n.playlistsEmpty),
        ],
      ),
    );
  }
}
