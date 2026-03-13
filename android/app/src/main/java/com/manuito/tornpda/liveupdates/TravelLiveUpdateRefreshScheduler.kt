package com.manuito.tornpda.liveupdates

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build

object TravelLiveUpdateRefreshScheduler {

    fun scheduleNextRefresh(context: Context, sessionId: String, payload: LiveUpdatePayload) {
        val arrivalTimestamp = payload.arrivalTimeTimestamp ?: run {
            cancelRefresh(context, sessionId)
            return
        }

        val remainingSeconds = arrivalTimestamp - (System.currentTimeMillis() / 1000)
        if (remainingSeconds <= 0) {
            cancelRefresh(context, sessionId)
            return
        }

        val nextDelaySeconds = nextRefreshDelaySeconds(remainingSeconds).coerceAtMost(remainingSeconds)
        val triggerAtMillis = System.currentTimeMillis() + (nextDelaySeconds * 1000)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pendingIntent = LiveUpdateNotificationReceiver.createRefreshIntent(context, sessionId, payload.extras)

        alarmManager.cancel(pendingIntent)
        scheduleAlarm(alarmManager, triggerAtMillis, pendingIntent, prefersExact = nextDelaySeconds <= 300)
    }

    fun cancelRefresh(context: Context, sessionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(LiveUpdateNotificationReceiver.createRefreshIntent(context, sessionId, emptyMap()))
    }

    fun scheduleArrived(context: Context, sessionId: String, payload: LiveUpdatePayload) {
        val arrivalMillis = ((payload.arrivalTimeTimestamp ?: 0L) * 1000)
        if (arrivalMillis <= 0L || arrivalMillis <= System.currentTimeMillis()) {
            cancelArrived(context, sessionId)
            return
        }

        val destination = payload.currentDestinationDisplayName ?: context.getString(com.manuito.tornpda.R.string.live_update_destination_unknown)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pendingIntent = LiveUpdateNotificationReceiver.createArrivedIntent(
            context = context,
            sessionId = sessionId,
            destination = destination,
            origin = payload.originDisplayName,
            earliestReturnTimestamp = payload.earliestReturnTimestamp,
        )

        alarmManager.cancel(pendingIntent)
        scheduleAlarm(alarmManager, arrivalMillis, pendingIntent, prefersExact = true)
    }

    fun cancelArrived(context: Context, sessionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(LiveUpdateNotificationReceiver.createArrivedIntent(context, sessionId, "dummy"))
    }

    private fun nextRefreshDelaySeconds(remainingSeconds: Long): Long {
        return when {
            remainingSeconds > 3600 -> 900
            remainingSeconds > 900 -> 300
            else -> 60
        }
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
