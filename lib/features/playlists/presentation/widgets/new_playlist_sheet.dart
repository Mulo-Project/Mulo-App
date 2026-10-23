import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/cover_editor_page.dart';
import '../../../covers/presentation/widgets/cover_settings_section.dart';
import '../bloc/playlists_cubit.dart';

/// 새 재생목록: 이름 · (이미지가 없을 때의) 카드 색 · 이미지를 정해 만든다.
/// 만들면 만든 재생목록 id를 돌려주고, 닫으면 null.
Future<String?> showNewPlaylistSheet(BuildContext context) {
  final playlists = context.read<PlaylistsCubit>();
  final covers = context.read<CoverCubit>();
  final colors = context.read<CoverColorCubit>();
  return showAppSheet<String>(
    context,
    isScrollControlled: true,
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

  /// 고른 이미지 (아직 저장 전).
  CoverArt? _art;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// 이미지 페이지(꾸미기 · 받기와 같은 것)를 열어 지금 이미지를 불러온 채로 고른다.
  Future<void> _pickImage() async {
    final result = await showCoverEditor(
      context,
      _art,
      initialQuery: _name.text,
      canRevert: _art != null,
    );
    if (result == null || !mounted) return;
    setState(() => _art = result.reverted ? null : result.art);
  }

  Future<void> _create() async {
    final playlists = context.read<PlaylistsCubit>();
    final covers = context.read<CoverCubit>();
    final colors = context.read<CoverColorCubit>();
    final art = _art;
    final color = _color;
    final made = await playlists.create(_name.text);
    if (made == null) return;
    // 이미지가 있으면 색은 카드에 보이지 않는다.
    if (art == null && color != null) {
      await colors.setColor(CoverKey.playlist(made.id), color);
    }
    if (art != null) await covers.setArt(CoverKey.playlist(made.id), art);
    if (mounted) Navigator.of(context).pop(made.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final art = _art;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
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
              // 꾸미기 시트와 같은 설정 구역. 색은 이미지가 없을 때만 카드에 보인다.
              CoverSettingsSection(
                image: art == null ? null : imageOfCoverArt(art),
                color: _color,
                icon: AppIcons.playlistPlay,
                showColor: art == null,
                onEditImage: _pickImage,
                onColorChanged: (c) => setState(() => _color = c),
              ),
              const SizedBox(height: AppSpacing.lg),
              PillButton(label: l10n.playlistCreate, onPressed: _create),
            ],
          ),
        ),
      ),
    );
  }
}
