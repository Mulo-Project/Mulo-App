import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/track_menu.dart';
import '../../../lyrics/presentation/screens/lyrics_full_screen.dart';
import '../../../lyrics/presentation/widgets/lyrics_view.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../bloc/now_playing_cubit.dart';
import 'player_seek.dart';
import 'player_sleep_timer.dart';

export 'player_morph_seek.dart';
export 'player_seek.dart';
export 'player_sleep_timer.dart';

/// 플레이어 화면 하나를 그리는 데 필요한 값. 모양마다 이 값으로 배치만 다르게 한다.
class PlayerLayoutData {
  const PlayerLayoutData({
    required this.track,
    required this.state,
    required this.vm,
    required this.showLyrics,
    required this.onToggleLyrics,
  });

  final Track track;
  final NowPlayingState state;
  final NowPlayingCubit vm;
  final bool showLyrics;
  final VoidCallback onToggleLyrics;
}

/// 재생 위치(와 곡)가 바뀔 때만 다시 그리는 구역. 위치는 1초에 여러 번 바뀌므로 진행 막대 · 시간처럼
/// 위치를 쓰는 곳만 이것으로 감싸고, 나머지 플레이어 화면은 위치가 바뀌어도 다시 그리지 않는다.
class PositionBuilder extends StatelessWidget {
  const PositionBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, NowPlayingState state) builder;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NowPlayingCubit, NowPlayingState>(
        buildWhen: (a, b) =>
            a.position != b.position ||
            a.track != b.track ||
            a.loopStart != b.loopStart ||
            a.loopEnd != b.loopEnd,
        builder: builder,
      );
}

/// 지금 곡의 커버 이미지 · 색. 배경 그라데이션도 여기서 뽑는다.
class PlayerArt {
  const PlayerArt({
    required this.image,
    required this.tone,
    required this.color,
    required this.glow,
  });

  factory PlayerArt.of(BuildContext context, Track track) {
    final key = CoverKey.track(track.id);
    final tone = toneFor(track.id);
    final color = coverColorOf(context, key);
    return PlayerArt(
      image: coverImageOf(context, key),
      tone: tone,
      color: color,
      glow: color != null ? glowFromColor(color) : context.tokens.glow(tone),
    );
  }

  final ImageProvider? image;
  final GlowTone tone;
  final Color? color;

  /// 밝은 → 어두운 3색.
  final List<Color> glow;
}

/// 플레이어 바탕: 커버(또는 테마) 색이 위에서 배경색으로 스며드는 그라데이션.
/// [blurred]면 커버 이미지를 흐리게 깔아 쓴다 (이미지가 없으면 더 진한 그라데이션).
class PlayerBackdrop extends StatelessWidget {
  const PlayerBackdrop({
    super.key,
    required this.art,
    required this.child,
    this.blurred = false,
  });

  final PlayerArt art;
  final bool blurred;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final image = blurred ? art.image : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.background),
        if (image != null) ...[
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: Image(image: image, fit: BoxFit.cover),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  p.background.withValues(alpha: .45),
                  p.background.withValues(alpha: .78),
                  p.background,
                ],
                stops: const [0, .6, 1],
              ),
            ),
          ),
        ] else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  art.glow[1].withValues(alpha: .9),
                  Color.lerp(art.glow[2], p.background, .35)!,
                  p.background,
                ],
                stops: const [0, .55, 1],
              ),
            ),
          ),
        child,
      ],
    );
  }
}

/// 맨 위 줄: 내리기 · 제목 · (더 보기).
class PlayerTopBar extends StatelessWidget {
  const PlayerTopBar({super.key, required this.track, this.showMore = true});

  final Track track;
  final bool showMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppTopBar(
      title: l10n.playerNowPlaying,
      leading: CircleIconButton(
        icon: AppIcons.chevronDown,
        tooltip: l10n.actionBack,
        onPressed: () => context.pop(),
      ),
      actions: [if (showMore) PlayerMoreButton(track: track)],
    );
  }
}

/// 곡 메뉴 (보관함 곡 목록의 ⋮ 와 같은 메뉴).
class PlayerMoreButton extends StatelessWidget {
  const PlayerMoreButton({super.key, required this.track, this.circle = true});

  final Track track;

  /// false면 유리 버튼 대신 맨 아이콘.
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Builder(
      builder: (btn) => circle
          ? CircleIconButton(
              icon: AppIcons.more,
              tooltip: l10n.trackMenuTitle,
              onPressed: () => showTrackMenu(btn, track, inPlayer: true),
            )
          : IconButton(
              tooltip: l10n.trackMenuTitle,
              onPressed: () => showTrackMenu(btn, track, inPlayer: true),
              icon: Icon(AppIcons.more, color: context.palette.onSurface),
            ),
    );
  }
}

