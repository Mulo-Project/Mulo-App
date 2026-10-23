import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import 'player_common.dart';

/// 플레이어 모양 3가지 (카드 · 상자 없이 배경 위에 바로 놓는다).
/// 위쪽(커버 · 진행 표시)만 다르고, 하단 조작부는 모두 [PlayerControls] 하나를 쓴다.

const _side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

/// 가사 보기일 때 커버 자리를 채우는 가사.
Widget _lyrics(PlayerLayoutData data) => Padding(
  padding: _side,
  child: PlayerLyricsPane(track: data.track),
);

/// 가사 보기일 때 바탕 전체를 배경색으로 덮는 막 (커버 · 그라데이션이 가장자리에 비치지 않게).
Widget _lyricsVeil(BuildContext context, bool show) => Positioned.fill(
  child: IgnorePointer(
    child: AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: AppMotion.slow,
      child: ColoredBox(color: context.palette.background),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          _lyricsVeil(context, data.showLyrics),
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
                            child: AspectRatio(
                              aspectRatio: 1,
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
                                  child: PlayerCover(art: art),
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
                  PlayerCover(art: art, radius: 0),
                  // 위: 상단 버튼이 읽히게 살짝 어둡게, 아래: 배경으로 부드럽게.
                  DecoratedBox(
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
                ],
              ),
            ),
            _lyricsVeil(context, data.showLyrics),
            SafeArea(
              child: Column(
                children: [
                  PlayerTopBar(track: data.track),
                  Expanded(
                    child: data.showLyrics
                        ? _lyrics(data)
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

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    return PlayerBackdrop(
      art: art,
      blurred: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _lyricsVeil(context, data.showLyrics),
          SafeArea(
            child: Column(
              children: [
                PlayerTopBar(track: data.track),
                Expanded(
                  child: MorphSeek(
                    progress: data.state.progress,
                    onSeek: data.vm.seekFraction,
                    onSeekStart: data.vm.beginScrub,
                    onSeekEnd: data.vm.endScrub,
                    straight: data.showLyrics,
                    pathOf: _path,
                    track: p.onSurface.withValues(alpha: .2),
                    fill: p.onSurface,
                    position: data.state.position,
                    total: data.track.duration,
                    timeAt: (s, _) => Offset(
                      s.width / 2,
                      s.height / 2 + (_size(s) / 2 - _knob - 1),
                    ),
                    cover: (s, _) => Center(
                      child: SizedBox.square(
                        dimension: _size(s),
                        child: Padding(
                          padding: EdgeInsets.all(_size(s) * .09),
                          child: PlayerCover(art: art, radius: _size(s)),
                        ),
                      ),
                    ),
                    lyrics: _lyrics(data),
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
