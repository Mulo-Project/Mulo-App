package com.mulo.app

import androidx.annotation.OptIn
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import kotlin.math.max
import kotlin.math.min

/**
 * 공간 울림(리버브). 기기 효과(PresetReverb)는 기기마다 들리는 정도가 달라서, 재생 엔진의 오디오 처리 단계에서
 * 직접 Freeverb 방식(빗살 필터 8개 + 올패스 4개)으로 만든다. 16비트 PCM 모노 · 스테레오만 처리하고,
 * 꺼져 있으면(프리셋 0) 소리를 그대로 통과시킨다.
 * 프리셋 번호: 0 없음, 1 작은 방, 2 중간 방, 3 큰 방, 4 중간 홀, 5 큰 홀, 6 플레이트.
 */
@OptIn(UnstableApi::class)
class ReverbProcessor : BaseAudioProcessor() {
    @Volatile
    private var preset = 0

    // 프리셋별 (잔향 길이 0~1, 고음 감쇠 0~1, 섞는 양 0~1).
    private val roomSize = floatArrayOf(0f, .55f, .70f, .82f, .88f, .94f, .90f)
    private val damping = floatArrayOf(0f, .50f, .40f, .35f, .30f, .25f, .10f)
    private val wetLevel = floatArrayOf(0f, .30f, .35f, .40f, .45f, .55f, .50f)

    private var channels = 0
    private var combs: Array<Array<Comb>> = emptyArray()
    private var allpasses: Array<Array<Allpass>> = emptyArray()

    fun setPreset(value: Int) {
        preset = value.coerceIn(0, 6)
    }

    override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        val ok = inputAudioFormat.encoding == androidx.media3.common.C.ENCODING_PCM_16BIT &&
            (inputAudioFormat.channelCount == 1 || inputAudioFormat.channelCount == 2)
        if (!ok) return AudioProcessor.AudioFormat.NOT_SET // 처리하지 않고 건너뛴다
        channels = inputAudioFormat.channelCount
        val scale = inputAudioFormat.sampleRate / 44100.0
        fun sized(n: Int, spread: Int) = max(1, ((n + spread) * scale).toInt())
        combs = Array(channels) { ch ->
            Array(COMB_TUNING.size) { Comb(sized(COMB_TUNING[it], ch * SPREAD)) }
        }
        allpasses = Array(channels) { ch ->
            Array(ALLPASS_TUNING.size) { Allpass(sized(ALLPASS_TUNING[it], ch * SPREAD)) }
        }
        return inputAudioFormat
    }

    override fun onFlush() {
        combs.forEach { row -> row.forEach { it.clear() } }
        allpasses.forEach { row -> row.forEach { it.clear() } }
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val size = inputBuffer.remaining()
        if (size == 0) return
        val out = replaceOutputBuffer(size)
        val p = preset
        if (p == 0) {
            out.put(inputBuffer)
            out.flip()
            return
        }
        val feedback = .7f + .28f * roomSize[p]
        val damp = damping[p]
        val wet = wetLevel[p] * WET_SCALE
        val dry = 1f - wetLevel[p] * .5f
        val frames = size / (2 * channels)
        repeat(frames) {
            val l = inputBuffer.short.toFloat()
            val r = if (channels == 2) inputBuffer.short.toFloat() else l
            val input = (l + r) * .5f * FIXED_GAIN
            for (ch in 0 until channels) {
                var acc = 0f
                for (c in combs[ch]) acc += c.process(input, feedback, damp)
                for (a in allpasses[ch]) acc = a.process(acc)
                val dryIn = if (ch == 0) l else r
                val mixed = dryIn * dry + acc * wet
                out.putShort(min(32767f, max(-32768f, mixed)).toInt().toShort())
            }
        }
        out.flip()
    }

    private class Comb(size: Int) {
        private val buf = FloatArray(size)
        private var idx = 0
        private var store = 0f

        fun process(input: Float, feedback: Float, damp: Float): Float {
            val output = buf[idx]
            store = output * (1f - damp) + store * damp
            buf[idx] = input + store * feedback
            idx = (idx + 1) % buf.size
            return output
        }

        fun clear() {
            buf.fill(0f)
            store = 0f
            idx = 0
        }
    }

    private class Allpass(size: Int) {
        private val buf = FloatArray(size)
        private var idx = 0

        fun process(input: Float): Float {
            val bufOut = buf[idx]
            val output = -input + bufOut
            buf[idx] = input + bufOut * .5f
            idx = (idx + 1) % buf.size
            return output
        }

        fun clear() {
            buf.fill(0f)
            idx = 0
        }
    }

    companion object {
        private val COMB_TUNING = intArrayOf(1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617)
        private val ALLPASS_TUNING = intArrayOf(556, 441, 341, 225)
        private const val SPREAD = 23
        private const val FIXED_GAIN = .015f
        private const val WET_SCALE = 3f
    }
}
