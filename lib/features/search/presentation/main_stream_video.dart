import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../player/presentation/bloc/now_playing_cubit.dart';
import '../../player/presentation/bloc/video_surface_cubit.dart';
import '../domain/usecases/search_usecases.dart';

/// 소리만 저장한 곡을 메인으로 듣는 중에 사용자가 영상 재생을 눌러 스트림 영상을 켰다.
/// 상세 화면을 나가도 영상이 이어지고 미니 플레이어가 영상을 보여 주도록, 화면 바깥에 둔다.
/// 켠 곡의 id는 [mainStreamVideoTrack]에 있고, 다른 곡으로 넘어가면 둘 다 비운다.
final mainStreamVideoTrack = ValueNotifier<String?>(null);

/// 스트림 영상이 켜져 있는가 (미니 플레이어는 이것만 보고 영상을 보여 준다).
final mainStreamVideoOn = ValueNotifier<bool>(false);

/// 켠 뒤로 영상이 한 번이라도 화면에 나왔는가. 켜는 중에 영상 화면이 새로 붙으며 잠깐 "준비 안 됨"이 되는 것을
/// 영상이 끊긴 것으로 오해해 바로 끄지 않게 한다 (그러면 한 번 더 눌러야 켜진다).
var _streamVideoShown = false;

/// 스트림 영상을 켠다 (소리만 저장한 곡 [trackId]).
void startMainStreamVideo(String trackId) {
  _streamVideoShown = false;
  mainStreamVideoTrack.value = trackId;
  mainStreamVideoOn.value = true;
}

/// 영상이 켜진 곡에서 다른 곡으로 넘어가면 영상을 멈추고 상태를 비운다.
class MainStreamVideoGuard extends StatelessWidget {
  const MainStreamVideoGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NowPlayingCubit, NowPlayingState>(
          listenWhen: (a, b) => a.track?.id != b.track?.id,
          listener: (context, state) {
            final on = mainStreamVideoTrack.value;
            if (on == null || on == state.track?.id) return;
            stopMainStreamVideo();
          },
        ),
        // 영상이 나오다가 끊기면(네트워크가 끊겨 네이티브가 영상을 내렸다) 저장해 둔 소리만 이어서 듣는다.
        BlocListener<VideoSurfaceCubit, VideoSurfaceState>(
          listenWhen: (a, b) => a.ready != b.ready,
          listener: (context, state) {
            if (!mainStreamVideoOn.value) return;
            if (state.ready) {
              _streamVideoShown = true;
            } else if (_streamVideoShown) {
              stopMainStreamVideo();
            }
          },
        ),
      ],
      child: child,
    );
  }
}

/// 스트림 영상을 끈다: 소리(저장해 둔 데이터)는 그대로 이어지고, 화면은 썸네일 · 재생 버튼으로 돌아간다.
void stopMainStreamVideo() {
  _streamVideoShown = false;
  mainStreamVideoTrack.value = null;
  mainStreamVideoOn.value = false;
  sl<PlayMainVideo>()(null).catchError((Object _) {});
}
