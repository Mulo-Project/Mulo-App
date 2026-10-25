import 'dart:async';

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/cached_web_image.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/presentation/bloc/download_queue_cubit.dart';
import '../../../downloads/presentation/widgets/download_bar.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../theme/presentation/bloc/theme_cubit.dart';
import '../../../search/presentation/bloc/preview_cubit.dart';
import '../../domain/entities/media_session_info.dart';
import '../../domain/repositories/download_notifier.dart';
import '../bloc/notification_settings_cubit.dart';
import '../bloc/notification_sync_cubit.dart';

/// 받기 대기열 · 재생 상태를 알림창으로 옮기고, 알림에서 누른 재생 조작을 재생 상태에 돌려준다.
/// 앱 셸 한 곳에서 감싼다 ([NotificationSyncCubit]이 바뀐 것만 골라 알림을 부른다).
class NotificationBridge extends StatefulWidget {
  const NotificationBridge({
    super.key,
    required this.child,
    this.onOpenPlayer,
    this.onOpenDownload,
  });

  final Widget child;

  /// 알림을 눌렀을 때 플레이어 화면을 연다 (재생 중인 곡이 있을 때만 부른다).
  final VoidCallback? onOpenPlayer;

  /// 받기 알림(진행 · 완료)을 눌렀을 때 그 곡의 상세 화면을 연다.
  final ValueChanged<MediaHit>? onOpenDownload;

  @override
  State<NotificationBridge> createState() => _NotificationBridgeState();
}

