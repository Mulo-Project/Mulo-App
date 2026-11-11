import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/cover_editor_page.dart';
import '../../../covers/presentation/widgets/cover_hero.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../home/domain/entities/home_summary.dart';
import '../../../home/domain/usecases/home_usecases.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_file_info.dart';
import '../../domain/entities/track_info.dart';
import '../../domain/usecases/library_usecases.dart';
import '../bloc/library_cubit.dart';

/// 곡 상세 정보 화면: 곡의 정보를 모두 보여 주고, 같은 화면에서 제목 · 아티스트 · 앨범 · 장르를 고친다.
/// 위쪽 연필을 누르면 고치는 모드가 되고, "저장"을 누르면 파일 태그부터 쓴 뒤 보관함에 반영한다.
class TrackInfoScreen extends StatefulWidget {
  const TrackInfoScreen({super.key, required this.track});

  final Track track;

  @override
  State<TrackInfoScreen> createState() => _TrackInfoScreenState();
}

class _TrackInfoScreenState extends State<TrackInfoScreen> {
  late Track _track = widget.track;
  var _editing = false;
  var _saving = false;

  /// 앱에서 받은 곡의 원본 주소 (기록이 없으면 null).
  String? _url;

  /// 음악 파일 정보 (크기 · 형식 · 비트레이트 · 샘플레이트). 읽기 전이거나 못 읽으면 null.
  TrackFileInfo? _file;
  TrackPlayStats? _plays;

