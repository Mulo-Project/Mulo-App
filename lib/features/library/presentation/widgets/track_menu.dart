import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/decorate_sheet.dart';
import '../../../lyrics/presentation/bloc/lyrics_cubit.dart';
import '../../../player/domain/entities/playback_speed.dart';
import '../../../lyrics/presentation/bloc/lyrics_overlay_cubit.dart';
import '../../../lyrics/presentation/bloc/lyrics_settings_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../player/presentation/bloc/playback_speed_cubit.dart';
import '../../../player/presentation/widgets/player_style_sheet.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_info.dart';
import '../bloc/library_cubit.dart';

enum _TrackAction {
  playerStyle,
  playbackSpeed,
  lyricsOverlay,
  playNext,
  addToQueue,
  addToPlaylist,
  favorite,
  editInfo,
  decorate,
  delete,
  removeFromPlaylist,
  removeFromQueue,
  deleteFile,
}

/// 곡 타일의 ⋮ 버튼. 누르면 버튼 옆에 [showTrackMenu] 팝업 메뉴가 열린다.
class TrackMoreButton extends StatelessWidget {
  const TrackMoreButton({
    super.key,
    required this.track,
    this.playlistId,
    this.inQueue = false,
  });

  final Track track;

  /// 재생목록 안의 곡이면 그 재생목록 id (삭제가 "빼기" · "파일 삭제"로 나뉜다).
  final String? playlistId;

  /// 재생 대기열 화면의 곡이면 true ("대기열에 추가" 대신 "대기열에서 빼기").
  final bool inQueue;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => IconButton(
      tooltip: context.l10n.trackMenuTitle,
      onPressed: () => showTrackMenu(
        context,
        track,
        playlistId: playlistId,
        inQueue: inQueue,
      ),
      icon: Icon(AppIcons.more, color: context.palette.onSurfaceMuted),
    ),
  );
}

