import 'package:flutter/material.dart';

import '../tokens/app_dimens.dart';

/// 화면 상단 바.
///
/// - [large]: 탭 첫 화면. 작은 부제 + 큰 제목을 왼쪽에, 동작 버튼은 오른쪽.
/// - 기본: 레퍼런스의 "← 제목 ≡"처럼 원형 버튼 사이 가운데 제목.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (large) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(subtitle!.toUpperCase(), style: text.labelSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(title, style: text.headlineLarge),
                ],
              ),
            ),
            ..._spaced(actions),
          ],
        ),
      );
    }

    // 버튼이 둘 이상이면 제목을 화면 가운데에 겹쳐 놓을 자리가 없어 깨지므로, 앞 버튼 · 제목 · 버튼들을 한 줄로 놓는다
    // (제목은 남는 자리의 가운데). 버튼이 하나 이하일 때만 화면 가운데에 둔다.
    if (actions.length > 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: SizedBox(
          height: AppSizes.circleButtonLarge,
          child: Row(
            children: [
              leading ?? const SizedBox(width: AppSizes.circleButton),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    title,
                    style: text.titleLarge,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ..._spaced(actions),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SizedBox(
        height: AppSizes.circleButtonLarge,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: leading),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 72),
              child: Text(
                title,
                style: text.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _spaced(actions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const SizedBox(width: AppSpacing.xs),
      items[i],
    ],
  ];
}
