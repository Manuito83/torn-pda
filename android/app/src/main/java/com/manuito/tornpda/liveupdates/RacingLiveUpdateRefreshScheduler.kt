package com.manuito.tornpda.liveupdates

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.util.Log

object RacingLiveUpdateRefreshScheduler {

    private const val TAG = "RacingLU"

    fun scheduleNextRefresh(context: Context, sessionId: String, payload: LiveUpdatePayload) {
        val delayMillis = nextRefreshDelayMillis(payload) ?: run {
            Log.d(TAG, "Scheduler: phase=${payload.phase} → no delay (chain stops here).")
            cancelRefresh(context, sessionId)
            return
        }

        val triggerAtMillis = System.currentTimeMillis() + delayMillis
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: run {
            Log.e(TAG, "Scheduler: AlarmManager is null! Cannot schedule.")
            return
        }
        val pendingIntent = LiveUpdateNotificationReceiver.createRacingRefreshIntent(context, sessionId, payload.extras)

        alarmManager.cancel(pendingIntent)
        val prefersExact = delayMillis <= 5 * 60 * 1000
        scheduleAlarm(alarmManager, triggerAtMillis, pendingIntent, prefersExact)
        Log.d(TAG, "Scheduler: alarm set in ${delayMillis / 1000}s (exact=$prefersExact). phase=${payload.phase}")
    }

    fun cancelRefresh(context: Context, sessionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(LiveUpdateNotificationReceiver.createRacingRefreshIntent(context, sessionId, emptyMap()))
    }

    private fun nextRefreshDelayMillis(payload: LiveUpdatePayload): Long? {
        val phase = payload.phase.orEmpty()
        val currentTimestamp = payload.currentServerTimestamp ?: (System.currentTimeMillis() / 1000)
        val targetTimestamp = payload.targetTimeTimestamp

        val durationSeconds = when (phase) {
            "waitingUnknown" -> 2 * 60L
            "waiting" -> {
                if (targetTimestamp == null) return 2 * 60L * 1000L
                val remainingSeconds = targetTimestamp - currentTimestamp
                if (remainingSeconds > 15 * 60) 5 * 60L else 60L
            }
            "racing" -> {
                if (targetTimestamp == null) return 60L * 1000L
                val remainingSeconds = targetTimestamp - currentTimestamp
                if (remainingSeconds > 5 * 60) 2 * 60L else 60L
            }
            else -> return null
        }

        return durationSeconds * 1000L
    }

    private fun scheduleAlarm(
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        pendingIntent: PendingIntent,
        prefersExact: Boolean,
    ) {
        val canScheduleExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }

        if (prefersExact && canScheduleExact) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        }
    }
}