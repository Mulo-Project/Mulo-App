import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/presentation/bloc/saved_videos_cubit.dart';
import '../../../search/presentation/saved_track.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../search/presentation/screens/media_detail_screen.dart';
import '../bloc/now_playing_cubit.dart';
import '../bloc/player_style_cubit.dart';
import '../widgets/player_common.dart';
import '../widgets/player_layouts.dart';
import '../widgets/player_style_sheet.dart';

/// 전체 화면 플레이어 (상세 기능: 미니·전체 화면 플레이어 #19, 기본 재생 컨트롤 #14,
/// 셔플·반복 #15, 재생 대기열 편집 #16 — 대기열은 보기 · 선택만).
/// 모양은 더 보기 메뉴의 "플레이어 테마"로 고른다 ([PlayerStyle], D-039).
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// 커버 ↔ 가사 전환 (상세 기능: 가사).
  bool get _showLyrics => playerShowLyrics.value;

  @override
  void initState() {
    super.initState();
    playerShowLyrics.value = false;
    playerShowLyrics.addListener(_onLyricsToggle);
  }

  void _onLyricsToggle() => setState(() {});

  Animation<double>? _covered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 위에 덮인 화면(대기열 등)이 닫혀 다시 맨 위가 되면 빈 화면인지 본다.
    final next = ModalRoute.of(context)?.secondaryAnimation;
    if (next == _covered) return;
    _covered?.removeStatusListener(_onCoverStatus);
    _covered = next?..addStatusListener(_onCoverStatus);
  }

  @override
  void dispose() {
    playerShowLyrics.removeListener(_onLyricsToggle);
    _covered?.removeStatusListener(_onCoverStatus);
    super.dispose();
  }

  void _onCoverStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _closeIfEmpty();
  }

  /// 재생할 곡이 없으면(대기열을 비웠을 때) 빈 플레이어를 닫는다.
  void _closeIfEmpty() {
    if (!mounted || context.read<NowPlayingCubit>().state.track != null) return;
    if ((ModalRoute.of(context)?.isCurrent ?? false) && context.canPop()) {
      context.pop();
    }
  }

  String? _loggedTrackId;

  @override
  Widget build(BuildContext context) {
    final style = context.watch<PlayerStyleCubit>().state;
    // 재생 위치만 바뀔 때는 다시 그리지 않는다 (진행 막대 · 시간은 PositionBuilder가 따로 그린다).
    return BlocBuilder<NowPlayingCubit, NowPlayingState>(
      buildWhen: (a, b) => a.copyWith(position: b.position) != b,
      builder: (context, state) => _screen(context, state, style),
    );
  }

  Widget _screen(
    BuildContext context,
    NowPlayingState state,
    PlayerStyle style,
  ) {
    final track = state.track;
    if (track != null && track.id != _loggedTrackId) {
      _loggedTrackId = track.id;
      debugPrint(
        'MuloPlayer track=${track.id} isVideo=${track.isVideo} '
        'hasVideo=${track.hasVideo} style=$style uri=${track.uri}',
      );
    }
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeIfEmpty());
    }

    // 임시 저장한 음원이면 가운데에 다운로드 페이지 내용을 보여 주고, 확장 버튼으로 다운로드 페이지 자체로 간다.
    // 틀(맨 위 줄)과 아래 조작부는 일반 곡과 같은 위젯이라 곡이 넘어가도 화면이 바뀌지 않는다.
    final savedId = track == null ? null : savedVideoIdOf(track.id);
    final savedHit = savedId == null
        ? null
        : context
              .watch<SavedVideosCubit>()
              .state
              .where((v) => v.id == savedId)
              .firstOrNull
              ?.hit;
    return Scaffold(
      backgroundColor: context.palette.background,
      body: track == null
          ? const AppBackground()
          : _shrinkForSheet(
              _layout(
                style,
                PlayerLayoutData(
                  track: track,
                  state: state,
                  vm: context.read<NowPlayingCubit>(),
                  showLyrics: _showLyrics,
                  onToggleLyrics: () =>
                      playerShowLyrics.value = !playerShowLyrics.value,
                ),
                savedHit: savedHit,
              ),
            ),
    );
  }

  /// 플레이어 테마 시트가 떠 있으면 화면 전체를 시트 위 빈 곳에 맞게 줄여 보여준다.
  Widget _shrinkForSheet(Widget child) => LayoutBuilder(
    builder: (context, c) => ValueListenableBuilder<double>(
      valueListenable: playerStyleSheetHeight,
      builder: (context, sheet, _) => AnimatedScale(
        scale: c.maxHeight > 0
            ? ((c.maxHeight - sheet) / c.maxHeight).clamp(.5, 1.0)
            : 1,
        alignment: Alignment.topCenter,
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        child: child,
      ),
    ),
  );

  Widget _layout(
    PlayerStyle style,
    PlayerLayoutData data, {
    MediaHit? savedHit,
  }) {
    if (savedHit != null) {
      return _SavedPlayerHost(
        key: ValueKey(savedHit.id),
        data: data,
        hit: savedHit,
        expandTooltip: context.l10n.mediaDetailTitle,
        onExpand: () => unawaited(showMediaDetail(context, savedHit)),
      );
    }
    return _styled(style, data);
  }

  Widget _styled(PlayerStyle style, PlayerLayoutData data) => switch (style) {
    PlayerStyle.square => SquarePlayer(data: data),
    PlayerStyle.fullBleed => FullBleedPlayer(data: data),
    PlayerStyle.arc => ArcPlayer(data: data),
  };
}

