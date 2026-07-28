package com.manuito.tornpda.liveupdates

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.util.Log

object TravelLiveUpdateRefreshScheduler {

    private const val TAG = "TravelLiveUpdate"

    // Most people buy and fly straight back, so poll often at first and then relax
    private const val ABROAD_POLL_FAST_SECONDS = 3 * 60L
    private const val ABROAD_POLL_SLOW_SECONDS = 15 * 60L
    private const val ABROAD_POLL_BACKOFF_AFTER_SECONDS = 60 * 60L

    /** Parked abroad for half a day: stop burning alarms. */
    private const val ABROAD_POLL_GIVE_UP_SECONDS = 12 * 60 * 60L

    private const val TORN = "Torn"

    /** Slack for second rounding when deciding whether an arrival already happened. */
    const val ARRIVAL_TOLERANCE_SECONDS = 5L

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

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pendingIntent = LiveUpdateNotificationReceiver.createArrivedIntent(context, sessionId, payload.extras)

        alarmManager.cancel(pendingIntent)
        scheduleAlarm(alarmManager, arrivalMillis, pendingIntent, prefersExact = true)
    }

    fun cancelArrived(context: Context, sessionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(LiveUpdateNotificationReceiver.createArrivedIntent(context, sessionId, emptyMap()))
    }

    /**
     * Arms the poll that watches for the flight home while the app is not running.
     * Cancels instead unless this is an arrival abroad and we have a key.
     */
    fun scheduleAbroadPoll(context: Context, sessionId: String, payload: LiveUpdatePayload) {
        val arrival = payload.arrivalTimeTimestamp
        val destination = payload.currentDestinationDisplayName
        val apiKey = payload.extras[LiveUpdateNotificationReceiver.EXTRA_API_KEY] as? String
        val nowSeconds = System.currentTimeMillis() / 1000

        // Rounding between Flutter and here can leave the arrival a second ahead
        val isAbroad = arrival != null &&
            arrival <= nowSeconds + ARRIVAL_TOLERANCE_SECONDS &&
            !destination.isNullOrBlank() &&
            !destination.equals(TORN, ignoreCase = true)

        if (!isAbroad) {
            Log.d(TAG, "Poll not armed: not an arrival abroad (dest=$destination, arrival=$arrival, now=$nowSeconds)")
            cancelAbroadPoll(context, sessionId)
            return
        }

        if (apiKey.isNullOrBlank()) {
            Log.w(TAG, "Poll not armed: payload carries no API key. Keys present: ${payload.extras.keys}")
            cancelAbroadPoll(context, sessionId)
            return
        }

        val secondsAbroad = (nowSeconds - arrival!!).coerceAtLeast(0L)
        val delaySeconds = abroadPollDelaySeconds(secondsAbroad) ?: run {
            Log.d(TAG, "Poll not armed: ${secondsAbroad / 3600}h abroad, giving up on this trip")
            cancelAbroadPoll(context, sessionId)
            return
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: run {
            Log.e(TAG, "Poll not armed: AlarmManager is null")
            return
        }
        val pendingIntent = LiveUpdateNotificationReceiver.createTravelPollIntent(context, sessionId, payload.extras)

        alarmManager.cancel(pendingIntent)
        val prefersExact = delaySeconds <= 300
        scheduleAlarm(alarmManager, System.currentTimeMillis() + (delaySeconds * 1000), pendingIntent, prefersExact)
        Log.d(TAG, "Poll armed for $destination in ${delaySeconds}s (exact=$prefersExact, session=$sessionId)")
    }

    fun cancelAbroadPoll(context: Context, sessionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(LiveUpdateNotificationReceiver.createTravelPollIntent(context, sessionId, emptyMap()))
    }

    /** Poll cadence while abroad. Null means stop polling. */
    fun abroadPollDelaySeconds(secondsAbroad: Long): Long? = when {
        secondsAbroad >= ABROAD_POLL_GIVE_UP_SECONDS -> null
        secondsAbroad >= ABROAD_POLL_BACKOFF_AFTER_SECONDS -> ABROAD_POLL_SLOW_SECONDS
        else -> ABROAD_POLL_FAST_SECONDS
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
