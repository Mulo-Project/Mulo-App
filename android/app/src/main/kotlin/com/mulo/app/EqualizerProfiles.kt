package com.mulo.app

import android.content.Context
import android.media.AudioDeviceInfo
import org.json.JSONArray
import org.json.JSONObject

/**
 * 출력 기기별 이퀄라이저. 앱(Dart)이 꺼져 있어도 지켜진다.
 *
 * - 내 프리셋: 이름을 붙여 만들어 둔 이퀄라이저 값 모음 (`presets`).
 * - 기기 프로필: 기기마다 전용 값 (`profiles`). 내 프리셋을 지정하면 그 값을 복사해 두고(`presetId`),
 *   프리셋을 고치면 지정한 기기의 값도 따라 바뀐다.
 * - 알고 있는 기기: 연결된 적 있는 기기 목록 (`devices`). 설정에서 기기를 골라 프리셋을 지정한다.
 * - 기기 열쇠는 `종류:이름` (예: `bluetooth:내 이어폰`, `speaker:`). 같은 이름의 기기는 같은 값을 쓴다.
 * - 프로필이 없는 기기는 [setBase]로 받아 둔 기본 값(앱의 저장 값)을 쓴다.
 * 값의 모양은 `EqualizerEngine.apply`의 인자와 같다 (+ 앱이 쓰는 `preset` 이름).
 */
object EqualizerProfiles {
    private const val PREFS = "mulo_eq_profiles"
    private const val PROFILES = "profiles"
    private const val PRESETS = "presets"
    private const val DEVICES = "devices"
    private const val BASE = "base"

    /** 출력 기기가 바뀌어 적용 값이 달라졌을 때 앱에 알린다 (앱이 떠 있을 때만 걸려 있다). */
    var onDeviceChanged: (() -> Unit)? = null

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun load(context: Context, name: String): JSONObject =
        try {
            JSONObject(prefs(context).getString(name, null) ?: "{}")
        } catch (_: Exception) {
            JSONObject()
        }

    private fun save(context: Context, name: String, value: JSONObject) {
        prefs(context).edit().putString(name, value.toString()).apply()
    }

    private fun keyOf(type: Any?, name: Any?) = "$type:$name"

    fun currentDevice(context: Context): Map<String, Any?> {
        val out = AudioOutputs.current(context)
        val key = keyOf(out["type"], out["name"])
        val profile = load(context, PROFILES).optJSONObject(key)
        return mapOf(
            "key" to key,
            "type" to out["type"],
            "name" to out["name"],
            "hasProfile" to (profile != null),
            "presetId" to profile?.optString("presetId")?.takeIf { it.isNotEmpty() },
        )
    }

    /** 지금 기기의 프로필 값 (없으면 null). */
    fun currentProfile(context: Context): Map<String, Any?>? {
        val key = currentDevice(context)["key"] as String
        return load(context, PROFILES).optJSONObject(key)?.let { toMap(it) }
    }

    fun saveProfile(context: Context, values: Map<*, *>) =
        putProfile(context, currentDevice(context)["key"] as String, values)

    fun deleteProfile(context: Context) = removeProfile(context, currentDevice(context)["key"] as String)

    private fun putProfile(context: Context, key: String, values: Map<*, *>) {
        val all = load(context, PROFILES)
        all.put(key, JSONObject(values.entries.associate { it.key.toString() to it.value }))
        save(context, PROFILES, all)
    }

    private fun removeProfile(context: Context, key: String) {
        val all = load(context, PROFILES)
        all.remove(key)
        save(context, PROFILES, all)
    }

    /** 앱의 저장 값(프로필이 없는 기기에 쓰는 값)을 받아 둔다. */
    fun setBase(context: Context, values: Map<*, *>) {
        save(context, BASE, JSONObject(values.entries.associate { it.key.toString() to it.value }))
    }

    // ── 내 프리셋 ──

    fun presets(context: Context): List<Map<String, Any?>> {
        val all = load(context, PRESETS)
        return all.keys().asSequence().map { toMap(all.getJSONObject(it)) }
            .sortedBy { (it["createdAt"] as? Number)?.toLong() ?: 0L }.toList()
    }

    /** 프리셋을 만들거나 고친다 (`id` `name` + 값). 이 프리셋을 지정한 기기의 값도 함께 고친다. */
    fun savePreset(context: Context, preset: Map<*, *>) {
        val id = preset["id"] as? String ?: return
        val all = load(context, PRESETS)
        val values = JSONObject(preset.entries.associate { it.key.toString() to it.value })
        values.put("createdAt", all.optJSONObject(id)?.optLong("createdAt") ?: System.currentTimeMillis())
        all.put(id, values)
        save(context, PRESETS, all)
        val profiles = load(context, PROFILES)
        for (key in profiles.keys().asSequence().toList()) {
            if (profiles.getJSONObject(key).optString("presetId") == id) profiles.put(key, withPresetId(values, id))
        }
        save(context, PROFILES, profiles)
        onOutputChanged(context)
    }

