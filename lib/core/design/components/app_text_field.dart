import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 라벨이 위에 붙은 둥근 입력칸 (폼용). 검색창은 `AppSearchField`.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  /// 1이면 한 줄 입력칸(높이 48), 더 크면 그 줄 수만큼 높이를 잡는 여러 줄 입력칸.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
      keyboardType: maxLines > 1 ? TextInputType.multiline : null,
      minLines: maxLines > 1 ? maxLines : null,
      maxLines: maxLines > 1 ? maxLines : 1,
      style: text.bodyLarge,
      cursorColor: p.accent,
      decoration: InputDecoration.collapsed(
        hintText: hint,
        hintStyle: text.bodyLarge?.copyWith(color: p.onSurfaceMuted),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: text.labelSmall),
        const SizedBox(height: AppSpacing.xxs),
        Container(
          decoration: ShapeDecoration(
            color: p.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              side: BorderSide(color: p.outline),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: maxLines > 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: field,
                )
              : SizedBox(
                  height: 48,
                  // 고정 높이 안에서 글자를 세로 가운데에 둔다 (Center가 입력칸 높이를 풀어 준다).
                  child: Center(child: field),
                ),
        ),
      ],
    );
  }
}
