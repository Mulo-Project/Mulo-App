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

  /// No description provided for @playerFloatExpand.
  ///
  /// In ko, this message translates to:
  /// **'미니 플레이어로 돌아가기'**
  String get playerFloatExpand;

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
  /// **'링크를 붙여 넣거나 검색어를 입력하세요.\n왼쪽 아이콘으로 찾을 사이트를 고를 수 있어요.'**
  String get searchEmptyBody;

  /// No description provided for @searchEngineNeededTitle.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 엔진이 필요해요'**
  String get searchEngineNeededTitle;

  /// No description provided for @searchEngineNeededBody.
  ///
  /// In ko, this message translates to:
  /// **'yt-dlp가 설치되어 있지 않아 검색할 수 없어요.\n설치하면 바로 검색하고 받을 수 있어요.'**
  String get searchEngineNeededBody;

  /// No description provided for @searchEngineInstallFailed.
  ///
  /// In ko, this message translates to:
  /// **'설치하지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요.'**
  String get searchEngineInstallFailed;

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

  /// No description provided for @stateNetworkTitle.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결이 필요해요'**
  String get stateNetworkTitle;

  /// No description provided for @stateNetworkBody.
  ///
  /// In ko, this message translates to:
  /// **'연결을 확인한 뒤 다시 시도해 주세요.'**
  String get stateNetworkBody;

  /// No description provided for @stateTimeoutTitle.
  ///
  /// In ko, this message translates to:
  /// **'응답이 너무 오래 걸려요'**
  String get stateTimeoutTitle;

  /// No description provided for @stateTimeoutBody.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해 주세요.'**
  String get stateTimeoutBody;

  /// No description provided for @stateSignInTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요해요'**
  String get stateSignInTitle;

  /// No description provided for @stateSignInBody.
  ///
  /// In ko, this message translates to:
  /// **'로그인한 뒤에 쓸 수 있어요.'**
  String get stateSignInBody;

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

  /// No description provided for @searchLive.
  ///
  /// In ko, this message translates to:
  /// **'라이브'**
  String get searchLive;

  /// No description provided for @searchLiveNoDownload.
  ///
  /// In ko, this message translates to:
  /// **'라이브는 받을 수 없어요'**
  String get searchLiveNoDownload;

  /// No description provided for @searchLiveNoPreview.
  ///
  /// In ko, this message translates to:
  /// **'라이브는 미리 들을 수 없어요'**
  String get searchLiveNoPreview;

  /// No description provided for @searchPreviewUnplayable.
  ///
  /// In ko, this message translates to:
  /// **'지금은 들을 수 없는 영상이에요'**
  String get searchPreviewUnplayable;

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

  /// No description provided for @downloadsResumeAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 이어 받기'**
  String get downloadsResumeAll;

  /// No description provided for @downloadsHideCurrent.
  ///
  /// In ko, this message translates to:
  /// **'받는 곡 정보 숨기기'**
  String get downloadsHideCurrent;

  /// No description provided for @downloadsShowCurrent.
  ///
  /// In ko, this message translates to:
  /// **'받는 곡 정보 보이기'**
  String get downloadsShowCurrent;

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

  /// No description provided for @statusProcessing.
  ///
  /// In ko, this message translates to:
  /// **'처리 중'**
  String get statusProcessing;

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

  /// No description provided for @sortAscending.
  ///
  /// In ko, this message translates to:
  /// **'오름차순'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In ko, this message translates to:
  /// **'내림차순'**
  String get sortDescending;

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

  /// No description provided for @sortCount.
  ///
  /// In ko, this message translates to:
  /// **'곡 수순'**
  String get sortCount;

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
  /// **'고정 안 함 · 마지막에 받은 폴더'**
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

  /// No description provided for @loadedFoldersRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 폴더에서 뺄까요?'**
  String get loadedFoldersRemoveTitle;

  /// No description provided for @loadedFoldersRemoveBody.
  ///
  /// In ko, this message translates to:
  /// **'{path}\n이 폴더의 {count}곡이 보관함에서 사라져요. 음악 파일은 지워지지 않아요.'**
  String loadedFoldersRemoveBody(String path, int count);

  /// No description provided for @loadedFoldersRemoveBodyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'{path}\n음악 파일은 지워지지 않아요.'**
  String loadedFoldersRemoveBodyEmpty(String path);

  /// No description provided for @loadedFoldersScanning.
  ///
  /// In ko, this message translates to:
  /// **'폴더에서 곡을 찾는 중이에요'**
  String get loadedFoldersScanning;

  /// No description provided for @loadedFoldersRemoving.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 빼고 보관함을 정리하는 중이에요'**
  String get loadedFoldersRemoving;

  /// No description provided for @loadedFoldersReading.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보를 읽는 중이에요'**
  String get loadedFoldersReading;

  /// No description provided for @loadedFoldersCovers.
  ///
  /// In ko, this message translates to:
  /// **'곡 이미지를 가져오는 중이에요'**
  String get loadedFoldersCovers;

  /// No description provided for @loadedFoldersPlaylistTitle.
  ///
  /// In ko, this message translates to:
  /// **'불러온 {count}곡을 재생목록에 담을까요?'**
  String loadedFoldersPlaylistTitle(int count);

  /// No description provided for @loadedFoldersPlaylistSkip.
  ///
  /// In ko, this message translates to:
  /// **'안 담기'**
  String get loadedFoldersPlaylistSkip;

  /// No description provided for @loadedFoldersPlaylistAdd.
  ///
  /// In ko, this message translates to:
  /// **'담기'**
  String get loadedFoldersPlaylistAdd;

  /// No description provided for @loadedFoldersAddedToPlaylists.
  ///
  /// In ko, this message translates to:
  /// **'{songs}곡을 {count}개 재생목록에 담았어요'**
  String loadedFoldersAddedToPlaylists(int songs, int count);

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

  /// No description provided for @settingsEngineRemove.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get settingsEngineRemove;

  /// No description provided for @settingsEngineRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 엔진을 지울까요?'**
  String get settingsEngineRemoveTitle;

  /// No description provided for @settingsEngineRemoveBody.
  ///
  /// In ko, this message translates to:
  /// **'앱이 받아 둔 yt-dlp를 지워요. 검색과 받기를 하려면 다시 설치해야 해요. 기기에 따로 설치된 건 지우지 않아요.'**
  String get settingsEngineRemoveBody;

  /// No description provided for @settingsEngineInstalling.
  ///
  /// In ko, this message translates to:
  /// **'내려받는 중…'**
  String get settingsEngineInstalling;

  /// No description provided for @settingsEngineReverting.
  ///
  /// In ko, this message translates to:
  /// **'되돌리는 중…'**
  String get settingsEngineReverting;

  /// No description provided for @settingsEngineRevertTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트한 yt-dlp를 지울까요?'**
  String get settingsEngineRevertTitle;

  /// No description provided for @settingsEngineRevertBody.
  ///
  /// In ko, this message translates to:
  /// **'업데이트로 받은 yt-dlp를 지우고 처음 버전으로 돌아가요. 업데이트 뒤 검색이나 받기가 안 될 때 써 보세요.'**
  String get settingsEngineRevertBody;

  /// No description provided for @settingsEngineRevertFailed.
  ///
  /// In ko, this message translates to:
  /// **'지우지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get settingsEngineRevertFailed;

  /// No description provided for @settingsEngineBundled.
  ///
  /// In ko, this message translates to:
  /// **'앱에 들어 있는 yt-dlp'**
  String get settingsEngineBundled;

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

  /// No description provided for @settingsBackgroundDownload.
  ///
  /// In ko, this message translates to:
  /// **'백그라운드 받기'**
  String get settingsBackgroundDownload;

  /// No description provided for @settingsBackgroundDownloadDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱이 뒤로 가거나 닫혀도 받기를 이어 가요. 켜 두면 받는 동안 알림이 계속 떠 있어요.'**
  String get settingsBackgroundDownloadDesc;

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

  /// No description provided for @settingsThemeColorFollowing.
  ///
  /// In ko, this message translates to:
  /// **'곡 분위기 따라가기가 켜져 있어 재생 중인 곡의 색을 따라가요.'**
  String get settingsThemeColorFollowing;

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
  /// **'고른 테마로 앱 화면들을 직접 둘러보고 적용해요.'**
  String get settingsThemePreviewDesc;

  /// No description provided for @settingsPlayback.
  ///
  /// In ko, this message translates to:
  /// **'재생 설정'**
  String get settingsPlayback;

  /// No description provided for @settingsMixWithOthers.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱과 함께 재생'**
  String get settingsMixWithOthers;

  /// No description provided for @videoQualityTitle.
  ///
  /// In ko, this message translates to:
  /// **'영상 화질'**
  String get videoQualityTitle;

  /// No description provided for @videoQualityHint.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기 영상에 쓰여요. 높이면 선명하지만 데이터를 더 써요.'**
  String get videoQualityHint;

  /// No description provided for @videoQualityLow.
  ///
  /// In ko, this message translates to:
  /// **'144p'**
  String get videoQualityLow;

  /// No description provided for @videoQualityStandard.
  ///
  /// In ko, this message translates to:
  /// **'360p · 기본'**
  String get videoQualityStandard;

  /// No description provided for @videoQualityMedium.
  ///
  /// In ko, this message translates to:
  /// **'480p'**
  String get videoQualityMedium;

  /// No description provided for @videoQualityHigh.
  ///
  /// In ko, this message translates to:
  /// **'720p'**
  String get videoQualityHigh;

  /// No description provided for @videoQualityFull.
  ///
  /// In ko, this message translates to:
  /// **'1080p'**
  String get videoQualityFull;

  /// No description provided for @settingsSleepTimerOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get settingsSleepTimerOff;

  /// No description provided for @settingsLyricsOverlay.
  ///
  /// In ko, this message translates to:
  /// **'오버레이 가사'**
  String get settingsLyricsOverlay;

  /// No description provided for @settingsLyricsOverlayDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 위에 가사를 띄워요. 한 번 켜 두면 앱을 다시 켜도 유지돼요.'**
  String get settingsLyricsOverlayDesc;

  /// No description provided for @settingsMixWithOthersDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 소리와 함께 재생해요. 소리가 겹칠 수 있어요.'**
  String get settingsMixWithOthersDesc;

  /// No description provided for @settingsPauseOnDisconnect.
  ///
  /// In ko, this message translates to:
  /// **'기기가 끊기면 일시정지'**
  String get settingsPauseOnDisconnect;

  /// No description provided for @settingsPauseOnDisconnectDesc.
  ///
  /// In ko, this message translates to:
  /// **'이어폰을 빼거나 블루투스 연결이 끊기면 재생을 멈춰요.'**
  String get settingsPauseOnDisconnectDesc;

  /// No description provided for @settingsResumeOnConnect.
  ///
  /// In ko, this message translates to:
  /// **'기기가 연결되면 이어 재생'**
  String get settingsResumeOnConnect;

  /// No description provided for @settingsResumeOnConnectDesc.
  ///
  /// In ko, this message translates to:
  /// **'끊겨서 멈춘 재생을 10분 안에 다시 연결하면 이어서 재생해요.'**
  String get settingsResumeOnConnectDesc;

  /// No description provided for @settingsResumeWithoutNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림이 없어도 블루투스로 재생'**
  String get settingsResumeWithoutNotification;

  /// No description provided for @settingsResumeWithoutNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림을 지웠거나 재생이 끝난 뒤에도 블루투스 재생 버튼으로 마지막 곡을 이어 재생해요.'**
  String get settingsResumeWithoutNotificationDesc;

  /// No description provided for @playerStyleTitle.
  ///
  /// In ko, this message translates to:
  /// **'플레이어 테마'**
  String get playerStyleTitle;

  /// No description provided for @playerSpeedTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생 속도'**
  String get playerSpeedTitle;

  /// No description provided for @playerSpeedValue.
  ///
  /// In ko, this message translates to:
  /// **'{speed}배속'**
  String playerSpeedValue(String speed);

  /// No description provided for @playerSpeedNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get playerSpeedNormal;

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

  /// No description provided for @playerSleepTimerUnitHour.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get playerSleepTimerUnitHour;

  /// No description provided for @playerSleepTimerUnitMinute.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get playerSleepTimerUnitMinute;

  /// No description provided for @playerSleepTimerStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get playerSleepTimerStart;

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

  /// No description provided for @settingsData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsData;

  /// No description provided for @settingsStreamCache.
  ///
  /// In ko, this message translates to:
  /// **'스트리밍 임시 저장'**
  String get settingsStreamCache;

  /// No description provided for @settingsStreamCacheDesc.
  ///
  /// In ko, this message translates to:
  /// **'{used} 사용 중 · 한도 {limit}'**
  String settingsStreamCacheDesc(String used, String limit);

  /// No description provided for @settingsStreamCacheClear.
  ///
  /// In ko, this message translates to:
  /// **'지금 비우기'**
  String get settingsStreamCacheClear;

  /// No description provided for @savedVideosTitle.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장한 음원'**
  String get savedVideosTitle;

  /// No description provided for @savedVideosOpen.
  ///
  /// In ko, this message translates to:
  /// **'저장한 음원'**
  String get savedVideosOpen;

  /// No description provided for @savedVideosEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장한 음원이 없어요'**
  String get savedVideosEmpty;

  /// No description provided for @savedVideosAdd.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get savedVideosAdd;

  /// No description provided for @savedVideosAdded.
  ///
  /// In ko, this message translates to:
  /// **'저장됨'**
  String get savedVideosAdded;

  /// No description provided for @savedVideosFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요'**
  String get savedVideosFailed;

  /// No description provided for @savedVideosDownloading.
  ///
  /// In ko, this message translates to:
  /// **'받는 중'**
  String get savedVideosDownloading;

  /// No description provided for @savedVideosEtaSeconds.
  ///
  /// In ko, this message translates to:
  /// **'약 {n}초 남음'**
  String savedVideosEtaSeconds(int n);

  /// No description provided for @savedVideosEtaMinutes.
  ///
  /// In ko, this message translates to:
  /// **'약 {n}분 남음'**
  String savedVideosEtaMinutes(int n);

  /// No description provided for @savedVideosRemove.
  ///
  /// In ko, this message translates to:
  /// **'저장 해제'**
  String get savedVideosRemove;

  /// No description provided for @savedVideosAudioOnly.
  ///
  /// In ko, this message translates to:
  /// **'소리만'**
  String get savedVideosAudioOnly;

  /// No description provided for @savedVideosClearAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get savedVideosClearAll;

  /// No description provided for @savedVideosClearAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장한 음원을 모두 삭제할까요?'**
  String get savedVideosClearAllTitle;

  /// No description provided for @savedVideosClearAllBody.
  ///
  /// In ko, this message translates to:
  /// **'저장해 둔 음원이 모두 지워져요'**
  String get savedVideosClearAllBody;

  /// No description provided for @savedVideosStorage.
  ///
  /// In ko, this message translates to:
  /// **'저장 {saved} + 듣기 캐시 {temp} / 한도 {limit}'**
  String savedVideosStorage(String saved, String temp, String limit);

  /// No description provided for @savedVideosFull.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장 공간이 가득 찼어요. 저장한 곡을 지우거나 용량을 늘려 주세요'**
  String get savedVideosFull;

  /// No description provided for @savedVideosUsed.
  ///
  /// In ko, this message translates to:
  /// **'{size} 사용 중'**
  String savedVideosUsed(String size);

  /// No description provided for @savedVideosQualityTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장 화질'**
  String get savedVideosQualityTitle;

  /// No description provided for @savedVideosQualityHint.
  ///
  /// In ko, this message translates to:
  /// **'고른 화질로 받아 둬요'**
  String get savedVideosQualityHint;

  /// No description provided for @savedQueueTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장한 음원 대기열'**
  String get savedQueueTitle;

  /// No description provided for @savedQueueOpen.
  ///
  /// In ko, this message translates to:
  /// **'대기열'**
  String get savedQueueOpen;

  /// No description provided for @notifSavedQueueLabel.
  ///
  /// In ko, this message translates to:
  /// **'저장한 음원 {n}/{total}'**
  String notifSavedQueueLabel(String n, String total);

  /// No description provided for @savedVideosLoop.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get savedVideosLoop;

  /// No description provided for @savedVideosPlay.
  ///
  /// In ko, this message translates to:
  /// **'듣기'**
  String get savedVideosPlay;

  /// No description provided for @videoFullscreen.
  ///
  /// In ko, this message translates to:
  /// **'전체 화면'**
  String get videoFullscreen;

  /// No description provided for @videoFullscreenExit.
  ///
  /// In ko, this message translates to:
  /// **'축소'**
  String get videoFullscreenExit;

  /// No description provided for @newVideosDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 보기'**
  String get newVideosDetail;

  /// No description provided for @savedVideosConfirm.
  ///
  /// In ko, this message translates to:
  /// **'담기'**
  String get savedVideosConfirm;

  /// No description provided for @videoBack10.
  ///
  /// In ko, this message translates to:
  /// **'10초 뒤로'**
  String get videoBack10;

  /// No description provided for @videoForward10.
  ///
  /// In ko, this message translates to:
  /// **'10초 앞으로'**
  String get videoForward10;

  /// No description provided for @savedVideosSectionVideo.
  ///
  /// In ko, this message translates to:
  /// **'영상'**
  String get savedVideosSectionVideo;

  /// No description provided for @savedVideosSectionAudio.
  ///
  /// In ko, this message translates to:
  /// **'음원'**
  String get savedVideosSectionAudio;

  /// No description provided for @videoPip.
  ///
  /// In ko, this message translates to:
  /// **'작은 화면으로 보기'**
  String get videoPip;

  /// No description provided for @videoOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션'**
  String get videoOptions;

  /// No description provided for @videoOptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'영상 옵션'**
  String get videoOptionsTitle;

  /// No description provided for @videoRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복 재생'**
  String get videoRepeat;

  /// No description provided for @videoQualityAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get videoQualityAuto;

  /// No description provided for @videoQualityAutoHint.
  ///
  /// In ko, this message translates to:
  /// **'빠르게 시작한 뒤 화질을 높여요'**
  String get videoQualityAutoHint;

  /// No description provided for @settingsStreamCacheLimitHint.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장한 음원도 함께 계산해요. 넘으면 오래된 임시 캐시부터 지워요. ({used} 사용 중)'**
  String settingsStreamCacheLimitHint(String used);

  /// No description provided for @settingsStreamCacheCleared.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장소를 비웠어요'**
  String get settingsStreamCacheCleared;

  /// No description provided for @settingsPurgeHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 곡 기록 정리'**
  String get settingsPurgeHidden;

  /// No description provided for @settingsPurgeHiddenDesc.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 빼서 숨겨 둔 {count}곡의 기록이 남아 있어요'**
  String settingsPurgeHiddenDesc(int count);

  /// No description provided for @settingsPurgeHiddenNone.
  ///
  /// In ko, this message translates to:
  /// **'정리할 기록이 없어요'**
  String get settingsPurgeHiddenNone;

  /// No description provided for @settingsPurgeHiddenTitle.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 곡 기록을 지울까요?'**
  String get settingsPurgeHiddenTitle;

  /// No description provided for @settingsPurgeHiddenBody.
  ///
  /// In ko, this message translates to:
  /// **'숨겨 둔 {count}곡의 재생 횟수, 좋아요, 재생목록, 커버, 가사 사본이 지워져요. 음악 파일과 태그는 그대로예요.'**
  String settingsPurgeHiddenBody(int count);

  /// No description provided for @settingsPurgeHiddenDone.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡의 기록을 지웠어요'**
  String settingsPurgeHiddenDone(int count);

  /// No description provided for @hiddenRecordsHint.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 빼서 숨겨 둔 {count}곡이에요. 기록을 지울 곡을 골라요.'**
  String hiddenRecordsHint(int count);

  /// No description provided for @hiddenRecordsPlays.
  ///
  /// In ko, this message translates to:
  /// **'{count}회 재생'**
  String hiddenRecordsPlays(int count);

  /// No description provided for @hiddenRecordsLastPlayed.
  ///
  /// In ko, this message translates to:
  /// **'마지막 {date}'**
  String hiddenRecordsLastPlayed(String date);

  /// No description provided for @hiddenRecordsPlaylists.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 {count}개'**
  String hiddenRecordsPlaylists(int count);

  /// No description provided for @hiddenRecordsCover.
  ///
  /// In ko, this message translates to:
  /// **'커버'**
  String get hiddenRecordsCover;

  /// No description provided for @hiddenRecordsLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사 사본'**
  String get hiddenRecordsLyrics;

  /// No description provided for @hiddenRecordsPurgeAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 지우기'**
  String get hiddenRecordsPurgeAll;

  /// No description provided for @hiddenRecordsPurgeOneTitle.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 기록을 지울까요?'**
  String hiddenRecordsPurgeOneTitle(String title);

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

  /// No description provided for @shuffleOn.
  ///
  /// In ko, this message translates to:
  /// **'셔플 켜기'**
  String get shuffleOn;

  /// No description provided for @shuffleOff.
  ///
  /// In ko, this message translates to:
  /// **'셔플 끄기'**
  String get shuffleOff;

  /// No description provided for @queueClear.
  ///
  /// In ko, this message translates to:
  /// **'대기열 비우기'**
  String get queueClear;

  /// No description provided for @queueSelect.
  ///
  /// In ko, this message translates to:
  /// **'여러 곡 선택'**
  String get queueSelect;

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

  /// No description provided for @playerLoop.
  ///
  /// In ko, this message translates to:
  /// **'구간 반복'**
  String get playerLoop;

  /// No description provided for @playerLoopSetStart.
  ///
  /// In ko, this message translates to:
  /// **'구간 반복: 시작 지점을 정해요'**
  String get playerLoopSetStart;

  /// No description provided for @playerLoopSetEnd.
  ///
  /// In ko, this message translates to:
  /// **'구간 반복: 끝 지점을 정해요'**
  String get playerLoopSetEnd;

  /// No description provided for @playerLoopClear.
  ///
  /// In ko, this message translates to:
  /// **'구간 반복 끄기'**
  String get playerLoopClear;

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

  /// No description provided for @coverWebBrowserHelp.
  ///
  /// In ko, this message translates to:
  /// **'마음에 드는 이미지를 누르면 바로 편집 화면으로 가요.'**
  String get coverWebBrowserHelp;

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
  /// **'이미지'**
  String get coverEditTitle;

  /// No description provided for @coverEditHint.
  ///
  /// In ko, this message translates to:
  /// **'테두리 안이 실제 커버예요. 어두운 곳은 잘리고 빈 곳은 검정이에요. 끌어서 옮기고 두 손가락으로 크기와 각도를 바꿔요'**
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

  /// No description provided for @coverEditResetPosition.
  ///
  /// In ko, this message translates to:
  /// **'위치 되돌리기'**
  String get coverEditResetPosition;

  /// No description provided for @coverEditResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'위치와 크기를 되돌릴까요?'**
  String get coverEditResetTitle;

  /// No description provided for @coverEditResetBody.
  ///
  /// In ko, this message translates to:
  /// **'확대 · 위치 · 회전이 처음 상태로 돌아가요.'**
  String get coverEditResetBody;

  /// No description provided for @coverEditResetConfirm.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get coverEditResetConfirm;

  /// No description provided for @coverChange.
  ///
  /// In ko, this message translates to:
  /// **'이미지 바꾸기'**
  String get coverChange;

  /// No description provided for @coverRemove.
  ///
  /// In ko, this message translates to:
  /// **'이미지 지우기'**
  String get coverRemove;

  /// No description provided for @coverRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 지울까요?'**
  String get coverRemoveTitle;

  /// No description provided for @coverRemoveBody.
  ///
  /// In ko, this message translates to:
  /// **'고른 이미지를 지워요. 나중에 다시 고를 수 있어요.'**
  String get coverRemoveBody;

  /// No description provided for @coverRevertTitle.
  ///
  /// In ko, this message translates to:
  /// **'기본 이미지로 되돌릴까요?'**
  String get coverRevertTitle;

  /// No description provided for @coverRevertBody.
  ///
  /// In ko, this message translates to:
  /// **'고른 이미지를 지우고 기본 이미지로 돌아가요.'**
  String get coverRevertBody;

  /// No description provided for @coverEditApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get coverEditApply;

  /// No description provided for @coverEditEmpty.
  ///
  /// In ko, this message translates to:
  /// **'위에서 이미지를 불러오세요'**
  String get coverEditEmpty;

  /// No description provided for @coverEditRotation.
  ///
  /// In ko, this message translates to:
  /// **'회전'**
  String get coverEditRotation;

  /// No description provided for @coverEditRotateLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 90°'**
  String get coverEditRotateLeft;

  /// No description provided for @coverEditRotateRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 90°'**
  String get coverEditRotateRight;

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

  /// No description provided for @searchHintSite.
  ///
  /// In ko, this message translates to:
  /// **'{site} URL이나 검색어'**
  String searchHintSite(String site);

  /// No description provided for @sourceSoundcloud.
  ///
  /// In ko, this message translates to:
  /// **'SoundCloud'**
  String get sourceSoundcloud;

  /// No description provided for @searchSubmitTooltip.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get searchSubmitTooltip;

  /// No description provided for @searchPasteLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 붙여넣기'**
  String get searchPasteLink;

  /// No description provided for @searchPasteEmpty.
  ///
  /// In ko, this message translates to:
  /// **'클립보드에 링크가 없어요'**
  String get searchPasteEmpty;

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

  /// No description provided for @searchPreviewPause.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기 일시정지'**
  String get searchPreviewPause;

  /// No description provided for @searchPreviewResume.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기 이어 듣기'**
  String get searchPreviewResume;

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

  /// No description provided for @mediaDetailListenOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원본 사이트에서 듣기'**
  String get mediaDetailListenOriginal;

  /// No description provided for @mediaDetailListenSoundcloud.
  ///
  /// In ko, this message translates to:
  /// **'SoundCloud에서 듣기'**
  String get mediaDetailListenSoundcloud;

  /// No description provided for @mediaDetailOpenArtist.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 보기'**
  String get mediaDetailOpenArtist;

  /// No description provided for @mediaDetailPlays.
  ///
  /// In ko, this message translates to:
  /// **'재생수'**
  String get mediaDetailPlays;

  /// No description provided for @mediaDetailGenre.
  ///
  /// In ko, this message translates to:
  /// **'장르'**
  String get mediaDetailGenre;

  /// No description provided for @mediaDetailFollowers.
  ///
  /// In ko, this message translates to:
  /// **'팔로워 {count}명'**
  String mediaDetailFollowers(String count);

  /// No description provided for @mediaDetailChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get mediaDetailChannel;

  /// No description provided for @mediaDetailSite.
  ///
  /// In ko, this message translates to:
  /// **'출처'**
  String get mediaDetailSite;

  /// No description provided for @mediaDetailUploader.
  ///
  /// In ko, this message translates to:
  /// **'올린 사람'**
  String get mediaDetailUploader;

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

  /// No description provided for @mediaDetailSectionPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기'**
  String get mediaDetailSectionPreview;

  /// No description provided for @mediaDetailSectionInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get mediaDetailSectionInfo;

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

  /// No description provided for @searchSortDuration.
  ///
  /// In ko, this message translates to:
  /// **'길이순'**
  String get searchSortDuration;

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

  /// No description provided for @downloadsRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡 남음'**
  String downloadsRemaining(int count);

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

  /// No description provided for @downloadLyricsEditHint.
  ///
  /// In ko, this message translates to:
  /// **'파일 · 웹에서 불러오거나 직접 써요. 자막이 없어도 돼요.'**
  String get downloadLyricsEditHint;

  /// No description provided for @downloadLyricsOverwriteTitle.
  ///
  /// In ko, this message translates to:
  /// **'직접 정한 가사가 있어요'**
  String get downloadLyricsOverwriteTitle;

  /// No description provided for @downloadLyricsOverwriteBody.
  ///
  /// In ko, this message translates to:
  /// **'영상 자막을 쓰면 직접 정한 가사는 지워져요. 계속할까요?'**
  String get downloadLyricsOverwriteBody;

  /// No description provided for @downloadLyricsOverwriteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'자막으로 바꾸기'**
  String get downloadLyricsOverwriteConfirm;

  /// No description provided for @downloadLyricsCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 정한 가사를 넣어요 · {lines}줄'**
  String downloadLyricsCustom(int lines);

  /// No description provided for @downloadImportLyrics.
  ///
  /// In ko, this message translates to:
  /// **'자막을 가사로 가져오기'**
  String get downloadImportLyrics;

  /// No description provided for @downloadImportLyricsHint.
  ///
  /// In ko, this message translates to:
  /// **'받은 뒤 가사 보기의 싱크 설정에서 다듬을 수 있어요.'**
  String get downloadImportLyricsHint;

  /// No description provided for @downloadSubtitleChecking.
  ///
  /// In ko, this message translates to:
  /// **'자막이 있는지 확인하는 중이에요.'**
  String get downloadSubtitleChecking;

  /// No description provided for @downloadSubtitleNone.
  ///
  /// In ko, this message translates to:
  /// **'이 영상에는 자막이 없어요.'**
  String get downloadSubtitleNone;

  /// No description provided for @downloadSubtitleUnknown.
  ///
  /// In ko, this message translates to:
  /// **'자막을 확인하지 못했어요. 켜 두면 받은 뒤 다시 찾아봐요.'**
  String get downloadSubtitleUnknown;

  /// No description provided for @downloadSubtitleLanguage.
  ///
  /// In ko, this message translates to:
  /// **'자막 언어'**
  String get downloadSubtitleLanguage;

  /// No description provided for @downloadSubtitleAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동으로 고르기'**
  String get downloadSubtitleAuto;

  /// No description provided for @downloadSubtitleAutoHint.
  ///
  /// In ko, this message translates to:
  /// **'한국어 → 영어 → 첫 번째 자막 순으로 골라요.'**
  String get downloadSubtitleAutoHint;

  /// No description provided for @downloadLyricsPreviewLoading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get downloadLyricsPreviewLoading;

  /// No description provided for @downloadLyricsPreviewFailed.
  ///
  /// In ko, this message translates to:
  /// **'자막을 불러오지 못했어요.'**
  String get downloadLyricsPreviewFailed;

  /// No description provided for @downloadSubtitleEditHint.
  ///
  /// In ko, this message translates to:
  /// **'글은 고칠 수 있지만 시간은 바꿀 수 없어요. 싱크는 받은 뒤 재생 화면에서 맞춰요.'**
  String get downloadSubtitleEditHint;

  /// No description provided for @downloadSubtitleUseEdited.
  ///
  /// In ko, this message translates to:
  /// **'이 자막 사용'**
  String get downloadSubtitleUseEdited;

  /// No description provided for @downloadSubtitleApplied.
  ///
  /// In ko, this message translates to:
  /// **'가사에 적용'**
  String get downloadSubtitleApplied;

  /// No description provided for @downloadLyricsRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 불러오기'**
  String get downloadLyricsRetry;

  /// No description provided for @downloadSubtitleUse.
  ///
  /// In ko, this message translates to:
  /// **'이 자막 사용'**
  String get downloadSubtitleUse;

  /// No description provided for @downloadSubtitleInUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 중인 자막'**
  String get downloadSubtitleInUse;

  /// No description provided for @downloadLyricsSkipSounds.
  ///
  /// In ko, this message translates to:
  /// **'효과음 줄 빼기'**
  String get downloadLyricsSkipSounds;

  /// No description provided for @downloadLyricsSkipSoundsHint.
  ///
  /// In ko, this message translates to:
  /// **'[음악] · (박수) · ♪ 같은 줄은 가사로 가져오지 않아요.'**
  String get downloadLyricsSkipSoundsHint;

  /// No description provided for @downloadSubtitleColLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get downloadSubtitleColLanguage;

  /// No description provided for @downloadSubtitleColKind.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get downloadSubtitleColKind;

  /// No description provided for @downloadSubtitleKindAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동 생성'**
  String get downloadSubtitleKindAuto;

  /// No description provided for @downloadSubtitleKindManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 단 자막'**
  String get downloadSubtitleKindManual;

  /// No description provided for @downloadSubtitleFound.
  ///
  /// In ko, this message translates to:
  /// **'자막 {count}개를 찾았어요.'**
  String downloadSubtitleFound(int count);

  /// No description provided for @downloadSectionInfo.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get downloadSectionInfo;

  /// No description provided for @downloadSectionSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get downloadSectionSave;

  /// No description provided for @downloadSectionLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사'**
  String get downloadSectionLyrics;

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

  /// No description provided for @downloadFieldAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get downloadFieldAlbum;

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

  /// No description provided for @saveFolderTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장 위치 고르기'**
  String get saveFolderTitle;

  /// No description provided for @saveFolderFixedHint.
  ///
  /// In ko, this message translates to:
  /// **'체크한 폴더로 항상 받아요. 모두 풀면 마지막에 받은 폴더에 받아요.'**
  String get saveFolderFixedHint;

  /// No description provided for @saveFolderEmpty.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 폴더가 없어요. 직접 선택해 주세요.'**
  String get saveFolderEmpty;

  /// No description provided for @saveFolderPickOther.
  ///
  /// In ko, this message translates to:
  /// **'직접 선택'**
  String get saveFolderPickOther;

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

  /// No description provided for @downloadAlreadyDownloaded.
  ///
  /// In ko, this message translates to:
  /// **'이미 받은 곡이에요'**
  String get downloadAlreadyDownloaded;

  /// No description provided for @downloadStateDownloading.
  ///
  /// In ko, this message translates to:
  /// **'받는 중'**
  String get downloadStateDownloading;

  /// No description provided for @downloadStateQueued.
  ///
  /// In ko, this message translates to:
  /// **'대기 중'**
  String get downloadStateQueued;

  /// No description provided for @downloadStateDone.
  ///
  /// In ko, this message translates to:
  /// **'받음'**
  String get downloadStateDone;

  /// No description provided for @downloadAlreadyInQueue.
  ///
  /// In ko, this message translates to:
  /// **'이미 받는 중이거나 대기 중인 곡이에요'**
  String get downloadAlreadyInQueue;

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

  /// No description provided for @playlistsReorderHint.
  ///
  /// In ko, this message translates to:
  /// **'길게 눌러 끌면 순서를 바꿀 수 있어요.'**
  String get playlistsReorderHint;

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

  /// No description provided for @artistRenameTooltip.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 이름 바꾸기'**
  String get artistRenameTooltip;

  /// No description provided for @artistRenameTitle.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 이름 바꾸기'**
  String get artistRenameTitle;

  /// No description provided for @artistRenameHint.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 이름'**
  String get artistRenameHint;

  /// No description provided for @genreRenameTooltip.
  ///
  /// In ko, this message translates to:
  /// **'장르 이름 바꾸기'**
  String get genreRenameTooltip;

  /// No description provided for @genreRenameTitle.
  ///
  /// In ko, this message translates to:
  /// **'장르 이름 바꾸기'**
  String get genreRenameTitle;

  /// No description provided for @genreRenameHint.
  ///
  /// In ko, this message translates to:
  /// **'장르 이름'**
  String get genreRenameHint;

  /// No description provided for @renameProgressTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보를 고치는 중이에요'**
  String get renameProgressTitle;

  /// No description provided for @renameProgressCount.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{total}곡'**
  String renameProgressCount(int done, int total);

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
  /// **'상세 정보'**
  String get trackMenuEditInfo;

  /// No description provided for @trackMenuDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get trackMenuDelete;

  /// No description provided for @trackMenuRemoveFromQueue.
  ///
  /// In ko, this message translates to:
  /// **'대기열에서 빼기'**
  String get trackMenuRemoveFromQueue;

  /// No description provided for @trackRemovedFromQueue.
  ///
  /// In ko, this message translates to:
  /// **'대기열에서 뺐어요.'**
  String get trackRemovedFromQueue;

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

  /// No description provided for @trackInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 상세 정보'**
  String get trackInfoTitle;

  /// No description provided for @trackInfoUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get trackInfoUnknown;

  /// No description provided for @trackInfoDuration.
  ///
  /// In ko, this message translates to:
  /// **'길이'**
  String get trackInfoDuration;

  /// No description provided for @trackInfoAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가한 날'**
  String get trackInfoAdded;

  /// No description provided for @trackInfoSource.
  ///
  /// In ko, this message translates to:
  /// **'출처'**
  String get trackInfoSource;

  /// No description provided for @trackInfoSourceDevice.
  ///
  /// In ko, this message translates to:
  /// **'외부'**
  String get trackInfoSourceDevice;

  /// No description provided for @trackInfoSourceDownload.
  ///
  /// In ko, this message translates to:
  /// **'받은 곡'**
  String get trackInfoSourceDownload;

  /// No description provided for @downloadTagFailed.
  ///
  /// In ko, this message translates to:
  /// **'태그를 저장하지 못했어요: {title}'**
  String downloadTagFailed(String title);

  /// No description provided for @trackInfoFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더'**
  String get trackInfoFolder;

  /// No description provided for @collectionMenuInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get collectionMenuInfo;

  /// No description provided for @playlistInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생목록 정보'**
  String get playlistInfoTitle;

  /// No description provided for @albumInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범 정보'**
  String get albumInfoTitle;

  /// No description provided for @artistInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 정보'**
  String get artistInfoTitle;

  /// No description provided for @genreInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'장르 정보'**
  String get genreInfoTitle;

  /// No description provided for @trackInfoFileSize.
  ///
  /// In ko, this message translates to:
  /// **'파일 크기'**
  String get trackInfoFileSize;

  /// No description provided for @trackInfoFormat.
  ///
  /// In ko, this message translates to:
  /// **'형식'**
  String get trackInfoFormat;

  /// No description provided for @trackInfoBitrate.
  ///
  /// In ko, this message translates to:
  /// **'비트레이트'**
  String get trackInfoBitrate;

  /// No description provided for @trackInfoSampleRate.
  ///
  /// In ko, this message translates to:
  /// **'샘플레이트'**
  String get trackInfoSampleRate;

  /// No description provided for @trackInfoUrl.
  ///
  /// In ko, this message translates to:
  /// **'원본 주소'**
  String get trackInfoUrl;

  /// No description provided for @trackInfoUrlCopied.
  ///
  /// In ko, this message translates to:
  /// **'주소를 복사했어요'**
  String get trackInfoUrlCopied;

  /// No description provided for @trackEditTagFailed.
  ///
  /// In ko, this message translates to:
  /// **'음악 파일에 곡 정보를 쓰지 못해 바꾸지 않았어요. 잠시 뒤 다시 시도해 주세요.'**
  String get trackEditTagFailed;

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
  /// **'가사를 붙여넣거나 입력하세요. [01:02.30]처럼 시간이 붙은 글이나 .lrc · .txt 파일을 불러오면 싱크 가사가 돼요. 비우고 저장하면 지워져요.'**
  String get lyricsEditHint;

  /// No description provided for @lyricsEditSyncedHint.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 시간은 줄 번호에 붙어 있어요. 줄을 끼우거나 지우면 시간은 그대로 남고 글만 밀려요. 시간은 싱크 설정에서 바꿔요.'**
  String get lyricsEditSyncedHint;

  /// No description provided for @lyricsAddLine.
  ///
  /// In ko, this message translates to:
  /// **'줄 추가'**
  String get lyricsAddLine;

  /// No description provided for @lyricsDeleteLine.
  ///
  /// In ko, this message translates to:
  /// **'줄 지우기'**
  String get lyricsDeleteLine;

  /// No description provided for @lyricsTimePrev.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get lyricsTimePrev;

  /// No description provided for @lyricsTimeNow.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get lyricsTimeNow;

  /// No description provided for @lyricsTimeNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get lyricsTimeNext;

  /// No description provided for @lyricsTimeNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get lyricsTimeNone;

  /// No description provided for @lyricsTimeGroupedAbove.
  ///
  /// In ko, this message translates to:
  /// **'앞 줄과 같은 시간이라 묶여요'**
  String get lyricsTimeGroupedAbove;

  /// No description provided for @lyricsTimeGroupedBelow.
  ///
  /// In ko, this message translates to:
  /// **'다음 줄과 같은 시간이라 묶여요'**
  String get lyricsTimeGroupedBelow;

  /// No description provided for @lyricsTimeSeparate.
  ///
  /// In ko, this message translates to:
  /// **'이 줄부터 묶음에서 떼기'**
  String get lyricsTimeSeparate;

  /// No description provided for @lyricsTimeClearFrom.
  ///
  /// In ko, this message translates to:
  /// **'여기부터 싱크 지우기'**
  String get lyricsTimeClearFrom;

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
  /// **'가사를 끌어서 골라 \'담기\', 다 모았으면 \'가져오기\''**
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

  /// No description provided for @lyricsSyncPrevious.
  ///
  /// In ko, this message translates to:
  /// **'싱크 한 칸 지우고 뒤로'**
  String get lyricsSyncPrevious;

  /// No description provided for @lyricsSyncSavePartial.
  ///
  /// In ko, this message translates to:
  /// **'중간 저장 (찍은 곳까지)'**
  String get lyricsSyncSavePartial;

  /// No description provided for @lyricsSyncSave.
  ///
  /// In ko, this message translates to:
  /// **'싱크 저장'**
  String get lyricsSyncSave;

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

  /// No description provided for @lyricsTagNotSaved.
  ///
  /// In ko, this message translates to:
  /// **'파일 저장에 실패했어요. 앱 데이터를 지우면 가사가 사라져요.'**
  String get lyricsTagNotSaved;

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

  /// No description provided for @lyricsSyncBackBy.
  ///
  /// In ko, this message translates to:
  /// **'{n}초 전으로 (길게 눌러 단위 바꾸기)'**
  String lyricsSyncBackBy(double n);

  /// No description provided for @lyricsSyncForwardBy.
  ///
  /// In ko, this message translates to:
  /// **'{n}초 뒤로 (길게 눌러 단위 바꾸기)'**
  String lyricsSyncForwardBy(double n);

  /// No description provided for @lyricsSyncAutoPause.
  ///
  /// In ko, this message translates to:
  /// **'자동 멈춤'**
  String get lyricsSyncAutoPause;

  /// No description provided for @lyricsSyncAutoPauseHint.
  ///
  /// In ko, this message translates to:
  /// **'다음 줄에 이미 있는 싱크 시간에 닿으면 재생을 멈춰요'**
  String get lyricsSyncAutoPauseHint;

  /// No description provided for @lyricsSyncSeek.
  ///
  /// In ko, this message translates to:
  /// **'재생 위치'**
  String get lyricsSyncSeek;

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

  /// No description provided for @lyricsImportMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모에 추가'**
  String get lyricsImportMemo;

  /// No description provided for @lyricsMemoTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get lyricsMemoTitle;

  /// No description provided for @lyricsMemoHide.
  ///
  /// In ko, this message translates to:
  /// **'메모 숨기기'**
  String get lyricsMemoHide;

  /// No description provided for @lyricsMemoHint.
  ///
  /// In ko, this message translates to:
  /// **'골라서 \"끼우기\"를 누르면 지금 줄 아래에 들어가요'**
  String get lyricsMemoHint;

  /// No description provided for @lyricsMemoInsert.
  ///
  /// In ko, this message translates to:
  /// **'끼우기'**
  String get lyricsMemoInsert;

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
  /// **'아직 모든 줄에 시간을 찍지 않았어요. 지금 나가면 찍은 시간이 사라져요. 저장하고 나갈까요?'**
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

  /// No description provided for @lyricsSyncExpandedHint.
  ///
  /// In ko, this message translates to:
  /// **'줄별로 펼쳤어요 · 시간을 따로 정할 수 있고, 영역 밖을 누르면 시간이 같은 줄은 다시 합쳐져요'**
  String get lyricsSyncExpandedHint;

  /// No description provided for @lyricsSyncCancelAfter.
  ///
  /// In ko, this message translates to:
  /// **'이 싱크로 초기화'**
  String get lyricsSyncCancelAfter;

  /// No description provided for @lyricsSyncCancelAfterHint.
  ///
  /// In ko, this message translates to:
  /// **'이 싱크 뒤에 찍은 싱크를 지우고 여기서부터 다시 찍어요'**
  String get lyricsSyncCancelAfterHint;

  /// No description provided for @lyricsSyncNextSlot.
  ///
  /// In ko, this message translates to:
  /// **'이어 찍기'**
  String get lyricsSyncNextSlot;

  /// No description provided for @lyricsSyncFollow.
  ///
  /// In ko, this message translates to:
  /// **'따라가기'**
  String get lyricsSyncFollow;

  /// No description provided for @lyricsSyncFollowHint.
  ///
  /// In ko, this message translates to:
  /// **'켜면 목록이 포커스한 칸을 따라 움직이고, 끄면 가사를 자유롭게 볼 수 있어요'**
  String get lyricsSyncFollowHint;

  /// No description provided for @lyricsFollow.
  ///
  /// In ko, this message translates to:
  /// **'싱크 추적'**
  String get lyricsFollow;

  /// No description provided for @lyricsThemeList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get lyricsThemeList;

  /// No description provided for @lyricsThemeCentered.
  ///
  /// In ko, this message translates to:
  /// **'가운데 한 줄'**
  String get lyricsThemeCentered;

  /// No description provided for @lyricsThemeCover.
  ///
  /// In ko, this message translates to:
  /// **'커버 배경'**
  String get lyricsThemeCover;

  /// No description provided for @themeTabPlayer.
  ///
  /// In ko, this message translates to:
  /// **'플레이어'**
  String get themeTabPlayer;

  /// No description provided for @themeTabLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사'**
  String get themeTabLyrics;

  /// No description provided for @lyricsLatencyTitle.
  ///
  /// In ko, this message translates to:
  /// **'반응 시간 보정'**
  String get lyricsLatencyTitle;

  /// No description provided for @lyricsLatencyEntry.
  ///
  /// In ko, this message translates to:
  /// **'반응 시간 보정'**
  String get lyricsLatencyEntry;

  /// No description provided for @lyricsLatencyIntro.
  ///
  /// In ko, this message translates to:
  /// **'소리를 듣고 지금을 누르면 반응 시간만큼 늦게 찍혀요. 아래 값만큼 앞당겨 찍어요.'**
  String get lyricsLatencyIntro;

  /// No description provided for @lyricsLatencySeconds.
  ///
  /// In ko, this message translates to:
  /// **'{s}초'**
  String lyricsLatencySeconds(String s);

  /// No description provided for @lyricsLatencyReset.
  ///
  /// In ko, this message translates to:
  /// **'기본값 0.20초로'**
  String get lyricsLatencyReset;

  /// No description provided for @lyricsBeatTitle.
  ///
  /// In ko, this message translates to:
  /// **'박자 테스트'**
  String get lyricsBeatTitle;

  /// No description provided for @lyricsBeatBody.
  ///
  /// In ko, this message translates to:
  /// **'소리와 함께 원이 깜빡여요. 깜빡일 때마다 가운데 원을 누르세요. 8번 누르면 평균으로 추천 값을 알려 줘요.'**
  String get lyricsBeatBody;

  /// No description provided for @lyricsBeatIdle.
  ///
  /// In ko, this message translates to:
  /// **'시작을 누르세요'**
  String get lyricsBeatIdle;

  /// No description provided for @lyricsBeatProgress.
  ///
  /// In ko, this message translates to:
  /// **'{n}/{total}번'**
  String lyricsBeatProgress(int n, int total);

  /// No description provided for @lyricsBeatStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get lyricsBeatStart;

  /// No description provided for @lyricsBeatStop.
  ///
  /// In ko, this message translates to:
  /// **'멈추기'**
  String get lyricsBeatStop;

  /// No description provided for @lyricsBeatResult.
  ///
  /// In ko, this message translates to:
  /// **'추천 보정 {s}초'**
  String lyricsBeatResult(String s);

  /// No description provided for @lyricsBeatApply.
  ///
  /// In ko, this message translates to:
  /// **'이 값으로 적용'**
  String get lyricsBeatApply;

  /// No description provided for @lyricsBeatNote.
  ///
  /// In ko, this message translates to:
  /// **'기기마다 화면과 소리 지연이 달라서 안드로이드 기준이에요. 데스크톱은 오차가 클 수 있어요.'**
  String get lyricsBeatNote;

  /// No description provided for @lyricsSongCheckTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡으로 확인'**
  String get lyricsSongCheckTitle;

  /// No description provided for @lyricsSongCheckBody.
  ///
  /// In ko, this message translates to:
  /// **'곡을 들으며 소리가 시작되는 순간 찍어 보기를 눌러 보세요. 찍힌 위치부터 다시 들어 맞는지 확인해요.'**
  String get lyricsSongCheckBody;

  /// No description provided for @lyricsSongTry.
  ///
  /// In ko, this message translates to:
  /// **'찍어 보기'**
  String get lyricsSongTry;

  /// No description provided for @lyricsSongTried.
  ///
  /// In ko, this message translates to:
  /// **'찍힌 위치 {clock}'**
  String lyricsSongTried(String clock);

  /// No description provided for @lyricsSongListen.
  ///
  /// In ko, this message translates to:
  /// **'찍힌 위치부터 듣기'**
  String get lyricsSongListen;

  /// No description provided for @lyricsSyncSkipTitle.
  ///
  /// In ko, this message translates to:
  /// **'찍어 둔 싱크가 사라져요'**
  String get lyricsSyncSkipTitle;

  /// No description provided for @lyricsSyncSkipBody.
  ///
  /// In ko, this message translates to:
  /// **'묶을 범위 안에 이미 찍어 둔 싱크가 있어요. 한 칸으로 묶으면 그 싱크는 지워져요. 계속할까요?'**
  String get lyricsSyncSkipBody;

  /// No description provided for @lyricsSyncSkipConfirm.
  ///
  /// In ko, this message translates to:
  /// **'묶기'**
  String get lyricsSyncSkipConfirm;

  /// No description provided for @lyricsSyncResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'묶음이 사라져요'**
  String get lyricsSyncResetTitle;

  /// No description provided for @lyricsSyncResetBody.
  ///
  /// In ko, this message translates to:
  /// **'기본 줄 수를 바꾸면 직접 묶은 줄과 찍은 시간이 모두 사라져요. 계속할까요?'**
  String get lyricsSyncResetBody;

  /// No description provided for @lyricsSyncResetConfirm.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get lyricsSyncResetConfirm;

  /// No description provided for @lyricsSyncMerged.
  ///
  /// In ko, this message translates to:
  /// **'{n}줄 같은 시간으로 묶음'**
  String lyricsSyncMerged(int n);

  /// No description provided for @lyricsSyncUnmerge.
  ///
  /// In ko, this message translates to:
  /// **'풀기'**
  String get lyricsSyncUnmerge;

  /// No description provided for @playerLyricsExpand.
  ///
  /// In ko, this message translates to:
  /// **'가사만 크게 보기'**
  String get playerLyricsExpand;

  /// No description provided for @playerLyricsCollapse.
  ///
  /// In ko, this message translates to:
  /// **'가사 닫기'**
  String get playerLyricsCollapse;

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

  /// No description provided for @playlistFeaturedTitle.
  ///
  /// In ko, this message translates to:
  /// **'대표곡'**
  String get playlistFeaturedTitle;

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

  /// No description provided for @filterAllArtists.
  ///
  /// In ko, this message translates to:
  /// **'모든 아티스트'**
  String get filterAllArtists;

  /// No description provided for @filterAllAlbums.
  ///
  /// In ko, this message translates to:
  /// **'모든 앨범'**
  String get filterAllAlbums;

  /// No description provided for @filterAllGenres.
  ///
  /// In ko, this message translates to:
  /// **'모든 장르'**
  String get filterAllGenres;

  /// No description provided for @playlistAddTracks.
  ///
  /// In ko, this message translates to:
  /// **'곡 추가'**
  String get playlistAddTracks;

  /// No description provided for @playlistAddTracksTitle.
  ///
  /// In ko, this message translates to:
  /// **'곡 추가'**
  String get playlistAddTracksTitle;

  /// No description provided for @playlistAddTracksStart.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡 추가'**
  String playlistAddTracksStart(int count);

  /// No description provided for @playlistAddTracksEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'추가할 곡이 없어요'**
  String get playlistAddTracksEmptyTitle;

  /// No description provided for @playlistAddTracksEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'보관함의 곡이 모두 이 재생목록에 있거나 검색 결과가 없어요.'**
  String get playlistAddTracksEmptyBody;

  /// No description provided for @playlistDetailEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 담긴 곡이 없어요'**
  String get playlistDetailEmpty;

  /// No description provided for @playlistDetailEmptyFavorites.
  ///
  /// In ko, this message translates to:
  /// **'아직 좋아요한 곡이 없어요'**
  String get playlistDetailEmptyFavorites;

  /// No description provided for @playlistDetailEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'아래 ‘곡 추가’로 담아 보세요.'**
  String get playlistDetailEmptyBody;

  /// No description provided for @playlistDetailEmptyFavoritesBody.
  ///
  /// In ko, this message translates to:
  /// **'곡 메뉴에서 좋아요를 누르면 여기에 담겨요.'**
  String get playlistDetailEmptyFavoritesBody;

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

  /// No description provided for @playlistImportLoading.
  ///
  /// In ko, this message translates to:
  /// **'곡 목록을 읽는 중이에요'**
  String get playlistImportLoading;

  /// No description provided for @playlistImportSelectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{selected}/{total}곡 선택됨'**
  String playlistImportSelectedCount(int selected, int total);

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
  /// **'로그인하면 내 유튜브 재생목록을 불러올 수 있어요.'**
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

  /// No description provided for @playlistImportNoChannelTitle.
  ///
  /// In ko, this message translates to:
  /// **'유튜브 채널이 없어요'**
  String get playlistImportNoChannelTitle;

  /// No description provided for @playlistImportNoChannelBody.
  ///
  /// In ko, this message translates to:
  /// **'이 구글 계정에는 유튜브 채널이 없어서 내 재생목록을 불러올 수 없어요. 재생목록 링크를 위 입력창에 붙여 넣어 보세요. 비공개 목록은 일부 공개로 바꿔야 해요.'**
  String get playlistImportNoChannelBody;

  /// No description provided for @searchPlaylistFind.
  ///
  /// In ko, this message translates to:
  /// **'재생목록으로 찾기'**
  String get searchPlaylistFind;

  /// No description provided for @settingsPermissions.
  ///
  /// In ko, this message translates to:
  /// **'권한'**
  String get settingsPermissions;

  /// No description provided for @permNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get permNotifications;

  /// No description provided for @permNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'받기가 앱 밖에서도 이어지고 재생 알림이 보여요.'**
  String get permNotificationsDesc;

  /// No description provided for @permAudio.
  ///
  /// In ko, this message translates to:
  /// **'음악 파일 접근'**
  String get permAudio;

  /// No description provided for @permAudioDesc.
  ///
  /// In ko, this message translates to:
  /// **'기기에 있는 음악을 불러오는 데 써요.'**
  String get permAudioDesc;

  /// No description provided for @permOverlay.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 위에 표시'**
  String get permOverlay;

  /// No description provided for @permOverlayDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱을 쓰는 동안 화면 위에 가사를 띄우는 데 써요.'**
  String get permOverlayDesc;

  /// No description provided for @permBlockedDesc.
  ///
  /// In ko, this message translates to:
  /// **'요청이 막혀 있어요. 눌러서 휴대폰 설정에서 켜 주세요.'**
  String get permBlockedDesc;

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
  /// **'받는 동안 진행 상황을 알림창에 보여요.'**
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

  /// No description provided for @lyricsOverlayMinimize.
  ///
  /// In ko, this message translates to:
  /// **'숨기기'**
  String get lyricsOverlayMinimize;

  /// No description provided for @lyricsOverlayTurnOff.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get lyricsOverlayTurnOff;

  /// No description provided for @lyricsOverlayOn.
  ///
  /// In ko, this message translates to:
  /// **'오버레이 가사 켜기'**
  String get lyricsOverlayOn;

  /// No description provided for @lyricsOverlayOff.
  ///
  /// In ko, this message translates to:
  /// **'오버레이 가사 끄기'**
  String get lyricsOverlayOff;

  /// No description provided for @lyricsOverlayNoLyrics.
  ///
  /// In ko, this message translates to:
  /// **'가사가 없어요'**
  String get lyricsOverlayNoLyrics;

  /// No description provided for @lyricsOverlayNotSynced.
  ///
  /// In ko, this message translates to:
  /// **'싱크된 가사가 없어요'**
  String get lyricsOverlayNotSynced;

  /// No description provided for @lyricsOverlayNeedPermission.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 \"다른 앱 위에 표시\"를 허용한 뒤 다시 켜 주세요.'**
  String get lyricsOverlayNeedPermission;

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

  /// No description provided for @notifPreviewLabel.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기'**
  String get notifPreviewLabel;

  /// No description provided for @notifSleepAt.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 수면 타이머'**
  String notifSleepAt(String time);

  /// No description provided for @notifHiddenNote.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보 숨김'**
  String get notifHiddenNote;

  /// No description provided for @notifHiddenNotePosition.
  ///
  /// In ko, this message translates to:
  /// **'곡 정보 숨김 · {n}/{total}번째 곡'**
  String notifHiddenNotePosition(String n, String total);

  /// No description provided for @notifStop.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get notifStop;

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

  /// No description provided for @notifDownloadProgressNext.
  ///
  /// In ko, this message translates to:
  /// **'받는 중 · {percent}% · 다음 곡: {next}'**
  String notifDownloadProgressNext(int percent, String next);

  /// No description provided for @notifDownloadOverall.
  ///
  /// In ko, this message translates to:
  /// **'전체 {done}/{total}곡 · {percent}%'**
  String notifDownloadOverall(int done, int total, int percent);

  /// No description provided for @notifDownloadPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리듣기'**
  String get notifDownloadPreview;

  /// No description provided for @notifDownloadCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get notifDownloadCancel;

  /// No description provided for @notifDownloadPause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get notifDownloadPause;

  /// No description provided for @notifDownloadResume.
  ///
  /// In ko, this message translates to:
  /// **'이어받기'**
  String get notifDownloadResume;

  /// No description provided for @notifDownloadPausedBody.
  ///
  /// In ko, this message translates to:
  /// **'일시정지됨 · {percent}%'**
  String notifDownloadPausedBody(int percent);

  /// No description provided for @notifDownloadPausePreview.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get notifDownloadPausePreview;

  /// No description provided for @notifDownloadResumePreview.
  ///
  /// In ko, this message translates to:
  /// **'이어 듣기'**
  String get notifDownloadResumePreview;

  /// No description provided for @notifDownloadStopPreview.
  ///
  /// In ko, this message translates to:
  /// **'중지'**
  String get notifDownloadStopPreview;

  /// No description provided for @notifSavedDoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'보관 완료'**
  String get notifSavedDoneTitle;

  /// No description provided for @notifSavedDoneNote.
  ///
  /// In ko, this message translates to:
  /// **'보관함에서 바로 들을 수 있어요'**
  String get notifSavedDoneNote;

  /// No description provided for @notifSavedDoneHidden.
  ///
  /// In ko, this message translates to:
  /// **'음원 저장이 끝났어요'**
  String get notifSavedDoneHidden;

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

  /// No description provided for @notifSaveLocation.
  ///
  /// In ko, this message translates to:
  /// **'저장 위치: {path}'**
  String notifSaveLocation(String path);

  /// No description provided for @notifSaveLocationCache.
  ///
  /// In ko, this message translates to:
  /// **'저장 위치: 앱 보관(캐시)'**
  String get notifSaveLocationCache;

  /// No description provided for @notifSaveLocationDefault.
  ///
  /// In ko, this message translates to:
  /// **'저장 위치: 기본 폴더'**
  String get notifSaveLocationDefault;

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

  /// No description provided for @subscribeAction.
  ///
  /// In ko, this message translates to:
  /// **'구독'**
  String get subscribeAction;

  /// No description provided for @subscribedAction.
  ///
  /// In ko, this message translates to:
  /// **'구독 중'**
  String get subscribedAction;

  /// No description provided for @subscribeAdded.
  ///
  /// In ko, this message translates to:
  /// **'구독했어요. 지금부터 올라오는 영상을 알려 드려요'**
  String get subscribeAdded;

  /// No description provided for @subscribeFailed.
  ///
  /// In ko, this message translates to:
  /// **'이 채널은 구독할 수 없어요'**
  String get subscribeFailed;

  /// No description provided for @unsubscribed.
  ///
  /// In ko, this message translates to:
  /// **'구독을 해제했어요'**
  String get unsubscribed;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독 채널'**
  String get subscriptionsTitle;

  /// No description provided for @subscriptionsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'새 영상 골라 받기'**
  String get subscriptionsSubtitle;

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독한 채널이 없어요'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'영상 상세에서 채널을 구독하면 새 영상이 올라올 때 골라서 받을 수 있어요.'**
  String get subscriptionsEmptyBody;

  /// No description provided for @subscriptionsNewVideos.
  ///
  /// In ko, this message translates to:
  /// **'새 영상 보기'**
  String get subscriptionsNewVideos;

  /// No description provided for @subscriptionsUnsubscribe.
  ///
  /// In ko, this message translates to:
  /// **'구독 해제'**
  String get subscriptionsUnsubscribe;

  /// No description provided for @subscriptionsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 채널'**
  String subscriptionsCount(int count);

  /// No description provided for @newVideosTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 영상'**
  String get newVideosTitle;

  /// No description provided for @newVideosChecking.
  ///
  /// In ko, this message translates to:
  /// **'새 영상을 확인하고 있어요'**
  String get newVideosChecking;

  /// No description provided for @newVideosEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 영상이 없어요'**
  String get newVideosEmptyTitle;

  /// No description provided for @newVideosEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'구독한 채널에 새 영상이 올라오면 여기에서 골라 받을 수 있어요.'**
  String get newVideosEmptyBody;

  /// No description provided for @newVideosSummary.
  ///
  /// In ko, this message translates to:
  /// **'채널 {channels}개 · 영상 {videos}개'**
  String newVideosSummary(int channels, int videos);

  /// No description provided for @newVideosStart.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡 받기'**
  String newVideosStart(int count);

  /// No description provided for @newVideosStarted.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡을 받기 시작했어요'**
  String newVideosStarted(int count);

  /// No description provided for @newVideosSkipped.
  ///
  /// In ko, this message translates to:
  /// **'이미 받은 곡이라 새로 받을 곡이 없어요'**
  String get newVideosSkipped;

  /// No description provided for @newVideosClear.
  ///
  /// In ko, this message translates to:
  /// **'비우기'**
  String get newVideosClear;

  /// No description provided for @newVideosClearTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 영상 목록을 비울까요?'**
  String get newVideosClearTitle;

  /// No description provided for @newVideosClearBody.
  ///
  /// In ko, this message translates to:
  /// **'받지 않은 영상도 목록에서 사라지고 다시 뜨지 않아요. 이후 올라오는 영상만 새 영상으로 보여요.'**
  String get newVideosClearBody;

  /// No description provided for @newVideosSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 선택'**
  String get newVideosSelectAll;

  /// No description provided for @newVideosSelectNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get newVideosSelectNone;

  /// No description provided for @newVideosAnnounce.
  ///
  /// In ko, this message translates to:
  /// **'구독 채널에 새 영상이 {count}개 있어요'**
  String newVideosAnnounce(int count);

  /// No description provided for @newVideosOpen.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get newVideosOpen;

  /// No description provided for @settingsSubscriptions.
  ///
  /// In ko, this message translates to:
  /// **'구독'**
  String get settingsSubscriptions;

  /// No description provided for @settingsSubscriptionChannels.
  ///
  /// In ko, this message translates to:
  /// **'구독 채널'**
  String get settingsSubscriptionChannels;

  /// No description provided for @settingsCheckOnLaunch.
  ///
  /// In ko, this message translates to:
  /// **'앱을 켤 때 새 영상 확인'**
  String get settingsCheckOnLaunch;

  /// No description provided for @settingsCheckOnLaunchDesc.
  ///
  /// In ko, this message translates to:
  /// **'구독한 채널에 새 영상이 있으면 알려 주고 골라서 받게 해요.'**
  String get settingsCheckOnLaunchDesc;

  /// No description provided for @settingsBackgroundCheck.
  ///
  /// In ko, this message translates to:
  /// **'앱이 꺼져 있어도 확인'**
  String get settingsBackgroundCheck;

  /// No description provided for @settingsBackgroundCheckDesc.
  ///
  /// In ko, this message translates to:
  /// **'주기적으로 확인하고 새 영상이 있으면 알림으로 알려요.'**
  String get settingsBackgroundCheckDesc;

  /// No description provided for @settingsCheckInterval.
  ///
  /// In ko, this message translates to:
  /// **'확인 주기'**
  String get settingsCheckInterval;

  /// No description provided for @settingsCheckIntervalHours.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간'**
  String settingsCheckIntervalHours(int count);

  /// No description provided for @settingsCheckWifiOnly.
  ///
  /// In ko, this message translates to:
  /// **'와이파이에서만 확인'**
  String get settingsCheckWifiOnly;

  /// No description provided for @settingsCheckWifiOnlyDesc.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 쓰지 않도록 와이파이에 연결됐을 때만 확인해요.'**
  String get settingsCheckWifiOnlyDesc;

  /// No description provided for @settingsCheckNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 확인'**
  String get settingsCheckNow;

  /// No description provided for @settingsCheckNowChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인하는 중…'**
  String get settingsCheckNowChecking;

  /// No description provided for @settingsCheckStatusNever.
  ///
  /// In ko, this message translates to:
  /// **'아직 확인한 적이 없어요.'**
  String get settingsCheckStatusNever;

  /// No description provided for @settingsCheckStatusLast.
  ///
  /// In ko, this message translates to:
  /// **'마지막 확인 {time}'**
  String settingsCheckStatusLast(String time);

  /// No description provided for @settingsCheckStatusNotified.
  ///
  /// In ko, this message translates to:
  /// **'새 영상 {count}개를 알렸어요.'**
  String settingsCheckStatusNotified(int count);

  /// No description provided for @settingsCheckStatusFailed.
  ///
  /// In ko, this message translates to:
  /// **'채널 {count}개를 읽지 못했어요.'**
  String settingsCheckStatusFailed(int count);

  /// No description provided for @settingsCheckStatusBlocked.
  ///
  /// In ko, this message translates to:
  /// **'알림이 꺼져 있어 알리지 못했어요. 기기 설정에서 Mulo 알림(새 영상 포함)을 켜 주세요.'**
  String get settingsCheckStatusBlocked;

  /// No description provided for @settingsCheckStatusNotScheduled.
  ///
  /// In ko, this message translates to:
  /// **'주기 확인이 예약되지 않았어요. 위 스위치를 껐다 켜 보세요.'**
  String get settingsCheckStatusNotScheduled;

  /// No description provided for @notifChannelNewVideos.
  ///
  /// In ko, this message translates to:
  /// **'새 영상'**
  String get notifChannelNewVideos;

  /// No description provided for @notifNewVideosTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독 채널에 새 영상이 올라왔어요'**
  String get notifNewVideosTitle;

  /// No description provided for @notifNewVideosBody.
  ///
  /// In ko, this message translates to:
  /// **'{channels} · 새 영상 {count}개'**
  String notifNewVideosBody(String channels, String count);

  /// No description provided for @channelSearchTitle.
  ///
  /// In ko, this message translates to:
  /// **'채널 검색'**
  String get channelSearchTitle;

  /// No description provided for @channelSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'채널 이름으로 찾기'**
  String get channelSearchHint;

  /// No description provided for @channelSearchIdle.
  ///
  /// In ko, this message translates to:
  /// **'구독할 채널 이름을 검색해 보세요'**
  String get channelSearchIdle;

  /// No description provided for @channelSearchLoading.
  ///
  /// In ko, this message translates to:
  /// **'채널을 찾는 중이에요'**
  String get channelSearchLoading;

  /// No description provided for @channelSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'찾은 채널이 없어요'**
  String get channelSearchEmpty;

  /// No description provided for @channelSearchFailed.
  ///
  /// In ko, this message translates to:
  /// **'채널을 찾지 못했어요. 잠시 뒤 다시 시도해 주세요'**
  String get channelSearchFailed;

  /// No description provided for @categoryAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 분류'**
  String get categoryAll;

  /// No description provided for @subscriptionsCategories.
  ///
  /// In ko, this message translates to:
  /// **'알림 받을 분류'**
  String get subscriptionsCategories;

  /// No description provided for @subscriptionsCategoriesDesc.
  ///
  /// In ko, this message translates to:
  /// **'고른 분류의 새 영상만 알리고 보여 줘요. 고르지 않으면 모든 분류예요.'**
  String get subscriptionsCategoriesDesc;

  /// No description provided for @channelInfoVideoCount.
  ///
  /// In ko, this message translates to:
  /// **'영상 {count}개'**
  String channelInfoVideoCount(int count);

  /// No description provided for @channelSaveFolder.
  ///
  /// In ko, this message translates to:
  /// **'저장 위치'**
  String get channelSaveFolder;

  /// No description provided for @channelSaveFolderDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 저장 위치'**
  String get channelSaveFolderDefault;

  /// No description provided for @channelSaveFolderChange.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get channelSaveFolderChange;

  /// No description provided for @channelSaveFolderReset.
  ///
  /// In ko, this message translates to:
  /// **'기본으로'**
  String get channelSaveFolderReset;

  /// No description provided for @notifNewVideoDownloadNow.
  ///
  /// In ko, this message translates to:
  /// **'바로 받기'**
  String get notifNewVideoDownloadNow;

  /// No description provided for @equalizerTitle.
  ///
  /// In ko, this message translates to:
  /// **'이퀄라이저'**
  String get equalizerTitle;

  /// No description provided for @equalizerOn.
  ///
  /// In ko, this message translates to:
  /// **'켜짐'**
  String get equalizerOn;

  /// No description provided for @equalizerOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get equalizerOff;

  /// No description provided for @equalizerUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 이퀄라이저를 쓸 수 없어요'**
  String get equalizerUnsupported;

  /// No description provided for @equalizerEnable.
  ///
  /// In ko, this message translates to:
  /// **'이퀄라이저 사용'**
  String get equalizerEnable;

  /// No description provided for @equalizerEnableDesc.
  ///
  /// In ko, this message translates to:
  /// **'켜면 아래 설정대로 소리를 다듬어요. 기본은 꺼짐이에요.'**
  String get equalizerEnableDesc;

  /// No description provided for @equalizerDeviceProfile.
  ///
  /// In ko, this message translates to:
  /// **'이 기기 전용으로 저장'**
  String get equalizerDeviceProfile;

  /// No description provided for @equalizerDeviceProfileDesc.
  ///
  /// In ko, this message translates to:
  /// **'{device}에 연결되면 이 설정을 자동으로 적용해요.'**
  String equalizerDeviceProfileDesc(String device);

  /// No description provided for @equalizerMyPresets.
  ///
  /// In ko, this message translates to:
  /// **'내 프리셋'**
  String get equalizerMyPresets;

  /// No description provided for @equalizerMyPresetsHint.
  ///
  /// In ko, this message translates to:
  /// **'길게 누르면 지워요'**
  String get equalizerMyPresetsHint;

  /// No description provided for @equalizerPresetSaveNew.
  ///
  /// In ko, this message translates to:
  /// **'지금 값 저장'**
  String get equalizerPresetSaveNew;

  /// No description provided for @equalizerPresetNameTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름'**
  String get equalizerPresetNameTitle;

  /// No description provided for @equalizerPresetNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 이어폰용, 차량용'**
  String get equalizerPresetNameHint;

  /// No description provided for @equalizerPresetSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get equalizerPresetSave;

  /// No description provided for @equalizerPresetDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 지우기'**
  String get equalizerPresetDeleteTitle;

  /// No description provided for @equalizerPresetDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 프리셋을 지워요. 이 프리셋을 지정한 기기는 마지막 값을 그대로 써요'**
  String equalizerPresetDeleteBody(String name);

  /// No description provided for @equalizerDevicesTitle.
  ///
  /// In ko, this message translates to:
  /// **'기기별 이퀄라이저'**
  String get equalizerDevicesTitle;

  /// No description provided for @equalizerDevicesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 연결된 블루투스 · 이어폰 기기가 없어요'**
  String get equalizerDevicesEmpty;

  /// No description provided for @equalizerDeviceDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 설정'**
  String get equalizerDeviceDefault;

  /// No description provided for @equalizerDeviceCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 설정'**
  String get equalizerDeviceCustom;

  /// No description provided for @equalizerDeviceEdit.
  ///
  /// In ko, this message translates to:
  /// **'이퀄라이저에서 직접 설정'**
  String get equalizerDeviceEdit;

  /// No description provided for @equalizerEditingDevice.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에 쓸 값을 고치는 중이에요'**
  String get equalizerEditingDevice;

  /// No description provided for @equalizerDeviceCurrent.
  ///
  /// In ko, this message translates to:
  /// **'지금 연결됨'**
  String get equalizerDeviceCurrent;

  /// No description provided for @equalizerDevicePickTitle.
  ///
  /// In ko, this message translates to:
  /// **'{device}에 쓸 프리셋'**
  String equalizerDevicePickTitle(String device);

  /// No description provided for @equalizerDeviceNoPresets.
  ///
  /// In ko, this message translates to:
  /// **'이퀄라이저 화면에서 \"지금 값 저장\"으로 프리셋을 먼저 만들어 주세요'**
  String get equalizerDeviceNoPresets;

  /// No description provided for @equalizerPreset.
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get equalizerPreset;

  /// No description provided for @equalizerBands.
  ///
  /// In ko, this message translates to:
  /// **'대역별 조절'**
  String get equalizerBands;

  /// No description provided for @equalizerBassBoost.
  ///
  /// In ko, this message translates to:
  /// **'저음 강화'**
  String get equalizerBassBoost;

  /// No description provided for @equalizerBassBoostDesc.
  ///
  /// In ko, this message translates to:
  /// **'낮은 소리를 더 묵직하게 해요.'**
  String get equalizerBassBoostDesc;

  /// No description provided for @equalizerReset.
  ///
  /// In ko, this message translates to:
  /// **'처음으로'**
  String get equalizerReset;

  /// No description provided for @equalizerPresetFlat.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get equalizerPresetFlat;

  /// No description provided for @equalizerPresetBass.
  ///
  /// In ko, this message translates to:
  /// **'저음 강조'**
  String get equalizerPresetBass;

  /// No description provided for @equalizerPresetTreble.
  ///
  /// In ko, this message translates to:
  /// **'고음 강조'**
  String get equalizerPresetTreble;

  /// No description provided for @equalizerPresetVocal.
  ///
  /// In ko, this message translates to:
  /// **'보컬'**
  String get equalizerPresetVocal;

  /// No description provided for @equalizerPresetRock.
  ///
  /// In ko, this message translates to:
  /// **'록'**
  String get equalizerPresetRock;

  /// No description provided for @equalizerPresetPop.
  ///
  /// In ko, this message translates to:
  /// **'팝'**
  String get equalizerPresetPop;

  /// No description provided for @equalizerPresetJazz.
  ///
  /// In ko, this message translates to:
  /// **'재즈'**
  String get equalizerPresetJazz;

  /// No description provided for @equalizerPresetClassical.
  ///
  /// In ko, this message translates to:
  /// **'클래식'**
  String get equalizerPresetClassical;

  /// No description provided for @equalizerPresetDance.
  ///
  /// In ko, this message translates to:
  /// **'힙합 · EDM'**
  String get equalizerPresetDance;

  /// No description provided for @equalizerPresetCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 조절'**
  String get equalizerPresetCustom;

  /// No description provided for @equalizerVirtualizer.
  ///
  /// In ko, this message translates to:
  /// **'입체 음향'**
  String get equalizerVirtualizer;

  /// No description provided for @equalizerVirtualizerDesc.
  ///
  /// In ko, this message translates to:
  /// **'이어폰에서 소리가 더 넓게 퍼져 들려요.'**
  String get equalizerVirtualizerDesc;

  /// No description provided for @equalizerReverb.
  ///
  /// In ko, this message translates to:
  /// **'공간 울림'**
  String get equalizerReverb;

  /// No description provided for @equalizerReverbDesc.
  ///
  /// In ko, this message translates to:
  /// **'방이나 홀에서 듣는 것 같은 잔향을 더해요.'**
  String get equalizerReverbDesc;

  /// No description provided for @equalizerLimiter.
  ///
  /// In ko, this message translates to:
  /// **'소리 찢어짐 방지'**
  String get equalizerLimiter;

  /// No description provided for @equalizerLimiterDesc.
  ///
  /// In ko, this message translates to:
  /// **'소리를 많이 키워도 갈라지지 않게 눌러 줘요.'**
  String get equalizerLimiterDesc;

  /// No description provided for @equalizerReverbNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get equalizerReverbNone;

  /// No description provided for @equalizerReverbSmallRoom.
  ///
  /// In ko, this message translates to:
  /// **'작은 방'**
  String get equalizerReverbSmallRoom;

  /// No description provided for @equalizerReverbMediumRoom.
  ///
  /// In ko, this message translates to:
  /// **'중간 방'**
  String get equalizerReverbMediumRoom;

  /// No description provided for @equalizerReverbLargeRoom.
  ///
  /// In ko, this message translates to:
  /// **'큰 방'**
  String get equalizerReverbLargeRoom;

  /// No description provided for @equalizerReverbMediumHall.
  ///
  /// In ko, this message translates to:
  /// **'중간 홀'**
  String get equalizerReverbMediumHall;

  /// No description provided for @equalizerReverbLargeHall.
  ///
  /// In ko, this message translates to:
  /// **'큰 홀'**
  String get equalizerReverbLargeHall;

  /// No description provided for @equalizerReverbPlate.
  ///
  /// In ko, this message translates to:
  /// **'플레이트'**
  String get equalizerReverbPlate;

  /// No description provided for @equalizerSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get equalizerSave;

  /// No description provided for @audioLanguageTitle.
  ///
  /// In ko, this message translates to:
  /// **'오디오 언어'**
  String get audioLanguageTitle;

  /// No description provided for @audioLanguageRow.
  ///
  /// In ko, this message translates to:
  /// **'오디오 언어'**
  String get audioLanguageRow;

  /// No description provided for @audioLanguageOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원본'**
  String get audioLanguageOriginal;

  /// No description provided for @audioLanguageHint.
  ///
  /// In ko, this message translates to:
  /// **'고르면 바로 적용돼요. 미리 듣기와 받기에 같은 언어를 써요.'**
  String get audioLanguageHint;

  /// No description provided for @downloadAgainTitle.
  ///
  /// In ko, this message translates to:
  /// **'다시 받을까요?'**
  String get downloadAgainTitle;

  /// No description provided for @downloadAgainBody.
  ///
  /// In ko, this message translates to:
  /// **'이미 받은 곡이에요. 다시 받으면 같은 곡이 하나 더 생겨요.'**
  String get downloadAgainBody;

  /// No description provided for @downloadAgainConfirm.
  ///
  /// In ko, this message translates to:
  /// **'다시 받기'**
  String get downloadAgainConfirm;

  /// No description provided for @selectCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡 선택'**
  String selectCount(int count);

  /// No description provided for @selectClose.
  ///
  /// In ko, this message translates to:
  /// **'선택 끝내기'**
  String get selectClose;

  /// No description provided for @selectAssignAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범 지정'**
  String get selectAssignAlbum;

  /// No description provided for @selectAssignArtist.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 지정'**
  String get selectAssignArtist;

  /// No description provided for @selectAssignGenre.
  ///
  /// In ko, this message translates to:
  /// **'장르 지정'**
  String get selectAssignGenre;

  /// No description provided for @selectAssignAlbumTitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범 바꾸기'**
  String get selectAssignAlbumTitle;

  /// No description provided for @selectAssignArtistTitle.
  ///
  /// In ko, this message translates to:
  /// **'아티스트 바꾸기'**
  String get selectAssignArtistTitle;

  /// No description provided for @selectAssignGenreTitle.
  ///
  /// In ko, this message translates to:
  /// **'장르 바꾸기'**
  String get selectAssignGenreTitle;

  /// No description provided for @selectConfirmAlbum.
  ///
  /// In ko, this message translates to:
  /// **'고른 {count}곡의 앨범을 바꿀까요?\n\n새 앨범: {value}\n\n이 곡들은 다른 앨범에서 빠지고, 음악 파일 정보도 함께 바뀌어요.'**
  String selectConfirmAlbum(int count, String value);

  /// No description provided for @selectConfirmArtist.
  ///
  /// In ko, this message translates to:
  /// **'고른 {count}곡의 아티스트를 바꿀까요?\n\n새 아티스트: {value}\n\n이 곡들은 다른 아티스트에서 빠지고, 음악 파일 정보도 함께 바뀌어요.'**
  String selectConfirmArtist(int count, String value);

  /// No description provided for @selectConfirmGenre.
  ///
  /// In ko, this message translates to:
  /// **'고른 {count}곡의 장르를 바꿀까요?\n\n새 장르: {value}\n\n이 곡들은 다른 장르에서 빠지고, 음악 파일 정보도 함께 바뀌어요.'**
  String selectConfirmGenre(int count, String value);

  /// No description provided for @selectConfirmApply.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get selectConfirmApply;

  /// No description provided for @selectAssignPartial.
  ///
  /// In ko, this message translates to:
  /// **'{count}곡은 음악 파일에 정보를 쓰지 못해 바꾸지 않았어요.'**
  String selectAssignPartial(int count);

  /// No description provided for @selectActions.
  ///
  /// In ko, this message translates to:
  /// **'작업'**
  String get selectActions;

  /// No description provided for @selectAssignHintAlbum.
  ///
  /// In ko, this message translates to:
  /// **'고른 곡 모두에 넣을 앨범 이름을 적어요. 비워 두면 앨범 정보가 없는 곡이 돼요.'**
  String get selectAssignHintAlbum;

  /// No description provided for @selectAssignHintArtist.
  ///
  /// In ko, this message translates to:
  /// **'고른 곡 모두에 넣을 아티스트 이름을 적어요. 비워 두면 아티스트 정보가 없는 곡이 돼요.'**
  String get selectAssignHintArtist;

  /// No description provided for @selectAssignHintGenre.
  ///
  /// In ko, this message translates to:
  /// **'고른 곡 모두에 넣을 장르를 적어요. 비워 두면 장르 정보가 없는 곡이 돼요.'**
  String get selectAssignHintGenre;

  /// No description provided for @selectNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get selectNext;

  /// No description provided for @playlistImportChannels.
  ///
  /// In ko, this message translates to:
  /// **'구독 채널의 재생목록'**
  String get playlistImportChannels;

  /// No description provided for @channelPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'채널 고르기'**
  String get channelPickTitle;

  /// No description provided for @channelPickEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 구독한 채널이 없어요. 아래에서 내 YouTube 구독 채널을 가져올 수 있어요.'**
  String get channelPickEmpty;

  /// No description provided for @channelPlaylistsUploads.
  ///
  /// In ko, this message translates to:
  /// **'업로드한 영상 전체'**
  String get channelPlaylistsUploads;

  /// No description provided for @channelImportOpen.
  ///
  /// In ko, this message translates to:
  /// **'내 YouTube 구독에서 채널 고르기'**
  String get channelImportOpen;

  /// No description provided for @channelImportTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 구독 채널'**
  String get channelImportTitle;

  /// No description provided for @channelImportHint.
  ///
  /// In ko, this message translates to:
  /// **'구독할 채널을 눌러 골라요. 고른 채널만 추가돼요.'**
  String get channelImportHint;

  /// No description provided for @channelImportAlready.
  ///
  /// In ko, this message translates to:
  /// **'구독 중'**
  String get channelImportAlready;

  /// No description provided for @channelImportLoading.
  ///
  /// In ko, this message translates to:
  /// **'구독 채널 {count}개 불러오는 중…'**
  String channelImportLoading(int count);

  /// No description provided for @channelImportEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독한 채널이 없어요'**
  String get channelImportEmptyTitle;

  /// No description provided for @channelImportEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'이 구글 계정으로 YouTube에서 구독한 채널이 없어요.'**
  String get channelImportEmptyBody;

  /// No description provided for @channelImportSignInBody.
  ///
  /// In ko, this message translates to:
  /// **'내 YouTube 구독 채널을 불러오려면 구글 로그인이 필요해요.'**
  String get channelImportSignInBody;

  /// No description provided for @channelImportSelectCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 채널 선택'**
  String channelImportSelectCount(int count);

  /// No description provided for @channelImportSelectNew.
  ///
  /// In ko, this message translates to:
  /// **'새 채널 모두 선택'**
  String get channelImportSelectNew;

  /// No description provided for @channelImportSubscribe.
  ///
  /// In ko, this message translates to:
  /// **'고른 채널 구독하기'**
  String get channelImportSubscribe;

  /// No description provided for @channelImportConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'채널 구독'**
  String get channelImportConfirmTitle;

  /// No description provided for @channelImportConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'고른 {count}개 채널을 구독할까요? 지금부터 올라오는 영상을 알려 드려요.'**
  String channelImportConfirmBody(int count);

  /// No description provided for @channelImportDone.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 채널을 구독했어요'**
  String channelImportDone(int count);
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
