import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/subtitle_availability_cubit.dart';
import '../../../library/domain/entities/track.dart';
import '../../../lyrics/presentation/widgets/lyrics_editor.dart';
import 'subtitle_detail_screen.dart';
import 'subtitle_language_label.dart';

/// 받기 창의 가사 구역(유튜브 곡만): 영상 자막 가져오기 · 언어 표 · 가사 설정.
/// 고른 값은 [DownloadLyricsSectionState]의 값으로 읽는다 (받기를 누를 때 부모가 읽는다).
class DownloadLyricsSection extends StatefulWidget {
  const DownloadLyricsSection({
    super.key,
    required this.url,
    required this.songTitle,
    required this.songArtist,
  });

  final String url;

  /// 받기 창에 지금 적힌 제목 · 아티스트 (웹에서 가사를 찾는 검색어).
  final String Function() songTitle;
  final String Function() songArtist;

  @override
  State<DownloadLyricsSection> createState() => DownloadLyricsSectionState();
}

class DownloadLyricsSectionState extends State<DownloadLyricsSection> {
  var _importLyrics = false;

  // 사용자가 고른 자막 언어. 고르지 않았으면(null) 기본 언어([_defaultLanguage])를 쓴다.
  String? _lyricsLanguage;

  // 기본 자막 언어: 기기(시스템) 언어와 맞는 자막, 없으면 첫 자막. 자막 목록이 바뀔 때마다 다시 정한다.
  String? _defaultLanguage;
  var _skipSounds = true;

  // 가사 설정 페이지에서 직접 정한 가사 (파일 · 웹에서 불러오거나 쓴 글). 있으면 영상 자막 대신 이 글을 넣는다.
  String? _custom;

  // 상세 페이지에서 고른 자막의 가사 (언어 코드별). 효과음 옵션이 바뀌면 비운다.
  final _edited = <String, String>{};

  /// 영상 자막을 가져오게 켰는가.
  bool get importLyrics => _importLyrics;

  /// 직접 정했거나 자막에서 적용한 가사 글 (없으면 null).
  String? get custom => _custom;

  /// 가져올 자막 언어: 고른 언어, 안 골랐으면 기본 언어 (자막 목록을 아직 모르면 null).
  String? get language => _lyricsLanguage ?? _defaultLanguage;

  /// 자막의 효과음 줄을 건너뛰는가.
  bool get skipSounds => _skipSounds;

  /// 받기 요청에 실을 가사 글: 직접 정한 가사가 먼저, 없으면 고른 언어에서 고쳐 둔 글.
  String? get lyricsText =>
      _custom ?? (language == null ? null : _edited[language]);

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubtitleAvailabilityCubit, SubtitleAvailability>(
        builder: _lyricsSection,
      );

