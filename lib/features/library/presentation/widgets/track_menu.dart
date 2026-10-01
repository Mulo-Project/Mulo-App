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
}

/// 곡 타일의 ⋮ 버튼. 누르면 [showTrackMenu].
class TrackMoreButton extends StatelessWidget {
  const TrackMoreButton({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.trackMenuTitle,
    onPressed: () => showTrackMenu(context, track),
    icon: Icon(Icons.more_vert_rounded, color: context.palette.onSurfaceMuted),
  );
}

/// 곡 메뉴 (⋮ · 길게 누르기 · 데스크톱 오른쪽 클릭에서 같은 메뉴를 연다).
/// 항목을 고르면 시트를 닫고, 이어지는 대화상자 · 안내는 [context]에서 이어 간다.
Future<void> showTrackMenu(BuildContext context, Track track) async {
  final action = await showModalBottomSheet<_TrackAction>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    // 탭 틀(미니 플레이어 · 탭 바) 위에 뜨도록 최상위 내비게이터에서 연다.
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (_) => _TrackMenuSheet(track: track),
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
    case _TrackAction.delete:
      await _delete(context, track);
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
  await covers.clear(CoverKey.track(track.id));
  await lyrics.clear(track.id);
  await library.delete(track.id);
  player.removeFromQueue(track);
  if (context.mounted) _snack(context, l10n.trackDeleted);
}

class _TrackMenuSheet extends StatelessWidget {
  const _TrackMenuSheet({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    Widget row(
      IconData icon,
      String label,
      _TrackAction action, {
      bool destructive = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: MenuRow(
        icon: icon,
        label: label,
        destructive: destructive,
        onTap: () => Navigator.of(context).pop(action),
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                track.title,
                style: text.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                track.artist.isEmpty ? l10n.unknownArtist : track.artist,
                style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              row(
                Icons.playlist_play_rounded,
                l10n.trackMenuPlayNext,
                _TrackAction.playNext,
              ),
              row(
                Icons.queue_music_rounded,
                l10n.trackMenuAddToQueue,
                _TrackAction.addToQueue,
              ),
              row(
                Icons.playlist_add_rounded,
                l10n.trackMenuAddToPlaylist,
                _TrackAction.addToPlaylist,
              ),
              row(
                Icons.edit_rounded,
                l10n.trackMenuEditInfo,
                _TrackAction.editInfo,
              ),
              row(
                Icons.lyrics_rounded,
                l10n.trackMenuLyrics,
                _TrackAction.lyrics,
              ),
              row(Icons.image_rounded, l10n.trackMenuCover, _TrackAction.cover),
              row(
                Icons.delete_outline_rounded,
                l10n.trackMenuDelete,
                _TrackAction.delete,
                destructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
