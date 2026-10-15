import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/widgets/cover_picker.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_request.dart';
import '../bloc/download_queue_cubit.dart';
import '../bloc/download_settings_cubit.dart';
import 'playlist_picker_dialog.dart';
import 'save_folder_dialog.dart';

/// 받기 팝업: 제목 · 아티스트 · 장르를 고치고, 저장할 때 넣을 재생목록을 고른다.
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
  final started = await showAppSheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: queue),
        BlocProvider.value(value: playlists),
        BlocProvider.value(value: settings),
        BlocProvider.value(value: library),
        BlocProvider.value(value: colors),
        BlocProvider.value(value: covers),
      ],
      child: _DownloadSheet(
        title: title,
        artist: artist,
        genre: genre,
        quality: quality,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
        url: url,
      ),
    ),
  );
  return started ?? false;
}

class _DownloadSheet extends StatefulWidget {
  const _DownloadSheet({
    required this.title,
    required this.artist,
    required this.genre,
    this.quality,
    required this.url,
    this.duration,
    this.thumbnailUrl,
  });

  final String title;
  final String artist;
  final String genre;
  final Quality? quality;
  final Duration? duration;
  final String? thumbnailUrl;
  final String url;

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
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
      ),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        // 키보드가 올라오면 그만큼 띄운다.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: appSheetPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.downloadDialogTitle, style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
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
              AppTextField(label: l10n.downloadFieldTitle, controller: _title),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: l10n.downloadFieldArtist,
                controller: _artist,
                hint: l10n.unknownArtist,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: l10n.downloadFieldGenre, controller: _genre),
              _GenreSuggestions(
                controller: _genre,
                label: l10n.downloadGenreExisting,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.decorateColor, style: text.labelLarge),
              const SizedBox(height: AppSpacing.xs),
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
                          () => _saveAsGenreDefault = !_saveAsGenreDefault,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}

/// 팝업 맨 위의 커버: 작은 정사각형 + 바꾸기 · 기본으로. 상자 없이 한 줄로 둔다.
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

/// 팝업의 재생목록 줄: 고른 개수를 보여 주고, 누르면 고르는 대화상자를 연다.
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
