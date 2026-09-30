import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 알약 모양 입력칸. 왼쪽 돋보기, 입력이 있으면 오른쪽 지우기, 없으면 [trailing].
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.clearTooltip,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
  });

  final String hint;
  final String clearTooltip;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// 입력이 비어 있을 때 오른쪽에 둘 위젯 (예: 붙여넣기 버튼).
  final Widget? trailing;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final hasText = _controller.text.isNotEmpty;

    return Container(
      decoration: ShapeDecoration(
        color: p.surfaceHigh,
        shape: StadiumBorder(side: BorderSide(color: p.outline)),
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.xxs,
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: p.onSurfaceMuted, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: text.bodyLarge,
                cursorColor: p.accent,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration.collapsed(
                  hintText: widget.hint,
                  hintStyle: text.bodyLarge?.copyWith(color: p.onSurfaceMuted),
                ),
              ),
            ),
            if (hasText)
              IconButton(
                tooltip: widget.clearTooltip,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: p.onSurfaceMuted,
                  size: 20,
                ),
              )
            else if (widget.trailing != null)
              widget.trailing!,
          ],
        ),
      ),
    );
  }
}
