import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';

import '../../../../core/app_info.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';

/// 정보 묶음: 앱 버전 · 오픈소스 라이선스.
class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: l10n.settingsAbout,
      children: [
        SettingRow(
          title: l10n.settingsVersion,
          trailing: Text(
            appVersion,
            style: text.bodyMedium?.copyWith(
              color: context.palette.onSurfaceMuted,
            ),
          ),
        ),
        SettingRow(
          title: l10n.settingsLicenses,
          trailing: Icon(
            AppIcons.chevronRight,
            size: AppSizes.iconMd,
            color: context.palette.onSurfaceMuted,
          ),
          onTap: () {
            _registerNativeLicenses();
            showLicensePage(
              context: context,
              applicationName: 'Mulo',
              applicationVersion: appVersion,
            );
          },
        ),
      ],
    );
  }
}

var _nativeLicensesRegistered = false;

/// Flutter가 자동으로 모으지 못하는 네이티브 부품(재생 · 받기 · 변환)의 고지를 목록에 더한다.
void _registerNativeLicenses() {
  if (_nativeLicensesRegistered) return;
  _nativeLicensesRegistered = true;
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(['androidx.media3'], 'Copyright The Android Open Source Project.\n'
        'Licensed under the Apache License, Version 2.0.\n'
        'https://www.apache.org/licenses/LICENSE-2.0');
    yield const LicenseEntryWithLineBreaks(['yt-dlp', 'youtubedl-android'], 'yt-dlp is released into the public domain (The Unlicense).\n'
        'youtubedl-android is licensed under the GNU General Public License v3.0 or the Apache License 2.0 depending on the component; see its repository.\n'
        'https://github.com/yt-dlp/yt-dlp\n'
        'https://github.com/yausername/youtubedl-android');
    yield const LicenseEntryWithLineBreaks(['FFmpeg'], 'FFmpeg is licensed under the LGPL v2.1 or later (GPL v2 or later for some builds).\n'
        'https://ffmpeg.org/legal.html');
  });
}
