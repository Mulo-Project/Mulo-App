import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../equalizer/presentation/widgets/device_equalizer_section.dart';
import '../../../permissions/presentation/widgets/permissions_section.dart';
import '../../../subscriptions/presentation/widgets/subscriptions_section.dart';

import '../widgets/settings_about_section.dart';
import '../widgets/settings_account_section.dart';
import '../widgets/settings_data_section.dart';
import '../widgets/settings_download_section.dart';
import '../widgets/settings_notification_section.dart';
import '../widgets/settings_playback_section.dart';
import '../widgets/settings_security_section.dart';
import '../widgets/settings_theme_section.dart';

export '../widgets/settings_common.dart' show presetLabel;

/// 설정 (상세 기능: 서버 연결·모드 선택 #31, 저장 위치 #23, 기본 포맷 #24,
/// 다운로드 엔진 업데이트 #25, 알림 곡 정보 숨기기 #32 + 테마 D-005).
/// 테마 색(프리셋, 저장됨) · 앱 잠금(PIN · 생체 인증) · 알림 설정만 실제로 동작하고 나머지는 자리 표시.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 묶음 접힘 · 검색어. 화면이 살아 있는 동안 유지된다.
  final _layout = SectionLayoutController();

  @override
  void dispose() {
    _layout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            large: true,
            title: l10n.navSettings,
            subtitle: l10n.settingsSubtitle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: AppSearchField(
              key: const ValueKey('settings-search'),
              hint: l10n.settingsSearchHint,
              clearTooltip: l10n.actionClear,
              height: 44,
              onChanged: _layout.setQuery,
            ),
          ),
          // 묶음 안 줄이 이미 좌우 [AppSpacing.md]를 두므로 바깥 여백 없이 상단 제목과 왼쪽 선을 맞춘다.
          // 묶음마다 자기가 쓰는 값만 지켜보므로, 한 값이 바뀌어도 그 묶음만 다시 그려진다.
          // 묶음 사이 간격과 접기 · 검색 걸러내기는 [SectionCard]가 [SectionLayoutScope]로 처리한다.
          SectionLayoutScope(
            controller: _layout,
            child: const Column(
              children: [
                SettingsDownloadSection(),
                SettingsAccountSection(),
                SettingsSecuritySection(),
                SettingsNotificationSection(),
                SettingsPlaybackSection(),
                DeviceEqualizerSection(),
                SubscriptionsSection(),
                PermissionsSection(),
                SettingsThemeSection(),
                SettingsDataSection(),
                SettingsAboutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
