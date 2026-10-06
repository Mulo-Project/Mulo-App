import '../../../../l10n/app_localizations.dart';

/// 유튜브 분류 이름 → ARB select 키.
const _categoryKeys = {
  'Film & Animation': 'FilmAnimation',
  'Autos & Vehicles': 'Autos',
  'Music': 'Music',
  'Pets & Animals': 'Pets',
  'Sports': 'Sports',
  'Travel & Events': 'Travel',
  'Gaming': 'Gaming',
  'People & Blogs': 'People',
  'Comedy': 'Comedy',
  'Entertainment': 'Entertainment',
  'News & Politics': 'News',
  'Howto & Style': 'Howto',
  'Education': 'Education',
  'Science & Technology': 'Science',
  'Nonprofits & Activism': 'Nonprofits',
};

/// 유튜브 분류를 화면에 보일 이름으로. 모르는 분류는 원문 그대로.
String categoryLabel(AppLocalizations l10n, String name) =>
    l10n.videoCategory(_categoryKeys[name] ?? name);
