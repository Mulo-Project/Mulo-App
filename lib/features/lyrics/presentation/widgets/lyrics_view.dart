import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/lyrics_cubit.dart';
import 'lyrics_editor.dart';
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
    if (index < 0 || !_following) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = index < _keys.length ? _keys[index].currentContext : null;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: .4,
        duration: AppMotion.medium,
        curve: AppMotion.standard,
      );
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
    return Column(
      children: [
        Expanded(child: _body(context)),
        // 싱크 추적: 켜면 재생 위치의 줄을 따라 가사가 올라가고, 끄면 방해 없이 자유롭게 볼 수 있다.
        // 싱크 설정 · 가사 편집 버튼과는 다른 줄에 둔다.
        if (synced)
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

  Widget _body(BuildContext context) {
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
    }
    final position = context.select<NowPlayingCubit, Duration>(
      (c) => c.state.position,
    );
    final current = lyrics.currentLine(position);
    _follow(current);
    final vm = context.read<NowPlayingCubit>();

    return SingleChildScrollView(
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
                      lyrics.lines[i].text.isEmpty ? '♪' : lyrics.lines[i].text,
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
    );
  }
}
