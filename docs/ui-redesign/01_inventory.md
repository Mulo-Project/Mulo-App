# 01. 인벤토리 (develop @ 9aa8172, 코드 직접 확인)

신뢰도 표기: 코드 확인 = 파일 목록/호출처 검색으로 확인, 추정 = 캡처 없이 판단.

## 1. 화면 (`features/*/presentation/screens`)
| 영역 | 화면 파일 |
|---|---|
| 탭 5개 (보관함 → 재생목록 → 홈 → 검색 → 설정) | `library_screen`, `playlists_screen`, `home_screen`, `search_screen`, `settings_screen` |
| 보관함 하위 | `track_group_screen` + `artist_screen` / `album_screen` / `genre_screen` |
| 홈 하위 | `top_tracks_screen` |
| 재생목록 하위 | `playlist_detail_screen`, `playlist_add_tracks_screen`, `playlist_pick_screen`, `playlist_import_screen` |
| 검색 하위 | `media_detail_screen` (+ 다운로드 설정 화면 `download_dialog.dart`, 일반 dialog가 아니라 긴 편집 화면) |
| 플레이어 | `player_screen`(Square / Full Bleed / Arc), `queue_screen`, `equalizer_screen` |
| 구독 | `subscriptions_screen`, `my_subscriptions_screen`, `channel_search_screen` |
| 가사 | `lyrics_full_screen`, `lyrics_latency_screen`, `lyrics_sync_screen`, `lyrics_web_screen` (+ LyricsEditorPage) |
| 기타 | `pin_entry_screen`, `cover_editor_page`, SubtitleDetailScreen |
| 앱 셸 | `app/app_shell.dart`, `mini_float_layer.dart` (MiniPlayerBar · DownloadBar · 플로팅 버튼 · NewVideosBanner) |

명세에 적힌 route는 `lib/app/router.dart` 기준으로 대조 완료(탭 5 + 하위 `artist/genre/album/pick/import/:id/add/:id/top-tracks/subscriptions/equalizer/channel-search/channel-import` + root `queue`, `player`). 상세한 route ↔ 화면 대조는 P0 작업 단위 0에서 다시 한다.

## 2. 공통 컴포넌트 (`lib/core/design/components`, 호출 파일 수 = components 밖 사용처)
| 군 | 컴포넌트 | 사용처(파일 수) | 변경 파급 |
|---|---|---|---|
| 상단/하단 | AppTopBar 27, AppBottomNav 1 | 매우 큼 | 높음 |
| 행/목록 | TrackTile 16, TrackListTile(library), MenuRow | 큼 | 높음 |
| 버튼 | PillButton 47, CircleIconButton 22, PlainButton 13, RowIconButton 11 | 매우 큼 | 높음 |
| 입력/선택 | AppSearchField 6, SegmentedPills 9, AppDropdown 2, AppSwitch 10, AppSlider 4, AppTextField, ColorPicker, PinPad, WheelPicker | 중간 | 중간 |
| 이미지 | ArtworkBox 12, CoverCard 3 | 중간 | 중간 |
| 면 | GlassSurface 4, GlassCard 1, SectionCard 12, SettingRow 18, OutlinedPanel | 중간 | 중간 |
| 상태 | EmptyState 19, LoadingState 9, LoadingIndicator | 큼 | 낮음~중간 |
| 오버레이 | AppDialog(20 파일), showAppSheet(17), showAppMenu / AppPopupMenu(7) | 큼 | 높음 |
| 플레이어 | MiniPlayerBar, FloatingPlayerButton, ProgressRing/Line, MarqueeText, ExpandableText | 셸 | 중간 |

호출처 전체 목록은 컴포넌트별 작업 단위 시작 때 grep으로 다시 만든다.

## 3. Dialog / Sheet / Menu / Overlay (코드 확인)
- **Sheet (`showAppSheet`, 16 파일)**: decorate_sheet, playlist_picker_sheet, save_folder_sheet, device_equalizer_section, hidden_records_sheet, library_selection, loaded_folders_sheet, lyric_time_sheet, player_style_sheet, channel_pick_sheet, new_playlist_sheet, audio_language_sheet, my_subscriptions_screen, channel_info_sheet, channel_options_sheet, new_videos_sheet.
- **Dialog (`AppDialog`/`showConfirmDialog`, 19 파일)**: sign_in_flow, cover_editor_page, download_dialog, download_item_widgets, download_lyrics_section, equalizer_screen, track_group_screen, hidden_records_sheet, library_selection, loaded_folders_sheet, rename_progress, track_menu, lyrics_dialogs, queue_screen, player_sleep_timer, playlist_menu, settings_engine_sections, my_subscriptions_screen, new_videos_sheet.
- **Menu**: app_popup_menu(공통), app_dropdown, history_section(연도/월), track_menu, playlist_menu, lyrics_sync_screen, lyric_time_sheet, search_screen(정렬), search_source_menu(출처).
- **Overlay**: `lyrics_import_bar.dart`의 OverlayEntry(Lyrics Memo, 이동 · 크기 조절). 셸 계층: MiniPlayerBar / DownloadBar / FloatingPlayerButton / DownloadFloatButton / NewVideosBanner.
- 별도 route형: DownloadScreen, CoverEditor, SubtitleDetail, Lyrics*, PIN, LyricsFullScreen(PageRouteBuilder + fade).

## 4. 문서-코드 확인 필요 항목
- 라이트 강조색 대비 기준: `docs/design-system.md`는 "배경 대비 3:1로 보정", 프리셋 설명은 "강조색 대비 7:1 이상(다크)". `app_palette.dart` 실제 값과 `contrast.dart` 호출을 대조해야 한다 (테마 감사 작업 단위).
- 스크린샷 테스트(`test/screenshots/screenshots_test.dart`)는 `skip: true` 상태. 이번 계획에서 실행하지 않았다.
