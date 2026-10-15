import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 휠 피커 한 칸: 0부터 [count]-1까지 숫자를 돌려서 고른다.
/// [unit]은 숫자 옆에 붙는 단위 글자(시간 · 분 등)이다. 선택이 바뀔 때마다 가벼운 진동을 준다.
class WheelPicker extends StatefulWidget {
  const WheelPicker({
    super.key,
    required this.count,
    required this.value,
    required this.onChanged,
    this.unit = '',
    this.itemExtent = 44,
    this.width = 96,
  });

  final int count;
  final int value;
  final ValueChanged<int> onChanged;
  final String unit;
  final double itemExtent;
  final double width;

  @override
  State<WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<WheelPicker> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: widget.width,
      height: widget.itemExtent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가운데 선택 줄 표시.
          Container(
            height: widget.itemExtent,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemExtent,
            diameterRatio: 1.6,
            perspective: 0.003,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              HapticFeedback.selectionClick();
              widget.onChanged(i);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.count,
              builder: (context, i) {
                final selected = i == widget.value;
                return Center(
                  child: Text(
                    '$i${widget.unit}',
                    style: text.titleLarge?.copyWith(
                      color: selected ? p.onSurface : p.onSurfaceMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
