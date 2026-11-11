import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../bloc/video_surface_cubit.dart';
import 'fullscreen_video.dart';
import 'player_common.dart';

/// 플레이어 모양 3가지 (카드 · 상자 없이 배경 위에 바로 놓는다).
/// 위쪽(커버 · 진행 표시)만 다르고, 하단 조작부는 모두 [PlayerControls] 하나를 쓴다.

const _side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

/// 지금 영상의 가로 / 세로 비율. 아직 크기를 모르면 16:9.
double _videoAspect(BuildContext context) {
  final s = context.watch<VideoSurfaceCubit>().state;
  return s.width > 0 && s.height > 0 ? s.width / s.height : 16 / 9;
}

/// 가사 보기일 때 커버 자리를 채우는 가사.
Widget _lyrics(PlayerLayoutData data) => Padding(
  padding: _side,
  child: PlayerLyricsPane(track: data.track),
);

/// 가사 보기일 때 바탕 전체를 배경색으로 덮는 막 (커버 · 그라데이션이 가장자리에 비치지 않게).
/// 영상 곡은 가사 뒤로 영상이 비쳐 움직이게 얇게 덮는다 (영상이 아니면 배경색으로 꽉 덮는다).
Widget _lyricsVeil(BuildContext context, bool show, {bool video = false}) =>
    Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: AppMotion.slow,
          child: ColoredBox(
            color: context.palette.background.withValues(
              alpha: video ? .6 : 1,
            ),
          ),
        ),
      ),
    );

