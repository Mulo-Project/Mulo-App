import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 휠 피커 한 칸: 0부터 [count]-1까지 숫자를 끝없이 돌려서 고른다 (두 자리 `00` 모양).
/// 단위 글자는 휠 밖에 고정해 두는 것이 보기 좋다. 선택이 바뀔 때마다 가벼운 진동을 준다.
class WheelPicker extends StatefulWidget {
  const WheelPicker({
    super.key,
    required this.count,
    required this.value,
    required this.onChanged,
    this.itemExtent = 44,
    this.width = 72,
  });

  final int count;
  final int value;
  final ValueChanged<int> onChanged;
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
              widget.onChanged(i % widget.count);
            },
            childDelegate: ListWheelChildLoopingListDelegate(
              children: [
                for (var i = 0; i < widget.count; i++)
                  Center(
                    child: Text(
                      i.toString().padLeft(2, '0'),
                      style: text.headlineSmall?.copyWith(
                        color: i == widget.value
                            ? p.onSurface
                            : p.onSurfaceMuted,
                        fontWeight: i == widget.value
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
