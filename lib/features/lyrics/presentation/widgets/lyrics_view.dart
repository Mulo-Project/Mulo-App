import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/lyrics_cubit.dart';
import 'lyrics_menu.dart';

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
    if (index < 0) return;
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
    return Stack(
      children: [
        Positioned.fill(child: _body(context)),
        Positioned(
          top: 0,
          right: 0,
          child: LyricsMenuButton(track: widget.track),
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
            PillButton(
              label: l10n.lyricsMenuTooltip,
              icon: Icons.edit_note_rounded,
              variant: PillVariant.tonal,
              onPressed: () => showLyricsMenu(context, widget.track),
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
        ],
      ),
    );
  }
}
