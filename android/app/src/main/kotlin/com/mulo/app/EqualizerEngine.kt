package com.mulo.app

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer

/**
 * ExoPlayer의 오디오 세션에 붙이는 이퀄라이저 + 저음 강화.
 * 값은 앱(Dart)이 [apply]로 보내고, 세션 번호가 바뀌면([attach]) 같은 값으로 효과를 다시 만든다.
 * 효과를 만들지 못하는 기기에서는 [info]가 null이고 나머지는 아무 일도 하지 않는다.
 */
object EqualizerEngine {
    private var sessionId = 0
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null

    private var enabled = false
    private var levelsDb = listOf<Double>()
    private var bass = 0.0

    @Synchronized
    fun attach(newSessionId: Int) {
        if (newSessionId == sessionId && equalizer != null) return
        release()
        sessionId = newSessionId
        if (newSessionId == 0) return
        equalizer = runCatching { Equalizer(0, newSessionId) }.getOrNull()
        bassBoost = runCatching { BassBoost(0, newSessionId) }.getOrNull()
        push()
    }

    @Synchronized
    fun info(): Map<String, Any?>? {
        val eq = equalizer ?: return null
        val range = eq.bandLevelRange
        return mapOf(
            "bands" to (0 until eq.numberOfBands).map { eq.getCenterFreq(it.toShort()) / 1000 },
            "minDb" to range[0] / 100.0,
            "maxDb" to range[1] / 100.0,
            "bassBoost" to (bassBoost?.strengthSupported == true),
        )
    }

    /** [levels]는 대역별 dB (대역 수가 다르면 모자란 쪽은 0). [bassStrength]는 0 ~ 1. */
    @Synchronized
    fun apply(isEnabled: Boolean, levels: List<Double>, bassStrength: Double) {
        enabled = isEnabled
        levelsDb = levels
        bass = bassStrength
        push()
    }

    private fun push() {
        equalizer?.let { eq ->
            runCatching {
                val range = eq.bandLevelRange
                for (band in 0 until eq.numberOfBands) {
                    val db = levelsDb.getOrNull(band) ?: 0.0
                    val mb = (db * 100).toInt().coerceIn(range[0].toInt(), range[1].toInt())
                    eq.setBandLevel(band.toShort(), mb.toShort())
                }
                eq.enabled = enabled
            }
        }
        bassBoost?.let { bb ->
            runCatching {
                if (bb.strengthSupported) bb.setStrength((bass * 1000).toInt().coerceIn(0, 1000).toShort())
                bb.enabled = enabled && bass > 0
            }
        }
    }

    private fun release() {
        runCatching { equalizer?.release() }
        runCatching { bassBoost?.release() }
        equalizer = null
        bassBoost = null
    }
}
