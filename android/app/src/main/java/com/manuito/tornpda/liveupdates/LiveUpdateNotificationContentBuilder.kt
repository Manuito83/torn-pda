package com.manuito.tornpda.liveupdates

import kotlin.math.max
import kotlin.math.min

/**
 * Pure-logic helper that computes notification state decisions for travel live updates.
 * Has zero Android dependencies so it can be covered by plain JUnit tests.
 */
class LiveUpdateNotificationContentBuilder(
    private val timeProvider: () -> Long = { System.currentTimeMillis() },
) {

    data class ProgressInfo(val totalSeconds: Long, val elapsedSeconds: Long)

    data class RemainingTime(val hours: Long, val minutes: Long) {
        fun toCompact(): String = if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
    }

    /**
     * Determines whether the user has actually arrived, taking real wall-clock
     * time into account — not just Flutter's [LiveUpdatePayload.hasArrived] flag.
     */
    fun hasActuallyArrived(payload: LiveUpdatePayload): Boolean {
        val arrivalMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
        return payload.hasArrived || (arrivalMillis > 0 && arrivalMillis <= timeProvider())
    }

    /**
     * Computes progress bar values (total / elapsed seconds) based on
     * departure, arrival and the current wall-clock time.
     * Returns `null` when timestamps are missing.
     */
    fun computeProgress(payload: LiveUpdatePayload): ProgressInfo? {
        val arrival = payload.arrivalTimeTimestamp ?: return null
        val departure = payload.departureTimeTimestamp ?: return null
        val reference = timeProvider() / 1000
        val totalSeconds = max(1L, arrival - departure)
        val elapsedSeconds = min(totalSeconds, max(0L, reference - departure))
        return ProgressInfo(totalSeconds, elapsedSeconds)
    }

    /**
     * Computes remaining travel time as hours + minutes.
     * Returns `null` when arrived, remaining <= 0, or arrival timestamp is absent.
     */
    fun computeRemainingTime(payload: LiveUpdatePayload): RemainingTime? {
        if (hasActuallyArrived(payload)) return null
        val arrival = payload.arrivalTimeTimestamp ?: return null
        val nowSec = timeProvider() / 1000
        val remaining = arrival - nowSec
        if (remaining <= 0) return null
        val hours = remaining / 3600
        val minutes = (remaining % 3600) / 60
        return RemainingTime(hours, minutes)
    }

    /** `true` when the notification should display an ETA (i.e. user is still en-route). */
    fun shouldShowEta(payload: LiveUpdatePayload): Boolean = !hasActuallyArrived(payload)

    /** `true` when the notification should use a countdown chronometer. */
    fun shouldShowChronometer(payload: LiveUpdatePayload): Boolean {
        if (hasActuallyArrived(payload)) return false
        val arrivalMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
        return arrivalMillis > 0
    }
}
