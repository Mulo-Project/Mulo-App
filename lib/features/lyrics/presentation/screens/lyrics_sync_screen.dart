import 'dart:async';

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
  static const _steps = [10, 100, 500, 1000, 3000, 5000, 10000, 30000, 60000];
  var _stepMs = 500;
  var _autoPause = false;
  var _keys = <GlobalKey>[];
  StreamSubscription<NowPlayingState>? _positionWatch;

  @override
  void initState() {
    super.initState();
    _positionWatch = context.read<NowPlayingCubit>().stream.listen(_watchPass);
    _keys = List.generate(
      context.read<LyricsSyncCubit>().state.draft.length,
      (_) => GlobalKey(),
    );
    // 들어오면 재생 중이던 소리는 멈추고, 이 곡을 0초에 세워 둔다 (재생은 직접 누른다).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _askDefaultGroup();
      final np = context.read<NowPlayingCubit>();
      if (np.state.track != widget.track) {
        np.playQueue([widget.track]);
      } else {
        np.seekTo(Duration.zero);
      }
      if (np.state.isPlaying) np.togglePlay();
    });
  }

  @override
  void dispose() {
    _positionWatch?.cancel();
    super.dispose();
  }

  /// 자동 멈춤: 다음에 찍을 줄에 이미 싱크가 있으면, 재생이 그 시간에 닿을 때 멈춘다.
  void _watchPass(NowPlayingState s) {
    if (!_autoPause || !mounted || !s.isPlaying) return;
    final draft = context.read<LyricsSyncCubit>().state.draft;
    final at = draft.current < draft.length ? draft.times[draft.current] : null;
    if (at == null || s.position < at) return;
    // 이미 지나 있던 곳에서 재생을 시작한 경우는 멈추지 않는다 (한 번 닿는 순간만).
    if (s.position - at > const Duration(seconds: 1)) return;
    context.read<NowPlayingCubit>().togglePlay();
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
            icon: AppIcons.lineSpacing,
            label: l10n.lyricsSyncGroupLines(n),
            selected: n == sync.state.group,
          ),
      ],
    );
    if (group == null || group == sync.state.group || !mounted) return;
    if (sync.loseOnSetGroup && !await confirmLyricsGroupReset(context)) return;
    sync.setGroup(group);
  }

  /// 나가기: 다 찍었으면 그대로 나가고, 덜 찍었으면 저장하고 나갈지 묻는다.
  Future<void> _confirmLeave() async {
    final sync = context.read<LyricsSyncCubit>();
    final draft = sync.state.draft;
    if (draft.stamped == 0) {
      Navigator.of(context).pop();
      return;
    }
    final choice = await askLyricsSyncLeave(context);
    if (choice == null || !mounted) return;
    Navigator.of(context).pop(
      choice == LyricsSyncLeave.save ? sync.state.draft.toPartialLrc() : null,
    );
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

  /// 이전 싱크로: 지금까지 완료한 가장 마지막 싱크 칸에 포커스하고 재생도 그 시간으로 옮긴다.
  /// 이미 포커스한 칸이 있으면 한 칸씩 더 앞으로 간다.
  void _previous() {
    final sync = context.read<LyricsSyncCubit>();
    final draft = sync.state.draft;
    final at = sync.state.selected;
    var target = at != null && at < draft.current ? at - 1 : draft.current - 1;
    while (target >= 0 && draft.times[target] == null) {
      target--;
    }
    if (target < 0) return;
    final time = draft.times[target]!;
    sync.select(target);
    context.read<NowPlayingCubit>().seekTo(time);
  }

  /// 가사 칸 목록. 줄별로 펼친 영역이 있으면 그 칸들을 색 바탕 한 영역으로 묶어 보여 준다.
  List<Widget> _rows(BuildContext context, LyricsSyncState state) {
    final draft = state.draft;
    final sync = context.read<LyricsSyncCubit>();
    final l10n = context.l10n;
    final p = context.palette;
    final ex = state.expanded;

    Widget row(int i) => _LineRow(
      key: _keys[i],
      index: i,
      draft: draft,
      selected: state.selected == i,
      canGroup: sync.canGroup,
      clock: _clock,
      onLongPress: sync.canGroup && draft.sizes[i] > 1
          ? () => sync.expand(i)
          : null,
      onTap: () async {
        if (i == draft.current) return _now();
        // 건너뛰면 사이에 찍어 둔 싱크가 사라지니 먼저 묻는다.
        if (sync.skipErasesStamped(i) &&
            !await confirmLyricsSkipMerge(context)) {
          return;
        }
        if (!context.mounted) return;
        sync.select(i);
        // 찍어 둔 줄이면 재생도 그 싱크 위치로 옮긴다.
        final time = draft.times[i];
        if (time != null) {
          context.read<NowPlayingCubit>().seekTo(time);
        }
      },
    );

    final out = <Widget>[];
    var i = 0;
    while (i < draft.length) {
      if (ex != null && i == ex.$1) {
        final end = (ex.$1 + ex.$2).clamp(0, draft.length);
        out.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    0,
                  ),
                  child: Text(
                    l10n.lyricsSyncExpandedHint,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: p.accent),
                  ),
                ),
                for (var j = i; j < end; j++) row(j),
              ],
            ),
          ),
        );
        i = end;
      } else {
        out.add(row(i));
        i++;
      }
    }
    return out;
  }

  /// 되돌리기: 찍은 줄이 풀리면 그 앞 줄부터 다시 들려줘 이어서 찍을 수 있게 한다.
  void _undo() {
    final sync = context.read<LyricsSyncCubit>();
    final before = sync.state.draft.current;
    sync.undo();
    final draft = sync.state.draft;
    if (draft.current == before) return;
    final prev = draft.current > 0 ? draft.times[draft.current - 1] : null;
    _replay(prev ?? Duration.zero);
  }

  /// 자동 멈춤이 켜져 있으면 다음에 찍을 줄의 기존 싱크 시간이 앞으로 갈 수 있는 끝이다.
  Duration? get _limit {
    if (!_autoPause) return null;
    final draft = context.read<LyricsSyncCubit>().state.draft;
    return draft.current < draft.length ? draft.times[draft.current] : null;
  }

  Duration _clampLimit(Duration target) {
    final limit = _limit;
    return limit != null && target > limit ? limit : target;
  }

  /// 지금 위치에서 [_stepMs]밀리초 앞뒤로 옮긴다 ('지금'을 놓쳤을 때).
  /// 뒤로 가면 이어서 들려주고, 자동 멈춤 중에는 다음 싱크 시간 너머로 못 간다.
  void _skip(int sign) {
    final np = context.read<NowPlayingCubit>();
    final target = np.state.position + Duration(milliseconds: _stepMs * sign);
    np.seekTo(_clampLimit(target));
    if (sign < 0 && !np.state.isPlaying) np.togglePlay();
  }

  /// 슬라이더로 옮길 때도 같은 한계를 지킨다.
  void _seekFraction(double fraction) {
    final np = context.read<NowPlayingCubit>();
    final total = np.state.track?.duration;
    if (total == null) return;
    np.seekTo(_clampLimit(total * fraction.clamp(0.0, 1.0)));
  }

  /// 앞뒤 버튼을 길게 눌렀을 때: 한 번에 옮길 초를 고른다.
  Future<void> _pickStep(BuildContext buttonContext) async {
    final pick = await showAppMenu<int>(
      buttonContext,
      items: [
        for (final n in _steps)
          AppMenuItem(
            value: n,
            icon: AppIcons.timer,
            label: stepLabel(n),
            selected: n == _stepMs,
          ),
      ],
    );
    if (pick != null && mounted) setState(() => _stepMs = pick);
  }

  /// [time]보다 조금 앞에서 다시 재생한다 (찍은 곳이 맞는지 앞 소리까지 듣도록).
  void _replay(Duration time) {
    final np = context.read<NowPlayingCubit>();
    np.seekTo(time > _lead ? time - _lead : Duration.zero);
    if (!np.state.isPlaying) np.togglePlay();
  }

  /// 이동 단위 글자: 1초 미만은 0.1s처럼, 1분 단위는 1m, 나머지는 정수 초.
  static String stepLabel(int ms) {
    if (ms < 1000) return '${ms / 1000}s';
    if (ms >= 60000 && ms % 60000 == 0) return '${ms ~/ 60000}m';
    return '${ms ~/ 1000}s';
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
        // 한 줄이라도 찍은 채로 나가면 저장할지 묻는다.
        return PopScope(
          canPop: draft.stamped == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            backgroundColor: p.background,
            body: SafeArea(
              child: Column(
                children: [
                  AppTopBar(
                    title: l10n.lyricsSyncTitle,
                    leading: CircleIconButton(
                      icon: AppIcons.close,
                      tooltip: l10n.actionCancel,
                      onPressed: _confirmLeave,
                    ),
                    actions: [
                      if (sync.canGroup)
                        Builder(
                          builder: (buttonContext) => CircleIconButton(
                            icon: AppIcons.more,
                            tooltip: l10n.lyricsSyncDefaultLines,
                            onPressed: () => _changeDefaultGroup(buttonContext),
                          ),
                        ),
                      CircleIconButton(
                        icon: AppIcons.check,
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
                        style: text.bodySmall?.copyWith(
                          color: p.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: draft.length == 0
                        ? Center(child: Text(l10n.lyricsSyncEmpty))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(children: [..._rows(context, state)]),
                          ),
                  ),
                  _ControlBar(
                    stepMs: _stepMs,
                    autoPause: _autoPause,
                    onAutoPause: () => setState(() => _autoPause = !_autoPause),
                    onNow: _now,
                    onUndo: _undo,
                    onPrevious: _previous,
                    onSkip: _skip,
                    onSeek: _seekFraction,
                    onPickStep: _pickStep,
                  ),
                ],
              ),
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
    required this.canGroup,
    required this.clock,
    required this.onTap,
    this.onLongPress,
  });

  final int index;
  final SyncDraft draft;
  final bool selected;
  final bool canGroup;
  final String Function(Duration) clock;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
    // 다음에 찍을 줄의 기존 싱크 시간을 재생이 이미 지나갔는가.
    final passed =
        isCurrent &&
        time != null &&
        context.select<NowPlayingCubit, bool>((c) => c.state.position > time);

    final block = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            // 다음에 찍을 줄은 왼쪽에 강조 선을 둔다.
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isCurrent ? p.accent : p.accent.withValues(alpha: 0),
                  width: 3,
                ),
              ),
            ),
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
                      // 찍은 줄(완료)과 다음에 찍을 줄은 강조 색, 아직인 줄은 흐리게.
                      color: time != null || isCurrent
                          ? p.accent
                          : p.onSurfaceMuted,
                      decoration: passed ? TextDecoration.lineThrough : null,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    style: (isCurrent ? text.bodyLarge : text.bodyMedium)!
                        .copyWith(color: color),
                    child: Text(draft.texts[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 건너뛰어 같은 시간으로 묶인 칸은 따로 표시하고, 다시 나눌 수 있게 한다.
        if (canGroup && sync.isMerged(index))
          Padding(
            padding: const EdgeInsets.only(left: 76 + AppSpacing.sm + 3),
            child: Row(
              children: [
                Text(
                  l10n.lyricsSyncMerged(draft.sizes[index]),
                  style: text.labelSmall?.copyWith(color: p.accent),
                ),
                PlainButton(
                  label: l10n.lyricsSyncUnmerge,
                  onPressed: () => sync.split(index),
                ),
              ],
            ),
          ),
        if (selected && time != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 위: 시간 맞추기 버튼
                Wrap(
                  children: [
                    for (final ms in const [-500, -100, -10, 10, 100, 500])
                      PlainButton(
                        label: '${ms > 0 ? '+' : '−'}${ms.abs() / 1000}s',
                        onPressed: () {
                          sync.nudge(Duration(milliseconds: ms));
                          // 조정한 시간으로 재생도 옮겨, 바로 들어 보며 맞춘다.
                          final moved = sync.state.draft.times[index];
                          if (moved != null) {
                            context.read<NowPlayingCubit>().seekTo(moved);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
    // 포커스된 싱크 칸(시간 조정 버튼까지)은 영역 전체에 색을 깐다.
    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: selected ? p.accent.withValues(alpha: .16) : null,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: block,
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.stepMs,
    required this.autoPause,
    required this.onAutoPause,
    required this.onNow,
    required this.onUndo,
    required this.onPrevious,
    required this.onSkip,
    required this.onSeek,
    required this.onPickStep,
  });

  final int stepMs;
  final bool autoPause;
  final VoidCallback onAutoPause;
  final VoidCallback onNow;
  final VoidCallback onUndo;
  final VoidCallback onPrevious;
  final void Function(int sign) onSkip;
  final ValueChanged<double> onSeek;
  final void Function(BuildContext buttonContext) onPickStep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final np = context.watch<NowPlayingCubit>();
    final sync = context.watch<LyricsSyncCubit>();
    final draft = sync.state.draft;
    final total = np.state.track?.duration ?? Duration.zero;
    final totalMs = total.inMilliseconds;
    // 찍어 둔 줄마다 슬라이더 위에 작은 표시를 남긴다.
    final marks = totalMs == 0
        ? const <double>[]
        : [
            for (final t in draft.times)
              if (t != null) t.inMilliseconds / totalMs,
          ];
    // 지금 포커스된 줄의 표시는 따로 강조한다.
    final at = sync.state.selected;
    final focus = totalMs == 0 || at == null || draft.times[at] == null
        ? null
        : draft.times[at]!.inMilliseconds / totalMs;
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
              Builder(
                builder: (buttonContext) => PlainButton(
                  label: '−${_LyricsSyncScreenState.stepLabel(stepMs)}',
                  tooltip: l10n.lyricsSyncBackBy(stepMs / 1000),
                  onPressed: () => onSkip(-1),
                  onLongPress: () => onPickStep(buttonContext),
                ),
              ),
              Expanded(
                child: AppSlider(
                  semanticLabel: l10n.lyricsSyncSeek,
                  value: totalMs == 0
                      ? 0
                      : np.state.position.inMilliseconds / totalMs,
                  marks: marks,
                  activeMark: focus,
                  thumbAlpha: .5,
                  onChanged: totalMs == 0 ? null : onSeek,
                ),
              ),
              Builder(
                builder: (buttonContext) => PlainButton(
                  label: '+${_LyricsSyncScreenState.stepLabel(stepMs)}',
                  tooltip: l10n.lyricsSyncForwardBy(stepMs / 1000),
                  onPressed: () => onSkip(1),
                  onLongPress: () => onPickStep(buttonContext),
                ),
              ),
            ],
          ),
          const Align(alignment: Alignment.centerRight, child: _ClockText()),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              CircleIconButton(
                icon: AppIcons.undo,
                tooltip: l10n.lyricsSyncUndo,
                onPressed: draft.canUndo ? onUndo : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: AppIcons.skipPrevious,
                tooltip: l10n.lyricsSyncPrevious,
                onPressed: draft.stamped > 0 ? onPrevious : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: np.state.isPlaying ? AppIcons.pause : AppIcons.play,
                tooltip: np.state.isPlaying
                    ? l10n.lyricsSyncPause
                    : l10n.lyricsSyncPlay,
                emphasized: true,
                onPressed: np.togglePlay,
              ),
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(width: AppSpacing.sm),
              PlainButton(
                icon: AppIcons.timer,
                tooltip: l10n.lyricsSyncAutoPauseHint,
                accent: autoPause,
                onPressed: onAutoPause,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PillButton(
                    label: l10n.lyricsSyncNow,
                    icon: AppIcons.touch,
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
