import '../../../../core/l10n/l10n.dart';

/// 들은 시간 글자: 1시간 이상이면 "2시간 5분", 아니면 "35분".
String formatListened(AppLocalizations l10n, Duration d) {
  final minutes = d.inMinutes;
  return minutes >= 60
      ? l10n.homeTodayHoursMinutes(minutes ~/ 60, minutes % 60)
      : l10n.homeTodayMinutes(minutes);
}
