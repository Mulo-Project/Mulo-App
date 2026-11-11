import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../core/l10n/l10n.dart';
import '../features/covers/presentation/bloc/cover_cubit.dart';
import '../features/library/domain/entities/track.dart'
    show Track, formatDuration;
import '../features/home/presentation/bloc/play_recorder_cubit.dart';
import '../features/player/presentation/bloc/audio_output_cubit.dart';
import '../features/player/presentation/bloc/now_playing_cubit.dart';
import '../features/player/presentation/widgets/native_video.dart';
import '../features/player/presentation/widgets/player_sleep_timer.dart';
import '../features/search/presentation/bloc/preview_cubit.dart';
import '../features/search/domain/entities/saved_video.dart';
import '../features/search/presentation/bloc/saved_videos_cubit.dart';
import '../features/search/presentation/saved_track.dart';
import '../features/search/presentation/main_stream_video.dart';
import '../features/search/presentation/widgets/saved_cover_sync.dart';
import '../features/search/presentation/screens/saved_queue_detail_screen.dart'
    show showSavedQueueDetail;
import '../core/cache/cached_web_image.dart';
import '../features/downloads/presentation/bloc/download_queue_cubit.dart';
import '../features/downloads/presentation/widgets/download_bar.dart';
import '../features/downloads/presentation/widgets/download_float_button.dart';
import '../features/search/presentation/screens/media_detail_screen.dart';
import '../features/search/presentation/widgets/preview_video.dart';
import '../features/theme/presentation/bloc/theme_cubit.dart';
import 'mini_float_layer.dart';
import 'router.dart';
import 'theme_preview_bar.dart';

