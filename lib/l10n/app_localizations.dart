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

  /// No description provided for @statusQueued.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get statusQueued;

  /// No description provided for @statusPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get statusPaused;

  /// No description provided for @statusFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get statusFailed;

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

  /// No description provided for @genreBack.
  ///
  /// In ko, this message translates to:
  /// **'장르 목록으로'**
  String get genreBack;

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
  /// **'알림 · 잠금화면에 \"음악 재생 중\"만 보여요.'**
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

  /// No description provided for @playerRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get playerRepeat;

  /// No description provided for @playerLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사'**
  String get playerLyrics;

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

  /// No description provided for @coverTitle.
  ///
  /// In ko, this message translates to:
  /// **'커버 이미지'**
  String get coverTitle;

  /// No description provided for @coverChange.
  ///
  /// In ko, this message translates to:
  /// **'커버 이미지 바꾸기'**
  String get coverChange;

  /// No description provided for @coverPick.
  ///
  /// In ko, this message translates to:
  /// **'사진에서 고르기'**
  String get coverPick;

  /// No description provided for @coverReset.
  ///
  /// In ko, this message translates to:
  /// **'기본 이미지로'**
  String get coverReset;

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

  /// No description provided for @playlistMenuImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 바꾸기'**
  String get playlistMenuImage;

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

  /// No description provided for @playlistColorOption.
  ///
  /// In ko, this message translates to:
  /// **'카드 색 {name}'**
  String playlistColorOption(String name);

  /// No description provided for @playlistColorPrimary.
  ///
  /// In ko, this message translates to:
  /// **'주 색'**
  String get playlistColorPrimary;

  /// No description provided for @playlistColorSecondary.
  ///
  /// In ko, this message translates to:
  /// **'보조 색'**
  String get playlistColorSecondary;

  /// No description provided for @playlistColorTertiary.
  ///
  /// In ko, this message translates to:
  /// **'포인트 색'**
  String get playlistColorTertiary;

  /// No description provided for @playlistSummaryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'비어 있어요'**
  String get playlistSummaryEmpty;

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

  /// No description provided for @trackMenuCover.
  ///
  /// In ko, this message translates to:
  /// **'커버 이미지 설정'**
  String get trackMenuCover;

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

  /// No description provided for @trackMenuLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사 설정'**
  String get trackMenuLyrics;

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
  /// **'가사를 붙여넣거나 입력하세요. [01:23.45] 같은 시간 표시가 있으면 싱크 가사로 저장돼요. 비워서 저장하면 가사를 지워요.'**
  String get lyricsEditHint;

  /// No description provided for @lyricsLoadFile.
  ///
  /// In ko, this message translates to:
  /// **'파일에서 불러오기 (.lrc · .txt)'**
  String get lyricsLoadFile;

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

  /// No description provided for @playlistImagePick.
  ///
  /// In ko, this message translates to:
  /// **'사진에서 고르기'**
  String get playlistImagePick;

  /// No description provided for @playlistImageReset.
  ///
  /// In ko, this message translates to:
  /// **'기본 이미지로'**
  String get playlistImageReset;

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
