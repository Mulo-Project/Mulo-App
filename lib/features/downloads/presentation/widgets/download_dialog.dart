import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/widgets/cover_picker.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/entities/download_source.dart';
import '../bloc/download_queue_cubit.dart';
import '../bloc/download_settings_cubit.dart';
import '../bloc/subtitle_availability_cubit.dart';
import '../bloc/subtitle_preview_cubit.dart';
import 'playlist_picker_dialog.dart';
import 'save_folder_dialog.dart';
import 'subtitle_detail_screen.dart';
import 'subtitle_language_label.dart';

/// 받기 페이지: 제목 · 아티스트 · 장르를 고치고, 저장할 때 넣을 재생목록 · 자막 가사 가져오기를 정한다.
/// "받기"를 누르면 대기열에 넣고 true를 돌려준다 (닫기만 하면 false).
Future<bool> showDownloadDialog(
  BuildContext context, {
  required String title,
  String artist = '',
  String genre = '',
  Quality? quality,
  Duration? duration,
  String? thumbnailUrl,
  required String url,
  List<String>? subtitleLangs,
  List<String> autoSubtitleLangs = const [],
}) async {
  final queue = context.read<DownloadQueueCubit>();
  // 이미 받았거나 받는 중인 곡은 팝업을 열지 않고 알린다.
  if (queue.isDownloaded(url) || queue.isInQueue(url)) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          queue.isDownloaded(url)
              ? l10n.downloadAlreadyDownloaded
              : l10n.downloadAlreadyInQueue,
        ),
      ),
    );
    return false;
  }
  final playlists = context.read<PlaylistsCubit>();
  final settings = context.read<DownloadSettingsCubit>();
  final library = context.read<LibraryCubit>();
  final colors = context.read<CoverColorCubit>();
  final covers = context.read<CoverCubit>();
  final started = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: queue),
          BlocProvider.value(value: playlists),
          BlocProvider.value(value: settings),
          BlocProvider.value(value: library),
          BlocProvider.value(value: colors),
          BlocProvider.value(value: covers),
          BlocProvider(create: (_) => sl<SubtitlePreviewCubit>()),
          BlocProvider(
            create: (_) => sl<SubtitleAvailabilityCubit>()
              ..load(
                url,
                known: subtitleLangs,
                knownAutomatic: autoSubtitleLangs,
              ),
          ),
        ],
        child: DownloadScreen(
          title: title,
          artist: artist,
          genre: genre,
          quality: quality,
          duration: duration,
          thumbnailUrl: thumbnailUrl,
          url: url,
          subtitleLangs: subtitleLangs,
        ),
      ),
    ),
  );
  return started ?? false;
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.genre,
    this.quality,
    required this.url,
    this.duration,
    this.thumbnailUrl,
    this.subtitleLangs,
  });

  /// 영상에 달린 자막 언어. null이면 아직 모른다 (유튜브면 "있으면" 가져오기로 묻는다).
  final List<String>? subtitleLangs;
  final String title;
  final String artist;
  final String genre;
  final Quality? quality;
  final Duration? duration;
  final String? thumbnailUrl;
  final String url;

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  late final _title = TextEditingController(text: widget.title);
  late final _artist = TextEditingController(text: widget.artist);
  late final _genre = TextEditingController(text: widget.genre);
  // 기본 저장 위치로 채워 시작하고, 이 곡만 바꿀 수 있다 (기본값은 설정에서).
  late final _savePath = TextEditingController(
    text: context.read<DownloadSettingsCubit>().state,
  );
  final Set<String> _selected = {};

  // 직접 고른 색. 안 골랐으면 장르의 기본 색을 따라간다 (없으면 자동).
  Color? _picked;
  var _pickedSet = false;
  var _saveAsGenreDefault = false;
  var _importLyrics = false;

  // 가져올 자막 언어. null이면 자동(한국어 → 영어 → 첫 언어).
  String? _lyricsLanguage;
  var _skipSounds = true;

  // 가사 구역은 유튜브 곡만 둔다.
  late final bool _isYoutube = downloadSourceKey(widget.url)
      .startsWith('youtube:');

  // 커버: 유튜브 썸네일(웹 이미지)이 기본. 바꾸면 고른 이미지와 확대 · 위치를 따른다.
  // 웹 이미지는 주소만 쓰고 내려받지 않는다.
  late final CoverArt? _defaultCover = widget.thumbnailUrl == null
      ? null
      : CoverArt.web(widget.thumbnailUrl!);

  Future<void> _changeCover() async {
    final picked = await pickCoverArt(context, initialQuery: _title.text);
    if (picked != null && mounted) setState(() => _cover = picked);
  }

  late CoverArt? _cover = _defaultCover;

  void _resetCover() => setState(() => _cover = _defaultCover);

  Color? _genreColor() {
    final genre = _genre.text.trim();
    if (genre.isEmpty) return null;
    final v = context.read<CoverColorCubit>().state[CoverKey.genre(genre)];
    return v == null ? null : Color(v);
  }

  Color? get _color => _pickedSet ? _picked : _genreColor();

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _genre.dispose();
    _savePath.dispose();
    super.dispose();
  }

  Future<void> _pickPlaylists() async {
    final picked = await showPlaylistPickerDialog(
      context,
      playlists: context.read<PlaylistsCubit>(),
      selected: _selected,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(picked);
    });
  }

  Future<void> _pickFolder() async {
    final settings = context.read<DownloadSettingsCubit>();
    final path = await showSaveFolderDialog(
      context,
      current: _savePath.text,
      pickOther: settings.pickFolder,
    );
    if (path != null && mounted) setState(() => _savePath.text = path);
  }

  Future<void> _start() async {
    final queue = context.read<DownloadQueueCubit>();
    // 같은 곡이 이미 대기열에 있으면 또 넣지 않는다.
    if (queue.isInQueue(widget.url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.downloadAlreadyInQueue)),
      );
      Navigator.of(context).pop(false);
      return;
    }
    final color = _color;
    final subtitleStatus = context
        .read<SubtitleAvailabilityCubit>()
        .state
        .status;
    final colors = context.read<CoverColorCubit>();
    final genre = _genre.text.trim();
    // 이 장르의 기본 색으로 저장하면 다음에 같은 장르를 받을 때 미리 채워진다.
    if (_saveAsGenreDefault && genre.isNotEmpty && color != null) {
      await colors.setColor(CoverKey.genre(genre), color);
    }
    final ok = await queue.enqueue(
      DownloadRequest(
        title: _title.text,
        artist: _artist.text,
        genre: _genre.text,
        playlistIds: _selected,
        quality: widget.quality,
        savePath: _savePath.text,
        duration: widget.duration,
        color: color?.toARGB32(),
        thumbnailUrl: widget.thumbnailUrl,
        cover: _cover,
        url: widget.url,
        importLyrics:
            _isYoutube &&
            _importLyrics &&
            subtitleStatus != SubtitleStatus.none,
        lyricsLanguage: _lyricsLanguage,
        lyricsSkipSounds: _skipSounds,
      ),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  /// 자막이 있는지(확인 중 · 있음 · 없음 · 모름) 보여 주고, 가져올지 · 어떤 언어로 가져올지 정한다.
  Widget _lyricsSection(BuildContext context, SubtitleAvailability sub) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final none = sub.status == SubtitleStatus.none;
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
        DecoratedBox(
          decoration: ShapeDecoration(
            color: p.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              side: BorderSide(color: p.outline),
            ),
          ),
          child: SettingRow(
            key: const ValueKey('download-import-lyrics'),
            title: l10n.downloadImportLyrics,
            description: status,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sub.status == SubtitleStatus.checking) ...[
                  SizedBox.square(
                    dimension: AppSizes.iconSm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                AppSwitch(
                  value: on,
                  onChanged: none
                      ? null
                      : (v) => setState(() => _importLyrics = v),
                ),
              ],
            ),
            onTap: none
                ? null
                : () => setState(() => _importLyrics = !_importLyrics),
          ),
        ),
        if (on && sub.languages.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.downloadSubtitleLanguage, style: text.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          _languageTable(context, sub),
        ],
        if (on) ...[
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: ShapeDecoration(
              color: p.surfaceHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                side: BorderSide(color: p.outline),
              ),
            ),
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
          const SizedBox(height: AppSpacing.sm),
          _lyricsPreview(context),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.downloadImportLyricsHint,
            style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
          ),
        ],
      ],
    );
  }

  void _pickLanguage(String? lang) {
    setState(() => _lyricsLanguage = lang);
    context.read<SubtitlePreviewCubit>().clear();
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
      selected: _lyricsLanguage == lang,
    );
    if (use == true && mounted) _pickLanguage(lang);
  }

  void _setSkipSounds(bool v) {
    setState(() => _skipSounds = v);
    context.read<SubtitlePreviewCubit>().clear();
  }

  static const _rowsPerColumn = 5;

  /// 자막 표: 한 칸에 5줄씩 세로로 쌓고, 넘치면 오른쪽으로 칸을 늘려 가로로 민다.
  Widget _languageTable(BuildContext context, SubtitleAvailability sub) {
    final l10n = context.l10n;
    final p = context.palette;
    final korean = Localizations.localeOf(context).languageCode == 'ko';
    final entries = <({String? lang, String name, String kind})>[
      (
        lang: null,
        name: l10n.downloadSubtitleAuto,
        kind: l10n.downloadSubtitleAutoHint,
      ),
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
    Widget column(List<({String? lang, String name, String kind})> rows) =>
        SizedBox(
          width: columns.length == 1 ? null : 260,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: p.surfaceHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                side: BorderSide(color: p.outline),
              ),
            ),
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
                    kind: r.kind,
                    selected: _lyricsLanguage == r.lang,
                    openable: r.lang != null,
                    onTap: () => r.lang == null
                        ? _pickLanguage(null)
                        : _openSubtitle(r.lang!, r.name, r.kind),
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

  /// 가져올 자막의 앞부분을 받기 전에 읽어 본다.
  Widget _lyricsPreview(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return BlocBuilder<SubtitlePreviewCubit, SubtitlePreview>(
      builder: (context, preview) {
        final loading = preview.status == SubtitlePreviewStatus.loading;
        final track = preview.track;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PillButton(
              key: const ValueKey('download-lyrics-preview'),
              label: loading
                  ? l10n.downloadLyricsPreviewLoading
                  : l10n.downloadLyricsPreview,
              icon: AppIcons.lyrics,
              busy: loading,
              compact: true,
              variant: PillVariant.tonal,
              onPressed: loading
                  ? null
                  : () => context.read<SubtitlePreviewCubit>().load(
                      widget.url,
                      language: _lyricsLanguage,
                      skipSounds: _skipSounds,
                    ),
            ),
            if (preview.status == SubtitlePreviewStatus.failed) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.downloadLyricsPreviewFailed,
                style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
              ),
            ],
            if (track != null) ...[
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: p.surfaceHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    side: BorderSide(color: p.outline),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.downloadLyricsPreviewOf(
                          subtitleLanguageLabel(
                            track.language,
                            korean:
                                Localizations.localeOf(context).languageCode ==
                                'ko',
                          ),
                          track.cues.length,
                        ),
                        style: text.labelSmall?.copyWith(
                          color: p.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final cue in track.cues.take(_previewLines))
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xxs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  _clock(cue.start),
                                  style: text.bodySmall?.copyWith(
                                    color: p.onSurfaceMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(cue.text, style: text.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static const _previewLines = 8;

  static String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: l10n.downloadDialogTitle,
              leading: CircleIconButton(
                icon: AppIcons.back,
                tooltip: l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  _CoverRow(
                    art: _cover,
                    label: l10n.downloadFieldCover,
                    changeLabel: l10n.downloadCoverChange,
                    resetLabel: l10n.downloadCoverDefault,
                    canReset: _cover != _defaultCover,
                    onChange: _changeCover,
                    onReset: _resetCover,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.downloadFieldTitle,
                    controller: _title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: l10n.downloadFieldArtist,
                    controller: _artist,
                    hint: l10n.unknownArtist,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: l10n.downloadFieldGenre,
                    controller: _genre,
                  ),
                  _GenreSuggestions(
                    controller: _genre,
                    label: l10n.downloadGenreExisting,
                  ),
                  _section(context, l10n.decorateColor, [
                    ListenableBuilder(
                      listenable: _genre,
                      builder: (_, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ColorPicker(
                            selected: _color,
                            autoLabel: l10n.playlistColorAuto,
                            customLabel: l10n.colorCustom,
                            optionLabel: l10n.colorOption,
                            onChanged: (c) => setState(() {
                              _picked = c;
                              _pickedSet = true;
                            }),
                          ),
                          if (_genre.text.trim().isNotEmpty && _color != null)
                            SettingRow(
                              title: l10n.downloadColorSaveForGenre(
                                _genre.text.trim(),
                              ),
                              trailing: AppSwitch(
                                value: _saveAsGenreDefault,
                                onChanged: (v) =>
                                    setState(() => _saveAsGenreDefault = v),
                              ),
                              onTap: () => setState(
                                () =>
                                    _saveAsGenreDefault = !_saveAsGenreDefault,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                  _section(context, l10n.downloadSectionSave, [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: l10n.downloadFieldSavePath,
                            controller: _savePath,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        CircleIconButton(
                          icon: AppIcons.folderOpen,
                          tooltip: l10n.downloadPickFolder,
                          onPressed: _pickFolder,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.downloadPlaylistsLabel.toUpperCase(),
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    _PlaylistPickRow(
                      summary: _selected.isEmpty
                          ? l10n.downloadPlaylistsNone
                          : l10n.downloadPlaylistsSelected(_selected.length),
                      onTap: _pickPlaylists,
                    ),
                  ]),
                  if (_isYoutube)
                    _section(context, l10n.downloadSectionLyrics, [
                      BlocBuilder<
                        SubtitleAvailabilityCubit,
                        SubtitleAvailability
                      >(
                        builder: (context, sub) => _lyricsSection(context, sub),
                      ),
                    ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: l10n.actionCancel,
                      variant: PillVariant.tonal,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ListenableBuilder(
                      listenable: _title,
                      builder: (_, _) => PillButton(
                        label: l10n.actionDownload,
                        icon: AppIcons.download,
                        onPressed: _title.text.trim().isEmpty ? null : _start,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 페이지 맨 위의 커버: 작은 정사각형 + 바꾸기 · 기본으로. 상자 없이 한 줄로 둔다.
class _CoverRow extends StatelessWidget {
  const _CoverRow({
    required this.art,
    required this.label,
    required this.changeLabel,
    required this.resetLabel,
    required this.canReset,
    required this.onChange,
    required this.onReset,
  });

  final CoverArt? art;
  final String label;
  final String changeLabel;
  final String resetLabel;
  final bool canReset;
  final VoidCallback onChange;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        GestureDetector(
          onTap: onChange,
          child: ArtworkBox(
            image: art == null ? null : imageOfCoverArt(art!),
            size: 72,
            radius: AppRadii.sm,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  PillButton(
                    label: changeLabel,
                    icon: AppIcons.photoLibrary,
                    compact: true,
                    variant: PillVariant.tonal,
                    onPressed: onChange,
                  ),
                  if (canReset)
                    PillButton(
                      label: resetLabel,
                      icon: AppIcons.restart,
                      compact: true,
                      variant: PillVariant.tonal,
                      onPressed: onReset,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 재생목록 줄: 고른 개수를 보여 주고, 누르면 고르는 대화상자를 연다.
class _PlaylistPickRow extends StatelessWidget {
  const _PlaylistPickRow({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: ShapeDecoration(
        color: p.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(color: p.outline),
        ),
      ),
      child: SettingRow(
        title: summary,
        onTap: onTap,
        trailing: Icon(AppIcons.chevronRight, color: p.onSurfaceMuted),
      ),
    );
  }
}

/// 보관함에 이미 있는 장르를 많은 순서로 보여 주고, 누르면 장르 칸을 그 장르로 채운다.
class _GenreSuggestions extends StatelessWidget {
  const _GenreSuggestions({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tracks = context.select((LibraryCubit c) => c.state).tracks;
    final counts = <String, int>{};
    for (final t in tracks) {
      final g = t.genre.trim();
      if (g.isNotEmpty) counts[g] = (counts[g] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final genres =
        (counts.keys.toList()..sort((a, b) {
              final byCount = counts[b]!.compareTo(counts[a]!);
              return byCount != 0 ? byCount : a.compareTo(b);
            }))
            .take(12)
            .toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final g in genres)
                  PillButton(
                    label: g,
                    compact: true,
                    variant: PillVariant.tonal,
                    selected: controller.text.trim() == g,
                    onPressed: () => controller.text = g,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
