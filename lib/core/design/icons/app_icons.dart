import 'package:flutter/widgets.dart';

/// 앱 전체 아이콘의 단일 매핑. 화면 · 컴포넌트는 `Icons.xxx`를 직접 쓰지 않고 여기서만 가져온다.
///
/// 글리프는 Phosphor(MIT, `assets/fonts/phosphor/`)의 둥글고 부드러운 선 아이콘이다.
/// 재생 컨트롤 · 선택 상태처럼 면이 필요한 곳만 채움(Fill)을 쓴다.
/// 아이콘 세트를 바꾸거나 직접 그린 아이콘으로 교체할 때는 이 파일(과 폰트)만 고친다.
abstract final class AppIcons {
  /// 안쪽으로 모이는 두 화살표: 플로팅 버튼을 미니 플레이어 띠로 접어 넣는다.
  static const IconData dockDown = IconData(
    0xe09e,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData play = IconData(
    0xe3d0,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData back = IconData(
    0xe058,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData more = IconData(
    0xe208,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData close = IconData(
    0xe4f6,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData check = IconData(
    0xe182,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData pause = IconData(
    0xe39e,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData delete = IconData(
    0xe4a6,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData chevronRight = IconData(
    0xe13a,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData shuffle = IconData(
    0xe422,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData edit = IconData(
    0xe3b4,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData queue = IconData(
    0xe6ac,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData musicNote = IconData(
    0xe33c,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData chevronDown = IconData(
    0xe136,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData sparkle = IconData(
    0xe6a2,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData album = IconData(
    0xecac,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData playlistAdd = IconData(
    0xe2f8,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData person = IconData(
    0xe4c2,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData library = IconData(
    0xe340,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData equalizer = IconData(
    0xe802,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData favorite = IconData(
    0xe2a8,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData add = IconData(
    0xe3d4,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData explore = IconData(
    0xe1c8,
    fontFamily: 'PhosphorRegular',
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
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData radioOff = IconData(
    0xe18a,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData photoLibrary = IconData(
    0xe2ca,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData fingerprint = IconData(
    0xe23e,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData favoriteOutline = IconData(
    0xe2a8,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData folderUpload = IconData(
    0xe25e,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData download = IconData(
    0xe20c,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData checkCircle = IconData(
    0xe184,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData category = IconData(
    0xe464,
    fontFamily: 'PhosphorRegular',
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
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData undo = IconData(
    0xe038,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData tune = IconData(
    0xe434,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData tuneOutline = IconData(
    0xe434,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData touch = IconData(
    0xec90,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData timerOff = IconData(
    0xe492,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData style = IconData(
    0xe6c8,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData sort = IconData(
    0xe444,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData searchOutline = IconData(
    0xe30c,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData restart = IconData(
    0xe038,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData replay = IconData(
    0xe036,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData replay10 = IconData(
    0xe1a0,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData repeat = IconData(
    0xe3f6,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData repeatOne = IconData(
    0xe3f8,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData queueOutline = IconData(
    0xe6ac,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData globe = IconData(
    0xe288,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData playlistRemove = IconData(
    0xe2f4,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData playlistPlay = IconData(
    0xe6aa,
    fontFamily: 'PhosphorRegular',
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
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData lock = IconData(
    0xe308,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData link = IconData(
    0xe2e2,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData libraryOutline = IconData(
    0xe340,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData leaderboard = IconData(
    0xe150,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData chevronUp = IconData(
    0xe13c,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData hourglassTop = IconData(
    0xe2b4,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData hourglassEmpty = IconData(
    0xe2b2,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData home = IconData(
    0xe2c2,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData homeOutline = IconData(
    0xe2c2,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData headphones = IconData(
    0xe2a6,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData fullscreen = IconData(
    0xe0a2,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData forward10 = IconData(
    0xe19e,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData lineSpacing = IconData(
    0xe5a2,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData folder = IconData(
    0xe25a,
    fontFamily: 'PhosphorFill',
    matchTextDirection: true,
  );
  static const IconData folderOpen = IconData(
    0xe256,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData fileOpen = IconData(
    0xe230,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData expandMore = IconData(
    0xe136,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData expandLess = IconData(
    0xe13c,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData event = IconData(
    0xe10a,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData eq = IconData(
    0xebbc,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData deleteAll = IconData(
    0xe4a8,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData usage = IconData(
    0xe158,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData square = IconData(
    0xe45e,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData newFolder = IconData(
    0xe25e,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData calendar = IconData(
    0xe108,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData sleepOutline = IconData(
    0xe330,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData backspace = IconData(
    0xe0ae,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData timer = IconData(
    0xe492,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData refresh = IconData(
    0xe094,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData paste = IconData(
    0xe196,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData info = IconData(
    0xe2ce,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
  static const IconData openInNew = IconData(
    0xe5de,
    fontFamily: 'PhosphorRegular',
    matchTextDirection: true,
  );
}
