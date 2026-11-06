package com.mulo.app

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import java.io.File
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * 기기 음악 불러오기 (상세 기능 #11): MediaStore에서 음악 파일 목록을 읽어 Flutter로 보낸다.
 * 내장 커버: 곡 파일의 내장 이미지를 꺼낸다.
 * 곡 삭제: 음악 파일을 지운다. 앱이 만든 파일이 아니면 Android 10+가 삭제 동의 창을 띄운다.
 * 권한 요청은 Flutter(permission_handler)가 먼저 한다.
 */
class MediaStoreChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activity: () -> Activity?,
) : NativeChannel(messenger, NAME) {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** 삭제 동의 창 결과를 기다리는 요청 (동시에 하나만). */
    private class PendingDelete(
        val uri: Uri,
        val result: MethodChannel.Result,
        /** Android 10은 동의 뒤 앱이 다시 지워야 한다 (11+는 시스템이 지움). */
        val retry: Boolean,
    )

    private var pendingDelete: PendingDelete? = null

    /** 쓰기 동의 창 결과를 기다리는 요청 (동시에 하나만). */
    private class PendingWrite(val uri: Uri, val src: File?, val result: MethodChannel.Result)

    private var pendingWrite: PendingWrite? = null

    private fun overwrite(uri: Uri, src: File): Boolean =
        context.contentResolver.openOutputStream(uri, "wt")?.use { o ->
            src.inputStream().use { i -> i.copyTo(o) }
            true
        } ?: false

    /** 앱이 만든 파일이 아니라 쓸 수 없을 때(다시 설치 뒤 등) 시스템 동의 창을 띄운다. 못 띄우면 false. */
    private fun requestWrite(uri: Uri, src: File?, e: SecurityException, result: MethodChannel.Result) {
        if (pendingWrite != null) {
            result.success(false)
            return
        }
        val sender = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
                MediaStore.createWriteRequest(context.contentResolver, listOf(uri)).intentSender
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && e is RecoverableSecurityException ->
                e.userAction.actionIntent.intentSender
            else -> null
        }
        val host = activity()
        if (sender == null || host == null) {
            result.success(false)
            return
        }
        pendingWrite = PendingWrite(uri, src, result)
        try {
            host.startIntentSenderForResult(sender, REQUEST_WRITE, null, 0, 0, 0)
        } catch (ex: Exception) {
            pendingWrite = null
            result.success(false)
        }
    }

    /** 곡 파일의 크기(byte) · 형식(mime) · 비트레이트(bps) · 샘플레이트(Hz). 알 수 없는 값은 키를 뺀다. */
    private fun fileInfo(uri: Uri): Map<String, Any> {
        val out = mutableMapOf<String, Any>()
        context.contentResolver.openFileDescriptor(uri, "r")?.use { out["size"] = it.statSize }
        context.contentResolver.getType(uri)?.let { out["mime"] = it }
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, uri)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)
                ?.toIntOrNull()?.let { out["bitrate"] = it }
        } catch (e: Exception) {
            // 읽지 못하면 비트레이트는 비운다.
        } finally {
            retriever.release()
        }
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(context, uri, null)
            if (extractor.trackCount > 0) {
                val format = extractor.getTrackFormat(0)
                if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
                    out["sampleRate"] = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                }
            }
        } catch (e: Exception) {
            // 읽지 못하면 샘플레이트는 비운다.
        } finally {
            extractor.release()
        }
        return out
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "queryAudio" -> io.execute {
                    try {
                        val rows = queryAudio()
                        main.post { result.success(rows) }
                    } catch (e: SecurityException) {
                        main.post { result.error("permission", e.message, null) }
                    } catch (e: Exception) {
                        main.post { result.error("query_failed", e.message, null) }
                    }
                }
                "queryVideo" -> io.execute {
                    try {
                        val rows = queryVideo()
                        main.post { result.success(rows) }
                    } catch (e: SecurityException) {
                        main.post { result.error("permission", e.message, null) }
                    } catch (e: Exception) {
                        main.post { result.error("query_failed", e.message, null) }
                    }
                }
                "saveAudio" -> runAsync(io, result, "save_failed") {
                    saveAudio(
                        path = call.argument<String>("path")!!,
                        displayName = call.argument<String>("displayName")!!,
                        mime = call.argument<String>("mime")!!,
                        relativePath = call.argument<String>("relativePath")!!,
                        title = call.argument<String>("title") ?: "",
                        artist = call.argument<String>("artist") ?: "",
                    )
                }
                "embeddedPicture" -> {
                    val uri = Uri.parse(call.argument<String>("uri"))
                    io.execute {
                        // 내장 커버가 없거나 못 읽으면 null (기본 커버 유지).
                        val bytes = try {
                            embeddedPicture(uri)
                        } catch (e: Exception) {
                            null
                        }
                        main.post { result.success(bytes) }
                    }
                }
                "fileInfo" -> {
                    val uri = Uri.parse(call.argument<String>("uri"))
                    io.execute {
                        // 크기 · 형식 · 비트레이트 · 샘플레이트. 못 읽는 값은 빼고 돌려준다.
                        val info = try {
                            fileInfo(uri)
                        } catch (e: Exception) {
                            emptyMap()
                        }
                        main.post { result.success(info) }
                    }
                }
                "mimeType" -> result.success(
                    try {
                        context.contentResolver.getType(Uri.parse(call.argument<String>("uri")))
                    } catch (e: Exception) {
                        null
                    },
                )
                "ensureWrite" -> {
                    // 곡 파일에 쓸 수 있는지 먼저 확인한다 (내용은 건드리지 않는다).
                    // 쓸 수 없고 ask가 true면 수정 전에 시스템 동의 창을 띄운다.
                    val uri = Uri.parse(call.argument<String>("uri"))
                    val ask = call.argument<Boolean>("ask") ?: false
                    io.execute {
                        var denied: SecurityException? = null
                        val ok = try {
                            context.contentResolver.openFileDescriptor(uri, "rw")?.use { true } ?: false
                        } catch (e: SecurityException) {
                            denied = e
                            false
                        } catch (e: Exception) {
                            false
                        }
                        main.post {
                            if (!ok && denied != null && ask) {
                                requestWrite(uri, null, denied, result)
                            } else {
                                result.success(ok)
                            }
                        }
                    }
                }
                "overwriteAudio" -> {
                    // 태그를 고친 임시 파일로 곡 파일을 덮어쓴다. 쓸 권한이 없으면 false.
                    // ask가 true면 (사용자가 직접 한 저장) 시스템 동의 창을 띄우고 허용 뒤 다시 쓴다.
                    val uri = Uri.parse(call.argument<String>("uri"))
                    val src = File(call.argument<String>("path")!!)
                    val ask = call.argument<Boolean>("ask") ?: false
                    io.execute {
                        var denied: SecurityException? = null
                        val ok = try {
                            overwrite(uri, src)
                        } catch (e: SecurityException) {
                            denied = e
                            false
                        } catch (e: Exception) {
                            false
                        }
                        main.post {
                            if (!ok && denied != null && ask) {
                                requestWrite(uri, src, denied, result)
                            } else {
                                result.success(ok)
                            }
                        }
                    }
                }
                "deleteAudio" -> deleteAudio(Uri.parse(call.argument<String>("uri")), result)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 받아 둔 임시 파일을 MediaStore의 음악 폴더(`Music/Mulo` 등)로 저장하고 content:// 주소를 돌려준다.
     * 다 쓸 때까지 IS_PENDING으로 숨겨 두어 반쪽 파일이 목록에 뜨지 않게 한다.
     */
    private fun saveAudio(
        path: String,
        displayName: String,
        mime: String,
        relativePath: String,
        title: String,
        artist: String,
    ): String {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, mime)
            if (title.isNotEmpty()) put(MediaStore.Audio.Media.TITLE, title)
            if (artist.isNotEmpty()) put(MediaStore.Audio.Media.ARTIST, artist)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Audio.Media.RELATIVE_PATH, relativePath)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            } else {
                // Android 9 이하: 상대 경로 칸이 없어 파일 위치를 직접 정한다.
                val dir = File(Environment.getExternalStorageDirectory(), relativePath)
                dir.mkdirs()
                put(MediaStore.Audio.Media.DATA, File(dir, displayName).absolutePath)
            }
        }
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore에 곡을 만들지 못했어요")
        try {
            resolver.openOutputStream(uri)!!.use { out ->
                File(path).inputStream().use { it.copyTo(out) }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val done = ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }
                resolver.update(uri, done, null, null)
            }
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        return uri.toString()
    }

    /** 음악 파일에 내장된 커버 이미지(ID3 APIC · m4a covr · FLAC picture 등)의 원본 바이트. 없으면 null. */
    private fun embeddedPicture(uri: Uri): ByteArray? {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, uri)
            return retriever.embeddedPicture
        } finally {
            retriever.release()
        }
    }

    private fun deleteAudio(uri: Uri, result: MethodChannel.Result) {
        if (pendingDelete != null) {
            result.error("busy", "다른 삭제를 기다리는 중이에요", null)
            return
        }
        try {
            // 이미 없으면 0행이라도 지운 것으로 본다.
            context.contentResolver.delete(uri, null, null)
            result.success(true)
        } catch (e: SecurityException) {
            val sender = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
                    MediaStore.createDeleteRequest(context.contentResolver, listOf(uri)).intentSender
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && e is RecoverableSecurityException ->
                    e.userAction.actionIntent.intentSender
                else -> null
            }
            val host = activity()
            if (sender == null || host == null) {
                result.success(false)
                return
            }
            pendingDelete = PendingDelete(uri, result, Build.VERSION.SDK_INT < Build.VERSION_CODES.R)
            try {
                host.startIntentSenderForResult(sender, REQUEST_DELETE, null, 0, 0, 0)
            } catch (e: Exception) {
                pendingDelete = null
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("delete_failed", e.message, null)
        }
    }

    /** MainActivity.onActivityResult에서 부른다. 이 채널의 요청이면 true. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode == REQUEST_WRITE) {
            val pending = pendingWrite ?: return true
            pendingWrite = null
            if (resultCode != Activity.RESULT_OK) {
                pending.result.success(false)
            } else if (pending.src == null) {
                // 쓰기 확인만 구한 요청: 허용했으면 끝.
                pending.result.success(true)
            } else {
                // 허용했다: 이제 쓸 수 있으니 다시 쓴다.
                io.execute {
                    val ok = try {
                        overwrite(pending.uri, pending.src)
                    } catch (e: Exception) {
                        false
                    }
                    main.post { pending.result.success(ok) }
                }
            }
            return true
        }
        if (requestCode != REQUEST_DELETE) return false
        val pending = pendingDelete ?: return true
        pendingDelete = null
        if (resultCode != Activity.RESULT_OK) {
            pending.result.success(false)
        } else if (pending.retry) {
            try {
                context.contentResolver.delete(pending.uri, null, null)
                pending.result.success(true)
            } catch (e: Exception) {
                pending.result.success(false)
            }
        } else {
            pending.result.success(true)
        }
        return true
    }

    private fun queryAudio(): List<Map<String, Any?>> {
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DATE_ADDED,
        )
        val rows = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            collection,
            projection,
            "${MediaStore.Audio.Media.IS_MUSIC} != 0",
            null,
            "${MediaStore.Audio.Media.TITLE} ASC",
        )?.use { c ->
            val id = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val title = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artist = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val album = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val duration = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val data = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val dateAdded = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            while (c.moveToNext()) {
                val mediaId = c.getLong(id)
                rows += mapOf(
                    "id" to mediaId,
                    "title" to c.getString(title),
                    "artist" to c.getString(artist),
                    "album" to c.getString(album),
                    "durationMs" to c.getLong(duration),
                    "uri" to ContentUris.withAppendedId(collection, mediaId).toString(),
                    // 불러오는 폴더로 거르고 폴더별 곡 수를 세는 데 쓴다.
                    "folder" to c.getString(data)?.let { File(it).parent },
                    // 파일이 기기에 들어온 시각(밀리초). 추가일순 정렬에 쓴다.
                    "addedAtMs" to c.getLong(dateAdded) * 1000,
                )
            }
        }
        return rows
    }

    /** 기기의 영상 파일. 보관함에서는 소리는 네이티브가, 화면은 Dart가 같은 파일로 보여 준다. */
    private fun queryVideo(): List<Map<String, Any?>> {
        val collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.TITLE,
            MediaStore.Video.Media.ARTIST,
            MediaStore.Video.Media.ALBUM,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_ADDED,
        )
        val rows = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            collection,
            projection,
            null,
            null,
            "${MediaStore.Video.Media.TITLE} ASC",
        )?.use { c ->
            val id = c.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val title = c.getColumnIndexOrThrow(MediaStore.Video.Media.TITLE)
            val artist = c.getColumnIndexOrThrow(MediaStore.Video.Media.ARTIST)
            val album = c.getColumnIndexOrThrow(MediaStore.Video.Media.ALBUM)
            val duration = c.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val data = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            val dateAdded = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
            while (c.moveToNext()) {
                val mediaId = c.getLong(id)
                rows += mapOf(
                    "id" to mediaId,
                    "title" to c.getString(title),
                    "artist" to c.getString(artist),
                    "album" to c.getString(album),
                    "durationMs" to c.getLong(duration),
                    "uri" to ContentUris.withAppendedId(collection, mediaId).toString(),
                    "folder" to c.getString(data)?.let { File(it).parent },
                    "addedAtMs" to c.getLong(dateAdded) * 1000,
                )
            }
        }
        return rows
    }

    override fun dispose() {
        super.dispose()
        io.shutdown()
    }

    companion object {
        const val NAME = "music_app/media_store"
        private const val REQUEST_DELETE = 4101
        private const val REQUEST_WRITE = 4102
    }
}
