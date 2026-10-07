import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../search/presentation/bloc/preview_cubit.dart';
import '../../domain/entities/media_session_info.dart';
import '../bloc/notification_settings_cubit.dart';
import '../bloc/notification_sync_cubit.dart';

/// 받기 대기열 · 재생 상태를 알림창으로 옮기고, 알림에서 누른 재생 조작을 재생 상태에 돌려준다.
/// 앱 셸 한 곳에서 감싼다 ([NotificationSyncCubit]이 바뀐 것만 골라 알림을 부른다).
class NotificationBridge extends StatefulWidget {
  const NotificationBridge({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationBridge> createState() => _NotificationBridgeState();
}

class _NotificationBridgeState extends State<NotificationBridge>
    with WidgetsBindingObserver {
  StreamSubscription<MediaCommand>? _commands;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _commands = context.read<NotificationSyncCubit>().commands.listen(
      _onCommand,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commands?.cancel();
    super.dispose();
  }

  /// 시스템 설정에서 알림 권한을 바꾸고 돌아왔을 수 있다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsCubit>().refreshPermission();
    }
  }

  void _onCommand(MediaCommand command) {
    // 미리 듣는 동안 알림은 미리 듣기의 것: 멈추기 · 옮기기만 받는다.
    final preview = context.read<PreviewCubit>();
    if (preview.state.status == PreviewStatus.playing) {
      switch (command.type) {
        case MediaCommandType.pause:
        case MediaCommandType.stop:
          preview.stop();
        case MediaCommandType.seek:
          final to = command.position;
          final total = preview.state.progress?.duration;
          if (to != null && total != null && total > Duration.zero) {
            preview.seekTo(to.inMilliseconds / total.inMilliseconds);
          }
        case MediaCommandType.play:
        case MediaCommandType.next:
        case MediaCommandType.previous:
        case MediaCommandType.favorite:
          break;
      }
      return;
    }
    final player = context.read<NowPlayingCubit>();
    final playing = player.state.isPlaying;
    switch (command.type) {
      case MediaCommandType.play:
        if (!playing) player.togglePlay();
      case MediaCommandType.pause:
      case MediaCommandType.stop:
        if (playing) player.togglePlay();
      case MediaCommandType.next:
        player.next();
      case MediaCommandType.previous:
        player.previous();
      case MediaCommandType.favorite:
        final track = player.state.track;
        if (track != null) {
          context.read<PlaylistsCubit>().toggleFavorite(track.id);
        }
      case MediaCommandType.seek:
        final to = command.position;
        if (to != null) player.seekTo(to);
    }
  }

  void _syncDownloads() {
    final settings = context.read<NotificationSettingsCubit>().state;
    if (!settings.loaded) return;
    context.read<NotificationSyncCubit>().syncDownloads(
      context.read<DownloadQueueCubit>().state.items,
      settings.settings,
      context.l10n,
    );
  }

  void _syncPlayback() {
    final settings = context.read<NotificationSettingsCubit>().state;
    if (!settings.loaded) return;
    final now = context.read<NowPlayingCubit>().state;
    final track = now.track;
    final cover = track == null
        ? null
        : context.read<CoverCubit>().state[CoverKey.track(track.id)];
    final previewing = context.read<PreviewCubit>().state;
    final hit = previewing.hit;
    context.read<NotificationSyncCubit>().syncPlayback(
      preview: previewing.status == PreviewStatus.playing && hit != null
          ? PreviewNotice(
              title: previewing.title,
              uploader: hit.uploader,
              artUri: hit.thumbnailUrl,
              position: previewing.progress?.position ?? Duration.zero,
              duration: previewing.progress?.duration,
            )
          : null,
      track: track,
      isPlaying: now.isPlaying,
      position: now.position,
      hasPrevious: now.queue.length > 1 || now.position > Duration.zero,
      hasNext: now.queue.length > 1,
      favorite:
          track != null && context.read<PlaylistsCubit>().isFavorite(track.id),
      artUri: _artUri(cover),
      settings: settings.settings,
      l10n: context.l10n,
    );
  }

  /// 알림에 쓸 커버 주소 (확대 · 위치 맞춤은 알림에서는 쓰지 않는다).
  String? _artUri(CoverArt? cover) {
    if (cover == null) return null;
    if (cover.isWeb) return cover.url;
    return Uri.file(cover.path!).toString();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<DownloadQueueCubit, DownloadQueueState>(
        listener: (_, _) => _syncDownloads(),
      ),
      BlocListener<NowPlayingCubit, NowPlayingState>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<PreviewCubit, PreviewState>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<PlaylistsCubit, List<Playlist>>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<CoverCubit, Map<String, CoverArt>>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<NotificationSettingsCubit, NotificationSettingsState>(
        listenWhen: (a, b) => a.settings != b.settings || a.loaded != b.loaded,
        listener: (_, _) {
          _syncDownloads();
          _syncPlayback();
        },
      ),
    ],
    child: widget.child,
  );
}
