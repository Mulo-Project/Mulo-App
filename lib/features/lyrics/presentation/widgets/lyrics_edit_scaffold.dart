import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'timed_lyrics_controller.dart';
import 'timed_lyrics_field.dart';

/// 가사 글을 고치는 공통 페이지 틀. 플레이어의 "가사 설정"과 받기 전 "가사 상세"가 함께 쓴다.
/// 위쪽 바(제목 · 부제) → 안내 글 → 가사 입력 칸(싱크가 있으면 시간 칸) → 도구 줄 → 취소 · 확인 버튼.
class LyricsEditScaffold extends StatelessWidget {
  const LyricsEditScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.controller,
    required this.showTimes,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryKey,
    this.notice,
    this.fieldHint,
    this.tools = const [],
    this.top,
    this.body,
    this.leadingIcon = AppIcons.close,
  });

  final String title;
  final String? subtitle;
  final TimedLyricsController controller;

  /// 줄마다 싱크 시간 칸을 보이는가.
  final bool showTimes;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Key? primaryKey;

  /// 입력 칸 위의 안내 글.
  final String? notice;

  /// 입력 칸이 비었을 때 보이는 안내.
  final String? fieldHint;

  /// 입력 칸 아래 도구 줄에 놓을 버튼들 (파일 불러오기 등).
  final List<Widget> tools;

  /// 안내 글 아래, 입력 칸 위에 놓을 것 (불러오기 줄 · 불러온 가사 메모 등).
  final Widget? top;

  /// 입력 칸 대신 보일 것 (불러오는 중 · 실패 안내). null이면 입력 칸.
  final Widget? body;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: p.background,
      // 키보드가 올라와도 페이지 레이아웃을 줄이지 않는다 (떠 있는 메모 · 입력칸이 눌리지 않게).
      // 가려지는 입력칸은 입력칸 쪽에서 키보드 높이만큼 더 스크롤해 커서를 보인다.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: title,
              subtitle: subtitle,
              leading: CircleIconButton(
                icon: leadingIcon,
                tooltip: l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (notice != null && body == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    notice!,
                    style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                  ),
                ),
              ),
            ?top,
            Expanded(
              child:
                  body ??
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: TimedLyricsField(
                      controller: controller,
                      showTimes: showTimes,
                      hint: fieldHint,
                    ),
                  ),
            ),
            if (tools.isNotEmpty && body == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(children: tools),
              ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: l10n.actionCancel,
                      variant: PillVariant.tonal,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PillButton(
                      key: primaryKey,
                      label: primaryLabel,
                      icon: AppIcons.check,
                      onPressed: onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
