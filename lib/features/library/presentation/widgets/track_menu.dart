import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/cover_sheet.dart';
import '../../../downloads/presentation/widgets/playlist_picker_dialog.dart';
import '../../../lyrics/presentation/bloc/lyrics_cubit.dart';
import '../../../lyrics/presentation/widgets/lyrics_editor.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_info.dart';
import '../bloc/library_cubit.dart';

enum _TrackAction {
  playNext,
  addToQueue,
  addToPlaylist,
  editInfo,
  lyrics,
  cover,
  delete,
  removeFromPlaylist,
  deleteFile,
}

/// 곡 타일의 ⋮ 버튼. 누르면 버튼 옆에 [showTrackMenu] 팝업 메뉴가 열린다.
class TrackMoreButton extends StatelessWidget {
  const TrackMoreButton({super.key, required this.track, this.playlistId});

  final Track track;

  /// 재생목록 안의 곡이면 그 재생목록 id (삭제가 "빼기" · "파일 삭제"로 나뉜다).
  final String? playlistId;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => IconButton(
      tooltip: context.l10n.trackMenuTitle,
      onPressed: () => showTrackMenu(context, track, playlistId: playlistId),
      icon: Icon(
        Icons.more_vert_rounded,
        color: context.palette.onSurfaceMuted,
      ),
    ),
  );
}

/// 곡 메뉴: 팝업 메뉴 (⋮ · 길게 누르기 · 데스크톱 오른쪽 클릭에서 같은 메뉴를 연다).
/// [globalPosition]이 있으면 눌린 자리에, 없으면 [context] 위젯 옆에 띄운다.
/// 항목을 고르면 메뉴를 닫고, 이어지는 대화상자 · 안내는 [context]에서 이어 간다.
///
/// [playlistId]가 있으면(재생목록 안의 곡) 삭제가 "재생목록에서 빼기"와
/// "파일 삭제"로 나뉜다. 없으면(보관함) "삭제"는 음악 파일까지 지운다.
Future<void> showTrackMenu(
  BuildContext context,
  Track track, {
  Offset? globalPosition,
  String? playlistId,
}) async {
  final l10n = context.l10n;
  final action = await showAppMenu<_TrackAction>(
    context,
    globalPosition: globalPosition,
    items: [
      AppMenuItem(
        value: _TrackAction.playNext,
        icon: Icons.playlist_play_rounded,
        label: l10n.trackMenuPlayNext,
      ),
      AppMenuItem(
        value: _TrackAction.addToQueue,
        icon: Icons.queue_music_rounded,
        label: l10n.trackMenuAddToQueue,
      ),
      AppMenuItem(
        value: _TrackAction.addToPlaylist,
        icon: Icons.playlist_add_rounded,
        label: l10n.trackMenuAddToPlaylist,
      ),
      AppMenuItem(
        value: _TrackAction.editInfo,
        icon: Icons.edit_rounded,
        label: l10n.trackMenuEditInfo,
      ),
      AppMenuItem(
        value: _TrackAction.lyrics,
        icon: Icons.lyrics_rounded,
        label: l10n.trackMenuLyrics,
      ),
      AppMenuItem(
        value: _TrackAction.cover,
        icon: Icons.image_rounded,
        label: l10n.trackMenuCover,
      ),
      if (playlistId == null)
        AppMenuItem(
          value: _TrackAction.delete,
          icon: Icons.delete_outline_rounded,
          label: l10n.trackMenuDelete,
          destructive: true,
          dividerBefore: true,
        )
      else ...[
        AppMenuItem(
          value: _TrackAction.removeFromPlaylist,
          icon: Icons.playlist_remove_rounded,
          label: l10n.trackMenuRemoveFromPlaylist,
          dividerBefore: true,
        ),
        AppMenuItem(
          value: _TrackAction.deleteFile,
          icon: Icons.delete_outline_rounded,
          label: l10n.trackMenuDeleteFile,
          destructive: true,
        ),
      ],
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _TrackAction.playNext:
      context.read<NowPlayingCubit>().playNext(track);
      _snack(context, context.l10n.trackMenuPlayNextDone);
    case _TrackAction.addToQueue:
      context.read<NowPlayingCubit>().addToQueue(track);
      _snack(context, context.l10n.trackMenuAddedToQueue);
    case _TrackAction.addToPlaylist:
      await _addToPlaylist(context, track);
    case _TrackAction.editInfo:
      await _editInfo(context, track);
    case _TrackAction.lyrics:
      await showLyricsEditor(context, track);
    case _TrackAction.cover:
      await showCoverSheet(
        context,
        coverKey: CoverKey.track(track.id),
        title: track.title,
        tone: toneFor(track.id),
      );
    case _TrackAction.delete || _TrackAction.deleteFile:
      await _delete(context, track);
    case _TrackAction.removeFromPlaylist:
      await context.read<PlaylistsCubit>().removeTrack(track.id, playlistId!);
      if (context.mounted) {
        _snack(context, context.l10n.trackRemovedFromPlaylist);
      }
  }
}

void _snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

Future<void> _addToPlaylist(BuildContext context, Track track) async {
  final l10n = context.l10n;
  final cubit = context.read<PlaylistsCubit>();
  if (cubit.state.isEmpty) return _snack(context, l10n.trackMenuNoPlaylists);
  final picked = await showPlaylistPickerDialog(
    context,
    playlists: cubit.state,
    selected: const {},
  );
  if (picked == null || picked.isEmpty) return;
  await cubit.addTrack(track.id, picked);
  if (context.mounted) {
    _snack(context, l10n.trackMenuAddedToPlaylists(picked.length));
  }
}

Future<void> _editInfo(BuildContext context, Track track) async {
  final l10n = context.l10n;
  final library = context.read<LibraryCubit>();
  final player = context.read<NowPlayingCubit>();
  final info = await showDialog<TrackInfo>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _TrackInfoDialog(track: track),
  );
  if (info == null) return;
  if (!await library.updateInfo(track.id, info)) return;
  player.updateTrack(track.withInfo(info.trimmed()));
  if (context.mounted) _snack(context, l10n.trackEditSaved);
}

