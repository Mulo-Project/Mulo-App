import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../player/presentation/widgets/player_common.dart';
import '../widgets/lyrics_view.dart';

/// 가사만 크게 보는 화면: 커버 · 재생 조작 없이 가사와 닫기 버튼만 둔다.
/// 재생은 그대로 이어지고, 곡이 넘어가면 가사도 따라 바뀐다.
class LyricsFullScreen extends StatelessWidget {
  const LyricsFullScreen({super.key});

  /// 현재 화면 위에 부드럽게 겹쳐 연다.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: true,
          transitionDuration: AppMotion.medium,
          reverseTransitionDuration: AppMotion.medium,
          pageBuilder: (_, _, _) => const LyricsFullScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final track = context.select((NowPlayingCubit c) => c.state.track);
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
    return Scaffold(
      backgroundColor: context.palette.background,
      body: track == null
          ? const AppBackground()
          : _Backdrop(
              track: track,
              child: SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xxl + AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: LyricsView(track: track, followTop: 0),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.md,
                      child: CircleIconButton(
                        icon: AppIcons.close,
                        tooltip: context.l10n.playerLyricsCollapse,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// 영상 곡이면 가사 뒤에 흐린 영상이 움직인다 (영상이 아니면 평소 배경 그대로).
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.track, required this.child});

  final Track track;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!track.isVideo) return child;
    return PlayerBackdrop(
      art: PlayerArt.of(context, track),
      blurred: true,
      video: true,
      child: child,
    );
  }
}
