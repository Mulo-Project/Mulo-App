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
/// 메모는 불러온 가사를 줄마다 보여 주고, 줄을 누르면 [controller]의 지금 줄 아래에 그 줄을 끼워 넣는다
/// (여러 줄을 골라 여기저기 이어 붙일 수 있다).
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
  /// 메모로 띄워 둔 불러온 가사의 줄들 (없으면 메모 칸이 없다).
  List<String> _memo = const [];

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
        setState(() => _memo = const []);
      case LyricsImportMode.append:
        // 붙인 글은 시간 없는 줄로 뒤에 더한다.
        final extra = TimedLyricsText.parse(imported).text;
        c.text = '${c.text.trimRight()}\n$extra';
      case LyricsImportMode.memo:
        setState(() => _memo = _linesOf(imported));
    }
  }

  static List<String> _linesOf(String raw) => [
    for (final l in TimedLyricsText.parse(raw).text.split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];

  /// 메모의 [line]을 가사의 지금 줄(커서가 있는 줄) 아래에 새 줄로 끼워 넣는다. 시간은 그 자리에 남는다.
  void _insert(String line) {
    final c = widget.controller;
    final text = c.text;
    final caret = c.selection.isValid
        ? c.selection.baseOffset.clamp(0, text.length)
        : text.length;
    final lineEnd = text.indexOf('\n', caret);
    final at = lineEnd < 0 ? text.length : lineEnd;
    final insert = '\n$line';
    c.value = TextEditingValue(
      text: text.replaceRange(at, at, insert),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xxs,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
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
          if (_memo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: p.surfaceHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    side: BorderSide(color: p.outline),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.xxs,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.lyricsMemoTitle,
                              style: text.titleSmall,
                            ),
                          ),
                          RowIconButton(
                            key: ValueKey('${widget.keyPrefix}-memo-close'),
                            icon: AppIcons.close,
                            tooltip: l10n.actionClear,
                            onPressed: () => setState(() => _memo = const []),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        l10n.lyricsMemoHint,
                        style: text.bodySmall?.copyWith(
                          color: p.onSurfaceMuted,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 168),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        children: [
                          for (final line in _memo)
                            InkWell(
                              onTap: () => _insert(line),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(line, style: text.bodyMedium),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Icon(
                                      AppIcons.add,
                                      size: AppSizes.iconSm,
                                      color: p.accent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
