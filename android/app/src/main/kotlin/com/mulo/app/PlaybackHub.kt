package com.mulo.app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * 재생의 주인: 소리를 내는 ExoPlayer, 미디어 세션, 알림 서비스 연결을 프로세스에 하나씩 쥔다.
 * 대기열(순서가 정해진 목록 · 현재 위치 · 반복)도 ExoPlayer가 쥐고 곡 넘김을 스스로 한다:
 * Flutter 화면(MainActivity)이 사라져도 서비스가 살아 있는 한 다음 곡으로 이어지고, 앱이 다시 켜지면 [getState]로 돌려받는다.
 * 대기열의 규칙(셔플 · 다음에 재생 · 이동 · 삭제)은 앱(Dart)이 정해 스냅샷으로 보낸다 ([setQueue]).
 * 앱(Dart)에는 [PlaybackChannel]로 명령을 받고 이벤트를 돌려준다. 모든 호출은 메인 스레드.
 */
object PlaybackHub {
    private const val RESUME_WINDOW_MS = 10 * 60 * 1000L
    private const val ACTION_FAVORITE = "com.mulo.app.FAVORITE"
    private const val ACTION_CLOSE = "com.mulo.app.CLOSE"
    private const val ACTION_SHUFFLE = "com.mulo.app.SHUFFLE"
    const val ACTION_OPEN_PLAYER = "com.mulo.app.OPEN_PLAYER"
    private val favoriteCommand = SessionCommand(ACTION_FAVORITE, Bundle.EMPTY)
    private val closeCommand = SessionCommand(ACTION_CLOSE, Bundle.EMPTY)
    private val shuffleCommand = SessionCommand(ACTION_SHUFFLE, Bundle.EMPTY)

    private lateinit var context: Context
    private val main = Handler(Looper.getMainLooper())

    lateinit var exo: ExoPlayer
        private set
    lateinit var sessionPlayer: SessionPlayer
        private set

    /** 미디어 세션. 알림을 지웠거나 재생을 끝낸 뒤에는 정리(release)되어 null이고, 다시 재생하면 새로 만든다. */
    var session: MediaSession? = null
        private set

    /** 알림 서비스 (떠 있을 때만). */
    var service: MuloPlaybackService? = null

    /** 알림을 보여 줄지 (Dart가 알림을 끄면 false). */
    var isNotificationVisible = false
        private set

    /**
     * 사용자가 알림을 지웠거나(닫기 · 밀어서 지우기) 재생을 끝낸 상태: 세션을 정리해 두고,
     * 앱에서 다시 재생하기 전까지 알림을 띄우지 않으며 블루투스 · 이어폰 버튼도 받지 않는다.
     */
    private var dismissed = false

    /** 미디어 버튼을 무시해야 하는 상태인지 (서비스가 새로 떴을 때 확인한다). */
    val isGated get() = dismissed && !resumeWithoutNotification

    /** 알림을 지운 뒤에도 버튼으로 이어 재생하는 설정. */
    private var resumeWithoutNotification = true

    /** 저장해 둔 대기열로 되살린 상태: 앱(Dart)이 아직 알림 내용을 보내기 전이라 좋아요 버튼은 숨긴다. */
    private var restoredFromStore = false

    /** 이어폰 분리 · 블루투스 끊김으로 멈춘 시각 (SystemClock). 0이면 그렇게 멈춘 게 아니다. */
    private var pausedByNoisyAt = 0L
    private var resumeOnConnect = false
    private var tickCount = 0

    private var sink: EventChannel.EventSink? = null
    private var pendingLoad: MethodChannel.Result? = null
    private var initialized = false

    /** 앱(Dart)만 해석하는 문자열 (셔플 여부 · 섞기 전 순서). 그대로 보관했다가 돌려준다. */
    private var extras = ""

    /** 직전에 재생하던 곡의 id (한 바퀴 돌아 첫 곡으로 넘어왔는지 알아보려고). */
    private var lastMediaId: String? = null

    /** 대기열 곡별 커버 주소 (곡 id → 주소). 앱이 꺼진 사이 곡이 넘어가도 알림에 커버가 나오게 한다. */
    private var artById = mapOf<String, String>()

    /** 알림을 눌러 앱이 새로 켜졌는데 Dart가 아직 받아 가지 않은 요청. */
    private var openPlayerRequested = false

