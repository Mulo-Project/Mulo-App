import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/lyrics.dart';
import '../bloc/lyrics_settings_cubit.dart';
import '../bloc/lyrics_sync_cubit.dart';
import '../widgets/lyrics_dialogs.dart';
import '../widgets/lyrics_sync_parts.dart';
import 'lyrics_latency_screen.dart';

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
  int? _dragFrom;
  int? _dragTo;
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
    // 들어오면 재생 중이던 소리는 멈추고, 이 곡을 0초(이어 찍는 가사면 마지막 싱크 위치)에 세워 둔다 (재생은 직접 누른다).
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
      // 도중에 저장한 가사를 다시 열었으면 마지막으로 찍은 싱크 위치에 재생을 맞춰 둔다.
      final times = context.read<LyricsSyncCubit>().state.draft.times;
      final last = times.lastIndexWhere((t) => t != null);
      if (last >= 0) np.seekTo(times[last]!);
    });
  }

  @override
  void dispose() {
    _positionWatch?.cancel();
    super.dispose();
  }

  /// 자동 멈춤: 포커스한 싱크 바로 다음 칸에 이미 싱크가 있으면, 재생이 그 시간에 닿을 때 멈춘다.
  void _watchPass(NowPlayingState s) {
    if (!_autoPause || !mounted || !s.isPlaying) return;
    final at = context.read<LyricsSyncCubit>().nextStampAfterFocus;
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

  /// 위쪽 메뉴: 기본 줄 수를 바꾸거나 반응 시간 보정 페이지를 연다.
  /// 줄 수를 바꿀 때 직접 묶은 줄이 있으면 사라진다고 먼저 알린다.
  Future<void> _openMenu(BuildContext buttonContext) async {
    final l10n = context.l10n;
    final sync = context.read<LyricsSyncCubit>();
    const latency = 0;
    final picked = await showAppMenu<int>(
      buttonContext,
      items: [
        if (sync.canGroup)
          for (final n in const [1, 2, 3, 4])
            AppMenuItem(
              value: n,
              icon: AppIcons.lineSpacing,
              label: l10n.lyricsSyncGroupLines(n),
              selected: n == sync.state.group,
            ),
        AppMenuItem(
          value: latency,
          icon: AppIcons.tune,
          label: l10n.lyricsLatencyEntry,
          dividerBefore: sync.canGroup,
        ),
      ],
    );
    if (picked == null || !mounted) return;
    if (picked == latency) {
      await showLyricsLatency(context);
      return;
    }
    if (picked == sync.state.group) return;
    if (sync.loseOnSetGroup && !await confirmLyricsGroupReset(context)) return;
    sync.setGroup(picked);
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
    final np = context.read<NowPlayingCubit>();
    final sync = context.read<LyricsSyncCubit>();
    final stamped = sync.state.draft.current;
    // 소리를 듣고 누르는 반응 시간만큼 앞당겨 찍는다.
    final latency = context.read<LyricsSettingsCubit>().state.latency;
    final at = np.state.position - latency;
    sync.stamp(at < Duration.zero ? Duration.zero : at);
    // 찍은 뒤 포커스가 이미 싱크된 칸으로 넘어갔으면, 재생도 그 싱크 위치로 맞춘다 (빈 칸이면 그대로 이어서 재생).
    final next = sync.state.selected;
    final time = next == null ? null : sync.state.draft.times[next];
    if (next != null && next != stamped && time != null) np.seekTo(time);
  }

  /// 뒤로: 가장 뒤에 찍은 싱크를 하나 지우고 그 줄로 돌아간다. 누를 때마다 한 칸씩 지운다.
  void _previous() {
    final sync = context.read<LyricsSyncCubit>();
    final draft = sync.state.draft;
    final last = draft.times.lastIndexWhere((t) => t != null);
    if (last < 0) return;
    final time = draft.times[last]!;
    sync.stepBack();
    // 지운 싱크 조금 앞에서부터 다시 들려줘, 이어서 지금으로 다시 찍을 수 있게 한다.
    _replay(time);
  }

  /// 끌고 있는 손가락 아래 칸을 찾아 묶을 범위의 끝으로 삼는다 (위로도 아래로도).
  void _dragMove(double dy, SyncDraft draft) {
    final from = _dragFrom;
    if (from == null) return;
    var to = 0;
    for (var i = 0; i < _keys.length && i < draft.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (dy >= top) to = i;
    }
    if (to != _dragTo) setState(() => _dragTo = to);
  }

  /// 손을 떼면 고른 범위를 한 칸으로 묶는다 (이미 찍은 싱크가 지워지면 먼저 묻는다).
  Future<void> _dragEnd() async {
    final from = _dragFrom;
    final to = _dragTo;
    setState(() {
      _dragFrom = null;
      _dragTo = null;
    });
    if (from == null || to == null || to == from) return;
    // 위로 끌어도 된다: 범위는 위쪽 칸부터 아래쪽 칸까지이고 위쪽 칸의 시간을 쓴다.
    final first = math.min(from, to);
    final last = math.max(from, to);
    final sync = context.read<LyricsSyncCubit>();
    if (sync.rangeErasesStamped(first, last) &&
        !await confirmLyricsSkipMerge(context)) {
      return;
    }
    if (!mounted) return;
    sync.mergeRange(first, last);
  }

  /// 가사 칸 목록. 줄별로 펼친 영역이 있으면 그 칸들을 색 바탕 한 영역으로 묶어 보여 준다.
  List<Widget> _rows(BuildContext context, LyricsSyncState state) {
    final draft = state.draft;
    final sync = context.read<LyricsSyncCubit>();
    final l10n = context.l10n;
    final p = context.palette;
    final ex = state.expanded;

    Widget row(int i) {
      final dragRange =
          _dragFrom != null &&
          _dragTo != null &&
          i >= math.min(_dragFrom!, _dragTo!) &&
          i <= math.max(_dragFrom!, _dragTo!);
      final merged = draft.sizes[i] > 1;
      final line = SyncLineRow(
        key: _keys[i],
        index: i,
        draft: draft,
        selected: state.selected == i,
        inRange: dragRange,
        afterFocus: state.selected != null && i == state.selected! + 1,
        canMerge: sync.canMerge,
        clock: _clock,
        onLongPress: sync.canMerge && merged ? () => sync.expand(i) : null,
        onTap: () {
          // 줄을 눌러서는 싱크를 찍지 않는다 (싱크 등록은 지금 버튼으로만).
          sync.select(i);
          // 찍어 둔 줄이면 재생도 그 싱크 위치로 옮긴다.
          final time = draft.times[i];
          if (time != null) {
            context.read<NowPlayingCubit>().seekTo(time);
          }
        },
      );
      // 한 줄짜리 칸은 꾹 누른 채 아래로 끌어 묶을 범위를 고른다.
      if (!sync.canMerge || merged) return line;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: (_) => setState(() {
          _dragFrom = i;
          _dragTo = i;
        }),
        onLongPressMoveUpdate: (d) => _dragMove(d.globalPosition.dy, draft),
        onLongPressEnd: (_) => _dragEnd(),
        onLongPressCancel: () => setState(() {
          _dragFrom = null;
          _dragTo = null;
        }),
        child: line,
      );
    }

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

  /// 자동 멈춤이 켜져 있으면 포커스한 싱크 다음 칸의 기존 싱크 시간이 앞으로 갈 수 있는 끝이다.
  Duration? get _limit {
    if (!_autoPause) return null;
    return context.read<LyricsSyncCubit>().nextStampAfterFocus;
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
            label: syncStepLabel(n),
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
                      Builder(
                        builder: (buttonContext) => CircleIconButton(
                          icon: AppIcons.more,
                          tooltip: l10n.lyricsSyncDefaultLines,
                          onPressed: () => _openMenu(buttonContext),
                        ),
                      ),
                      CircleIconButton(
                        icon: AppIcons.check,
                        // 다 찍었으면 강조해서 저장하고, 덜 찍었어도 누르면 찍은 곳까지 중간 저장한다.
                        tooltip: draft.isComplete
                            ? l10n.lyricsSyncSave
                            : l10n.lyricsSyncSavePartial,
                        emphasized: draft.isComplete,
                        onPressed: draft.stamped == 0
                            ? null
                            : () => Navigator.of(context).pop(
                                draft.isComplete
                                    ? draft.toLrc()
                                    : draft.toPartialLrc(),
                              ),
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
                        ? EmptyState(title: l10n.lyricsSyncEmpty)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(children: [..._rows(context, state)]),
                          ),
                  ),
                  SyncControlBar(
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
