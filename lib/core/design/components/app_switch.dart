import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 토글 스위치 (레퍼런스의 "Training" 토글). 켜짐 = 강조 색 트랙.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _width = 48;
  static const double _height = 28;
  static const double _knob = 22;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : .4,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            width: _width,
            height: _height,
            padding: const EdgeInsets.all(3),
            decoration: ShapeDecoration(
              color: value ? p.accent : p.surfaceHigh,
              shape: StadiumBorder(
                side: BorderSide(color: value ? p.accent : p.outline),
              ),
            ),
            child: AnimatedAlign(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? p.onAccent : p.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
