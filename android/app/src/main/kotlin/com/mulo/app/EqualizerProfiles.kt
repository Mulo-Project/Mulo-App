package com.mulo.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 출력 기기별 이퀄라이저 값. 기기(블루투스 이름 · 이어폰 · 스피커)마다 따로 저장해 두고,
 * 출력 기기가 바뀌면 그 기기의 값을 자동으로 적용한다. 앱(Dart)이 꺼져 있어도 지켜진다.
 *
 * - 기기 열쇠는 `종류:이름` (예: `bluetooth:내 이어폰`, `speaker:`). 같은 이름의 기기는 같은 값을 쓴다.
 * - 프로필이 없는 기기는 [setBase]로 받아 둔 기본 값(앱의 저장 값)을 쓴다.
 * 값의 모양은 `EqualizerEngine.apply`의 인자와 같다 (+ 앱이 쓰는 `preset` 이름).
 */
object EqualizerProfiles {
    private const val PREFS = "mulo_eq_profiles"
    private const val PROFILES = "profiles"
    private const val BASE = "base"

    /** 출력 기기가 바뀌어 적용 값이 달라졌을 때 앱에 알린다 (앱이 떠 있을 때만 걸려 있다). */
    var onDeviceChanged: (() -> Unit)? = null

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun currentDevice(context: Context): Map<String, Any?> {
        val out = AudioOutputs.current(context)
        val key = "${out["type"]}:${out["name"]}"
        return mapOf(
            "key" to key,
            "type" to out["type"],
            "name" to out["name"],
            "hasProfile" to (profiles(context).optJSONObject(key) != null),
        )
    }

    /** 지금 기기의 프로필 값 (없으면 null). */
    fun currentProfile(context: Context): Map<String, Any?>? {
        val key = currentDevice(context)["key"] as String
        return profiles(context).optJSONObject(key)?.let { toMap(it) }
    }

    fun saveProfile(context: Context, values: Map<*, *>) {
        val key = currentDevice(context)["key"] as String
        val all = profiles(context)
        all.put(key, JSONObject(values.entries.associate { it.key.toString() to it.value }))
        prefs(context).edit().putString(PROFILES, all.toString()).apply()
    }

    fun deleteProfile(context: Context) {
        val key = currentDevice(context)["key"] as String
        val all = profiles(context)
        all.remove(key)
        prefs(context).edit().putString(PROFILES, all.toString()).apply()
    }

    /** 앱의 저장 값(프로필이 없는 기기에 쓰는 값)을 받아 둔다. */
    fun setBase(context: Context, values: Map<*, *>) {
        val json = JSONObject(values.entries.associate { it.key.toString() to it.value })
        prefs(context).edit().putString(BASE, json.toString()).apply()
    }

    /** 지금 출력 기기에 맞는 값(프로필 > 기본)을 엔진에 적용한다. 받아 둔 값이 없으면 아무것도 안 한다. */
    fun applyCurrent(context: Context) {
        val values = currentProfile(context)
            ?: prefs(context).getString(BASE, null)?.let { toMap(JSONObject(it)) }
            ?: return
        val levels = (values["levels"] as? List<*>)?.map { (it as Number).toDouble() } ?: emptyList()
        EqualizerEngine.apply(
            values["enabled"] as? Boolean ?: false,
            levels,
            (values["bassBoost"] as? Number)?.toDouble() ?: 0.0,
            (values["virtualizer"] as? Number)?.toDouble() ?: 0.0,
            (values["reverb"] as? Number)?.toInt() ?: 0,
            values["limiter"] as? Boolean ?: true,
        )
    }

    /** 출력 기기가 바뀌었다: 그 기기의 값을 적용하고 앱에 알린다. */
    fun onOutputChanged(context: Context) {
        applyCurrent(context)
        onDeviceChanged?.invoke()
    }

    private fun profiles(context: Context): JSONObject =
        try {
            JSONObject(prefs(context).getString(PROFILES, null) ?: "{}")
        } catch (_: Exception) {
            JSONObject()
        }

    private fun toMap(o: JSONObject): Map<String, Any?> = o.keys().asSequence().associateWith { k ->
        when (val v = o.get(k)) {
            is JSONArray -> (0 until v.length()).map { v.get(it) }
            else -> v
        }
    }
}
