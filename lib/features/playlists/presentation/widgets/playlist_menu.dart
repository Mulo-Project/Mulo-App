import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/presentation/screens/collection_info_screen.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/playlists_cubit.dart';
import 'playlist_card.dart';

enum _Action { playAll, shuffle, addTracks, info, delete }

/// 재생목록 팝업 메뉴: 전체 재생 · 셔플 재생 · 곡 추가 · 정보(큰 이미지 · 이름 바꾸기 · 색) · 삭제.
/// 카드의 ⋮, 길게 누르기, 오른쪽 클릭, 상세 화면의 ⋮에서 같은 메뉴를 연다.
/// [globalPosition]이 있으면 눌린 자리에, 없으면 [context] 위젯 옆에 띄운다.
/// 좋아요 목록은 삭제 항목이 없고, 정보에서 이름 · 색을 바꿀 수 없다.
Future<void> showPlaylistMenu(
  BuildContext context,
  Playlist pl, {
  Offset? globalPosition,
  VoidCallback? onDeleted,
}) async {
  final l10n = context.l10n;
  final action = await showAppMenu<_Action>(
    context,
    globalPosition: globalPosition,
    items: [
      AppMenuItem(
        value: _Action.playAll,
        icon: AppIcons.play,
        label: l10n.playlistMenuPlayAll,
      ),
      AppMenuItem(
        value: _Action.shuffle,
        icon: AppIcons.shuffle,
        label: l10n.playlistMenuShuffle,
      ),
      if (!pl.isFavorites)
        AppMenuItem(
          value: _Action.addTracks,
          icon: AppIcons.add,
          label: l10n.playlistAddTracks,
        ),
      AppMenuItem(
        value: _Action.info,
        icon: AppIcons.info,
        label: l10n.collectionMenuInfo,
      ),
      if (!pl.isFavorites) ...[
        AppMenuItem(
          value: _Action.delete,
          icon: AppIcons.delete,
          label: l10n.playlistMenuDelete,
          destructive: true,
          dividerBefore: true,
        ),
      ],
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _Action.playAll:
      await _playAll(context, pl);
    case _Action.shuffle:
      await _playAll(context, pl, shuffle: true);
    case _Action.addTracks:
      await context.push(Routes.playlistAddTracks(pl.id));
    case _Action.info:
      await _info(context, pl);
    case _Action.delete:
      await _delete(context, pl, onDeleted);
  }
}

Future<void> _playAll(
  BuildContext context,
  Playlist pl, {
  bool shuffle = false,
}) async {
  final tracks = await context.read<PlaylistsCubit>().tracksOf(pl.id);
  if (!context.mounted) return;
  if (tracks.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.playlistPlayEmpty)));
    return;
  }
  final now = context.read<NowPlayingCubit>();
  shuffle ? now.playShuffled(tracks) : now.playQueue(tracks);
}

/// 정보 화면: 큰 이미지 · 이름 바꾸기 · 색을 한 곳에서 (좋아요 목록은 이름 · 색을 바꾸지 않는다).
Future<void> _info(BuildContext context, Playlist pl) async {
  final l10n = context.l10n;
  final cubit = context.read<PlaylistsCubit>();
  final name = await showCollectionInfo(
    context,
    screenTitle: l10n.playlistInfoTitle,
    title: playlistNameOf(l10n, pl),
    subtitle: l10n.songCount(pl.trackCount),
    nameLabel: l10n.playlistNewHint,
    coverKey: CoverKey.playlist(pl.id),
    tone: playlistToneOf(pl),
    icon: AppIcons.playlistPlay,
    allowRename: !pl.isFavorites,
    allowColor: !pl.isFavorites,
    initialName: pl.name,
  );
  if (name == null) return;
  await cubit.rename(pl.id, name);
}

Future<void> _delete(
  BuildContext context,
  Playlist pl,
  VoidCallback? onDeleted,
) async {
  final cubit = context.read<PlaylistsCubit>();
  final covers = context.read<CoverCubit>();
  final colors = context.read<CoverColorCubit>();
  final l10n = context.l10n;
  final ok = await showConfirmDialog(
    context,
    title: l10n.playlistDeleteTitle,
    body: l10n.playlistDeleteBody(pl.name),
    confirmLabel: l10n.playlistDeleteConfirm,
    confirmIcon: AppIcons.delete,
    cancelLabel: l10n.actionCancel,
  );
  if (!ok) return;
  await cubit.delete(pl.id);
  await covers.clear(CoverKey.playlist(pl.id));
  await colors.clear(CoverKey.playlist(pl.id));
  onDeleted?.call();
}
