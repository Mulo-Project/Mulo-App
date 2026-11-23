import 'package:flutter/widgets.dart';

import '../../../../core/l10n/l10n.dart';

/// 저장하는 중 글자: "받는 중", 진행률이 있으면 "받는 중 42%", 남은 시간 어림이 있으면 "받는 중 42% · 약 30초 남음".
String savedProgressLabel(
  BuildContext context, {
  int? percent,
  int? etaSeconds,
}) {
  final l10n = context.l10n;
  final parts = [
    percent == null
        ? l10n.savedVideosDownloading
        : '${l10n.savedVideosDownloading} $percent%',
    if (etaSeconds != null)
      etaSeconds < 90
          ? l10n.savedVideosEtaSeconds(etaSeconds < 1 ? 1 : etaSeconds)
          : l10n.savedVideosEtaMinutes((etaSeconds / 60).ceil()),
  ];
  return parts.join(' · ');
}
