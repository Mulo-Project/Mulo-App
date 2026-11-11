package com.mulo.app

import android.os.Bundle
import androidx.media3.session.CommandButton
import androidx.media3.session.SessionCommand
import com.google.common.collect.ImmutableList

/** 재생 알림의 맞춤 버튼(좋아요 · 셔플 · 닫기): 세션 명령과 버튼 배치. 누름 처리는 [PlaybackHub]가 한다. */
internal object PlaybackButtons {
    const val ACTION_FAVORITE = "com.mulo.app.FAVORITE"
    const val ACTION_CLOSE = "com.mulo.app.CLOSE"
    const val ACTION_SHUFFLE = "com.mulo.app.SHUFFLE"

    val favorite = SessionCommand(ACTION_FAVORITE, Bundle.EMPTY)
    val close = SessionCommand(ACTION_CLOSE, Bundle.EMPTY)
    val shuffle = SessionCommand(ACTION_SHUFFLE, Bundle.EMPTY)

    /**
     * 맞춤 버튼 배치. 미리 듣기는 닫기 하나. 그 밖에는 앱이 있든 없든 늘 `[좋아요, 셔플]`이다.
     * [shuffled]는 셔플이 켜져 있는지, [favoriteOn]은 지금 곡이 좋아요인지(아이콘 · 이름을 정한다).
     * 재생 중인 알림은 일시정지한 뒤 밀어서 지울 수 있다.
     */
    fun layout(
        info: SessionInfo,
        shuffled: Boolean,
        favoriteOn: Boolean,
        favoriteShown: Boolean = true,
    ): ImmutableList<CommandButton> {
        val closeButton = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(R.drawable.ic_notif_close)
            .setDisplayName(info.closeLabel)
            .setSessionCommand(close)
            .build()
        if (info.preview) return ImmutableList.of(closeButton)
        // 셔플 순서는 extras가 쥐고 있어 앱이 없어도 네이티브가 켜고 끌 수 있다: 아이콘도 extras를 따른다.
        val shuffleButton = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(if (shuffled) R.drawable.ic_notif_shuffle_on else R.drawable.ic_notif_shuffle_off)
            .setDisplayName(if (shuffled) info.shuffleOffLabel else info.shuffleOnLabel)
            .setSessionCommand(shuffle)
            .build()
        // 좋아요도 앱이 없으면 네이티브가 DB를 직접 바꾼다 ([FavoriteStore]): 셔플과 같이 늘 같은 자리에 둔다.
        val favoriteButton = CommandButton.Builder(CommandButton.ICON_UNDEFINED)
            .setCustomIconResId(if (favoriteOn) R.drawable.ic_notif_favorite else R.drawable.ic_notif_favorite_outline)
            .setDisplayName(if (favoriteOn) info.unfavoriteLabel else info.favoriteLabel)
            .setSessionCommand(favorite)
            .build()
        // 임시 저장한 음원(cache)은 파일이 아니라 좋아요를 둘 수 없어 버튼을 뺀다.
        if (!favoriteShown) return ImmutableList.of(shuffleButton)
        return ImmutableList.of(favoriteButton, shuffleButton)
    }
}