Future<void> _delete(BuildContext context, Track track) async {
  final l10n = context.l10n;
  final library = context.read<LibraryCubit>();
  final player = context.read<NowPlayingCubit>();
  final covers = context.read<CoverCubit>();
  final lyrics = context.read<LyricsCubit>();
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _DeleteDialog(track: track),
  );
  if (ok != true) return;
  // 파일부터 지운다. 못 지우면(권한 거절 등) 기록은 그대로 둔다.
  if (!await library.delete(track)) {
    if (context.mounted) _snack(context, l10n.trackDeleteFailed);
    return;
  }
  await covers.clear(CoverKey.track(track.id));
  await lyrics.clear(track.id);
  player.removeFromQueue(track);
  if (context.mounted) _snack(context, l10n.trackDeleted);
}

/// 제목 · 아티스트 · 앨범 · 장르 편집. 저장하면 [TrackInfo], 취소하면 null.
class _TrackInfoDialog extends StatefulWidget {
  const _TrackInfoDialog({required this.track});

  final Track track;

  @override
  State<_TrackInfoDialog> createState() => _TrackInfoDialogState();
}

class _TrackInfoDialogState extends State<_TrackInfoDialog> {
  late final _title = TextEditingController(text: widget.track.title);
  late final _artist = TextEditingController(text: widget.track.artist);
  late final _album = TextEditingController(text: widget.track.album);
  late final _genre = TextEditingController(text: widget.track.genre);

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _genre.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      TrackInfo(
        title: _title.text,
        artist: _artist.text,
        album: _album.text,
        genre: _genre.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.trackEditTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: l10n.trackEditName, controller: _title),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(label: l10n.trackEditArtist, controller: _artist),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(label: l10n.trackEditAlbum, controller: _album),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: l10n.trackEditGenre,
              controller: _genre,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(label: l10n.trackEditSave, onPressed: _save),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: l10n.actionCancel,
              variant: PillVariant.tonal,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.trackDeleteTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.trackDeleteBody(track.title), style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: l10n.trackDeleteConfirm,
              icon: Icons.delete_outline_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: l10n.actionCancel,
              variant: PillVariant.tonal,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