    fun init(appContext: Context) {
        if (initialized) return
        initialized = true
        context = appContext.applicationContext

        // 공간 울림은 오디오 출력 앞단의 프로세서로 처리한다 (기기 효과보다 확실히 들린다).
        val renderers = object : DefaultRenderersFactory(context) {
            override fun buildAudioSink(
                context: Context,
                enableFloatOutput: Boolean,
                enableAudioTrackPlaybackParams: Boolean,
            ): AudioSink = DefaultAudioSink.Builder(context)
                .setEnableFloatOutput(enableFloatOutput)
                .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
                .setAudioProcessors(arrayOf<AudioProcessor>(EqualizerEngine.reverbProcessor))
                .build()
        }
        exo = ExoPlayer.Builder(context, renderers)
            // 다른 앱이 소리를 가져가면(영상, 통화) 멈추고, 이어폰이 빠지면 멈춘다.
            .setAudioAttributes(
                AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
                true,
            )
            .setHandleAudioBecomingNoisy(PlaybackStore.pauseOnDisconnect(context))
            .setWakeMode(C.WAKE_MODE_LOCAL)
            .build()
        exo.addListener(playerListener)
        exo.setPlaybackSpeed(PlaybackStore.speed(context))
        EqualizerEngine.attach(exo.audioSessionId)
        // 앱 없이 프로세스가 새로 떠도 지금 출력 기기에 맞는 이퀄라이저 값을 적용한다.
        EqualizerProfiles.applyCurrent(context)

        sessionPlayer = SessionPlayer(exo) { name, positionMs -> emitCommand(name, positionMs) }
        resumeOnConnect = PlaybackStore.resumeOnConnect(context)
        resumeWithoutNotification = PlaybackStore.resumeWithoutNotification(context)
        (context.getSystemService(Context.AUDIO_SERVICE) as AudioManager)
            .registerAudioDeviceCallback(deviceCallback, main)

        // 프로세스가 새로 떴다면 저장해 둔 대기열을 되살린다 (블루투스 버튼 · 앱 재시작으로 이어 재생).
        val stored = PlaybackStore.load(context)
        if (stored != null) {
            restore(stored)
            dismissed = !stored.resumable
            // 이어 재생할 수 있는 상태면 서비스가 뜰 때 알림에도 올린다.
            isNotificationVisible = stored.resumable
        }
        if (!dismissed) buildSession()
    }

    private fun buildSession() {
        val builder = MediaSession.Builder(context, sessionPlayer)
            .setId("mulo")
            .setCallback(sessionCallback)
        // 알림을 누르면 앱을 열고 현재 곡의 플레이어 화면으로 간다.
        val open = Intent(context, MainActivity::class.java)
            .setAction(ACTION_OPEN_PLAYER)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        builder.setSessionActivity(
            PendingIntent.getActivity(context, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT),
        )
        session = builder.build()
        refreshLayout()
    }

    private fun releaseSession() {
        session?.release()
        session = null
    }

    /** 저장해 둔 대기열을 플레이어에 올린다. 소리는 내지 않고(일시정지), 재생이 시작될 때 준비한다. */
    private fun restore(stored: StoredPlayback) {
        extras = stored.extras
        artById = stored.items.mapNotNull { i -> i.art?.let { i.id to it } }.toMap()
        exo.repeatMode = repeatModeOf(stored.repeat)
        exo.setMediaItems(
            stored.items.map { i ->
                val metadata = MediaMetadata.Builder()
                    .setTitle(i.title)
                    .setArtist(i.artist.ifEmpty { null })
                    .setAlbumTitle(i.album.ifEmpty { null })
                    .setDurationMs(i.durationMs.takeIf { it > 0 })
                    .setArtworkUri(i.art?.let { Uri.parse(it) })
                    .build()
                MediaItem.Builder().setMediaId(i.id).setUri(i.uri).setMediaMetadata(metadata).build()
            },
            stored.index,
            stored.positionMs,
        )
        exo.playWhenReady = false
        val saved = SessionInfo(stored.session ?: emptyMap<String, Any?>())
        // 저장된 알림 내용은 미리 듣기가 아닌 메인 재생의 것만 쓴다.
        sessionPlayer.info = if (saved.preview) SessionInfo(emptyMap<String, Any?>()) else saved
        restoredFromStore = true
    }

    // ── 저장 ──

    private fun persistQueue() {
        if (!initialized) return
        if (exo.mediaItemCount == 0) {
            PlaybackStore.clear(context)
            return
        }
        val items = (0 until exo.mediaItemCount).map { i ->
            val item = exo.getMediaItemAt(i)
            StoredItem(
                id = item.mediaId,
                uri = item.localConfiguration?.uri?.toString() ?: "",
                title = item.mediaMetadata.title?.toString() ?: "",
                artist = item.mediaMetadata.artist?.toString() ?: "",
                album = item.mediaMetadata.albumTitle?.toString() ?: "",
                durationMs = item.mediaMetadata.durationMs ?: 0L,
                art = item.mediaMetadata.artworkUri?.toString(),
            )
        }
        PlaybackStore.saveQueue(context, items, extras)
        persistPosition()
        syncResumable()
    }

    private fun persistPosition() {
        if (!initialized || exo.mediaItemCount == 0) return
        PlaybackStore.savePosition(context, exo.currentMediaItemIndex, exo.currentPosition, repeatNameOf(exo.repeatMode))
    }

    /** 이어 재생해도 되는 상태인지 저장한다: 알림을 지우지 않았고 대기열이 있을 때. */
    private fun syncResumable() {
        PlaybackStore.setResumable(context, (!dismissed || resumeWithoutNotification) && exo.mediaItemCount > 0)
    }

