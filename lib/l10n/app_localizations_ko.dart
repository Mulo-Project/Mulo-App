// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '음악';

  @override
  String get navSearch => '검색';

  @override
  String get navDownloads => '다운로드';

  @override
  String get navLibrary => '보관함';

  @override
  String get navPlaylists => '재생목록';

  @override
  String get navSettings => '설정';

  @override
  String get actionPlay => '재생';

  @override
  String get actionPause => '일시정지';

  @override
  String get actionNext => '다음 곡';

  @override
  String get actionPrevious => '이전 곡';

  @override
  String get actionBack => '뒤로';

  @override
  String get actionMore => '더 보기';

  @override
  String get actionDownload => '받기';

  @override
  String get actionPaste => '붙여넣기';

  @override
  String get actionClear => '지우기';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionResume => '이어 받기';

  @override
  String get actionCancel => '취소';

  @override
  String get actionPlayAll => '전체 재생';

  @override
  String get actionShuffle => '셔플';

  @override
  String get unitSongs => '곡';

  @override
  String songCount(int count) {
    return '$count곡';
  }

  @override
  String get searchSubtitle => '찾고 받기';

  @override
  String get searchHint => '유튜브 URL이나 검색어';

  @override
  String get searchEmptyTitle => '무엇을 받을까요?';

  @override
  String get searchEmptyBody =>
      'URL을 붙여넣거나 검색어를 입력하세요.\n유튜브 앱에서 공유를 누르면 바로 여기로 와요.';

  @override
  String get searchResultsTitle => '검색 결과';

  @override
  String get searchUrlCardLabel => 'URL에서 찾은 곡';

  @override
  String get searchPlaylistLabel => '재생목록';

  @override
  String get searchSelectAll => '모두 선택';

  @override
  String searchDownloadSelected(int count) {
    return '$count곡 받기';
  }

  @override
  String get alreadyDownloaded => '이미 받은 곡';

  @override
  String get qualityBest => '최고';

  @override
  String get qualityNormal => '보통';

  @override
  String get qualitySaver => '절약';

  @override
  String get downloadsActive => '진행 중';

  @override
  String downloadsWaiting(int count) {
    return '대기 $count';
  }

  @override
  String get downloadsPauseAll => '모두 일시정지';

  @override
  String get downloadsClearDone => '완료 지우기';

  @override
  String get statusDownloading => '받는 중';

  @override
  String get statusQueued => '대기';

  @override
  String get statusPaused => '일시정지';

  @override
  String get statusFailed => '실패';

  @override
  String get statusDone => '완료';

  @override
  String get downloadsEmpty => '받는 중인 곡이 없어요.';

  @override
  String get librarySubtitle => '내 음악';

  @override
  String get librarySongs => '곡';

  @override
  String get libraryArtists => '아티스트';

  @override
  String get libraryAlbums => '앨범';

  @override
  String get librarySearchHint => '보관함에서 찾기';

  @override
  String get libraryGenres => '장르';

  @override
  String get unknownGenre => '알 수 없는 장르';

  @override
  String get genreBack => '장르 목록으로';

  @override
  String get sortLabel => '정렬';

  @override
  String get sortName => '이름순';

  @override
  String get sortAdded => '추가일순';

  @override
  String get sortArtist => '아티스트순';

  @override
  String get libraryImport => '기기 음악 불러오기';

  @override
  String get libraryNoMatch => '찾는 곡이 없어요.';

  @override
  String get playlistsSubtitle => '모음';

  @override
  String get playlistsNew => '새 재생목록';

  @override
  String get playlistsImport => '유튜브 재생목록 가져오기';

  @override
  String get settingsSubtitle => '앱 설정';

  @override
  String get settingsServer => '서버';

  @override
  String get settingsConnection => '연결 상태';

  @override
  String get settingsDisconnected => '연결 안 됨';

  @override
  String get settingsMode => '다운로드 모드';

  @override
  String get settingsModeServer => '서버';

  @override
  String get settingsModeLocal => '로컬';

  @override
  String get settingsModeLiteNote => 'lite 빌드는 서버 모드만 쓸 수 있어요.';

  @override
  String get settingsDownload => '다운로드';

  @override
  String get settingsSavePath => '저장 위치';

  @override
  String get settingsLoadedFolders => '불러오는 폴더';

  @override
  String settingsLoadedFoldersCount(int count) {
    return '$count개 폴더';
  }

  @override
  String get loadedFoldersHint => '이 폴더 안의 음악을 보관함에 불러와요. 하위 폴더도 포함돼요.';

  @override
  String loadedFoldersTrackCount(int count) {
    return '$count곡';
  }

  @override
  String get loadedFoldersDefault => '기본 저장 위치';

  @override
  String get loadedFoldersAdd => '폴더 추가';

  @override
  String get loadedFoldersRemove => '폴더 빼기';

  @override
  String get loadedFoldersScanning => '보관함을 다시 찾는 중이에요';

  @override
  String get settingsQuality => '기본 음질';

  @override
  String get settingsFormat => '기본 포맷';

  @override
  String get settingsEngine => '다운로드 엔진';

  @override
  String settingsEngineVersion(String current, String latest) {
    return '현재 $current · 최신 $latest';
  }

  @override
  String get settingsEngineUpdate => '업데이트';

  @override
  String get settingsSecurity => '보안';

  @override
  String get settingsAppLock => '앱 잠금';

  @override
  String get settingsChangePin => 'PIN 바꾸기';

  @override
  String get settingsChangePinDesc => '현재 PIN(또는 지문 · 얼굴)을 확인한 뒤 새 PIN으로 바꿔요.';

  @override
  String get settingsAppLockDesc => '앱을 열 때 PIN(4~6자리)을 물어요.';

  @override
  String get settingsBiometric => '지문 · 얼굴로 열기';

  @override
  String get settingsBiometricDesc => 'PIN 대신 기기의 생체 인증으로 잠금을 풀어요.';

  @override
  String get biometricReason => 'Mulo 잠금을 풀어요';

  @override
  String get pinCreateTitle => 'PIN 정하기';

  @override
  String get pinCreateHint => '4~6자리 숫자를 입력하세요.';

  @override
  String get pinConfirmTitle => 'PIN 한 번 더';

  @override
  String get pinConfirmHint => '같은 PIN을 다시 입력하세요.';

  @override
  String get pinMismatch => 'PIN이 서로 달라요. 처음부터 다시 정해 주세요.';

  @override
  String get pinCurrentTitle => '현재 PIN';

  @override
  String get pinCurrentHint => '잠금을 끄려면 현재 PIN을 입력하세요.';

  @override
  String get pinCurrentHintChange => 'PIN을 바꾸려면 현재 PIN을 입력하세요.';

  @override
  String get pinCurrentHintBiometric => '현재 PIN을 입력하거나 지문 · 얼굴로 확인하세요.';

  @override
  String get pinWrong => 'PIN이 달라요.';

  @override
  String pinCooldown(int seconds) {
    return '$seconds초 뒤에 다시 시도하세요.';
  }

  @override
  String get pinSubmit => '확인';

  @override
  String get pinBackspace => '지우기';

  @override
  String get pinUseBiometric => '생체 인증으로 열기';

  @override
  String get lockTitle => '잠겨 있어요';

  @override
  String get lockHint => 'PIN을 입력하세요.';

  @override
  String get settingsHideNotification => '알림에 곡 정보 숨기기';

  @override
  String get settingsHideNotificationDesc => '알림 · 잠금화면에 \"음악 재생 중\"만 보여요.';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsFollowMood => '곡 분위기 따라가기';

  @override
  String get settingsFollowMoodDesc => '재생 중인 곡의 커버 색으로 강조 색이 바뀌어요.';

  @override
  String get settingsThemeColor => '테마 색';

  @override
  String get settingsThemePreview => '테마 미리보기';

  @override
  String get settingsThemePreviewDesc => '지금 테마로 화면이 어떻게 보이는지 확인해요';

  @override
  String get themePreviewSong => 'Midnight Signal';

  @override
  String get themePreviewArtist => 'Sample Artist';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsVersion => '버전';

  @override
  String get comingSoon => '준비 중';

  @override
  String get playerNowPlaying => '지금 재생 중';

  @override
  String get playerQueue => '재생 대기열';

  @override
  String get playerRepeat => '반복';

  @override
  String get playerLyrics => '가사';

  @override
  String playerFrom(String source) {
    return '$source에서 재생';
  }

  @override
  String get themeViolet => '바이올렛';

  @override
  String get themeCoral => '코랄';

  @override
  String get themeOcean => '오션';

  @override
  String get themeForest => '포레스트';

  @override
  String get themeSunset => '선셋';

  @override
  String get themeRose => '로즈';

  @override
  String get themeGold => '골드';

  @override
  String get themeIce => '아이스';

  @override
  String get coverTitle => '커버 이미지';

  @override
  String get coverChange => '커버 이미지 바꾸기';

  @override
  String get coverPick => '사진에서 고르기';

  @override
  String get coverReset => '기본 이미지로';

  @override
  String get settingsAppearance => '화면 모드';

  @override
  String get appearanceDark => '다크';

  @override
  String get appearanceLight => '라이트';

  @override
  String get libraryEmptyTitle => '아직 음악이 없어요';

  @override
  String get libraryEmptyBody => '기기에 있는 음악을 불러오거나\n검색에서 받아 보세요.';

  @override
  String get importing => '불러오는 중…';

  @override
  String importAdded(int count) {
    return '$count곡을 불러왔어요';
  }

  @override
  String get importNothingNew => '새로 추가된 곡이 없어요';

  @override
  String get importDenied => '음악 파일 권한이 필요해요. 설정에서 허용해 주세요.';

  @override
  String get importFailed => '음악을 불러오지 못했어요';

  @override
  String get unknownArtist => '알 수 없는 아티스트';

  @override
  String get unknownAlbum => '알 수 없는 앨범';

  @override
  String librarySources(int device, int downloaded) {
    return '기기 $device곡 · 받은 곡 $downloaded곡';
  }

  @override
  String get navHome => '홈';

  @override
  String get homeSubtitle => '오늘의 음악';

  @override
  String get homePeriodWeek => '이번 주';

  @override
  String get homePeriodMonth => '이번 달';

  @override
  String get homePeriodAll => '전체';

  @override
  String get homeToday => '오늘 들은 시간';

  @override
  String homeTodayMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String homeTodayHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String homeTodayPlays(int count) {
    return '오늘 $count곡 재생';
  }

  @override
  String get homeTodayNone => '오늘은 아직 듣지 않았어요';

  @override
  String get homeStats => '청취 분석';

  @override
  String get homeStatPlays => '재생';

  @override
  String get homeStatTracks => '곡';

  @override
  String get homeTopArtist => '많이 들은 아티스트';

  @override
  String get homeTopTracks => '많이 들은 곡';

  @override
  String get homeRecommendations => '추천';

  @override
  String get homeRecent => '최근 재생';

  @override
  String get homeNoPlays => '아직 재생 기록이 없어요. 보관함에서 곡을 재생해 보세요.';

  @override
  String get homeNoRecommendations => '보관함에 곡이 더 있으면 추천해 드려요.';

  @override
  String get homeEmptyLibraryTitle => '보관함이 비었어요';

  @override
  String get homeEmptyLibraryBody =>
      '기기 음악을 불러오거나 검색에서 받으면\n여기에 많이 들은 곡과 추천이 보여요.';

  @override
  String get homeGoLibrary => '보관함으로';

  @override
  String playCount(int count) {
    return '$count회';
  }

  @override
  String get searchHintWeb => '웹 음원 검색어나 URL';

  @override
  String get searchSourceTooltip => '검색 대상';

  @override
  String get sourceYoutube => '유튜브';

  @override
  String get sourceWeb => '웹';

  @override
  String get downloadsExpand => '대기 목록 펼치기';

  @override
  String get downloadsCollapse => '대기 목록 접기';

  @override
  String get downloadDialogTitle => '받기 정보';

  @override
  String get downloadFieldTitle => '제목';

  @override
  String get downloadFieldArtist => '아티스트';

  @override
  String get downloadFieldGenre => '장르';

  @override
  String get downloadPlaylistsLabel => '담을 재생목록';

  @override
  String get downloadPlaylistsEmpty => '아직 재생목록이 없어요. 아래에서 새로 만들 수 있어요.';

  @override
  String get downloadNewPlaylist => '새 재생목록';

  @override
  String get downloadNewPlaylistHint => '이름을 입력하고 +';

  @override
  String get downloadQueued => '대기열에 넣었어요';

  @override
  String get homeTopGenre => '많이 들은 장르';

  @override
  String get playlistsEmpty => '아직 재생목록이 없어요. 위의 +로 만들어 보세요.';

  @override
  String get playlistNewTitle => '새 재생목록';

  @override
  String get playlistNewHint => '재생목록 이름';

  @override
  String get playlistCreate => '만들기';

  @override
  String get playlistMenuImage => '이미지 바꾸기';

  @override
  String get playlistMenuColor => '카드 색';

  @override
  String get playlistColorAuto => '자동';

  @override
  String playlistColorOption(String name) {
    return '카드 색 $name';
  }

  @override
  String get playlistColorPrimary => '주 색';

  @override
  String get playlistColorSecondary => '보조 색';

  @override
  String get playlistColorTertiary => '포인트 색';

  @override
  String get playlistSummaryEmpty => '비어 있어요';

  @override
  String get downloadPlaylistsNone => '선택 안 함';

  @override
  String downloadPlaylistsSelected(int count) {
    return '$count개 선택';
  }

  @override
  String get downloadPlaylistsPickTitle => '재생목록 선택';

  @override
  String get downloadPlaylistsDone => '선택 완료';

  @override
  String get trackMenuTitle => '곡 메뉴';

  @override
  String get trackMenuPlayNext => '다음에 재생';

  @override
  String get trackMenuAddToQueue => '대기열에 추가';

  @override
  String get trackMenuAddToPlaylist => '재생목록에 추가';

  @override
  String get trackMenuEditInfo => '정보 편집';

  @override
  String get trackMenuCover => '커버 이미지 설정';

  @override
  String get trackMenuDelete => '삭제';

  @override
  String get trackMenuRemoveFromPlaylist => '재생목록에서 빼기';

  @override
  String get trackMenuDeleteFile => '파일 삭제';

  @override
  String get trackRemovedFromPlaylist => '재생목록에서 뺐어요';

  @override
  String get trackDeleteFailed => '파일을 지우지 못했어요. 권한을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get trackMenuPlayNextDone => '다음에 재생해요';

  @override
  String get trackMenuAddedToQueue => '대기열에 추가했어요';

  @override
  String get trackMenuNoPlaylists => '재생목록이 없어요. 재생목록 탭에서 먼저 만들어 주세요.';

  @override
  String trackMenuAddedToPlaylists(int count) {
    return '$count개 재생목록에 담았어요';
  }

  @override
  String get trackEditTitle => '곡 정보 편집';

  @override
  String get trackEditName => '제목';

  @override
  String get trackEditArtist => '아티스트';

  @override
  String get trackEditAlbum => '앨범';

  @override
  String get trackEditGenre => '장르';

  @override
  String get trackEditSave => '저장';

  @override
  String get trackEditSaved => '곡 정보를 고쳤어요';

  @override
  String get trackDeleteTitle => '곡 삭제';

  @override
  String trackDeleteBody(String title) {
    return '\"$title\"의 음악 파일을 기기에서 지울까요? 보관함과 재생목록에서도 빠지고, 되돌릴 수 없어요.';
  }

  @override
  String get trackDeleteConfirm => '삭제';

  @override
  String get trackDeleted => '삭제했어요';

  @override
  String get trackMenuLyrics => '가사 설정';

  @override
  String get lyricsEditTitle => '가사 설정';

  @override
  String get lyricsEditLabel => '가사';

  @override
  String get lyricsEditHint =>
      '가사를 붙여넣거나 입력하세요. [01:23.45] 같은 시간 표시가 있으면 싱크 가사로 저장돼요. 비워서 저장하면 가사를 지워요.';

  @override
  String get lyricsLoadFile => '파일에서 불러오기 (.lrc · .txt)';

  @override
  String get lyricsSave => '저장';

  @override
  String get lyricsSaved => '가사를 저장했어요';

  @override
  String get lyricsCleared => '가사를 지웠어요';

  @override
  String get playerShowLyrics => '가사 보기';

  @override
  String get playerShowCover => '커버 보기';

  @override
  String get lyricsEmpty => '가사가 없어요';

  @override
  String get lyricsEmptyHint => '곡 옆에 같은 이름의 .lrc 파일을 두거나, 직접 넣을 수 있어요.';
}
