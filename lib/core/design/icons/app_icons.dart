import 'package:flutter/widgets.dart';

/// 앱 전체 아이콘의 단일 매핑. 화면 · 컴포넌트는 `Icons.xxx`를 직접 쓰지 않고 여기서만 가져온다.
///
/// 글리프는 Phosphor Light(MIT, `assets/fonts/phosphor/`)의 둥글고 부드러운 선 아이콘이다.
/// 재생 컨트롤 · 선택 상태처럼 면이 필요한 곳만 채움(Fill)을 쓴다.
/// 아이콘 세트를 바꾸거나 직접 그린 아이콘으로 교체할 때는 이 파일(과 폰트)만 고친다.
abstract final class AppIcons {
  /// 바깥으로 펼쳐지는 두 화살표: 플로팅 버튼을 펼쳐 미니 플레이어로 되돌린다.
  static const IconData expandOut = IconData(
    0xe0a6,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData play = IconData(
    0xe3d0,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData back = IconData(
    0xe058,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData more = IconData(
    0xe208,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData close = IconData(
    0xe4f6,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData check = IconData(
    0xe182,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData pause = IconData(
    0xe39e,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData delete = IconData(
    0xe4a6,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData chevronRight = IconData(
    0xe13a,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData shuffle = IconData(
    0xe422,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData edit = IconData(
    0xe3b4,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData queue = IconData(
    0xe6ac,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData musicNote = IconData(
    0xe33c,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData chevronDown = IconData(
    0xe136,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData sparkle = IconData(
    0xe6a2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData album = IconData(
    0xecac,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData playlistAdd = IconData(
    0xe2f8,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData person = IconData(
    0xe4c2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData library = IconData(
    0xe340,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData equalizer = IconData(
    0xe802,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData favorite = IconData(
    0xe2a8,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData remove = IconData(
    0xe32a,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData add = IconData(
    0xe3d4,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData explore = IconData(
    0xe1c8,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData skipPrevious = IconData(
    0xe5a4,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData skipNext = IconData(
    0xe5a6,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData search = IconData(
    0xe30c,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData radioOff = IconData(
    0xe18a,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );

  /// 이미지가 없음을 나타내는 아이콘.
  static const IconData imageBroken = IconData(
    0xe7a8,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData arrowDown = IconData(
    0xe03e,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData arrowUp = IconData(
    0xe08e,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData photoLibrary = IconData(
    0xe2ca,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData fingerprint = IconData(
    0xe23e,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData favoriteOutline = IconData(
    0xe2a8,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData folderUpload = IconData(
    0xe25e,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData download = IconData(
    0xe20c,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData checkCircle = IconData(
    0xe184,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData category = IconData(
    0xe464,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData sleep = IconData(
    0xe330,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData dropDown = IconData(
    0xe136,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData dragHandle = IconData(
    0xe2f0,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData undo = IconData(
    0xe038,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData settings = IconData(
    0xe270,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData settingsOutline = IconData(
    0xe270,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData tune = IconData(
    0xe434,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData tuneOutline = IconData(
    0xe434,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData touch = IconData(
    0xec90,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData timerOff = IconData(
    0xe492,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData style = IconData(
    0xe6c8,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData sort = IconData(
    0xe444,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData searchOutline = IconData(
    0xe30c,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData restart = IconData(
    0xe038,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData replay = IconData(
    0xe036,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData replay10 = IconData(
    0xe1a0,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData repeat = IconData(
    0xe3f6,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData repeatOne = IconData(
    0xe3f8,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData queueOutline = IconData(
    0xe6ac,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData globe = IconData(
    0xe288,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData playlistRemove = IconData(
    0xe2f4,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData playlistPlay = IconData(
    0xe6aa,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData playCircle = IconData(
    0xe3d2,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData pauseCircle = IconData(
    0xe3a0,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData lyrics = IconData(
    0xe75c,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );

  /// 네트워크 연결이 끊겼을 때 (와이파이에 빗금).
  static const IconData wifiOff = IconData(
    0xe4f2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData lock = IconData(
    0xe308,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData link = IconData(
    0xe2e2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData libraryOutline = IconData(
    0xe340,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData leaderboard = IconData(
    0xe150,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData chevronUp = IconData(
    0xe13c,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData hourglassTop = IconData(
    0xe2b4,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData hourglassEmpty = IconData(
    0xe2b2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData home = IconData(
    0xe2c2,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData homeOutline = IconData(
    0xe2c2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData headphones = IconData(
    0xe2a6,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  /// 전체 화면 닫기(축소): 안쪽을 향한 네 모서리 화살표.
  static const IconData fullscreenExit = IconData(
    0xe09a,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData fullscreen = IconData(
    0xe0a2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData forward10 = IconData(
    0xe19e,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData lineSpacing = IconData(
    0xe5a2,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData folder = IconData(
    0xe25a,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData folderOpen = IconData(
    0xe256,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData fileOpen = IconData(
    0xe230,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData expandMore = IconData(
    0xe136,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData expandLess = IconData(
    0xe13c,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData event = IconData(
    0xe10a,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData eq = IconData(
    0xebbc,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData deleteAll = IconData(
    0xe4a8,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData usage = IconData(
    0xe158,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData square = IconData(
    0xe45e,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData newFolder = IconData(
    0xe25e,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData calendar = IconData(
    0xe108,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData sleepOutline = IconData(
    0xe330,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData backspace = IconData(
    0xe0ae,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData timer = IconData(
    0xe492,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData refresh = IconData(
    0xe094,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData paste = IconData(
    0xe196,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData info = IconData(
    0xe2ce,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
  static const IconData openInNew = IconData(
    0xe5de,
    fontFamily: 'PhosphorLight',
    matchTextDirection: true,
  );
}
