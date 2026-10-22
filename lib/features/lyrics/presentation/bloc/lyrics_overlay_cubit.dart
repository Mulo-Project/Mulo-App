import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/usecases/lyrics_overlay_usecases.dart';

/// 떠 있는 가사 창에 지금 곡의 가사를 올리고 내린다. 화면이 없고 상태도 없다:
/// 바뀐 것(켜짐 · 곡 · 가사)만 골라 네이티브에 보낸다.
class LyricsOverlayCubit extends Cubit<void> {
  LyricsOverlayCubit({
    required this._canDraw,
    required this._openPermission,
    required this._show,
    required this._hide,
    required this._watchClosed,
  }) : super(null);

  final CanDrawLyricsOverlay _canDraw;
  final OpenLyricsOverlayPermission _openPermission;
  final ShowLyricsOverlay _show;
  final HideLyricsOverlay _hide;
  final WatchLyricsOverlayClosed _watchClosed;

  /// 창의 닫기(✕)를 눌렀다 (설정을 끄라는 뜻).
  Stream<void> get closed => _watchClosed(const NoParams());

  /// 권한이 있으면 true. 없으면 시스템 설정을 열고 false (돌아와서 다시 켜면 된다).
  Future<bool> ensurePermission() async {
    if (await _canDraw(const NoParams())) return true;
    await _openPermission(const NoParams());
    return false;
  }

  String? _sent;

  /// [trackId]의 [lyrics]를 올린다. 꺼져 있거나 싱크 가사가 없으면 내린다.
  /// 같은 내용은 다시 보내지 않는다.
  Future<void> sync({
    required bool enabled,
    required String? trackId,
    required Lyrics? lyrics,
    String hideLabel = '',
    String offLabel = '',
    int accent = 0xFFFFFFFF,
  }) async {
    final show =
        enabled && trackId != null && lyrics != null && lyrics.isSynced;
    final key = show ? '$trackId|${lyrics.raw.hashCode}' : null;
    if (key == _sent) return;
    _sent = key;
    if (!show) {
      await _hide(const NoParams());
      return;
    }
    await _show(
      ShowLyricsOverlayParams(
        trackId,
        _merged(lyrics.lines),
        hideLabel: hideLabel,
        offLabel: offLabel,
        accent: accent,
      ),
    );
  }

  /// 같은 시간으로 묶인 줄(싱크 화면에서 한 칸으로 묶은 줄)은 한 줄로 합친다.
  static List<LyricLine> _merged(List<LyricLine> lines) {
    final out = <LyricLine>[];
    for (final l in lines) {
      if (out.isNotEmpty && out.last.time == l.time) {
        final text = [out.last.text, l.text].where((t) => t.isNotEmpty);
        out[out.length - 1] = LyricLine(l.time, text.join('\n'));
      } else {
        out.add(l);
      }
    }
    return out;
  }
}
