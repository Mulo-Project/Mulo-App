import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/lyrics.dart';
import '../bloc/lyrics_sync_cubit.dart';
import '../widgets/lyrics_dialogs.dart';

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
      _askDefaultGroup();
      final np = context.read<NowPlayingCubit>();
      if (np.state.track != widget.track) {
        np.playQueue([widget.track]);
      } else if (!np.state.isPlaying) {
        np.togglePlay();
      }
    });
  }

  /// 싱크가 아직 없는 일반 글이면 기본으로 한 번에 찍을 줄 수를 먼저 묻는다.
  Future<void> _askDefaultGroup() async {
    final sync = context.read<LyricsSyncCubit>();
    if (!sync.canGroup) return;
    final group = await pickLyricsDefaultGroup(
      context,
      initial: sync.state.group,
    );
    if (group != null) sync.setGroup(group);
  }

  /// 위쪽 메뉴: 기본 줄 수를 바꾼다. 직접 묶은 줄이 있으면 사라진다고 먼저 알린다.
  Future<void> _changeDefaultGroup(BuildContext buttonContext) async {
    final l10n = context.l10n;
    final sync = context.read<LyricsSyncCubit>();
    final group = await showAppMenu<int>(
      buttonContext,
      items: [
        for (final n in const [1, 2, 3, 4])
          AppMenuItem(
            value: n,
            icon: Icons.format_line_spacing_rounded,
            label: l10n.lyricsSyncGroupLines(n),
            selected: n == sync.state.group,
          ),
      ],
    );
    if (group == null || group == sync.state.group || !mounted) return;
    if (sync.loseOnSetGroup && !await confirmLyricsGroupReset(context)) return;
    sync.setGroup(group);
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
        // 줄을 다시 묶어도 같은 칸은 같은 키를 쓴다 (끌고 있는 위젯이 다시 만들어지지 않게).
        while (_keys.length < draft.length) {
          _keys.add(GlobalKey());
        }
        if (_keys.length > draft.length) _keys.length = draft.length;
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
                    if (sync.canGroup)
                      Builder(
                        builder: (buttonContext) => CircleIconButton(
                          icon: Icons.more_vert_rounded,
                          tooltip: l10n.lyricsSyncDefaultLines,
                          onPressed: () => _changeDefaultGroup(buttonContext),
                        ),
                      ),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ClockText(),
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
                                  editing: state.editing == i,
                                  canGroup: sync.canGroup,
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
    required this.editing,
    required this.canGroup,
    required this.clock,
    required this.onTap,
    required this.onReplay,
  });

  final int index;
  final SyncDraft draft;
  final bool selected;
  final bool editing;
  final bool canGroup;
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
        if (editing)
          _GroupPanel(draft: draft, index: index)
        else if (selected && time != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlainButton(
                  icon: Icons.replay_rounded,
                  label: l10n.lyricsSyncReset,
                  tooltip: l10n.lyricsSyncReplay,
                  onPressed: onReplay,
                ),
                if (canGroup)
                  Builder(
                    builder: (buttonContext) => PlainButton(
                      icon: Icons.more_vert_rounded,
                      tooltip: l10n.actionMore,
                      onPressed: () async {
                        final pick = await showAppMenu<bool>(
                          buttonContext,
                          items: [
                            AppMenuItem(
                              value: true,
                              icon: Icons.view_headline_rounded,
                              label: l10n.lyricsSyncGroupEdit,
                            ),
                          ],
                        );
                        if (pick == true) sync.startGroupEdit(index);
                      },
                    ),
                  ),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      for (final ms in const [-500, -100, 100, 500])
                        PlainButton(
                          label: '${ms > 0 ? '+' : '−'}${ms.abs() / 1000}s',
                          onPressed: () =>
                              sync.nudge(Duration(milliseconds: ms)),
                        ),
                    ],
                  ),
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
          Row(
            children: [
              CircleIconButton(
                icon: Icons.undo_rounded,
                tooltip: l10n.lyricsSyncUndo,
                onPressed: draft.canUndo ? sync.undo : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: np.state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: np.state.isPlaying
                    ? l10n.lyricsSyncPause
                    : l10n.lyricsSyncPlay,
                emphasized: true,
                onPressed: np.togglePlay,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PillButton(
                    label: l10n.lyricsSyncNow,
                    icon: Icons.touch_app_rounded,
                    onPressed: draft.current >= draft.length ? null : onNow,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 지금 재생 위치 / 곡 전체 시간. 몇 줄 남았는지 보이는 위쪽에 둔다.
class _ClockText extends StatelessWidget {
  const _ClockText();

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NowPlayingCubit>();
    return Text(
      '${formatDuration(np.state.position)} / '
      '${formatDuration(np.state.track?.duration ?? Duration.zero)}',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.palette.onSurfaceMuted,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// 한 칸에 묶을 줄을 고르는 영역. 묶을 마지막 줄을 누르거나 위아래로 끌어 고른다.
class _GroupPanel extends StatelessWidget {
  const _GroupPanel({required this.draft, required this.index});

  final SyncDraft draft;
  final int index;

  static const _rowHeight = 36.0;
  static const _extra = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final sync = context.read<LyricsSyncCubit>();
    final start = draft.startOf(index);
    final end = start + draft.sizes[index];
    final shown = (end + _extra).clamp(0, draft.lines.length);

    void pick(double dy) {
      final line = (start + dy ~/ _rowHeight).clamp(start, shown - 1);
      sync.regroup(line);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.lyricsSyncGroupPanelHint,
            style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition.dy),
            onVerticalDragStart: (d) => pick(d.localPosition.dy),
            onVerticalDragUpdate: (d) => pick(d.localPosition.dy),
            child: Column(
              children: [
                for (var i = start; i < shown; i++)
                  Container(
                    height: _rowHeight,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: i < end ? p.accent.withValues(alpha: .18) : null,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      draft.lines[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: i < end ? p.onSurface : p.onSurfaceMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PlainButton(
              label: l10n.lyricsSyncGroupDone,
              accent: true,
              onPressed: sync.endGroupEdit,
            ),
          ),
        ],
      ),
    );
  }
}
