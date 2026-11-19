import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/config/default_video_folder.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/widgets/cover_editor_page.dart';
import '../../../covers/presentation/widgets/cover_entry.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/entities/download_source.dart';
import '../../../search/presentation/bloc/audio_language_cubit.dart';
import '../../../search/presentation/widgets/audio_language_sheet.dart';
import '../../domain/usecases/download_usecases.dart';
import '../../../../core/usecase/usecase.dart';
import '../bloc/download_preferences_cubit.dart';
import '../bloc/download_queue_cubit.dart';
import '../bloc/download_settings_cubit.dart';
import '../bloc/subtitle_availability_cubit.dart';
import 'download_lyrics_section.dart';
import 'playlist_picker_sheet.dart';
import 'save_folder_sheet.dart';

/// 받기 페이지: 제목 · 아티스트 · 장르를 고치고, 저장할 때 넣을 재생목록 · 자막 가사 가져오기를 정한다.
/// "받기"를 누르면 대기열에 넣고 true를 돌려준다 (닫기만 하면 false).
Future<bool> showDownloadDialog(
  BuildContext context, {
  required String title,
  String artist = '',
  String album = '',
  String genre = '',
  Duration? duration,
  String? thumbnailUrl,
  required String url,
  List<String>? subtitleLangs,
  List<String> autoSubtitleLangs = const [],
  String? audioLanguage,
}) async {
  final queue = context.read<DownloadQueueCubit>();
  // 이미 받는 중이거나 대기 중인 곡은 팝업을 열지 않고 알린다. (이미 받은 곡은 막지 않는다.)
  if (queue.isInQueue(url)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.downloadAlreadyInQueue)),
    );
    return false;
  }
  final started = await _pushDownloadScreen<bool>(
    context,
    mode: DownloadScreenMode.enqueue,
    title: title,
    artist: artist,
    album: album,
    genre: genre,
    duration: duration,
    thumbnailUrl: thumbnailUrl,
    url: url,
    subtitleLangs: subtitleLangs,
    autoSubtitleLangs: autoSubtitleLangs,
    audioLanguage: audioLanguage,
  );
  return started ?? false;
}

/// 곡 받기 창을 "받지 않고 설정만 고르는" 모드로 연다 (재생목록 가져오기의 곡별 설정).
/// [preset]이 있으면 그 값으로 채워 열고([canReset]이면 "공통 설정으로" 버튼도 보인다), 적용하면 설정을 담은 요청을, 공통 설정으로 되돌리면
/// [DownloadSettingsReset]을, 닫으면 null을 돌려준다.
Future<Object?> showTrackDownloadSettings(
  BuildContext context, {
  required String title,
  String artist = '',
  String album = '',
  String genre = '',
  Duration? duration,
  String? thumbnailUrl,
  required String url,
  List<String>? subtitleLangs,
  List<String> autoSubtitleLangs = const [],
  DownloadRequest? preset,
  bool canReset = false,
}) => _pushDownloadScreen<Object>(
  context,
  canReset: canReset,
  mode: DownloadScreenMode.collectTrack,
  title: title,
  artist: artist,
  album: album,
  genre: genre,
  duration: duration,
  thumbnailUrl: thumbnailUrl,
  url: url,
  subtitleLangs: subtitleLangs,
  autoSubtitleLangs: autoSubtitleLangs,
  preset: preset,
);

/// 곡 받기 창을 "공통 설정" 모드로 연다: 곡 하나에 묶이는 칸(제목 · 이미지 · 앨범 · 재생목록 · 가사)은 숨기고,
/// 아티스트 · 장르 · 색 · 저장 유형 · 형식 · 폴더만 고른다. 적용하면 그 값을 담은 요청을 돌려준다.
Future<DownloadRequest?> showCommonDownloadSettings(
  BuildContext context, {
  DownloadRequest? preset,
}) async {
  final result = await _pushDownloadScreen<Object>(
    context,
    mode: DownloadScreenMode.collectCommon,
    title: '',
    url: '',
    preset: preset,
  );
  return result is DownloadRequest ? result : null;
}

/// [showTrackDownloadSettings]에서 "공통 설정으로"를 눌렀을 때 돌려주는 표시.
class DownloadSettingsReset {
  const DownloadSettingsReset();
}

