import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../icons/app_icons.dart';
import '../tokens/app_dimens.dart';
import 'app_divider.dart';

/// 긴 화면(설정)의 묶음을 접고 펴고, 검색어로 걸러 보이게 하는 상태.
/// [SectionLayoutScope]로 아래 [SectionCard]들에 내려준다. 접힘 상태는 제목으로 구분한다.
class SectionLayoutController extends ChangeNotifier {
  final _open = <String, bool>{};
  String _query = '';

  /// 소문자로 다듬은 검색어 (없으면 빈 문자열).
  String get query => _query;
  bool get searching => _query.isNotEmpty;

  /// [title] 묶음이 펼쳐져 있는지. 사용자가 누른 적이 없으면 [initial].
  bool isOpen(String title, bool initial) => _open[title] ?? initial;

  void toggle(String title, bool initial) {
    _open[title] = !isOpen(title, initial);
    notifyListeners();
  }

  void setQuery(String value) {
    final q = value.trim().toLowerCase();
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }
}

/// [SectionLayoutController]를 아래로 내려주는 범위. 없으면 [SectionCard]는 늘 펼쳐진다.
class SectionLayoutScope extends InheritedNotifier<SectionLayoutController> {
  const SectionLayoutScope({
    super.key,
    required SectionLayoutController controller,
    required super.child,
  }) : super(notifier: controller);

  static SectionLayoutController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SectionLayoutScope>()
      ?.notifier;
}

/// 제목이 붙은 목록 묶음 (설정 목록 등). 카드 면 없이 자식 사이에 옅은 구분선만 둔다.
///
/// [SectionLayoutScope] 안에서는 제목을 눌러 접고 펼 수 있고, 검색어가 있으면 제목이나
/// [SettingRow]의 제목·설명이 맞는 줄만 남긴다 (제목이 맞으면 묶음 전체). 줄이 하나도
/// 안 남으면 묶음이 사라진다. 이 경우 묶음 아래에 [AppSpacing.lg] 간격을 스스로 둔다.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String? title;
  final List<Widget> children;

  /// 접기를 쓸 때 처음 펼쳐 둘지.
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final layout = title == null ? null : SectionLayoutScope.maybeOf(context);

    var shown = children;
    var open = true;
    if (layout != null) {
      if (layout.searching) {
        final q = layout.query;
        if (!title!.toLowerCase().contains(q)) {
          shown = [
            for (final c in children)
              if (c is SettingRow && c.matches(q)) c,
          ];
          if (shown.isEmpty) return const SizedBox.shrink();
        }
      } else {
        open = layout.isOpen(title!, initiallyExpanded);
      }
    }

    final heading = Text(
      title ?? '',
      style: text.titleSmall?.copyWith(color: p.onSurfaceMuted),
    );
    final body = Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
              color: p.outline,
            ),
          shown[i],
        ],
      ],
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          if (layout == null)
            Padding(
              // 제목도 줄 글자와 같은 [AppSpacing.md]에서 시작해 왼쪽 선을 맞춘다.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: heading,
            )
          else
            InkWell(
              onTap: layout.searching
                  ? null
                  : () => layout.toggle(title!, initiallyExpanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(child: heading),
                    AnimatedRotation(
                      turns: open ? 0.25 : 0,
                      duration: AppMotion.fast,
                      child: Icon(
                        AppIcons.chevronRight,
                        color: p.onSurfaceMuted,
                        size: AppSizes.iconMd,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (layout == null)
          body
        else
          AnimatedSize(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: open
                ? body
                : const SizedBox(width: double.infinity, height: 0),
          ),
      ],
    );
    return layout == null
        ? column
        : Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: column,
          );
  }
}

/// 설정 한 줄: 제목 · 설명 · 오른쪽 값/스위치. [below]는 줄 아래에 붙는 컨트롤.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.below,
    this.onTap,
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  /// 소문자 검색어 [q]가 제목이나 설명에 들어 있는지.
  bool matches(String q) =>
      title.toLowerCase().contains(q) ||
      (description?.toLowerCase().contains(q) ?? false);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      if (description != null) ...[
                        const SizedBox(height: AppSpacing.hair),
                        Text(description!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            if (below != null) ...[
              const SizedBox(height: AppSpacing.sm),
              below!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 긴 화면의 구역: 위에 옅은 구분선, 그 아래 작은 제목, 이어서 내용. 카드 면 없이 선과 여백으로만 나눈다.
/// [first]면 맨 위 구역이라 구분선과 위 여백을 생략한다.
class SectionBlock extends StatelessWidget {
  const SectionBlock({
    super.key,
    this.title,
    required this.children,
    this.first = false,
  });

  final String? title;
  final List<Widget> children;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!first) ...[
            const AppDivider(),
            const SizedBox(height: AppSpacing.md),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: text.titleSmall?.copyWith(color: p.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          ...children,
        ],
      ),
    );
  }
}
