import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get appTitle;

  /// No description provided for @navSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get navSearch;

  /// No description provided for @navDownloads.
  ///
  /// In ko, this message translates to:
  /// **'다운로드'**
  String get navDownloads;

  /// No description provided for @navLibrary.
  ///
  /// In ko, this message translates to:
  /// **'보관함'**
  String get navLibrary;

  /// No description provided for @navPlaylists.
  ///
  /// In ko, this message translates to:
  /// **'재생목록'**
  String get navPlaylists;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @actionPlay.
  ///
  /// In ko, this message translates to:
  /// **'재생'**
  String get actionPlay;

  /// No description provided for @actionPause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get actionPause;

  /// No description provided for @actionNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 곡'**
  String get actionNext;

  /// No description provided for @actionPrevious.
  ///
  /// In ko, this message translates to:
  /// **'이전 곡'**
  String get actionPrevious;

  /// No description provided for @actionBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get actionBack;

  /// No description provided for @actionMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get actionMore;

  /// No description provided for @actionDownload.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get actionDownload;

  /// No description provided for @actionPaste.
  ///
  /// In ko, this message translates to:
  /// **'붙여넣기'**
  String get actionPaste;

  /// No description provided for @actionClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get actionClear;

  /// No description provided for @actionRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get actionRetry;

  /// No description provided for @actionResume.
  ///
  /// In ko, this message translates to:
  /// **'이어 받기'**
  String get actionResume;

  /// No description provided for @actionCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get actionCancel;

  /// No description provided for @actionPlayAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 재생'**
  String get actionPlayAll;

  /// No description provided for @actionShuffle.
  ///
  /// In ko, this message translates to:
  /// **'셔플'**
  String get actionShuffle;

  /// No description provided for @unitSongs.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get unitSongs;

  /// No description provided for @songCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡'**
  String songCount(int count);

  /// No description provided for @searchSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'찾고 받기'**
  String get searchSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'유튜브 URL이나 검색어'**
  String get searchHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 받을까요?'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'URL을 붙여넣거나 검색어를 입력하세요.\n유튜브 앱에서 공유를 누르면 바로 여기로 와요.'**
  String get searchEmptyBody;

  /// No description provided for @searchNotReadyTitle.
  ///
  /// In ko, this message translates to:
  /// **'쓸 수 있는 엔진이 없어요'**
  String get searchNotReadyTitle;

  /// No description provided for @searchNotReadyBody.
  ///
  /// In ko, this message translates to:
  /// **'서버 주소가 빌드에 없고 이 기기에 yt-dlp도 없어서 검색할 수 없어요.\n서버를 연결하거나 yt-dlp를 설치해 주세요.'**
  String get searchNotReadyBody;

  /// No description provided for @searchErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했어요'**
  String get searchErrorTitle;

  /// No description provided for @searchErrorBody.
  ///
  /// In ko, this message translates to:
  /// **'잠시 뒤에 다시 시도해 주세요.'**
  String get searchErrorBody;

  /// No description provided for @searchNetworkBody.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결하지 못했어요. 인터넷 연결을 확인해 주세요.'**
  String get searchNetworkBody;

  /// No description provided for @searchAuthBody.
  ///
  /// In ko, this message translates to:
  /// **'서버가 로그인을 요구해요.'**
  String get searchAuthBody;

  /// No description provided for @searchNotFoundBody.
  ///
  /// In ko, this message translates to:
  /// **'이 주소는 받을 수 없는 곳이에요.'**
  String get searchNotFoundBody;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In ko, this message translates to:
  /// **'결과가 없어요'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In ko, this message translates to:
  /// **'다른 검색어로 찾아보세요.'**
  String get searchNoResultsBody;

  /// No description provided for @searchLoadMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get searchLoadMore;

  /// No description provided for @searchResultsTitle.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과'**
  String get searchResultsTitle;

  /// No description provided for @searchUrlCardLabel.
  ///
  /// In ko, this message translates to:
  /// **'URL에서 찾은 곡'**
  String get searchUrlCardLabel;

  /// No description provided for @searchPlaylistLabel.
  ///
  /// In ko, this message translates to:
  /// **'재생목록'**
  String get searchPlaylistLabel;

  /// No description provided for @searchSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 선택'**
  String get searchSelectAll;

  /// No description provided for @searchDownloadSelected.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡 받기'**
  String searchDownloadSelected(int count);

  /// No description provided for @alreadyDownloaded.
  ///
  /// In ko, this message translates to:
  /// **'이미 받은 곡'**
  String get alreadyDownloaded;

  /// No description provided for @qualityBest.
  ///
  /// In ko, this message translates to:
  /// **'최고'**
  String get qualityBest;

  /// No description provided for @qualityNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get qualityNormal;

  /// No description provided for @qualitySaver.
  ///
  /// In ko, this message translates to:
  /// **'절약'**
  String get qualitySaver;

  /// No description provided for @downloadsActive.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get downloadsActive;

  /// No description provided for @downloadsWaiting.
  ///
  /// In ko, this message translates to:
  /// **'대기 {count}'**
  String downloadsWaiting(int count);

  /// No description provided for @downloadsPauseAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 일시정지'**
  String get downloadsPauseAll;

  /// No description provided for @downloadsClearDone.
  ///
  /// In ko, this message translates to:
  /// **'완료 지우기'**
  String get downloadsClearDone;

  /// No description provided for @statusDownloading.
  ///
  /// In ko, this message translates to:
  /// **'받는 중'**
  String get statusDownloading;

  /// No description provided for @statusFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get statusFailed;

  /// No description provided for @statusPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get statusPaused;

  /// No description provided for @statusQueued.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get statusQueued;

  /// No description provided for @statusDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get statusDone;

  /// No description provided for @downloadsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'받는 중인 곡이 없어요.'**
  String get downloadsEmpty;

  /// No description provided for @librarySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'내 음악'**
  String get librarySubtitle;

  /// No description provided for @librarySongs.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get librarySongs;

  /// No description provided for @libraryArtists.
  ///
  /// In ko, this message translates to:
  /// **'아티스트'**
  String get libraryArtists;

  /// No description provided for @libraryAlbums.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get libraryAlbums;

  /// No description provided for @librarySearchHint.
  ///
  /// In ko, this message translates to:
  /// **'보관함에서 찾기'**
  String get librarySearchHint;

  /// No description provided for @libraryGenres.
  ///
  /// In ko, this message translates to:
  /// **'장르'**
  String get libraryGenres;

  /// No description provided for @unknownGenre.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 장르'**
  String get unknownGenre;

  /// No description provided for @genreNotFound.
  ///
  /// In ko, this message translates to:
  /// **'장르를 찾을 수 없어요'**
  String get genreNotFound;

  /// No description provided for @sortLabel.
  ///
  /// In ko, this message translates to:
  /// **'정렬'**
  String get sortLabel;

  /// No description provided for @sortName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get sortName;

  /// No description provided for @sortAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가일순'**
  String get sortAdded;

  /// No description provided for @sortArtist.
  ///
  /// In ko, this message translates to:
  /// **'아티스트순'**
  String get sortArtist;

  /// No description provided for @libraryImport.
  ///
  /// In ko, this message translates to:
  /// **'기기 음악 불러오기'**
  String get libraryImport;

  /// No description provided for @libraryNoMatch.
  ///
  /// In ko, this message translates to:
  /// **'찾는 곡이 없어요.'**
  String get libraryNoMatch;

  /// No description provided for @playlistsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'모음'**
  String get playlistsSubtitle;

  /// No description provided for @playlistsNew.
  ///
  /// In ko, this message translates to:
  /// **'새 재생목록'**
  String get playlistsNew;

  /// No description provided for @playlistsImport.
  ///
  /// In ko, this message translates to:
  /// **'유튜브 재생목록 가져오기'**
  String get playlistsImport;

  /// No description provided for @settingsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 설정'**
  String get settingsSubtitle;

  /// No description provided for @settingsServer.
  ///
  /// In ko, this message translates to:
  /// **'서버'**
  String get settingsServer;

  /// No description provided for @settingsConnection.
  ///
  /// In ko, this message translates to:
  /// **'연결 상태'**
  String get settingsConnection;

  /// No description provided for @settingsDisconnected.
  ///
  /// In ko, this message translates to:
  /// **'연결 안 됨'**
  String get settingsDisconnected;

  /// No description provided for @settingsServerConfigured.
  ///
  /// In ko, this message translates to:
  /// **'서버 주소 설정됨'**
  String get settingsServerConfigured;

  /// No description provided for @settingsMode.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 모드'**
  String get settingsMode;

  /// No description provided for @settingsModeServer.
  ///
  /// In ko, this message translates to:
  /// **'서버'**
  String get settingsModeServer;

  /// No description provided for @settingsModeLocal.
  ///
  /// In ko, this message translates to:
  /// **'로컬'**
  String get settingsModeLocal;

  /// No description provided for @settingsModeLiteNote.
  ///
  /// In ko, this message translates to:
  /// **'lite 빌드는 서버 모드만 쓸 수 있어요.'**
  String get settingsModeLiteNote;

  /// No description provided for @settingsDownload.
  ///
  /// In ko, this message translates to:
  /// **'다운로드'**
  String get settingsDownload;

  /// No description provided for @settingsSavePath.
  ///
  /// In ko, this message translates to:
  /// **'저장 위치'**
  String get settingsSavePath;

  /// No description provided for @settingsSavePathDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱 기본 폴더'**
  String get settingsSavePathDesc;

  /// No description provided for @settingsLoadedFolders.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 폴더'**
  String get settingsLoadedFolders;

  /// No description provided for @settingsLoadedFoldersCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 폴더'**
  String settingsLoadedFoldersCount(int count);

  /// No description provided for @loadedFoldersHint.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더 안의 음악을 보관함에 불러와요. 하위 폴더도 포함돼요.'**
  String get loadedFoldersHint;

  /// No description provided for @loadedFoldersTrackCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡'**
  String loadedFoldersTrackCount(int count);

  /// No description provided for @loadedFoldersDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 저장 위치'**
  String get loadedFoldersDefault;

  /// No description provided for @loadedFoldersAdd.
  ///
  /// In ko, this message translates to:
  /// **'폴더 추가'**
  String get loadedFoldersAdd;

  /// No description provided for @loadedFoldersRemove.
  ///
  /// In ko, this message translates to:
  /// **'폴더 빼기'**
  String get loadedFoldersRemove;

  /// No description provided for @loadedFoldersScanning.
  ///
  /// In ko, this message translates to:
  /// **'보관함을 다시 찾는 중이에요'**
  String get loadedFoldersScanning;

  /// No description provided for @settingsQuality.
  ///
  /// In ko, this message translates to:
  /// **'기본 음질'**
  String get settingsQuality;

  /// No description provided for @settingsFormat.
  ///
  /// In ko, this message translates to:
  /// **'기본 포맷'**
  String get settingsFormat;

  /// No description provided for @settingsEngine.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 엔진'**
  String get settingsEngine;

  /// No description provided for @settingsEngineVersion.
  ///
  /// In ko, this message translates to:
  /// **'현재 {current} · 최신 {latest}'**
  String settingsEngineVersion(String current, String latest);

  /// No description provided for @settingsEngineUpdate.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get settingsEngineUpdate;

  /// No description provided for @settingsEngineInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치'**
  String get settingsEngineInstall;

  /// No description provided for @settingsEngineNotInstalled.
  ///
  /// In ko, this message translates to:
  /// **'yt-dlp가 없어요. 설치하면 검색하고 받을 수 있어요.'**
  String get settingsEngineNotInstalled;

  /// No description provided for @settingsEngineInstalling.
  ///
  /// In ko, this message translates to:
  /// **'내려받는 중…'**
  String get settingsEngineInstalling;

  /// No description provided for @settingsEngineFailed.
  ///
  /// In ko, this message translates to:
  /// **'설치하지 못했어요. 인터넷 연결을 확인해 주세요.'**
  String get settingsEngineFailed;

  /// No description provided for @settingsEngineInstalled.
  ///
  /// In ko, this message translates to:
  /// **'yt-dlp {version}'**
  String settingsEngineInstalled(String version);

  /// No description provided for @settingsSecurity.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get settingsSecurity;

  /// No description provided for @settingsAppLock.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금'**
  String get settingsAppLock;

  /// No description provided for @settingsChangePin.
  ///
  /// In ko, this message translates to:
  /// **'PIN 바꾸기'**
  String get settingsChangePin;

  /// No description provided for @settingsChangePinDesc.
  ///
  /// In ko, this message translates to:
  /// **'현재 PIN(또는 지문 · 얼굴)을 확인한 뒤 새 PIN으로 바꿔요.'**
  String get settingsChangePinDesc;

  /// No description provided for @settingsAppLockDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱을 열 때 PIN(4~6자리)을 물어요.'**
  String get settingsAppLockDesc;

  /// No description provided for @settingsBiometric.
  ///
  /// In ko, this message translates to:
  /// **'지문 · 얼굴로 열기'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricDesc.
  ///
  /// In ko, this message translates to:
  /// **'PIN 대신 기기의 생체 인증으로 잠금을 풀어요.'**
  String get settingsBiometricDesc;

  /// No description provided for @biometricReason.
  ///
  /// In ko, this message translates to:
  /// **'Mulo 잠금을 풀어요'**
  String get biometricReason;

  /// No description provided for @pinCreateTitle.
  ///
  /// In ko, this message translates to:
  /// **'PIN 정하기'**
  String get pinCreateTitle;

  /// No description provided for @pinCreateHint.
  ///
  /// In ko, this message translates to:
  /// **'4~6자리 숫자를 입력하세요.'**
  String get pinCreateHint;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'PIN 한 번 더'**
  String get pinConfirmTitle;

  /// No description provided for @pinConfirmHint.
  ///
  /// In ko, this message translates to:
  /// **'같은 PIN을 다시 입력하세요.'**
  String get pinConfirmHint;

  /// No description provided for @pinMismatch.
  ///
  /// In ko, this message translates to:
  /// **'PIN이 서로 달라요. 처음부터 다시 정해 주세요.'**
  String get pinMismatch;

  /// No description provided for @pinCurrentTitle.
  ///
  /// In ko, this message translates to:
  /// **'현재 PIN'**
  String get pinCurrentTitle;

  /// No description provided for @pinCurrentHint.
  ///
  /// In ko, this message translates to:
  /// **'잠금을 끄려면 현재 PIN을 입력하세요.'**
  String get pinCurrentHint;

  /// No description provided for @pinCurrentHintChange.
  ///
  /// In ko, this message translates to:
  /// **'PIN을 바꾸려면 현재 PIN을 입력하세요.'**
  String get pinCurrentHintChange;

  /// No description provided for @pinCurrentHintBiometric.
  ///
  /// In ko, this message translates to:
  /// **'현재 PIN을 입력하거나 지문 · 얼굴로 확인하세요.'**
  String get pinCurrentHintBiometric;

  /// No description provided for @pinWrong.
  ///
  /// In ko, this message translates to:
  /// **'PIN이 달라요.'**
  String get pinWrong;

  /// No description provided for @pinCooldown.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 다시 시도하세요.'**
  String pinCooldown(int seconds);

  /// No description provided for @pinSubmit.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get pinSubmit;

  /// No description provided for @pinBackspace.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get pinBackspace;

  /// No description provided for @pinUseBiometric.
  ///
  /// In ko, this message translates to:
  /// **'생체 인증으로 열기'**
  String get pinUseBiometric;

  /// No description provided for @lockTitle.
  ///
  /// In ko, this message translates to:
  /// **'잠겨 있어요'**
  String get lockTitle;

  /// No description provided for @lockHint.
  ///
  /// In ko, this message translates to:
  /// **'PIN을 입력하세요.'**
  String get lockHint;

  /// No description provided for @settingsHideNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림에 곡 정보 숨기기'**
  String get settingsHideNotification;

  /// No description provided for @settingsHideNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림 · 잠금화면에 \"음악 재생 중\"만 보이고, 받기 알림에서도 곡 정보를 숨겨요.'**
  String get settingsHideNotificationDesc;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settingsTheme;

  /// No description provided for @settingsFollowMood.
  ///
  /// In ko, this message translates to:
  /// **'곡 분위기 따라가기'**
  String get settingsFollowMood;

  /// No description provided for @settingsFollowMoodDesc.
  ///
  /// In ko, this message translates to:
  /// **'재생 중인 곡의 커버 색으로 강조 색이 바뀌어요.'**
  String get settingsFollowMoodDesc;

  /// No description provided for @settingsThemeColor.
  ///
  /// In ko, this message translates to:
  /// **'테마 색'**
  String get settingsThemeColor;

  /// No description provided for @settingsThemePreview.
  ///
  /// In ko, this message translates to:
  /// **'테마 미리보기'**
  String get settingsThemePreview;

  /// No description provided for @settingsThemePreviewDesc.
  ///
  /// In ko, this message translates to:
  /// **'고른 테마로 앱 화면들을 직접 둘러보고 적용해요'**
  String get settingsThemePreviewDesc;

  /// No description provided for @playerStyleTitle.
  ///
  /// In ko, this message translates to:
  /// **'플레이어 테마'**
  String get playerStyleTitle;

  /// No description provided for @playerStyleSquare.
  ///
  /// In ko, this message translates to:
  /// **'네모'**
  String get playerStyleSquare;

  /// No description provided for @playerStyleFullBleed.
  ///
  /// In ko, this message translates to:
  /// **'꽉 찬 이미지'**
  String get playerStyleFullBleed;

  /// No description provided for @playerStyleArc.
  ///
  /// In ko, this message translates to:
  /// **'호'**
  String get playerStyleArc;

  /// No description provided for @playerSleepTimer.
  ///
  /// In ko, this message translates to:
  /// **'수면 타이머'**
  String get playerSleepTimer;

  /// No description provided for @playerSleepTimerOff.
  ///
  /// In ko, this message translates to:
  /// **'타이머 끄기'**
  String get playerSleepTimerOff;

  /// No description provided for @playerSleepTimerMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 뒤 멈춤'**
  String playerSleepTimerMinutes(int minutes);

  /// No description provided for @playerSleepTimerSet.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 뒤 재생을 멈춰요'**
  String playerSleepTimerSet(int minutes);

  /// No description provided for @playerSleepTimerCleared.
  ///
  /// In ko, this message translates to:
  /// **'수면 타이머를 껐어요'**
  String get playerSleepTimerCleared;

  /// No description provided for @playerEqualizer.
  ///
  /// In ko, this message translates to:
  /// **'이퀄라이저'**
  String get playerEqualizer;

  /// No description provided for @playerEqualizerSoon.
  ///
  /// In ko, this message translates to:
  /// **'이퀄라이저는 준비 중이에요'**
  String get playerEqualizerSoon;

  /// No description provided for @playerLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사'**
  String get playerLyrics;

  /// No description provided for @playerRewind10.
  ///
  /// In ko, this message translates to:
  /// **'10초 뒤로'**
  String get playerRewind10;

  /// No description provided for @playerForward10.
  ///
  /// In ko, this message translates to:
  /// **'10초 앞으로'**
  String get playerForward10;

  /// No description provided for @themePreviewHint.
  ///
  /// In ko, this message translates to:
  /// **'탭을 오가며 확인해 보세요'**
  String get themePreviewHint;

  /// No description provided for @themePreviewApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get themePreviewApply;

  /// No description provided for @settingsAbout.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get settingsVersion;

  /// No description provided for @comingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중'**
  String get comingSoon;

  /// No description provided for @playerNowPlaying.
  ///
  /// In ko, this message translates to:
  /// **'지금 재생 중'**
  String get playerNowPlaying;

  /// No description provided for @playerQueue.
  ///
  /// In ko, this message translates to:
  /// **'재생 대기열'**
  String get playerQueue;

  /// No description provided for @outputSpeaker.
  ///
  /// In ko, this message translates to:
  /// **'기기 스피커'**
  String get outputSpeaker;

  /// No description provided for @outputWired.
  ///
  /// In ko, this message translates to:
  /// **'유선 이어폰'**
  String get outputWired;

  /// No description provided for @outputBluetooth.
  ///
  /// In ko, this message translates to:
  /// **'블루투스'**
  String get outputBluetooth;

  /// No description provided for @outputUsb.
  ///
  /// In ko, this message translates to:
  /// **'USB 오디오'**
  String get outputUsb;

  /// No description provided for @outputOther.
  ///
  /// In ko, this message translates to:
  /// **'외부 출력'**
  String get outputOther;

  /// No description provided for @queueShuffle.
  ///
  /// In ko, this message translates to:
  /// **'다음 곡 섞기'**
  String get queueShuffle;

  /// No description provided for @queueClear.
  ///
  /// In ko, this message translates to:
  /// **'대기열 비우기'**
  String get queueClear;

  /// No description provided for @queueCleared.
  ///
  /// In ko, this message translates to:
  /// **'대기열을 비웠어요'**
  String get queueCleared;

  /// No description provided for @queueClearTitle.
  ///
  /// In ko, this message translates to:
  /// **'대기열을 비울까요?'**
  String get queueClearTitle;

  /// No description provided for @queueClearBody.
  ///
  /// In ko, this message translates to:
  /// **'재생 중인 곡도 멈추고 대기열에서 모두 사라져요. 보관함의 곡은 그대로 남아요.'**
  String get queueClearBody;

  /// No description provided for @queueClearConfirm.
  ///
  /// In ko, this message translates to:
  /// **'비우기'**
  String get queueClearConfirm;

  /// No description provided for @queueReorderHint.
  ///
  /// In ko, this message translates to:
  /// **'길게 눌러 끌면 순서가 바뀌어요'**
  String get queueReorderHint;

  /// No description provided for @playerRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get playerRepeat;

  /// No description provided for @playerFrom.
  ///
  /// In ko, this message translates to:
  /// **'{source}에서 재생'**
  String playerFrom(String source);

  /// No description provided for @themeViolet.
  ///
  /// In ko, this message translates to:
  /// **'바이올렛'**
  String get themeViolet;

  /// No description provided for @themeCoral.
  ///
  /// In ko, this message translates to:
  /// **'코랄'**
  String get themeCoral;

  /// No description provided for @themeOcean.
  ///
  /// In ko, this message translates to:
  /// **'오션'**
  String get themeOcean;

  /// No description provided for @themeForest.
  ///
  /// In ko, this message translates to:
  /// **'포레스트'**
  String get themeForest;

  /// No description provided for @themeSunset.
  ///
  /// In ko, this message translates to:
  /// **'선셋'**
  String get themeSunset;

  /// No description provided for @themeRose.
  ///
  /// In ko, this message translates to:
  /// **'로즈'**
  String get themeRose;

  /// No description provided for @themeGold.
  ///
  /// In ko, this message translates to:
  /// **'골드'**
  String get themeGold;

  /// No description provided for @themeIce.
  ///
  /// In ko, this message translates to:
  /// **'아이스'**
  String get themeIce;

  /// No description provided for @coverPick.
  ///
  /// In ko, this message translates to:
  /// **'이미지 고르기'**
  String get coverPick;

  /// No description provided for @coverReset.
  ///
  /// In ko, this message translates to:
  /// **'기본 이미지로'**
  String get coverReset;

  /// No description provided for @coverSourceTitle.
  ///
  /// In ko, this message translates to:
  /// **'어디서 가져올까요?'**
  String get coverSourceTitle;

  /// No description provided for @coverSourceDevice.
  ///
  /// In ko, this message translates to:
  /// **'기기에서 고르기'**
  String get coverSourceDevice;

  /// No description provided for @coverSourceWeb.
  ///
  /// In ko, this message translates to:
  /// **'웹에서 가져오기'**
  String get coverSourceWeb;

  /// No description provided for @coverAdjust.
  ///
  /// In ko, this message translates to:
  /// **'위치 조정'**
  String get coverAdjust;

  /// No description provided for @coverWebHint.
  ///
  /// In ko, this message translates to:
  /// **'이미지 주소 또는 검색어'**
  String get coverWebHint;

  /// No description provided for @coverWebHelp.
  ///
  /// In ko, this message translates to:
  /// **'이미지 주소(https://…)를 붙여 넣거나, 검색어로 찾아 고르세요.'**
  String get coverWebHelp;

  /// No description provided for @coverWebUseUrl.
  ///
  /// In ko, this message translates to:
  /// **'이 주소의 이미지 쓰기'**
  String get coverWebUseUrl;

  /// No description provided for @coverWebEmpty.
  ///
  /// In ko, this message translates to:
  /// **'찾은 이미지가 없어요'**
  String get coverWebEmpty;

  /// No description provided for @coverWebFailed.
  ///
  /// In ko, this message translates to:
  /// **'검색하지 못했어요. 잠시 뒤 다시 해 주세요'**
  String get coverWebFailed;

  /// No description provided for @coverEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'이미지 위치'**
  String get coverEditTitle;

  /// No description provided for @coverEditHint.
  ///
  /// In ko, this message translates to:
  /// **'끌어서 옮기고, 두 손가락이나 마우스 휠로 크기를 바꿔요'**
  String get coverEditHint;

  /// No description provided for @coverEditZoomIn.
  ///
  /// In ko, this message translates to:
  /// **'확대'**
  String get coverEditZoomIn;

  /// No description provided for @coverEditZoomOut.
  ///
  /// In ko, this message translates to:
  /// **'축소'**
  String get coverEditZoomOut;

  /// No description provided for @coverEditReset.
  ///
  /// In ko, this message translates to:
  /// **'원래대로'**
  String get coverEditReset;

  /// No description provided for @coverEditApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get coverEditApply;

  /// No description provided for @coverEditLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 불러오지 못했어요'**
  String get coverEditLoadFailed;

  /// No description provided for @settingsAppearance.
  ///
  /// In ko, this message translates to:
  /// **'화면 모드'**
  String get settingsAppearance;

  /// No description provided for @appearanceDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get appearanceDark;

  /// No description provided for @appearanceLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get appearanceLight;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 음악이 없어요'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'기기에 있는 음악을 불러오거나\n검색에서 받아 보세요.'**
  String get libraryEmptyBody;

  /// No description provided for @importing.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get importing;

  /// No description provided for @importAdded.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 불러왔어요'**
  String importAdded(int count);

  /// No description provided for @importNothingNew.
  ///
  /// In ko, this message translates to:
  /// **'새로 추가된 곡이 없어요'**
  String get importNothingNew;

  /// No description provided for @importDenied.
  ///
  /// In ko, this message translates to:
  /// **'음악 파일 권한이 필요해요. 설정에서 허용해 주세요.'**
  String get importDenied;

  /// No description provided for @importFailed.
  ///
  /// In ko, this message translates to:
  /// **'음악을 불러오지 못했어요'**
  String get importFailed;

  /// No description provided for @unknownArtist.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 아티스트'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 앨범'**
  String get unknownAlbum;

  /// No description provided for @librarySources.
  ///
  /// In ko, this message translates to:
  /// **'기기 {device}곡 · 받은 곡 {downloaded}곡'**
  String librarySources(int device, int downloaded);

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @homeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 음악'**
  String get homeSubtitle;

  /// No description provided for @homePeriodWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get homePeriodWeek;

  /// No description provided for @homePeriodMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get homePeriodMonth;

  /// No description provided for @homePeriodAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get homePeriodAll;

  /// No description provided for @homeToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 들은 시간'**
  String get homeToday;

  /// No description provided for @homeTodayMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String homeTodayMinutes(int minutes);

  /// No description provided for @homeTodayHoursMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String homeTodayHoursMinutes(int hours, int minutes);

  /// No description provided for @homeTodayPlays.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {count}곡 재생'**
  String homeTodayPlays(int count);

  /// No description provided for @homeTodayNone.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 아직 듣지 않았어요'**
  String get homeTodayNone;

  /// No description provided for @homeStats.
  ///
  /// In ko, this message translates to:
  /// **'청취 분석'**
  String get homeStats;

  /// No description provided for @homeStatPlays.
  ///
  /// In ko, this message translates to:
  /// **'재생'**
  String get homeStatPlays;

  /// No description provided for @homeStatTracks.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get homeStatTracks;

  /// No description provided for @homeTopArtist.
  ///
  /// In ko, this message translates to:
  /// **'많이 들은 아티스트'**
  String get homeTopArtist;

  /// No description provided for @homeTopTracks.
  ///
  /// In ko, this message translates to:
  /// **'많이 들은 곡'**
  String get homeTopTracks;

  /// No description provided for @homeRecommendations.
  ///
  /// In ko, this message translates to:
  /// **'추천 재생목록'**
  String get homeRecommendations;

  /// No description provided for @homeRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 들은 곡'**
  String get homeRecent;

  /// No description provided for @homeNoPlays.
  ///
  /// In ko, this message translates to:
  /// **'아직 재생 기록이 없어요. 보관함에서 곡을 재생해 보세요.'**
  String get homeNoPlays;

  /// No description provided for @homeNoRecommendations.
  ///
  /// In ko, this message translates to:
  /// **'보관함에 곡이 더 있으면 추천해 드려요.'**
  String get homeNoRecommendations;

  /// No description provided for @homeEmptyLibraryTitle.
  ///
  /// In ko, this message translates to:
  /// **'보관함이 비었어요'**
  String get homeEmptyLibraryTitle;

  /// No description provided for @homeEmptyLibraryBody.
  ///
  /// In ko, this message translates to:
  /// **'기기 음악을 불러오거나 검색에서 받으면\n여기에 많이 들은 곡과 추천이 보여요.'**
  String get homeEmptyLibraryBody;

  /// No description provided for @homeGoLibrary.
  ///
  /// In ko, this message translates to:
  /// **'보관함으로'**
  String get homeGoLibrary;

  /// No description provided for @homeTopTracksGo.
  ///
  /// In ko, this message translates to:
  /// **'TOP 100 보러가기'**
  String get homeTopTracksGo;

  /// No description provided for @homeRecentList.
  ///
  /// In ko, this message translates to:
  /// **'최근 재생'**
  String get homeRecentList;

  /// No description provided for @homeAllSince.
  ///
  /// In ko, this message translates to:
  /// **'{date}부터의 기록'**
  String homeAllSince(String date);

  /// No description provided for @homeRecRediscover.
  ///
  /// In ko, this message translates to:
  /// **'오랜만에 다시 듣기'**
  String get homeRecRediscover;

  /// No description provided for @homeChipTracks.
  ///
  /// In ko, this message translates to:
  /// **'곡'**
  String get homeChipTracks;

  /// No description provided for @homeChipArtists.
  ///
  /// In ko, this message translates to:
  /// **'아티스트'**
  String get homeChipArtists;

  /// No description provided for @homeChipGenres.
  ///
  /// In ko, this message translates to:
  /// **'장르'**
  String get homeChipGenres;

  /// No description provided for @homeMonthPrev.
  ///
  /// In ko, this message translates to:
  /// **'이전 달'**
  String get homeMonthPrev;

  /// No description provided for @homeMonthNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 달'**
  String get homeMonthNext;

  /// No description provided for @homeHistory.
  ///
  /// In ko, this message translates to:
  /// **'재생 기록'**
  String get homeHistory;

  /// No description provided for @homeMetricPlays.
  ///
  /// In ko, this message translates to:
  /// **'재생 횟수'**
  String get homeMetricPlays;

  /// No description provided for @homeMetricTime.
  ///
  /// In ko, this message translates to:
  /// **'재생 시간'**
  String get homeMetricTime;

  /// No description provided for @homePickMonth.
  ///
  /// In ko, this message translates to:
  /// **'달 고르기'**
  String get homePickMonth;

  /// No description provided for @homeMonthLabel.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String homeMonthLabel(int year, int month);

  /// No description provided for @homeYearLabel.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String homeYearLabel(int year);

  /// No description provided for @homeMonthShort.
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String homeMonthShort(int month);

  /// No description provided for @homeAllDays.
  ///
  /// In ko, this message translates to:
  /// **'들은 날'**
  String get homeAllDays;

  /// No description provided for @homeAllDaysValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String homeAllDaysValue(int count);

  /// No description provided for @homeAllTime.
  ///
  /// In ko, this message translates to:
  /// **'총 재생 시간'**
  String get homeAllTime;

  /// No description provided for @homeAllPlays.
  ///
  /// In ko, this message translates to:
  /// **'총 재생'**
  String get homeAllPlays;

  /// No description provided for @homeAllTracks.
  ///
  /// In ko, this message translates to:
  /// **'들은 곡'**
  String get homeAllTracks;

  /// No description provided for @homeChartNone.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에는 들은 기록이 없어요.'**
  String get homeChartNone;

  /// No description provided for @homeTopAlbum.
  ///
  /// In ko, this message translates to:
  /// **'많이 들은 앨범'**
  String get homeTopAlbum;

  /// No description provided for @homeTopTracksMore.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get homeTopTracksMore;

  /// No description provided for @homeTopTracksTitle.
  ///
  /// In ko, this message translates to:
  /// **'많이 들은 곡 TOP 100'**
  String get homeTopTracksTitle;

  /// No description provided for @homeRecArtist.
  ///
  /// In ko, this message translates to:
  /// **'{artist} 믹스'**
  String homeRecArtist(String artist);

  /// No description provided for @homeRecGenre.
  ///
  /// In ko, this message translates to:
  /// **'{genre} 모음'**
  String homeRecGenre(String genre);

  /// No description provided for @homeRecUnheard.
  ///
  /// In ko, this message translates to:
  /// **'아직 안 들어 본 곡'**
  String get homeRecUnheard;

  /// No description provided for @homeRecNewest.
  ///
  /// In ko, this message translates to:
  /// **'새로 담은 곡'**
  String get homeRecNewest;

  /// No description provided for @playCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String playCount(int count);

  /// No description provided for @searchHintWeb.
  ///
  /// In ko, this message translates to:
  /// **'웹 음원 검색어나 URL'**
  String get searchHintWeb;

  /// No description provided for @searchSourceTooltip.
  ///
  /// In ko, this message translates to:
  /// **'검색 대상'**
  String get searchSourceTooltip;

  /// No description provided for @sourceYoutube.
  ///
  /// In ko, this message translates to:
  /// **'유튜브'**
  String get sourceYoutube;

  /// No description provided for @sourceWeb.
  ///
  /// In ko, this message translates to:
  /// **'웹'**
  String get sourceWeb;

  /// No description provided for @searchHitMenuDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 보기'**
  String get searchHitMenuDetail;

  /// No description provided for @searchPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기'**
  String get searchPreview;

  /// No description provided for @searchPreviewStop.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기 멈추기'**
  String get searchPreviewStop;

  /// No description provided for @searchPreviewLoading.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기 준비 중'**
  String get searchPreviewLoading;

  /// No description provided for @searchPreviewFailed.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기를 시작하지 못했어요.'**
  String get searchPreviewFailed;

  /// No description provided for @searchPreviewUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 미리 듣기를 쓸 수 없어요.'**
  String get searchPreviewUnavailable;

  /// No description provided for @mediaDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'상세 정보'**
  String get mediaDetailTitle;

  /// No description provided for @mediaDetailWatchYoutube.
  ///
  /// In ko, this message translates to:
  /// **'유튜브에서 보기'**
  String get mediaDetailWatchYoutube;

  /// No description provided for @mediaDetailOpenOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원본 페이지 열기'**
  String get mediaDetailOpenOriginal;

  /// No description provided for @mediaDetailChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get mediaDetailChannel;

  /// No description provided for @mediaDetailOpenChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널 보기'**
  String get mediaDetailOpenChannel;

  /// No description provided for @mediaDetailDuration.
  ///
  /// In ko, this message translates to:
  /// **'길이'**
  String get mediaDetailDuration;

  /// No description provided for @mediaDetailViews.
  ///
  /// In ko, this message translates to:
  /// **'조회수'**
  String get mediaDetailViews;

  /// No description provided for @mediaDetailUploaded.
  ///
  /// In ko, this message translates to:
  /// **'올린 날'**
  String get mediaDetailUploaded;

  /// No description provided for @mediaDetailCategory.
  ///
  /// In ko, this message translates to:
  /// **'분류'**
  String get mediaDetailCategory;

  /// No description provided for @mediaDetailDescription.
  ///
  /// In ko, this message translates to:
  /// **'설명'**
  String get mediaDetailDescription;

  /// No description provided for @mediaDetailMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get mediaDetailMore;

  /// No description provided for @mediaDetailLikes.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get mediaDetailLikes;

  /// No description provided for @mediaDetailSubscribers.
  ///
  /// In ko, this message translates to:
  /// **'구독자 {count}명'**
  String mediaDetailSubscribers(String count);

  /// No description provided for @mediaDetailCollaborators.
  ///
  /// In ko, this message translates to:
  /// **'공동 작업자'**
  String get mediaDetailCollaborators;

  /// No description provided for @mediaDetailPlayInApp.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 재생'**
  String get mediaDetailPlayInApp;

  /// No description provided for @mediaDetailEmbedBlocked.
  ///
  /// In ko, this message translates to:
  /// **'이 영상은 앱 안에서 재생할 수 없어요. 아래 버튼으로 유튜브에서 열어 보세요.'**
  String get mediaDetailEmbedBlocked;

  /// No description provided for @mediaDetailLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get mediaDetailLess;

  /// No description provided for @mediaDetailOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'열 수 있는 앱이 없어요.'**
  String get mediaDetailOpenFailed;

  /// No description provided for @mediaDetailViewCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String mediaDetailViewCount(String count);

  /// No description provided for @searchSortTooltip.
  ///
  /// In ko, this message translates to:
  /// **'정렬'**
  String get searchSortTooltip;

  /// No description provided for @searchSortRelevance.
  ///
  /// In ko, this message translates to:
  /// **'관련도순'**
  String get searchSortRelevance;

  /// No description provided for @searchSortPopular.
  ///
  /// In ko, this message translates to:
  /// **'인기순'**
  String get searchSortPopular;

  /// No description provided for @searchSortNewest.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get searchSortNewest;

  /// No description provided for @searchSortShortest.
  ///
  /// In ko, this message translates to:
  /// **'짧은 순'**
  String get searchSortShortest;

  /// No description provided for @searchSortLongest.
  ///
  /// In ko, this message translates to:
  /// **'긴 순'**
  String get searchSortLongest;

  /// No description provided for @searchSortTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목순'**
  String get searchSortTitle;

  /// No description provided for @videoCategory.
  ///
  /// In ko, this message translates to:
  /// **'{name, select, FilmAnimation{영화/애니메이션} Autos{자동차} Music{음악} Pets{동물} Sports{스포츠} Travel{여행} Gaming{게임} People{인물/블로그} Comedy{코미디} Entertainment{엔터테인먼트} News{뉴스/정치} Howto{노하우/스타일} Education{교육} Science{과학/기술} Nonprofits{비영리/사회운동} other{{name}}}'**
  String videoCategory(String name);

  /// No description provided for @downloadsExpand.
  ///
  /// In ko, this message translates to:
  /// **'대기 목록 펼치기'**
  String get downloadsExpand;

  /// No description provided for @downloadsCollapse.
  ///
  /// In ko, this message translates to:
  /// **'대기 목록 접기'**
  String get downloadsCollapse;

  /// No description provided for @downloadDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'받기 정보'**
  String get downloadDialogTitle;

  /// No description provided for @downloadFieldCover.
  ///
  /// In ko, this message translates to:
  /// **'커버'**
  String get downloadFieldCover;

  /// No description provided for @downloadCoverChange.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get downloadCoverChange;

  /// No description provided for @downloadCoverDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본으로'**
  String get downloadCoverDefault;

  /// No description provided for @downloadCancelTitle.
  ///
  /// In ko, this message translates to:
  /// **'받기 취소'**
  String get downloadCancelTitle;

  /// No description provided for @downloadCancelBody.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 받기를 취소할까요? 지금까지 받은 부분은 사라져요.'**
  String downloadCancelBody(String title);

  /// No description provided for @downloadCancelKeep.
  ///
  /// In ko, this message translates to:
  /// **'계속 받기'**
  String get downloadCancelKeep;

  /// No description provided for @downloadCancelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'취소하기'**
  String get downloadCancelConfirm;

  /// No description provided for @downloadsCancelAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 취소'**
  String get downloadsCancelAll;

  /// No description provided for @downloadsCancelAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'받기 모두 취소'**
  String get downloadsCancelAllTitle;

  /// No description provided for @downloadsCancelAllBody.
  ///
  /// In ko, this message translates to:
  /// **'받는 중이거나 기다리는 {count}곡의 받기를 모두 취소할까요? 지금까지 받은 부분은 사라져요.'**
  String downloadsCancelAllBody(int count);

  /// No description provided for @downloadsOverall.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{total}곡'**
  String downloadsOverall(int done, int total);

  /// No description provided for @playlistDownloadsTitle.
  ///
  /// In ko, this message translates to:
  /// **'받는 중 {count}곡'**
  String playlistDownloadsTitle(int count);

  /// No description provided for @downloadFieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get downloadFieldTitle;

  /// No description provided for @downloadFieldArtist.
  ///
  /// In ko, this message translates to:
  /// **'아티스트'**
  String get downloadFieldArtist;

  /// No description provided for @downloadFieldGenre.
  ///
  /// In ko, this message translates to:
  /// **'장르'**
  String get downloadFieldGenre;

  /// No description provided for @downloadFieldSavePath.
  ///
  /// In ko, this message translates to:
  /// **'저장 위치'**
  String get downloadFieldSavePath;

  /// No description provided for @downloadGenreExisting.
  ///
  /// In ko, this message translates to:
  /// **'기존 장르에서 고르기'**
  String get downloadGenreExisting;

  /// No description provided for @downloadPickFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 고르기'**
  String get downloadPickFolder;

  /// No description provided for @downloadPlaylistsLabel.
  ///
  /// In ko, this message translates to:
  /// **'담을 재생목록'**
  String get downloadPlaylistsLabel;

  /// No description provided for @downloadPlaylistsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 재생목록이 없어요. 아래에서 새로 만들 수 있어요.'**
  String get downloadPlaylistsEmpty;

  /// No description provided for @downloadNewPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'새 재생목록'**
  String get downloadNewPlaylist;

  /// No description provided for @downloadNewPlaylistHint.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력하고 +'**
  String get downloadNewPlaylistHint;

  /// No description provided for @downloadQueued.
  ///
  /// In ko, this message translates to:
  /// **'대기열에 넣었어요'**
  String get downloadQueued;

  /// No description provided for @homeTopGenre.
  ///
  /// In ko, this message translates to:
  /// **'많이 들은 장르'**
  String get homeTopGenre;

  /// No description provided for @playlistsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 재생목록이 없어요. 위의 +로 만들어 보세요.'**
  String get playlistsEmpty;

  /// No description provided for @playlistNewTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 재생목록'**
  String get playlistNewTitle;

  /// No description provided for @playlistNewHint.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 이름'**
  String get playlistNewHint;

  /// No description provided for @playlistCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get playlistCreate;

  /// No description provided for @decorateTitle.
  ///
  /// In ko, this message translates to:
  /// **'꾸미기'**
  String get decorateTitle;

  /// No description provided for @decorateImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get decorateImage;

  /// No description provided for @decorateColor.
  ///
  /// In ko, this message translates to:
  /// **'색'**
  String get decorateColor;

  /// No description provided for @decorateAlbumTooltip.
  ///
  /// In ko, this message translates to:
  /// **'앨범 꾸미기'**
  String get decorateAlbumTooltip;

  /// No description provided for @decorateArtistTooltip.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 꾸미기'**
  String get decorateArtistTooltip;

  /// No description provided for @playlistMenuDecorate.
  ///
  /// In ko, this message translates to:
  /// **'꾸미기'**
  String get playlistMenuDecorate;

  /// No description provided for @trackMenuDecorate.
  ///
  /// In ko, this message translates to:
  /// **'꾸미기'**
  String get trackMenuDecorate;

  /// No description provided for @albumRenameTooltip.
  ///
  /// In ko, this message translates to:
  /// **'앨범 이름 바꾸기'**
  String get albumRenameTooltip;

  /// No description provided for @albumRenameTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범 이름 바꾸기'**
  String get albumRenameTitle;

  /// No description provided for @albumRenameHint.
  ///
  /// In ko, this message translates to:
  /// **'앨범 이름'**
  String get albumRenameHint;

  /// No description provided for @albumRenameSave.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get albumRenameSave;

  /// No description provided for @albumRenameDone.
  ///
  /// In ko, this message translates to:
  /// **'앨범 이름을 바꿨어요'**
  String get albumRenameDone;

  /// No description provided for @artistNotFound.
  ///
  /// In ko, this message translates to:
  /// **'아티스트를 찾을 수 없어요'**
  String get artistNotFound;

  /// No description provided for @playlistMenuColor.
  ///
  /// In ko, this message translates to:
  /// **'카드 색'**
  String get playlistMenuColor;

  /// No description provided for @playlistColorAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get playlistColorAuto;

  /// No description provided for @colorCustom.
  ///
  /// In ko, this message translates to:
  /// **'색상 직접 고르기'**
  String get colorCustom;

  /// No description provided for @colorOption.
  ///
  /// In ko, this message translates to:
  /// **'색 {n}'**
  String colorOption(int n);

  /// No description provided for @playlistSummaryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'비어 있어요'**
  String get playlistSummaryEmpty;

  /// No description provided for @downloadColorSaveForGenre.
  ///
  /// In ko, this message translates to:
  /// **'\'{genre}\' 장르의 기본 색으로 저장'**
  String downloadColorSaveForGenre(String genre);

  /// No description provided for @downloadPlaylistsNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get downloadPlaylistsNone;

  /// No description provided for @downloadPlaylistsSelected.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String downloadPlaylistsSelected(int count);

  /// No description provided for @downloadPlaylistsPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 선택'**
  String get downloadPlaylistsPickTitle;

  /// No description provided for @downloadPlaylistsDone.
  ///
  /// In ko, this message translates to:
  /// **'선택 완료'**
  String get downloadPlaylistsDone;

  /// No description provided for @trackMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 메뉴'**
  String get trackMenuTitle;

  /// No description provided for @trackMenuPlayNext.
  ///
  /// In ko, this message translates to:
  /// **'다음에 재생'**
  String get trackMenuPlayNext;

  /// No description provided for @trackMenuAddToQueue.
  ///
  /// In ko, this message translates to:
  /// **'대기열에 추가'**
  String get trackMenuAddToQueue;

  /// No description provided for @trackMenuAddToPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록에 추가'**
  String get trackMenuAddToPlaylist;

  /// No description provided for @trackMenuEditInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보 편집'**
  String get trackMenuEditInfo;

  /// No description provided for @trackMenuDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get trackMenuDelete;

  /// No description provided for @trackMenuRemoveFromPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록에서 빼기'**
  String get trackMenuRemoveFromPlaylist;

  /// No description provided for @trackMenuDeleteFile.
  ///
  /// In ko, this message translates to:
  /// **'파일 삭제'**
  String get trackMenuDeleteFile;

  /// No description provided for @trackRemovedFromPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생목록에서 뺐어요'**
  String get trackRemovedFromPlaylist;

  /// No description provided for @trackDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 지우지 못했어요. 권한을 확인한 뒤 다시 시도해 주세요.'**
  String get trackDeleteFailed;

  /// No description provided for @trackMenuPlayNextDone.
  ///
  /// In ko, this message translates to:
  /// **'다음에 재생해요'**
  String get trackMenuPlayNextDone;

  /// No description provided for @trackMenuAddedToQueue.
  ///
  /// In ko, this message translates to:
  /// **'대기열에 추가했어요'**
  String get trackMenuAddedToQueue;

  /// No description provided for @trackMenuNoPlaylists.
  ///
  /// In ko, this message translates to:
  /// **'재생목록이 없어요. 재생목록 탭에서 먼저 만들어 주세요.'**
  String get trackMenuNoPlaylists;

  /// No description provided for @trackMenuAddedToPlaylists.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 재생목록에 담았어요'**
  String trackMenuAddedToPlaylists(int count);

  /// No description provided for @trackEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보 편집'**
  String get trackEditTitle;

  /// No description provided for @trackEditName.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get trackEditName;

  /// No description provided for @trackEditArtist.
  ///
  /// In ko, this message translates to:
  /// **'아티스트'**
  String get trackEditArtist;

  /// No description provided for @trackEditAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get trackEditAlbum;

  /// No description provided for @trackEditGenre.
  ///
  /// In ko, this message translates to:
  /// **'장르'**
  String get trackEditGenre;

  /// No description provided for @trackEditSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get trackEditSave;

  /// No description provided for @trackEditSaved.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보를 고쳤어요'**
  String get trackEditSaved;

  /// No description provided for @trackDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 삭제'**
  String get trackDeleteTitle;

  /// No description provided for @trackDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\"의 음악 파일을 기기에서 지울까요? 보관함과 재생목록에서도 빠지고, 되돌릴 수 없어요.'**
  String trackDeleteBody(String title);

  /// No description provided for @trackDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get trackDeleteConfirm;

  /// No description provided for @trackDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제했어요'**
  String get trackDeleted;

  /// No description provided for @lyricsMenuEdit.
  ///
  /// In ko, this message translates to:
  /// **'가사 편집'**
  String get lyricsMenuEdit;

  /// No description provided for @lyricsEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'가사 설정'**
  String get lyricsEditTitle;

  /// No description provided for @lyricsEditLabel.
  ///
  /// In ko, this message translates to:
  /// **'가사'**
  String get lyricsEditLabel;

  /// No description provided for @lyricsEditHint.
  ///
  /// In ko, this message translates to:
  /// **'가사를 붙여넣거나 입력하세요. [01:02.30]처럼 시간이 붙은 글이나 .lrc · .txt 파일을 불러오면 싱크 가사가 돼요. 비워서 저장하면 가사를 지워요.'**
  String get lyricsEditHint;

  /// No description provided for @lyricsLoadFile.
  ///
  /// In ko, this message translates to:
  /// **'파일에서 불러오기'**
  String get lyricsLoadFile;

  /// No description provided for @lyricsWebSearch.
  ///
  /// In ko, this message translates to:
  /// **'웹에서 가져오기'**
  String get lyricsWebSearch;

  /// No description provided for @lyricsWebTitle.
  ///
  /// In ko, this message translates to:
  /// **'가사 검색'**
  String get lyricsWebTitle;

  /// No description provided for @lyricsWebHint.
  ///
  /// In ko, this message translates to:
  /// **'가사를 길게 눌러 끌어서 고른 뒤 \'담기\'를 누르세요. 여러 번 담은 뒤 \'가져오기\'로 한꺼번에 넣어요.'**
  String get lyricsWebHint;

  /// No description provided for @lyricsWebImport.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get lyricsWebImport;

  /// No description provided for @lyricsWebNothingSelected.
  ///
  /// In ko, this message translates to:
  /// **'고른 글이 없어요. 가사를 끌어서 먼저 골라 주세요.'**
  String get lyricsWebNothingSelected;

  /// No description provided for @lyricsWebAdd.
  ///
  /// In ko, this message translates to:
  /// **'담기'**
  String get lyricsWebAdd;

  /// No description provided for @lyricsWebScratchTitle.
  ///
  /// In ko, this message translates to:
  /// **'모은 글'**
  String get lyricsWebScratchTitle;

  /// No description provided for @lyricsWebScratchHint.
  ///
  /// In ko, this message translates to:
  /// **'담은 글이 여기 쌓여요. 직접 고치거나 지울 수 있어요.'**
  String get lyricsWebScratchHint;

  /// No description provided for @lyricsWebClear.
  ///
  /// In ko, this message translates to:
  /// **'모두 비우기'**
  String get lyricsWebClear;

  /// No description provided for @lyricsWebScratchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'모은 글이 없어요. 가사를 골라 \'담기\'를 먼저 눌러 주세요.'**
  String get lyricsWebScratchEmpty;

  /// No description provided for @lyricsSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get lyricsSave;

  /// No description provided for @lyricsSaved.
  ///
  /// In ko, this message translates to:
  /// **'가사를 저장했어요'**
  String get lyricsSaved;

  /// No description provided for @lyricsCleared.
  ///
  /// In ko, this message translates to:
  /// **'가사를 지웠어요'**
  String get lyricsCleared;

  /// No description provided for @lyricsSyncTitle.
  ///
  /// In ko, this message translates to:
  /// **'싱크 맞추기'**
  String get lyricsSyncTitle;

  /// No description provided for @lyricsSyncSetting.
  ///
  /// In ko, this message translates to:
  /// **'싱크 설정'**
  String get lyricsSyncSetting;

  /// No description provided for @lyricsSyncHint.
  ///
  /// In ko, this message translates to:
  /// **'노래에 맞춰 \'지금\'을 눌러 줄마다 시간을 찍어요. 찍은 줄을 누르면 시간을 다듬을 수 있어요.'**
  String get lyricsSyncHint;

  /// No description provided for @lyricsSyncNow.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get lyricsSyncNow;

  /// No description provided for @lyricsSyncUndo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get lyricsSyncUndo;

  /// No description provided for @lyricsSyncSave.
  ///
  /// In ko, this message translates to:
  /// **'싱크 저장'**
  String get lyricsSyncSave;

  /// No description provided for @lyricsSyncReplay.
  ///
  /// In ko, this message translates to:
  /// **'이 줄부터 다시 듣기'**
  String get lyricsSyncReplay;

  /// No description provided for @lyricsSyncReset.
  ///
  /// In ko, this message translates to:
  /// **'이 싱크로'**
  String get lyricsSyncReset;

  /// No description provided for @lyricsSyncGroup.
  ///
  /// In ko, this message translates to:
  /// **'한 번에 묶을 줄 수'**
  String get lyricsSyncGroup;

  /// No description provided for @lyricsSyncGroupLines.
  ///
  /// In ko, this message translates to:
  /// **'{n}줄'**
  String lyricsSyncGroupLines(int n);

  /// No description provided for @lyricsSyncNeedAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 줄에 시간을 찍으면 저장할 수 있어요.'**
  String get lyricsSyncNeedAll;

  /// No description provided for @lyricsSyncEmpty.
  ///
  /// In ko, this message translates to:
  /// **'싱크를 맞출 가사가 없어요. 먼저 가사를 입력해 주세요.'**
  String get lyricsSyncEmpty;

  /// No description provided for @lyricsSyncPlay.
  ///
  /// In ko, this message translates to:
  /// **'재생'**
  String get lyricsSyncPlay;

  /// No description provided for @lyricsSyncPause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get lyricsSyncPause;

  /// No description provided for @lyricsSyncProgress.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{total}줄'**
  String lyricsSyncProgress(int done, int total);

  /// No description provided for @lyricsImportExistsTitle.
  ///
  /// In ko, this message translates to:
  /// **'가사가 이미 있어요'**
  String get lyricsImportExistsTitle;

  /// No description provided for @lyricsImportExistsBody.
  ///
  /// In ko, this message translates to:
  /// **'불러온 가사를 어떻게 넣을까요?'**
  String get lyricsImportExistsBody;

  /// No description provided for @lyricsImportReplace.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get lyricsImportReplace;

  /// No description provided for @lyricsImportAppend.
  ///
  /// In ko, this message translates to:
  /// **'뒤에 붙이기'**
  String get lyricsImportAppend;

  /// No description provided for @lyricsSyncGroupSetupBody.
  ///
  /// In ko, this message translates to:
  /// **'한 번에 시간을 찍을 줄 수를 골라 주세요. 나중에 위쪽 메뉴에서 바꿀 수 있어요.'**
  String get lyricsSyncGroupSetupBody;

  /// No description provided for @lyricsSyncLeaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'싱크가 저장되지 않아요'**
  String get lyricsSyncLeaveTitle;

  /// No description provided for @lyricsSyncLeaveBody.
  ///
  /// In ko, this message translates to:
  /// **'아직 모든 줄에 시간을 찍지 않았어요. 지금 나가면 찍은 시간이 사라져요. 지금까지 찍은 싱크를 저장하고 나갈까요?'**
  String get lyricsSyncLeaveBody;

  /// No description provided for @lyricsSyncLeaveSave.
  ///
  /// In ko, this message translates to:
  /// **'저장 후 나가기'**
  String get lyricsSyncLeaveSave;

  /// No description provided for @lyricsSyncLeaveDiscard.
  ///
  /// In ko, this message translates to:
  /// **'저장 안 하고 나가기'**
  String get lyricsSyncLeaveDiscard;

  /// No description provided for @lyricsSyncLeaveStay.
  ///
  /// In ko, this message translates to:
  /// **'계속 맞추기'**
  String get lyricsSyncLeaveStay;

  /// No description provided for @lyricsSyncGroupOk.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get lyricsSyncGroupOk;

  /// No description provided for @lyricsSyncDefaultLines.
  ///
  /// In ko, this message translates to:
  /// **'기본 줄 수 변경'**
  String get lyricsSyncDefaultLines;

  /// No description provided for @lyricsSyncResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'묶음이 사라져요'**
  String get lyricsSyncResetTitle;

  /// No description provided for @lyricsSyncResetBody.
  ///
  /// In ko, this message translates to:
  /// **'기본 줄 수를 바꾸면 직접 묶은 줄과 찍은 시간이 모두 사라지고, 고른 줄 수로 다시 나뉘어요. 계속할까요?'**
  String get lyricsSyncResetBody;

  /// No description provided for @lyricsSyncResetConfirm.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get lyricsSyncResetConfirm;

  /// No description provided for @lyricsSyncGroupEdit.
  ///
  /// In ko, this message translates to:
  /// **'줄 묶기'**
  String get lyricsSyncGroupEdit;

  /// No description provided for @lyricsSyncGroupDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get lyricsSyncGroupDone;

  /// No description provided for @lyricsSyncGroupPanelHint.
  ///
  /// In ko, this message translates to:
  /// **'묶을 마지막 줄을 누르거나 끌어서 고르세요. 이 싱크의 시간은 다시 찍어야 해요.'**
  String get lyricsSyncGroupPanelHint;

  /// No description provided for @playerShowLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사 보기'**
  String get playerShowLyrics;

  /// No description provided for @playerShowCover.
  ///
  /// In ko, this message translates to:
  /// **'커버 보기'**
  String get playerShowCover;

  /// No description provided for @lyricsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'가사가 없어요'**
  String get lyricsEmpty;

  /// No description provided for @lyricsEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'곡 옆에 같은 이름의 .lrc 파일을 두거나, 직접 넣을 수 있어요.'**
  String get lyricsEmptyHint;

  /// No description provided for @playlistFavorites.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get playlistFavorites;

  /// No description provided for @playlistMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 메뉴'**
  String get playlistMenuTooltip;

  /// No description provided for @playlistFeaturedPreview.
  ///
  /// In ko, this message translates to:
  /// **'대표곡 미리 듣기'**
  String get playlistFeaturedPreview;

  /// No description provided for @playlistMenuPlayAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 재생'**
  String get playlistMenuPlayAll;

  /// No description provided for @playlistMenuShuffle.
  ///
  /// In ko, this message translates to:
  /// **'셔플 재생'**
  String get playlistMenuShuffle;

  /// No description provided for @playlistMenuRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get playlistMenuRename;

  /// No description provided for @playlistMenuDelete.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 삭제'**
  String get playlistMenuDelete;

  /// No description provided for @playlistPlayEmpty.
  ///
  /// In ko, this message translates to:
  /// **'재생할 곡이 없어요'**
  String get playlistPlayEmpty;

  /// No description provided for @playlistRenameTitle.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get playlistRenameTitle;

  /// No description provided for @playlistRenameSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get playlistRenameSave;

  /// No description provided for @playlistDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록을 지울까요?'**
  String get playlistDeleteTitle;

  /// No description provided for @playlistDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’을(를) 지워요. 담긴 곡은 보관함에 그대로 남아요.'**
  String playlistDeleteBody(String name);

  /// No description provided for @playlistDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get playlistDeleteConfirm;

  /// No description provided for @playlistDeleted.
  ///
  /// In ko, this message translates to:
  /// **'재생목록을 지웠어요'**
  String get playlistDeleted;

  /// No description provided for @playlistNewImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 고르기'**
  String get playlistNewImage;

  /// No description provided for @playlistNewImageChange.
  ///
  /// In ko, this message translates to:
  /// **'이미지 바꾸기'**
  String get playlistNewImageChange;

  /// No description provided for @playlistPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 선택'**
  String get playlistPickTitle;

  /// No description provided for @playlistPickHint.
  ///
  /// In ko, this message translates to:
  /// **'담을 재생목록을 골라 주세요'**
  String get playlistPickHint;

  /// No description provided for @playlistPickDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get playlistPickDone;

  /// No description provided for @playlistPickAlready.
  ///
  /// In ko, this message translates to:
  /// **'이미 담겼어요'**
  String get playlistPickAlready;

  /// No description provided for @playlistDetailEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 담긴 곡이 없어요. 곡 메뉴의 ‘재생목록에 추가’로 담아 보세요.'**
  String get playlistDetailEmpty;

  /// No description provided for @playlistNotFound.
  ///
  /// In ko, this message translates to:
  /// **'재생목록을 찾을 수 없어요'**
  String get playlistNotFound;

  /// No description provided for @albumNotFound.
  ///
  /// In ko, this message translates to:
  /// **'앨범을 찾을 수 없어요'**
  String get albumNotFound;

  /// No description provided for @playerQueueEmpty.
  ///
  /// In ko, this message translates to:
  /// **'대기열이 비어 있어요'**
  String get playerQueueEmpty;

  /// No description provided for @trackMenuFavorite.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get trackMenuFavorite;

  /// No description provided for @trackMenuUnfavorite.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 취소'**
  String get trackMenuUnfavorite;

  /// No description provided for @trackFavoriteOn.
  ///
  /// In ko, this message translates to:
  /// **'좋아요에 담았어요'**
  String get trackFavoriteOn;

  /// No description provided for @trackFavoriteOff.
  ///
  /// In ko, this message translates to:
  /// **'좋아요를 취소했어요'**
  String get trackFavoriteOff;

  /// No description provided for @playlistImportHint.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 이름이나 주소'**
  String get playlistImportHint;

  /// No description provided for @playlistImportEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록을 찾아 보세요'**
  String get playlistImportEmptyTitle;

  /// No description provided for @playlistImportEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'이름으로 찾거나 주소를 붙여 넣으면, 곡 목록에서 받을 곡을 고를 수 있어요.'**
  String get playlistImportEmptyBody;

  /// No description provided for @playlistImportNoResultsTitle.
  ///
  /// In ko, this message translates to:
  /// **'찾은 재생목록이 없어요'**
  String get playlistImportNoResultsTitle;

  /// No description provided for @playlistImportNoResultsBody.
  ///
  /// In ko, this message translates to:
  /// **'다른 검색어로 찾아 보세요.'**
  String get playlistImportNoResultsBody;

  /// No description provided for @playlistImportBackToResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과'**
  String get playlistImportBackToResults;

  /// No description provided for @playlistImportResultSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'{channel} · {count}곡'**
  String playlistImportResultSubtitle(String channel, int count);

  /// No description provided for @playlistImportNotPlaylistTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 주소가 아니에요'**
  String get playlistImportNotPlaylistTitle;

  /// No description provided for @playlistImportNotPlaylistBody.
  ///
  /// In ko, this message translates to:
  /// **'곡 하나의 주소예요. 재생목록 주소를 붙여 넣어 주세요.'**
  String get playlistImportNotPlaylistBody;

  /// No description provided for @playlistImportNoTracksTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡이 없어요'**
  String get playlistImportNoTracksTitle;

  /// No description provided for @playlistImportNoTracksBody.
  ///
  /// In ko, this message translates to:
  /// **'이 재생목록에는 받을 수 있는 곡이 없어요.'**
  String get playlistImportNoTracksBody;

  /// No description provided for @playlistImportSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 선택'**
  String get playlistImportSelectAll;

  /// No description provided for @playlistImportClear.
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get playlistImportClear;

  /// No description provided for @playlistImportStart.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡 받기'**
  String playlistImportStart(int count);

  /// No description provided for @playlistImportStarted.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 받기 시작했어요'**
  String playlistImportStarted(int count);

  /// No description provided for @playlistImportStartedSkipped.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 받기 시작했어요 (이미 받은 {skipped}곡은 건너뛰었어요)'**
  String playlistImportStartedSkipped(int count, int skipped);

  /// No description provided for @searchPlaylistPick.
  ///
  /// In ko, this message translates to:
  /// **'골라서 받기'**
  String get searchPlaylistPick;

  /// No description provided for @settingsAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get settingsAccount;

  /// No description provided for @settingsGoogleAccount.
  ///
  /// In ko, this message translates to:
  /// **'구글 계정'**
  String get settingsGoogleAccount;

  /// No description provided for @settingsAccountSignedOutDesc.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 내 유튜브 재생목록을 불러올 수 있어요'**
  String get settingsAccountSignedOutDesc;

  /// No description provided for @settingsAccountSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get settingsAccountSignIn;

  /// No description provided for @settingsAccountSignOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get settingsAccountSignOut;

  /// No description provided for @settingsAccountNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인 설정값({keys})이 이 빌드에 없어서 쓸 수 없어요. docs/google-login-setup.md를 보고 설정해 주세요'**
  String settingsAccountNotConfigured(String keys);

  /// No description provided for @playlistImportSignInPromptTitle.
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인이 필요해요'**
  String get playlistImportSignInPromptTitle;

  /// No description provided for @playlistImportSignInPromptBody.
  ///
  /// In ko, this message translates to:
  /// **'내 유튜브 재생목록을 불러오려면 구글 계정으로 로그인해야 해요. 지금 로그인할까요?'**
  String get playlistImportSignInPromptBody;

  /// No description provided for @playlistImportSignInAllow.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get playlistImportSignInAllow;

  /// No description provided for @settingsAccountUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 구글 로그인을 쓸 수 없어요'**
  String get settingsAccountUnsupported;

  /// No description provided for @settingsAccountFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 못했어요. 다시 시도해 주세요'**
  String get settingsAccountFailed;

  /// No description provided for @playlistImportMine.
  ///
  /// In ko, this message translates to:
  /// **'내 재생목록'**
  String get playlistImportMine;

  /// No description provided for @playlistImportMineTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 유튜브 재생목록'**
  String get playlistImportMineTitle;

  /// No description provided for @playlistImportMineEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록이 없어요'**
  String get playlistImportMineEmptyTitle;

  /// No description provided for @playlistImportMineEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'이 계정에는 만든 재생목록이 없어요.'**
  String get playlistImportMineEmptyBody;

  /// No description provided for @playlistImportLoginTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요해요'**
  String get playlistImportLoginTitle;

  /// No description provided for @playlistImportLoginBody.
  ///
  /// In ko, this message translates to:
  /// **'내 유튜브 재생목록을 불러오려면 구글 계정으로 로그인해 주세요.'**
  String get playlistImportLoginBody;

  /// No description provided for @playlistImportLoginExpiredBody.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 풀렸어요. 다시 로그인해 주세요.'**
  String get playlistImportLoginExpiredBody;

  /// No description provided for @searchPlaylistFind.
  ///
  /// In ko, this message translates to:
  /// **'재생목록으로 찾기'**
  String get searchPlaylistFind;

  /// No description provided for @settingsNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifyDownloadProgress.
  ///
  /// In ko, this message translates to:
  /// **'받기 진행 알림'**
  String get settingsNotifyDownloadProgress;

  /// No description provided for @settingsNotifyDownloadProgressDesc.
  ///
  /// In ko, this message translates to:
  /// **'받는 동안 진행 상황을 알림창에 보여요. 앱이 뒤로 가도 받기가 이어져요.'**
  String get settingsNotifyDownloadProgressDesc;

  /// No description provided for @settingsNotifyDownloadResult.
  ///
  /// In ko, this message translates to:
  /// **'받기 결과 알림'**
  String get settingsNotifyDownloadResult;

  /// No description provided for @settingsNotifyDownloadResultDesc.
  ///
  /// In ko, this message translates to:
  /// **'받기가 끝나거나 실패하면 알려요.'**
  String get settingsNotifyDownloadResultDesc;

  /// No description provided for @settingsNotifyPlayback.
  ///
  /// In ko, this message translates to:
  /// **'재생 알림'**
  String get settingsNotifyPlayback;

  /// No description provided for @settingsNotifyPlaybackDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림창 · 잠금화면에서 재생을 조작해요.'**
  String get settingsNotifyPlaybackDesc;

  /// No description provided for @settingsNotifyPermission.
  ///
  /// In ko, this message translates to:
  /// **'시스템 알림이 꺼져 있어요'**
  String get settingsNotifyPermission;

  /// No description provided for @settingsNotifyPermissionDesc.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 설정에서 Mulo 알림을 켜야 알림이 보여요.'**
  String get settingsNotifyPermissionDesc;

  /// No description provided for @settingsNotifyOpenSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get settingsNotifyOpenSettings;

  /// No description provided for @notifHiddenTitle.
  ///
  /// In ko, this message translates to:
  /// **'음악 재생 중'**
  String get notifHiddenTitle;

  /// No description provided for @notifChannelPlayback.
  ///
  /// In ko, this message translates to:
  /// **'재생'**
  String get notifChannelPlayback;

  /// No description provided for @notifChannelDownloadProgress.
  ///
  /// In ko, this message translates to:
  /// **'받는 중'**
  String get notifChannelDownloadProgress;

  /// No description provided for @notifChannelDownloadDone.
  ///
  /// In ko, this message translates to:
  /// **'받기 완료'**
  String get notifChannelDownloadDone;

  /// No description provided for @notifChannelDownloadFailed.
  ///
  /// In ko, this message translates to:
  /// **'받기 실패'**
  String get notifChannelDownloadFailed;

  /// No description provided for @notifDownloadHiddenTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 받는 중'**
  String get notifDownloadHiddenTitle;

  /// No description provided for @notifDownloadProgressBody.
  ///
  /// In ko, this message translates to:
  /// **'받는 중 · {percent}%'**
  String notifDownloadProgressBody(int percent);

  /// No description provided for @notifDownloadProgressMore.
  ///
  /// In ko, this message translates to:
  /// **'받는 중 · {percent}% · {count}곡 대기'**
  String notifDownloadProgressMore(int percent, int count);

  /// No description provided for @notifDownloadDoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'받기 완료'**
  String get notifDownloadDoneTitle;

  /// No description provided for @notifDownloadDoneHidden.
  ///
  /// In ko, this message translates to:
  /// **'곡이 보관함에 추가됐어요'**
  String get notifDownloadDoneHidden;

  /// No description provided for @notifDownloadFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'받기 실패'**
  String get notifDownloadFailedTitle;

  /// No description provided for @notifDownloadFailedHidden.
  ///
  /// In ko, this message translates to:
  /// **'곡을 받지 못했어요'**
  String get notifDownloadFailedHidden;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
