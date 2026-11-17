package com.mulo.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * 받기 큐와 받기 실행 전부 (예전 Dart `EngineDownloadQueueRepository`를 옮겼다): 대기열 저장 · 일시정지 · 재시도 · 취소,
 * 주소 읽기, 조각 이어받기, HLS 받기, 형식 변환, 가사, 태그, 저장(MediaStore), 보관함(DB) 등록, 알림.
 * 앱 화면이 없어도 포그라운드 서비스 안에서 끝까지 돈다. Dart는 요청을 넘기고 상태만 받아 그린다 ([DownloadChannel]).
 *
 * 형식별 처리(태그 키 · 커버 넣는 방식 · ffmpeg 인자)는 이 클래스가 아니라 [TagChannel] · [TranscoderChannel]의 형식별 함수가 한다.
 */
class DownloadEngine(
    private val context: Context,
    private val ytdlp: YtDlpEngine,
    private val transcoder: TranscoderChannel,
    private val store: MediaStoreChannel,
    private val tags: TagChannel,
    /** Dart로 알린다 (`queue` · `tagNotice` · `saved` · `engineError` · `registered`). 메인 스레드로 보낸다. */
    private val emit: (String, Any?) -> Unit,
) {
    private class Item(
        val id: String,
        val request: JSONObject,
        var status: String,
        var progress: Double = 0.0,
        var error: String = "",
        var processing: Boolean = false,
        var savedFolder: String = "",
        var partMime: String? = null,
    ) {
        fun active() = status == DOWNLOADING || status == QUEUED || status == PAUSED
    }

    private class Aborted : Exception()
    private class Failed(message: String) : Exception(message)

    private val lock = Any()
    private val items = ArrayList<Item>()
    private val sources = LinkedHashMap<String, String>()
    private val worker = Executors.newSingleThreadExecutor()
    private val saver = Executors.newSingleThreadExecutor()
    // init의 schedule()이 바로 일을 시작하므로, 받기가 쓰는 값은 모두 init보다 위에서 만든다.
    private val resolver = Executors.newCachedThreadPool()
    private val watchdog = java.util.concurrent.Executors.newSingleThreadScheduledExecutor()
    private val pending = AppDb.Pending(context)
    private val queueFile = File(context.filesDir, "download_queue.json")
    private val sourcesFile = File(context.filesDir, "download_sources.json")
    private val partsDir = File(context.filesDir, "download_parts")
    private val cfgPrefs = context.getSharedPreferences("download_cfg", Context.MODE_PRIVATE)

    @Volatile private var pumping = false
    @Volatile private var abort: String? = null
    @Volatile private var runningId: String? = null
    @Volatile private var activeConn: HttpURLConnection? = null
    private var seq = 0

    /** 알림을 만들 때 쓰는 글과 설정 (Dart가 [configure]로 넘긴다, 앱이 꺼져 있어도 쓰도록 저장해 둔다). */
    private var cfg: JSONObject = try {
        JSONObject(cfgPrefs.getString("cfg", "{}") ?: "{}")
    } catch (e: Exception) {
        JSONObject()
    }

    /** 이 곡을 미리 듣는 중이면 그 id (알림의 버튼이 바뀐다). Dart가 알려 준다. */
    @Volatile var previewingId: String? = null
        set(value) {
            field = value
            updateNotifications()
        }

    private var lastStatuses = HashMap<String, String>()
    private var progressShown = false
    private var lastProgressKey: String? = null
    private val batch = HashSet<String>()

    init {
        // 어느 빌드가 돌고 있는지 로그로 알 수 있게 한다 (고칠 때마다 표식을 올린다).
        MuloLog.d(MuloLog.NATIVE, "받기 엔진 시작 (표식 R8: 영상 받기도 일시정지가 바로 먹음)")
        load()
        schedule()
    }

    // ── 저장 ──

    private fun load() {
        synchronized(lock) {
            try {
                if (queueFile.exists()) {
                    val arr = JSONArray(queueFile.readText())
                    for (i in 0 until arr.length()) {
                        val o = arr.getJSONObject(i)
                        val status = o.getString("status")
                        if (status == DONE) continue
                        items.add(
                            Item(
                                o.getString("id"), o.getJSONObject("request"),
                                // 꺼질 때 받던 곡은 대기로 돌아와 이어서 받는다.
                                if (status == DOWNLOADING) QUEUED else status,
                                o.optDouble("progress", 0.0), o.optString("error", ""),
                                partMime = if (o.isNull("partMime")) null else o.optString("partMime"),
                            ),
                        )
                    }
                }
                if (sourcesFile.exists()) {
                    val o = JSONObject(sourcesFile.readText())
                    for (k in o.keys()) sources[k] = o.getString(k)
                }
            } catch (e: Exception) {
                MuloLog.e(MuloLog.NATIVE, "받기 대기열 읽기 실패: ${e.message}", e)
            }
        }
        lastStatuses = HashMap(items.associate { it.id to it.status })
    }

    private fun persist() {
        val arr = JSONArray()
        synchronized(lock) {
            for (it in items) {
                arr.put(
                    JSONObject().put("id", it.id).put("status", it.status).put("progress", it.progress)
                        .put("error", it.error).put("partMime", it.partMime).put("request", it.request),
                )
            }
        }
        try {
            queueFile.writeText(arr.toString())
        } catch (e: Exception) {
            MuloLog.e(MuloLog.NATIVE, "받기 대기열 저장 실패: ${e.message}", e)
        }
    }

    private fun persistSources() {
        try {
            val o = JSONObject()
            synchronized(lock) { sources.forEach { (k, v) -> o.put(k, v) } }
            sourcesFile.writeText(o.toString())
        } catch (e: Exception) {
            MuloLog.e(MuloLog.NATIVE, "받은 곡 기록 저장 실패: ${e.message}", e)
        }
    }

    /**
     * 옛 버전(Dart 큐)이 shared_preferences(`FlutterSharedPreferences`)에 남긴 대기열 · 받은 곡 기록을 한 번 가져온다.
     * 이미 네이티브 기록이 있으면 아무것도 하지 않고, 가져온 뒤에는 옛 기록을 지운다.
     */
    private fun importLegacy() {
        val legacy = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val queueJson = legacy.getString("flutter.download.queue", null)
        val sourcesJson = legacy.getString("flutter.download.sources", null)
        if (queueJson == null && sourcesJson == null) return
        synchronized(lock) {
            if (queueFile.exists() || sourcesFile.exists()) return
            try {
                if (queueJson != null) {
                    val arr = JSONArray(queueJson)
                    for (i in 0 until arr.length()) {
                        val o = arr.getJSONObject(i)
                        val status = o.getString("status")
                        if (status == DONE) continue
                        items.add(
                            Item(
                                o.getString("id"), clean(o.getJSONObject("request")),
                                if (status == DOWNLOADING) QUEUED else status,
                                o.optDouble("progress", 0.0), o.optString("error", ""),
                                partMime = if (o.isNull("partMime")) null else o.optString("partMime"),
                            ),
                        )
                    }
                }
                if (sourcesJson != null) {
                    val o = JSONObject(sourcesJson)
                    for (k in o.keys()) sources[k] = o.getString(k)
                }
            } catch (e: Exception) {
                MuloLog.e(MuloLog.NATIVE, "옛 받기 기록 가져오기 실패: ${e.message}", e)
            }
        }
        legacy.edit().remove("flutter.download.queue").remove("flutter.download.sources").apply()
        persist()
        persistSources()
        emitQueue()
        schedule()
    }

    // ── Dart가 부르는 명령 ──

    fun configure(config: JSONObject) {
        cfg = config
        cfgPrefs.edit().putString("cfg", config.toString()).apply()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) DownloadNotifications.createChannels(context, toMap(config))
        updateNotifications()
    }

    /** 보관함 DB를 Dart가 연 뒤 부른다: 맡겨 둔 등록이 있으면 쓰고, 썼으면 Dart가 목록을 다시 읽게 알린다. */
    fun dbReady() {
        // 앱이 처음 열릴 때 옛 Dart 큐의 기록이 있으면 한 번 가져온다 (Dart는 관여하지 않는다).
        importLegacy()
        // 아직 Dart가 등록하지 못한 곡을 다시 넘긴다 (앱이 꺼져 있는 사이 받은 곡 등).
        saver.execute { pending.all().forEach { emit("registered", toDartMap(it)) } }
    }

    /** JSON의 null 값을 뺀다 (`optString`이 null을 "null" 글자로 읽는 것을 막는다). */
    private fun clean(o: JSONObject): JSONObject {
        for (k in o.keys().asSequence().toList()) {
            when (val v = o.get(k)) {
                JSONObject.NULL -> o.remove(k)
                is JSONObject -> clean(v)
            }
        }
        return o
    }

    fun enqueue(request: JSONObject): String {
        val id = "d${System.currentTimeMillis()}${(seq++)}"
        synchronized(lock) {
            // 끝난 곡은 새로 받기 시작할 때 목록에서 치운다.
            items.removeAll { it.status == DONE }
            items.add(Item(id, clean(request), QUEUED))
        }
        changed()
        schedule()
        return id
    }

    fun pause(id: String) {
        var running = false
        synchronized(lock) {
            val it = items.firstOrNull { x -> x.id == id } ?: return
            if (!it.active() || it.status == PAUSED) return
            running = it.status == DOWNLOADING
            it.status = PAUSED
            it.processing = false
        }
        if (running && runningId == id) {
            abort = "pause"
            dropConnection()
            ytdlp.cancelTagged(id)
            transcoder.cancelProcess()
        }
        changed()
    }

    /** 받는 중인 연결을 끊어, 응답을 기다리며 막힌 읽기를 바로 풀어 준다 (알림 버튼은 메인 스레드라 따로 끊는다). */
    private fun dropConnection() {
        val c = activeConn ?: return
        Thread { try { c.disconnect() } catch (_: Exception) {} }.start()
    }

    fun resume(id: String) {
        synchronized(lock) {
            val it = items.firstOrNull { x -> x.id == id } ?: return
            if (it.status != PAUSED) return
            items.remove(it)
            items.add(it)
            it.status = QUEUED
        }
        changed()
        schedule()
    }

    fun retry(id: String) {
        synchronized(lock) {
            val it = items.firstOrNull { x -> x.id == id }
            if (it == null || it.status != FAILED) {
                MuloLog.d(MuloLog.NATIVE, "다시 시도 못 함 $id: ${it?.status ?: "목록에 없음"}")
                return
            }
            items.remove(it)
            items.add(it)
            // 실패 전에 받아 둔 만큼이 있으면 이어 받는다.
            it.status = QUEUED
            it.error = ""
        }
        // 다시 받기 시작하면 그 항목의 실패 알림은 치운다.
        DownloadNotifications.clearResult(context, id)
        changed()
        schedule()
    }

    fun cancel(id: String) {
        val removed = synchronized(lock) {
            val it = items.firstOrNull { x -> x.id == id } ?: return
            items.remove(it)
            it
        }
        if (removed.status == DOWNLOADING && runningId == id) {
            abort = "cancel"
            dropConnection()
            ytdlp.cancelTagged(id)
            transcoder.cancelProcess()
        } else {
            deletePart(id)
        }
        changed()
    }

    fun cancelAll(playlistId: String?): Int {
        val ids = synchronized(lock) {
            items.filter { it.status != DONE }
                .filter { playlistId == null || playlistIdsOf(it.request).contains(playlistId) }
                .map { it.id }
        }
        ids.forEach { cancel(it) }
        return ids.size
    }

    fun findExisting(url: String): Map<String, Any?> = synchronized(lock) {
        val key = sourceKey(url)
        mapOf(
            "trackId" to sources[key],
            "inQueue" to items.any { it.active() && sourceKey(it.request.optString("url")) == key },
        )
    }

    fun sourceUrlOf(trackId: String): String? = synchronized(lock) {
        val key = sources.entries.firstOrNull { it.value == trackId }?.key ?: return null
        if (key.startsWith("youtube:")) "https://www.youtube.com/watch?v=${key.removePrefix("youtube:")}" else key
    }

    /** 받는 중이거나 기다리는 곡이 있다 (엔진을 정리하면 안 된다). */
    fun isBusy(): Boolean = synchronized(lock) { items.any { it.status == QUEUED || it.status == DOWNLOADING } }

    fun snapshot(): List<Map<String, Any?>> = synchronized(lock) { items.map { toMap(it) } }

    /** 알림 버튼(취소 · 일시정지/이어받기 · 미리 듣기 · 미리 듣기 일시정지/중지)을 앱 없이 바로 처리한다. 처리했으면 true. */
    fun onAction(key: String): Boolean {
        if (key == "stopPreview") {
            MuloEngine.preview?.stopFromNotification()
            return true
        }
        val current = synchronized(lock) {
            val active = items.filter { it.active() }
            active.firstOrNull { it.status != PAUSED } ?: active.firstOrNull()
        } ?: return true
        MuloLog.d(MuloLog.NATIVE, "받기 알림 버튼 $key → ${current.id} (${current.status})")
        when (key) {
            "cancel" -> cancel(current.id)
            "toggleHold" -> if (current.status == PAUSED) resume(current.id) else pause(current.id)
            "pausePreview" -> if (previewingId == current.id) MuloEngine.preview?.togglePauseFromNotification()
            "preview" -> {
                if (previewingId == current.id) return true
                val r = current.request
                MuloEngine.preview?.startFromNotification(
                    current.id, r.optString("title"), r.optString("url"), r.optString("artist"),
                    r.optString("thumbnailUrl").ifEmpty { null },
                ) { previewStreams(r.optString("url")) }
            }
            else -> return false
        }
        return true
    }

    /** 미리 듣기로 틀 소리 주소들 (읽은 주소, 안 열리면 대체 형식 순). 못 읽으면 null. */
    private fun previewStreams(url: String): List<Pair<String, Map<String, String>>>? {
        val s = try {
            resolveAudio(url, null, false)
        } catch (e: Exception) {
            return null
        }
        return listOf(s.url to s.headers) + s.fallbacks
    }

    // ── 상태 알림 ──

    private fun toMap(item: Item): Map<String, Any?> {
        val r = item.request
        return mapOf(
            "id" to item.id, "title" to r.optString("title"), "artist" to r.optString("artist"),
            "genre" to r.optString("genre"), "playlistIds" to playlistIdsOf(r).toList(),
            "status" to item.status, "progress" to item.progress,
            "thumbnailUrl" to if (r.isNull("thumbnailUrl")) null else r.optString("thumbnailUrl"),
            "cover" to r.optJSONObject("cover")?.let { toMap(it) },
            "durationMs" to if (r.has("durationMs") && !r.isNull("durationMs")) r.optLong("durationMs") else null,
            "color" to if (r.has("color") && !r.isNull("color")) r.optLong("color") else null,
            "url" to r.optString("url"), "error" to item.error, "processing" to item.processing,
            "savedFolder" to item.savedFolder,
        )
    }

    private fun toMap(o: JSONObject): Map<String, Any?> = o.keys().asSequence().associateWith { k ->
        when (val v = o.get(k)) {
            JSONObject.NULL -> null
            is JSONObject -> toMap(v)
            else -> v
        }
    }

    /** Dart가 곡을 보관함에 등록했다. 맡겨 둔 것에서 뺀다. */
    fun ack(trackId: String) = pending.remove(trackId)

    private fun toDartMap(o: JSONObject): Map<String, Any?> = o.keys().asSequence().associateWith { k ->
        when (val v = o.get(k)) {
            JSONObject.NULL -> null
            is JSONObject -> toDartMap(v)
            is JSONArray -> List(v.length()) { v.get(it) }
            else -> v
        }
    }

    private fun emitQueue() = emit("queue", snapshot())

    /** 상태가 바뀌었다 (저장 + 화면 + 알림). */
    private fun changed() {
        MuloLog.d(MuloLog.NATIVE, "받기 상태 ${synchronized(lock) { items.joinToString { "${it.id}:${it.status}" } }}")
        persist()
        emitQueue()
        updateNotifications()
    }

    /** 진행률만 바뀌었다 (저장은 하지 않는다). */
    private fun progressed() {
        emitQueue()
        updateNotifications()
    }

    private fun str(key: String) = cfg.optString(key, "")

    private fun fill(template: String, vararg pairs: Pair<String, Any>): String {
        var s = template
        for ((k, v) in pairs) s = s.replace("{$k}", v.toString())
        return s
    }

    @Synchronized
    private fun updateNotifications() {
        val snap: List<Item> = synchronized(lock) { items.toList() }
        val hide = cfg.optBoolean("hide", false)
        val results = cfg.optBoolean("results", true)
        val color = if (cfg.has("color")) cfg.optLong("color").toInt() else null
        val before = lastStatuses
        lastStatuses = HashMap(snap.associate { it.id to it.status })

        if (results) {
            for (i in snap) {
                if (before[i.id] == i.status) continue
                val r = i.request
                val art = if (hide) null else r.optString("thumbnailUrl").ifEmpty { null }
                if (i.status == DONE) {
                    val title = r.optString("title")
                    val artist = r.optString("artist")
                    val line = if (hide) str("doneHidden") else if (artist.isEmpty()) title else "$title · $artist"
                    val loc = if (i.savedFolder.isEmpty()) null
                    else fill(str("saveLocation"), "f" to i.savedFolder.replaceFirst("/storage/emulated/0/", ""))
                    DownloadNotifications.showResult(
                        context,
                        mapOf(
                            "id" to i.id, "openId" to i.id, "title" to str("doneTitle"),
                            "body" to listOfNotNull(line, loc).joinToString("\n"),
                            "failed" to false, "artUri" to art, "color" to color,
                        ),
                    )
                } else if (i.status == FAILED) {
                    val body = if (hide) str("failedHidden")
                    else listOf(r.optString("title"), i.error).filter { it.isNotEmpty() }.joinToString("\n")
                    DownloadNotifications.showResult(
                        context,
                        mapOf(
                            "id" to i.id, "openId" to i.id, "title" to str("failedTitle"), "body" to body,
                            "failed" to true, "artUri" to art, "retryLabel" to str("retry"), "color" to color,
                        ),
                    )
                }
            }
        } else {
            DownloadNotifications.clearResults(context)
        }

        val active = snap.filter { it.active() }
        var current = snap.firstOrNull { it.status == DOWNLOADING }
        if (current == null && !progressShown) current = snap.firstOrNull { it.status == QUEUED }
        val allPaused = active.isNotEmpty() && active.all { it.status == PAUSED }
        if (current == null && allPaused) current = active.first()
        if (active.isEmpty()) batch.clear() else batch.addAll(active.map { it.id })

        val keepAlive = cfg.optBoolean("keepAlive", true)
        if (!keepAlive || (current == null && active.isEmpty())) {
            clearProgress()
            return
        }
        val cur = current ?: return

        val batchItems = snap.filter { batch.contains(it.id) && it.status != FAILED }
        val done = batchItems.count { it.status == DONE }
        val overall = if (batchItems.isEmpty()) 0.0
        else batchItems.sumOf { if (it.status == DONE) 1.0 else it.progress } / batchItems.size
        val overallPercent = Math.round(overall * 100).toInt().coerceIn(0, 100)
        val next = snap.firstOrNull { it.status == QUEUED && it.id != cur.id }
        val percent = Math.round(cur.progress * 100).toInt().coerceIn(0, 100)
        val r = cur.request
        val title = if (hide) str("hiddenTitle") else r.optString("title")
        val paused = cur.status == PAUSED
        val progressLine = when {
            paused -> fill(str("paused"), "p" to percent)
            next != null && !hide -> fill(str("progressNext"), "p" to percent, "t" to next.request.optString("title"))
            else -> fill(str("progress"), "p" to percent)
        }
        val artist = r.optString("artist")
        val body = if (hide || artist.isEmpty()) progressLine else "$artist · $progressLine"
        val subText = fill(str("overall"), "d" to done, "n" to batchItems.size, "p" to overallPercent)
        val previewing = !hide && previewingId == cur.id
        val preview = if (hide || previewing) null else str("preview")
        val stop = if (previewing) str("stopPreview") else null
        val cancel = if (previewing) null else str("cancel")
        val hold = if (previewing) null else if (paused) str("resume") else str("pause")
        val art = if (hide) null else r.optString("thumbnailUrl").ifEmpty { null }
        val key = "$title|$body|$subText|$overallPercent|$preview|$stop|$hold|${cur.id}|$art"
        if (progressShown && key == lastProgressKey) return
        progressShown = true
        lastProgressKey = key
        val args = mapOf(
            "title" to title, "body" to body, "percent" to overallPercent, "foreground" to true, "subText" to subText,
            "previewLabel" to preview, "cancelLabel" to cancel, "holdLabel" to hold, "stopLabel" to stop,
            "openId" to cur.id, "artUri" to art, "color" to color,
        )
        DownloadNotifications.lastProgress = args
        DownloadForegroundService.start(context)
        DownloadNotifications.showProgress(context, args)
    }

    private fun clearProgress() {
        if (!progressShown) return
        progressShown = false
        lastProgressKey = null
        DownloadNotifications.lastProgress = null
        DownloadForegroundService.stop(context)
        DownloadNotifications.clearProgress(context)
    }

    // ── 실행 ──

    private fun schedule() {
        if (pumping) {
            MuloLog.d(MuloLog.NATIVE, "받기 순서 대기: 앞 작업이 아직 끝나지 않음 (running=$runningId)")
            return
        }
        pumping = true
        worker.execute {
            try {
                while (true) {
                    val next = synchronized(lock) { items.firstOrNull { it.status == QUEUED } } ?: break
                    run(next)
                }
            } finally {
                pumping = false
                // 처리하는 사이 새로 들어온 것이 있으면 이어 간다.
                if (synchronized(lock) { items.any { it.status == QUEUED } }) schedule()
                else MuloEngine.releaseWhenIdle()
            }
        }
    }

    private fun checkAbort() {
        if (abort != null) throw Aborted()
    }

    private fun run(item: Item) {
        val id = item.id
        val request = item.request
        MuloLog.d(MuloLog.NATIVE, "받기 시작 $id")
        // 받기가 15초가 지나도 진행이 없으면 받는 스레드가 어디서 멈췄는지 남긴다.
        val runner = Thread.currentThread()
        watchdog.schedule({
            if (runningId == id && item.progress == 0.0) {
                val where = runner.stackTrace.take(14).joinToString("\n") { "  at $it" }
                MuloLog.d(MuloLog.NATIVE, "받기 15초째 진행 없음 $id (${runner.state})\n$where")
            }
        }, 15, java.util.concurrent.TimeUnit.SECONDS)
        abort = null
        runningId = id
        synchronized(lock) { item.status = DOWNLOADING; item.processing = false }
        changed()
        val part = File(partsDir, "$id.part")
        var converted: File? = null
        try {
            partsDir.mkdirs()
            val videoFormat = request.optString("videoFormat", "")
            if (videoFormat.isNotEmpty()) {
                runVideo(item, videoFormat)
                return
            }
            val format = request.optString("resolvedFormat", request.optString("format", "opus"))
            val url = request.optString("url")
            if (url.isEmpty()) throw Failed("받을 주소가 없어요")
            val language = request.optString("audioLanguage", "").ifEmpty { null }
            var lastShown = 0.0

            fun fetch(refresh: Boolean): Downloaded {
                val stream = resolveAudio(url, language, refresh)
                checkAbort()
                if (stream.hls) {
                    // HLS(사운드클라우드 등)는 목록 파일이라 조각을 받아 합친다 (크기를 몰라 진행률은 없다).
                    synchronized(lock) { item.processing = true }
                    progressed()
                    val merged = try {
                        transcoder.fetchStream(stream.url, stream.headers, stream.codec, part.absolutePath)
                    } catch (e: Exception) {
                        throw Failed("스트림을 합치지 못했어요 (HLS: ${e.message})")
                    }
                    checkAbort()
                    return Downloaded(part, merged["extension"] ?: "m4a", merged["mime"] ?: "audio/mp4")
                }
                return downloadAudio(stream, part, if (refresh) null else item.partMime, { mime ->
                    item.partMime = mime
                    persist()
                }) { p ->
                    if (abort == null && (p - lastShown >= PROGRESS_STEP || p >= 1.0)) {
                        lastShown = p
                        synchronized(lock) { if (item.status == DOWNLOADING) item.progress = p }
                        progressed()
                    }
                }
            }

            var audio = try {
                fetch(false)
            } catch (e: Failed) {
                // 주소가 막혔거나(403) 만료됐을 수 있다: 새로 읽어 처음부터 한 번 더 받는다.
                checkAbort()
                lastShown = 0.0
                fetch(true)
            }
            checkAbort()
            synchronized(lock) { if (item.status == DOWNLOADING) { item.progress = 1.0; item.processing = true } }
            progressed()

            // 설정의 형식대로 바꾼다. 변환기가 없거나 실패하면 받은 그대로 저장한다.
            if (format == "mp3" && transcoder.isAvailable()) {
                val out = File(partsDir, "$id.conv").also { converted = it }
                val ok = try {
                    transcoder.convertAudio(audio.file.absolutePath, out.absolutePath, "libmp3lame", 192, "mp3")
                } catch (e: Exception) {
                    false
                }
                checkAbort()
                if (ok && out.length() > 0) audio = Downloaded(out, "mp3", "audio/mpeg")
            }

            val lyrics = lyricsFor(request)
            checkAbort()
            writeTags(audio.file, audio.extension, request, lyrics)
            checkAbort()

            val folder = request.optString("resolvedFolder", request.optString("savePath", ""))
                .ifEmpty { DEFAULT_MUSIC_FOLDER }
            val saved = saveToStore(audio.file, folder, audio.extension, audio.mime, request, video = false)
            register(item, request, saved.first, saved.second, lyrics, remember = true, video = false)
            emit("saved", folder)
            synchronized(lock) {
                item.status = DONE; item.progress = 1.0; item.processing = false; item.savedFolder = saved.second
                item.partMime = null
            }
            changed()
        } catch (e: Aborted) {
            // 취소(목록에서 이미 뺐다) 또는 일시정지(상태를 이미 바꿨다)다.
        } catch (e: YtDlpException) {
            emit("engineError", e.message ?: "")
            fail(item, engineMessage(e))
        } catch (e: Failed) {
            fail(item, e.message ?: "받지 못했어요")
        } catch (e: Exception) {
            MuloLog.e(MuloLog.NATIVE, "받기 실패: ${e.message}", e)
            fail(item, e.message ?: e.toString())
        } finally {
            val keep = synchronized(lock) { items.firstOrNull { it.id == id }?.status.let { it == PAUSED || it == FAILED } }
            if (!keep) {
                part.delete()
                synchronized(lock) { item.partMime = null }
            }
            converted?.delete()
            runningId = null
            abort = null
        }
    }

    private fun fail(item: Item, message: String) {
        synchronized(lock) {
            if (items.none { it.id == item.id }) return
            item.status = FAILED
            item.processing = false
            item.error = message.lines().map { it.trim() }.filter { it.isNotEmpty() }.joinToString(" / ")
        }
        changed()
    }

    private fun engineMessage(e: YtDlpException): String = when (e.code) {
        "unavailable" -> "받을 수 있는 엔진이 없어요"
        "network" -> "네트워크에 닿지 못했어요"
        "timeout" -> "응답이 너무 오래 걸려요"
        "unauthorized" -> "서버가 로그인을 요구해요"
        "not_found" -> "찾을 수 없는 주소예요"
        else -> if ((e.message ?: "").isEmpty()) "주소를 읽지 못했어요" else e.message!!
    }

    private fun deletePart(id: String) {
        File(partsDir, "$id.part").delete()
    }

    // ── 영상 저장 ──

    private fun runVideo(item: Item, videoFormat: String) {
        val request = item.request
        val folder = request.optString("resolvedFolder", request.optString("savePath", ""))
            .ifEmpty { DEFAULT_VIDEO_FOLDER }
        val extension = if (videoFormat == "webm") "webm" else "mp4"
        val mime = if (extension == "webm") "video/webm" else "video/mp4"
        val lyrics = lyricsFor(request)
        checkAbort()
        val dir = File(context.cacheDir, "mulo_video").also { it.mkdirs() }
        val stem = "video_${System.nanoTime()}"
        var shown = 0.0
        try {
            val tag = runningId
            val save = {
                ytdlp.saveVideo(request.optString("url"), request.optInt("videoHeight", 1080), extension, dir, stem) { p ->
                    // 일시정지 · 취소는 받는 중에도 바로 먹는다 (조각을 받을 때마다 확인한다).
                    if (abort != null) throw java.util.concurrent.CancellationException("받기 중단")
                    if (p - shown >= PROGRESS_STEP) {
                        shown = p
                        synchronized(lock) {
                            if (item.status == DOWNLOADING) { item.progress = p; item.processing = p >= 0.98 }
                        }
                        progressed()
                    }
                }
            }
            try {
                if (tag == null) save() else ytdlp.tagged(tag) { save() }
            } catch (e: java.util.concurrent.CancellationException) {
                throw Aborted()
            } catch (e: YtDlpException) {
                if (abort != null) throw Aborted()
                throw e
            }
            checkAbort()
            val out = File(dir, "$stem.$extension")
            if (!out.exists() || out.length() == 0L) throw Failed("영상을 저장하지 못했어요 (no output file)")
            writeTags(out, extension, request, lyrics)
            checkAbort()
            val saved = saveToStore(out, folder, extension, mime, request, video = true)
            register(item, request, saved.first, saved.second, lyrics, remember = false, video = true)
            synchronized(lock) {
                item.status = DONE; item.progress = 1.0; item.processing = false; item.savedFolder = folder
            }
            changed()
        } finally {
            dir.listFiles { f -> f.name.startsWith(stem) }?.forEach { it.delete() }
        }
    }

    // ── 주소 읽기 ──

    private class Stream(
        val url: String,
        val headers: Map<String, String>,
        val hls: Boolean,
        val codec: String?,
        val fallbacks: List<Pair<String, Map<String, String>>>,
    )

    private class Downloaded(val file: File, val extension: String, val mime: String)

    @Suppress("UNCHECKED_CAST")
    private fun toStream(m: Map<String, Any?>) = Stream(
        m["url"] as String,
        (m["headers"] as? Map<String, String>) ?: emptyMap(),
        m["hls"] == true,
        m["codec"] as? String,
        ((m["fallbacks"] as? List<Map<String, Any?>>) ?: emptyList()).map {
            (it["url"] as String) to ((it["headers"] as? Map<String, String>) ?: emptyMap())
        },
    )

    /** 네이티브(유튜브) → yt-dlp 순으로 소리 주소를 읽는다. */
    /**
     * 주소 읽기가 멈춰도 받기 줄 전체가 막히지 않게, 따로 돌리고 기다린다: 일시정지 · 취소는 0.3초 안에 먹고,
     * 60초가 지나도 못 읽으면 실패로 처리한다 (다시 시도할 수 있다).
     */
    private fun resolveAudio(url: String, language: String?, refresh: Boolean): Stream {
        val tag = runningId
        val task = resolver.submit<Stream> { resolveAudioNow(url, language, refresh, tag) }
        val limit = System.currentTimeMillis() + RESOLVE_LIMIT_MS
        while (true) {
            if (abort != null) {
                task.cancel(true)
                tag?.let { ytdlp.cancelTagged(it) }
                throw Aborted()
            }
            try {
                return task.get(300, java.util.concurrent.TimeUnit.MILLISECONDS)
            } catch (_: java.util.concurrent.TimeoutException) {
                if (System.currentTimeMillis() > limit) {
                    task.cancel(true)
                    MuloLog.d(MuloLog.NATIVE, "받기 주소 읽기 시간 초과 ${RESOLVE_LIMIT_MS}ms")
                    throw Failed("응답이 너무 오래 걸려요")
                }
            } catch (e: java.util.concurrent.ExecutionException) {
                // 일시정지 · 취소로 yt-dlp가 끊겨 난 오류는 실패가 아니다.
                if (abort != null) throw Aborted()
                throw e.cause ?: e
            }
        }
    }

    private fun resolveAudioNow(url: String, language: String?, refresh: Boolean, tag: String?): Stream {
        val clock = System.currentTimeMillis()
        val id = NativeVideoSaver.youtubeIdOf(url)
        var nativeError: String? = null
        if (id != null) {
            try {
                YoutubeResolver.audio(id, language, true, refresh)?.let {
                    MuloLog.d(MuloLog.NATIVE, "받기 주소 읽기(네이티브) ${System.currentTimeMillis() - clock}ms")
                    return toStream(it)
                }
                MuloLog.d(MuloLog.NATIVE, "받기 주소 읽기(네이티브) 결과 없음 ${System.currentTimeMillis() - clock}ms")
            } catch (e: Exception) {
                nativeError = e.message
                MuloLog.d(MuloLog.NATIVE, "받기 주소 읽기(네이티브) 실패 ${System.currentTimeMillis() - clock}ms: ${e.message}")
            }
        }
        try {
            val r = toStream(if (tag == null) ytdlp.audio(url, language) else ytdlp.tagged(tag) { ytdlp.audio(url, language) })
            MuloLog.d(MuloLog.NATIVE, "받기 주소 읽기(yt-dlp) ${System.currentTimeMillis() - clock}ms")
            return r
        } catch (e: YtDlpException) {
            MuloLog.d(MuloLog.NATIVE, "받기 주소 읽기(yt-dlp) 실패 ${System.currentTimeMillis() - clock}ms: ${e.message}")
            if (nativeError == null) throw e
            throw YtDlpException(e.code, "네이티브: $nativeError | ${e.message}")
        }
    }

    // ── 받기 (조각 이어받기) ──

    private fun downloadAudio(
        stream: Stream,
        target: File,
        resumeMime: String?,
        onMime: (String) -> Unit,
        onProgress: (Double) -> Unit,
    ): Downloaded {
        val errors = ArrayList<String>()
        var resume = resumeMime
        val all = listOf(stream.url to stream.headers) + stream.fallbacks
        for ((u, h) in all) {
            checkAbort()
            try {
                return downloadOne(u, h, target, resume, onMime, onProgress)
            } catch (e: Failed) {
                errors.add(e.message ?: "")
            }
            // 앞 주소가 남긴 부분 파일은 다른 주소와 이어 붙이지 않는다.
            resume = null
        }
        throw Failed(errors.joinToString(" | "))
    }

    private class Chunk(val bytes: ByteArray, val total: Long?, val wholeBody: Boolean, val mime: String?)

    private fun downloadOne(
        url: String,
        headers: Map<String, String>,
        target: File,
        resumeMime: String?,
        onMime: (String) -> Unit,
        onProgress: (Double) -> Unit,
    ): Downloaded {
        val urlMime = Regex("[?&]mime=([^&]+)").find(url)?.groupValues?.get(1)?.let { java.net.URLDecoder.decode(it, "UTF-8") }
        var offset = 0L
        if (resumeMime != null && target.exists()) {
            val same = urlMime == null || normalizeMime(urlMime) == resumeMime
            if (same && target.length() > 0) offset = target.length()
        }
        var mime: String? = if (offset > 0) resumeMime else urlMime
        var total: Long? = null
        var announced = false
        var out = java.io.FileOutputStream(target, offset > 0)
        try {
            while (total == null || offset < total) {
                checkAbort()
                val chunk = requestChunk(url, headers, offset, offset + CHUNK - 1) { pos, known ->
                    // 조각을 받는 중에도 진행률을 알린다 (한 곡이 한 조각이어도 0에서 100으로 뛰지 않게).
                    val t = known ?: total
                    if (t != null && t > 0) onProgress((pos.toDouble() / t).coerceIn(0.0, 0.999))
                }
                if (mime == null) mime = chunk.mime
                total = chunk.total ?: (offset + chunk.bytes.size)
                if (chunk.bytes.isEmpty()) {
                    // 이미 다 받아 둔 파일을 이어받으려 한 경우(범위 밖 요청)는 끝난 것으로 본다.
                    if (offset > 0 && offset >= total) break
                    throw Failed("빈 응답")
                }
                if (chunk.wholeBody) {
                    // 서버가 구간을 무시하고 전부 보냈다: 앞에서 받은 것을 버리고 처음부터 쓴다.
                    offset = 0
                    out.close()
                    out = java.io.FileOutputStream(target, false)
                }
                out.write(chunk.bytes)
                offset += chunk.bytes.size
                if (!announced) {
                    announced = true
                    onMime(normalizeMime(mime))
                }
                onProgress(if (total == 0L) 0.0 else (offset.toDouble() / total).coerceIn(0.0, 1.0))
            }
            onProgress(1.0)
            out.flush()
        } catch (e: Aborted) {
            throw e
        } catch (e: Failed) {
            throw e
        } catch (e: Exception) {
            throw Failed("$e")
        } finally {
            try {
                out.close()
            } catch (_: Exception) {
            }
        }
        val m = normalizeMime(mime)
        return Downloaded(target, extensionFor(m), m)
    }

    /** [onRead]: 지금까지 받은 위치(파일 기준)와, 응답에서 알게 된 전체 크기(모르면 null). */
    private fun requestChunk(url: String, headers: Map<String, String>, from: Long, to: Long, onRead: (Long, Long?) -> Unit): Chunk {
        var last: Exception? = null
        for (attempt in 0..RETRIES_PER_CHUNK) {
            checkAbort()
            var conn: HttpURLConnection? = null
            try {
                conn = (URL(url).openConnection() as HttpURLConnection).apply {
                    connectTimeout = 15_000
                    readTimeout = 20_000
                    headers.forEach { (k, v) -> setRequestProperty(k, v) }
                    setRequestProperty("Range", "bytes=$from-$to")
                }
                activeConn = conn
                // 일시정지 · 취소가 연결을 기다리는 동안(최대 20초)에 눌렸으면 기다리지 않고 바로 끊는다.
                checkAbort()
                val status = conn.responseCode
                if (status == 416 && from > 0) return Chunk(ByteArray(0), from, false, null) // 받아 둔 만큼이 이미 전체다.
                if (status != 206 && status != 200) {
                    // 403 등은 다시 해도 같다. 다음 형식 주소로 넘어간다.
                    if (status == 403 || status == 404 || status == 410) throw Failed("HTTP $status (구간 $from)")
                    throw IOException("HTTP $status")
                }
                val range = conn.getHeaderField("Content-Range")
                val totalFromRange = range?.substringAfterLast('/')?.toLongOrNull()
                val length = conn.contentLengthLong
                val knownTotal = if (status == 206) totalFromRange else if (length > 0) length else null
                val base = if (status == 206) from else 0L
                val buf = ByteArrayOutputStream()
                conn.inputStream.use { input ->
                    val b = ByteArray(64 * 1024)
                    while (true) {
                        checkAbort()
                        val n = input.read(b)
                        if (n < 0) break
                        buf.write(b, 0, n)
                        onRead(base + buf.size(), knownTotal)
                    }
                }
                return Chunk(
                    buf.toByteArray(),
                    if (status == 206) totalFromRange else if (length > 0) length else null,
                    status == 200,
                    conn.contentType?.substringBefore(';')?.trim(),
                )
            } catch (e: Aborted) {
                throw e
            } catch (e: Failed) {
                throw e
            } catch (e: Exception) {
                last = e
                // 인터넷이 끊겼다 돌아오는 동안(와이파이 · 데이터 전환) 기다리며 다시 시도한다: 1 · 2 · 4 · 8초, 이후 8초씩.
                sleepChecked(if (attempt < 3) 1000L shl attempt else 8000L)
            } finally {
                if (activeConn === conn) activeConn = null
                conn?.disconnect()
            }
        }
        throw Failed("$last")
    }

    private fun sleepChecked(ms: Long) {
        var left = ms
        while (left > 0) {
            checkAbort()
            val step = minOf(left, 200L)
            Thread.sleep(step)
            left -= step
        }
    }

    private fun normalizeMime(mime: String?): String {
        val m = mime?.substringBefore(';')?.trim()?.lowercase()
        return if (m == null || !m.startsWith("audio/")) "audio/webm" else m
    }

    private fun extensionFor(mime: String) = when (mime) {
        "audio/mp4", "audio/x-m4a", "audio/m4a" -> "m4a"
        "audio/mpeg" -> "mp3"
        "audio/ogg", "audio/opus" -> "opus"
        else -> "weba"
    }

    // ── 가사 · 태그 ──

    /** 받은 곡에 넣을 가사 글. 고쳐 둔 글이 있으면 그대로, 아니면 영상 자막을 싱크 가사(.lrc)로. 못 읽어도 받기는 성공으로 둔다. */
    private fun lyricsFor(request: JSONObject): String? {
        if (!request.optBoolean("importLyrics", false)) return null
        val text = request.optString("lyricsText", "")
        if (text.isNotBlank()) return text
        return try {
            val language = request.optString("lyricsLanguage", "")
            val prefer = if (language.isEmpty()) listOf("ko", "en") else listOf(language)
            // 가사 읽기는 yt-dlp를 두 번 돌려 20초 넘게 걸릴 수 있다: 따로 돌리고, 일시정지 · 취소는 바로 먹고,
            // 너무 오래 걸리면 가사 없이 저장한다.
            val tag = runningId
            val url = request.optString("url")
            val task = resolver.submit<Map<String, Any?>?> {
                if (tag == null) ytdlp.subtitles(url, prefer) else ytdlp.tagged(tag) { ytdlp.subtitles(url, prefer) }
            }
            val limit = System.currentTimeMillis() + LYRICS_LIMIT_MS
            var found: Map<String, Any?>? = null
            while (true) {
                if (abort != null) {
                    task.cancel(true)
                    tag?.let { ytdlp.cancelTagged(it) }
                    throw Aborted()
                }
                try {
                    found = task.get(300, java.util.concurrent.TimeUnit.MILLISECONDS)
                    break
                } catch (_: java.util.concurrent.TimeoutException) {
                    if (System.currentTimeMillis() > limit) {
                        task.cancel(true)
                        tag?.let { ytdlp.cancelTagged(it) }
                        MuloLog.d(MuloLog.NATIVE, "받기 가사 읽기 시간 초과: 가사 없이 저장")
                        return null
                    }
                } catch (e: java.util.concurrent.ExecutionException) {
                    if (abort != null) throw Aborted()
                    throw e.cause ?: e
                }
            }
            @Suppress("UNCHECKED_CAST")
            val track = found ?: return null
            @Suppress("UNCHECKED_CAST")
            val lrc = SubtitleLrc.toLrc(track["cues"] as List<Map<String, Any?>>, request.optBoolean("lyricsSkipSounds", true))
            lrc.ifEmpty { null }
        } catch (e: Aborted) {
            throw e
        } catch (e: Exception) {
            null
        }
    }

    /** 제목 · 커버 등을 파일 태그에 쓴다. 못 써도 파일은 그대로 저장한다 (결과는 화면이 알린다). */
    private fun writeTags(file: File, extension: String, request: JSONObject, lyrics: String?) {
        val values = LinkedHashMap<String, String>()
        fun put(k: String, v: String?) {
            if (!v.isNullOrBlank()) values[k] = v
        }
        put("title", request.optString("title"))
        put("artist", request.optString("artist"))
        put("album", request.optString("album"))
        put("genre", request.optString("genre"))
        put("lyrics", lyrics)
        if (request.has("color") && !request.isNull("color")) {
            values["COVER_COLOR"] = java.lang.Long.toHexString(request.optLong("color") and 0xFFFFFFFFL).padStart(8, '0')
        }
        val cover = request.optJSONObject("cover")
        val source = coverSource(cover, request.optString("thumbnailUrl", "").ifEmpty { null })
        val coverMap = source?.let {
            mapOf(
                "path" to it.absolutePath,
                "scale" to (cover?.optDouble("scale", 1.0) ?: 1.0),
                "dx" to (cover?.optDouble("dx", 0.0) ?: 0.0),
                "dy" to (cover?.optDouble("dy", 0.0) ?: 0.0),
                "rotation" to (cover?.optDouble("rotation", 0.0) ?: 0.0),
            )
        }
        val result = try {
            tags.writeBlocking(file.absolutePath, extension, values, coverMap, false)
        } catch (e: Exception) {
            mapOf("status" to "failed", "error" to (e.message ?: e.toString()))
        }
        val status = result["status"] as? String ?: "failed"
        if (status != "unsupported") {
            emit(
                "tagNotice",
                mapOf(
                    "title" to request.optString("title"), "extension" to extension, "ok" to (status == "written"),
                    "detail" to (if (status == "written") "cover=${result["cover"]}" else (result["error"] ?: status).toString()),
                ),
            )
        }
    }

    /** 커버 원본 이미지 파일: 고른 파일이면 그대로, 웹 주소면 내려받는다. 없으면 null. */
    private fun coverSource(cover: JSONObject?, thumbnailUrl: String?): File? {
        val path = cover?.optString("path", "").orEmpty()
        if (path.isNotEmpty()) return File(path).takeIf { it.exists() }
        val url = (if (cover != null && !cover.isNull("url")) cover.optString("url") else null) ?: thumbnailUrl
        if (url.isNullOrEmpty()) return null
        return try {
            val out = File(context.cacheDir, "dl_cover_${url.hashCode()}")
            if (out.exists() && out.length() > 0) return out
            val conn = (URL(url).openConnection() as HttpURLConnection).apply {
                connectTimeout = 15_000
                readTimeout = 20_000
            }
            conn.inputStream.use { i -> out.outputStream().use { o -> i.copyTo(o) } }
            out.takeIf { it.length() > 0 }
        } catch (e: Exception) {
            null
        }
    }

    // ── 저장 · 보관함 등록 ──

    /** 파일을 MediaStore에 저장하고 (content 주소, 저장된 폴더)를 돌려준다. 원본 임시 파일은 지운다. */
    private fun saveToStore(file: File, folder: String, extension: String, mime: String, request: JSONObject, video: Boolean): Pair<String, String> {
        val relative = if (video) relativePath(folder, VIDEO_DIRS, "Movies/Mulo") else relativePath(folder, MEDIA_DIRS, "Music/Mulo")
        // webm(`audio/webm`)은 MediaStore가 거절하므로 같은 opus 오디오를 ogg(`.opus`)로 등록한다.
        val (ext, type) = if (!video && (mime == "audio/webm" || extension == "weba" || extension == "webm")) "opus" to "audio/ogg" else extension to mime
        val uri = store.saveAudio(
            path = file.absolutePath,
            displayName = "${fileName(request)}.$ext",
            mime = type,
            relativePath = relative,
            title = request.optString("title"),
            artist = request.optString("artist"),
            video = video,
        )
        file.delete()
        return uri to "/storage/emulated/0/$relative"
    }

    private fun register(item: Item, request: JSONObject, uri: String, folder: String, lyrics: String?, remember: Boolean, video: Boolean) {
        val trackId = "download:${item.id}"
        val cover = request.optJSONObject("cover")
        val thumb = request.optString("thumbnailUrl", "")
        val coverJson: JSONObject? = when {
            cover != null && !cover.isNull("url") -> JSONObject()
                .put("url", cover.getString("url")).put("path", "")
                .put("scale", cover.optDouble("scale", 1.0)).put("dx", cover.optDouble("dx", 0.0))
                .put("dy", cover.optDouble("dy", 0.0)).put("rotation", cover.optDouble("rotation", 0.0))
            cover != null && cover.optString("path", "").isNotEmpty() -> copyCover(trackId, cover)
            thumb.isNotEmpty() -> JSONObject().put("url", thumb).put("path", "")
            else -> null
        }
        val lyricsPath = lyrics?.let { saveLyrics(trackId, it) }
        val reg = AppDb.Registration(
            trackId, request.optString("title"), request.optString("artist"), request.optString("album"),
            request.optString("genre"), if (request.has("durationMs") && !request.isNull("durationMs")) request.optLong("durationMs") else 0L,
            uri, folder, if (video) (if (request.optString("videoFormat") == "webm") "video/webm" else "video/mp4") else "",
            System.currentTimeMillis() / 1000, playlistIdsOf(request).toList(), coverJson,
            if (request.has("color") && !request.isNull("color")) request.optLong("color") else null,
            lyricsPath,
        )
        // 보관함 DB는 Dart가 쥔다: 맡겨 두고 넘기면 Dart가 등록한 뒤 `ack`로 알려 준다.
        pending.add(reg)
        MuloLog.d(MuloLog.NATIVE, "보관함 등록을 Dart에 넘김: $trackId")
        emit("registered", toDartMap(reg.toJson()))
        if (remember) {
            synchronized(lock) { sources[sourceKey(request.optString("url"))] = trackId }
            persistSources()
        }
    }

    /** 고른 사진을 앱 폴더(`covers/`)로 복사한다 (원본이 지워져도 커버가 남도록). */
    private fun copyCover(trackId: String, cover: JSONObject): JSONObject? {
        return try {
            val src = File(cover.getString("path"))
            val dir = File(context.filesDir, "covers").also { it.mkdirs() }
            val ext = src.extension.let { if (it.isEmpty()) "img" else it }
            val dest = File(dir, "${trackId.replace(Regex("[^\\w]"), "_")}_${System.currentTimeMillis() * 1000}.$ext")
            src.copyTo(dest, overwrite = true)
            JSONObject().put("path", dest.absolutePath).put("scale", cover.optDouble("scale", 1.0))
                .put("dx", cover.optDouble("dx", 0.0)).put("dy", cover.optDouble("dy", 0.0))
                .put("rotation", cover.optDouble("rotation", 0.0))
        } catch (e: Exception) {
            null
        }
    }

    /** 가사 글을 앱 폴더(`lyrics/`)에 파일로 쓴다 (싱크 가사면 .lrc, 아니면 .txt). 경로를 돌려준다. */
    private fun saveLyrics(trackId: String, text: String): String? = try {
        val dir = File(context.filesDir, "lyrics").also { it.mkdirs() }
        val synced = Regex("^\\[\\d{1,3}:\\d{2}([.:]\\d{1,3})?]", RegexOption.MULTILINE).containsMatchIn(text)
        val file = File(dir, "${trackId.replace(Regex("[^\\w]"), "_")}.${if (synced) "lrc" else "txt"}")
        file.writeText(text)
        file.absolutePath
    } catch (e: Exception) {
        null
    }

    private fun playlistIdsOf(request: JSONObject): Set<String> {
        val a = request.optJSONArray("playlistIds") ?: return emptySet()
        return (0 until a.length()).map { a.getString(it) }.toSet()
    }

    private fun relativePath(folder: String, allowed: Set<String>, fallback: String): String {
        val f = folder.replace('\\', '/')
        if (f.startsWith(ROOT)) {
            val rest = f.removePrefix(ROOT).trim('/')
            if (rest.isNotEmpty() && allowed.contains(rest.substringBefore('/'))) return rest
        }
        return fallback
    }

    private fun fileName(r: JSONObject): String {
        val title = r.optString("title")
        val artist = r.optString("artist")
        val raw = if (artist.isEmpty()) title else "$artist - $title"
        val clean = raw.replace(Regex("[\\\\/:*?\"<>|]"), " ").replace(Regex("\\s+"), " ").trim()
        val cut = if (clean.length > 120) clean.substring(0, 120).trim() else clean
        return cut.ifEmpty { "download" }
    }

    private fun sourceKey(url: String): String {
        val trimmed = url.trim()
        val id = NativeVideoSaver.youtubeIdOf(trimmed)
        return if (id == null) trimmed else "youtube:$id"
    }

    fun dispose() {
        abort = "cancel"
        worker.shutdownNow()
        resolver.shutdownNow()
        watchdog.shutdownNow()
        saver.shutdownNow()
    }

    companion object {
        const val DOWNLOADING = "downloading"
        const val QUEUED = "queued"
        const val PAUSED = "paused"
        const val FAILED = "failed"
        const val DONE = "done"

        private const val PROGRESS_STEP = 0.01
        private const val RESOLVE_LIMIT_MS = 60_000L
        private const val LYRICS_LIMIT_MS = 30_000L
        private const val CHUNK = 10L * 1024 * 1024
        private const val RETRIES_PER_CHUNK = 6
        private const val ROOT = "/storage/emulated/0/"
        private const val DEFAULT_MUSIC_FOLDER = "/storage/emulated/0/Music/Mulo"
        private const val DEFAULT_VIDEO_FOLDER = "/storage/emulated/0/Movies/Mulo"
        private val VIDEO_DIRS = setOf("Movies", "DCIM", "Pictures", "Download")
        private val MEDIA_DIRS = setOf("Music", "Podcasts", "Ringtones", "Alarms", "Notifications", "Audiobooks", "Recordings")
    }
}
