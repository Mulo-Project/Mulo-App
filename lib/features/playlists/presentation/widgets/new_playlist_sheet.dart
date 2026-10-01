import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../bloc/playlists_cubit.dart';
import 'playlist_card.dart';

/// 새 재생목록: 이름 · (이미지가 없을 때의) 카드 색 · 이미지를 정해 만든다.
/// 만들면 만든 재생목록 id를 돌려주고, 닫으면 null.
Future<String?> showNewPlaylistSheet(BuildContext context) {
  final playlists = context.read<PlaylistsCubit>();
  final covers = context.read<CoverCubit>();
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: playlists),
        BlocProvider.value(value: covers),
      ],
      child: const _NewPlaylistSheet(),
    ),
  );
}

class _NewPlaylistSheet extends StatefulWidget {
  const _NewPlaylistSheet();

  @override
  State<_NewPlaylistSheet> createState() => _NewPlaylistSheetState();
}

class _NewPlaylistSheetState extends State<_NewPlaylistSheet> {
  final _name = TextEditingController();

  /// 고른 카드 색 (null이면 자동).
  int? _colorIndex;

  /// 고른 이미지 파일 (아직 저장 전).
  String? _imagePath;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await context.read<CoverCubit>().pickFile();
    if (path != null && mounted) setState(() => _imagePath = path);
  }

  Future<void> _create() async {
    final playlists = context.read<PlaylistsCubit>();
    final covers = context.read<CoverCubit>();
    final path = _imagePath;
    final made = await playlists.create(
      _name.text,
      // 이미지가 있으면 색은 카드에 보이지 않는다.
      colorIndex: path == null ? _colorIndex : null,
    );
    if (made == null) return;
    if (path != null) {
      await covers.setFromFile(CoverKey.playlist(made.id), path);
    }
    if (mounted) Navigator.of(context).pop(made.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final path = _imagePath;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.playlistNewTitle, style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.playlistNewHint,
                controller: _name,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _create(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  ArtworkBox(
                    image: path == null ? null : FileImage(File(path)),
                    size: 64,
                    radius: AppRadii.md,
                    tone: _colorIndex == null
                        ? GlowTone.primary
                        : GlowTone.values[_colorIndex!],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PillButton(
                      label: path == null
                          ? l10n.playlistNewImage
                          : l10n.playlistNewImageChange,
                      icon: Icons.photo_library_rounded,
                      variant: PillVariant.tonal,
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
              // 색은 이미지가 없을 때만 카드에 보인다.
              if (path == null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.playlistMenuColor, style: text.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ColorDot(
                      label: l10n.playlistColorAuto,
                      tone: GlowTone.primary,
                      auto: true,
                      selected: _colorIndex == null,
                      onTap: () => setState(() => _colorIndex = null),
                    ),
                    for (final tone in GlowTone.values)
                      _ColorDot(
                        label: l10n.playlistColorOption(
                          playlistToneName(l10n, tone),
                        ),
                        tone: tone,
                        selected: _colorIndex == tone.index,
                        onTap: () => setState(() => _colorIndex = tone.index),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PillButton(label: l10n.playlistCreate, onPressed: _create),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카드 색 고르기 동그라미. 자동은 새로고침 표시.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
    this.auto = false,
  });

  final String label;
  final GlowTone tone;
  final bool selected;
  final bool auto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final glow = context.tokens.glow(tone);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: glow,
              ),
              border: Border.all(
                color: selected ? p.accent : p.outline,
                width: selected ? 3 : 1,
              ),
            ),
            child: auto
                ? Icon(Icons.autorenew_rounded, size: 20, color: p.onGlow)
                : (selected
                      ? Icon(Icons.check_rounded, size: 20, color: p.onGlow)
                      : null),
          ),
        ),
      ),
    );
  }
}