/// 임시 저장한 곡 플레이어: 정보를 펼쳤는지를 쥐고, 가운데 내용([_SavedDetailPanel])과 그 아래 펼치기 줄을 이어 준다.
class _SavedPlayerHost extends StatefulWidget {
  const _SavedPlayerHost({
    super.key,
    required this.data,
    required this.hit,
    required this.expandTooltip,
    required this.onExpand,
  });

  final PlayerLayoutData data;
  final MediaHit hit;
  final String expandTooltip;
  final VoidCallback onExpand;

  @override
  State<_SavedPlayerHost> createState() => _SavedPlayerHostState();
}

class _SavedPlayerHostState extends State<_SavedPlayerHost> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return SavedPlayer(
      data: widget.data,
      // 상세 화면 조각을 조합한다: 처음엔 영상 · 썸네일만, 펼치면 정보와 한 스크롤.
      panel: MediaDetailScope(
        hit: widget.hit,
        builder: (_) => _SavedDetailPanel(open: _open),
      ),
      expandTooltip: widget.expandTooltip,
      onExpand: widget.onExpand,
      // 다운로드 상세로 가는 확장 버튼 바로 아래에 둔다.
      belowExpand: _InfoToggleTile(
        open: _open,
        onTap: () => setState(() => _open = !_open),
      ),
    );
  }
}

/// 가운데 내용: 처음에는 일반 곡처럼 썸네일 · 영상만 크게 보이고, 펼치면 고정이 풀려 영상 · 썸네일과 정보가 한 스크롤이 된다.
class _SavedDetailPanel extends StatelessWidget {
  const _SavedDetailPanel({required this.open});

  final bool open;

  /// 펼쳤을 때 목록 끝이 아래 줄 쪽으로 서서히 사라지는 높이.
  static const _fade = 32.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (!open) {
      // 낮은 화면에서도 영상 · 썸네일이 넘치지 않게 남은 높이에 맞춘다.
      return LayoutBuilder(
        builder: (context, box) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: MediaDetailMedia(maxHeight: box.maxHeight),
          ),
        ),
      );
    }
    // 어떤 배경과도 어울리도록 바탕색을 깔지 않고, 내용이 아래로 서서히 사라지게 한다.
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          p.background,
          p.background,
          p.background.withValues(alpha: 0),
        ],
        stops: [0, (1 - _fade / rect.height).clamp(0, 1), 1],
      ).createShader(rect),
      child: const MediaDetailInfo(
        header: MediaDetailMedia(),
        bottomInset: _fade,
      ),
    );
  }
}

/// 정보 펼치기 줄: 가로로 꽉 차는 눌림 영역에 가운데 화살표 + "정보".
class _InfoToggleTile extends StatelessWidget {
  const _InfoToggleTile({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      key: const ValueKey('saved-info-toggle'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              open ? AppIcons.chevronUp : AppIcons.chevronDown,
              size: AppSizes.iconSm,
              color: p.onSurfaceMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              context.l10n.mediaDetailSectionInfo,
              style: text.labelLarge?.copyWith(color: p.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}
