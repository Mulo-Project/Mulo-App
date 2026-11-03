import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/repositories/track_tag_repository.dart';

/// 가사를 음원 파일 태그에 쓴 결과를 알린다. 파일에 쓰지 못했으면(앱 데이터를 지우면 가사가 사라진다) 이유와 함께 안내한다.
/// 쓰려 하지 않았거나(null) 썼으면 아무것도 보이지 않는다.
void showLyricsTagNotice(BuildContext context, TagWriteResult? result) {
  if (result == null || result == TagWriteResult.written) return;
  final l10n = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.lyricsTagNotSaved(result.name))),
  );
}