/// 곡 받기 창이 하는 일: 대기열에 넣기, 곡 하나의 설정만 돌려주기, 여러 곡이 함께 쓸 공통 설정만 돌려주기.
enum DownloadScreenMode { enqueue, collectTrack, collectCommon }

Future<T?> _pushDownloadScreen<T extends Object>(
  BuildContext context, {
  required DownloadScreenMode mode,
  required String title,
  String artist = '',
  String album = '',
  String genre = '',
  Duration? duration,
  String? thumbnailUrl,
  required String url,
  List<String>? subtitleLangs,
  List<String> autoSubtitleLangs = const [],
  String? audioLanguage,
  DownloadRequest? preset,
  bool canReset = false,
}) {
  final queue = context.read<DownloadQueueCubit>();
  final playlists = context.read<PlaylistsCubit>();
  final settings = context.read<DownloadSettingsCubit>();
  final library = context.read<LibraryCubit>();
  final colors = context.read<CoverColorCubit>();
  final covers = context.read<CoverCubit>();
  final common = mode == DownloadScreenMode.collectCommon;
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: queue),
          BlocProvider.value(value: playlists),
          BlocProvider.value(value: settings),
          BlocProvider.value(value: library),
          BlocProvider.value(value: colors),
          BlocProvider.value(value: covers),
          BlocProvider(
            create: (_) {
              final cubit = sl<AudioLanguageCubit>();
              if (!common && downloadSourceKey(url).startsWith('youtube:')) {
                cubit.load(url, selected: audioLanguage);
              }
              return cubit;
            },
          ),
          BlocProvider(
            create: (_) {
              final cubit = sl<SubtitleAvailabilityCubit>();
              if (!common) {
                cubit.load(
                  url,
                  known: subtitleLangs,
                  knownAutomatic: autoSubtitleLangs,
                );
              }
              return cubit;
            },
          ),
        ],
        child: DownloadScreen(
          mode: mode,
          preset: preset,
          canReset: canReset,
          title: title,
          artist: artist,
          album: album,
          genre: genre,
          duration: duration,
          thumbnailUrl: thumbnailUrl,
          url: url,
          subtitleLangs: subtitleLangs,
        ),
      ),
    ),
  );
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({
    super.key,
    required this.title,
    required this.artist,
    this.album = '',
    required this.genre,
    required this.url,
    this.duration,
    this.thumbnailUrl,
    this.subtitleLangs,
    this.mode = DownloadScreenMode.enqueue,
    this.preset,
    this.canReset = false,
  });

  final DownloadScreenMode mode;

  /// 곡별 설정 모드에서 "공통 설정으로" 버튼을 보일지 (이미 따로 정한 곡일 때).
  final bool canReset;

  /// 이미 정해 둔 설정. 있으면 이 값으로 채워 연다 (곡별 · 공통 설정 모드).
  final DownloadRequest? preset;

  /// 영상에 달린 자막 언어. null이면 아직 모른다 (유튜브면 "있으면" 가져오기로 묻는다).
  final List<String>? subtitleLangs;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final Duration? duration;
  final String? thumbnailUrl;
  final String url;

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  late final _title = TextEditingController(text: widget.title);
  late final _artist = TextEditingController(text: widget.artist);
  late final _album = TextEditingController(text: widget.album);
  late final _genre = TextEditingController(text: widget.genre);
  // 고정한 폴더(없으면 마지막에 받은 폴더)로 채워 시작하고, 이 곡만 바꿀 수 있다 (고정은 설정에서).
  late final _savePath = TextEditingController(
    text: context.read<DownloadSettingsCubit>().state,
  );
  final Set<String> _selected = {};

  // 저장 형식: 설정의 기본 형식으로 시작하고, 이 곡만 바꿀 수 있다 (기본값은 설정에서).
  List<AudioFormat> _formats = const [];
  AudioFormat? _format;

  // 직접 고른 색. 안 골랐으면 장르의 기본 색을 따라간다 (없으면 자동).
  Color? _picked;
  var _pickedSet = false;
  var _saveAsGenreDefault = false;
  // 가사 구역(자막 · 가사 설정)은 유튜브 곡만 둔다. 고른 값은 구역이 들고 있다.
  final _lyricsKey = GlobalKey<DownloadLyricsSectionState>();
  late final bool _isYoutube = downloadSourceKey(widget.url)
      .startsWith('youtube:');

  // 커버: 유튜브 썸네일(웹 이미지)이 기본. 바꾸면 고른 이미지와 확대 · 위치를 따른다.
  // 웹 이미지는 주소만 쓰고 내려받지 않는다.
  late final CoverArt? _defaultCover = widget.thumbnailUrl == null
      ? null
      : CoverArt.web(widget.thumbnailUrl!);

  /// 이미지 페이지(곡 · 앨범 · 재생목록과 같은 것)를 열어 지금 이미지를 불러온 채로 고친다.
  /// "기본 이미지로"는 유튜브 썸네일로 돌아간다.
  Future<void> _changeCover() async {
    final result = await showCoverEditor(
      context,
      _cover,
      initialQuery: _title.text,
      canRevert: _cover != _defaultCover,
      canRemove: _cover != null,
    );
    if (result == null || !mounted) return;
    setState(
      () => _cover = result.removed
          ? null
          : result.reverted
          ? _defaultCover
          : result.art,
    );
  }

  late CoverArt? _cover = _defaultCover;

  // 영상 파일(mp4)로 저장: 풀 빌드(Android)에서만 켜진다.
  var _videoAvailable = false;
  // SoundCloud는 소리만 있는 사이트라 영상으로 저장하는 칸을 보이지 않는다.
  // 변환하지 않을 때 저장될 형식 이름 (표시용): 사운드클라우드는 AAC(m4a), 그 밖(유튜브)은 opus.
  String get _originalName => _hasVideo ? 'opus' : 'm4a';

  bool get _hasVideo {
    final host = Uri.tryParse(widget.url)?.host.toLowerCase() ?? '';
    return host != 'soundcloud.com' && !host.endsWith('.soundcloud.com');
  }

  var _asVideo = false;
  bool get _common => widget.mode == DownloadScreenMode.collectCommon;
  bool get _collect => widget.mode != DownloadScreenMode.enqueue;
  // 저장 유형을 바꾸면 폴더 칸도 그 유형의 폴더로 바뀐다 (음원은 음악 폴더, 영상은 `Movies/Mulo`).
  var _otherPath = defaultVideoFolder();
  var _videoFormat = VideoFormat.mp4;
  var _videoHeight = 1080;

  Color? _genreColor() {
    final genre = _genre.text.trim();
    if (genre.isEmpty) return null;
    final v = context.read<CoverColorCubit>().state[CoverKey.genre(genre)];
    return v == null ? null : Color(v);
  }

  Color? get _color => _pickedSet ? _picked : _genreColor();

  @override
  void initState() {
    super.initState();
    _format = context.read<DownloadPreferencesCubit>().state.format;
    _applyPreset();
    sl<IsVideoSaveAvailable>()(const NoParams()).then((ok) {
      if (mounted && ok) setState(() => _videoAvailable = true);
    });
    sl<GetSelectableFormats>()(const NoParams()).then((formats) {
      if (!mounted) return;
      setState(() {
        _formats = formats;
        if (!formats.contains(_format) && formats.isNotEmpty) {
          _format = formats.first;
        }
      });
    });
    // 고정한 폴더가 없으면 마지막에 받은 폴더(없으면 앱 기본 폴더)로 채운다.
    if (_savePath.text.isEmpty) {
      context.read<DownloadSettingsCubit>().effectivePath().then((path) {
        if (!mounted) return;
        if (_asVideo) {
          // 그 사이 영상으로 바꿨으면 음원 폴더 자리([_otherPath])를 채운다.
          if (_otherPath.isEmpty) setState(() => _otherPath = path);
        } else if (_savePath.text.isEmpty) {
          setState(() => _savePath.text = path);
        }
      });
    }
  }

  /// [DownloadScreen.preset]의 값으로 형식 · 저장 유형 · 폴더 · 색 · 이미지 · 재생목록을 채운다.
  void _applyPreset() {
    final preset = widget.preset;
    if (preset == null) return;
    _format = preset.format ?? _format;
    if (preset.color != null) {
      _picked = Color(preset.color!);
      _pickedSet = true;
    }
    if (!_common) {
      _cover = preset.cover ?? _defaultCover;
      _selected.addAll(preset.playlistIds);
    }
    if (preset.videoFormat != null) {
      _asVideo = true;
      _videoFormat = preset.videoFormat!;
      _videoHeight = preset.videoHeight;
      // 폴더 칸은 영상 폴더, 음원 폴더는 반대 칸([_otherPath])에 둔다.
      _otherPath = _savePath.text;
      _savePath.text = preset.savePath.isEmpty
          ? defaultVideoFolder()
          : preset.savePath;
    } else if (preset.savePath.isNotEmpty) {
      _savePath.text = preset.savePath;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _genre.dispose();
    _savePath.dispose();
    super.dispose();
  }

  Future<void> _pickPlaylists() async {
    final picked = await showPlaylistPickerSheet(
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

  void _setAsVideo(bool video) {
    if (video == _asVideo) return;
    setState(() {
      final here = _savePath.text;
      _savePath.text = _otherPath;
      _otherPath = here;
      _asVideo = video;
    });
  }

  Future<void> _pickFolder() async {
    final settings = context.read<DownloadSettingsCubit>();
    if (_asVideo) {
      // 영상은 Movies · Download 중에서만 고른다 (MediaStore가 영상을 받아 주는 위치).
      final path = await showSaveFolderSheet(
        context,
        current: _savePath.text,
        pickOther: settings.pickFolder,
        only: videoFolderPresets(),
      );
      if (path != null && mounted) setState(() => _savePath.text = path);
      return;
    }
    final path = await showSaveFolderSheet(
      context,
      current: _savePath.text,
      pickOther: settings.pickFolder,
    );
    if (path != null && mounted) setState(() => _savePath.text = path);
  }

  Future<void> _start() async {
    final queue = context.read<DownloadQueueCubit>();
    // 같은 곡이 이미 대기열에 있으면 또 넣지 않는다.
    if (!_collect && queue.isInQueue(widget.url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.downloadAlreadyInQueue)),
      );
      Navigator.of(context).pop(false);
      return;
    }
    final color = _color;
    final lyrics = _lyricsKey.currentState;
    final subtitle = context.read<SubtitleAvailabilityCubit>().state;
    final subtitleStatus = subtitle.status;
    final colors = context.read<CoverColorCubit>();
    final audioLanguage = context.read<AudioLanguageCubit>().state.selected;
    final defaultFormat = context.read<DownloadPreferencesCubit>().state.format;
    final genre = _genre.text.trim();
    // 이 장르의 기본 색으로 저장하면 다음에 같은 장르를 받을 때 미리 채워진다.
    if (_saveAsGenreDefault && genre.isNotEmpty && color != null) {
      await colors.setColor(CoverKey.genre(genre), color);
    }
    final request = DownloadRequest(
        title: _title.text,
        artist: _artist.text,
        album: _album.text.trim(),
        genre: _genre.text,
        playlistIds: _selected,
        savePath: _savePath.text,
        duration: widget.duration,
        color: color?.toARGB32(),
        // 이미지를 지웠으면 썸네일도 쓰지 않는다 (커버 없이 받는다).
        thumbnailUrl: _cover == null ? null : widget.thumbnailUrl,
        cover: _cover,
        url: widget.url,
        // 설정의 기본 형식과 같으면 비워 두어, 나중에 기본 형식을 바꿔도 따라가게 한다.
        format: _format == defaultFormat ? null : _format,
        importLyrics:
            _isYoutube &&
            lyrics != null &&
            // 자막 언어 목록이 있으면 사용자가 언어를 골랐을 때만 가져온다 (기본으로 고르지 않는다).
            // 목록을 읽지 못한 경우는 켜 두면 네이티브가 기본 언어(ko · en)로 읽는다.
            ((lyrics.importLyrics &&
                    (lyrics.language != null || subtitle.languages.isEmpty) &&
                    subtitleStatus != SubtitleStatus.none) ||
                lyrics.custom != null),
        lyricsLanguage: lyrics?.language,
        lyricsSkipSounds: lyrics?.skipSounds ?? true,
        lyricsText: lyrics?.lyricsText,
        audioLanguage: audioLanguage,
        // 영상으로 저장하면 음원 전용 설정(오디오 형식 · 오디오 언어)은 쓰지 않는다.
        videoFormat: _videoAvailable && _hasVideo && _asVideo
            ? _videoFormat
            : null,
        videoHeight: _videoHeight,
      );
    // 설정만 고르는 모드는 받지 않고 고른 값을 돌려준다.
    if (_collect) {
      if (mounted) Navigator.of(context).pop(request.normalized());
      return;
    }
    final ok = await queue.enqueue(request);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      SectionBlock(title: title, children: children);

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
              title: switch (widget.mode) {
                DownloadScreenMode.enqueue => l10n.downloadDialogTitle,
                DownloadScreenMode.collectTrack =>
                  l10n.playlistImportTrackSettings,
                DownloadScreenMode.collectCommon =>
                  l10n.playlistImportCommonTitle,
              },
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
                  SectionBlock(
                    first: true,
                    title: l10n.downloadSectionInfo,
                    children: [
                      if (!_common) ...[
                        CoverEntry(
                          image: _cover == null
                              ? null
                              : imageOfCoverArt(_cover!),
                          label: l10n.downloadFieldCover,
                          onTap: _changeCover,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: l10n.downloadFieldTitle,
                          controller: _title,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppTextField(
                        label: l10n.downloadFieldArtist,
                        controller: _artist,
                        // 공통 설정에서 비워 두면 곡마다 올린 채널 이름을 쓴다.
                        hint: _common
                            ? l10n.playlistImportArtistFromChannel
                            : l10n.unknownArtist,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (!_common) ...[
                        AppTextField(
                          label: l10n.downloadFieldAlbum,
                          controller: _album,
                          hint: l10n.unknownAlbum,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppTextField(
                        label: l10n.downloadFieldGenre,
                        controller: _genre,
                      ),
                      _GenreSuggestions(
                        controller: _genre,
                        label: l10n.downloadGenreExisting,
                      ),
                    ],
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
                    if (_videoAvailable && _hasVideo) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.videoSaveType.toUpperCase(),
                        style: text.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      SegmentedPills<bool>(
                        expand: true,
                        values: const [false, true],
                        selected: _asVideo,
                        labelOf: (v) => v
                            ? l10n.videoSaveTypeVideo
                            : l10n.videoSaveTypeAudio,
                        onChanged: _setAsVideo,
                      ),
                    ],
                    if (_asVideo && _hasVideo) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.videoSaveFormat.toUpperCase(),
                        style: text.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      SegmentedPills<VideoFormat>(
                        expand: true,
                        values: VideoFormat.values,
                        selected: _videoFormat,
                        labelOf: (f) => f.name,
                        onChanged: (f) => setState(() => _videoFormat = f),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.videoSaveQuality.toUpperCase(),
                        style: text.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      SegmentedPills<int>(
                        expand: true,
                        values: videoHeights,
                        selected: _videoHeight,
                        labelOf: (h) => '${h}p',
                        onChanged: (h) => setState(() => _videoHeight = h),
                      ),
                    ] else ...[
                      if (_formats.length > 1 && _format != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.settingsFormat.toUpperCase(),
                          style: text.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        SegmentedPills<AudioFormat>(
                          expand: true,
                          values: _formats,
                          selected: _format!,
                          // opus는 변환 없이 받은 원본 그대로: 이 곡의 원본 형식을 함께 보인다.
                          labelOf: (f) => f == AudioFormat.opus
                              ? l10n.downloadFormatOriginal(_originalName)
                              : f.name,
                          onChanged: (f) => setState(() => _format = f),
                        ),
                      ],
                      if (!_common) const AudioLanguageRow(),
                    ],
                    if (!_common) ...[
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
                    ],
                  ]),
                  if (_isYoutube)
                    _section(context, l10n.downloadSectionLyrics, [
                      DownloadLyricsSection(
                        key: _lyricsKey,
                        url: widget.url,
                        songTitle: () => _title.text,
                        songArtist: () => _artist.text,
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
                  if (widget.mode == DownloadScreenMode.collectTrack &&
                      widget.canReset) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PillButton(
                        label: l10n.playlistImportTrackReset,
                        variant: PillVariant.tonal,
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(const DownloadSettingsReset()),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ListenableBuilder(
                      listenable: _title,
                      builder: (_, _) => PillButton(
                        label: _collect
                            ? l10n.downloadApply
                            : l10n.actionDownload,
                        icon: _collect ? null : AppIcons.download,
                        onPressed: !_common && _title.text.trim().isEmpty
                            ? null
                            : _start,
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
