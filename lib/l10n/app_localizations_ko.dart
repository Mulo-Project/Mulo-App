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
  String get playerFloatExpand => '미니 플레이어로 돌아가기';

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
      '링크를 붙여 넣거나 검색어를 입력하세요.\n왼쪽 아이콘으로 찾을 사이트를 고를 수 있어요.';

  @override
  String get searchEngineNeededTitle => '다운로드 엔진이 필요해요';

  @override
  String get searchEngineNeededBody =>
      'yt-dlp가 설치되어 있지 않아 검색할 수 없어요.\n설치하면 바로 검색하고 받을 수 있어요.';

  @override
  String get searchEngineInstallFailed => '설치하지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get searchNotReadyTitle => '쓸 수 있는 엔진이 없어요';

  @override
  String get searchNotReadyBody =>
      '서버 주소가 빌드에 없고 이 기기에 yt-dlp도 없어서 검색할 수 없어요.\n서버를 연결하거나 yt-dlp를 설치해 주세요.';

  @override
  String get searchErrorTitle => '불러오지 못했어요';

  @override
  String get searchErrorBody => '잠시 뒤에 다시 시도해 주세요.';

  @override
  String get searchNetworkBody => '서버에 연결하지 못했어요. 인터넷 연결을 확인해 주세요.';

  @override
  String get stateNetworkTitle => '네트워크 연결이 필요해요';

  @override
  String get stateNetworkBody => '연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get stateTimeoutTitle => '응답이 너무 오래 걸려요';

  @override
  String get stateTimeoutBody => '잠시 후 다시 시도해 주세요.';

  @override
  String get stateSignInTitle => '로그인이 필요해요';

  @override
  String get stateSignInBody => '로그인한 뒤에 쓸 수 있어요.';

  @override
  String get searchAuthBody => '서버가 로그인을 요구해요.';

  @override
  String get searchNotFoundBody => '이 주소는 받을 수 없는 곳이에요.';

  @override
  String get searchNoResultsTitle => '결과가 없어요';

  @override
  String get searchNoResultsBody => '다른 검색어로 찾아보세요.';

  @override
  String get searchLoadMore => '더 보기';

  @override
  String get searchLive => '라이브';

  @override
  String get searchLiveNoDownload => '라이브는 받을 수 없어요';

  @override
  String get searchLiveNoPreview => '라이브는 미리 들을 수 없어요';

  @override
  String get searchPreviewUnplayable => '지금은 들을 수 없는 영상이에요';

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
  String get downloadsActive => '진행 중';

  @override
  String downloadsWaiting(int count) {
    return '대기 $count';
  }

  @override
  String get downloadsPauseAll => '모두 일시정지';

  @override
  String get downloadsResumeAll => '모두 이어 받기';

  @override
  String get downloadsHideCurrent => '받는 곡 정보 숨기기';

  @override
  String get downloadsShowCurrent => '받는 곡 정보 보이기';

  @override
  String get downloadsClearDone => '완료 지우기';

  @override
  String get statusDownloading => '받는 중';

  @override
  String get statusFailed => '실패';

  @override
  String get statusPaused => '일시정지';

  @override
  String get statusQueued => '대기';

  @override
  String get statusProcessing => '처리 중';

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
  String get genreNotFound => '장르를 찾을 수 없어요';

  @override
  String get sortLabel => '정렬';

  @override
  String get sortAscending => '오름차순';

  @override
  String get sortDescending => '내림차순';

  @override
  String get sortName => '이름순';

  @override
  String get sortAdded => '추가일순';

  @override
  String get sortArtist => '아티스트순';

  @override
  String get sortCount => '곡 수순';

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
  String get settingsServerConfigured => '서버 주소 설정됨';

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
  String get settingsSavePathDesc => '고정 안 함 · 마지막에 받은 폴더';

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
  String get loadedFoldersRemoveTitle => '불러오는 폴더에서 뺄까요?';

  @override
  String loadedFoldersRemoveBody(String path, int count) {
    return '$path\n이 폴더의 $count곡이 보관함에서 사라져요. 음악 파일은 지워지지 않아요.';
  }

  @override
  String loadedFoldersRemoveBodyEmpty(String path) {
    return '$path\n음악 파일은 지워지지 않아요.';
  }

  @override
  String get loadedFoldersScanning => '폴더에서 곡을 찾는 중이에요';

  @override
  String get loadedFoldersRemoving => '폴더를 빼고 보관함을 정리하는 중이에요';

  @override
  String get loadedFoldersReading => '곡 정보를 읽는 중이에요';

  @override
  String get loadedFoldersCovers => '곡 이미지를 가져오는 중이에요';

  @override
  String loadedFoldersPlaylistTitle(int count) {
    return '불러온 $count곡을 재생목록에 담을까요?';
  }

  @override
  String get loadedFoldersPlaylistSkip => '안 담기';

  @override
  String get loadedFoldersPlaylistAdd => '담기';

  @override
  String loadedFoldersAddedToPlaylists(int songs, int count) {
    return '$songs곡을 $count개 재생목록에 담았어요';
  }

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
  String get settingsEngineInstall => '설치';

  @override
  String get settingsEngineNotInstalled => 'yt-dlp가 없어요. 설치하면 검색하고 받을 수 있어요.';

  @override
  String get settingsEngineRemove => '삭제';

  @override
  String get settingsEngineRemoveTitle => '다운로드 엔진을 지울까요?';

  @override
  String get settingsEngineRemoveBody =>
      '앱이 받아 둔 yt-dlp를 지워요. 검색과 받기를 하려면 다시 설치해야 해요. 기기에 따로 설치된 건 지우지 않아요.';

  @override
  String get settingsEngineInstalling => '내려받는 중…';

  @override
  String get settingsEngineReverting => '되돌리는 중…';

  @override
  String get settingsEngineRevertTitle => '업데이트한 yt-dlp를 지울까요?';

  @override
  String get settingsEngineRevertBody =>
      '업데이트로 받은 yt-dlp를 지우고 처음 버전으로 돌아가요. 업데이트 뒤 검색이나 받기가 안 될 때 써 보세요.';

  @override
  String get settingsEngineRevertFailed => '지우지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get settingsEngineBundled => '앱에 들어 있는 yt-dlp';

  @override
  String get settingsEngineFailed => '설치하지 못했어요. 인터넷 연결을 확인해 주세요.';

  @override
  String settingsEngineInstalled(String version) {
    return 'yt-dlp $version';
  }

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
  String get settingsBackgroundDownload => '백그라운드 받기';

  @override
  String get settingsBackgroundDownloadDesc =>
      '앱이 뒤로 가거나 닫혀도 받기를 이어 가요. 켜 두면 받는 동안 알림이 계속 떠 있어요.';

  @override
  String get settingsHideNotification => '알림에 곡 정보 숨기기';

  @override
  String get settingsHideNotificationDesc =>
      '알림 · 잠금화면에 \"음악 재생 중\"만 보이고, 받기 알림에서도 곡 정보를 숨겨요.';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeColorFollowing =>
      '곡 분위기 따라가기가 켜져 있어 재생 중인 곡의 색을 따라가요.';

  @override
  String get settingsFollowMood => '곡 분위기 따라가기';

  @override
  String get settingsFollowMoodDesc => '재생 중인 곡의 커버 색으로 강조 색이 바뀌어요.';

  @override
  String get settingsThemeColor => '테마 색';

  @override
  String get settingsThemePreview => '테마 미리보기';

  @override
  String get settingsThemePreviewDesc => '고른 테마로 앱 화면들을 직접 둘러보고 적용해요.';

  @override
  String get settingsPlayback => '재생 설정';

  @override
  String get settingsMixWithOthers => '다른 앱과 함께 재생';

  @override
  String get videoQualityTitle => '영상 화질';

  @override
  String get videoQualityHint => '미리 듣기 영상에 쓰여요. 높이면 선명하지만 데이터를 더 써요.';

  @override
  String get videoQualityLow => '144p';

  @override
  String get videoQualityStandard => '360p · 기본';

  @override
  String get videoQualityMedium => '480p';

  @override
  String get videoQualityHigh => '720p';

  @override
  String get videoQualityFull => '1080p';

  @override
  String get settingsSleepTimerOff => '꺼짐';

  @override
  String get settingsLyricsOverlay => '오버레이 가사';

  @override
  String get settingsLyricsOverlayDesc => '다른 앱 위에 가사를 띄워요. 한 번 켜 두면 앱을 다시 켜도 유지돼요.';

  @override
  String get settingsMixWithOthersDesc =>
      '다른 앱 소리와 함께 재생해요. 소리가 겹칠 수 있어요.';

  @override
  String get settingsPauseOnDisconnect => '기기가 끊기면 일시정지';

  @override
  String get settingsPauseOnDisconnectDesc => '이어폰을 빼거나 블루투스 연결이 끊기면 재생을 멈춰요.';

  @override
  String get settingsResumeOnConnect => '기기가 연결되면 이어 재생';

  @override
  String get settingsResumeOnConnectDesc =>
      '끊겨서 멈춘 재생을 10분 안에 다시 연결하면 이어서 재생해요.';

  @override
  String get settingsResumeWithoutNotification => '알림이 없어도 블루투스로 재생';

  @override
  String get settingsResumeWithoutNotificationDesc =>
      '알림을 지웠거나 재생이 끝난 뒤에도 블루투스 재생 버튼으로 마지막 곡을 이어 재생해요.';

  @override
  String get playerStyleTitle => '플레이어 테마';

  @override
  String get playerSpeedTitle => '재생 속도';

  @override
  String playerSpeedValue(String speed) {
    return '$speed배속';
  }

  @override
  String get playerSpeedNormal => '보통';

  @override
  String get playerStyleSquare => '네모';

  @override
  String get playerStyleFullBleed => '꽉 찬 이미지';

  @override
  String get playerStyleArc => '호';

  @override
  String get playerSleepTimer => '수면 타이머';

  @override
  String get playerSleepTimerOff => '타이머 끄기';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return '$minutes분 뒤 멈춤';
  }

  @override
  String playerSleepTimerSet(int minutes) {
    return '$minutes분 뒤 재생을 멈춰요';
  }

  @override
  String get playerSleepTimerUnitHour => '시간';

  @override
  String get playerSleepTimerUnitMinute => '분';

  @override
  String get playerSleepTimerStart => '시작';

  @override
  String get playerSleepTimerCleared => '수면 타이머를 껐어요';

  @override
  String get playerEqualizer => '이퀄라이저';

  @override
  String get playerLyrics => '가사';

  @override
  String get playerRewind10 => '10초 뒤로';

  @override
  String get playerForward10 => '10초 앞으로';

  @override
  String get themePreviewHint => '탭을 오가며 확인해 보세요';

  @override
  String get themePreviewApply => '적용';

  @override
  String get settingsData => '데이터';

  @override
  String get settingsStreamCache => '스트리밍 임시 저장';

  @override
  String settingsStreamCacheDesc(String used, String limit) {
    return '$used 사용 중 · 한도 $limit';
  }

  @override
  String get settingsStreamCacheClear => '지금 비우기';

  @override
  String get settingsStreamCacheCleared => '임시 저장소를 비웠어요';

  @override
  String get savedVideosTitle => '저장한 음원';

  @override
  String get savedVideosOpen => '저장한 음원';

  @override
  String get savedVideosEmpty => '저장한 음원이 없어요';

  @override
  String get savedVideosAdd => '저장';

  @override
  String get savedVideosAdded => '저장됨';

  @override
  String get savedVideosFailed => '저장하지 못했어요';

  @override
  String get savedVideosDownloading => '받는 중';

  @override
  String get savedVideosRemove => '저장 해제';

  @override
  String savedVideosUsed(String size) {
    return '$size 사용 중';
  }

  @override
  String get savedVideosQualityTitle => '저장 화질';

  @override
  String get savedVideosQualityHint => '고른 화질로 받아 둬요';

  @override
  String get savedVideosPlay => '듣기';

  @override
  String get videoFullscreen => '전체 화면';

  @override
  String get videoFullscreenExit => '축소';

  @override
  String get newVideosDetail => '상세 보기';

  @override
  String get savedVideosConfirm => '담기';

  @override
  String get videoBack10 => '10초 뒤로';

  @override
  String get videoForward10 => '10초 앞으로';

  @override
  String get savedVideosSectionVideo => '영상';

  @override
  String get savedVideosSectionAudio => '음원';

  @override
  String get videoOptions => '옵션';

  @override
  String get videoOptionsTitle => '영상 옵션';

  @override
  String get videoRepeat => '반복 재생';

  @override
  String get videoQualityAuto => '자동 (낮게 시작해 올림)';

  @override
  String get settingsPurgeHidden => '숨긴 곡 기록 정리';

  @override
  String settingsPurgeHiddenDesc(int count) {
    return '폴더를 빼서 숨겨 둔 $count곡의 기록이 남아 있어요';
  }

  @override
  String get settingsPurgeHiddenNone => '정리할 기록이 없어요';

  @override
  String get settingsPurgeHiddenTitle => '숨긴 곡 기록을 지울까요?';

  @override
  String settingsPurgeHiddenBody(int count) {
    return '숨겨 둔 $count곡의 재생 횟수, 좋아요, 재생목록, 커버, 가사 사본이 지워져요. 음악 파일과 태그는 그대로예요.';
  }

  @override
  String settingsPurgeHiddenDone(int count) {
    return '$count곡의 기록을 지웠어요';
  }

  @override
  String hiddenRecordsHint(int count) {
    return '폴더를 빼서 숨겨 둔 $count곡이에요. 기록을 지울 곡을 골라요.';
  }

  @override
  String get hiddenRecordsPurgeAll => '모두 지우기';

  @override
  String hiddenRecordsPurgeOneTitle(String title) {
    return '\"$title\" 기록을 지울까요?';
  }

  @override
  String hiddenRecordsPlays(int count) {
    return '$count회 재생';
  }

  @override
  String hiddenRecordsLastPlayed(String date) {
    return '마지막 $date';
  }

  @override
  String hiddenRecordsPlaylists(int count) {
    return '재생목록 $count개';
  }

  @override
  String get hiddenRecordsCover => '커버';

  @override
  String get hiddenRecordsLyrics => '가사 사본';

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
  String get outputSpeaker => '기기 스피커';

  @override
  String get outputWired => '유선 이어폰';

  @override
  String get outputBluetooth => '블루투스';

  @override
  String get outputUsb => 'USB 오디오';

  @override
  String get outputOther => '외부 출력';

  @override
  String get shuffleOn => '셔플 켜기';

  @override
  String get shuffleOff => '셔플 끄기';

  @override
  String get queueClear => '대기열 비우기';

  @override
  String get queueSelect => '여러 곡 선택';

  @override
  String get queueCleared => '대기열을 비웠어요';

  @override
  String get queueClearTitle => '대기열을 비울까요?';

  @override
  String get queueClearBody => '재생 중인 곡도 멈추고 대기열에서 모두 사라져요. 보관함의 곡은 그대로 남아요.';

  @override
  String get queueClearConfirm => '비우기';

  @override
  String get queueReorderHint => '길게 눌러 끌면 순서가 바뀌어요';

  @override
  String get playerLoop => '구간 반복';

  @override
  String get playerLoopSetStart => '구간 반복: 시작 지점을 정해요';

  @override
  String get playerLoopSetEnd => '구간 반복: 끝 지점을 정해요';

  @override
  String get playerLoopClear => '구간 반복 끄기';

  @override
  String get playerRepeat => '반복';

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
  String get coverPick => '이미지 고르기';

  @override
  String get coverReset => '기본 이미지로';

  @override
  String get coverSourceTitle => '어디서 가져올까요?';

  @override
  String get coverSourceDevice => '기기에서 고르기';

  @override
  String get coverSourceWeb => '웹에서 가져오기';

  @override
  String get coverAdjust => '위치 조정';

  @override
  String get coverWebBrowserHelp => '마음에 드는 이미지를 누르면 바로 편집 화면으로 가요.';

  @override
  String get coverWebHint => '이미지 주소 또는 검색어';

  @override
  String get coverWebHelp => '이미지 주소(https://…)를 붙여 넣거나, 검색어로 찾아 고르세요.';

  @override
  String get coverWebUseUrl => '이 주소의 이미지 쓰기';

  @override
  String get coverWebEmpty => '찾은 이미지가 없어요';

  @override
  String get coverWebFailed => '검색하지 못했어요. 잠시 뒤 다시 해 주세요';

  @override
  String get coverEditTitle => '이미지';

  @override
  String get coverEditHint =>
      '테두리 안이 실제 커버예요. 어두운 곳은 잘리고 빈 곳은 검정이에요. 끌어서 옮기고 두 손가락으로 크기와 각도를 바꿔요';

  @override
  String get coverEditZoomIn => '확대';

  @override
  String get coverEditZoomOut => '축소';

  @override
  String get coverEditReset => '원래대로';

  @override
  String get coverEditResetPosition => '위치 되돌리기';

  @override
  String get coverEditResetTitle => '위치와 크기를 되돌릴까요?';

  @override
  String get coverEditResetBody => '확대 · 위치 · 회전이 처음 상태로 돌아가요.';

  @override
  String get coverEditResetConfirm => '되돌리기';

  @override
  String get coverChange => '이미지 바꾸기';

  @override
  String get coverRemove => '이미지 지우기';

  @override
  String get coverRemoveTitle => '이미지를 지울까요?';

  @override
  String get coverRemoveBody => '고른 이미지를 지워요. 나중에 다시 고를 수 있어요.';

  @override
  String get coverRevertTitle => '기본 이미지로 되돌릴까요?';

  @override
  String get coverRevertBody => '고른 이미지를 지우고 기본 이미지로 돌아가요.';

  @override
  String get coverEditApply => '적용';

  @override
  String get coverEditEmpty => '위에서 이미지를 불러오세요';

  @override
  String get coverEditRotation => '회전';

  @override
  String get coverEditRotateLeft => '왼쪽 90°';

  @override
  String get coverEditRotateRight => '오른쪽 90°';

  @override
  String get coverEditLoadFailed => '이미지를 불러오지 못했어요';

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
  String get homeRecommendations => '추천 재생목록';

  @override
  String get homeRecent => '최근 들은 곡';

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
  String get homeTopTracksGo => 'TOP 100 보러가기';

  @override
  String get homeRecentList => '최근 재생';

  @override
  String homeAllSince(String date) {
    return '$date부터의 기록';
  }

  @override
  String get homeRecRediscover => '오랜만에 다시 듣기';

  @override
  String get homeChipTracks => '곡';

  @override
  String get homeChipArtists => '아티스트';

  @override
  String get homeChipGenres => '장르';

  @override
  String get homeMonthPrev => '이전 달';

  @override
  String get homeMonthNext => '다음 달';

  @override
  String get homeHistory => '재생 기록';

  @override
  String get homeMetricPlays => '재생 횟수';

  @override
  String get homeMetricTime => '재생 시간';

  @override
  String get homePickMonth => '달 고르기';

  @override
  String homeMonthLabel(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String homeYearLabel(int year) {
    return '$year년';
  }

  @override
  String homeMonthShort(int month) {
    return '$month월';
  }

  @override
  String get homeAllDays => '들은 날';

  @override
  String homeAllDaysValue(int count) {
    return '$count일';
  }

  @override
  String get homeAllTime => '총 재생 시간';

  @override
  String get homeAllPlays => '총 재생';

  @override
  String get homeAllTracks => '들은 곡';

  @override
  String get homeChartNone => '이 기간에는 들은 기록이 없어요.';

  @override
  String get homeTopAlbum => '많이 들은 앨범';

  @override
  String get homeTopTracksMore => '전체 보기';

  @override
  String get homeTopTracksTitle => '많이 들은 곡 TOP 100';

  @override
  String homeRecArtist(String artist) {
    return '$artist 믹스';
  }

  @override
  String homeRecGenre(String genre) {
    return '$genre 모음';
  }

  @override
  String get homeRecUnheard => '아직 안 들어 본 곡';

  @override
  String get homeRecNewest => '새로 담은 곡';

  @override
  String playCount(int count) {
    return '$count회';
  }

  @override
  String searchHintSite(String site) {
    return '$site URL이나 검색어';
  }

  @override
  String get sourceSoundcloud => 'SoundCloud';

  @override
  String get searchSubmitTooltip => '검색';

  @override
  String get searchPasteLink => '링크 붙여넣기';

  @override
  String get searchPasteEmpty => '클립보드에 링크가 없어요';

  @override
  String get searchSourceTooltip => '검색 대상';

  @override
  String get sourceYoutube => '유튜브';

  @override
  String get searchHitMenuDetail => '상세 보기';

  @override
  String get searchPreview => '미리 듣기';

  @override
  String get searchPreviewStop => '미리 듣기 멈추기';

  @override
  String get searchPreviewPause => '미리 듣기 일시정지';

  @override
  String get searchPreviewResume => '미리 듣기 이어 듣기';

  @override
  String get searchPreviewLoading => '미리 듣기 준비 중';

  @override
  String get searchPreviewFailed => '미리 듣기를 시작하지 못했어요.';

  @override
  String get searchPreviewUnavailable => '이 기기에서는 미리 듣기를 쓸 수 없어요.';

  @override
  String get mediaDetailTitle => '상세 정보';

  @override
  String get mediaDetailWatchYoutube => '유튜브에서 보기';

  @override
  String get mediaDetailOpenOriginal => '원본 페이지 열기';

  @override
  String get mediaDetailListenOriginal => '원본 사이트에서 듣기';

  @override
  String get mediaDetailListenSoundcloud => 'SoundCloud에서 듣기';

  @override
  String get mediaDetailOpenArtist => '아티스트 보기';

  @override
  String get mediaDetailPlays => '재생수';

  @override
  String get mediaDetailGenre => '장르';

  @override
  String mediaDetailFollowers(String count) {
    return '팔로워 $count명';
  }

  @override
  String get mediaDetailChannel => '채널';

  @override
  String get mediaDetailSite => '출처';

  @override
  String get mediaDetailUploader => '올린 사람';

  @override
  String get mediaDetailOpenChannel => '채널 보기';

  @override
  String get mediaDetailDuration => '길이';

  @override
  String get mediaDetailViews => '조회수';

  @override
  String get mediaDetailUploaded => '올린 날';

  @override
  String get mediaDetailCategory => '분류';

  @override
  String get mediaDetailDescription => '설명';

  @override
  String get mediaDetailSectionPreview => '미리 듣기';

  @override
  String get mediaDetailSectionInfo => '정보';

  @override
  String get mediaDetailMore => '더 보기';

  @override
  String get mediaDetailLikes => '좋아요';

  @override
  String mediaDetailSubscribers(String count) {
    return '구독자 $count명';
  }

  @override
  String get mediaDetailCollaborators => '공동 작업자';

  @override
  String get mediaDetailPlayInApp => '앱에서 재생';

  @override
  String get mediaDetailEmbedBlocked =>
      '이 영상은 앱 안에서 재생할 수 없어요. 아래 버튼으로 유튜브에서 열어 보세요.';

  @override
  String get mediaDetailLess => '접기';

  @override
  String get mediaDetailOpenFailed => '열 수 있는 앱이 없어요.';

  @override
  String mediaDetailViewCount(String count) {
    return '$count회';
  }

  @override
  String get searchSortTooltip => '정렬';

  @override
  String get searchSortRelevance => '관련도순';

  @override
  String get searchSortPopular => '인기순';

  @override
  String get searchSortNewest => '최신순';

  @override
  String get searchSortDuration => '길이순';

  @override
  String get searchSortTitle => '제목순';

  @override
  String videoCategory(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'FilmAnimation': '영화/애니메이션',
      'Autos': '자동차',
      'Music': '음악',
      'Pets': '동물',
      'Sports': '스포츠',
      'Travel': '여행',
      'Gaming': '게임',
      'People': '인물/블로그',
      'Comedy': '코미디',
      'Entertainment': '엔터테인먼트',
      'News': '뉴스/정치',
      'Howto': '노하우/스타일',
      'Education': '교육',
      'Science': '과학/기술',
      'Nonprofits': '비영리/사회운동',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String downloadsRemaining(int count) {
    return '$count곡 남음';
  }

  @override
  String get downloadsExpand => '대기 목록 펼치기';

  @override
  String get downloadsCollapse => '대기 목록 접기';

  @override
  String get downloadDialogTitle => '받기 정보';

  @override
  String get downloadFieldCover => '커버';

  @override
  String get downloadCoverChange => '바꾸기';

  @override
  String get downloadCoverDefault => '기본으로';

  @override
  String get downloadLyricsEditHint => '파일 · 웹에서 불러오거나 직접 써요. 자막이 없어도 돼요.';

  @override
  String get downloadLyricsOverwriteTitle => '직접 정한 가사가 있어요';

  @override
  String get downloadLyricsOverwriteBody => '영상 자막을 쓰면 직접 정한 가사는 지워져요. 계속할까요?';

  @override
  String get downloadLyricsOverwriteConfirm => '자막으로 바꾸기';

  @override
  String downloadLyricsCustom(int lines) {
    return '직접 정한 가사를 넣어요 · $lines줄';
  }

  @override
  String get downloadImportLyrics => '자막을 가사로 가져오기';

  @override
  String get downloadImportLyricsHint => '받은 뒤 가사 보기의 싱크 설정에서 다듬을 수 있어요.';

  @override
  String get downloadSubtitleChecking => '자막이 있는지 확인하는 중이에요.';

  @override
  String get downloadSubtitleNone => '이 영상에는 자막이 없어요.';

  @override
  String get downloadSubtitleUnknown => '자막을 확인하지 못했어요. 켜 두면 받은 뒤 다시 찾아봐요.';

  @override
  String get downloadSubtitleLanguage => '자막 언어';

  @override
  String get downloadSubtitleAuto => '자동으로 고르기';

  @override
  String get downloadSubtitleAutoHint => '한국어 → 영어 → 첫 번째 자막 순으로 골라요.';

  @override
  String get downloadLyricsPreviewLoading => '불러오는 중…';

  @override
  String get downloadLyricsPreviewFailed => '자막을 불러오지 못했어요.';

  @override
  String get downloadSubtitleEditHint =>
      '글은 고칠 수 있지만 시간은 바꿀 수 없어요. 싱크는 받은 뒤 재생 화면에서 맞춰요.';

  @override
  String get downloadSubtitleUseEdited => '이 자막 사용';

  @override
  String get downloadSubtitleApplied => '가사에 적용';

  @override
  String get downloadLyricsRetry => '다시 불러오기';

  @override
  String get downloadSubtitleUse => '이 자막 사용';

  @override
  String get downloadSubtitleInUse => '사용 중인 자막';

  @override
  String get downloadLyricsSkipSounds => '효과음 줄 빼기';

  @override
  String get downloadLyricsSkipSoundsHint =>
      '[음악] · (박수) · ♪ 같은 줄은 가사로 가져오지 않아요.';

  @override
  String get downloadSubtitleColLanguage => '언어';

  @override
  String get downloadSubtitleColKind => '종류';

  @override
  String get downloadSubtitleKindAuto => '자동 생성';

  @override
  String get downloadSubtitleKindManual => '직접 단 자막';

  @override
  String downloadSubtitleFound(int count) {
    return '자막 $count개를 찾았어요.';
  }

  @override
  String get downloadSectionInfo => '기본 정보';

  @override
  String get downloadSectionSave => '저장';

  @override
  String get downloadSectionLyrics => '가사';

  @override
  String get downloadCancelTitle => '받기 취소';

  @override
  String downloadCancelBody(String title) {
    return '\"$title\" 받기를 취소할까요? 지금까지 받은 부분은 사라져요.';
  }

  @override
  String get downloadCancelKeep => '계속 받기';

  @override
  String get downloadCancelConfirm => '취소하기';

  @override
  String get downloadsCancelAll => '전체 취소';

  @override
  String get downloadsCancelAllTitle => '받기 모두 취소';

  @override
  String downloadsCancelAllBody(int count) {
    return '받는 중이거나 기다리는 $count곡의 받기를 모두 취소할까요? 지금까지 받은 부분은 사라져요.';
  }

  @override
  String downloadsOverall(int done, int total) {
    return '$done/$total곡';
  }

  @override
  String playlistDownloadsTitle(int count) {
    return '받는 중 $count곡';
  }

  @override
  String get downloadFieldTitle => '제목';

  @override
  String get downloadFieldArtist => '아티스트';

  @override
  String get downloadFieldAlbum => '앨범';

  @override
  String get downloadFieldGenre => '장르';

  @override
  String get downloadFieldSavePath => '저장 위치';

  @override
  String get downloadGenreExisting => '기존 장르에서 고르기';

  @override
  String get saveFolderTitle => '저장 위치 고르기';

  @override
  String get saveFolderFixedHint => '체크한 폴더로 항상 받아요. 모두 풀면 마지막에 받은 폴더에 받아요.';

  @override
  String get saveFolderEmpty => '불러오는 폴더가 없어요. 직접 선택해 주세요.';

  @override
  String get saveFolderPickOther => '직접 선택';

  @override
  String get downloadPickFolder => '폴더 고르기';

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
  String get downloadAlreadyDownloaded => '이미 받은 곡이에요';

  @override
  String get downloadStateDownloading => '받는 중';

  @override
  String get downloadStateQueued => '대기 중';

  @override
  String get downloadStateDone => '받음';

  @override
  String get downloadAlreadyInQueue => '이미 받는 중이거나 대기 중인 곡이에요';

  @override
  String get homeTopGenre => '많이 들은 장르';

  @override
  String get playlistsEmpty => '아직 재생목록이 없어요. 위의 +로 만들어 보세요.';

  @override
  String get playlistsReorderHint => '길게 눌러 끌면 순서를 바꿀 수 있어요.';

  @override
  String get playlistNewTitle => '새 재생목록';

  @override
  String get playlistNewHint => '재생목록 이름';

  @override
  String get playlistCreate => '만들기';

  @override
  String get decorateTitle => '꾸미기';

  @override
  String get decorateImage => '이미지';

  @override
  String get decorateColor => '색';

  @override
  String get decorateAlbumTooltip => '앨범 꾸미기';

  @override
  String get decorateArtistTooltip => '아티스트 꾸미기';

  @override
  String get playlistMenuDecorate => '꾸미기';

  @override
  String get trackMenuDecorate => '꾸미기';

  @override
  String get albumRenameTooltip => '앨범 이름 바꾸기';

  @override
  String get albumRenameTitle => '앨범 이름 바꾸기';

  @override
  String get albumRenameHint => '앨범 이름';

  @override
  String get albumRenameSave => '바꾸기';

  @override
  String get albumRenameDone => '앨범 이름을 바꿨어요';

  @override
  String get artistRenameTooltip => '아티스트 이름 바꾸기';

  @override
  String get artistRenameTitle => '아티스트 이름 바꾸기';

  @override
  String get artistRenameHint => '아티스트 이름';

  @override
  String get genreRenameTooltip => '장르 이름 바꾸기';

  @override
  String get genreRenameTitle => '장르 이름 바꾸기';

  @override
  String get genreRenameHint => '장르 이름';

  @override
  String get renameProgressTitle => '곡 정보를 고치는 중이에요';

  @override
  String renameProgressCount(int done, int total) {
    return '$done/$total곡';
  }

  @override
  String get artistNotFound => '아티스트를 찾을 수 없어요';

  @override
  String get playlistMenuColor => '카드 색';

  @override
  String get playlistColorAuto => '자동';

  @override
  String get colorCustom => '색상 직접 고르기';

  @override
  String colorOption(int n) {
    return '색 $n';
  }

  @override
  String get playlistSummaryEmpty => '비어 있어요';

  @override
  String downloadColorSaveForGenre(String genre) {
    return '\'$genre\' 장르의 기본 색으로 저장';
  }

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
  String get trackMenuEditInfo => '상세 정보';

  @override
  String get trackMenuDelete => '삭제';

  @override
  String get trackMenuRemoveFromQueue => '대기열에서 빼기';

  @override
  String get trackRemovedFromQueue => '대기열에서 뺐어요.';

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
  String get trackInfoTitle => '곡 상세 정보';

  @override
  String get trackInfoUnknown => '알 수 없음';

  @override
  String get trackInfoDuration => '길이';

  @override
  String get trackInfoAdded => '추가한 날';

  @override
  String get trackInfoSource => '출처';

  @override
  String get trackInfoSourceDevice => '외부';

  @override
  String get trackInfoSourceDownload => '받은 곡';

  @override
  String get trackInfoFolder => '폴더';

  @override
  String downloadTagFailed(String title) {
    return '태그를 저장하지 못했어요: $title';
  }

  @override
  String get collectionMenuInfo => '정보';

  @override
  String get playlistInfoTitle => '재생목록 정보';

  @override
  String get albumInfoTitle => '앨범 정보';

  @override
  String get artistInfoTitle => '아티스트 정보';

  @override
  String get genreInfoTitle => '장르 정보';

  @override
  String get trackInfoFileSize => '파일 크기';

  @override
  String get trackInfoFormat => '형식';

  @override
  String get trackInfoBitrate => '비트레이트';

  @override
  String get trackInfoSampleRate => '샘플레이트';

  @override
  String get trackInfoUrl => '원본 주소';

  @override
  String get trackInfoUrlCopied => '주소를 복사했어요';

  @override
  String get trackEditTagFailed =>
      '음악 파일에 곡 정보를 쓰지 못해 바꾸지 않았어요. 잠시 뒤 다시 시도해 주세요.';

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
  String get lyricsMenuEdit => '가사 편집';

  @override
  String get lyricsEditTitle => '가사 설정';

  @override
  String get lyricsEditLabel => '가사';

  @override
  String get lyricsEditHint =>
      '가사를 붙여넣거나 입력하세요. [01:02.30]처럼 시간이 붙은 글이나 .lrc · .txt 파일을 불러오면 싱크 가사가 돼요. 비우고 저장하면 지워져요.';

  @override
  String get lyricsEditSyncedHint =>
      '왼쪽 시간은 줄 번호에 붙어 있어요. 줄을 끼우거나 지우면 시간은 그대로 남고 글만 밀려요. 시간은 싱크 설정에서 바꿔요.';

  @override
  String get lyricsAddLine => '줄 추가';

  @override
  String get lyricsDeleteLine => '줄 지우기';

  @override
  String get lyricsTimePrev => '이전';

  @override
  String get lyricsTimeNow => '현재';

  @override
  String get lyricsTimeNext => '다음';

  @override
  String get lyricsTimeNone => '없음';

  @override
  String get lyricsTimeGroupedAbove => '앞 줄과 같은 시간이라 묶여요';

  @override
  String get lyricsTimeGroupedBelow => '다음 줄과 같은 시간이라 묶여요';

  @override
  String get lyricsTimeSeparate => '이 줄부터 묶음에서 떼기';

  @override
  String get lyricsTimeClearFrom => '여기부터 싱크 지우기';

  @override
  String get lyricsLoadFile => '파일에서 불러오기';

  @override
  String get lyricsWebSearch => '웹에서 가져오기';

  @override
  String get lyricsWebTitle => '가사 검색';

  @override
  String get lyricsWebHint => '가사를 끌어서 골라 \'담기\', 다 모았으면 \'가져오기\'';

  @override
  String get lyricsWebImport => '가져오기';

  @override
  String get lyricsWebNothingSelected => '고른 글이 없어요. 가사를 끌어서 먼저 골라 주세요.';

  @override
  String get lyricsWebAdd => '담기';

  @override
  String get lyricsWebScratchTitle => '모은 글';

  @override
  String get lyricsWebScratchHint => '담은 글이 여기 쌓여요. 직접 고치거나 지울 수 있어요.';

  @override
  String get lyricsWebClear => '모두 비우기';

  @override
  String get lyricsWebScratchEmpty => '모은 글이 없어요. 가사를 골라 \'담기\'를 먼저 눌러 주세요.';

  @override
  String get lyricsSave => '저장';

  @override
  String get lyricsSaved => '가사를 저장했어요';

  @override
  String get lyricsCleared => '가사를 지웠어요';

  @override
  String get lyricsSyncTitle => '싱크 맞추기';

  @override
  String get lyricsSyncSetting => '싱크 설정';

  @override
  String get lyricsSyncHint =>
      '노래에 맞춰 \'지금\'을 눌러 줄마다 시간을 찍어요. 찍은 줄을 누르면 시간을 다듬을 수 있어요.';

  @override
  String get lyricsSyncNow => '지금';

  @override
  String get lyricsSyncUndo => '되돌리기';

  @override
  String get lyricsSyncPrevious => '싱크 한 칸 지우고 뒤로';

  @override
  String get lyricsSyncSavePartial => '중간 저장 (찍은 곳까지)';

  @override
  String get lyricsSyncSave => '싱크 저장';

  @override
  String get lyricsSyncGroup => '한 번에 묶을 줄 수';

  @override
  String lyricsSyncGroupLines(int n) {
    return '$n줄';
  }

  @override
  String get lyricsSyncNeedAll => '모든 줄에 시간을 찍으면 저장할 수 있어요.';

  @override
  String get lyricsSyncEmpty => '싱크를 맞출 가사가 없어요. 먼저 가사를 입력해 주세요.';

  @override
  String get lyricsTagNotSaved => '파일 저장에 실패했어요. 앱 데이터를 지우면 가사가 사라져요.';

  @override
  String get lyricsSyncPlay => '재생';

  @override
  String get lyricsSyncPause => '일시정지';

  @override
  String lyricsSyncBackBy(double n) {
    return '$n초 전으로 (길게 눌러 단위 바꾸기)';
  }

  @override
  String lyricsSyncForwardBy(double n) {
    return '$n초 뒤로 (길게 눌러 단위 바꾸기)';
  }

  @override
  String get lyricsSyncAutoPause => '자동 멈춤';

  @override
  String get lyricsSyncAutoPauseHint => '다음 줄에 이미 있는 싱크 시간에 닿으면 재생을 멈춰요';

  @override
  String get lyricsSyncSeek => '재생 위치';

  @override
  String lyricsSyncProgress(int done, int total) {
    return '$done/$total줄';
  }

  @override
  String get lyricsImportExistsTitle => '가사가 이미 있어요';

  @override
  String get lyricsImportExistsBody => '불러온 가사를 어떻게 넣을까요?';

  @override
  String get lyricsImportReplace => '바꾸기';

  @override
  String get lyricsImportAppend => '뒤에 붙이기';

  @override
  String get lyricsImportMemo => '메모에 추가';

  @override
  String get lyricsMemoTitle => '메모';

  @override
  String get lyricsMemoHide => '메모 숨기기';

  @override
  String get lyricsMemoHint => '골라서 \"끼우기\"를 누르면 지금 줄 아래에 들어가요';

  @override
  String get lyricsMemoInsert => '끼우기';

  @override
  String get lyricsSyncGroupSetupBody =>
      '한 번에 시간을 찍을 줄 수를 골라 주세요. 나중에 위쪽 메뉴에서 바꿀 수 있어요.';

  @override
  String get lyricsSyncLeaveTitle => '싱크가 저장되지 않아요';

  @override
  String get lyricsSyncLeaveBody =>
      '아직 모든 줄에 시간을 찍지 않았어요. 지금 나가면 찍은 시간이 사라져요. 저장하고 나갈까요?';

  @override
  String get lyricsSyncLeaveSave => '저장 후 나가기';

  @override
  String get lyricsSyncLeaveDiscard => '저장 안 하고 나가기';

  @override
  String get lyricsSyncLeaveStay => '계속 맞추기';

  @override
  String get lyricsSyncGroupOk => '확인';

  @override
  String get lyricsSyncDefaultLines => '기본 줄 수 변경';

  @override
  String get lyricsSyncExpandedHint =>
      '줄별로 펼쳤어요 · 시간을 따로 정할 수 있고, 영역 밖을 누르면 시간이 같은 줄은 다시 합쳐져요';

  @override
  String get lyricsSyncCancelAfter => '이 싱크로 초기화';

  @override
  String get lyricsSyncCancelAfterHint => '이 싱크 뒤에 찍은 싱크를 지우고 여기서부터 다시 찍어요';

  @override
  String get lyricsSyncNextSlot => '이어 찍기';

  @override
  String get lyricsSyncFollow => '따라가기';

  @override
  String get lyricsSyncFollowHint =>
      '켜면 목록이 포커스한 칸을 따라 움직이고, 끄면 가사를 자유롭게 볼 수 있어요';

  @override
  String get lyricsFollow => '싱크 추적';

  @override
  String get lyricsThemeList => '목록';

  @override
  String get lyricsThemeCentered => '가운데 한 줄';

  @override
  String get lyricsThemeCover => '커버 배경';

  @override
  String get themeTabPlayer => '플레이어';

  @override
  String get themeTabLyrics => '가사';

  @override
  String get lyricsLatencyTitle => '반응 시간 보정';

  @override
  String get lyricsLatencyEntry => '반응 시간 보정';

  @override
  String get lyricsLatencyIntro =>
      '소리를 듣고 지금을 누르면 반응 시간만큼 늦게 찍혀요. 아래 값만큼 앞당겨 찍어요.';

  @override
  String lyricsLatencySeconds(String s) {
    return '$s초';
  }

  @override
  String get lyricsLatencyReset => '기본값 0.20초로';

  @override
  String get lyricsBeatTitle => '박자 테스트';

  @override
  String get lyricsBeatBody =>
      '소리와 함께 원이 깜빡여요. 깜빡일 때마다 가운데 원을 누르세요. 8번 누르면 평균으로 추천 값을 알려 줘요.';

  @override
  String get lyricsBeatIdle => '시작을 누르세요';

  @override
  String lyricsBeatProgress(int n, int total) {
    return '$n/$total번';
  }

  @override
  String get lyricsBeatStart => '시작';

  @override
  String get lyricsBeatStop => '멈추기';

  @override
  String lyricsBeatResult(String s) {
    return '추천 보정 $s초';
  }

  @override
  String get lyricsBeatApply => '이 값으로 적용';

  @override
  String get lyricsBeatNote =>
      '기기마다 화면과 소리 지연이 달라서 안드로이드 기준이에요. 데스크톱은 오차가 클 수 있어요.';

  @override
  String get lyricsSongCheckTitle => '곡으로 확인';

  @override
  String get lyricsSongCheckBody =>
      '곡을 들으며 소리가 시작되는 순간 찍어 보기를 눌러 보세요. 찍힌 위치부터 다시 들어 맞는지 확인해요.';

  @override
  String get lyricsSongTry => '찍어 보기';

  @override
  String lyricsSongTried(String clock) {
    return '찍힌 위치 $clock';
  }

  @override
  String get lyricsSongListen => '찍힌 위치부터 듣기';

  @override
  String get lyricsSyncSkipTitle => '찍어 둔 싱크가 사라져요';

  @override
  String get lyricsSyncSkipBody =>
      '묶을 범위 안에 이미 찍어 둔 싱크가 있어요. 한 칸으로 묶으면 그 싱크는 지워져요. 계속할까요?';

  @override
  String get lyricsSyncSkipConfirm => '묶기';

  @override
  String get lyricsSyncResetTitle => '묶음이 사라져요';

  @override
  String get lyricsSyncResetBody =>
      '기본 줄 수를 바꾸면 직접 묶은 줄과 찍은 시간이 모두 사라져요. 계속할까요?';

  @override
  String get lyricsSyncResetConfirm => '바꾸기';

  @override
  String lyricsSyncMerged(int n) {
    return '$n줄 같은 시간으로 묶음';
  }

  @override
  String get lyricsSyncUnmerge => '풀기';

  @override
  String get playerLyricsExpand => '가사만 크게 보기';

  @override
  String get playerLyricsCollapse => '가사 닫기';

  @override
  String get playerShowLyrics => '가사 보기';

  @override
  String get playerShowCover => '커버 보기';

  @override
  String get lyricsEmpty => '가사가 없어요';

  @override
  String get lyricsEmptyHint => '곡 옆에 같은 이름의 .lrc 파일을 두거나, 직접 넣을 수 있어요.';

  @override
  String get playlistFavorites => '좋아요';

  @override
  String get playlistMenuTooltip => '재생목록 메뉴';

  @override
  String get playlistFeaturedTitle => '대표곡';

  @override
  String get playlistFeaturedPreview => '대표곡 미리 듣기';

  @override
  String get playlistMenuPlayAll => '전체 재생';

  @override
  String get playlistMenuShuffle => '셔플 재생';

  @override
  String get playlistMenuRename => '이름 바꾸기';

  @override
  String get playlistMenuDelete => '재생목록 삭제';

  @override
  String get playlistPlayEmpty => '재생할 곡이 없어요';

  @override
  String get playlistRenameTitle => '이름 바꾸기';

  @override
  String get playlistRenameSave => '저장';

  @override
  String get playlistDeleteTitle => '재생목록을 지울까요?';

  @override
  String playlistDeleteBody(String name) {
    return '‘$name’을(를) 지워요. 담긴 곡은 보관함에 그대로 남아요.';
  }

  @override
  String get playlistDeleteConfirm => '지우기';

  @override
  String get playlistDeleted => '재생목록을 지웠어요';

  @override
  String get playlistNewImage => '이미지 고르기';

  @override
  String get playlistNewImageChange => '이미지 바꾸기';

  @override
  String get playlistPickTitle => '재생목록 선택';

  @override
  String get playlistPickHint => '담을 재생목록을 골라 주세요';

  @override
  String get playlistPickDone => '완료';

  @override
  String get playlistPickAlready => '이미 담겼어요';

  @override
  String get filterAllArtists => '모든 아티스트';

  @override
  String get filterAllAlbums => '모든 앨범';

  @override
  String get filterAllGenres => '모든 장르';

  @override
  String get playlistAddTracks => '곡 추가';

  @override
  String get playlistAddTracksTitle => '곡 추가';

  @override
  String playlistAddTracksStart(int count) {
    return '$count곡 추가';
  }

  @override
  String get playlistAddTracksEmptyTitle => '추가할 곡이 없어요';

  @override
  String get playlistAddTracksEmptyBody => '보관함의 곡이 모두 이 재생목록에 있거나 검색 결과가 없어요.';

  @override
  String get playlistDetailEmpty => '아직 담긴 곡이 없어요';

  @override
  String get playlistDetailEmptyFavorites => '아직 좋아요한 곡이 없어요';

  @override
  String get playlistDetailEmptyBody =>
      '아래 ‘곡 추가’로 담아 보세요.';

  @override
  String get playlistDetailEmptyFavoritesBody => '곡 메뉴에서 좋아요를 누르면 여기에 담겨요.';

  @override
  String get playlistNotFound => '재생목록을 찾을 수 없어요';

  @override
  String get albumNotFound => '앨범을 찾을 수 없어요';

  @override
  String get playerQueueEmpty => '대기열이 비어 있어요';

  @override
  String get trackMenuFavorite => '좋아요';

  @override
  String get trackMenuUnfavorite => '좋아요 취소';

  @override
  String get trackFavoriteOn => '좋아요에 담았어요';

  @override
  String get trackFavoriteOff => '좋아요를 취소했어요';

  @override
  String get playlistImportHint => '재생목록 이름이나 주소';

  @override
  String get playlistImportEmptyTitle => '재생목록을 찾아 보세요';

  @override
  String get playlistImportEmptyBody =>
      '이름으로 찾거나 주소를 붙여 넣으면, 곡 목록에서 받을 곡을 고를 수 있어요.';

  @override
  String get playlistImportNoResultsTitle => '찾은 재생목록이 없어요';

  @override
  String get playlistImportNoResultsBody => '다른 검색어로 찾아 보세요.';

  @override
  String get playlistImportLoading => '곡 목록을 읽는 중이에요';

  @override
  String playlistImportSelectedCount(int selected, int total) {
    return '$selected/$total곡 선택됨';
  }

  @override
  String playlistImportResultSubtitle(String channel, int count) {
    return '$channel · $count곡';
  }

  @override
  String get playlistImportNotPlaylistTitle => '재생목록 주소가 아니에요';

  @override
  String get playlistImportNotPlaylistBody => '곡 하나의 주소예요. 재생목록 주소를 붙여 넣어 주세요.';

  @override
  String get playlistImportNoTracksTitle => '곡이 없어요';

  @override
  String get playlistImportNoTracksBody => '이 재생목록에는 받을 수 있는 곡이 없어요.';

  @override
  String get playlistImportSelectAll => '전체 선택';

  @override
  String get playlistImportClear => '선택 해제';

  @override
  String playlistImportStart(int count) {
    return '$count곡 받기';
  }

  @override
  String playlistImportStarted(int count) {
    return '$count곡을 받기 시작했어요';
  }

  @override
  String playlistImportStartedSkipped(int count, int skipped) {
    return '$count곡을 받기 시작했어요 (이미 받은 $skipped곡은 건너뛰었어요)';
  }

  @override
  String get searchPlaylistPick => '골라서 받기';

  @override
  String get settingsAccount => '계정';

  @override
  String get settingsGoogleAccount => '구글 계정';

  @override
  String get settingsAccountSignedOutDesc => '로그인하면 내 유튜브 재생목록을 불러올 수 있어요.';

  @override
  String get settingsAccountSignIn => '로그인';

  @override
  String get settingsAccountSignOut => '로그아웃';

  @override
  String settingsAccountNotConfigured(String keys) {
    return '구글 로그인 설정값($keys)이 이 빌드에 없어서 쓸 수 없어요. docs/google-login-setup.md를 보고 설정해 주세요';
  }

  @override
  String get playlistImportSignInPromptTitle => '구글 로그인이 필요해요';

  @override
  String get playlistImportSignInPromptBody =>
      '내 유튜브 재생목록을 불러오려면 구글 계정으로 로그인해야 해요. 지금 로그인할까요?';

  @override
  String get playlistImportSignInAllow => '로그인';

  @override
  String get settingsAccountUnsupported => '이 기기에서는 구글 로그인을 쓸 수 없어요';

  @override
  String get settingsAccountFailed => '로그인하지 못했어요. 다시 시도해 주세요';

  @override
  String get playlistImportMine => '내 재생목록';

  @override
  String get playlistImportMineTitle => '내 유튜브 재생목록';

  @override
  String get playlistImportMineEmptyTitle => '재생목록이 없어요';

  @override
  String get playlistImportMineEmptyBody => '이 계정에는 만든 재생목록이 없어요.';

  @override
  String get playlistImportLoginTitle => '로그인이 필요해요';

  @override
  String get playlistImportLoginBody => '내 유튜브 재생목록을 불러오려면 구글 계정으로 로그인해 주세요.';

  @override
  String get playlistImportLoginExpiredBody => '로그인이 풀렸어요. 다시 로그인해 주세요.';

  @override
  String get playlistImportNoChannelTitle => '유튜브 채널이 없어요';

  @override
  String get playlistImportNoChannelBody =>
      '이 구글 계정에는 유튜브 채널이 없어서 내 재생목록을 불러올 수 없어요. 재생목록 링크를 위 입력창에 붙여 넣어 보세요. 비공개 목록은 일부 공개로 바꿔야 해요.';

  @override
  String get searchPlaylistFind => '재생목록으로 찾기';

  @override
  String get settingsPermissions => '권한';

  @override
  String get permNotifications => '알림';

  @override
  String get permNotificationsDesc => '받기가 앱 밖에서도 이어지고 재생 알림이 보여요.';

  @override
  String get permAudio => '음악 파일 접근';

  @override
  String get permAudioDesc => '기기에 있는 음악을 불러오는 데 써요.';

  @override
  String get permOverlay => '다른 앱 위에 표시';

  @override
  String get permOverlayDesc => '다른 앱을 쓰는 동안 화면 위에 가사를 띄우는 데 써요.';

  @override
  String get permBlockedDesc => '요청이 막혀 있어요. 눌러서 휴대폰 설정에서 켜 주세요.';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsNotifyDownloadProgress => '받기 진행 알림';

  @override
  String get settingsNotifyDownloadProgressDesc =>
      '받는 동안 진행 상황을 알림창에 보여요.';

  @override
  String get settingsNotifyDownloadResult => '받기 결과 알림';

  @override
  String get settingsNotifyDownloadResultDesc => '받기가 끝나거나 실패하면 알려요.';

  @override
  String get settingsNotifyPlayback => '재생 알림';

  @override
  String get settingsNotifyPlaybackDesc => '알림창 · 잠금화면에서 재생을 조작해요.';

  @override
  String get lyricsOverlayMinimize => '숨기기';

  @override
  String get lyricsOverlayTurnOff => '끄기';

  @override
  String get lyricsOverlayOn => '오버레이 가사 켜기';

  @override
  String get lyricsOverlayOff => '오버레이 가사 끄기';

  @override
  String get lyricsOverlayNoLyrics => '가사가 없어요';

  @override
  String get lyricsOverlayNotSynced => '싱크된 가사가 없어요';

  @override
  String get lyricsOverlayNeedPermission =>
      '설정에서 \"다른 앱 위에 표시\"를 허용한 뒤 다시 켜 주세요.';

  @override
  String get settingsNotifyPermission => '시스템 알림이 꺼져 있어요';

  @override
  String get settingsNotifyPermissionDesc => '휴대폰 설정에서 Mulo 알림을 켜야 알림이 보여요.';

  @override
  String get settingsNotifyOpenSettings => '설정 열기';

  @override
  String get notifHiddenTitle => '음악 재생 중';

  @override
  String get notifPreviewLabel => '미리 듣기';

  @override
  String notifSleepAt(String time) {
    return '$time에 수면 타이머';
  }

  @override
  String get notifHiddenNote => '곡 정보 숨김';

  @override
  String notifHiddenNotePosition(String n, String total) {
    return '곡 정보 숨김 · $n/$total번째 곡';
  }

  @override
  String get notifStop => '닫기';

  @override
  String get notifChannelPlayback => '재생';

  @override
  String get notifChannelDownloadProgress => '받는 중';

  @override
  String get notifChannelDownloadDone => '받기 완료';

  @override
  String get notifChannelDownloadFailed => '받기 실패';

  @override
  String get notifDownloadHiddenTitle => '곡 받는 중';

  @override
  String notifDownloadProgressBody(int percent) {
    return '받는 중 · $percent%';
  }

  @override
  String notifDownloadProgressNext(int percent, String next) {
    return '받는 중 · $percent% · 다음 곡: $next';
  }

  @override
  String notifDownloadOverall(int done, int total, int percent) {
    return '전체 $done/$total곡 · $percent%';
  }

  @override
  String get notifDownloadPreview => '미리듣기';

  @override
  String get notifDownloadCancel => '취소';

  @override
  String get notifDownloadPause => '일시정지';

  @override
  String get notifDownloadResume => '이어받기';

  @override
  String notifDownloadPausedBody(int percent) {
    return '일시정지됨 · $percent%';
  }

  @override
  String get notifDownloadPausePreview => '일시정지';

  @override
  String get notifDownloadResumePreview => '이어 듣기';

  @override
  String get notifDownloadStopPreview => '중지';

  @override
  String get notifDownloadDoneTitle => '받기 완료';

  @override
  String get notifDownloadDoneHidden => '곡이 보관함에 추가됐어요';

  @override
  String get notifDownloadFailedTitle => '받기 실패';

  @override
  String get notifDownloadFailedHidden => '곡을 받지 못했어요';

  @override
  String get subscribeAction => '구독';

  @override
  String get subscribedAction => '구독 중';

  @override
  String get subscribeAdded => '구독했어요. 지금부터 올라오는 영상을 알려 드려요';

  @override
  String get subscribeFailed => '이 채널은 구독할 수 없어요';

  @override
  String get unsubscribed => '구독을 해제했어요';

  @override
  String get subscriptionsTitle => '구독 채널';

  @override
  String get subscriptionsSubtitle => '새 영상 골라 받기';

  @override
  String get subscriptionsEmptyTitle => '구독한 채널이 없어요';

  @override
  String get subscriptionsEmptyBody =>
      '영상 상세에서 채널을 구독하면 새 영상이 올라올 때 골라서 받을 수 있어요.';

  @override
  String get subscriptionsNewVideos => '새 영상 보기';

  @override
  String get subscriptionsUnsubscribe => '구독 해제';

  @override
  String subscriptionsCount(int count) {
    return '$count개 채널';
  }

  @override
  String get newVideosTitle => '새 영상';

  @override
  String get newVideosChecking => '새 영상을 확인하고 있어요';

  @override
  String get newVideosEmptyTitle => '새 영상이 없어요';

  @override
  String get newVideosEmptyBody => '구독한 채널에 새 영상이 올라오면 여기에서 골라 받을 수 있어요.';

  @override
  String newVideosSummary(int channels, int videos) {
    return '채널 $channels개 · 영상 $videos개';
  }

  @override
  String newVideosStart(int count) {
    return '$count곡 받기';
  }

  @override
  String newVideosStarted(int count) {
    return '$count곡을 받기 시작했어요';
  }

  @override
  String get newVideosSkipped => '이미 받은 곡이라 새로 받을 곡이 없어요';

  @override
  String get newVideosClear => '비우기';

  @override
  String get newVideosClearTitle => '새 영상 목록을 비울까요?';

  @override
  String get newVideosClearBody =>
      '받지 않은 영상도 목록에서 사라지고 다시 뜨지 않아요. 이후 올라오는 영상만 새 영상으로 보여요.';

  @override
  String get newVideosSelectAll => '모두 선택';

  @override
  String get newVideosSelectNone => '선택 해제';

  @override
  String newVideosAnnounce(int count) {
    return '구독 채널에 새 영상이 $count개 있어요';
  }

  @override
  String get newVideosOpen => '보기';

  @override
  String get settingsSubscriptions => '구독';

  @override
  String get settingsSubscriptionChannels => '구독 채널';

  @override
  String get settingsCheckOnLaunch => '앱을 켤 때 새 영상 확인';

  @override
  String get settingsCheckOnLaunchDesc => '구독한 채널에 새 영상이 있으면 알려 주고 골라서 받게 해요.';

  @override
  String get settingsBackgroundCheck => '앱이 꺼져 있어도 확인';

  @override
  String get settingsBackgroundCheckDesc => '주기적으로 확인하고 새 영상이 있으면 알림으로 알려요.';

  @override
  String get settingsCheckInterval => '확인 주기';

  @override
  String settingsCheckIntervalHours(int count) {
    return '$count시간';
  }

  @override
  String get settingsCheckWifiOnly => '와이파이에서만 확인';

  @override
  String get settingsCheckWifiOnlyDesc => '데이터를 쓰지 않도록 와이파이에 연결됐을 때만 확인해요.';

  @override
  String get settingsCheckNow => '지금 확인';

  @override
  String get settingsCheckNowChecking => '확인하는 중…';

  @override
  String get settingsCheckStatusNever => '아직 확인한 적이 없어요.';

  @override
  String settingsCheckStatusLast(String time) {
    return '마지막 확인 $time';
  }

  @override
  String settingsCheckStatusNotified(int count) {
    return '새 영상 $count개를 알렸어요.';
  }

  @override
  String settingsCheckStatusFailed(int count) {
    return '채널 $count개를 읽지 못했어요.';
  }

  @override
  String get settingsCheckStatusBlocked =>
      '알림이 꺼져 있어 알리지 못했어요. 기기 설정에서 Mulo 알림(새 영상 포함)을 켜 주세요.';

  @override
  String get settingsCheckStatusNotScheduled =>
      '주기 확인이 예약되지 않았어요. 위 스위치를 껐다 켜 보세요.';

  @override
  String get notifChannelNewVideos => '새 영상';

  @override
  String get notifNewVideosTitle => '구독 채널에 새 영상이 올라왔어요';

  @override
  String notifNewVideosBody(String channels, String count) {
    return '$channels · 새 영상 $count개';
  }

  @override
  String get channelSearchTitle => '채널 검색';

  @override
  String get channelSearchHint => '채널 이름으로 찾기';

  @override
  String get channelSearchIdle => '구독할 채널 이름을 검색해 보세요';

  @override
  String get channelSearchLoading => '채널을 찾는 중이에요';

  @override
  String get channelSearchEmpty => '찾은 채널이 없어요';

  @override
  String get channelSearchFailed => '채널을 찾지 못했어요. 잠시 뒤 다시 시도해 주세요';

  @override
  String get categoryAll => '모든 분류';

  @override
  String get subscriptionsCategories => '알림 받을 분류';

  @override
  String get subscriptionsCategoriesDesc =>
      '고른 분류의 새 영상만 알리고 보여 줘요. 고르지 않으면 모든 분류예요.';

  @override
  String channelInfoVideoCount(int count) {
    return '영상 $count개';
  }

  @override
  String get channelSaveFolder => '저장 위치';

  @override
  String get channelSaveFolderDefault => '기본 저장 위치';

  @override
  String get channelSaveFolderChange => '변경';

  @override
  String get channelSaveFolderReset => '기본으로';

  @override
  String get notifNewVideoDownloadNow => '바로 받기';

  @override
  String get equalizerTitle => '이퀄라이저';

  @override
  String get equalizerOn => '켜짐';

  @override
  String get equalizerOff => '꺼짐';

  @override
  String get equalizerUnsupported => '이 기기에서는 이퀄라이저를 쓸 수 없어요';

  @override
  String get equalizerEnable => '이퀄라이저 사용';

  @override
  String get equalizerEnableDesc => '켜면 아래 설정대로 소리를 다듬어요. 기본은 꺼짐이에요.';

  @override
  String get equalizerDeviceProfile => '이 기기 전용으로 저장';

  @override
  String equalizerDeviceProfileDesc(String device) {
    return '$device에 연결되면 이 설정을 자동으로 적용해요.';
  }

  @override
  String get equalizerMyPresets => '내 프리셋';

  @override
  String get equalizerMyPresetsHint => '길게 누르면 지워요';

  @override
  String get equalizerPresetSaveNew => '지금 값 저장';

  @override
  String get equalizerPresetNameTitle => '프리셋 이름';

  @override
  String get equalizerPresetNameHint => '예: 이어폰용, 차량용';

  @override
  String get equalizerPresetSave => '저장';

  @override
  String get equalizerPresetDeleteTitle => '프리셋 지우기';

  @override
  String equalizerPresetDeleteBody(String name) {
    return '\"$name\" 프리셋을 지워요. 이 프리셋을 지정한 기기는 마지막 값을 그대로 써요';
  }

  @override
  String get equalizerDevicesTitle => '기기별 이퀄라이저';

  @override
  String get equalizerDevicesEmpty => '아직 연결된 블루투스 · 이어폰 기기가 없어요';

  @override
  String get equalizerDeviceDefault => '기본 설정';

  @override
  String get equalizerDeviceCustom => '직접 설정';

  @override
  String get equalizerDeviceEdit => '이퀄라이저에서 직접 설정';

  @override
  String get equalizerEditingDevice => '이 기기에 쓸 값을 고치는 중이에요';

  @override
  String get equalizerDeviceCurrent => '지금 연결됨';

  @override
  String equalizerDevicePickTitle(String device) {
    return '$device에 쓸 프리셋';
  }

  @override
  String get equalizerDeviceNoPresets =>
      '이퀄라이저 화면에서 \"지금 값 저장\"으로 프리셋을 먼저 만들어 주세요';

  @override
  String get equalizerPreset => '프리셋';

  @override
  String get equalizerBands => '대역별 조절';

  @override
  String get equalizerBassBoost => '저음 강화';

  @override
  String get equalizerBassBoostDesc => '낮은 소리를 더 묵직하게 해요.';

  @override
  String get equalizerReset => '처음으로';

  @override
  String get equalizerPresetFlat => '기본';

  @override
  String get equalizerPresetBass => '저음 강조';

  @override
  String get equalizerPresetTreble => '고음 강조';

  @override
  String get equalizerPresetVocal => '보컬';

  @override
  String get equalizerPresetRock => '록';

  @override
  String get equalizerPresetPop => '팝';

  @override
  String get equalizerPresetJazz => '재즈';

  @override
  String get equalizerPresetClassical => '클래식';

  @override
  String get equalizerPresetDance => '힙합 · EDM';

  @override
  String get equalizerPresetCustom => '직접 조절';

  @override
  String get equalizerVirtualizer => '입체 음향';

  @override
  String get equalizerVirtualizerDesc => '이어폰에서 소리가 더 넓게 퍼져 들려요.';

  @override
  String get equalizerReverb => '공간 울림';

  @override
  String get equalizerReverbDesc => '방이나 홀에서 듣는 것 같은 잔향을 더해요.';

  @override
  String get equalizerLimiter => '소리 찢어짐 방지';

  @override
  String get equalizerLimiterDesc => '소리를 많이 키워도 갈라지지 않게 눌러 줘요.';

  @override
  String get equalizerReverbNone => '없음';

  @override
  String get equalizerReverbSmallRoom => '작은 방';

  @override
  String get equalizerReverbMediumRoom => '중간 방';

  @override
  String get equalizerReverbLargeRoom => '큰 방';

  @override
  String get equalizerReverbMediumHall => '중간 홀';

  @override
  String get equalizerReverbLargeHall => '큰 홀';

  @override
  String get equalizerReverbPlate => '플레이트';

  @override
  String get equalizerSave => '저장';

  @override
  String get audioLanguageTitle => '오디오 언어';

  @override
  String get audioLanguageRow => '오디오 언어';

  @override
  String get audioLanguageOriginal => '원본';

  @override
  String get audioLanguageHint => '고르면 바로 적용돼요. 미리 듣기와 받기에 같은 언어를 써요.';

  @override
  String get downloadAgainTitle => '다시 받을까요?';

  @override
  String get downloadAgainBody => '이미 받은 곡이에요. 다시 받으면 같은 곡이 하나 더 생겨요.';

  @override
  String get downloadAgainConfirm => '다시 받기';

  @override
  String selectCount(int count) {
    return '$count곡 선택';
  }

  @override
  String get selectClose => '선택 끝내기';

  @override
  String get selectAssignAlbum => '앨범 지정';

  @override
  String get selectAssignArtist => '아티스트 지정';

  @override
  String get selectAssignGenre => '장르 지정';

  @override
  String get selectAssignAlbumTitle => '앨범 바꾸기';

  @override
  String get selectAssignArtistTitle => '아티스트 바꾸기';

  @override
  String get selectAssignGenreTitle => '장르 바꾸기';

  @override
  String selectConfirmAlbum(int count, String value) {
    return '고른 $count곡의 앨범을 바꿀까요?\n\n새 앨범: $value\n\n이 곡들은 다른 앨범에서 빠지고, 음악 파일 정보도 함께 바뀌어요.';
  }

  @override
  String selectConfirmArtist(int count, String value) {
    return '고른 $count곡의 아티스트를 바꿀까요?\n\n새 아티스트: $value\n\n이 곡들은 다른 아티스트에서 빠지고, 음악 파일 정보도 함께 바뀌어요.';
  }

  @override
  String selectConfirmGenre(int count, String value) {
    return '고른 $count곡의 장르를 바꿀까요?\n\n새 장르: $value\n\n이 곡들은 다른 장르에서 빠지고, 음악 파일 정보도 함께 바뀌어요.';
  }

  @override
  String get selectConfirmApply => '바꾸기';

  @override
  String selectAssignPartial(int count) {
    return '$count곡은 음악 파일에 정보를 쓰지 못해 바꾸지 않았어요.';
  }

  @override
  String get selectActions => '작업';

  @override
  String get selectAssignHintAlbum =>
      '고른 곡 모두에 넣을 앨범 이름을 적어요. 비워 두면 앨범 정보가 없는 곡이 돼요.';

  @override
  String get selectAssignHintArtist =>
      '고른 곡 모두에 넣을 아티스트 이름을 적어요. 비워 두면 아티스트 정보가 없는 곡이 돼요.';

  @override
  String get selectAssignHintGenre =>
      '고른 곡 모두에 넣을 장르를 적어요. 비워 두면 장르 정보가 없는 곡이 돼요.';

  @override
  String get selectNext => '다음';

  @override
  String get playlistImportChannels => '구독 채널의 재생목록';

  @override
  String get channelPickTitle => '채널 고르기';

  @override
  String get channelPickEmpty =>
      '아직 구독한 채널이 없어요. 아래에서 내 YouTube 구독 채널을 가져올 수 있어요.';

  @override
  String get channelPlaylistsUploads => '업로드한 영상 전체';

  @override
  String get channelImportOpen => '내 YouTube 구독에서 채널 고르기';

  @override
  String get channelImportTitle => '내 구독 채널';

  @override
  String get channelImportHint => '구독할 채널을 눌러 골라요. 고른 채널만 추가돼요.';

  @override
  String get channelImportAlready => '구독 중';

  @override
  String channelImportLoading(int count) {
    return '구독 채널 $count개 불러오는 중…';
  }

  @override
  String get channelImportEmptyTitle => '구독한 채널이 없어요';

  @override
  String get channelImportEmptyBody => '이 구글 계정으로 YouTube에서 구독한 채널이 없어요.';

  @override
  String get channelImportSignInBody => '내 YouTube 구독 채널을 불러오려면 구글 로그인이 필요해요.';

  @override
  String channelImportSelectCount(int count) {
    return '$count개 채널 선택';
  }

  @override
  String get channelImportSelectNew => '새 채널 모두 선택';

  @override
  String get channelImportSubscribe => '고른 채널 구독하기';

  @override
  String get channelImportConfirmTitle => '채널 구독';

  @override
  String channelImportConfirmBody(int count) {
    return '고른 $count개 채널을 구독할까요? 지금부터 올라오는 영상을 알려 드려요.';
  }

  @override
  String channelImportDone(int count) {
    return '$count개 채널을 구독했어요';
  }
}
