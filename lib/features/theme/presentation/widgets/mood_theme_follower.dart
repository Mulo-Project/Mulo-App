import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/theme_cubit.dart';

/// 설정의 "곡 분위기 따라가기": 켜져 있으면 재생 중인 곡의 색을 테마에 적용한다.
/// 곡에 직접 고른 색이 있으면 그 색, 없으면 커버 이미지에서 뽑은 색을 쓴다.
/// 색을 낼 단서가 없거나(커버 없음) 재생 곡이 없으면 고른 프리셋으로 돌아간다.
/// 앱 셸 한 곳에서 감싼다.
class MoodThemeFollower extends StatelessWidget {
  const MoodThemeFollower({super.key, required this.child});

  final Widget child;

  void _sync(BuildContext context) {
    final theme = context.read<ThemeCubit>();
    if (!theme.state.followMood) return;
    final track = context.read<NowPlayingCubit>().state.track;
    if (track == null) {
      theme.reset();
      return;
    }
    final key = CoverKey.track(track.id);
    final chosen = context.read<CoverColorCubit>().state[key];
    if (chosen != null) {
      theme.apply(
        MoodColorThemeSource(trackId: track.id, color: Color(chosen)),
      );
      return;
    }
    final art = context.read<CoverCubit>().state[key];
    if (art == null) {
      theme.reset();
      return;
    }
    theme.apply(
      MoodThemeSource(trackId: track.id, artwork: imageOfCoverArt(art)),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ThemeCubit, ThemeState>(
        listenWhen: (a, b) => a.followMood != b.followMood,
        listener: (context, _) => _sync(context),
      ),
      BlocListener<NowPlayingCubit, NowPlayingState>(
        listenWhen: (a, b) => a.track?.id != b.track?.id,
        listener: (context, _) => _sync(context),
      ),
      BlocListener<CoverColorCubit, Map<String, int>>(
        listener: (context, _) => _sync(context),
      ),
      BlocListener<CoverCubit, Map<String, CoverArt>>(
        listener: (context, _) => _sync(context),
      ),
    ],
    child: child,
  );
}
