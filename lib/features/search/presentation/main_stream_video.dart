import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../player/presentation/bloc/now_playing_cubit.dart';
import '../domain/usecases/search_usecases.dart';

/// 소리만 저장한 곡을 메인으로 듣는 중에 사용자가 영상 재생을 눌러 스트림 영상을 켰다.
/// 상세 화면을 나가도 영상이 이어지고 미니 플레이어가 영상을 보여 주도록, 화면 바깥에 둔다.
/// 켠 곡의 id는 [mainStreamVideoTrack]에 있고, 다른 곡으로 넘어가면 둘 다 비운다.
final mainStreamVideoTrack = ValueNotifier<String?>(null);

/// 스트림 영상이 켜져 있는가 (미니 플레이어는 이것만 보고 영상을 보여 준다).
final mainStreamVideoOn = ValueNotifier<bool>(false);

/// 영상이 켜진 곡에서 다른 곡으로 넘어가면 영상을 멈추고 상태를 비운다.
class MainStreamVideoGuard extends StatelessWidget {
  const MainStreamVideoGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NowPlayingCubit, NowPlayingState>(
      listenWhen: (a, b) => a.track?.id != b.track?.id,
      listener: (context, state) {
        final on = mainStreamVideoTrack.value;
        if (on == null || on == state.track?.id) return;
        mainStreamVideoTrack.value = null;
        mainStreamVideoOn.value = false;
        sl<PlayMainVideo>()(null).catchError((Object _) {});
      },
      child: child,
    );
  }
}
