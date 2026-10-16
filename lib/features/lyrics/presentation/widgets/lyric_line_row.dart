import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// `mm:ss.xx` 모양의 시간 글자 (싱크 가사의 시간 표시와 같은 모양).
String lyricTimeLabel(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final cs = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
  return '$m:$s.$cs';
}

/// 가사 한 줄을 고치는 칸: 왼쪽에 시간(읽기 전용, 없으면 `—`), 오른쪽에 글 입력칸.
/// 시간은 글에 섞이지 않고 따로 보여, 글을 고쳐도 `[01:02.30]` 표시가 깨지지 않는다.
/// [onDelete]가 있으면 줄 끝에 지우기 버튼을 둔다.
class LyricLineRow extends StatelessWidget {
  const LyricLineRow({
    super.key,
    required this.time,
    required this.controller,
    this.onDelete,
    this.deleteTooltip = '',
  });

  /// 이 줄에 등록된 싱크 시간. 아직 없으면 null.
  final Duration? time;
  final TextEditingController controller;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      borderSide: BorderSide(color: p.outline),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              time == null ? '—' : lyricTimeLabel(time!),
              style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: text.bodyMedium,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: p.surfaceHigh,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: p.primary),
                ),
              ),
            ),
          ),
          if (onDelete != null)
            RowIconButton(
              icon: AppIcons.close,
              tooltip: deleteTooltip,
              onPressed: onDelete!,
            ),
        ],
      ),
    );
  }
}
