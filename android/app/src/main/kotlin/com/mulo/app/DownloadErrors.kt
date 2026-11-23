package com.mulo.app

/** 받기 실패 문구를 사람이 읽을 수 있게 다듬는다 (원문은 로그에 남는다). */
object DownloadErrors {
    private val NO_SPACE = listOf("ENOSPC", "No space left on device", "Not enough space", "disk full", "저장 공간")

    /** 저장공간이 부족해서 난 오류인가. */
    fun isNoSpace(message: String): Boolean = NO_SPACE.any { message.contains(it, ignoreCase = true) }

    /** [message]가 저장공간 부족이면 [noSpace] 문구로, 아니면 그대로. */
    fun friendly(message: String, noSpace: String = "저장 공간이 부족해요"): String =
        if (isNoSpace(message)) noSpace else message
}
