import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../library/domain/entities/track.dart';
import '../../domain/entities/timed_lyrics_text.dart';
import '../../domain/usecases/lyrics_usecases.dart';
import '../screens/lyrics_web_screen.dart';
import 'lyrics_dialogs.dart';
import 'timed_lyrics_controller.dart';

/// 가사 편집 페이지 위쪽의 "파일에서 불러오기 · 웹에서 가져오기" 줄과, 불러온 가사를 띄워 두는 메모.
/// 플레이어의 "가사 설정"과 받기 전 "가사 상세"가 함께 쓴다.
///
/// 불러온 글이 들어오면: 지금 가사가 비어 있으면 그대로 넣고([onReplace]),
/// 이미 있으면 바꾸기 · 뒤에 붙이기 · 메모로 띄우기 중에서 고른다.
///
/// 메모는 화면 위에 떠 있는 작은 카드다. 페이지 레이아웃 밖(오버레이)에 있어서 키보드가 올라와도 가사 입력칸을
/// 누르지 않고, 머리를 끌어 위아래로 옮길 수 있다. 메모 글은 직접 고칠 수 있고, "끼우기"는 메모에서 고른 글
/// (고른 게 없으면 커서가 있는 줄)을 가사의 지금 줄 아래에 끼워 넣는다.
class LyricsImportBar extends StatefulWidget {
  const LyricsImportBar({
    super.key,
    required this.controller,
    required this.track,
    required this.onReplace,
    this.keyPrefix = 'lyrics',
  });

  final TimedLyricsController controller;

  /// 웹에서 찾을 때 검색어가 되는 곡 (제목 · 아티스트).
  final Track track;

  /// 불러온 글로 가사를 통째로 바꾼다 (싱크 가사면 시간도 함께 넣는 일은 부른 쪽이 한다).
  final ValueChanged<String> onReplace;

  /// 버튼 키 앞에 붙는 이름 (화면마다 구분하려고).
  final String keyPrefix;

  @override
  State<LyricsImportBar> createState() => _LyricsImportBarState();
}

class _LyricsImportBarState extends State<LyricsImportBar> {
  static const _cardHeight = 210.0;

  final _memo = TextEditingController();
  OverlayEntry? _entry;

  /// 메모 카드의 위쪽 위치. null이면 처음 놓을 자리(화면 아래쪽)를 쓴다.
  double? _top;

  @override
  void dispose() {
    _closeMemo();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await sl<PickLyricsFile>()(const NoParams());
    if (picked != null && mounted) await _apply(picked);
  }

  Future<void> _searchWeb() async {
    final picked = await showLyricsWeb(context, widget.track);
    if (picked != null && mounted) await _apply(picked);
  }

  Future<void> _apply(String imported) async {
    final c = widget.controller;
    if (c.text.trim().isEmpty) {
      widget.onReplace(imported);
      return;
    }
    final mode = await showLyricsImportMode(context);
    if (mode == null || !mounted) return;
    switch (mode) {
      case LyricsImportMode.replace:
        widget.onReplace(imported);
        _closeMemo();
      case LyricsImportMode.append:
        // 붙인 글은 시간 없는 줄로 뒤에 더한다.
        final extra = TimedLyricsText.parse(imported).text;
        c.text = '${c.text.trimRight()}\n$extra';
      case LyricsImportMode.memo:
        _openMemo(TimedLyricsText.parse(imported).text);
    }
  }

  void _openMemo(String text) {
    _memo.text = text;
    if (_entry != null) {
      _entry!.markNeedsBuild();
      return;
    }
    _entry = OverlayEntry(builder: _memoCard);
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _closeMemo() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  /// 메모에서 고른 글(고른 게 없으면 커서가 있는 줄)을 가사의 지금 줄 아래에 새 줄로 끼워 넣는다.
  /// 시간은 그 자리에 남는다.
  void _insertFromMemo() {
    final m = _memo.text;
    final sel = _memo.selection;
    String piece;
    if (sel.isValid && !sel.isCollapsed) {
      piece = sel.textInside(m);
    } else {
      final at = sel.isValid ? sel.baseOffset.clamp(0, m.length) : 0;
      final start = at == 0 ? 0 : m.lastIndexOf('\n', at - 1) + 1;
      final end = m.indexOf('\n', at);
      piece = m.substring(start, end < 0 ? m.length : end);
    }
    piece = piece.trim();
    if (piece.isEmpty) return;
    final c = widget.controller;
    final text = c.text;
    final caret = c.selection.isValid
        ? c.selection.baseOffset.clamp(0, text.length)
        : text.length;
    final lineEnd = text.indexOf('\n', caret);
    final at = lineEnd < 0 ? text.length : lineEnd;
    final insert = '\n$piece';
    c.value = TextEditingValue(
      text: text.replaceRange(at, at, insert),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
  }

  /// 화면 위에 떠 있는 메모 카드. 키보드로 줄어들지 않고, 키보드에 가려지면 그 위로 올라와 있는다.
  Widget _memoCard(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final maxTop = (size.height - keyboard - safeBottom - _cardHeight - 8)
        .clamp(0.0, size.height);
    // 처음에는 아래쪽(저장 버튼 위)에 놓고, 끌면 그 자리를 따른다. 키보드가 가리면 키보드 위로 올린다.
    final wanted = _top ?? (size.height - safeBottom - _cardHeight - 96);
    final top = wanted.clamp(0.0, maxTop);
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: top,
      height: _cardHeight,
      child: Material(
        color: p.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: p.accent.withValues(alpha: .5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 머리: 끌어서 옮긴다.
            GestureDetector(
              key: ValueKey('${widget.keyPrefix}-memo-handle'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) {
                _top = (top + d.delta.dy).clamp(0.0, maxTop);
                _entry?.markNeedsBuild();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.xxs,
                  0,
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.dragHandle,
                      size: AppSizes.iconSm,
                      color: p.onSurfaceMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(l10n.lyricsMemoTitle, style: text.titleSmall),
                    ),
                    PlainButton(
                      key: ValueKey('${widget.keyPrefix}-memo-insert'),
                      label: l10n.lyricsMemoInsert,
                      icon: AppIcons.add,
                      accent: true,
                      onPressed: _insertFromMemo,
                    ),
                    RowIconButton(
                      key: ValueKey('${widget.keyPrefix}-memo-close'),
                      icon: AppIcons.close,
                      tooltip: l10n.actionClear,
                      onPressed: _closeMemo,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.lyricsMemoHint,
                style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
              ),
            ),
            // 메모 글: 고치고 · 고르고 · 복사할 수 있다.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: TextField(
                  key: ValueKey('${widget.keyPrefix}-memo-field'),
                  controller: _memo,
                  style: text.bodyMedium,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xxs,
        AppSpacing.md,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: AppSpacing.xs,
          children: [
            PlainButton(
              key: ValueKey('${widget.keyPrefix}-import-file'),
              label: l10n.lyricsLoadFile,
              icon: AppIcons.fileOpen,
              onPressed: _pickFile,
            ),
            if (lyricsWebSupported)
              PlainButton(
                key: ValueKey('${widget.keyPrefix}-import-web'),
                label: l10n.lyricsWebSearch,
                icon: AppIcons.explore,
                onPressed: _searchWeb,
              ),
          ],
        ),
      ),
    );
  }
}