    // ── Dart → 네이티브 ──

    private fun repeatModeOf(name: String?) = when (name) {
        "all" -> Player.REPEAT_MODE_ALL
        "one" -> Player.REPEAT_MODE_ONE
        else -> Player.REPEAT_MODE_OFF
    }

    private fun repeatNameOf(mode: Int) = when (mode) {
        Player.REPEAT_MODE_ALL -> "all"
        Player.REPEAT_MODE_ONE -> "one"
        else -> "off"
    }

    private fun mediaItemOf(map: Map<*, *>): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(map["title"] as? String)
            .setArtist((map["artist"] as? String)?.ifEmpty { null })
            .setAlbumTitle((map["album"] as? String)?.ifEmpty { null })
            .setDurationMs((map["durationMs"] as? Number)?.toLong()?.takeIf { it > 0 })
            .setArtworkUri((map["id"] as? String)?.let { artById[it] }?.let { Uri.parse(it) })
            .build()
        return MediaItem.Builder()
            .setMediaId(map["id"] as? String ?: "")
            .setUri(map["uri"] as? String ?: "")
            .setMediaMetadata(metadata)
            .build()
    }

    /**
     * 대기열 스냅샷을 통째로 바꾼다. 현재 곡이 같으면 재생을 끊지 않고 앞뒤 목록만 맞춘다.
     * 다른 곡이면 새로 불러오고, 재생할 준비가 되면 [result]를 성공으로 끝낸다.
     */
    fun setQueue(map: Map<*, *>, result: MethodChannel.Result) {
        val items = (map["items"] as? List<*>)?.mapNotNull { it as? Map<*, *> } ?: emptyList()
        val playing = map["playing"] as? Boolean ?: false
        val positionMs = (map["positionMs"] as? Number)?.toLong()
        val wasShuffled = shuffleOn
        extras = map["extras"] as? String ?: ""
        if (wasShuffled != shuffleOn) main.post { refreshLayout() }
        exo.repeatMode = repeatModeOf(map["repeat"] as? String)
        pendingLoad?.error("interrupted", "다른 대기열을 불러와 중단됨", null)
        pendingLoad = null

        if (items.isEmpty()) {
            exo.stop()
            exo.clearMediaItems()
            persistQueue()
            result.success(null)
            return
        }
        revive()
        val index = ((map["index"] as? Number)?.toInt() ?: 0).coerceIn(0, items.size - 1)
        val mediaItems = items.map { mediaItemOf(it) }
        val keepCurrent = exo.mediaItemCount > 0 &&
            exo.playbackState != Player.STATE_ENDED &&
            exo.currentMediaItem?.mediaId == mediaItems[index].mediaId

        if (keepCurrent) {
            // 듣던 곡은 그대로 두고 앞뒤만 바꾼다 (다음에 재생 · 순서 이동 · 삭제 · 반복 변경).
            val current = exo.currentMediaItemIndex
            if (current < exo.mediaItemCount - 1) exo.removeMediaItems(current + 1, exo.mediaItemCount)
            if (current > 0) exo.removeMediaItems(0, current)
            if (index > 0) exo.addMediaItems(0, mediaItems.subList(0, index))
            if (index < mediaItems.size - 1) exo.addMediaItems(mediaItems.subList(index + 1, mediaItems.size))
            if (positionMs != null) exo.seekTo(positionMs)
            exo.playWhenReady = playing
            sessionPlayer.refresh()
            persistQueue()
            result.success(null)
        } else {
            pendingLoad = result
            exo.setMediaItems(mediaItems, index, positionMs ?: 0L)
            exo.playWhenReady = playing
            exo.prepare()
            sessionPlayer.refresh()
            persistQueue()
        }
    }

    /** 앱에서 다시 재생을 시작한다: 정리해 둔 세션을 되살리고 이어폰 분리로 멈춘 기록을 비운다. */
    private fun revive() {
        pausedByNoisyAt = 0L
        previewRevived = false
        if (!dismissed && session != null) return
        dismissed = false
        if (session == null) buildSession()
        syncResumable()
    }

    /** 대기열은 그대로 두고 [index]번 곡으로 처음부터 옮긴다. */
    fun skipTo(index: Int) {
        if (index < 0 || index >= exo.mediaItemCount) return
        revive()
        exo.seekTo(index, 0L)
        if (exo.playbackState == Player.STATE_IDLE) exo.prepare()
    }

    fun play() {
        if (exo.mediaItemCount == 0) return
        revive()
        // 끝까지 들은 곡은 처음부터 다시.
        if (exo.playbackState == Player.STATE_ENDED) exo.seekTo(0)
        if (exo.playbackState == Player.STATE_IDLE) exo.prepare()
        exo.playWhenReady = true
    }

    fun pause() {
        pausedByNoisyAt = 0L
        exo.playWhenReady = false
    }

    fun seek(ms: Long) {
        if (exo.mediaItemCount > 0) exo.seekTo(ms)
    }

    fun artFor(id: String): Uri? = artById[id]?.let { Uri.parse(it) }

    /** true면 오디오 포커스를 따로 다루지 않아 다른 앱 소리와 겹쳐 재생한다. false면 뺏기면 멈춘다. */
    fun setMixWithOthers(mix: Boolean) {
        exo.setAudioAttributes(
            AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),
            !mix,
        )
    }

    /** 재생 속도 (0.5~2.0배, 음높이는 그대로). 알림 · 세션은 [exo] 상태를 비추므로 따로 맞출 게 없다. */
    fun setSpeed(speed: Double) {
        val value = speed.toFloat().coerceIn(0.5f, 2f)
        PlaybackStore.saveSpeed(context, value)
        exo.setPlaybackSpeed(value)
    }

    /** 대기열 곡별 커버 주소를 받는다. 지금 곡은 앱이 [setSession]으로 보내므로 건드리지 않는다. */
    fun setQueueArt(map: Map<*, *>) {
        artById = map.entries.mapNotNull { (k, v) -> if (k is String && v is String) k to v else null }.toMap()
        for (i in 0 until exo.mediaItemCount) {
            if (i == exo.currentMediaItemIndex) continue
            val item = exo.getMediaItemAt(i)
            val art = artById[item.mediaId]?.let { Uri.parse(it) }
            if (item.mediaMetadata.artworkUri == art) continue
            val metadata = item.mediaMetadata.buildUpon().setArtworkUri(art).build()
            exo.replaceMediaItem(i, item.buildUpon().setMediaMetadata(metadata).build())
        }
        persistQueue()
    }

    /** 지금 쥐고 있는 대기열 스냅샷 (앱을 다시 켰을 때 복원용). 곡이 없으면 null. */
    fun getState(): Map<String, Any?>? {
        if (!initialized || exo.mediaItemCount == 0) return null
        val items = (0 until exo.mediaItemCount).map { i ->
            val item = exo.getMediaItemAt(i)
            mapOf(
                "id" to item.mediaId,
                "uri" to item.localConfiguration?.uri?.toString(),
                "title" to (item.mediaMetadata.title?.toString() ?: ""),
                "artist" to (item.mediaMetadata.artist?.toString() ?: ""),
                "album" to (item.mediaMetadata.albumTitle?.toString() ?: ""),
                "durationMs" to (item.mediaMetadata.durationMs ?: 0L),
            )
        }
        return mapOf(
            "items" to items,
            "index" to exo.currentMediaItemIndex,
            "playing" to (exo.playWhenReady && exo.playbackState != Player.STATE_ENDED),
            "repeat" to repeatNameOf(exo.repeatMode),
            "positionMs" to exo.currentPosition,
            "extras" to extras,
        )
    }

    /** 알림을 눌러 앱이 새로 켜졌는지 한 번 알려 주고 비운다. */
    fun takeOpenPlayerRequest(): Boolean {
        val requested = openPlayerRequested
        openPlayerRequested = false
        return requested
    }

    /** 알림을 눌렀다: 화면이 떠 있으면 바로 알리고, 아직 없으면 Dart가 시작할 때 가져가게 남긴다. */
    fun onOpenPlayerRequested() {
        val current = sink
        if (current != null) {
            current.success(mapOf("type" to "openPlayer"))
        } else {
            openPlayerRequested = true
        }
    }

    /** 미리 듣기 내용이 알림에 올라 있는지. 화면이 없어도 Flutter 엔진(미리 듣기 소리)을 살려 둘 이유가 된다. */
    val isPreviewing get() = initialized && sessionPlayer.info?.preview == true

    /** 미리 듣기가 지금 소리를 내고 있는지. */
    val isPreviewPlaying get() = isPreviewing && sessionPlayer.info?.playing == true

    /** 알림을 지운(닫기) 상태에서 미리 듣기 때문에 세션을 잠깐 되살린 상태. 미리 듣기가 끝나면 다시 치운다. */
    private var previewRevived = false

    /** [map]이 null이면 알림을 치운다 (재생은 그대로). */
    fun setSession(map: Map<*, *>?) {
        restoredFromStore = false
        val info = map?.let { SessionInfo(it) }
        if (previewRevived && info?.preview != true) {
            previewRevived = false
            service?.hideSession()
            releaseSession()
        }
        MuloEngine.releaseWhenIdle()
        if (info == null) {
            isNotificationVisible = false
            sessionPlayer.info = null
            service?.hideSession()
            PlaybackStore.saveSession(context, null)
            return
        }
        // 닫기(X) 뒤에도 미리 듣기는 알림(포그라운드 서비스)에 올라야 앱이 뒤로 가도 이어진다.
        if (dismissed && info.preview) {
            previewRevived = true
            if (session == null) buildSession()
        }
        sessionPlayer.info = info
        if (!info.preview) PlaybackStore.saveSession(context, map)
        refreshLayout()
        if (dismissed && !previewRevived) return
        isNotificationVisible = true
        ensureService()
        service?.showSession()
    }

    /** 알림 버튼 모양을 다시 맞춘다 (좋아요 · 셔플은 앱이 있든 없든 같은 자리에 둔다). */
    private fun refreshLayout() {
        val info = sessionPlayer.info ?: return
        session?.setCustomLayout(customLayout(info))
    }

    /** 좋아요를 Dart가 처리할 수 있는지: Dart가 붙어 있고, 앱이 보낸 내용이 지금 재생 중인 곡의 것일 때. */
    private fun dartHandlesFavorite() = sink != null && !restoredFromStore && sessionPlayer.infoMatchesCurrent()

    /** 알림의 좋아요 모양. Dart가 못 맡으면 DB를 직접 읽고, 읽지 못하면 앱이 마지막으로 보낸 값을 쓴다. */
    private fun favoriteOn(info: SessionInfo): Boolean {
        if (dartHandlesFavorite()) return info.favorite
        val id = exo.currentMediaItem?.mediaId ?: return info.favorite
        return FavoriteStore.isFavorite(context, id) ?: info.favorite
    }

    /** 좋아요 버튼: Dart가 있으면 Dart에 맡기고(화면의 목록이 바로 바뀌게), 없으면 DB를 직접 바꾼다. */
    private fun toggleFavorite() {
        if (dartHandlesFavorite()) {
            emitCommand("favorite", null)
            return
        }
        val id = exo.currentMediaItem?.mediaId ?: return
        if (FavoriteStore.toggle(context, id) != null) refreshLayout()
    }

    /**
     * 세션 정리: 닫기(X) · 알림 밀어서 지우기 · 끝까지 재생 · 앱을 밀었는데 멈춰 있을 때.
     * 알림을 치우고 미디어 세션을 release해서 이어폰 · 차량 버튼이 곡을 저절로 켜지 않게 한다.
     * 대기열은 남아 있어(앱을 열면 보인다) 앱에서 다시 재생하면 세션이 새로 만들어진다.
     */
    fun endSession() {
        if (!initialized) return
        exo.pause()
        pausedByNoisyAt = 0L
        dismissed = true
        isNotificationVisible = false
        service?.hideSession()
        releaseSession()
        persistPosition()
        syncResumable()
    }

    /** 세션 안에서 불린 정리 요청은 콜백이 끝난 뒤에 처리한다 (세션을 쓰는 중에 release하지 않게). */
    fun endSessionSoon() {
        main.post { endSession() }
    }

    private fun ensureService() {
        if (service != null) return
        try {
            context.startService(Intent(context, MuloPlaybackService::class.java))
        } catch (_: Exception) {
            // 백그라운드에서는 서비스를 새로 못 띄울 수 있다: 알림만 못 보일 뿐 재생은 그대로.
        }
    }

    private fun customLayout(info: SessionInfo): ImmutableList<CommandButton> {
        val close = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(R.drawable.ic_notif_close)
            .setDisplayName(info.closeLabel)
            .setSessionCommand(closeCommand)
            .build()
        if (info.preview) return ImmutableList.of(close)
        // 셔플 순서는 extras가 쥐고 있어 앱이 없어도 네이티브가 켜고 끌 수 있다: 아이콘도 extras를 따른다.
        val shuffled = shuffleOn
        val shuffle = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(if (shuffled) R.drawable.ic_notif_shuffle_on else R.drawable.ic_notif_shuffle_off)
            .setDisplayName(if (shuffled) info.shuffleOffLabel else info.shuffleOnLabel)
            .setSessionCommand(shuffleCommand)
            .build()
        // 좋아요도 앱이 없으면 네이티브가 DB를 직접 바꾼다 ([FavoriteStore]): 셔플과 같이 늘 같은 자리에 둔다.
        // 재생 중인 알림은 일시정지한 뒤 밀어서 지울 수 있다.
        val on = favoriteOn(info)
        val favorite = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(if (on) R.drawable.ic_notif_favorite else R.drawable.ic_notif_favorite_outline)
            .setDisplayName(if (on) info.unfavoriteLabel else info.favoriteLabel)
            .setSessionCommand(favoriteCommand)
            .build()
        return ImmutableList.of(favorite, shuffle)
    }

    // ── 네이티브 → Dart ──

    fun setSink(newSink: EventChannel.EventSink?) {
        sink = newSink
        // Dart가 붙거나 떨어지면 알림 버튼(좋아요 · 셔플 ↔ 닫기)을 다시 맞춘다.
        if (initialized) main.post { refreshLayout() }
    }

    private fun emit(map: Map<String, Any?>) {
        sink?.success(map)
    }

    /** 앱이 저장해 둔 대기열 정보에 셔플이 켜져 있는지. */
    private val shuffleOn: Boolean
        get() = try {
            extras.isNotEmpty() && JSONObject(extras).optBoolean("shuffle", false)
        } catch (_: Exception) {
            false
        }

    /**
     * 셔플 중 대기열을 한 바퀴 다 돌아 첫 곡으로 넘어왔으면 나머지 곡을 새로 섞는다 (같은 순서로 다시 돌지 않게).
     * 앱(Dart)이 붙어 있으면 앱이 같은 일을 하므로, 앱을 밀어 서비스만 남았을 때만 여기서 한다.
     * 지금 곡(첫 곡)은 끊기지 않게 그대로 두고, 방금 들은 곡이 바로 다음에 오지 않게 한다.
     * 섞기 전 순서(extras의 original)는 그대로라 앱을 다시 열어 셔플을 끄면 원래 순서로 돌아간다.
     */
    private fun reshuffleAfterLap(previousId: String?) {
        val count = exo.mediaItemCount
        if (sink != null || previousId == null || count < 3 || !shuffleOn) return
        if (exo.currentMediaItemIndex != 0 || exo.getMediaItemAt(count - 1).mediaId != previousId) return
        val rest = (1 until count).map { exo.getMediaItemAt(it) }.shuffled().toMutableList()
        if (rest.first().mediaId == previousId) rest.add(rest.removeAt(0))
        exo.removeMediaItems(1, count)
        exo.addMediaItems(rest)
        persistQueue()
    }

    /**
     * 알림의 셔플 버튼. 앱(Dart)이 붙어 있으면 Dart에 넘기고(순서는 Dart가 쥔다),
     * 앱을 밀어 서비스만 남았으면 여기서 직접 켜고 끈다.
     * 켜면 지금 곡을 맨 앞에 두고 나머지를 섞으며 원래 순서를 extras의 original에 적어 둔다.
     * 끄면 original 순서로 되돌린다. 듣던 곡은 끊기지 않는다. 앱을 다시 열면 `getState`의 extras로 이어 받는다.
     */
    private fun toggleShuffle() {
        if (sink != null) {
            emitCommand("shuffle", null)
            return
        }
        val count = exo.mediaItemCount
        if (count == 0) return
        val current = exo.currentMediaItemIndex
        val all = (0 until count).map { exo.getMediaItemAt(it) }
        val json = try {
            if (extras.isNotEmpty()) JSONObject(extras) else JSONObject()
        } catch (_: Exception) {
            JSONObject()
        }
        val currentItem = all[current]
        val others = all.filterIndexed { i, _ -> i != current }
        val before: List<MediaItem>
        val after: List<MediaItem>
        if (!shuffleOn) {
            val rest = others.shuffled()
            before = emptyList()
            after = rest
            json.put("shuffle", true)
            json.put("original", JSONArray(all.map { it.mediaId }))
        } else {
            val original = json.optJSONArray("original")
            val ids = (0 until (original?.length() ?: 0)).map { original!!.getString(it) }
            val byId = all.groupBy { it.mediaId }
            val ordered = ids.mapNotNull { byId[it]?.firstOrNull() }.distinct() +
                all.filter { it.mediaId !in ids }
            val at = ordered.indexOf(currentItem).takeIf { it >= 0 } ?: 0
            before = ordered.subList(0, at)
            after = ordered.subList(at + 1, ordered.size)
            json.put("shuffle", false)
            json.remove("original")
        }
        if (current < count - 1) exo.removeMediaItems(current + 1, count)
        if (current > 0) exo.removeMediaItems(0, current)
        if (before.isNotEmpty()) exo.addMediaItems(0, before)
        if (after.isNotEmpty()) exo.addMediaItems(after)
        extras = json.toString()
        persistQueue()
        sessionPlayer.refresh()
        refreshLayout()
    }

    private fun emitCommand(name: String, positionMs: Long?) {
        emit(mapOf("type" to "command", "name" to name, "positionMs" to positionMs))
    }

    /** 구간 반복(A-B): 현재 곡의 [loopStartMs, loopEndMs]. 둘 다 -1이면 꺼짐. 곡이 바뀌면 풀린다. */
    private var loopStartMs = -1L
    private var loopEndMs = -1L
    private var lastPositionEmitAt = 0L

    /** 현재 곡의 [startMs]~[endMs] 구간만 반복한다. 둘 중 하나라도 null이거나 구간이 비정상이면 해제. */
    fun setLoop(startMs: Long?, endMs: Long?) {
        if (startMs == null || endMs == null || startMs < 0 || endMs <= startMs) {
            loopStartMs = -1L
            loopEndMs = -1L
        } else {
            loopStartMs = startMs
            loopEndMs = endMs
            // 끝 지점을 이미 지났으면 바로 시작 지점으로.
            if (exo.mediaItemCount > 0 && exo.currentPosition >= endMs) exo.seekTo(startMs)
        }
        // 구간 반복은 촘촘히 재야 하므로 재생 중이면 타이머를 새 주기로 다시 건다.
        if (exo.isPlaying) {
            main.removeCallbacks(ticker)
            main.post(ticker)
        }
    }

    private fun loopActive() = loopStartMs >= 0

    private val ticker = object : Runnable {
        override fun run() {
            if (!exo.isPlaying) return
            val now = SystemClock.elapsedRealtime()
            // 끝 지점에 닿았으면 시작 지점으로 되돌린다 (되돌림은 onPositionDiscontinuity가 앱에 알린다).
            val wrapped = loopActive() && exo.currentPosition >= loopEndMs
            if (wrapped) exo.seekTo(loopStartMs)
            // 앱에 보내는 위치는 구간 반복 중에도 250ms 간격을 지킨다.
            if (!wrapped && now - lastPositionEmitAt >= 250) {
                lastPositionEmitAt = now
                emit(mapOf("type" to "position", "ms" to exo.currentPosition))
                // 위치는 5초마다 저장한다 (프로세스가 죽어도 거의 그 자리에서 이어진다).
                if (++tickCount % 20 == 0) persistPosition()
            }
            main.postDelayed(this, if (loopActive()) 40L else 250L)
        }
    }

    private val playerListener = object : Player.Listener {
        override fun onAudioSessionIdChanged(audioSessionId: Int) {
            EqualizerEngine.attach(audioSessionId)
        }

        override fun onEvents(player: Player, events: Player.Events) {
            sessionPlayer.refresh()
            LyricsOverlay.onPlayerChanged()
        }

        override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
            val previousId = lastMediaId
            lastMediaId = mediaItem?.mediaId
            // 다른 곡으로 넘어가면 구간 반복은 풀린다 (앱도 곡이 바뀌면 스스로 푼다).
            if (previousId != lastMediaId) setLoop(null, null)
            if (reason != Player.MEDIA_ITEM_TRANSITION_REASON_PLAYLIST_CHANGED) reshuffleAfterLap(previousId)
            persistPosition()
            // 현재 곡이 바뀌었으니 좋아요 버튼 모양을 다시 맞춘다 (앱이 모르는 곡이면 숨긴다).
            refreshLayout()
            // 목록을 바꾸느라 생긴 전환은 앱이 시킨 것이라 알리지 않는다.
            if (mediaItem == null || reason == Player.MEDIA_ITEM_TRANSITION_REASON_PLAYLIST_CHANGED) return
            emit(mapOf("type" to "track", "index" to exo.currentMediaItemIndex, "id" to mediaItem.mediaId))
        }

        override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
            if (!playWhenReady) {
                val why = when (reason) {
                    Player.PLAY_WHEN_READY_CHANGE_REASON_AUDIO_FOCUS_LOSS -> "audio_focus_loss"
                    Player.PLAY_WHEN_READY_CHANGE_REASON_AUDIO_BECOMING_NOISY -> "becoming_noisy"
                    Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST -> "user_request"
                    Player.PLAY_WHEN_READY_CHANGE_REASON_REMOTE -> "remote"
                    Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM -> "end_of_item"
                    else -> "reason_$reason"
                }
                PlaybackStore.logStop(context, "pause: $why")
            }
            if (reason == Player.PLAY_WHEN_READY_CHANGE_REASON_END_OF_MEDIA_ITEM) return
            // 이어폰 분리 · 블루투스 끊김으로 멈췄는지 기억해 둔다 (다시 연결되면 이어 재생하는 설정용).
            pausedByNoisyAt = if (!playWhenReady && reason == Player.PLAY_WHEN_READY_CHANGE_REASON_AUDIO_BECOMING_NOISY) {
                SystemClock.elapsedRealtime()
            } else {
                0L
            }
            persistPosition()
            emit(mapOf("type" to "playing", "value" to playWhenReady))
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            main.removeCallbacks(ticker)
            if (isPlaying) main.post(ticker) else persistPosition()
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_READY) {
                pendingLoad?.success(null)
                pendingLoad = null
            }
            // 반복 없이 대기열 끝까지 들었다 (슬라이더를 끝까지 끈 경우 포함): 첫 곡으로 돌아가 멈춰 두고
            // 앱에 알리고 세션을 정리한다. 다시 재생하면 첫 곡부터 나온다.
            if (playbackState == Player.STATE_ENDED) {
                setLoop(null, null)
                exo.playWhenReady = false
                exo.seekTo(0, 0L)
                emit(mapOf("type" to "ended"))
                endSessionSoon()
            }
        }

        override fun onPositionDiscontinuity(
            oldPosition: Player.PositionInfo,
            newPosition: Player.PositionInfo,
            reason: Int,
        ) {
            if (reason == Player.DISCONTINUITY_REASON_SEEK) {
                emit(mapOf("type" to "position", "ms" to newPosition.positionMs))
            }
        }

        override fun onPlaybackSuppressionReasonChanged(playbackSuppressionReason: Int) {
            if (playbackSuppressionReason != Player.PLAYBACK_SUPPRESSION_REASON_NONE) {
                PlaybackStore.logStop(context, "suppressed: $playbackSuppressionReason")
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            PlaybackStore.logStop(context, "error: ${error.errorCodeName} ${error.message}")
            val load = pendingLoad
            if (load != null) {
                load.error("load_failed", error.message, null)
                pendingLoad = null
                return
            }
            // 듣다가 못 여는 곡을 만나면 건너뛰고, 더 없으면 멈춘다.
            if (exo.hasNextMediaItem()) {
                exo.seekToNextMediaItem()
                exo.prepare()
            } else {
                exo.pause()
                emit(mapOf("type" to "ended"))
                endSessionSoon()
            }
        }
    }

    /** 출력 기기가 새로 연결됐다: 이어폰 분리로 멈춘 재생을 설정에 따라 이어서 재생한다. */
    private val deviceCallback = object : AudioDeviceCallback() {
        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
            EqualizerProfiles.onOutputChanged(context)
        }

        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
            EqualizerProfiles.remember(context, addedDevices)
            // 기기가 바뀌었으니 그 기기 전용 이퀄라이저 값을 적용한다.
            EqualizerProfiles.onOutputChanged(context)
            if (!resumeOnConnect || pausedByNoisyAt == 0L || dismissed || exo.mediaItemCount == 0) return
            if (addedDevices.none { AudioOutputs.isHeadset(it) }) return
            // 오래 전에 멈춘 재생이 갑자기 켜지지 않게 10분 안에 다시 연결됐을 때만.
            if (SystemClock.elapsedRealtime() - pausedByNoisyAt > RESUME_WINDOW_MS) {
                pausedByNoisyAt = 0L
                return
            }
            play()
        }
    }

    /**
     * 미디어 버튼이 서비스를 깨웠다: 세션 · 알림 내용 · 알림을 재생할 수 있게 갖춘다.
     * 알림을 지운 뒤에도 이어 재생하는 설정이면 정리된 세션을 되살리고, 앱이 알림을 꺼 둔(`setSession(null)`) 상태여도
     * 서비스가 포그라운드로 떴으니 대기열의 곡 정보로 알림을 올린다. 무시해야 하면 false.
     */
    fun prepareForButton(): Boolean {
        if (!initialized) return false
        val plan = MediaButtonPolicy.plan(
            gated = isGated,
            dismissed = dismissed,
            hasQueue = exo.mediaItemCount > 0,
            hasInfo = sessionPlayer.info != null,
        ) ?: return false
        if (plan.revive) revive()
        if (session == null) buildSession()
        if (plan.fillInfoFromQueue) {
            sessionPlayer.info = SessionInfo(emptyMap<String, Any?>())
            refreshLayout()
        }
        if (plan.showNotification) {
            isNotificationVisible = true
            service?.showSession()
        }
        return true
    }

    fun setResumeWithoutNotification(value: Boolean) {
        PlaybackStore.setResumeWithoutNotification(context, value)
        resumeWithoutNotification = value
        syncResumable()
    }

    /** 출력 기기 동작 설정 (앱이 꺼져도 지켜야 해서 네이티브에도 저장한다). */
    fun setOutputBehavior(pauseOnDisconnect: Boolean, resumeOnConnect: Boolean) {
        PlaybackStore.saveOutputBehavior(context, pauseOnDisconnect, resumeOnConnect)
        this.resumeOnConnect = resumeOnConnect
        exo.setHandleAudioBecomingNoisy(pauseOnDisconnect)
    }

    private val sessionCallback = object : MediaSession.Callback {
        override fun onConnect(session: MediaSession, controller: MediaSession.ControllerInfo): MediaSession.ConnectionResult {
            val commands = MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon()
                .add(favoriteCommand)
                .add(closeCommand)
                .add(shuffleCommand)
                .build()
            return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                .setAvailableSessionCommands(commands)
                .build()
        }

        // 이어폰 · 차량의 미디어 버튼. 알림을 지웠거나 재생을 끝낸 뒤라면 받지 않는다.
        override fun onMediaButtonEvent(
            session: MediaSession,
            controllerInfo: MediaSession.ControllerInfo,
            intent: Intent,
        ): Boolean = isGated

        override fun onCustomCommand(
            session: MediaSession,
            controller: MediaSession.ControllerInfo,
            customCommand: SessionCommand,
            args: Bundle,
        ): ListenableFuture<SessionResult> {
            when (customCommand.customAction) {
                ACTION_FAVORITE -> toggleFavorite()
                ACTION_SHUFFLE -> toggleShuffle()
                // 닫기(X): 재생을 멈추고 알림을 치운다 (미리 듣기면 Dart가 미리 듣기를 끝낸다).
                ACTION_CLOSE -> {
                    if (sessionPlayer.info?.preview != true) endSessionSoon()
                    emitCommand("stop", null)
                }
            }
            return Futures.immediateFuture(SessionResult(SessionResult.RESULT_SUCCESS))
        }
    }
}
