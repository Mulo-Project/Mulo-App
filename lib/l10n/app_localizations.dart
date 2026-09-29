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

  /// No description provided for @downloadsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'대기열'**
  String get downloadsSubtitle;

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

  /// No description provided for @libraryStorage.
  ///
  /// In ko, this message translates to:
  /// **'{size} 사용 중'**
  String libraryStorage(String size);

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

  /// No description provided for @settingsServerAddress.
  ///
  /// In ko, this message translates to:
  /// **'서버 주소'**
  String get settingsServerAddress;

  /// No description provided for @settingsServerNotSet.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록 안 함'**
  String get settingsServerNotSet;

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

  /// No description provided for @settingsPlayback.
  ///
  /// In ko, this message translates to:
  /// **'재생'**
  String get settingsPlayback;

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

  /// No description provided for @settingsThemeDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get settingsThemeDefault;

  /// No description provided for @settingsThemeAlt.
  ///
  /// In ko, this message translates to:
  /// **'코랄'**
  String get settingsThemeAlt;

  /// No description provided for @settingsDesignPreview.
  ///
  /// In ko, this message translates to:
  /// **'디자인 미리보기'**
  String get settingsDesignPreview;

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
