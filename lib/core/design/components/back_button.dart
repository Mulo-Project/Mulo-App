import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../icons/app_icons.dart';
import 'buttons.dart';

/// 화면 위 막대 왼쪽의 뒤로 가기 버튼. 따로 정하지 않으면 지금 화면을 닫는다.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  /// 닫기 말고 다른 동작이 필요할 때 (예: 결과를 돌려주며 닫기).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CircleIconButton(
    icon: AppIcons.back,
    tooltip: context.l10n.actionBack,
    onPressed: onPressed ?? () => context.pop(),
  );
}
