import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 제목을 눌러 접고 펴는 영역 (홈의 오늘 들은 시간 · 많이 들은 곡).
/// [header]는 접어도 보이고, [child]만 접힌다. 기본은 펼친 상태.
class ExpandSection extends StatefulWidget {
  const ExpandSection({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = true,
    this.padding = AppSpacing.screen,
  });

  final Widget header;
  final Widget child;
  final bool initiallyExpanded;

  /// 제목 줄의 좌우 여백 (펼친 내용에는 적용하지 않는다).
  final EdgeInsetsGeometry padding;

  @override
  State<ExpandSection> createState() => _ExpandSectionState();
}

class _ExpandSectionState extends State<ExpandSection> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: widget.padding,
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: AppMotion.medium,
                    curve: AppMotion.standard,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: p.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: _open ? widget.child : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
