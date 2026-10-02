import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'player_common.dart';

/// 플레이어 모양 4가지 (카드 · 상자 없이 배경 위에 바로 놓는다).
/// 위쪽(커버 · 진행 표시)만 다르고, 하단 조작부는 모두 [PlayerControls] 하나를 쓴다.

const _side = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

/// 가사 보기일 때 커버 자리를 채우는 가사.
Widget _lyrics(PlayerLayoutData data) => Padding(
  padding: _side,
  child: PlayerLyricsPane(track: data.track),
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
      child: SafeArea(
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
                              borderRadius: BorderRadius.circular(AppRadii.lg),
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
            const SizedBox(height: AppSpacing.sm),
            PlayerControls(
              data: data,
              play: SolidPlayButton(data: data, size: 72),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
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
            SafeArea(
              child: Column(
                children: [
                  PlayerTopBar(track: data.track),
                  Expanded(
                    child: data.showLyrics
                        ? Padding(
                            padding: _side,
                            child: ColoredBox(
                              color: p.background.withValues(alpha: .86),
                              child: PlayerLyricsPane(track: data.track),
                            ),
                          )
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

/// 호 · 커스텀이 같이 쓰는 하단: 진행 막대는 커버 쪽에 있고, 조작부는 [PlayerControls] 하나.
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
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track),
            Expanded(
              child: MorphSeek(
                progress: data.state.progress,
                onSeek: data.vm.seekFraction,
                straight: data.showLyrics,
                pathOf: _path,
                track: p.onSurface.withValues(alpha: .2),
                fill: p.onSurface,
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
            _imageSeekControls(data, GlowPlayButton(data: data, size: 72)),
          ],
        ),
      ),
    );
  }
}

/// 커스텀: 소프트(뉴모피즘) 화면. 키 큰 둥근 틀 안에 커버, 진행 막대가 틀을 따라 돈다.
/// 틀의 선은 화면 맨 위까지 이어지고, 가사 보기로 바꾸면 곧은 막대로 펴진다.
class CustomPlayer extends StatelessWidget {
  const CustomPlayer({super.key, required this.data});

  final PlayerLayoutData data;

  /// 틀 선이 커버 가장자리에서 안쪽으로 들어간 거리.
  static const _inset = 12.0;
  static const _shadowRoom = 6.0;

  /// 커버 몸통 사각형 (늘린 영역 아래쪽에 놓는다).
  static Rect _body(Size s, double extend) {
    final w = math.min(s.width * .78, (s.height - extend) / 1.2);
    final bottom = s.height - _shadowRoom;
    return Rect.fromLTWH((s.width - w) / 2, bottom - w * 1.2, w, w * 1.2);
  }

  /// U자 틀 윤곽: 화면 맨 위에서 내려와 바닥을 돌아 다시 맨 위로 오른다.
  static Path _path(Size s, double extend) {
    final b = _body(s, extend);
    final r = b.width / 2 - _inset;
    final cx = b.center.dx;
    final bottom = b.bottom - _inset;
    final lower = Rect.fromCircle(center: Offset(cx, bottom - r), radius: r);
    return Path()
      ..moveTo(cx - r, 0)
      ..lineTo(cx - r, bottom - r)
      ..arcTo(lower, math.pi, -math.pi, false)
      ..lineTo(cx + r, 0);
  }

  @override
  Widget build(BuildContext context) {
    final art = PlayerArt.of(context, data.track);
    final p = context.palette;
    final l10n = context.l10n;
    return ColoredBox(
      color: p.surface,
      child: SafeArea(
        child: Column(
          children: [
            PlayerTopBar(track: data.track),
            Expanded(
              child: MorphSeek(
                progress: data.state.progress,
                onSeek: data.vm.seekFraction,
                straight: data.showLyrics,
                reachTop: true,
                pathOf: _path,
                track: p.onSurface.withValues(alpha: .12),
                fill: p.primary,
                knobRing: p.surface,
                cover: (s, extend) {
                  final b = _body(s, extend);
                  final pad = _inset + 12;
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: b,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(b.width / 2),
                            ),
                            color: p.surface,
                            boxShadow: neuShadows(context, depth: 10),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(b.width / 2 - pad),
                              ),
                              child: PlayerCover(art: art, radius: 0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                lyrics: _lyrics(data),
              ),
            ),
            _imageSeekControls(
              data,
              NeuCircle(
                size: 72,
                child: SizedBox.square(
                  dimension: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.primary,
                    ),
                    child: IconButton(
                      tooltip: data.state.isPlaying
                          ? l10n.actionPause
                          : l10n.actionPlay,
                      onPressed: data.vm.togglePlay,
                      icon: Icon(
                        data.state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 32,
                        color: p.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
