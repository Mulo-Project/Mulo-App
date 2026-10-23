import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../bloc/lyrics_cubit.dart';
import '../bloc/lyrics_overlay_cubit.dart';
import '../bloc/lyrics_settings_cubit.dart';
import 'lyrics_editor.dart';
import 'lyrics_sync_start.dart';

/// 전체 화면 플레이어의 가사 보기. 싱크 가사는 재생 위치의 줄을 강조하고 따라 내려가며,
/// 줄을 누르면 그 위치로 옮긴다. 일반 글 가사는 그대로 보여 준다.
class LyricsView extends StatefulWidget {
  const LyricsView({
    super.key,
    required this.track,
    this.followTop = AppSizes.circleButton * .8 + AppSpacing.xs,
  });

  final Track track;

  /// 싱크 추적 버튼의 위쪽 간격 (위에 다른 버튼이 있으면 그 아래로 비킨다).
  final double followTop;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  var _keys = <GlobalKey>[];
  Lyrics? _keysFor;
  int _shown = -2;

  /// 재생 위치의 줄을 따라 목록이 움직이는가. 끄면 가사를 방해 없이 자유롭게 볼 수 있다.
  var _following = true;

  /// 처음 현재 줄로 자리를 잡았는가. 잡기 전에는 가사를 투명하게 두어 위치가 튀어 보이지 않게 한다.
  var _placed = false;

  late final LyricsOverlayCubit _overlay = context.read<LyricsOverlayCubit>();

  @override
  void initState() {
    super.initState();
    context.read<LyricsCubit>().show(widget.track);
    // 이 가사 보기가 떠 있는 동안은 떠 있는 가사 창이 겹치지 않게 숨긴다.
    _overlay.setLyricsViewShown(true);
  }

  @override
  void dispose() {
    _overlay.setLyricsViewShown(false);
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (old.track.id != widget.track.id) {
      context.read<LyricsCubit>().show(widget.track);
    }
  }