/// 곡 제목 한 줄 (칸을 넘치면 흐른다).
class PlayerTitleText extends StatelessWidget {
  const PlayerTitleText({
    super.key,
    required this.track,
    this.center = false,
    this.large = true,
  });

  final Track track;
  final bool center;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MarqueeText(
      track.title,
      style: (large ? text.headlineSmall : text.titleMedium)?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
  }
}

/// 아티스트(· 앨범) 한 줄.
class PlayerSubtitleText extends StatelessWidget {
  const PlayerSubtitleText({
    super.key,
    required this.track,
    this.center = false,
    this.large = true,
    this.withAlbum = true,
  });

  final Track track;
  final bool center;
  final bool large;
  final bool withAlbum;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Text(
      [
        track.artist.isEmpty ? l10n.unknownArtist : track.artist,
        if (withAlbum && track.album.isNotEmpty) track.album,
      ].join(' · '),
      style: (large ? text.bodyLarge : text.bodySmall)?.copyWith(
        color: p.onSurface.withValues(alpha: .66),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
  }
}

/// 커버 이미지가 있으면 사진, 없으면 테마 색 그라데이션 + 음표.
class PlayerCover extends StatelessWidget {
  const PlayerCover({
    super.key,
    required this.art,
    this.radius = AppRadii.lg,
    this.icon = true,
    this.video,
  });

  final PlayerArt art;

  /// 영상 곡이면 커버 위에 얹는 영상 화면.
  final Widget? video;
  final double radius;

  /// 이미지가 없을 때 가운데 음표를 그릴지.
  final bool icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cover = CoverCard(
      radius: radius,
      image: art.image,
      tone: art.tone,
      color: art.color,
      child: art.image != null || !icon
          ? null
          : LayoutBuilder(
              builder: (context, c) => Center(
                child: Icon(
                  AppIcons.musicNote,
                  size: math.min(c.maxWidth, c.maxHeight) * .34,
                  color: p.onGlow.withValues(alpha: .85),
                ),
              ),
            ),
    );
    final v = video;
    if (v == null) return cover;
    return Stack(
      fit: StackFit.expand,
      children: [
        cover,
        ClipRRect(borderRadius: BorderRadius.circular(radius), child: v),
      ],
    );
  }
}

/// 가사 보기: 커버 자리를 가사가 대신한다.
///
/// 플레이어 화면은 재생 위치가 바뀔 때마다(0.25초) 통째로 다시 그려진다. 같은 곡 · 같은 언어면
/// 가사 보기 위젯을 그대로 돌려줘서 그 틱마다 가사 전체를 다시 만들지 않는다
/// (가사 보기는 지금 줄이 바뀔 때만 스스로 다시 그린다).
class PlayerLyricsPane extends StatefulWidget {
  const PlayerLyricsPane({super.key, required this.track});

  final Track track;

  @override
  State<PlayerLyricsPane> createState() => _PlayerLyricsPaneState();
}

class _PlayerLyricsPaneState extends State<PlayerLyricsPane> {
  Widget? _view;
  Track? _viewTrack;
  Locale? _viewLocale;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (_view == null || _viewTrack != widget.track || _viewLocale != locale) {
      _viewTrack = widget.track;
      _viewLocale = locale;
      _view = Stack(
        children: [
          LyricsView(track: widget.track),
          // 가사만 크게 보기.
          Positioned(
            top: 0,
            right: 0,
            child: CircleIconButton(
              icon: AppIcons.fullscreen,
              tooltip: context.l10n.playerLyricsExpand,
              size: AppSizes.circleButton * .8,
              onPressed: () => LyricsFullScreen.open(this.context),
            ),
          ),
        ],
      );
    }
    return _view!;
  }
}

/// 좋아요 하트: 좋아요 목록에 넣고 뺀다.
class PlayerLikeButton extends StatelessWidget {
  const PlayerLikeButton({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final cubit = context.read<PlaylistsCubit>();
    return BlocBuilder<PlaylistsCubit, List<Playlist>>(
      builder: (context, _) {
        final on = cubit.isFavorite(trackId);
        // 같은 줄의 가사 · 대기열 버튼과 같은 크기 (줄의 IconButtonTheme을 따른다).
        return IconButton(
          tooltip: on ? l10n.trackMenuUnfavorite : l10n.trackMenuFavorite,
          onPressed: () => cubit.toggleFavorite(trackId),
          icon: Icon(
            on ? AppIcons.favorite : AppIcons.favoriteOutline,
            color: on ? p.accent : p.onSurfaceMuted,
          ),
        );
      },
    );
  }
}

/// 가사 보기 ↔ 커버 보기.
class LyricsToggleButton extends StatelessWidget {
  const LyricsToggleButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return IconButton(
      tooltip: data.showLyrics ? l10n.playerShowCover : l10n.playerShowLyrics,
      onPressed: data.onToggleLyrics,
      icon: Icon(
        data.showLyrics ? AppIcons.album : AppIcons.lyrics,
        color: data.showLyrics ? p.accent : p.onSurfaceMuted,
      ),
    );
  }
}

