package com.mulo.app

import android.content.Context

/**
 * 좋아요(즐겨찾기) 읽기 · 쓰기. 알림의 좋아요 버튼이 앱 화면 없이도 동작한다.
 * 좋아요는 `playlist_tracks`에 `playlist_id = 'favorites'`인 줄이 있느냐로 정해지며, 규칙은 [LibraryDb]가 가진다
 * (앱 DB는 네이티브가 쥐므로 여기서 바꾸면 화면의 목록도 [MuloDb]의 바뀜 알림으로 같이 갱신된다).
 */
object FavoriteStore {
    /** 좋아요한 곡인지. DB를 읽지 못하면 null. */
    fun isFavorite(context: Context, trackId: String): Boolean? {
        if (trackId.isEmpty()) return null
        return try {
            LibraryDb(context).isFavorite(trackId)
        } catch (_: Exception) {
            null
        }
    }

    /** 좋아요를 켜고 끈다. 바뀐 뒤의 상태를 돌려주고, DB를 쓰지 못하면 null. */
    fun toggle(context: Context, trackId: String): Boolean? {
        if (trackId.isEmpty()) return null
        return try {
            LibraryDb(context).toggleFavorite(trackId)
        } catch (_: Exception) {
            null
        }
    }
}