    /** 프리셋을 지운다. 지정했던 기기는 마지막 값을 그대로 쓰되 프리셋과의 연결만 끊는다. */
    fun deletePreset(context: Context, id: String) {
        val all = load(context, PRESETS)
        all.remove(id)
        save(context, PRESETS, all)
        val profiles = load(context, PROFILES)
        for (key in profiles.keys().asSequence().toList()) {
            val p = profiles.getJSONObject(key)
            if (p.optString("presetId") == id) {
                p.remove("presetId")
                profiles.put(key, p)
            }
        }
        save(context, PROFILES, profiles)
        onOutputChanged(context)
    }

    private fun withPresetId(preset: JSONObject, id: String): JSONObject {
        val copy = JSONObject(preset.toString())
        copy.remove("name")
        copy.remove("createdAt")
        copy.remove("id")
        copy.put("presetId", id)
        return copy
    }

    // ── 알고 있는 기기 ──

    /** 연결된 기기를 기억해 둔다 (설정의 기기 목록용). */
    fun remember(context: Context, devices: Array<out AudioDeviceInfo>) {
        val known = load(context, DEVICES)
        var changed = false
        for (d in devices) {
            val kind = AudioOutputs.kindOf(d) ?: continue
            val name = d.productName?.toString() ?: ""
            val key = keyOf(kind, name)
            known.put(
                key,
                JSONObject().put("key", key).put("type", kind).put("name", name)
                    .put("lastSeen", System.currentTimeMillis()),
            )
            changed = true
        }
        if (changed) save(context, DEVICES, known)
    }

    /** 기억한 기기 + 지금 기기 + 프리셋을 지정한 기기. 지금 기기가 맨 위, 그다음 최근에 쓴 순서. */
    fun devices(context: Context): List<Map<String, Any?>> {
        val known = load(context, DEVICES)
        val profiles = load(context, PROFILES)
        val current = currentDevice(context)
        val curKey = current["key"] as String
        val result = LinkedHashMap<String, MutableMap<String, Any?>>()
        for (k in known.keys()) result[k] = toMap(known.getJSONObject(k)).toMutableMap()
        if (!result.containsKey(curKey)) {
            result[curKey] = mutableMapOf(
                "key" to curKey, "type" to current["type"], "name" to current["name"], "lastSeen" to 0L,
            )
        }
        // 기기 스피커는 연결된 적 없어도 항상 목록에 둔다 (스피커 전용 값을 정할 수 있게).
        val speakerKey = keyOf("speaker", "")
        if (!result.containsKey(speakerKey)) {
            result[speakerKey] = mutableMapOf("key" to speakerKey, "type" to "speaker", "name" to "", "lastSeen" to 0L)
        }
        for (k in profiles.keys()) {
            if (!result.containsKey(k)) {
                result[k] = mutableMapOf(
                    "key" to k, "type" to k.substringBefore(':'), "name" to k.substringAfter(':'), "lastSeen" to 0L,
                )
            }
        }
        for ((k, d) in result) {
            val p = profiles.optJSONObject(k)
            d["hasProfile"] = p != null
            d["presetId"] = p?.optString("presetId")?.takeIf { it.isNotEmpty() }
            d["current"] = k == curKey
        }
        return result.values.sortedByDescending {
            if (it["current"] == true) Long.MAX_VALUE else (it["lastSeen"] as? Number)?.toLong() ?: 0L
        }
    }

    /** [key] 기기에 프리셋을 지정한다. [presetId]가 null이면 전용 값을 지우고 기본 값을 쓴다. */
    fun assignPreset(context: Context, key: String, presetId: String?) {
        if (presetId == null) {
            removeProfile(context, key)
        } else {
            val preset = load(context, PRESETS).optJSONObject(presetId) ?: return
            putProfile(context, key, toMap(withPresetId(preset, presetId)))
        }
        onOutputChanged(context)
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

    private fun toMap(o: JSONObject): Map<String, Any?> = o.keys().asSequence().associateWith { k ->
        when (val v = o.get(k)) {
            is JSONArray -> (0 until v.length()).map { v.get(it) }
            JSONObject.NULL -> null
            else -> v
        }
    }
}
