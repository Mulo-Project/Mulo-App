import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/google_account.dart';
import '../bloc/account_cubit.dart';

/// 구글 로그인이 돼 있는지 확인하고, 안 돼 있으면 "로그인할까요?"를 물은 뒤 로그인한다.
/// 이 기기에서 로그인을 쓸 수 없거나 로그인에 실패하면 안내만 하고 false를 돌려준다.
/// (내 재생목록 · 구독 채널 · 채널 재생목록 가져오기가 같이 쓴다.)
Future<bool> ensureGoogleSignIn(BuildContext context) async {
  final account = context.read<AccountCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final support = account.state.support;
  if (support != AccountSupport.available) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          support == AccountSupport.notConfigured
              ? l10n.settingsAccountNotConfigured(AppConfig.googleRequiredKeys)
              : l10n.settingsAccountUnsupported,
        ),
      ),
    );
    return false;
  }
  if (account.state.signedIn) return true;
  final allow = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const _SignInPromptDialog(),
  );
  if (allow != true) return false;
  if (await account.signIn() == null) {
    if (account.state.failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsAccountFailed)),
      );
    }
    return false;
  }
  return true;
}

/// 로그인하지 않고 구글 계정이 필요한 기능을 눌렀을 때: 구글 로그인을 할지 묻는다.
class _SignInPromptDialog extends StatelessWidget {
  const _SignInPromptDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.playlistImportSignInPromptTitle,
      body: l10n.playlistImportSignInPromptBody,
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PillButton(
          label: l10n.playlistImportSignInAllow,
          icon: AppIcons.person,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
