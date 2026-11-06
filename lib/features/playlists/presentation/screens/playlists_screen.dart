import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../app/router.dart';
import '../bloc/playlists_cubit.dart';
import '../widgets/new_playlist_sheet.dart';
import '../widgets/playlist_grid.dart';

/// 위 막대 ＋ 메뉴의 동작.
enum _AddAction { create, fromYoutube }

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
              // ＋ 하나에 "새 재생목록"과 "유튜브에서 가져오기"를 메뉴로 모은다.
              Builder(
                builder: (menuContext) => CircleIconButton(
                  icon: AppIcons.add,
                  tooltip: l10n.playlistsNew,
                  emphasized: true,
                  onPressed: () async {
                    final action = await showAppMenu<_AddAction>(
                      menuContext,
                      items: [
                        AppMenuItem(
                          value: _AddAction.create,
                          icon: AppIcons.add,
                          label: l10n.playlistsNew,
                        ),
                        AppMenuItem(
                          value: _AddAction.fromYoutube,
                          icon: AppIcons.link,
                          label: l10n.playlistsImport,
                        ),
                      ],
                    );
                    if (!context.mounted || action == null) return;
                    switch (action) {
                      case _AddAction.create:
                        showNewPlaylistSheet(context);
                      case _AddAction.fromYoutube:
                        context.push(Routes.playlistImport);
                    }
                  },
                ),
              ),
            ],
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
          // 직접 만든 재생목록이 둘 이상이면 순서 바꾸는 법을 한 줄로 알려 준다.
          if (lists.where((p) => !p.isFavorites).length > 1)
            Padding(
              padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
              child: Text(
                l10n.playlistsReorderHint,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
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
