package com.follow.clash.service.models

data class NotificationParams(
    val title: String = "极光VPN",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
    val showStopAction: Boolean = true,
)
