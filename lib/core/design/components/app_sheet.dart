import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 앱 공통 바텀 시트: 손잡이 · 작은 윗모서리 반경 · 최상위 내비게이터 위 (탭 틀을 덮는다).
/// 시트마다 모양이 달라지지 않게 모든 바텀 시트는 이것으로 연다.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool showDragHandle = true,
  Color? barrierColor,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: context.palette.surface,
  barrierColor: barrierColor,
  showDragHandle: showDragHandle,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  useRootNavigator: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
  ),
  builder: builder,
);

/// 시트 안쪽 여백. 가로는 화면 · 목록 줄과 같은 [AppSpacing.md]라 왼쪽 선이 이어지고,
/// 위는 손잡이가 이미 띄워 주므로 0이다.
const appSheetPadding = EdgeInsets.fromLTRB(
  AppSpacing.md,
  0,
  AppSpacing.md,
  AppSpacing.lg,
);

/// 시트 맨 위 제목 (+ 작은 부제). 모든 시트가 같은 크기 · 간격을 쓴다.
class AppSheetTitle extends StatelessWidget {
  const AppSheetTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: text.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle!, style: text.bodySmall),
        ],
      ],
    );
  }
}
