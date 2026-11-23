import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../account/domain/entities/google_account.dart';
import '../../../account/presentation/bloc/account_cubit.dart';

/// 계정 묶음: 구글 계정으로 로그인 · 로그아웃 (내 유튜브 재생목록을 불러오는 데 쓴다).
class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AccountCubit>().state;
    final cubit = context.read<AccountCubit>();
    final account = state.account;
    final String description;
    if (account != null) {
      description = account.displayName == null || account.displayName!.isEmpty
          ? account.email
          : '${account.displayName} · ${account.email}';
    } else if (state.failure != null) {
      description = l10n.settingsAccountFailed;
    } else {
      description = switch (state.support) {
        AccountSupport.available => l10n.settingsAccountSignedOutDesc,
        AccountSupport.notConfigured => l10n.settingsAccountNotConfigured(
          AppConfig.googleRequiredKeys,
        ),
        AccountSupport.unsupportedPlatform => l10n.settingsAccountUnsupported,
      };
    }
    return SectionCard(
      title: l10n.settingsAccount,
      children: [
        SettingRow(
          title: l10n.settingsGoogleAccount,
          description: description,
          trailing: account != null
              ? PillButton(
                  compact: true,
                  label: l10n.settingsAccountSignOut,
                  variant: PillVariant.tonal,
                  onPressed: state.busy ? null : cubit.signOut,
                )
              : PillButton(
                  compact: true,
                  label: l10n.settingsAccountSignIn,
                  onPressed:
                      state.busy || state.support != AccountSupport.available
                      ? null
                      : cubit.signIn,
                ),
        ),
      ],
    );
  }
}

/// 서버 묶음: 지금 쓰는 모드(엔진 상태로 정해짐)와 서버 주소가 빌드에 있는지를 보여 준다.
/// 모드는 자동으로 정해져서 바꾸는 버튼은 없다 (로컬 yt-dlp를 쓸 수 있으면 로컬).
