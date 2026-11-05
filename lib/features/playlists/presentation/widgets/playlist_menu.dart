import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/decorate_sheet.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/playlists_cubit.dart';
import 'playlist_card.dart';

enum _Action { playAll, shuffle, addTracks, decorate, rename, delete }

/// 재생목록 팝업 메뉴: 전체 재생 · 셔플 재생 · 곡 추가 · 꾸미기(이미지 · 색 시트) · 이름 바꾸기 · 삭제.
/// 카드의 ⋮, 길게 누르기, 오른쪽 클릭, 상세 화면의 ⋮에서 같은 메뉴를 연다.
/// [globalPosition]이 있으면 눌린 자리에, 없으면 [context] 위젯 옆에 띄운다.
/// 좋아요 목록은 이름 · 삭제 항목이 없고, 꾸미기에서 색을 고를 수 없다.
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
        value: _Action.decorate,
        icon: AppIcons.sparkle,
        label: l10n.playlistMenuDecorate,
      ),
      if (!pl.isFavorites) ...[
        AppMenuItem(
          value: _Action.rename,
          icon: AppIcons.edit,
          label: l10n.playlistMenuRename,
        ),
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
    case _Action.decorate:
      await showDecorateSheet(
        context,
        coverKey: CoverKey.playlist(pl.id),
        title: playlistNameOf(context.l10n, pl),
        tone: playlistToneOf(pl),
        allowColor: !pl.isFavorites,
      );
    case _Action.rename:
      await _rename(context, pl);
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

Future<void> _rename(BuildContext context, Playlist pl) async {
  final cubit = context.read<PlaylistsCubit>();
  final name = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _RenameDialog(initial: pl.name),
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

/// 새 이름 입력. 저장하면 이름, 취소하면 null.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.playlistRenameTitle,
      content: AppTextField(
        label: l10n.playlistNewHint,
        controller: _name,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(label: l10n.playlistRenameSave, onPressed: _save),
      ],
    );
  }
}
