import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../theme/presentation/bloc/theme_cubit.dart';
import '../../../search/presentation/bloc/preview_cubit.dart';
import '../../domain/entities/media_session_info.dart';
import '../bloc/notification_settings_cubit.dart';
import '../bloc/notification_sync_cubit.dart';

/// 재생 상태를 알림창으로 옮기고, 알림에서 누른 재생 조작을 재생 상태에 돌려준다.
/// 앱 셸 한 곳에서 감싼다 ([NotificationSyncCubit]이 바뀐 것만 골라 알림을 부른다).
class NotificationBridge extends StatefulWidget {
  const NotificationBridge({super.key, required this.child, this.onOpenPlayer});

  final Widget child;

  /// 알림을 눌렀을 때 플레이어 화면을 연다 (재생 중인 곡이 있을 때만 부른다).
  final VoidCallback? onOpenPlayer;

  @override
  State<NotificationBridge> createState() => _NotificationBridgeState();
}

class _NotificationBridgeState extends State<NotificationBridge>
    with WidgetsBindingObserver {
  StreamSubscription<MediaCommand>? _commands;
  StreamSubscription<void>? _openRequests;
  Future<void>? _restoring;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _commands = context.read<NotificationSyncCubit>().commands.listen(
      _onCommand,
    );
    _openRequests = context.read<NowPlayingCubit>().openPlayerRequests.listen(
      (_) => _openPlayer(),
    );
    if (context.read<LibraryCubit>().state.loaded) _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commands?.cancel();
    _openRequests?.cancel();
    super.dispose();
  }

  /// 앱이 새로 켜졌을 때 한 번: 네이티브가 쥐고 있는 대기열을 되살리고,
  /// 알림을 눌러 켠 것이면 현재 곡의 플레이어 화면을 연다.
  void _restore() {
    _restoring ??= () async {
      final player = context.read<NowPlayingCubit>();
      final byId = {
        for (final t in context.read<LibraryCubit>().state.tracks) t.id: t,
      };
      await player.restore((id) => byId[id]);
      if (mounted && await player.takeOpenPlayerRequest()) _openPlayer();
    }();
  }

  Future<void> _openPlayer() async {
    await _restoring;
    if (!mounted || context.read<NowPlayingCubit>().state.track == null) return;
    widget.onOpenPlayer?.call();
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
          if (!preview.state.paused) preview.togglePause();
        case MediaCommandType.play:
          if (preview.state.paused) preview.togglePause();
        case MediaCommandType.stop:
          preview.stop();
        case MediaCommandType.seek:
          final to = command.position;
          final total = preview.state.progress?.duration;
          if (to != null && total != null && total > Duration.zero) {
            preview.seekTo(to.inMilliseconds / total.inMilliseconds);
          }
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
    final isPreview = previewing.status == PreviewStatus.playing && hit != null;
    // 커버가 없을 때 그릴 기본 커버는 앱 안 곡 칸과 같은 색: 고른 색 > 곡마다 정해진 톤.
    final chosen = isPreview || track == null
        ? null
        : context.read<CoverColorCubit>().state[CoverKey.track(track.id)];
    final glow = chosen != null
        ? glowFromColor(Color(chosen))
        : context.tokens.glow(toneFor(isPreview ? hit.id : track?.id ?? ''));
    context.read<NotificationSyncCubit>().syncPlayback(
      preview: isPreview
          ? PreviewNotice(
              title: previewing.title,
              uploader: hit.uploader,
              artUri: hit.thumbnailUrl,
              position: previewing.progress?.position ?? Duration.zero,
              duration: previewing.progress?.duration,
              paused: previewing.paused,
            )
          : null,
      coverColors: [for (final c in glow) c.toARGB32()],
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
      BlocListener<LibraryCubit, LibraryState>(
        listenWhen: (a, b) => !a.loaded && b.loaded,
        listener: (_, _) => _restore(),
      ),
      BlocListener<NowPlayingCubit, NowPlayingState>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<ThemeCubit, ThemeState>(
        listenWhen: (a, b) => a != b,
        listener: (_, _) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncPlayback();
        }),
      ),
      BlocListener<PreviewCubit, PreviewState>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<PlaylistsCubit, List<Playlist>>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<CoverColorCubit, Map<String, int>>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<CoverCubit, Map<String, CoverArt>>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<NotificationSettingsCubit, NotificationSettingsState>(
        listenWhen: (a, b) => a.settings != b.settings || a.loaded != b.loaded,
        listener: (_, _) {
          _syncPlayback();
        },
      ),
    ],
    child: widget.child,
  );
}
