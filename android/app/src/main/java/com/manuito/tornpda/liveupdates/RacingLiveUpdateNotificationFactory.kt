package com.manuito.tornpda.liveupdates

import android.app.Notification
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.manuito.tornpda.R

/**
 * Builds racing live-update notifications for every phase of a race lifecycle.
 *
 * Active phases (waitingUnknown, waiting, racing) produce a promoted-ongoing
 * chip in the status bar:
 *  • waitingUnknown → car icon + "WAIT"
 *  • waiting        → car icon + "GO HH:MM" + countdown
 *  • racing         → speedometer icon + "END HH:MM" + countdown
 *
 * The finished phase starts as an ongoing promoted chip (visible in status
 * bar) and after 5 minutes is demoted to an ongoing **non-promoted**
 * notification: the flag icon stays permanently in the status bar but
 * without chip text. The user can tap it to dismiss (autoCancel).
 */
class RacingLiveUpdateNotificationFactory(
    private val context: Context,
) {

    private val channelId = LiveUpdateNotificationChannel.channelIdFor(LiveUpdateActivityType.RACING)

    private val positionRegex = Regex(
        pattern = "(\\d+)(?:st|nd|rd|th)",
        option = RegexOption.IGNORE_CASE,
    )

    /**
     * @param ongoing   Pass `false` to build a swipeable variant.
     *                  Defaults to `true` (persistent in status bar).
     * @param promoted  When `true` (default) the notification becomes a
     *                  promoted-ongoing chip with [chipText]. Pass `false`
     *                  together with `ongoing = true` to keep a persistent
     *                  status-bar icon *without* the chip (used after the
     *                  5-minute chip phase for finished races).
     */
    fun build(
        payload: LiveUpdatePayload,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
        ongoing: Boolean = true,
        promoted: Boolean = true,
    ): Notification {
        val title = payload.titleText ?: defaultTitle(payload)
        val phaseLabel = phaseStatusText(payload)
        val clockTimeText = formatTargetClockTime(payload)
        val contentText = clockTimeText ?: defaultContentText(payload)
        val chipText = chipText(payload, clockTimeText)
        val extrasBundle = payload.toExtrasBundle()

        return if (Build.VERSION.SDK_INT >= 35) {
            buildFrameworkNotification(
                payload = payload,
                title = title,
                contentText = contentText,
                phaseLabel = phaseLabel,
                chipText = chipText,
                extrasBundle = extrasBundle,
                tapIntent = tapIntent,
                dismissIntent = dismissIntent,
                ongoing = ongoing,
                promoted = promoted,
            )
        } else {
            buildCompatNotification(
                payload = payload,
                title = title,
                contentText = contentText,
                phaseLabel = phaseLabel,
                chipText = chipText,
                extrasBundle = extrasBundle,
                tapIntent = tapIntent,
                dismissIntent = dismissIntent,
                ongoing = ongoing,
                promoted = promoted,
            )
        }
    }

    // region Compat path (< API 35)

    private fun buildCompatNotification(
        payload: LiveUpdatePayload,
        title: String,
        contentText: String,
        phaseLabel: String,
        chipText: String,
        extrasBundle: android.os.Bundle,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
        ongoing: Boolean,
        promoted: Boolean,
    ): Notification {
        // When ongoing + promoted the notification is a status-bar chip.
        // When ongoing + !promoted the icon stays in the status bar but
        // without chip text (used for the demoted finished notification).
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(iconFor(payload))
            .setContentTitle(title)
            .setContentText(contentText)
            .setSubText(phaseLabel)
            .setStyle(NotificationCompat.BigTextStyle().bigText("$title\n$contentText"))
            .setContentIntent(tapIntent)
            .setDeleteIntent(dismissIntent)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setExtras(extrasBundle)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setAutoCancel(isFinished(payload))
            .setOngoing(ongoing)

        applyChronoSettings(builder, payload)
        if (promoted) {
            enablePromotedOngoing(builder)
            applyShortCriticalText(builder, chipText)
        }

        return builder.build()
    }

    // endregion

    // region Framework path (API 35+)

    @android.annotation.SuppressLint("NewApi")
    private fun buildFrameworkNotification(
        payload: LiveUpdatePayload,
        title: String,
        contentText: String,
        phaseLabel: String,
        chipText: String,
        extrasBundle: android.os.Bundle,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
        ongoing: Boolean,
        promoted: Boolean,
    ): Notification {
        // When ongoing + promoted the notification is a status-bar chip.
        // When ongoing + !promoted the icon stays in the status bar but
        // without chip text (used for the demoted finished notification).
        val builder = Notification.Builder(context, channelId)
            .setSmallIcon(iconFor(payload))
            .setContentTitle(title)
            .setContentText(contentText)
            .setSubText(phaseLabel)
            .setStyle(Notification.BigTextStyle().bigText("$title\n$contentText"))
            .setContentIntent(tapIntent)
            .setDeleteIntent(dismissIntent)
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setExtras(extrasBundle)
            .setCategory(Notification.CATEGORY_STATUS)
            .setAutoCancel(isFinished(payload))
            .setOngoing(ongoing)

        applyFrameworkChronoSettings(builder, payload)
        if (promoted) {
            invokeFrameworkPromotedOngoing(builder)
            invokeFrameworkShortCriticalText(builder, chipText)
        }

        return builder.build()
    }

    // endregion

    // region Chronometer configuration

    /**
     * Configures the system chronometer on the notification (compat path).
     * Active phases with a known target get a live countdown; the finished
     * phase uses a count-up chronometer from "now" so the chip stays visible
     * on pre-API 35 devices (where shortCriticalText alone doesn't produce one).
     */
    private fun applyChronoSettings(builder: NotificationCompat.Builder, payload: LiveUpdatePayload) {
        val targetMillis = (payload.targetTimeTimestamp ?: 0L) * 1000

        if (!isFinished(payload) && targetMillis > 0) {
            builder.setShowWhen(true)
            builder.setUsesChronometer(true)
            builder.setChronometerCountDown(true)
            builder.setWhen(targetMillis)
        } else {
            // Finished or no target: plain timestamp, no chronometer.
            builder.setShowWhen(true)
            builder.setUsesChronometer(false)
            builder.setWhen(System.currentTimeMillis())
        }
    }

    /** Framework-path equivalent of [applyChronoSettings]. */
    @android.annotation.SuppressLint("NewApi")
    private fun applyFrameworkChronoSettings(builder: Notification.Builder, payload: LiveUpdatePayload) {
        val targetMillis = (payload.targetTimeTimestamp ?: 0L) * 1000

        if (!isFinished(payload) && targetMillis > 0) {
            builder.setShowWhen(true)
            builder.setUsesChronometer(true)
            builder.setChronometerCountDown(true)
            builder.setWhen(targetMillis)
        } else {
            builder.setShowWhen(true)
            builder.setUsesChronometer(false)
            builder.setWhen(System.currentTimeMillis())
        }
    }

    // endregion

    // region Icon & text helpers

    private fun iconFor(payload: LiveUpdatePayload): Int {
        return when (payload.phase?.lowercase()) {
            "racing" -> R.drawable.ic_racing_speed
            "finished" -> R.drawable.ic_racing_finished
            else -> R.drawable.ic_racing_car
        }
    }

    private fun phaseStatusText(payload: LiveUpdatePayload): String {
        return when (payload.phase?.lowercase()) {
            "racing" -> context.getString(R.string.racing_live_update_status_racing)
            "finished" -> context.getString(R.string.racing_live_update_status_finished)
            else -> context.getString(R.string.racing_live_update_status_waiting)
        }
    }

    private fun defaultTitle(payload: LiveUpdatePayload): String {
        return when (payload.phase?.lowercase()) {
            "racing" -> context.getString(R.string.racing_live_update_title_racing)
            "finished" -> context.getString(R.string.racing_live_update_title_finished)
            else -> context.getString(R.string.racing_live_update_title_waiting)
        }
    }

    /** Secondary content text when no clock time is available. */
    private fun defaultContentText(payload: LiveUpdatePayload): String {
        return if (isFinished(payload)) {
            finishedSummary(payload)
        } else {
            context.getString(R.string.racing_live_update_body_pending)
        }
    }

    private fun isFinished(payload: LiveUpdatePayload): Boolean =
        payload.phase.equals("finished", ignoreCase = true)

    // endregion

    // region Clock time formatting

    /**
     * Absolute clock time for the race target (e.g. "Ends at 14:35").
     * Returns null when there is no meaningful target (waitingUnknown, finished).
     */
    private fun formatTargetClockTime(payload: LiveUpdatePayload): String? {
        val target = payload.targetTimeTimestamp ?: return null
        if (target <= 0) return null
        val formatted = android.text.format.DateFormat.getTimeFormat(context)
            .format(java.util.Date(target * 1000))
        return when {
            payload.phase.equals("racing", ignoreCase = true) ->
                context.getString(R.string.racing_live_update_timer_ends, formatted)
            payload.phase.equals("finished", ignoreCase = true) -> null
            else -> context.getString(R.string.racing_live_update_timer_starts, formatted)
        }
    }

    // endregion

    // region Chip text (shortCriticalText)

    /**
     * Determines the text shown inside the promoted-ongoing status-bar chip.
     *
     * Every phase gets a chip:
     *  • waitingUnknown → "WAIT"
     *  • waiting        → "GO 14:35"
     *  • racing         → "END 14:35"
     *  • finished       → "END #3" (finishing position extracted from body)
     */
    private fun chipText(payload: LiveUpdatePayload, clockTimeText: String?): String {
        if (isFinished(payload)) {
            return finishedChipLabel(payload)
        }
        val clockTime = formatTargetClockTimeShort(payload) ?: return "WAIT"
        return if (payload.phase.equals("racing", ignoreCase = true)) {
            "END $clockTime"
        } else {
            "GO $clockTime"
        }
    }

    /** Formats the target time as a short clock string (e.g. "14:35") for chip display. */
    private fun formatTargetClockTimeShort(payload: LiveUpdatePayload): String? {
        val target = payload.targetTimeTimestamp ?: return null
        if (target <= 0) return null
        return android.text.format.DateFormat.getTimeFormat(context)
            .format(java.util.Date(target * 1000))
    }

    /**
     * Builds the chip label for a completed race.
     * Extracts the ordinal position from the body text (e.g. "You came 3rd")
     * and produces "END #3". Falls back to "END" if position cannot be parsed.
     */
    private fun finishedChipLabel(payload: LiveUpdatePayload): String {
        val body = payload.bodyText.orEmpty()
        val position = positionRegex.find(body)?.groupValues?.getOrNull(1)
        return if (position != null) "END #$position" else "END"
    }

    /**
     * Builds the notification body text for a completed race,
     * using the raw API result text if available.
     */
    private fun finishedSummary(payload: LiveUpdatePayload): String {
        val body = payload.bodyText?.takeIf { it.isNotBlank() }
        return body ?: context.getString(R.string.racing_live_update_status_finished)
    }

    // endregion

    // region Promoted ongoing & shortCriticalText (reflection)

    private fun applyShortCriticalText(builder: NotificationCompat.Builder, text: CharSequence) {
        try {
            val method = builder.javaClass.getMethod("setShortCriticalText", CharSequence::class.java)
            method.invoke(builder, text)
        } catch (_: Exception) {
            // Graceful no-op on platforms without this API.
        }
    }

    private fun enablePromotedOngoing(builder: NotificationCompat.Builder) {
        try {
            val method = builder.javaClass.getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
            method.invoke(builder, true)
        } catch (_: Exception) {
            // Graceful no-op on platforms without this API.
        }
    }

    private fun invokeFrameworkPromotedOngoing(builder: Notification.Builder) {
        try {
            val method = builder.javaClass.getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
            method.invoke(builder, true)
        } catch (_: Exception) {
            // Graceful no-op on platforms without this API.
        }
    }

    private fun invokeFrameworkShortCriticalText(builder: Notification.Builder, text: CharSequence) {
        try {
            val extras = android.os.Bundle().apply {
                putCharSequence("android.shortCriticalText", text)
            }
            builder.addExtras(extras)
        } catch (_: Exception) {
            // Graceful no-op on platforms without this API.
        }

        try {
            val method = builder.javaClass.getMethod("setShortCriticalText", String::class.java)
            method.invoke(builder, text.toString())
        } catch (_: Exception) {
            // Graceful no-op on platforms without this API.
        }
    }

    // endregion

    // region Extras serialization

    private fun LiveUpdatePayload.toExtrasBundle(): android.os.Bundle {
        return android.os.Bundle().also { bundle ->
            extras.forEach { (key, value) ->
                when (value) {
                    is String -> bundle.putString(key, value)
                    is Boolean -> bundle.putBoolean(key, value)
                    is Int -> bundle.putInt(key, value)
                    is Long -> bundle.putLong(key, value)
                    is Double -> bundle.putDouble(key, value)
                    is Float -> bundle.putFloat(key, value)
                }
            }
        }
    }

    // endregion
}