/// 재생 대기열 화면 열기.
class QueueButton extends StatelessWidget {
  const QueueButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.playerQueue,
    onPressed: () => context.push(Routes.queue),
    icon: Icon(AppIcons.queue, color: context.palette.onSurfaceMuted),
  );
}

/// 셔플 토글.
class ShuffleButton extends StatelessWidget {
  const ShuffleButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.actionShuffle,
    onPressed: data.vm.toggleShuffle,
    icon: Icon(
      AppIcons.shuffle,
      color: data.state.shuffle
          ? context.palette.accent
          : context.palette.onSurfaceMuted,
    ),
  );
}

/// 반복 (끔 → 전체 → 한 곡).
class RepeatButton extends StatelessWidget {
  const RepeatButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final repeat = data.state.repeat;
    return IconButton(
      tooltip: context.l10n.playerRepeat,
      onPressed: data.vm.cycleRepeat,
      icon: Icon(
        repeat == PlayerRepeatMode.one ? AppIcons.repeatOne : AppIcons.repeat,
        color: repeat != PlayerRepeatMode.off ? p.accent : p.onSurfaceMuted,
      ),
    );
  }
}

/// 구간(A-B) 반복: 누를 때마다 지금 위치를 시작 → 끝으로 정하고(그 뒤로 구간만 반복), 한 번 더 누르면 해제.
/// 시작만 정했을 때는 "A 01:05", 구간이 걸리면 "A-B 01:05-02:10"을 옆에 보여 준다.
class LoopRangeButton extends StatelessWidget {
  const LoopRangeButton({super.key, required this.data});

  final PlayerLayoutData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final s = data.state;
    final active = s.loopStart != null;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: active ? p.accent : p.onSurfaceMuted,
      fontWeight: FontWeight.w700,
    );
    final label = s.looping
        ? 'A-B ${TimeText.clock(s.loopStart!)}-${TimeText.clock(s.loopEnd!)}'
        : active
        ? 'A ${TimeText.clock(s.loopStart!)}'
        : 'A-B';
    return IconButton(
      tooltip: s.looping
          ? l10n.playerLoopClear
          : active
          ? l10n.playerLoopSetEnd
          : l10n.playerLoopSetStart,
      onPressed: data.vm.cycleLoop,
      icon: Text(label, style: style, maxLines: 1),
    );
  }
}

/// 이전 · 다음 (맨 아이콘).
class SkipButton extends StatelessWidget {
  const SkipButton({
    super.key,
    required this.data,
    required this.next,
    this.color,
  });

  final PlayerLayoutData data;
  final bool next;

  /// 아이콘 색 (없으면 테마 글자색).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      iconSize: 40,
      tooltip: next ? l10n.actionNext : l10n.actionPrevious,
      onPressed: next ? data.vm.next : data.vm.previous,
      icon: Icon(
        next ? AppIcons.skipNext : AppIcons.skipPrevious,
        color: color ?? context.palette.onSurface,
      ),
    );
  }
}

/// 흰(테마 글자색) 원 재생 버튼.
class SolidPlayButton extends StatelessWidget {
  const SolidPlayButton({
    super.key,
    required this.data,
    this.size = 68,
    this.onPressed,
    this.playing,
  });

  final PlayerLayoutData data;
  final double size;

  /// 누를 때의 동작 (없으면 재생 · 일시정지). 임시 저장 곡 상세에서 아직 안 틀었을 때 "재생 시작"에 쓴다.
  final VoidCallback? onPressed;

  /// 재생 중 모양 (없으면 지금 재생 상태를 따른다).
  final bool? playing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final playing = this.playing ?? data.state.isPlaying;
    return Tooltip(
      message: playing ? l10n.actionPause : l10n.actionPlay,
      child: Material(
        color: p.onSurface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? data.vm.togglePlay,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              playing ? AppIcons.pause : AppIcons.play,
              size: size * .52,
              color: p.background,
            ),
          ),
        ),
      ),
    );
  }
}

/// 10초 뒤로 · 앞으로.
class SeekStepButton extends StatelessWidget {
  const SeekStepButton({
    super.key,
    required this.data,
    required this.forward,
    this.color,
  });

  final PlayerLayoutData data;
  final bool forward;

