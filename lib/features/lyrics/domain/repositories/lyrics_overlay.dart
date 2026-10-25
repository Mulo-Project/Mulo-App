import '../entities/lyrics.dart';

/// 다른 앱 위에 떠 있는 가사 창 (Android). 켜고 끄는 설정은 [LyricsSettings.overlay].
abstract interface class LyricsOverlay {
  /// "다른 앱 위에 표시" 권한이 있는지 (창이 없는 OS는 false).
  Future<bool> canDraw();

  /// 시스템의 "다른 앱 위에 표시" 설정 화면을 연다.
  Future<void> openPermissionSettings();

  /// [trackId] 곡의 싱크 가사 [lines]를 창에 넘긴다. 창은 재생 위치에 맞춰 스스로 줄을 바꾼다.
  /// [lines]가 비어 있고 [emptyLabel]이 있으면 창을 내리지 않고 그 글(예: "가사가 없어요")만 보여 준다.
  /// [hideLabel] · [offLabel]은 창을 탭하면 나오는 버튼의 글자, [accent]는 칩 · 버튼에 입힐 강조색(ARGB).
  Future<void> show(
    String trackId,
    List<LyricLine> lines, {
    required String hideLabel,
    required String offLabel,
    required int accent,
    String emptyLabel = '',
  });

  /// 앱 안 플레이어에서 가사를 보고 있는지 알린다 (보고 있는 동안은 창이 겹치지 않게 숨긴다).
  Future<void> setLyricsViewShown(bool shown);

  /// 창의 닫기(✕)를 눌러 사용자가 껐다.
  Stream<void> watchClosed();

  /// 창에 올린 가사를 치운다.
  Future<void> hide();
}