  late final _title = TextEditingController();
  late final _artist = TextEditingController();
  late final _album = TextEditingController();
  late final _genre = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _genre.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    sl<GetTrackSourceUrl>()(widget.track.id).then((url) {
      if (mounted) setState(() => _url = url);
    });
    sl<GetTrackPlayStats>()(widget.track.id).then((s) {
      if (mounted) setState(() => _plays = s);
    });
    sl<GetTrackFileInfo>()(widget.track).then((info) {
      if (mounted) setState(() => _file = info);
    });
  }

  static String _size(int bytes) {
    const mb = 1024 * 1024;
    return bytes >= mb
        ? '${(bytes / mb).toStringAsFixed(1)} MB'
        : '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  static String? _format(String? mime) => switch (mime) {
    'audio/mpeg' => 'MP3',
    'audio/ogg' || 'application/ogg' || 'audio/opus' => 'Opus / Ogg',
    'audio/mp4' || 'audio/aac' || 'audio/x-m4a' => 'AAC / M4A',
    'audio/flac' || 'audio/x-flac' => 'FLAC',
    'video/mp4' => 'MP4',
    'video/webm' => 'WebM',
    'video/x-matroska' => 'MKV',
    'audio/x-wav' || 'audio/wav' => 'WAV',
    null || '' => null,
    final m => m.replaceFirst(RegExp('^(audio|video)/'), '').toUpperCase(),
  };

  /// 커버 이미지를 이미지 페이지에서 고르고 · 맞추고 · 지운다.
  Future<void> _editImage(CoverArt? art) async {
    final covers = context.read<CoverCubit>();
    final key = CoverKey.track(_track.id);
    final result = await showCoverEditor(
      context,
      art,
      initialQuery: _track.title,
      canRemove: art != null,
    );
    if (result == null) return;
    if (result.removed || result.reverted) {
      await covers.clear(key);
    } else if (result.art != null) {
      await covers.setArt(key, result.art!);
    }
  }

  Future<void> _copyUrl(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.l10n.trackInfoUrlCopied;
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startEdit() {
    _title.text = _track.title;
    _artist.text = _track.artist;
    _album.text = _track.album;
    _genre.text = _track.genre;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    if (_saving || _title.text.trim().isEmpty) return;
    final l10n = context.l10n;
    final library = context.read<LibraryCubit>();
    final player = context.read<NowPlayingCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final info = TrackInfo(
      title: _title.text,
      artist: _artist.text,
      album: _album.text,
      genre: _genre.text,
    );
    setState(() => _saving = true);
    final result = await library.updateInfo(_track.id, info);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result == UpdateInfoResult.tagWriteFailed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.trackEditTagFailed)));
      return;
    }
    if (result != UpdateInfoResult.saved) return;
    final next = _track.withInfo(info.trimmed());
    player.updateTrack(next);
    setState(() {
      _track = next;
      _editing = false;
    });
    messenger.showSnackBar(SnackBar(content: Text(l10n.trackEditSaved)));
  }

  static String _date(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = _track;
    final key = CoverKey.track(t.id);
    String orDash(String v, String unknown) => v.isEmpty ? unknown : v;

    final art = context.select<CoverCubit, CoverArt?>((c) => c.state[key]);
    final colors = context.read<CoverColorCubit>();

    Widget row(String label, String value, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
            ),
          ),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    ),
    );

    final children = <Widget>[
      // 큰 커버: 눌러서 이미지 페이지에서 고르고 맞추고 지운다.
      CoverHero(
        image: coverImageOf(context, key),
        color: coverColorOf(context, key),
        tone: toneFor(t.id),
        onTap: () => _editImage(art),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (_editing) ...[
        AppTextField(label: l10n.trackEditName, controller: _title),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(label: l10n.trackEditArtist, controller: _artist),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(label: l10n.trackEditAlbum, controller: _album),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: l10n.trackEditGenre,
          controller: _genre,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
      ] else ...[
        row(l10n.trackEditName, t.title),
        const AppDivider(),
        row(l10n.trackEditArtist, orDash(t.artist, l10n.trackInfoUnknown)),
        const AppDivider(),
        row(l10n.trackEditAlbum, orDash(t.album, l10n.trackInfoUnknown)),
        const AppDivider(),
        row(l10n.trackEditGenre, orDash(t.genre, l10n.trackInfoUnknown)),
      ],
      const AppDivider(),
      row(l10n.trackInfoDuration, formatDuration(t.duration)),
      const AppDivider(),
      row(l10n.trackInfoAdded, _date(t.addedAt)),
      if (_plays != null) ...[
        const AppDivider(),
        row(
          l10n.trackInfoPlayCount,
          l10n.trackInfoPlayCountValue(_plays!.count),
        ),
        if (_plays!.count > 0) ...[
          const AppDivider(),
          row(l10n.trackInfoListened, formatDuration(_plays!.listened)),
          if (_plays!.lastAt != null) ...[
            const AppDivider(),
            row(l10n.trackInfoLastPlayed, _date(_plays!.lastAt!)),
          ],
        ],
      ],
      const AppDivider(),
      row(
        l10n.trackInfoSource,
        t.source == TrackSource.download
            ? l10n.trackInfoSourceDownload
            : l10n.trackInfoSourceDevice,
      ),
      if (_url != null) ...[
        const AppDivider(),
        row(l10n.trackInfoUrl, _url!, onTap: () => _copyUrl(_url!)),
      ],
      if (_file?.sizeBytes != null) ...[
        const AppDivider(),
        row(l10n.trackInfoFileSize, _size(_file!.sizeBytes!)),
      ],
      if (_format(_file?.mime ?? widget.track.mime) != null) ...[
        const AppDivider(),
        row(
          l10n.trackInfoFormat,
          _format(_file?.mime ?? widget.track.mime)!,
        ),
      ],
      if (_file?.bitrate != null) ...[
        const AppDivider(),
        row(
          l10n.trackInfoBitrate,
          '${(_file!.bitrate! / 1000).round()} kbps',
        ),
      ],
      if (_file?.sampleRate != null) ...[
        const AppDivider(),
        row(
          l10n.trackInfoSampleRate,
          '${(_file!.sampleRate! / 1000).toStringAsFixed(_file!.sampleRate! % 1000 == 0 ? 0 : 1)} kHz',
        ),
      ],
      if (_file?.width != null && _file?.height != null) ...[
        const AppDivider(),
        row(
          l10n.trackInfoResolution,
          '${_file!.width} × ${_file!.height}',
        ),
      ],
      if (t.folder.isNotEmpty) ...[
        const AppDivider(),
        row(l10n.trackInfoFolder, t.folder),
      ],
      const SizedBox(height: AppSpacing.md),
      const AppDivider(),
      const SizedBox(height: AppSpacing.md),
      // 이미지가 없을 때 쓰이는 커버 색.
      SectionTitle(l10n.decorateColor, padded: false),
      const SizedBox(height: AppSpacing.xs),
      ColorPicker(
        selected: coverColorOf(context, key),
        autoLabel: l10n.playlistColorAuto,
        customLabel: l10n.colorCustom,
        optionLabel: l10n.colorOption,
        onChanged: (c) =>
            c == null ? colors.clear(key) : colors.setColor(key, c),
      ),
    ];

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.trackInfoTitle,
                leading: _editing
                    ? CircleIconButton(
                        icon: AppIcons.close,
                        tooltip: l10n.actionCancel,
                        onPressed: () => setState(() => _editing = false),
                      )
                    : const AppBackButton(),
                actions: [
                  if (!_editing)
                    CircleIconButton(
                      icon: AppIcons.edit,
                      tooltip: l10n.trackEditTitle,
                      onPressed: _startEdit,
                    ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screen.copyWith(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.md,
                  ),
                  children: children,
                ),
              ),
              if (_editing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: l10n.trackEditSave,
                      icon: AppIcons.check,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
