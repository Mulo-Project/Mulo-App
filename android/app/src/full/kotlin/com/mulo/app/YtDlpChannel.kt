package com.mulo.app

import android.content.Context
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import java.io.File
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import java.util.concurrent.Executors

/**
 * 로컬 엔진(full 빌드): youtubedl-android가 APK에 넣어 둔 파이썬 · yt-dlp를 실행한다.
 * Android 10+는 내려받은 실행 파일을 돌릴 수 없어서 라이브러리 방식을 쓴다.
 * lite 빌드는 같은 이름의 빈 구현이 들어가 `available`이 false다.
 */
class YtDlpChannel(private val context: Context, messenger: BinaryMessenger) : NativeChannel(messenger, NAME), YtDlpRunner {
    private val io = Executors.newSingleThreadExecutor()

    // 초기화(파이썬 풀기)는 처음 한 번만 걸린다.
    @Volatile private var ready = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(true)
                "version" -> run(result) { mapOf("version" to YoutubeDL.version(context)) }
                "update" -> run(result) {
                    YoutubeDL.updateYoutubeDL(context, YoutubeDL.UpdateChannel.STABLE)
                    mapOf("version" to YoutubeDL.version(context))
                }
                // 업데이트로 받은 yt-dlp를 지우고 APK에 들어 있는 버전으로 되돌린다.
                "revert" -> run(result) {
                    revertToBundled()
                    mapOf("version" to YoutubeDL.version(context))
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 업데이트가 받아 둔 yt-dlp(`<noBackup>/youtubedl-android/yt-dlp`)와 저장된 버전을 지우고
     * APK의 번들 yt-dlp를 다시 푼다. 실행 줄(io)에서만 불러서 실행 중인 yt-dlp와 겹치지 않는다.
     */
    private fun revertToBundled() {
        val dir = File(File(context.noBackupFilesDir, "youtubedl-android"), "yt-dlp")
        if (dir.exists() && !dir.deleteRecursively()) {
            throw IllegalStateException("could not remove the updated yt-dlp")
        }
        context.getSharedPreferences("youtubedl-android", Context.MODE_PRIVATE).edit()
            .remove("dlpVersion")
            .remove("dlpVersionName")
            .commit()
        YoutubeDL.getInstance().init_ytdlp(context, dir)
    }

    private fun ensureInit() {
        if (ready) return
        synchronized(this) {
            if (ready) return
            YoutubeDL.getInstance().init(context)
            ready = true
        }
    }

    override val available: Boolean get() = true

    /** [YtDlpEngine]이 부른다: 마지막 인자가 주소, 앞은 옵션. 몇 개가 동시에 돌아도 실행마다 [id]로 구분된다. */
    override fun run(args: List<String>, id: String, onProgress: ((Double) -> Unit)?): YtDlpRun {
        if (args.isEmpty()) throw YtDlpException("failed", "no arguments")
        ensureInit()
        return execute(args.last(), args.dropLast(1), id, onProgress)
    }

    // 시간 초과로 포기한 실행을 끊는다.
    override fun cancel(id: String): Boolean = YoutubeDL.getInstance().destroyProcessById(id)

    private fun execute(url: String, options: List<String>, id: String, onProgress: ((Double) -> Unit)?): YtDlpRun {
        val request = YoutubeDLRequest(url)
        // "-f 값"처럼 값이 붙는 옵션은 짝으로 넘긴다. 하나씩 따로 넣으면 라이브러리가
        // 옵션을 키로 모아 순서가 뒤섞여 yt-dlp가 값을 주소로 읽을 수 있다.
        var i = 0
        while (i < options.size) {
            val option = options[i]
            val value = options.getOrNull(i + 1)
            if (option.startsWith("-") && value != null && !value.startsWith("-")) {
                request.addOption(option, value)
                i += 2
            } else {
                request.addOption(option)
                i += 1
            }
        }
        return try {
            val r = if (onProgress != null) {
                // 영상 + 소리가 따로 오면 파일이 둘이라, "Destination:" 줄로 몇 번째 파일인지 세어
                // 전체 진행률(0 ~ 1)로 합친다. 두 파일이면 영상이 대부분이라 영상 0.9 · 소리 0.1로 나눈다.
                var total = 1
                var index = 0
                var last = -1.0
                YoutubeDL.getInstance().execute(request, id) { percent, _, line ->
                    Regex("Downloading (\\d+) format").find(line)?.let { total = it.groupValues[1].toInt().coerceAtLeast(1) }
                    if (line.contains("Destination:")) index += 1
                    val part = (percent / 100.0).coerceIn(0.0, 1.0)
                    val n = index.coerceAtLeast(1)
                    val overall = if (total >= 2) {
                        if (n == 1) part * 0.9 else 0.9 + (part * 0.1)
                    } else part
                    val value = minOf(overall, 0.99)
                    if (value - last >= 0.005) {
                        last = value
                        onProgress(value)
                    }
                }
            } else {
                YoutubeDL.getInstance().execute(request, id)
            }
            YtDlpRun(r.exitCode, r.out, r.err)
        } catch (e: YoutubeDLException) {
            // yt-dlp가 0이 아닌 코드로 끝난 경우: 메시지에 stderr가 들어 있다.
            YtDlpRun(1, "", e.message ?: "")
        }
    }

    private fun run(
        result: MethodChannel.Result,
        executor: Executor = io,
        block: () -> Map<String, Any?>,
    ) =
        runAsync(executor, result, "ytdlp_failed") {
            ensureInit()
            block()
        }

    override fun dispose() {
        super.dispose()
        io.shutdown()
    }

    companion object {
        const val NAME = "music_app/ytdlp"
    }
}
