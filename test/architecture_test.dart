import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 클린 아키텍처 의존 규칙 검사 (D-019).
/// - domain은 순수 Dart: Flutter · 플러그인 · DB · 다른 계층을 가져오지 않는다.
/// - presentation은 data를 직접 가져오지 않는다 (유스케이스만 부른다).
void main() {
  List<File> dartFiles(String part) =>
      Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.replaceAll(r'\', '/').contains('/$part/'))
          .where((f) => f.path.endsWith('.dart'))
          .toList();

  Iterable<String> importsOf(File f) => RegExp(
    r"^import '([^']+)'",
    multiLine: true,
  ).allMatches(f.readAsStringSync()).map((m) => m.group(1)!);

  test('domain은 순수 Dart만 가져온다', () {
    const allowedPackages = ['package:equatable/'];
    final bad = <String>[];
    for (final f in dartFiles('domain')) {
      for (final imp in importsOf(f)) {
        final ok =
            imp.startsWith('dart:') && imp != 'dart:ui' ||
            allowedPackages.any(imp.startsWith) ||
            (!imp.startsWith('package:') &&
                !imp.contains('/data/') &&
                !imp.contains('/presentation/'));
        if (!ok) bad.add('${f.path}: $imp');
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('presentation은 data를 가져오지 않는다', () {
    final bad = [
      for (final f in dartFiles('presentation'))
        for (final imp in importsOf(f))
          if (imp.contains('/data/')) '${f.path}: $imp',
    ];
    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
