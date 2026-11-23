import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/playlist.dart';
import 'playlist_card.dart';

/// 재생목록 카드를 2열로 늘어놓는다. 재생목록 탭과 담기 선택 화면에서 같이 쓴다.
/// [cardBuilder]로 카드를 바꿀 수 있고, 안 주면 둘러보기 카드를 만든다.
///
/// [onReorder]를 주면 카드를 길게 눌러 끌어서 순서를 바꿀 수 있다: 끄는 동안 다른 카드가 비켜 주고,
/// 놓으면 바뀐 순서(좋아요 목록을 뺀 재생목록 id)를 넘긴다. 좋아요 목록은 늘 맨 앞이라 끌 수 없다.
class PlaylistGrid extends StatefulWidget {
  const PlaylistGrid({
    super.key,
    required this.lists,
    this.cardBuilder,
    this.onReorder,
  });

  final List<Playlist> lists;
  final Widget Function(BuildContext context, Playlist playlist)? cardBuilder;
  final ValueChanged<List<String>>? onReorder;

  @override
  State<PlaylistGrid> createState() => _PlaylistGridState();
}

class _PlaylistGridState extends State<PlaylistGrid> {
  /// 끄는 동안(그리고 저장된 순서가 돌아올 때까지) 보이는 순서.
  List<Playlist>? _order;
  String? _dragging;

  @override
  void didUpdateWidget(PlaylistGrid old) {
    super.didUpdateWidget(old);
    // 저장된 새 순서가 오면 임시 순서는 버린다.
    if (!identical(old.lists, widget.lists) && _dragging == null) {
      _order = null;
    }
  }

  /// 끄는 카드를 [target] 자리로 옮긴다 (좋아요 목록 자리로는 못 간다).
  void _moveOver(Playlist target) {
    final order = [..._order ?? widget.lists];
    final from = order.indexWhere((e) => e.id == _dragging);
    final to = order.indexWhere((e) => e.id == target.id);
    if (from < 0 || to < 0 || from == to || order[to].isFavorites) return;
    order.insert(to, order.removeAt(from));
    setState(() => _order = order);
  }

  void _drop() {
    final order = _order;
    setState(() => _dragging = null);
    if (order == null) return;
    final ids = [
      for (final e in order)
        if (!e.isFavorites) e.id,
    ];
    final before = [
      for (final e in widget.lists)
        if (!e.isFavorites) e.id,
    ];
    if (ids.join(',') == before.join(',')) {
      setState(() => _order = null);
      return;
    }
    widget.onReorder?.call(ids);
  }

  /// 끌면서 화면 위아래 가장자리에 가까워지면 목록을 스크롤한다.
  void _autoScroll(Offset global) {
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null) return;
    final height = MediaQuery.sizeOf(context).height;
    const edge = 120.0;
    var delta = 0.0;
    if (global.dy < edge) {
      delta = -14;
    } else if (global.dy > height - edge) {
      delta = 14;
    }
    if (delta == 0) return;
    position.jumpTo(
      (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  Widget _card(BuildContext context, Playlist pl) =>
      widget.cardBuilder?.call(context, pl) ??
      PlaylistCard(
        playlist: pl,
        longPressMenu: widget.onReorder == null || pl.isFavorites,
      );

  @override
  Widget build(BuildContext context) {
    final lists = _order ?? widget.lists;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final pl in lists)
              SizedBox(
                key: ValueKey(pl.id),
                width: w,
                child: widget.onReorder == null || pl.isFavorites
                    ? _card(context, pl)
                    : DragTarget<String>(
                        onWillAcceptWithDetails: (d) {
                          if (d.data != pl.id) _moveOver(pl);
                          return false;
                        },
                        builder: (context, _, _) => LongPressDraggable<String>(
                          data: pl.id,
                          onDragStarted: () => setState(() {
                            _dragging = pl.id;
                            _order = [...widget.lists];
                          }),
                          onDragUpdate: (d) => _autoScroll(d.globalPosition),
                          onDragEnd: (_) => _drop(),
                          onDraggableCanceled: (_, _) {},
                          feedback: SizedBox(
                            width: w,
                            child: Opacity(
                              opacity: .92,
                              child: Transform.scale(
                                scale: 1.04,
                                child: _card(context, pl),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: .35,
                            child: _card(context, pl),
                          ),
                          child: _card(context, pl),
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}