/// 네모: 큰 정사각 커버, 아래 진행 막대.
class SquarePlayer extends StatelessWidget {
  const SquarePlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    return PlayerBackdrop(
      art: art,
      // 영상 곡은 사각 커버 뒤에도 흐린 영상이 움직인다.
      blurred: data.track.isVideo,
      video: data.track.isVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _lyricsVeil(context, data.showLyrics, video: data.track.isVideo),
          SafeArea(
            child: Column(
              children: [
                PlayerTopBar(track: data.track),
                Expanded(
                  child: data.showLyrics
                      ? _lyrics(data)
                      : Padding(
                          padding: _side,
                          child: Center(
                            // 영상 곡은 영상 비율 그대로 (잘리지 않게), 음원은 정사각형.
                            child: AspectRatio(
                              aspectRatio: data.track.isVideo
                                  ? _videoAspect(context)
                                  : 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.lg,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.scrim.withValues(alpha: .35),
                                      blurRadius: 40,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Hero(
                                  tag: 'now-playing',
                                  child: PlayerCover(
                                    art: art,
                                    video: data.track.isVideo
                                        ? const NativeVideoWithFullscreen()
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                PlayerControls(
                  data: data,
                  play: SolidPlayButton(data: data, size: 72),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 꽉 찬 이미지: 커버가 위쪽을 채우고 배경으로 스며든다.
class FullBleedPlayer extends StatelessWidget {
  const FullBleedPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: c.maxHeight * .66,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 영상 곡: 윗부분은 색을 입힌 흐린 커버 배경이고, 영상은 아래 칸(상단 버튼줄 밑)에 맞춰 그린다.
                  PlayerCover(
                    art: art,
                    radius: 0,
                    softBackdrop: data.track.isVideo,
                  ),
                  // 위: 상단 버튼이 읽히게 살짝 어둡게, 아래: 배경으로 부드럽게. 누름은 아래로 통과시킨다.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            p.scrim.withValues(alpha: .35),
                            p.scrim.withValues(alpha: 0),
                            p.background.withValues(alpha: 0),
                            p.background.withValues(alpha: .45),
                            p.background.withValues(alpha: .85),
                            p.background,
                          ],
                          stops: const [0, .22, .45, .7, .88, 1],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _lyricsVeil(context, data.showLyrics, video: data.track.isVideo),
            SafeArea(
              child: Column(
                children: [
                  PlayerTopBar(track: data.track),
                  Expanded(
                    child: data.showLyrics
                        ? _lyrics(data)
                        : data.track.isVideo
                        // 영상 곡: 상단 버튼줄 밑부터 조작부 위까지 영상 전체가 딱 맞게 (잘리지 않게).
                        ? const NativeVideoWithFullscreen(fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  PlayerControls(
                    data: data,
                    play: SolidPlayButton(data: data, size: 72),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 호의 하단: 진행 막대는 커버 쪽에 있고, 조작부는 [PlayerControls] 하나.
Widget _imageSeekControls(PlayerLayoutData data, Widget play) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const SizedBox(height: AppSpacing.sm),
    PlayerControls(data: data, play: play, seekBar: false),
    const SizedBox(height: AppSpacing.xs),
  ],
);

/// 호: 흐린 커버 배경, 커버를 감싸는 곡선 진행 막대.
/// 가사 보기로 바꾸면 곡선이 곧은 막대로 펴진다.
class ArcPlayer extends StatelessWidget {
  const ArcPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  /// 아래쪽이 열린 정도 (라디안).
  static const _gap = math.pi * 4 / 9;
  static const _sweep = 2 * math.pi - _gap;
  static const _start = math.pi / 2 + _gap / 2;
  static const _knob = 8.0;

  static double _size(Size s) =>
      math.min(s.width - AppSpacing.lg * 2, s.height);

  static Path _path(Size s, double extend) {
    final radius = _size(s) / 2 - _knob - 1;
    return Path()..addArc(
      Rect.fromCircle(center: s.center(Offset.zero), radius: radius),
      _start,
      _sweep,
    );
  }

  /// 영상 곡: 진행 선과 영상 사이 간격.
  static const _frameInset = AppSpacing.sm;

  /// 영상 곡: 영상 틀 둘레(진행 선이 도는 길)의 크기. 영상 [aspect]에 맞추고 영역 안에 들어가게 한다.
  static Size _frameSize(Size s, double aspect) {
    const edge = _knob + 1;
    const inset = _frameInset;
    final maxW = s.width - AppSpacing.sm * 2 - edge * 2;
    final maxH = s.height - 48 - edge * 2;
    final w = math.min(maxW - inset * 2, (maxH - inset * 2) * aspect);
    return Size(w + inset * 2, w / aspect + inset * 2);
  }

  /// 영상 곡: 영상 틀을 따라 도는 둥근 사각형 길. 호처럼 아래 가운데가 열려 있다 (시간이 놓이는 자리).
  static Path _framePath(Size s, double aspect) {
    final f = _frameSize(s, aspect);
    final r = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: f.width,
      height: f.height,
    );
    final c = math.min(24.0, math.min(f.width, f.height) / 2);
    // 아래 가운데 열린 자리: 현재 · 전체 시간이 양옆(가운데에서 76 ~ 112)에 놓이므로 그만큼 열어 둔다.
    final g = math.min(124.0, f.width / 2 - c - 8);
    final cx = r.center.dx;
    const q = math.pi / 2;
    return Path()
      ..moveTo(cx - g, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..arcTo(Rect.fromLTWH(r.left, r.bottom - 2 * c, 2 * c, 2 * c), q, q, false)
      ..lineTo(r.left, r.top + c)
      ..arcTo(Rect.fromLTWH(r.left, r.top, 2 * c, 2 * c), math.pi, q, false)
      ..lineTo(r.right - c, r.top)
      ..arcTo(Rect.fromLTWH(r.right - 2 * c, r.top, 2 * c, 2 * c), -q, q, false)
      ..lineTo(r.right, r.bottom - c)
      ..arcTo(
        Rect.fromLTWH(r.right - 2 * c, r.bottom - 2 * c, 2 * c, 2 * c),
        0,
        q,
        false,
      )
      ..lineTo(cx + g, r.bottom);
  }

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    final video = data.track.isVideo;
    // 영상 곡은 원 대신 영상 틀(영상 비율)을 따라 진행 선이 돈다.
    final aspect = video ? _videoAspect(context) : 1.0;
    return PlayerBackdrop(
      art: art,
      blurred: true,
      video: data.track.isVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _lyricsVeil(context, data.showLyrics, video: data.track.isVideo),
          SafeArea(
            child: Column(
              children: [
                PlayerTopBar(track: data.track),
                Expanded(
                  child: PositionBuilder(
                    builder: (context, state) => MorphSeek(
                      progress: state.progress,
                      onSeek: data.vm.seekFraction,
                      onSeekStart: data.vm.beginScrub,
                      onSeekEnd: data.vm.endScrub,
                      straight: data.showLyrics,
                      pathOf: video
                          ? (s, _) => _framePath(s, aspect)
                          : _path,
                      track: p.onSurface.withValues(alpha: .2),
                      fill: p.onSurface,
                      position: state.position,
                      total: data.track.duration,
                      timeAt: (s, _) => Offset(
                        s.width / 2,
                        video
                            ? s.height / 2 + _frameSize(s, aspect).height / 2
                            : s.height / 2 + (_size(s) / 2 - _knob - 1),
                      ),
                      cover: (s, _) => video
                          ? Center(
                              child: SizedBox.fromSize(
                                size: _frameSize(s, aspect),
                                child: Padding(
                                  padding: const EdgeInsets.all(_frameInset),
                                  child: PlayerCover(
                                    art: art,
                                    radius: AppRadii.lg,
                                    video: const NativeVideoTapFullscreen(
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                        child: SizedBox.square(
                          dimension: _size(s),
                          child: Padding(
                            padding: EdgeInsets.all(_size(s) * .09),
                            child: PlayerCover(
                              art: art,
                              radius: _size(s),
                            ),
                          ),
                        ),
                      ),
                      lyrics: _lyrics(data),
                    ),
                  ),
                ),
                _imageSeekControls(data, SolidPlayButton(data: data, size: 72)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 플레이어 커버 자리의 영상 + 오른쪽 아래 전체 화면 버튼.
