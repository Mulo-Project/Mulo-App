import 'dart:ui';

import '../../../../l10n/app_localizations.dart';

/// 알림 채널 이름처럼 화면(context) 없이 만들어야 하는 글자용: 기기 언어를 따르고
/// 지원하지 않는 언어는 한국어.
AppLocalizations systemL10n() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(code == 'en' ? 'en' : 'ko'));
}
