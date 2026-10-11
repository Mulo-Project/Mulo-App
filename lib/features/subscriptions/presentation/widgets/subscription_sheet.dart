import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// 구독 화면들의 바텀시트 공통 모양: 손잡이 · 둥근 윗모서리 · 루트 네비게이터 위.
Future<T?> showSubscriptionSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  showDragHandle: true,
  backgroundColor: context.palette.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
  ),
  builder: builder,
);

/// 시트 안쪽 여백: 가로는 화면 · 목록 줄과 같은 [AppSpacing.md]라 시트가 열려도 왼쪽 선이 이어진다.
const sheetPadding = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.xs,
  AppSpacing.md,
  AppSpacing.lg,
);
