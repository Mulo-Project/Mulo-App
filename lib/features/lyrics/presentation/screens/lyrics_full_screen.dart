import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
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
    final track = context.watch<NowPlayingCubit>().state.track;
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
          : SafeArea(
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
    );
  }
}
