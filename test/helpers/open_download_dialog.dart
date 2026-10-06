import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/presentation/widgets/download_dialog.dart';

/// 검색 결과가 아직 없으므로(다운로드 엔진 연결 전) 받기 팝업을 직접 연다.
Future<void> openDownloadDialog(
  WidgetTester tester, {
  String title = 'Song',
  String? thumbnailUrl,
}) async {
  final context = tester.element(find.byType(Scaffold).first);
  showDownloadDialog(context, title: title, thumbnailUrl: thumbnailUrl);
  await tester.pumpAndSettle();
}