class _NotificationBridgeState extends State<NotificationBridge>
    with WidgetsBindingObserver {
  StreamSubscription<MediaCommand>? _commands;
  StreamSubscription<void>? _openRequests;
  Future<void>? _restoring;

  /// 알림을 눌러 앱이 새로 켜졌다: 대기열을 복원하고 플레이어 화면으로 갈 때까지 첫 화면이 비치지 않게 덮는다.
  // 첫 프레임부터 덮어 둔다 (시작 화면과 같은 모양). 알림으로 켠 게 아니면 바로 걷는다.
  var _splash = true;
  var _openPending = false;
  late final Future<void> _boot = _checkLaunch();
  StreamSubscription<DownloadNotificationAction>? _downloadActions;
  StreamSubscription<String>? _downloadOpens;

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
    _boot.then((_) {
      if (mounted && context.read<LibraryCubit>().state.loaded) _restore();
    });
    _downloadActions = context
        .read<NotificationSyncCubit>()
        .downloadActions
        .listen(_onDownloadAction);
    final sync = context.read<NotificationSyncCubit>();
    _downloadOpens = sync.downloadOpens.listen((id) => _openDownload(id));
    // 받기 알림을 눌러 앱이 새로 켜졌다면 그 곡의 상세 화면으로 간다.
    sync.takeDownloadOpen().then((id) {
      if (id != null && mounted) _openDownload(id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commands?.cancel();
    _openRequests?.cancel();
    _downloadActions?.cancel();
    _downloadOpens?.cancel();
    super.dispose();
  }

  /// 앱이 새로 켜졌을 때 한 번: 네이티브가 쥐고 있는 대기열을 되살리고,
  /// 알림을 눌러 켠 것이면 현재 곡의 플레이어 화면을 연다.
  void _restore() {
    _restoring ??= () async {
      await _boot;
      if (!mounted) return;
      final player = context.read<NowPlayingCubit>();
      final byId = {
        for (final t in context.read<LibraryCubit>().state.tracks) t.id: t,
      };
      await player.restore((id) => byId[id]);
      if (!mounted || !_openPending) return;
      _openPending = false;
      _pushPlayer();
      await Future<void>.delayed(AppMotion.slow);
      _hideSplash();
    }();
  }

  /// 알림을 눌러 새로 켜졌는지 확인한다. 그렇다면 복원이 끝날 때까지 덮개를 씌운다.
  Future<void> _checkLaunch() async {
    final opened = await context
        .read<NowPlayingCubit>()
        .takeOpenPlayerRequest();
    if (!mounted) return;
    if (!opened) {
      _hideSplash();
      return;
    }
    setState(() {
      _openPending = true;
      _splash = true;
    });
    // 보관함이 끝내 안 불러와져도 앱이 덮인 채로 남지 않게 한다.
    Future<void>.delayed(const Duration(seconds: 6), _hideSplash);
  }

  void _hideSplash() {
    if (mounted && _splash) setState(() => _splash = false);
  }

  Future<void> _openPlayer() async {
    await _restoring;
    if (mounted) _pushPlayer();
  }

  void _pushPlayer() {
    if (context.read<NowPlayingCubit>().state.track == null) return;
    widget.onOpenPlayer?.call();
  }

  /// 시스템 설정에서 알림 권한을 바꾸고 돌아왔을 수 있다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsCubit>().refreshPermission();
    }
  }

  /// 받기 알림 본문을 눌렀다: 그 항목의 상세 화면을 연다.
  /// 앱이 막 켜져 받기 대기열을 아직 못 읽었을 수 있어서 잠시 기다려 본다 (끝내 없으면 그대로 둔다).
  void _openDownload(String id, [int tries = 0]) {
    if (!mounted) return;
    final item = context
        .read<DownloadQueueCubit>()
        .state
        .items
        .where((i) => i.id == id)
        .firstOrNull;
    if (item == null) {
      if (tries < 10) {
        Future<void>.delayed(
          const Duration(milliseconds: 300),
          () => _openDownload(id, tries + 1),
        );
      }
      return;
    }
    widget.onOpenDownload?.call(mediaHitOfDownload(item));
  }

  /// 받기 알림의 버튼. 미리 듣기: 지금 받는 곡을 받지 않고 바로 듣는다 (받기는 그대로 이어진다).
  /// 이미 듣는 중이면 그대로 둔다. 취소: 지금 받는 곡을 대기열에서 뺀다.
  void _onDownloadAction(DownloadNotificationAction action) {
    // 알림이 보이는 곡: 받는 중 → 대기 → (모두 일시정지면) 일시정지된 곡.
    final active = context
        .read<DownloadQueueCubit>()
        .state
        .items
        .where((i) => i.isActive)
        .toList();
    final current =
        active.where((i) => i.status != DownloadStatus.paused).firstOrNull ??
        active.firstOrNull;
    if (current == null) return;
    if (action == DownloadNotificationAction.cancel) {
      context.read<DownloadQueueCubit>().cancel(current.id);
      return;
    }
    if (action == DownloadNotificationAction.toggleHold) {
      final queue = context.read<DownloadQueueCubit>();
      if (current.status == DownloadStatus.paused) {
        queue.resume(current.id);
      } else {
        queue.pause(current.id);
      }
      return;
    }
    final preview = context.read<PreviewCubit>();
    if (action == DownloadNotificationAction.pausePreview) {
      if (preview.state.isActive(current.id)) preview.togglePause();
      return;
    }
    if (action == DownloadNotificationAction.stopPreview) {
      if (preview.state.isActive(current.id)) preview.stop();
      return;
    }
    if (preview.state.isActive(current.id)) return;
    // 메인 재생과 겹치지 않게 재생 중이면 멈춘다.
    final player = context.read<NowPlayingCubit>();
    if (player.state.isPlaying) player.togglePlay();
    preview.toggle(
      MediaHit(
        id: current.id,
        title: current.title,
        url: current.url,
        uploader: current.artist,
        duration: current.duration,
        thumbnailUrl: current.thumbnailUrl,
      ),
    );
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
        case MediaCommandType.shuffle:
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
      case MediaCommandType.shuffle:
        player.toggleShuffle();
      case MediaCommandType.seek:
        final to = command.position;
        if (to != null) player.seekTo(to);
    }
  }

  /// 웹 커버 주소 → 저장된 사본(file 주소). 사본이 있으면 오프라인에서도 알림에 뜬다.
  final _artCopies = <String, String>{};
  var _artSeq = 0;

  /// 지금 곡 앞뒤로 사본을 미리 받아 둘 곡 수 (전체를 받으면 큰 대기열에서 낭비다).
  static const _copyBefore = 3;
  static const _copyAfter = 20;

  /// 대기열 곡별 커버를 네이티브에 알린다 (앱이 꺼진 사이 곡이 넘어가도 알림에 커버가 나오게).
  /// 웹 커버는 지금 곡 앞뒤 일부만 사본을 받아 그 파일 주소로 보내고, 나머지는 주소 그대로 보낸다.
  void _syncQueueArt() {
    final settings = context.read<NotificationSettingsCubit>().state;
    if (!settings.loaded) return;
    final covers = context.read<CoverCubit>().state;
    final now = context.read<NowPlayingCubit>().state;
    final sync = context.read<NotificationSyncCubit>();
    final seq = ++_artSeq;
    final art = <String, String>{};
    final toCopy = <String>[];
    for (var i = 0; i < now.queue.length; i++) {
      final t = now.queue[i];
      final cover = covers[CoverKey.track(t.id)];
      final uri = _artUri(cover);
      if (uri == null) continue;
      final copy = cover!.isWeb ? _artCopies[uri] : null;
      art[t.id] = copy ?? uri;
      if (cover.isWeb &&
          copy == null &&
          i >= now.index - _copyBefore &&
          i <= now.index + _copyAfter) {
        toCopy.add(uri);
      }
    }
    sync.syncQueueArt(art, settings: settings.settings);
    if (toCopy.isNotEmpty) _fetchCopies(toCopy, seq);
  }

  Future<void> _fetchCopies(List<String> urls, int seq) async {
    var added = false;
    for (final url in urls) {
      final file = await CachedWebImage.localCopy(url);
      if (file == null) continue;
      _artCopies[url] = file.uri.toString();
      added = true;
      // 더 새 요청이 시작됐으면 그쪽이 이어서 처리한다.
      if (!mounted || seq != _artSeq) return;
    }
    if (added && mounted && seq == _artSeq) _syncQueueArt();
  }

  PreviewState? get _previewing {
    final s = context.read<PreviewCubit>().state;
    return s.status == PreviewStatus.idle ? null : s;
  }

  void _syncDownloads() {
    final settings = context.read<NotificationSettingsCubit>().state;
    if (!settings.loaded) return;
    context.read<NotificationSyncCubit>().syncDownloads(
      context.read<DownloadQueueCubit>().state.items,
      settings.settings,
      context.l10n,
      previewingId: _previewing?.hitId,
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
      queueIndex: now.index,
      queueLength: now.queue.length,
      favorite:
          track != null && context.read<PlaylistsCubit>().isFavorite(track.id),
      shuffle: now.shuffle,
      sleepEndsAt: now.sleepEndsAt,
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
      BlocListener<DownloadQueueCubit, DownloadQueueState>(
        listener: (_, _) => _syncDownloads(),
      ),
      BlocListener<NowPlayingCubit, NowPlayingState>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<ThemeCubit, ThemeState>(
        listenWhen: (a, b) => a.dark != b.dark || a.light != b.light,
        listener: (_, _) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncPlayback();
        }),
      ),
      BlocListener<PreviewCubit, PreviewState>(
        listener: (_, _) {
          _syncPlayback();
          _syncDownloads();
        },
      ),
      BlocListener<PlaylistsCubit, List<Playlist>>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<CoverColorCubit, Map<String, int>>(
        listener: (_, _) => _syncPlayback(),
      ),
      BlocListener<CoverCubit, Map<String, CoverArt>>(
        listener: (_, _) {
          _syncPlayback();
          _syncQueueArt();
        },
      ),
      BlocListener<NowPlayingCubit, NowPlayingState>(
        listenWhen: (a, b) =>
            !identical(a.queue, b.queue) || a.index != b.index,
        listener: (_, _) => _syncQueueArt(),
      ),
      BlocListener<NotificationSettingsCubit, NotificationSettingsState>(
        listenWhen: (a, b) => a.settings != b.settings || a.loaded != b.loaded,
        listener: (_, _) {
          _syncDownloads();
          _syncPlayback();
          _syncQueueArt();
        },
      ),
    ],
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_splash || _openPending) const _LaunchCover(),
      ],
    ),
  );
}

/// 알림을 눌러 새로 켜졌을 때 대기열을 복원하고 플레이어 화면으로 가는 동안 첫 화면을 가리는 덮개.
class _LaunchCover extends StatelessWidget {
  const _LaunchCover();

  /// 안드로이드 시작 화면(`launch_background`)과 같은 검정 바탕 + 흰 음표: 이어 붙어도 바뀌어 보이지 않는다.
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppPalette.black,
    child: Center(
      child: Icon(
        Icons.music_note,
        size: 56,
        color: AppPalette.white.withValues(alpha: .9),
      ),
    ),
  );
}
