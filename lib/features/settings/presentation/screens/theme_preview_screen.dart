import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../widgets/theme_preview.dart';

/// 설정 › 테마 미리보기. 지금 적용된 테마로 화면이 어떻게 보이는지 보여 준다.
/// 최상위 내비게이터에서 열어 하단 탭 · 미니 플레이어를 가린다.
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
    rootNavigator: true,
  ).push<void>(MaterialPageRoute(builder: (_) => const ThemePreviewScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.palette.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.settingsThemePreview,
                leading: CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Expanded(
                child: SingleChildScrollView(child: ThemePreview()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
