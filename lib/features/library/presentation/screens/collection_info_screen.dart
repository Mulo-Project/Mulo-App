import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/cover_editor_page.dart';
import '../../../covers/presentation/widgets/cover_hero.dart';

/// 재생목록 · 앨범 · 아티스트 · 장르의 정보 화면을 연다. 이름을 바꿨으면 새 이름을, 아니면 null을 돌려준다.
/// (이미지와 색은 화면에서 바로 저장된다. 이름을 실제로 바꾸는 일은 부른 쪽이 맡는다.)
Future<String?> showCollectionInfo(
  BuildContext context, {
  required String screenTitle,
  required String title,
  required String nameLabel,
  required String coverKey,
  String? subtitle,
  GlowTone tone = GlowTone.neutral,
  IconData icon = AppIcons.musicNote,
  bool circle = false,
  bool allowRename = true,
  bool allowColor = true,
  bool allowEmptyName = false,
  String initialName = '',
}) => Navigator.of(context, rootNavigator: true).push<String>(
  MaterialPageRoute(
    builder: (_) => CollectionInfoScreen(
      screenTitle: screenTitle,
      title: title,
      nameLabel: nameLabel,
      coverKey: coverKey,
      subtitle: subtitle,
      tone: tone,
      icon: icon,
      circle: circle,
      allowRename: allowRename,
      allowColor: allowColor,
      allowEmptyName: allowEmptyName,
      initialName: initialName,
    ),
  ),
);

class CollectionInfoScreen extends StatefulWidget {
  const CollectionInfoScreen({
    super.key,
    required this.screenTitle,
    required this.title,
    required this.nameLabel,
    required this.coverKey,
    this.subtitle,
    this.tone = GlowTone.neutral,
    this.icon = AppIcons.musicNote,
    this.circle = false,
    this.allowRename = true,
    this.allowColor = true,
    this.allowEmptyName = false,
    this.initialName = '',
  });

  final String screenTitle;

  /// 화면에 보이는 이름 (비어 있으면 "알 수 없는 …" 같은 표시용 글).
  final String title;
  final String nameLabel;
  final String coverKey;
  final String? subtitle;
  final GlowTone tone;
  final IconData icon;
  final bool circle;
  final bool allowRename;
  final bool allowColor;

  /// 이름을 비워 저장해도 되는가 (아티스트 · 앨범 · 장르는 비우면 "알 수 없는 …").
  final bool allowEmptyName;

  /// 입력칸에 처음 채울 실제 이름 (곡에 저장된 값 그대로).
  final String initialName;

  @override
  State<CollectionInfoScreen> createState() => _CollectionInfoScreenState();
}

class _CollectionInfoScreenState extends State<CollectionInfoScreen> {
  late final _name = TextEditingController(text: widget.initialName);
  var _editing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _editImage(CoverArt? art) async {
    final covers = context.read<CoverCubit>();
    final result = await showCoverEditor(
      context,
      art,
      initialQuery: widget.title,
      canRemove: art != null,
    );
    if (result == null) return;
    if (result.removed || result.reverted) {
      await covers.clear(widget.coverKey);
    } else if (result.art != null) {
      await covers.setArt(widget.coverKey, result.art!);
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty && !widget.allowEmptyName) return;
    if (name == widget.initialName.trim()) {
      setState(() => _editing = false);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final key = widget.coverKey;
    final art = context.select<CoverCubit, CoverArt?>((c) => c.state[key]);
    final colors = context.read<CoverColorCubit>();
    final color = coverColorOf(context, key);

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: widget.screenTitle,
                leading: _editing
                    ? CircleIconButton(
                        icon: AppIcons.close,
                        tooltip: l10n.actionCancel,
                        onPressed: () => setState(() => _editing = false),
                      )
                    : const AppBackButton(),
                actions: [
                  if (widget.allowRename && !_editing)
                    CircleIconButton(
                      icon: AppIcons.edit,
                      tooltip: widget.nameLabel,
                      onPressed: () => setState(() => _editing = true),
                    ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screen.copyWith(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.md,
                  ),
                  children: [
                    CoverHero(
                      image: coverImageOf(context, key),
                      color: color,
                      tone: widget.tone,
                      icon: widget.icon,
                      circle: widget.circle,
                      onTap: () => _editImage(art),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_editing)
                      AppTextField(
                        label: widget.nameLabel,
                        controller: _name,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      )
                    else ...[
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: text.titleLarge,
                      ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Text(
                            widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: p.onSurfaceMuted,
                            ),
                          ),
                        ),
                    ],
                    if (widget.allowColor) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const AppDivider(),
                      const SizedBox(height: AppSpacing.md),
                      // 이미지가 없을 때 쓰이는 커버 색.
                      SectionTitle(l10n.decorateColor, padded: false),
                      const SizedBox(height: AppSpacing.xs),
                      ColorPicker(
                        selected: color,
                        autoLabel: l10n.playlistColorAuto,
                        customLabel: l10n.colorCustom,
                        optionLabel: l10n.colorOption,
                        onChanged: (c) => c == null
                            ? colors.clear(key)
                            : colors.setColor(key, c),
                      ),
                    ],
                  ],
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
                      onPressed: _save,
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