/// 곡 메뉴: 팝업 메뉴 (⋮ · 길게 누르기 · 데스크톱 오른쪽 클릭에서 같은 메뉴를 연다).
/// [globalPosition]이 있으면 눌린 자리에, 없으면 [context] 위젯 옆에 띄운다.
/// [inPlayer]면 맨 위에 "플레이어 테마" · "재생 속도"가 더해진다 (재생 화면의 더 보기).
/// 항목을 고르면 메뉴를 닫고, 이어지는 대화상자 · 안내는 [context]에서 이어 간다.
///
/// [playlistId]가 있으면(재생목록 안의 곡) 삭제가 "재생목록에서 빼기"와
/// "파일 삭제"로 나뉜다. 없으면(보관함) "삭제"는 음악 파일까지 지운다.
Future<void> showTrackMenu(
  BuildContext context,
  Track track, {
  Offset? globalPosition,
  String? playlistId,
  bool inQueue = false,
  bool inPlayer = false,
}) async {
  final l10n = context.l10n;
  final favorite = context.read<PlaylistsCubit>().isFavorite(track.id);
  final action = await showAppMenu<_TrackAction>(
    context,
    globalPosition: globalPosition,
    items: [
      if (inPlayer)
        AppMenuItem(
          value: _TrackAction.playerStyle,
          icon: AppIcons.style,
          label: l10n.playerStyleTitle,
        ),
      if (inPlayer)
        AppMenuItem(
          value: _TrackAction.playbackSpeed,
          icon: AppIcons.timer,
          label:
              '${l10n.playerSpeedTitle} · ${speedLabel(l10n, context.read<PlaybackSpeedCubit>().state)}',
        ),
      if (inPlayer && defaultTargetPlatform == TargetPlatform.android)
        AppMenuItem(
          value: _TrackAction.lyricsOverlay,
          icon: AppIcons.lyrics,
          label: context.read<LyricsSettingsCubit>().state.overlay
              ? l10n.lyricsOverlayOff
              : l10n.lyricsOverlayOn,
        ),
      // 지금 재생 중인 곡의 메뉴(재생 화면)에서는 "다음 재생" · "대기열에 추가"를 뺀다.
      if (!inPlayer)
        AppMenuItem(
          value: _TrackAction.playNext,
          icon: AppIcons.playlistPlay,
          label: l10n.trackMenuPlayNext,
        ),
      if (!inQueue && !inPlayer)
        AppMenuItem(
          value: _TrackAction.addToQueue,
          icon: AppIcons.queue,
          label: l10n.trackMenuAddToQueue,
        ),
      AppMenuItem(
        value: _TrackAction.addToPlaylist,
        dividerBefore: inPlayer,
        icon: AppIcons.playlistAdd,
        label: l10n.trackMenuAddToPlaylist,
      ),
      AppMenuItem(
        value: _TrackAction.favorite,
        icon: favorite ? AppIcons.favorite : AppIcons.favoriteOutline,
        label: favorite ? l10n.trackMenuUnfavorite : l10n.trackMenuFavorite,
      ),
      AppMenuItem(
        value: _TrackAction.editInfo,
        icon: AppIcons.edit,
        label: l10n.trackMenuEditInfo,
      ),
      AppMenuItem(
        value: _TrackAction.decorate,
        icon: AppIcons.sparkle,
        label: l10n.trackMenuDecorate,
      ),
      if (playlistId == null && !inQueue)
        AppMenuItem(
          value: _TrackAction.delete,
          icon: AppIcons.delete,
          label: l10n.trackMenuDelete,
          destructive: true,
          dividerBefore: true,
        )
      else ...[
        if (inQueue)
          AppMenuItem(
            value: _TrackAction.removeFromQueue,
            icon: AppIcons.playlistRemove,
            label: l10n.trackMenuRemoveFromQueue,
            dividerBefore: true,
          )
        else
          AppMenuItem(
            value: _TrackAction.removeFromPlaylist,
            icon: AppIcons.playlistRemove,
            label: l10n.trackMenuRemoveFromPlaylist,
            dividerBefore: true,
          ),
        AppMenuItem(
          value: _TrackAction.deleteFile,
          icon: AppIcons.delete,
          label: l10n.trackMenuDeleteFile,
          destructive: true,
        ),
      ],
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _TrackAction.playerStyle:
      await showPlayerStyleSheet(context);
    case _TrackAction.playbackSpeed:
      await _pickSpeed(context);
    case _TrackAction.lyricsOverlay:
      await toggleLyricsOverlay(context);
    case _TrackAction.playNext:
      context.read<NowPlayingCubit>().playNext(track);
      _snack(context, context.l10n.trackMenuPlayNextDone);
    case _TrackAction.addToQueue:
      context.read<NowPlayingCubit>().addToQueue(track);
      _snack(context, context.l10n.trackMenuAddedToQueue);
    case _TrackAction.addToPlaylist:
      // 팝업 대신 재생목록 화면으로 가서 고른다.
      await context.push(Routes.playlistPick, extra: [track.id]);
    case _TrackAction.favorite:
      final on = await context.read<PlaylistsCubit>().toggleFavorite(track.id);
      if (context.mounted) {
        _snack(
          context,
          on ? context.l10n.trackFavoriteOn : context.l10n.trackFavoriteOff,
        );
      }
    case _TrackAction.editInfo:
      await _editInfo(context, track);
    case _TrackAction.decorate:
      await showDecorateSheet(
        context,
        coverKey: CoverKey.track(track.id),
        title: track.title,
        tone: toneFor(track.id),
      );
    case _TrackAction.delete || _TrackAction.deleteFile:
      await _delete(context, track);
    case _TrackAction.removeFromQueue:
      context.read<NowPlayingCubit>().removeFromQueue(track);
      _snack(context, context.l10n.trackRemovedFromQueue);
    case _TrackAction.removeFromPlaylist:
      await context.read<PlaylistsCubit>().removeTrack(track.id, playlistId!);
      if (context.mounted) {
        _snack(context, context.l10n.trackRemovedFromPlaylist);
      }
  }
}

/// 재생 속도 고르기: 메뉴 목록에서 고르면 바로 소리에 반영된다.
Future<void> _pickSpeed(BuildContext context) async {
  final l10n = context.l10n;
  final cubit = context.read<PlaybackSpeedCubit>();
  final picked = await showAppMenu<double>(
    context,
    items: [
      for (final s in PlaybackSpeed.options)
        AppMenuItem(
          value: s,
          icon: AppIcons.timer,
          label: speedLabel(l10n, s),
          selected: cubit.state == s,
        ),
    ],
  );
  if (picked != null) await cubit.set(picked);
}

/// "1.5배속" · "보통".
String speedLabel(AppLocalizations l10n, double speed) =>
    speed == PlaybackSpeed.normal
    ? l10n.playerSpeedNormal
    : l10n.playerSpeedValue('$speed');

/// 떠 있는 가사 창을 켜고 끈다. 켜려는데 "다른 앱 위에 표시" 권한이 없으면 시스템 설정을 열고 안내한다.
Future<void> toggleLyricsOverlay(BuildContext context) async {
  final settings = context.read<LyricsSettingsCubit>();
  final overlay = context.read<LyricsOverlayCubit>();
  final l10n = context.l10n;
  if (settings.state.overlay) {
    await settings.setOverlay(false);
    return;
  }
  if (await overlay.ensurePermission()) {
    await settings.setOverlay(true);
  } else if (context.mounted) {
    _snack(context, l10n.lyricsOverlayNeedPermission);
  }
}

void _snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

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
  final colors = context.read<CoverColorCubit>();
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
  await colors.clear(CoverKey.track(track.id));
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
    return AppDialog(
      title: l10n.trackEditTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
        ],
      ),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(label: l10n.trackEditSave, onPressed: _save),
      ],
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.trackDeleteTitle,
      body: l10n.trackDeleteBody(track.title),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PillButton(
          label: l10n.trackDeleteConfirm,
          icon: AppIcons.delete,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