/// 탭 화면 공통 틀: 배경 · 탭 내용 · 가로 전체 유리 미니 플레이어 · 단색 하단 탭.
/// 재생 상태를 따라 재생 기록(곡 · 실제 재생 시간)을 남긴다.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  StatefulNavigationShell get shell => widget.shell;

  /// 받기 줄을 접어 둔 상태 (앱을 켜 두는 동안만).
  var _downloadMinimized = false;

  /// 플로팅 버튼을 보이는 중인가. 띠가 다 접힌 뒤에 나타나고 띠가 펴지기 전에 사라진다
  /// (띠 높이가 변하는 동안 버튼이 같이 오르내리지 않게).
  var _floatShown = false;
  Timer? _dockTimer;

  void _minimizeDownloads() {
    _dockTimer?.cancel();
    setState(() => _downloadMinimized = true);
    _dockTimer = Timer(AppMotion.medium, () {
      if (mounted && _downloadMinimized) setState(() => _floatShown = true);
    });
  }

  void _restoreDownloads() {
    _dockTimer?.cancel();
    setState(() => _floatShown = false);
    _dockTimer = Timer(AppMotion.fast, () {
      if (mounted) setState(() => _downloadMinimized = false);
    });
  }

  /// 미니 플레이어를 플로팅 버튼으로 바꿔 둔 상태 (앱을 켜 두는 동안만).
  var _miniFloating = false;

  /// 길게 눌러 미니 플레이어에서 버튼을 끌어내는 중 (손가락을 뗄 때까지).
  var _miniGripping = false;

  /// 버튼의 왼쪽 위 위치 (본문 좌표). 끄는 동안 셸 전체가 다시 그려지지 않게 따로 둔다.
  final _floatPos = ValueNotifier(Offset.zero);
  final _floatMoving = ValueNotifier(false);
  final _bodyKey = GlobalKey();
  final _miniKey = GlobalKey();
  var _miniHeight = 0.0;
  var _geometry = const MiniFloatGeometry(area: Rect.zero, safe: Rect.zero);
  var _grab = const Offset(
    FloatingPlayerButton.size / 2,
    FloatingPlayerButton.size / 2,
  );

  Offset _toBody(Offset global) {
    final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? global : box.globalToLocal(global);
  }

  void _gripStart(Offset global) {
    HapticFeedback.mediumImpact();
    _miniHeight = _miniKey.currentContext?.size?.height ?? _miniHeight;
    _grab = const Offset(
      FloatingPlayerButton.size / 2,
      FloatingPlayerButton.size / 2,
    );
    _floatMoving.value = true;
    _floatPos.value = MiniFloatGeometry.clampTo(
      _geometry.area,
      _toBody(global) - _grab,
    );
    setState(() {
      _miniFloating = true;
      _miniGripping = true;
    });
  }

  void _gripMove(Offset global) => _floatPos.value = MiniFloatGeometry.clampTo(
    _geometry.area,
    _toBody(global) - _grab,
  );

  void _gripEnd() {
    _settleFloat();
    setState(() => _miniGripping = false);
  }

  void _panStart(DragStartDetails d) {
    _grab = d.localPosition;
    _floatMoving.value = true;
  }

  void _panUpdate(DragUpdateDetails d) => _floatPos.value =
      MiniFloatGeometry.clampTo(_geometry.safe, _floatPos.value + d.delta);

  /// 놓으면 가까운 가장자리로 튕기듯 붙는다.
  void _settleFloat() {
    _floatMoving.value = false;
    _floatPos.value = _geometry.snap(_floatPos.value);
  }

  void _restoreMini() {
    HapticFeedback.selectionClick();
    setState(() => _miniFloating = false);
  }

  @override
  void dispose() {
    _dockTimer?.cancel();
    _measureTimer?.cancel();
    _floatPos.dispose();
    _floatMoving.dispose();
    super.dispose();
  }

  /// 받기 줄의 실제 높이 (바깥 크기 변화를 재서 갱신). 줄이 오르내리는 동안 본문 레이아웃이
  /// 매 프레임 바뀌지 않게, 본문의 아래 여백은 이 값으로 한 번만 바꾼다.
  final _barKey = GlobalKey();
  var _barHeight = 0.0;

  Timer? _measureTimer;

  /// 줄 높이가 움직이는 동안(펼침 · 접힘 애니메이션)에는 재지 않고, 멈춘 뒤 한 번만 반영한다.
  /// 프레임마다 본문 여백을 바꾸면 본문 전체가 매번 다시 배치돼 버벅인다.
  bool _measureBar(SizeChangedLayoutNotification _) {
    _measureTimer?.cancel();
    void apply() {
      final h = (_barKey.currentContext?.size?.height) ?? 0.0;
      if (mounted && h != _barHeight) setState(() => _barHeight = h);
    }

    // 처음 나타날 때는 바로 반영하고, 그 뒤 움직이는 동안만 모았다가 반영한다.
    if (_barHeight == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      _measureTimer = Timer(const Duration(milliseconds: 80), apply);
    }
    return true;
  }

  /// 본문(탭 화면) 위에 받기 줄 · 플로팅 버튼을 얹는다. 둘 다 본문 크기를 바꾸지 않고 위에 겹치며,
  /// 목록 맨 아래가 가려지지 않도록 본문의 아래 여백만 그만큼 더해 준다.
  Widget _body(BuildContext context) {
    final mq = MediaQuery.of(context);
    final navHeight = mq.padding.bottom;
    final barShown = !_downloadMinimized;
    // 접는 순간 한 번에 버튼 높이로 바꾼다 (버튼이 나타나는 시점까지 기다리면
    // 접는 애니메이션이 끝날 때 본문이 한 번 더 다시 레이아웃돼 버벅인다).
    final inset = barShown
        ? _barHeight
        : DownloadFloatButton.size + AppSpacing.md * 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 플로팅 버튼이 머물 수 있는 영역: 상태 표시줄 · 하단 바 · 받기 줄(버튼) 위.
        const s = FloatingPlayerButton.size;
        const m = AppSpacing.md;
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        _geometry = MiniFloatGeometry(
          area: Rect.fromLTRB(0, 0, w - s, h - s),
          safe: Rect.fromLTRB(
            m,
            mq.padding.top + m,
            w - s - m,
            h - navHeight - inset - s - m,
          ),
        );
        return _bodyStack(mq, navHeight, inset);
      },
    );
  }

  Widget _bodyStack(MediaQueryData mq, double navHeight, double inset) {
    return Stack(
      key: _bodyKey,
      children: [
        AppBackground(
          child: MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(bottom: navHeight + inset),
            ),
            // 받기 줄 · 버튼이 움직이는 동안 본문을 다시 그리지 않게 따로 그린다.
            child: RepaintBoundary(child: shell),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: navHeight,
          // 높이를 바꾸지 않고 아래로 미끄러져 접히고 위로 올라와 펴진다 (본문이 다시 그려지지 않게).
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: _measureBar,
            child: SizeChangedLayoutNotifier(
              child: RepaintBoundary(
                key: _barKey,
                child: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  switchInCurve: AppMotion.standard,
                  switchOutCurve: AppMotion.standard,
                  // 흐림(유리 블러) 위에 페이드를 얹으면 프레임마다 층을 다시 만들어 버벅이므로 슬라이드만 쓴다.
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                  child: _downloadMinimized
                      ? const SizedBox.shrink(key: ValueKey('download-gone'))
                      : DownloadBar(
                          key: const ValueKey('download-shown'),
                          onMinimize: _minimizeDownloads,
                        ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          // 버튼은 띠가 접힌 뒤 제자리에서 커지며 나타나고(버튼 쪽에서 처리), 펴질 때는 흐려지며 사라진다.
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: _floatShown
                ? DownloadFloatButton(
                    key: const ValueKey('download-float-on'),
                    onRestore: _restoreDownloads,
                  )
                : const SizedBox.shrink(key: ValueKey('download-float-off')),
          ),
        ),
        if (_miniFloating)
          MiniFloatLayer(
            position: _floatPos,
            moving: _floatMoving,
            geometry: _geometry,
            gripping: _miniGripping,
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: (_) => _settleFloat(),
            onExpand: _restoreMini,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    // 내용이 유리 미니 플레이어 · 탭 바 뒤로 흘러가도록 extendBody.
    // 화면은 MediaQuery.paddingOf(context).bottom 만큼 아래 여백을 둔다.
    return SavedCoverSync(
      child: BlocListener<DownloadQueueCubit, DownloadQueueState>(
        // 받을 곡이 모두 사라지면 다음 받기는 받기 줄로 다시 시작한다.
        listenWhen: (a, b) => a.current != null && b.current == null,
        listener: (context, _) {
          _dockTimer?.cancel();
          setState(() {
            _downloadMinimized = false;
            _floatShown = false;
          });
        },
        child: BlocListener<NowPlayingCubit, NowPlayingState>(
          listener: (context, s) =>
              context.read<PlayRecorderCubit>().playbackChanged(
                trackId: s.track?.id,
                position: s.position,
                isPlaying: s.isPlaying,
              ),
          child: BlocListener<NowPlayingCubit, NowPlayingState>(
            // 곡이 바뀌거나 재생을 시작 · 멈출 때 출력 기기를 다시 확인한다.
            listenWhen: (a, b) =>
                a.track?.id != b.track?.id || a.isPlaying != b.isPlaying,
            listener: (context, _) =>
                context.read<AudioOutputCubit>().refresh(),
            child: BlocListener<NowPlayingCubit, NowPlayingState>(
              // 메인 재생이 시작되면 미리 듣기는 멈춘다 (두 소리가 겹치지 않게).
              listenWhen: (a, b) => !a.isPlaying && b.isPlaying,
              listener: (context, _) => context.read<PreviewCubit>().stop(),
              child: BlocListener<PreviewCubit, PreviewState>(
                // 미리 듣기가 재생 중에 막혔으면 까닭을 알린다.
                listenWhen: (a, b) => b.error != null && a.error != b.error,
                listener: (context, s) => ScaffoldMessenger.of(context)
                    .showSnackBar(
                      SnackBar(
                        content: Text(
                          '${l10n.searchPreviewFailed}\n${s.error}',
                        ),
                      ),
                    ),
                child: Scaffold(
                  backgroundColor: p.background,
                  extendBody: true,
                  body: Builder(builder: (context) => _body(context)),
                  bottomNavigationBar: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (context.select((ThemeCubit c) => c.state.previewing))
                        const ThemePreviewBar(),
                      _ShellMiniPlayer(
                        measureKey: _miniKey,
                        floating: _miniFloating,
                        gripping: _miniGripping,
                        placeholderHeight: _miniHeight,
                        onGripStart: _gripStart,
                        onGripMove: _gripMove,
                        onGripEnd: _gripEnd,
                      ),
                      AppBottomNav(
                        currentIndex: shell.currentIndex,
                        onSelected: (i) {
                          shell.goBranch(
                            i,
                            initialLocation: i == shell.currentIndex,
                          );
                        },
                        items: [
                          AppNavItem(
                            icon: AppIcons.libraryOutline,
                            selectedIcon: AppIcons.library,
                            label: l10n.navLibrary,
                          ),
                          AppNavItem(
                            icon: AppIcons.queueOutline,
                            selectedIcon: AppIcons.queue,
                            label: l10n.navPlaylists,
                          ),
                          AppNavItem(
                            icon: AppIcons.homeOutline,
                            selectedIcon: AppIcons.home,
                            label: l10n.navHome,
                            highlighted: true,
                          ),
                          AppNavItem(
                            icon: AppIcons.searchOutline,
                            selectedIcon: AppIcons.search,
                            label: l10n.navSearch,
                          ),
                          AppNavItem(
                            icon: AppIcons.settingsOutline,
                            selectedIcon: AppIcons.settings,
                            label: l10n.navSettings,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 미니 플레이어. 미리 듣는 동안은 미리 듣는 곡이 이 자리를 대신한다
/// (누르면 그 곡의 상세 화면). 재생 대기열과 위치는 건드리지 않아서,
/// 미리 듣기가 끝나면 듣던 대기열이 그대로 돌아온다.
class _ShellMiniPlayer extends StatelessWidget {
  const _ShellMiniPlayer({
    required this.measureKey,
    required this.floating,
    required this.gripping,
    required this.placeholderHeight,
    required this.onGripStart,
    required this.onGripMove,
    required this.onGripEnd,
  });

  final Key measureKey;

  /// 플로팅 버튼으로 바뀐 상태: 띠는 자리를 비운다.
  final bool floating;

  /// 길게 눌러 끌어내는 중: 띠는 보이지 않되 높이는 그대로 둔다
  /// (손가락을 뗄 때까지 제스처가 살아 있고 본문 여백도 흔들리지 않게).
  final bool gripping;
  final double placeholderHeight;
  final ValueChanged<Offset> onGripStart;
  final ValueChanged<Offset> onGripMove;
  final VoidCallback onGripEnd;

  @override
  Widget build(BuildContext context) {
    final preview = context.watch<PreviewCubit>().state;
    if (preview.status != PreviewStatus.idle) {
      return _PreviewMiniPlayer(preview: preview);
    }
    final state = context.watch<NowPlayingCubit>().state;
    final track = state.track;
    if (track == null) return const SizedBox.shrink();
    if (floating && !gripping) return const SizedBox.shrink();
    final vm = context.read<NowPlayingCubit>();
    final l10n = context.l10n;

    // 길게 누른 채 끌면 띠가 플로팅 버튼으로 바뀐다.
    return GestureDetector(
      onLongPressStart: (d) => onGripStart(d.globalPosition),
      onLongPressMoveUpdate: (d) => onGripMove(d.globalPosition),
      onLongPressEnd: (_) => onGripEnd(),
      onLongPressCancel: gripping ? onGripEnd : null,
      child: gripping
          ? SizedBox(height: placeholderHeight, width: double.infinity)
          : KeyedSubtree(
              key: measureKey,
              // 위치가 바뀔 때마다 띠만 다시 그리고 아래 화면까지 번지지 않게 한다.
              child: RepaintBoundary(
                child: ValueListenableBuilder<bool>(
                  valueListenable: mainStreamVideoOn,
                  builder: (context, _, _) => _bar(context, state, track, vm, l10n),
                ),
              ),
            ),
    );
  }

  Widget _bar(
    BuildContext context,
    NowPlayingState state,
    Track track,
    NowPlayingCubit vm,
    AppLocalizations l10n,
  ) {
    return Hero(
      tag: 'now-playing',
      child: MiniPlayerBar(
        title: track.title,
        artist: track.artist,
        artwork: coverImageOf(context, CoverKey.track(track.id)),
        // 영상 곡이거나 스트림 영상이 켜져 있으면 미니 플레이어도 영상을 보여 준다 (곡을 따로 맞추지 않는다).
        video: track.isVideo || mainStreamVideoOn.value
            ? const NativeVideo()
            : null,
        progress: state.progress,
        isPlaying: state.isPlaying,
        playLabel: l10n.actionPlay,
        pauseLabel: l10n.actionPause,
        previousLabel: l10n.actionPrevious,
        nextLabel: l10n.actionNext,
        positionText: formatDuration(state.position),
        durationText: formatDuration(track.duration),
        queueLabel: l10n.playerQueue,
        // 수면 타이머가 켜져 있으면 남은 시간을 작게 보인다.
        note: state.sleepEndsAt == null
            ? null
            : SleepRemainingBadge(endsAt: state.sleepEndsAt),
        onTap: () {
          // 임시 저장한 음원은 재생 화면 대신 저장 타일의 상세 화면(하단 조작부)을 연다.
          final id = savedVideoIdOf(track.id);
          final saved = id == null
              ? const <SavedVideo>[]
              : context.read<SavedVideosCubit>().state.where((v) => v.id == id);
          if (saved.isNotEmpty) {
            unawaited(showSavedQueueDetail(context, saved.first.hit));
          } else {
            unawaited(context.push(Routes.player));
          }
        },
        onPlayPause: vm.togglePlay,
        onPrevious: vm.previous,
        onNext: vm.next,
        onQueue: () => context.push(Routes.queue),
      ),
    );
  }
}

class _PreviewMiniPlayer extends StatelessWidget {
  const _PreviewMiniPlayer({required this.preview});

  final PreviewState preview;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PreviewCubit>();
    final l10n = context.l10n;
    final hit = preview.hit;
    final loading = preview.status == PreviewStatus.loading;
    final duration = preview.progress?.duration;
    final thumb = hit?.thumbnailUrl;
    return MiniPlayerBar(
      key: const ValueKey('preview-mini-player'),
      title: preview.title,
      artist: loading
          ? l10n.searchPreviewLoading
          : [
              l10n.searchPreview,
              if (hit?.uploader case final u? when u.isNotEmpty) u,
            ].join(' · '),
      artwork: thumb == null ? null : CachedWebImage(thumb),
      // 영상이 있는 유튜브만 영상 자리를 넓게 둔다 (음원은 작은 커버만).
      // 소리만 저장한 곡은 영상 자리 없이 일반 음원 미니 플레이어처럼 보인다 (영상은 상세 화면에서만).
      video:
          hit == null ||
              !isYoutubeUrl(hit.url) ||
              loading ||
              context.read<SavedVideosCubit>().isAudioOnly(hit.id)
          ? null
          : PreviewVideo(
              pageUrl: hit.url,
              quality: context.read<SavedVideosCubit>().qualityOf(hit.id),
            ),
      progress: preview.fraction,
      isPlaying: !preview.paused,
      playLabel: l10n.searchPreviewResume,
      pauseLabel: l10n.searchPreviewPause,
      previousLabel: l10n.actionPrevious,
      nextLabel: l10n.actionNext,
      positionText: formatDuration(preview.progress?.position ?? Duration.zero),
      durationText: duration == null ? '--:--' : formatDuration(duration),
      queueLabel: l10n.searchPreviewStop,
      showSkip: false,
      onPrevious: () {},
      onNext: () {},
      queueIcon: AppIcons.close,
      onTap: hit == null || hit.url.isEmpty
          ? null
          : () => showMediaDetail(context, hit),
      onPlayPause: loading ? null : cubit.togglePause,
      onQueue: cubit.stop,
    );
  }
}
