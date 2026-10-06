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
  String get genreNotFound => '장르를 찾을 수 없어요';

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
  String get settingsSavePathDesc => '앱 기본 폴더';

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
  String get settingsEngineInstall => '설치';

  @override
  String get settingsEngineNotInstalled => 'yt-dlp가 없어요. 설치하면 검색하고 받을 수 있어요.';

  @override
  String get settingsEngineInstalling => '내려받는 중…';

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
  String get settingsThemePreviewDesc => '고른 테마로 앱 화면들을 직접 둘러보고 적용해요';

  @override
  String get playerStyleTitle => '플레이어 테마';

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
  String get playerSleepTimerCleared => '수면 타이머를 껐어요';

  @override
  String get playerEqualizer => '이퀄라이저';

  @override
  String get playerEqualizerSoon => '이퀄라이저는 준비 중이에요';

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
  String get queueShuffle => '다음 곡 섞기';

  @override
  String get queueClear => '대기열 비우기';

  @override
  String get queueCleared => '대기열을 비웠어요';

  @override
  String get queueReorderHint => '길게 눌러 끌면 순서가 바뀌어요';

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
  String get searchHintWeb => '웹 음원 검색어나 URL';

  @override
  String get searchSourceTooltip => '검색 대상';

  @override
  String get sourceYoutube => '유튜브';

  @override
  String get sourceWeb => '웹';

  @override
  String get searchHitMenuDetail => '상세 보기';

  @override
  String get searchPreview => '미리 듣기';

  @override
  String get searchPreviewStop => '미리 듣기 멈추기';

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
  String get mediaDetailChannel => '채널';

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
  String get searchSortShortest => '짧은 순';

  @override
  String get searchSortLongest => '긴 순';

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
  String get downloadFieldSavePath => '저장 위치';

  @override
  String get downloadGenreExisting => '기존 장르에서 고르기';

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
  String get lyricsMenuEdit => '가사 편집';

  @override
  String get lyricsEditTitle => '가사 설정';

  @override
  String get lyricsEditLabel => '가사';

  @override
  String get lyricsEditHint =>
      '가사를 붙여넣거나 입력하세요. [01:02.30]처럼 시간이 붙은 글이나 .lrc · .txt 파일을 불러오면 싱크 가사가 돼요. 비워서 저장하면 가사를 지워요.';

  @override
  String get lyricsLoadFile => '파일에서 불러오기';

  @override
  String get lyricsWebSearch => '웹에서 가져오기';

  @override
  String get lyricsWebTitle => '가사 검색';

  @override
  String get lyricsWebHint =>
      '가사를 길게 눌러 끌어서 고른 뒤 \'담기\'를 누르세요. 여러 번 담은 뒤 \'가져오기\'로 한꺼번에 넣어요.';

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
  String get lyricsSyncSave => '싱크 저장';

  @override
  String get lyricsSyncReplay => '이 줄부터 다시 듣기';

  @override
  String get lyricsSyncReset => '이 싱크로';

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
  String get lyricsSyncPlay => '재생';

  @override
  String get lyricsSyncPause => '일시정지';

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
  String get lyricsSyncGroupSetupBody =>
      '한 번에 시간을 찍을 줄 수를 골라 주세요. 나중에 위쪽 메뉴에서 바꿀 수 있어요.';

  @override
  String get lyricsSyncLeaveTitle => '싱크가 저장되지 않아요';

  @override
  String get lyricsSyncLeaveBody =>
      '아직 모든 줄에 시간을 찍지 않았어요. 지금 나가면 찍은 시간이 사라져요. 지금까지 찍은 싱크를 저장하고 나갈까요?';

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
  String get lyricsSyncResetTitle => '묶음이 사라져요';

  @override
  String get lyricsSyncResetBody =>
      '기본 줄 수를 바꾸면 직접 묶은 줄과 찍은 시간이 모두 사라지고, 고른 줄 수로 다시 나뉘어요. 계속할까요?';

  @override
  String get lyricsSyncResetConfirm => '바꾸기';

  @override
  String get lyricsSyncGroupEdit => '줄 묶기';

  @override
  String get lyricsSyncGroupDone => '완료';

  @override
  String get lyricsSyncGroupPanelHint =>
      '묶을 마지막 줄을 누르거나 끌어서 고르세요. 이 싱크의 시간은 다시 찍어야 해요.';

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
  String get playlistDetailEmpty => '아직 담긴 곡이 없어요. 곡 메뉴의 ‘재생목록에 추가’로 담아 보세요.';

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
}
