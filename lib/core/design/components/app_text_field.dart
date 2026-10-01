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
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

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
          child: SizedBox(
            height: 48,
            // 고정 높이 안에서 글자를 세로 가운데에 둔다 (Center가 입력칸 높이를 풀어 준다).
            child: Center(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: textInputAction,
                style: text.bodyLarge,
                cursorColor: p.accent,
                decoration: InputDecoration.collapsed(
                  hintText: hint,
                  hintStyle: text.bodyLarge?.copyWith(color: p.onSurfaceMuted),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