  /// 자막이 있는지(확인 중 · 있음 · 없음 · 모름) 보여 주고, 가져올지 · 어떤 언어로 가져올지 정한다.
  Widget _lyricsSection(BuildContext context, SubtitleAvailability sub) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    _defaultLanguage = _systemDefault(sub.languages);
    final none = sub.status == SubtitleStatus.none;
    // 자막 확인이 끝나기 전에는 켜고 끌 수 없다 (있는지 알고 나서 고른다).
    final locked = none || sub.status == SubtitleStatus.checking;
    final status = switch (sub.status) {
      SubtitleStatus.checking => l10n.downloadSubtitleChecking,
      SubtitleStatus.found => l10n.downloadSubtitleFound(sub.languages.length),
      SubtitleStatus.none => l10n.downloadSubtitleNone,
      SubtitleStatus.unknown => l10n.downloadSubtitleUnknown,
    };
    final on = _importLyrics && !none;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedPanel(
          child: SettingRow(
            key: const ValueKey('download-import-lyrics'),
            title: l10n.downloadImportLyrics,
            description: status,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sub.status == SubtitleStatus.checking) ...[
                  const LoadingIndicator.small(),
                  const SizedBox(width: AppSpacing.sm),
                ],
                AppSwitch(
                  value: on,
                  onChanged: locked
                      ? null
                      : (v) => setState(() => _importLyrics = v),
                ),
              ],
            ),
            onTap: locked
                ? null
                : () => setState(() => _importLyrics = !_importLyrics),
          ),
        ),
        if (on && sub.languages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.downloadSubtitleLanguage, style: text.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          _languageTable(context, sub),
        ],
        if (on) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedPanel(
            child: SettingRow(
              key: const ValueKey('download-lyrics-skip-sounds'),
              title: l10n.downloadLyricsSkipSounds,
              description: l10n.downloadLyricsSkipSoundsHint,
              trailing: AppSwitch(
                value: _skipSounds,
                onChanged: _setSkipSounds,
              ),
              onTap: () => _setSkipSounds(!_skipSounds),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.downloadImportLyricsHint,
            style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
          ),
        ],
        // 자막 표 아래: 영상 자막과 따로 가사를 직접 정한다 (파일 · 웹에서 불러오거나 직접 써서, 자막이 없어도 쓸 수 있다).
        // 위 "자막 가져오기" 줄과 같은 카드 모양의 줄이다.
        const SizedBox(height: AppSpacing.sm),
        OutlinedPanel(
          child: SettingRow(
            key: const ValueKey('download-lyrics-edit'),
            title: l10n.lyricsEditTitle,
            description: _custom == null
                ? l10n.downloadLyricsEditHint
                : l10n.downloadLyricsCustom(
                    _custom!
                        .split('\n')
                        .where((l) => l.trim().isNotEmpty)
                        .length,
                  ),
            trailing: _custom == null
                ? Icon(AppIcons.chevronRight, color: p.onSurfaceMuted)
                : PlainButton(
                    key: const ValueKey('download-lyrics-custom-clear'),
                    label: l10n.actionClear,
                    onPressed: () => setState(() {
                      _custom = null;
                      _edited.clear();
                      _lyricsLanguage = null;
                    }),
                  ),
            onTap: _editLyrics,
          ),
        ),
      ],
    );
  }

  /// 직접 정한 가사가 있는데 "이 자막 사용"을 누르면 영상 자막이 덮어써도 되는지 묻는다. 없거나 동의하면 true (동의하면 직접 정한 가사를 지운다).
  Future<bool> _confirmOverwriteCustom() async {
    if (_custom == null) return true;
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.downloadLyricsOverwriteTitle,
      body: l10n.downloadLyricsOverwriteBody,
      confirmLabel: l10n.downloadLyricsOverwriteConfirm,
      cancelLabel: l10n.actionCancel,
    );
    if (!ok || !mounted) return false;
    setState(() => _custom = null);
    return true;
  }

  /// 가사 설정 페이지를 열어 받을 곡의 가사를 직접 정한다. 비워서 저장하면 직접 정한 가사를 지운다.
  Future<void> _editLyrics() async {
    final probe = Track(
      id: 'download',
      title: widget.songTitle(),
      artist: widget.songArtist(),
      album: '',
      duration: Duration.zero,
      uri: '',
      addedAt: DateTime.now(),
    );
    final text = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        builder: (_) => LyricsEditorPage(
          track: probe,
          loadInitial: () async => _custom ?? '',
        ),
      ),
    );
    if (text == null || !mounted) return;
    setState(() => _custom = text.trim().isEmpty ? null : text);
  }

  /// 시스템 언어와 맞는 자막(코드가 같으면 먼저, 아니면 언어만 같은 것), 없으면 첫 자막.
  static String? _systemDefault(List<String> languages) {
    if (languages.isEmpty) return null;
    final locale = PlatformDispatcher.instance.locale;
    final tag = locale.toLanguageTag().toLowerCase();
    final lang = locale.languageCode.toLowerCase();
    String? byLanguage;
    for (final l in languages) {
      final code = l.toLowerCase().replaceAll('_', '-');
      if (code == tag) return l;
      if (byLanguage == null && code.split('-').first == lang) byLanguage = l;
    }
    return byLanguage ?? languages.first;
  }

  void _pickLanguage(String? lang) {
    setState(() => _lyricsLanguage = lang);
  }

  /// 자막 한 벌의 전체 가사 페이지를 열고, "이 자막 사용"이면 그 언어로 고른다.
  Future<void> _openSubtitle(String lang, String name, String kind) async {
    final use = await showSubtitleDetail(
      context,
      url: widget.url,
      language: lang,
      title: name,
      kind: kind,
      skipSounds: _skipSounds,
      selected: language == lang,
      edited: _edited[lang],
      songTitle: widget.songTitle(),
      songArtist: widget.songArtist(),
    );
    if (use == null || !mounted) return;
    // 이 자막의 가사를 "가사 설정"의 가사로 적용한다 (이미 직접 정한 가사가 있으면 덮어써도 되는지 먼저 묻는다).
    // 가사 설정 페이지를 다시 열면 이 가사가 들어 있어 이어서 고칠 수 있다.
    if (!await _confirmOverwriteCustom()) return;
    setState(() {
      _edited[lang] = use.text;
      _custom = use.text.trim().isEmpty ? null : use.text;
    });
    _pickLanguage(lang);
  }

  void _setSkipSounds(bool v) {
    setState(() {
      _skipSounds = v;
      _edited.clear();
    });
  }

  static const _rowsPerColumn = 5;

  /// 자막 표: 한 칸에 5줄씩 세로로 쌓고, 넘치면 오른쪽으로 칸을 늘려 가로로 민다.
  Widget _languageTable(BuildContext context, SubtitleAvailability sub) {
    final l10n = context.l10n;
    final korean = Localizations.localeOf(context).languageCode == 'ko';
    final entries = <({String lang, String name, String kind})>[
      for (final lang in sub.languages)
        (
          lang: lang,
          name: subtitleLanguageLabel(lang, korean: korean),
          kind: sub.automatic.contains(lang)
              ? l10n.downloadSubtitleKindAuto
              : l10n.downloadSubtitleKindManual,
        ),
    ];
    final columns = [
      for (var i = 0; i < entries.length; i += _rowsPerColumn)
        entries.sublist(i, (i + _rowsPerColumn).clamp(0, entries.length)),
    ];
    Widget column(List<({String lang, String name, String kind})> rows) =>
        SizedBox(
          width: columns.length == 1 ? null : 260,
          child: OutlinedPanel(
            child: Column(
              children: [
                _languageRow(
                  context,
                  header: true,
                  language: l10n.downloadSubtitleColLanguage,
                  kind: l10n.downloadSubtitleColKind,
                ),
                for (final r in rows)
                  _languageRow(
                    context,
                    language: r.name,
                    kind: language == r.lang && _custom != null
                        ? '${r.kind} · ${l10n.downloadSubtitleApplied}'
                        : r.kind,
                    selected: language == r.lang,
                    openable: true,
                    onTap: () => _openSubtitle(r.lang, r.name, r.kind),
                  ),
              ],
            ),
          ),
        );
    if (columns.length == 1) return column(columns.single);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            column(columns[i]),
          ],
        ],
      ),
    );
  }

  /// 자막 표의 한 줄: 언어 · 종류 · 고른 표시. [header]면 머리글.
  Widget _languageRow(
    BuildContext context, {
    required String language,
    required String kind,
    bool header = false,
    bool selected = false,
    bool openable = false,
    VoidCallback? onTap,
  }) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final style = header
        ? text.labelSmall?.copyWith(color: p.onSurfaceMuted)
        : text.bodyMedium;
    final kindStyle = header
        ? style
        : text.bodySmall?.copyWith(color: p.onSurfaceMuted);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: header ? null : Border(top: BorderSide(color: p.outline)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(language, style: style)),
            Expanded(flex: 5, child: Text(kind, style: kindStyle)),
            SizedBox(
              width: AppSpacing.lg,
              child: selected
                  ? Icon(
                      AppIcons.check,
                      size: AppSizes.iconSm,
                      color: p.primary,
                    )
                  : openable
                  ? Icon(
                      AppIcons.chevronRight,
                      size: AppSizes.iconSm,
                      color: p.onSurfaceMuted,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
