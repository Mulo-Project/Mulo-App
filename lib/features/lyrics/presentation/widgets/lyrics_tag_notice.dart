import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/repositories/track_tag_repository.dart';
import '../../domain/usecases/lyrics_usecases.dart';

/// 가사를 음원 파일 태그에 쓴 결과를 알린다. 파일에 쓰지 못했으면(앱 데이터를 지우면 가사가 사라진다) 짧게 안내한다.
/// 자세한 이유는 debug 빌드에서만 문구에 붙이고 로그(`MuloTag`)에도 남긴다.
/// 쓰려 하지 않았거나(null) 썼으면 아무것도 보이지 않는다.
void showLyricsTagNotice(BuildContext context, LyricsTagOutcome? outcome) {
  if (outcome == null || outcome.result == TagWriteResult.written) return;
  final detail = outcome.detail;
  final reason = detail == null || detail.isEmpty
      ? outcome.result.name
      : '${outcome.result.name}: ${detail.length > 220 ? detail.substring(0, 220) : detail}';
  debugPrint('MuloTag lyrics tag not saved: $reason');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 10),
      content: Text(
        kDebugMode
            ? '${context.l10n.lyricsTagNotSaved}\n[debug] $reason'
            : context.l10n.lyricsTagNotSaved,
      ),
    ),
  );
}
