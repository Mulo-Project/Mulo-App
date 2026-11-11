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
    this.detail,
    this.footer,
    this.active = false,
    this.number,
    this.badge,
    this.onTap,
    this.onMenu,
    this.onLongPress,
    this.horizontalPadding = AppSpacing.md,
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

  /// 부제 밑에 따로 보이는 한 줄 (예: 영상 길이). 부제가 길어도 밀리지 않는다.
  final String? detail;

  /// 제목 아래 추가 줄 (예: 다운로드 진행 막대).
  final Widget? footer;

  /// 지금 재생 중인 곡이면 제목을 강조 색으로.
  final bool active;

  /// 목록에서 몇 번째 곡인지 (있으면 커버 앞에 작은 숫자로).
  final int? number;

  /// 커버 오른쪽 아래 모서리에 겹쳐 붙는 작은 표시 아이콘 (알림 배지처럼 줄 크기를 바꾸지 않는다).
  final IconData? badge;
  final VoidCallback? onTap;

  /// 길게 누르기 · 데스크톱 오른쪽 클릭 (곡 메뉴 같은 보조 동작).
  /// 눌린 화면 좌표를 넘기므로 팝업 메뉴를 그 자리에 띄울 수 있다.
  final ValueChanged<Offset>? onMenu;

  /// 길게 누르기만 따로 받을 때 (여러 곡 선택 모드 진입). 있으면 길게 누르기는 [onMenu] 대신 이것을 부른다.
  final VoidCallback? onLongPress;

  /// 줄 좌우 안쪽 여백. 바깥에 이미 여백 · 강조 면이 있으면 줄인다 (대기열).
  final double horizontalPadding;

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  Offset _lastPointer = Offset.zero;

  /// [TrackTile.badge]가 있으면 커버 모서리에 겹쳐 붙인다 (밖으로 조금 나와도 레이아웃은 그대로).
  Widget _withBadge(BuildContext context, Widget child) {
    final icon = widget.badge;
    if (icon == null) return child;
    final p = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          bottom: -4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.accent,
              shape: BoxShape.circle,
              border: Border.all(color: p.background, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(icon, size: 10, color: p.onAccent),
            ),
          ),
        ),
      ],
    );
  }

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
        onLongPress:
            w.onLongPress ??
            (onMenu == null ? null : () => onMenu(_lastPointer)),
        onSecondaryTap: onMenu == null ? null : () => onMenu(_lastPointer),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        // 지금 재생 중인 줄은 강조 색 옅은 면으로 한눈에 보이게 한다.
        child: Ink(
          decoration: BoxDecoration(
            color: w.active ? p.accent.withValues(alpha: .06) : null,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: w.horizontalPadding,
            vertical: AppSpacing.sm - 2,
          ),
          child: Row(
            children: [
              if (w.number != null)
                SizedBox(
                  width: 24,
                  child: Text(
                    '${w.number}',
                    style: text.labelMedium?.copyWith(
                      color: w.active ? p.accent : p.onSurfaceMuted,
                    ),
                  ),
                ),
              _withBadge(
                context,
                w.leading ??
                    ArtworkBox(
                      image: w.artwork,
                      tone: w.tone,
                      color: w.color,
                      size: 52,
                    ),
              ),
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
                        fontSize: 15,
                        color: w.active ? p.accent : p.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      w.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                    if (w.detail != null && w.detail!.isNotEmpty)
                      Text(
                        w.detail!,
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
