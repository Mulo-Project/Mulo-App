import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/lyrics.dart';
import '../bloc/lyrics_sync_cubit.dart';

/// 가사 글 [text]를 곡에 맞춰 줄마다 시간을 찍는 화면을 연다.
/// 저장하면 LRC 글을, 닫으면 null을 돌려준다. [text]가 비어 있으면 열지 않고 null.
Future<String?> showLyricsSync(
  BuildContext context,
  Track track,
  String text,
) async {
  final lyrics = Lyrics.parse(text);
  if (lyrics == null) return null;
  return Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => LyricsSyncCubit(lyrics),
        child: LyricsSyncScreen(track: track),
      ),
    ),
  );
}

class LyricsSyncScreen extends StatefulWidget {
  const LyricsSyncScreen({super.key, required this.track});

  final Track track;

  @override
  State<LyricsSyncScreen> createState() => _LyricsSyncScreenState();
}

class _LyricsSyncScreenState extends State<LyricsSyncScreen> {
  static const _lead = Duration(seconds: 2);
  var _keys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _keys = List.generate(
      context.read<LyricsSyncCubit>().state.draft.length,
      (_) => GlobalKey(),
    );
    // 이 곡을 재생 중이 아니면 이 곡을 처음부터 틀고, 같은 곡이면 이어서 듣는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final np = context.read<NowPlayingCubit>();
      if (np.state.track != widget.track) {
        np.playQueue([widget.track]);
      } else if (!np.state.isPlaying) {
        np.togglePlay();
      }
    });
  }

  void _scrollTo(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = index >= 0 && index < _keys.length
          ? _keys[index].currentContext
          : null;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: .4,
        duration: AppMotion.medium,
        curve: AppMotion.standard,
      );
    });
  }

  void _now() {
    final position = context.read<NowPlayingCubit>().state.position;
    context.read<LyricsSyncCubit>().stamp(position);
  }

  /// [time]보다 조금 앞에서 다시 재생한다 (찍은 곳이 맞는지 앞 소리까지 듣도록).
  void _replay(Duration time) {
    final np = context.read<NowPlayingCubit>();
    np.seekTo(time > _lead ? time - _lead : Duration.zero);
    if (!np.state.isPlaying) np.togglePlay();
  }

  static String _clock(Duration d) {
    final s = SyncDraft.formatStamp(d);
    return s.substring(1, s.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return BlocConsumer<LyricsSyncCubit, LyricsSyncState>(
      listenWhen: (a, b) => a.draft.current != b.draft.current,
      listener: (_, s) => _scrollTo(s.draft.current),
      builder: (context, state) {
        final draft = state.draft;
        final sync = context.read<LyricsSyncCubit>();
        return Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            child: Column(
              children: [
                AppTopBar(
                  title: l10n.lyricsSyncTitle,
                  leading: CircleIconButton(
                    icon: Icons.close_rounded,
                    tooltip: l10n.actionCancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    CircleIconButton(
                      icon: Icons.check_rounded,
                      tooltip: draft.isComplete
                          ? l10n.lyricsSyncSave
                          : l10n.lyricsSyncNeedAll,
                      emphasized: draft.isComplete,
                      onPressed: draft.isComplete
                          ? () => Navigator.of(context).pop(draft.toLrc())
                          : null,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxs,
                    AppSpacing.lg,
                    AppSpacing.xxs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.track.title,
                          style: text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        l10n.lyricsSyncProgress(draft.stamped, draft.length),
                        style: text.labelLarge?.copyWith(color: p.accent),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.lyricsSyncHint,
                      style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                    ),
                  ),
                ),
                Expanded(
                  child: draft.length == 0
                      ? Center(child: Text(l10n.lyricsSyncEmpty))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              for (var i = 0; i < draft.length; i++)
                                _LineRow(
                                  key: _keys[i],
                                  index: i,
                                  draft: draft,
                                  selected: state.selected == i,
                                  clock: _clock,
                                  onTap: () => i == draft.current
                                      ? _now()
                                      : sync.select(i),
                                  onReplay: () => _replay(draft.times[i]!),
                                ),
                            ],
                          ),
                        ),
                ),
                _ControlBar(onNow: _now),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.index,
    required this.draft,
    required this.selected,
    required this.clock,
    required this.onTap,
    required this.onReplay,
  });

  final int index;
  final SyncDraft draft;
  final bool selected;
  final String Function(Duration) clock;
  final VoidCallback onTap;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final time = draft.times[index];
    final isCurrent = index == draft.current;
    final color = isCurrent
        ? p.accent
        : (time == null ? p.onSurfaceMuted : p.onSurface);
    final sync = context.read<LyricsSyncCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    time == null ? '--:--.--' : clock(time),
                    style: text.labelMedium?.copyWith(
                      color: selected ? p.accent : p.onSurfaceMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    style: (isCurrent ? text.titleMedium : text.bodyLarge)!
                        .copyWith(color: color),
                    child: Text(draft.texts[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selected && time != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final ms in const [-500, -100, 100, 500])
                  PillButton(
                    label: '${ms > 0 ? '+' : '−'}${ms.abs() / 1000}s',
                    variant: PillVariant.tonal,
                    compact: true,
                    onPressed: () => sync.nudge(Duration(milliseconds: ms)),
                  ),
                CircleIconButton(
                  icon: Icons.replay_rounded,
                  tooltip: l10n.lyricsSyncReplay,
                  size: 36,
                  onPressed: onReplay,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.onNow});

  final VoidCallback onNow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final np = context.watch<NowPlayingCubit>();
    final sync = context.watch<LyricsSyncCubit>();
    final draft = sync.state.draft;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${formatDuration(np.state.position)} / '
            '${formatDuration(np.state.track?.duration ?? Duration.zero)}',
            style: text.labelMedium?.copyWith(
              color: context.palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              CircleIconButton(
                icon: Icons.undo_rounded,
                tooltip: l10n.lyricsSyncUndo,
                onPressed: draft.canUndo ? sync.undo : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              CircleIconButton(
                icon: np.state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: np.state.isPlaying
                    ? l10n.lyricsSyncPause
                    : l10n.lyricsSyncPlay,
                onPressed: np.togglePlay,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PillButton(
                  label: l10n.lyricsSyncNow,
                  icon: Icons.touch_app_rounded,
                  onPressed: draft.current >= draft.length ? null : onNow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
