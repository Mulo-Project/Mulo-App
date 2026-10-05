import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'artwork_box.dart';
import 'marquee_text.dart';

/// 곡 한 줄: 커버 · 제목 · 부제 · 오른쪽 위젯.
class TrackTile extends StatefulWidget {
  const TrackTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.tone = GlowTone.primary,
    this.color,
    this.artwork,
    this.leading,
    this.trailing,
    this.footer,
    this.active = false,
    this.onTap,
    this.onMenu,
  });

  final String title;
  final String subtitle;
  final GlowTone tone;

  /// 사용자가 고른 커버 색 (있으면 [tone] 대신).
  final Color? color;
  final ImageProvider? artwork;

  /// 커버 대신 둘 위젯 (예: 선택 체크).
  final Widget? leading;
  final Widget? trailing;

  /// 제목 아래 추가 줄 (예: 다운로드 진행 막대).
  final Widget? footer;

  /// 지금 재생 중인 곡이면 제목을 강조 색으로.
  final bool active;
  final VoidCallback? onTap;

  /// 길게 누르기 · 데스크톱 오른쪽 클릭 (곡 메뉴 같은 보조 동작).
  /// 눌린 화면 좌표를 넘기므로 팝업 메뉴를 그 자리에 띄울 수 있다.
  final ValueChanged<Offset>? onMenu;

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  Offset _lastPointer = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final w = widget;
    final onMenu = w.onMenu;

    return Listener(
      onPointerDown: (e) => _lastPointer = e.position,
      child: InkWell(
        onTap: w.onTap,
        onLongPress: onMenu == null ? null : () => onMenu(_lastPointer),
        onSecondaryTap: onMenu == null ? null : () => onMenu(_lastPointer),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              w.leading ??
                  ArtworkBox(image: w.artwork, tone: w.tone, color: w.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MarqueeText(
                      w.title,
                      scroll: w.active,
                      style: text.titleSmall?.copyWith(
                        color: w.active ? p.accent : p.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                    if (w.footer != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      w.footer!,
                    ],
                  ],
                ),
              ),
              if (w.trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                w.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
