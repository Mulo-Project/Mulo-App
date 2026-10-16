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
import '../bloc/lyrics_settings_cubit.dart';
import 'lyrics_editor.dart';
import 'lyrics_theme_sheet.dart';
import 'lyrics_sync_start.dart';

/// 전체 화면 플레이어의 가사 보기. 싱크 가사는 재생 위치의 줄을 강조하고 따라 내려가며,
/// 줄을 누르면 그 위치로 옮긴다. 일반 글 가사는 그대로 보여 준다.
class LyricsView extends StatefulWidget {
  const LyricsView({super.key, required this.track});

  final Track track;

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

  @override
  void initState() {
    super.initState();
    context.read<LyricsCubit>().show(widget.track);
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
        alignment: .4,
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
    return Column(
      children: [
        Expanded(child: _body(context)),
        // 싱크 추적: 켜면 재생 위치의 줄을 따라 가사가 올라가고, 끄면 방해 없이 자유롭게 볼 수 있다.
        // 싱크 설정 · 가사 편집 버튼과는 다른 줄에 둔다.
        if (synced && theme != LyricsTheme.centered)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlainButton(
                  icon: AppIcons.explore,
                  label: l10n.lyricsFollow,
                  tooltip: l10n.lyricsSyncFollowHint,
                  accent: _following,
                  onPressed: () => setState(() {
                    _following = !_following;
                    // 다시 켜면 지금 줄로 한 번 따라가도록 한다.
                    if (_following) _shown = -2;
                  }),
                ),
              ],
            ),
          ),
        if (hasLyrics)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlainButton(
                  label: l10n.lyricsThemeTitle,
                  icon: AppIcons.style,
                  onPressed: () => showLyricsThemeSheet(context),
                ),
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
            Opacity(
              opacity: .6,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image(
                  image: ResizeImage(image, width: 240),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    glow[1].withValues(alpha: .5),
                    glow[2].withValues(alpha: .25),
                  ],
                ),
              ),
            ),
          // 글자 대비를 위해 어둡게 덮는다.
          ColoredBox(color: p.background.withValues(alpha: .45)),
          content,
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final state = context.watch<LyricsCubit>().state;
    final lyrics = state.trackId == widget.track.id ? state.lyrics : null;

    if (state.loading && lyrics == null) {
      return const SizedBox.shrink();
    }
    if (lyrics == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.lyricsEmpty, style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.lyricsEmptyHint,
              style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            PlainButton(
              label: l10n.lyricsMenuEdit,
              icon: AppIcons.edit,
              onPressed: () => showLyricsEditor(context, widget.track),
            ),
          ],
        ),
      );
    }

    if (!lyrics.isSynced) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          lyrics.plain,
          style: text.bodyLarge?.copyWith(height: 1.7),
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
    final position = context.select<NowPlayingCubit, Duration>(
      (c) => c.state.position,
    );
    final current = lyrics.currentLine(position);
    final vm = context.read<NowPlayingCubit>();
    if (context.select<LyricsSettingsCubit, LyricsTheme>(
          (c) => c.state.theme,
        ) ==
        LyricsTheme.centered) {
      return _centered(lyrics, current, vm);
    }
    _follow(current);

    return Opacity(
      opacity: _placed ? 1 : 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          children: [
            for (var i = 0; i < lyrics.lines.length; i++)
              InkWell(
                key: _keys[i],
                borderRadius: BorderRadius.circular(AppRadii.sm),
                onTap: () => vm.seekTo(lyrics.lines[i].time),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    textAlign: TextAlign.center,
                    style: (i == current ? text.titleLarge : text.bodyLarge)!
                        .copyWith(
                          color: i == current ? p.accent : p.onSurfaceMuted,
                        ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        lyrics.lines[i].text.isEmpty
                            ? '♪'
                            : lyrics.lines[i].text,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
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

  /// 가운데 한 줄 테마: 현재 줄을 가운데에 크게 두고 앞뒤 몇 줄만 흐리게 보인다. 줄이 바뀌면 부드럽게 미끄러진다.
  Widget _centered(Lyrics lyrics, int current, NowPlayingCubit vm) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    const slot = 64.0;
    const reach = 3;
    return LayoutBuilder(
      builder: (context, box) => TweenAnimationBuilder<double>(
        tween: Tween(end: current.toDouble()),
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        builder: (context, pos, _) {
          final first = (pos - reach).floor().clamp(0, lyrics.lines.length);
          final last = (pos + reach).ceil().clamp(-1, lyrics.lines.length - 1);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var i = first; i <= last; i++)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: box.maxHeight / 2 - slot / 2 + (i - pos) * slot,
                  height: slot,
                  child: _centeredLine(
                    lyrics.lines[i],
                    (i - pos).abs(),
                    text,
                    p,
                    vm,
                  ),
                ),
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
    NowPlayingCubit vm,
  ) {
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge!.copyWith(
                color: Color.lerp(p.onSurfaceMuted, p.accent, near),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