  /// 아이콘 색 (없으면 테마 글자색).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const step = Duration(seconds: 10);
    return IconButton(
      iconSize: 24,
      tooltip: forward ? l10n.playerForward10 : l10n.playerRewind10,
      // 누른 순간의 위치에서 옮긴다 (화면은 위치가 바뀌어도 다시 그리지 않으므로 지금 값을 읽는다).
      onPressed: () {
        final now = data.vm.state.position;
        data.vm.seekTo(forward ? now + step : now - step);
      },
      icon: Icon(
        forward ? AppIcons.forward10 : AppIcons.replay10,
        color: color ?? context.palette.onSurfaceMuted,
      ),
    );
  }
}

/// 재생목록에 추가 (재생목록 고르기 화면으로 간다).
class AddToPlaylistButton extends StatelessWidget {
  const AddToPlaylistButton({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.trackMenuAddToPlaylist,
    onPressed: () => context.push(Routes.playlistPick, extra: [trackId]),
    icon: Icon(AppIcons.playlistAdd, color: context.palette.onSurfaceMuted),
  );
}

/// 이퀄라이저 화면으로 간다 (플레이어 위로 덮어 열고, 뒤로 가면 플레이어로 돌아온다).
class EqualizerButton extends StatelessWidget {
  const EqualizerButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.playerEqualizer,
    onPressed: () => context.push(Routes.equalizer),
    icon: Icon(AppIcons.eq, color: context.palette.onSurfaceMuted),
  );
}

/// 모든 모양이 같이 쓰는 하단 조작부 (위에서 아래로):
/// 1) 제목 (한 줄) / 아티스트 + 가사/커버 · 현재 재생목록(대기열) · 좋아요 (같은 줄)
/// 2) 진행 막대 (총 시간은 위, 현재 시간은 손잡이 아래 둥근 삼각형 상자)
/// 3) 10초 뒤로 · 이전 · 재생 · 다음 · 10초 앞으로
/// 4) 셔플 · 반복 (왼쪽), 수면 타이머 · 이퀄라이저 (오른쪽)
///
/// [seekBar]가 false면 진행 막대는 커버 쪽(호, [MorphSeek])에 있어 2번 줄은 없다.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.data,
    required this.play,
    this.seekBar = true,
    this.savedMode = false,
  });

  final PlayerLayoutData data;
  final Widget play;
  final bool seekBar;

  /// 임시 저장한 음원 상세에서 쓰는 모양: 제목 줄(제목 · 가사 · 좋아요)은 위 상세 화면이 대신하므로 빼고,
  /// 싱크 · 좋아요처럼 파일 곡에서만 되는 버튼은 숨긴다. 대기열 버튼은 아래 줄로 옮긴다.
  final bool savedMode;

  @override
  Widget build(BuildContext context) {
    // 조작부가 화면 높이의 3분의 1을 넘지 않게 한다 (낮은 화면 · 큰 글자에서는 그만큼 줄여 그린다).
    final cap = MediaQuery.sizeOf(context).height / 3;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: cap),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: _content(context),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!savedMode) ...[
            // 제목은 위 한 줄에 혼자 두고(길면 흐른다), 버튼은 아티스트 줄 가운데에 맞춘다.
            Align(
              alignment: Alignment.centerLeft,
              child: PlayerTitleText(track: data.track),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: PlayerSubtitleText(
                    track: data.track,
                    withAlbum: false,
                  ),
                ),
                IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      iconSize: 20,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LyricsToggleButton(data: data),
                      const QueueButton(),
                      PlayerLikeButton(trackId: data.track.id),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (seekBar) ...[
            // 제목 묶음 → 진행 막대 → 재생 조작 → 보조 조작 순으로 틈을 둔다.
            if (!savedMode) const SizedBox(height: AppSpacing.sm),
            PositionBuilder(
              builder: (context, state) => PlayerSeekBar(
                progress: state.progress,
                onSeek: data.vm.seekFraction,
                onSeekStart: data.vm.beginScrub,
                onSeekEnd: data.vm.endScrub,
                position: state.position,
                total: data.track.duration,
                loopStart: state.loopStart,
                loopEnd: state.loopEnd,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SeekStepButton(data: data, forward: false),
              SkipButton(data: data, next: false),
              play,
              SkipButton(data: data, next: true),
              SeekStepButton(data: data, forward: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // 보조 조작(셔플 · 반복 · 수면 · 이퀄라이저)은 재생 조작보다 작게 두어 대비를 준다.
          IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(36, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            child: Row(
              children: [
                ShuffleButton(data: data),
                RepeatButton(data: data),
                if (!savedMode) LoopRangeButton(data: data),
                const Spacer(),
                SleepTimerButton(data: data),
                const EqualizerButton(),
                if (savedMode) const QueueButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