  void _follow(int index) {
    if (index == _shown) return;
    _shown = index;
    if (index < 0 || !_following) {
      // 따라갈 줄이 없으면 바로 보여 준다.
      _settle();
      return;
    }
    // 처음 열 때는 애니메이션 없이 현재 줄로 바로 가고, 자리를 잡은 뒤에야 보여 준다 (중앙에 잠깐 비쳤다가 튀지 않게).
    final first = !_placed;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = index < _keys.length ? _keys[index].currentContext : null;
      if (ctx == null || !ctx.mounted) {
        _settle();
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        alignment: .5,
        duration: first ? Duration.zero : AppMotion.medium,
        curve: AppMotion.standard,
      );
      _settle();
    });
  }

  /// 처음 자리를 잡았음을 알린다 (그 전에는 가사를 투명하게 둔다).
  void _settle() {
    if (_placed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_placed) setState(() => _placed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasLyrics =
        context.watch<LyricsCubit>().state.trackId == widget.track.id &&
        context.watch<LyricsCubit>().state.lyrics != null;
    final synced =
        hasLyrics && context.watch<LyricsCubit>().state.lyrics!.isSynced;
    final theme = context.select<LyricsSettingsCubit, LyricsTheme>(
      (c) => c.state.theme,
    );
    final column = Column(
      children: [
        Expanded(child: _body(context)),
        if (hasLyrics)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlainButton(
                  label: l10n.lyricsSyncSetting,
                  icon: AppIcons.timer,
                  onPressed: () => startLyricsSync(context, widget.track),
                ),
                PlainButton(
                  label: l10n.lyricsMenuEdit,
                  icon: AppIcons.edit,
                  onPressed: () => showLyricsEditor(context, widget.track),
                ),
              ],
            ),
          ),
      ],
    );
    // 싱크 추적: 켜면 재생 위치의 줄을 따라 가사가 올라가고, 끄면 방해 없이 자유롭게 볼 수 있다.
    // 가사 위 오른쪽의 동그란 버튼 (켜면 강조색). 위에 "가사만 크게 보기" 버튼이 놓인다.
    if (!synced || theme == LyricsTheme.centered) return column;
    return Stack(
      children: [
        column,
        Positioned(
          top: widget.followTop,
          right: 0,
          child: CircleIconButton(
            icon: AppIcons.explore,
            tooltip: l10n.lyricsSyncFollowHint,
            emphasized: _following,
            size: AppSizes.circleButton * .8,
            onPressed: () => setState(() {
              _following = !_following;
              // 다시 켜면 지금 줄로 한 번 따라가도록 한다.
              if (_following) _shown = -2;
            }),
          ),
        ),
      ],
    );
  }

  /// 커버 배경: 커버를 옅게 흐려 가사 뒤에 깐다 (한 번만 흐리고, 줄마다 필터를 쓰지 않는다).
  /// 커버 이미지가 없으면 곡 색 그라데이션을 깐다. 테마(목록 · 가운데 한 줄)와 따로 켜고 끈다.
  Widget _body(BuildContext context) {
    final content = _content(context);
    final on = context.select<LyricsSettingsCubit, bool>(
      (c) => c.state.coverBackground,
    );
    if (!on) return content;
    final p = context.palette;
    final key = CoverKey.track(widget.track.id);
    final image = coverImageOf(context, key);
    final color = coverColorOf(context, key);
    final glow = color != null
        ? glowFromColor(color)
        : context.tokens.glow(toneFor(widget.track.id));
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            // 커버는 거의 손대지 않고 선명하게 둔다. 현재 강조된 줄만 글자 모양대로 번지는 그림자(_halo)로 받친다.
            Image(image: ResizeImage(image, width: 480), fit: BoxFit.cover)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    glow[1].withValues(alpha: .7),
                    glow[2].withValues(alpha: .4),
                  ],
                ),
              ),
            ),
          // 글자 대비를 위해 어둡게 덮는다.
          ColoredBox(color: p.background.withValues(alpha: .1)),
          content,
        ],
      ),
    );
  }

  /// 커버 배경이 켜져 있으면 현재 강조된 줄 주위에만 배경색 번짐을 깔아 글자가 묻히지 않게 한다.
  List<Shadow>? _halo(AppPalette p) {
    if (!context.read<LyricsSettingsCubit>().state.coverBackground) return null;
    return [
      Shadow(color: p.background.withValues(alpha: .9), blurRadius: 12),
      Shadow(color: p.background.withValues(alpha: .8), blurRadius: 6),
      Shadow(color: p.background.withValues(alpha: .6), blurRadius: 3),
    ];
  }

  /// 강조된 줄이 놓인 가로 띠만 뒤를 흐리게 한다 (필터는 이 띠 하나에만 건다).
  Widget _band(bool on, Widget child) => on
      ? ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: child,
          ),
        )
      : child;

  /// 목록 테마의 줄들. 같은 시간으로 묶인 줄은 간격을 좁혀 한 덩어리로 놓고,
  /// 지금 재생 중인 덩어리 뒤에는 옅은 강조 바탕을 깐다.
  List<Widget> _listLines(
    Lyrics lyrics,
    (int, int) group,
    bool coverOn,
    NowPlayingCubit vm,
    TextTheme text,
    AppPalette p,
  ) {
    Widget line(int i, bool active, bool tight) => InkWell(
      key: _keys[i],
      borderRadius: BorderRadius.circular(AppRadii.sm),
      onTap: () => vm.seekTo(lyrics.lines[i].time),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: tight ? 0 : AppSpacing.xs,
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.fast,
          textAlign: TextAlign.center,
          style: (active ? text.titleLarge : text.bodyLarge)!.copyWith(
            color: active ? p.accent : p.onSurfaceMuted,
            shadows: active ? _halo(p) : null,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              lyrics.lines[i].text.isEmpty ? '♪' : lyrics.lines[i].text,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    final out = <Widget>[];
    var i = 0;
    while (i < lyrics.lines.length) {
      final (first, last) = lyrics.groupAt(i);
      final active = first == group.$1 && last == group.$2;
      if (first == last) {
        // 홑줄도 지금 줄이면 묶음과 같은 옅은 바탕을 깐다.
        final single = active
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: line(i, true, false),
                ),
              )
            : line(i, false, false);
        out.add(_band(coverOn && active, single));
      } else {
        // 묶인 덩어리: 줄 간격을 좁히고, 지금 덩어리면 옅은 바탕을 깐다.
        final box = Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active ? p.accent.withValues(alpha: .1) : null,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var k = first; k <= last; k++) line(k, active, true),
                ],
              ),
            ),
          ),
        );
        out.add(_band(coverOn && active, box));
      }
      i = last + 1;
    }
    return out;
  }

  Widget _content(BuildContext context) {
    final coverOn = context.select<LyricsSettingsCubit, bool>(
      (c) => c.state.coverBackground,
    );
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final state = context.watch<LyricsCubit>().state;
    final lyrics = state.trackId == widget.track.id ? state.lyrics : null;

    if (state.loading && lyrics == null) {
      return const SizedBox.shrink();
    }
    if (lyrics == null) {
      return EmptyState(
        title: l10n.lyricsEmpty,
        body: l10n.lyricsEmptyHint,
        action: PlainButton(
          label: l10n.lyricsMenuEdit,
          icon: AppIcons.edit,
          onPressed: () => showLyricsEditor(context, widget.track),
        ),
      );
    }

    if (!lyrics.isSynced) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          lyrics.plain,
          style: text.bodyLarge?.copyWith(height: 1.7, shadows: _halo(p)),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!identical(_keysFor, lyrics)) {
      _keysFor = lyrics;
      _keys = List.generate(lyrics.lines.length, (_) => GlobalKey());
      _shown = -2;
      _placed = false;
    }
    // 재생 위치(0.25초마다 바뀜) 대신 "지금 줄 번호"만 구독한다: 줄이 바뀔 때만 다시 그린다.
    final current = context.select<NowPlayingCubit, int>(
      (c) => lyrics.currentLine(c.state.position),
    );
    // 같은 시간으로 묶인 줄은 한 덩어리로 함께 강조하고, 덩어리 가운데 줄로 따라간다.
    final group = lyrics.groupAt(current);
    final vm = context.read<NowPlayingCubit>();
    if (context.select<LyricsSettingsCubit, LyricsTheme>(
          (c) => c.state.theme,
        ) ==
        LyricsTheme.centered) {
      return _centered(lyrics, group, vm);
    }
    _follow(current < 0 ? current : (group.$1 + group.$2) >> 1);

    return Opacity(
      opacity: _placed ? 1 : 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          children: [
            ..._listLines(lyrics, group, coverOn, vm, text, p),
            // 도중에 저장해 아직 싱크가 없는 뒷부분도 가사는 모두 보여 준다 (강조 · 이동은 싱크된 줄까지만).
            for (final line in lyrics.pending)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(
                      color: p.onSurfaceMuted.withValues(alpha: .6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 가운데 한 줄 테마의 세로 위치: 줄마다 쌓이는 높이. 같은 시간으로 묶인 줄은 간격을 좁힌다.
  static List<double> _stack(Lyrics lyrics, double slot, double tight) {
    final v = <double>[];
    for (var i = 0; i < lyrics.lines.length; i++) {
      if (i == 0) {
        v.add(0);
      } else {
        final same = lyrics.lines[i].time == lyrics.lines[i - 1].time;
        v.add(v[i - 1] + (same ? tight : slot));
      }
    }
    return v;
  }

  /// 줄 번호가 소수인 위치 [x]의 세로 위치 (줄 사이는 이어서 계산).
  static double _stackAt(List<double> v, double x, double slot) {
    if (v.isEmpty) return x * slot;
    if (x <= 0) return v.first + x * slot;
    if (x >= v.length - 1) return v.last + (x - (v.length - 1)) * slot;
    final i = x.floor();
    final f = x - i;
    return v[i] * (1 - f) + v[i + 1] * f;
  }

  /// 가운데 한 줄 테마: 현재 줄을 가운데에 크게 두고 앞뒤 몇 줄만 흐리게 보인다. 줄이 바뀌면 부드럽게 미끄러진다.
  /// 같은 시간으로 묶인 줄은 간격을 좁혀 함께 가운데에 놓고, 지금 줄(덩어리) 뒤에는 옅은 바탕을 깐다.
  Widget _centered(Lyrics lyrics, (int, int) group, NowPlayingCubit vm) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    const slot = 64.0;
    const tight = 32.0;
    const reach = 3;
    final v = _stack(lyrics, slot, tight);
    final center = (group.$1 + group.$2) / 2;
    // 지금 덩어리의 세로 길이 (홑줄이면 0).
    final span = group.$1 < 0 || group.$2 >= v.length
        ? 0.0
        : v[group.$2] - v[group.$1];
    final coverOn = context.read<LyricsSettingsCubit>().state.coverBackground;
    return LayoutBuilder(
      builder: (context, box) => TweenAnimationBuilder<double>(
        tween: Tween(end: center),
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        builder: (context, pos, _) {
          final at = _stackAt(v, pos, slot);
          final mid = box.maxHeight / 2;
          final shown = <int>[
            for (var i = 0; i < lyrics.lines.length; i++)
              if (((v[i] - at).abs() - span / 2) <= (reach + .5) * slot) i,
          ];
          final bandHeight = slot + span;
          final band = Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: mid - bandHeight / 2,
            height: bandHeight,
            // 줄이 미끄러지는 동안 흐림 띠가 매 프레임 다시 그려지지 않게 따로 그린다.
            child: RepaintBoundary(
              child: _band(
                coverOn,
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (group.$1 >= 0) band,
              for (final i in shown)
                () {
                  final inGroup = i >= group.$1 && i <= group.$2;
                  final grouped = lyrics.groupAt(i).$1 != lyrics.groupAt(i).$2;
                  final h = grouped ? tight : slot;
                  return Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: mid - h / 2 + (v[i] - at),
                    height: h,
                    child: _centeredLine(
                      lyrics.lines[i],
                      inGroup
                          ? 0.0
                          : (((v[i] - at).abs() - span / 2) / slot).clamp(
                              0.0,
                              double.infinity,
                            ),
                      text,
                      p,
                      vm,
                      oneLine: grouped,
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    );
  }

  /// [distance]는 현재 줄(0)에서 떨어진 줄 수 (움직이는 동안은 소수).
  Widget _centeredLine(
    LyricLine line,
    double distance,
    TextTheme text,
    AppPalette p,
    NowPlayingCubit vm, {
    bool oneLine = false,
  }) {
    final near = (1 - distance).clamp(0.0, 1.0);
    final opacity = distance < 1
        ? 1 - distance * .55
        : (.45 - (distance - 1) * .17).clamp(0.0, .45);
    return Opacity(
      opacity: opacity,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: () => vm.seekTo(line.time),
        child: Center(
          child: Transform.scale(
            scale: .78 + .22 * near,
            child: Text(
              line.text.isEmpty ? '♪' : line.text,
              textAlign: TextAlign.center,
              maxLines: oneLine ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge!.copyWith(
                color: Color.lerp(p.onSurfaceMuted, p.accent, near),
                shadows: near > .5 ? _halo(p) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
