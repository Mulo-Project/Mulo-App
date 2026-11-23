package com.mulo.app

/**
 * 미디어 버튼(이어폰 · 차량)이 서비스를 깨웠을 때 허브가 해야 할 준비를 정한다. 안드로이드에 기대지 않는 순수 규칙이라 JVM 테스트로 확인한다.
 *
 * 리시버는 저장소의 `resumable`만 보고 포그라운드 서비스를 띄운다. 그래서 서비스가 뜬 뒤에도 세션이 없거나(알림 설정을 꺼서 앱이
 * `setSession(null)`을 보낸 경우) 플레이어 상태가 비어 있으면 버튼이 아무 일도 하지 못하고, 서비스는 알림을 올리지 못한 채
 * `startForeground` 기한을 넘긴다. 버튼으로 깨운 서비스는 늘 재생할 수 있는 세션과 알림을 갖추게 한다.
 */
object MediaButtonPolicy {
    class Plan(
        /** 알림을 지운 뒤 정리된 세션을 되살린다. */
        val revive: Boolean,
        /** 앱이 알림 내용을 보내 주지 않았으니 대기열의 곡 정보로 채운다. */
        val fillInfoFromQueue: Boolean,
        /** 서비스에 세션을 올려 알림이 뜨게 한다. */
        val showNotification: Boolean,
    )

    /** 버튼을 무시해야 하면 null. */
    fun plan(
        gated: Boolean,
        dismissed: Boolean,
        hasQueue: Boolean,
        hasInfo: Boolean,
    ): Plan? {
        if (gated || !hasQueue) return null
        return Plan(revive = dismissed, fillInfoFromQueue = !hasInfo, showNotification = true)
    }
}
