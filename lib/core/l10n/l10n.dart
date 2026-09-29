import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  /// 현재 언어 문구. 화면 문자열은 모두 ARB(lib/l10n)에서 가져온다.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
