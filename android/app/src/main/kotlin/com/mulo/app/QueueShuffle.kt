package com.mulo.app

import androidx.media3.common.MediaItem
import org.json.JSONArray
import org.json.JSONObject

/**
 * 앱 없이 네이티브가 대기열 셔플을 켜고 끄는 계산 (플레이어에 반영하는 일은 [PlaybackHub]가 한다).
 * 셔플 상태와 섞기 전 순서는 앱이 저장해 둔 `extras`(JSON: `shuffle`, `original`)에 들어 있다.
 */
internal object QueueShuffle {
    /** [toggle]의 결과: 지금 곡 앞에 둘 곡, 뒤에 둘 곡, 새 extras. */
    class Result(val before: List<MediaItem>, val after: List<MediaItem>, val extras: String)

    /** 앱이 저장해 둔 대기열 정보에 셔플이 켜져 있는지. */
    fun isOn(extras: String): Boolean = try {
        extras.isNotEmpty() && JSONObject(extras).optBoolean("shuffle", false)
    } catch (_: Exception) {
        false
    }

    /**
     * 한 바퀴를 돈 뒤 첫 곡을 뺀 나머지를 새로 섞는다. 방금 들은 곡([previousId])이 바로 다음에 오지 않게 한다.
     * [items]는 대기열 전체이고 첫 곡은 그대로 둔다.
     */
    fun reshuffledRest(items: List<MediaItem>, previousId: String): List<MediaItem> {
        val rest = items.drop(1).shuffled().toMutableList()
        if (rest.first().mediaId == previousId) rest.add(rest.removeAt(0))
        return rest
    }

    /**
     * 셔플을 켜면 지금 곡을 맨 앞에 두고 나머지를 섞으며 원래 순서를 `original`에 적는다.
     * 끄면 `original` 순서로 되돌린다. [current]는 지금 곡의 위치.
     */
    fun toggle(all: List<MediaItem>, current: Int, extras: String): Result {
        val json = try {
            if (extras.isNotEmpty()) JSONObject(extras) else JSONObject()
        } catch (_: Exception) {
            JSONObject()
        }
        val currentItem = all[current]
        val others = all.filterIndexed { i, _ -> i != current }
        val before: List<MediaItem>
        val after: List<MediaItem>
        if (!isOn(extras)) {
            before = emptyList()
            after = others.shuffled()
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
        return Result(before, after, json.toString())
    }
}
