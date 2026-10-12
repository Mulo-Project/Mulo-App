package com.mulo.app

import android.media.audiofx.BassBoost
import android.media.audiofx.DynamicsProcessing
import android.media.audiofx.Equalizer
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import android.os.Build

/**
 * ExoPlayer의 오디오 세션에 붙이는 이퀄라이저 + 저음 강화 + 입체 음향(Virtualizer) + 공간 울림(PresetReverb)
 * + 클리핑 방지 리미터(DynamicsProcessing, Android 9+).
 * 값은 앱(Dart)이 [apply]로 보내고, 세션 번호가 바뀌면([attach]) 같은 값으로 효과를 다시 만든다.
 * 효과를 만들지 못하는 기기에서는 [info]가 null이고 나머지는 아무 일도 하지 않는다.
 */
object EqualizerEngine {
    private var sessionId = 0
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var reverb: PresetReverb? = null
    private var limiter: DynamicsProcessing? = null

    private var enabled = false
    private var levelsDb = listOf<Double>()
    private var bass = 0.0
    private var virtual = 0.0
    private var reverbPreset = 0
    private var limiterOn = true

    @Synchronized
    fun attach(newSessionId: Int) {
        if (newSessionId == sessionId && equalizer != null) return
        release()
        sessionId = newSessionId
        if (newSessionId == 0) return
        equalizer = runCatching { Equalizer(0, newSessionId) }.getOrNull()
        bassBoost = runCatching { BassBoost(0, newSessionId) }.getOrNull()
        virtualizer = runCatching { Virtualizer(0, newSessionId) }.getOrNull()
        reverb = runCatching { PresetReverb(0, newSessionId) }.getOrNull()
        limiter = createLimiter(newSessionId)
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
            "virtualizer" to (virtualizer?.strengthSupported == true),
            "reverb" to (reverb != null),
            "limiter" to (limiter != null),
        )
    }

    /** [levels]는 대역별 dB (대역 수가 다르면 모자란 쪽은 0). [bassStrength]는 0 ~ 1. */
    @Synchronized
    fun apply(
        isEnabled: Boolean,
        levels: List<Double>,
        bassStrength: Double,
        virtualizerStrength: Double,
        reverbIndex: Int,
        limiterEnabled: Boolean,
    ) {
        enabled = isEnabled
        levelsDb = levels
        bass = bassStrength
        virtual = virtualizerStrength
        reverbPreset = reverbIndex
        limiterOn = limiterEnabled
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
        virtualizer?.let { v ->
            runCatching {
                if (v.strengthSupported) v.setStrength((virtual * 1000).toInt().coerceIn(0, 1000).toShort())
                v.enabled = enabled && virtual > 0
            }
        }
        reverb?.let { r ->
            runCatching {
                r.preset = reverbPreset.coerceIn(0, 6).toShort()
                r.enabled = enabled && reverbPreset > 0
            }
        }
        limiter?.let { dp -> runCatching { dp.enabled = enabled && limiterOn } }
    }

    /** 소리가 찢어지지 않게 하는 리미터 (Android 9+). 만들지 못하면 null. */
    private fun createLimiter(session: Int): DynamicsProcessing? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
        return runCatching {
            val channels = 2
            val config = DynamicsProcessing.Config.Builder(
                DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                channels, false, 0, false, 0, false, 0, true,
            ).build()
            val dp = DynamicsProcessing(0, session, config)
            for (ch in 0 until channels) {
                dp.setLimiterByChannelIndex(
                    ch,
                    DynamicsProcessing.Limiter(true, true, 0, 1f, 60f, 10f, -2f, 0f),
                )
            }
            dp
        }.getOrNull()
    }

    private fun release() {
        runCatching { equalizer?.release() }
        runCatching { bassBoost?.release() }
        runCatching { virtualizer?.release() }
        runCatching { reverb?.release() }
        runCatching { limiter?.release() }
        equalizer = null
        bassBoost = null
        virtualizer = null
        reverb = null
        limiter = null
    }
}
