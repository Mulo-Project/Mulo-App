import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../bloc/playlists_cubit.dart';

/// 새 재생목록: 이름 · (이미지가 없을 때의) 카드 색 · 이미지를 정해 만든다.
/// 만들면 만든 재생목록 id를 돌려주고, 닫으면 null.
Future<String?> showNewPlaylistSheet(BuildContext context) {
  final playlists = context.read<PlaylistsCubit>();
  final covers = context.read<CoverCubit>();
  final colors = context.read<CoverColorCubit>();
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
        BlocProvider.value(value: colors),
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
  Color? _color;

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
    final colors = context.read<CoverColorCubit>();
    final path = _imagePath;
    final color = _color;
    final made = await playlists.create(_name.text);
    if (made == null) return;
    // 이미지가 있으면 색은 카드에 보이지 않는다.
    if (path == null && color != null) {
      await colors.setColor(CoverKey.playlist(made.id), color);
    }
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
                    radius: AppRadii.sm,
                    color: _color,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PillButton(
                      label: path == null
                          ? l10n.playlistNewImage
                          : l10n.playlistNewImageChange,
                      icon: AppIcons.photoLibrary,
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
                ColorPicker(
                  selected: _color,
                  autoLabel: l10n.playlistColorAuto,
                  customLabel: l10n.colorCustom,
                  optionLabel: l10n.colorOption,
                  onChanged: (c) => setState(() => _color = c),
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
