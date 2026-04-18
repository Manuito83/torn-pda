package com.manuito.tornpda.liveupdates

import android.annotation.SuppressLint
import android.app.Notification
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.manuito.tornpda.R

class TravelLiveUpdateNotificationFactory(
    private val context: Context,
    private val contentBuilder: LiveUpdateNotificationContentBuilder = LiveUpdateNotificationContentBuilder(),
) {

    private val channelId = LiveUpdateNotificationChannel.channelIdFor(LiveUpdateActivityType.TRAVEL)

    fun build(
        sessionId: String,
        payload: LiveUpdatePayload,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
    ): Notification {
        val destination = payload.currentDestinationDisplayName ?: context.getString(R.string.live_update_destination_unknown)
        val origin = payload.originDisplayName ?: context.getString(R.string.live_update_destination_unknown)
        val title = payload.activityStateTitle ?: context.getString(R.string.travel_live_update_channel_name)
        val etaText = formatEta(payload)
        val secondary = context.getString(R.string.live_update_notification_secondary, origin, destination)
        val extrasBundle = payload.toExtrasBundle()

        return if (Build.VERSION.SDK_INT >= 35) {
            buildFrameworkNotification(
                payload = payload,
                title = title,
                destination = destination,
                etaText = etaText,
                secondary = secondary,
                extrasBundle = extrasBundle,
                tapIntent = tapIntent,
                dismissIntent = dismissIntent,
            )
        } else {
            buildCompatNotification(
                payload = payload,
                title = title,
                destination = destination,
                etaText = etaText,
                secondary = secondary,
                extrasBundle = extrasBundle,
                tapIntent = tapIntent,
                dismissIntent = dismissIntent,
            )
        }
    }

    private fun buildCompatNotification(
        payload: LiveUpdatePayload,
        title: String,
        destination: String,
        etaText: String,
        secondary: String,
        extrasBundle: android.os.Bundle,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
    ): Notification {
        val hasActuallyArrived = contentBuilder.hasActuallyArrived(payload)
        val destinationIcon = TravelLiveUpdateAssets.trackerIconFor(payload.currentDestinationDisplayName)
        val remainingText = formatRemaining(payload)
        val earliestReturnText = formatEarliestReturn(payload)
        val arrivalClockTime = formatArrivalClockTime(payload)

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(destinationIcon)
            .setContentIntent(tapIntent)
            .setDeleteIntent(dismissIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(!hasActuallyArrived)
            .setAutoCancel(hasActuallyArrived)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setExtras(extrasBundle)
            .setCategory(NotificationCompat.CATEGORY_STATUS)

        if (hasActuallyArrived) {
            val arrivedTitle = context.getString(R.string.live_update_arrived_in_pattern, destination)
            val arrivedContentText = arrivalClockTime?.let {
                context.getString(R.string.live_update_arrived_at_pattern, it)
            } ?: context.getString(R.string.live_update_arrived_label)

            builder.setContentTitle(arrivedTitle)
            builder.setContentText(arrivedContentText)
            builder.setSubText(secondary)
            builder.setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    buildList {
                        add(arrivedContentText)
                        add(secondary)
                        earliestReturnText?.let { add(it) }
                    }.joinToString("\n"),
                ),
            )
            builder.setProgress(0, 0, false)
            builder.setShowWhen(true)
            builder.setUsesChronometer(false)
            builder.setWhen(System.currentTimeMillis())
        } else {
            val contentTextParts = buildList {
                add(etaText)
                remainingText?.let { add(it) }
            }

            builder.setContentTitle("$title $destination")
            builder.setContentText(contentTextParts.joinToString(" • "))
            builder.setSubText(secondary)
            builder.setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    buildList {
                        add(secondary)
                        add(contentTextParts.joinToString(" • "))
                        earliestReturnText?.let { add(it) }
                    }.joinToString("\n"),
                ),
            )

            contentBuilder.computeProgress(payload)?.let {
                builder.setProgress(it.totalSeconds.toInt(), it.elapsedSeconds.toInt(), false)
            } ?: builder.setProgress(0, 0, false)

            val arrivalMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
            if (arrivalMillis > 0) {
                builder.setShowWhen(true)
                builder.setUsesChronometer(true)
                builder.setChronometerCountDown(true)
                builder.setWhen(arrivalMillis)
                enablePromotedOngoing(builder)
                applyShortCriticalText(builder, payload)
            }
        }

        return builder.build()
    }

    @SuppressLint("NewApi")
    private fun buildFrameworkNotification(
        payload: LiveUpdatePayload,
        title: String,
        destination: String,
        etaText: String,
        secondary: String,
        extrasBundle: android.os.Bundle,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
    ): Notification {
        val hasActuallyArrived = contentBuilder.hasActuallyArrived(payload)
        val destinationIcon = TravelLiveUpdateAssets.trackerIconFor(payload.currentDestinationDisplayName)
        val remainingText = formatRemaining(payload)
        val earliestReturnText = formatEarliestReturn(payload)
        val arrivalClockTime = formatArrivalClockTime(payload)

        val builder = Notification.Builder(context, channelId)
            .setSmallIcon(destinationIcon)
            .setContentIntent(tapIntent)
            .setDeleteIntent(dismissIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(!hasActuallyArrived)
            .setAutoCancel(hasActuallyArrived)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setExtras(extrasBundle)
            .setCategory(Notification.CATEGORY_STATUS)

        if (hasActuallyArrived) {
            val arrivedTitle = context.getString(R.string.live_update_arrived_in_pattern, destination)
            val arrivedContentText = arrivalClockTime?.let {
                context.getString(R.string.live_update_arrived_at_pattern, it)
            } ?: context.getString(R.string.live_update_arrived_label)

            builder.setContentTitle(arrivedTitle)
            builder.setContentText(arrivedContentText)
            builder.setSubText(secondary)
            builder.setStyle(
                Notification.BigTextStyle().bigText(
                    buildList {
                        add(arrivedContentText)
                        add(secondary)
                        earliestReturnText?.let { add(it) }
                    }.joinToString("\n"),
                ),
            )
            builder.setProgress(0, 0, false)
            builder.setShowWhen(true)
            builder.setUsesChronometer(false)
            builder.setWhen(System.currentTimeMillis())
        } else {
            val contentTextParts = buildList {
                add(etaText)
                remainingText?.let { add(it) }
            }

            builder.setContentTitle("$title $destination")
            builder.setContentText(contentTextParts.joinToString(" • "))
            builder.setSubText(secondary)

            val progressInfo = contentBuilder.computeProgress(payload)
            val styleApplied = applyProgressStyleIfAvailable(builder, payload, progressInfo)
            if (!styleApplied) {
                builder.setStyle(
                    Notification.BigTextStyle().bigText(
                        buildList {
                            add(secondary)
                            add(contentTextParts.joinToString(" • "))
                            earliestReturnText?.let { add(it) }
                        }.joinToString("\n"),
                    ),
                )
                if (progressInfo != null) {
                    builder.setProgress(progressInfo.totalSeconds.toInt(), progressInfo.elapsedSeconds.toInt(), false)
                } else {
                    builder.setProgress(0, 0, false)
                }
            }

            val arrivalMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
            if (arrivalMillis > 0) {
                builder.setShowWhen(true)
                builder.setUsesChronometer(true)
                builder.setChronometerCountDown(true)
                builder.setWhen(arrivalMillis)
                invokeFrameworkPromotedOngoing(builder)
                buildShortCriticalText(payload)?.let { invokeFrameworkShortCriticalText(builder, it) }
            }
        }

        val notification = builder.build()
        warnIfNotPromotable(notification)
        return notification
    }

    private fun formatEta(payload: LiveUpdatePayload): String {
        val arrival = payload.arrivalTimeTimestamp ?: return context.getString(R.string.live_update_unknown_eta)
        val formatted = android.text.format.DateFormat.getTimeFormat(context).format(java.util.Date(arrival * 1000))
        return if (payload.hasArrived) {
            context.getString(R.string.live_update_arrived_at_pattern, formatted)
        } else {
            context.getString(R.string.live_update_eta_pattern, formatted)
        }
    }

    private fun formatRemaining(payload: LiveUpdatePayload): String? {
        val remainingSeconds = contentBuilder.computeRemainingSeconds(payload) ?: return null
        if (remainingSeconds <= 0) return null
        if (remainingSeconds < 180) {
            val lessThanMinutes = ((remainingSeconds + 59) / 60).coerceAtLeast(1)
            return context.getString(R.string.live_update_remaining_less_than_pattern, "${lessThanMinutes}m")
        }
        val remaining = contentBuilder.computeRemainingTime(payload) ?: return null
        return context.getString(R.string.live_update_remaining_pattern, remaining.toCompact())
    }

    private fun formatEarliestReturn(payload: LiveUpdatePayload): String? {
        val returnTs = payload.earliestReturnTimestamp ?: return null
        val formatted = android.text.format.DateFormat.getTimeFormat(context).format(java.util.Date(returnTs * 1000))
        return context.getString(R.string.live_update_earliest_return_pattern, formatted)
    }

    private fun formatArrivalClockTime(payload: LiveUpdatePayload): String? {
        val arrival = payload.arrivalTimeTimestamp ?: return null
        return android.text.format.DateFormat.getTimeFormat(context).format(java.util.Date(arrival * 1000))
    }

    private fun buildShortCriticalText(payload: LiveUpdatePayload): String? {
        if (payload.hasArrived) {
            return context.getString(R.string.live_update_arrived_label)
        }
        val arrival = payload.arrivalTimeTimestamp ?: return null
        val formatted = android.text.format.DateFormat.getTimeFormat(context).format(java.util.Date(arrival * 1000))
        return context.getString(R.string.live_update_eta_pattern, formatted)
    }

    private fun applyShortCriticalText(builder: NotificationCompat.Builder, payload: LiveUpdatePayload) {
        val shortText = buildShortCriticalText(payload) ?: return
        try {
            val method = builder.javaClass.getMethod("setShortCriticalText", CharSequence::class.java)
            method.invoke(builder, shortText)
        } catch (_: Exception) {
        }
    }

    private fun enablePromotedOngoing(builder: NotificationCompat.Builder) {
        try {
            val method = builder.javaClass.getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
            method.invoke(builder, true)
        } catch (_: Exception) {
        }
    }

    private fun invokeFrameworkPromotedOngoing(builder: Notification.Builder) {
        try {
            val method = builder.javaClass.getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
            method.invoke(builder, true)
        } catch (_: Exception) {
        }
    }

    // Reflective because compileSdk may be below 36 (ProgressStyle is Android 16+).
    @SuppressLint("NewApi")
    private fun applyProgressStyleIfAvailable(
        builder: Notification.Builder,
        payload: LiveUpdatePayload,
        progress: LiveUpdateNotificationContentBuilder.ProgressInfo?,
    ): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        progress ?: return false
        val refs = ProgressStyleRefs.resolve() ?: return false

        val total = progress.totalSeconds.toInt().coerceAtLeast(1)
        val elapsed = progress.elapsedSeconds.toInt().coerceIn(0, total)
        val originIcon = TravelLiveUpdateAssets.flagIconFor(payload.originDisplayName)
        val destinationIcon = TravelLiveUpdateAssets.flagIconFor(payload.currentDestinationDisplayName)
        val trackerIcon = TravelLiveUpdateAssets.trackerIconFor(payload.currentDestinationDisplayName)

        return try {
            val style = refs.styleCtor.newInstance()
            refs.setProgress.invoke(style, elapsed)
            refs.setTrackerIcon.invoke(style, Icon.createWithResource(context, trackerIcon))
            refs.setStartIcon.invoke(style, Icon.createWithResource(context, originIcon))
            refs.setEndIcon.invoke(style, Icon.createWithResource(context, destinationIcon))
            val segment = refs.segmentCtor.newInstance(total)
            refs.addSegment.invoke(style, segment)
            builder.setStyle(style as Notification.Style)
            true
        } catch (t: Throwable) {
            Log.w(TAG, "ProgressStyle unavailable, falling back to BigTextStyle", t)
            false
        }
    }

    @SuppressLint("NewApi")
    private fun warnIfNotPromotable(notification: Notification) {
        if (Build.VERSION.SDK_INT < 36) return
        val method = PromotableRef.resolve(notification.javaClass) ?: return
        try {
            val promotable = method.invoke(notification) as? Boolean ?: return
            if (!promotable) {
                Log.w(TAG, "Live Update notification did not qualify for promotion")
            }
        } catch (t: Throwable) {
            Log.d(TAG, "hasPromotableCharacteristics invocation failed", t)
        }
    }

    private fun invokeFrameworkShortCriticalText(builder: Notification.Builder, text: CharSequence) {
        try {
            val extras = android.os.Bundle().apply {
                putCharSequence("android.shortCriticalText", text)
            }
            builder.addExtras(extras)
        } catch (_: Exception) {
        }

        try {
            val method = builder.javaClass.getMethod("setShortCriticalText", String::class.java)
            method.invoke(builder, text.toString())
        } catch (_: Exception) {
        }
    }

    companion object {
        private const val TAG = "TravelLiveUpdate"
    }

    private class ProgressStyleRefs(
        val styleCtor: java.lang.reflect.Constructor<*>,
        val segmentCtor: java.lang.reflect.Constructor<*>,
        val setProgress: java.lang.reflect.Method,
        val setTrackerIcon: java.lang.reflect.Method,
        val setStartIcon: java.lang.reflect.Method,
        val setEndIcon: java.lang.reflect.Method,
        val addSegment: java.lang.reflect.Method,
    ) {
        companion object {
            @Volatile
            private var cached: ProgressStyleRefs? = null

            @Volatile
            private var unavailable = false

            fun resolve(): ProgressStyleRefs? {
                cached?.let { return it }
                if (unavailable) return null
                return try {
                    val styleClass = Class.forName("android.app.Notification\$ProgressStyle")
                    val segmentClass = Class.forName("android.app.Notification\$ProgressStyle\$Segment")
                    ProgressStyleRefs(
                        styleCtor = styleClass.getDeclaredConstructor(),
                        segmentCtor = segmentClass.getDeclaredConstructor(Int::class.javaPrimitiveType),
                        setProgress = styleClass.getMethod("setProgress", Int::class.javaPrimitiveType),
                        setTrackerIcon = styleClass.getMethod("setProgressTrackerIcon", Icon::class.java),
                        setStartIcon = styleClass.getMethod("setProgressStartIcon", Icon::class.java),
                        setEndIcon = styleClass.getMethod("setProgressEndIcon", Icon::class.java),
                        addSegment = styleClass.getMethod("addProgressSegment", segmentClass),
                    ).also { cached = it }
                } catch (_: Throwable) {
                    unavailable = true
                    null
                }
            }
        }
    }

    private object PromotableRef {
        @Volatile
        private var cached: java.lang.reflect.Method? = null

        @Volatile
        private var unavailable = false

        fun resolve(notificationClass: Class<*>): java.lang.reflect.Method? {
            cached?.let { return it }
            if (unavailable) return null
            return try {
                notificationClass.getMethod("hasPromotableCharacteristics").also { cached = it }
            } catch (_: Throwable) {
                unavailable = true
                null
            }
        }
    }

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
}
