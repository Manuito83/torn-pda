package com.manuito.tornpda.liveupdates

import java.util.HashMap

/**
 * Parsed representation of the Live Activity payload sent from Flutter
 * Keeps the most common fields typed while preserving the raw map for adapters that need it
 */
data class LiveUpdatePayload(
    val activityType: LiveUpdateActivityType,
    val currentDestinationDisplayName: String?,
    val currentDestinationFlagAsset: String?,
    val originDisplayName: String?,
    val originFlagAsset: String?,
    val arrivalTimeTimestamp: Long?,
    val departureTimeTimestamp: Long?,
    val currentServerTimestamp: Long?,
    val vehicleAssetName: String?,
    val earliestReturnTimestamp: Long?,
    val activityStateTitle: String?,
    val showProgressBar: Boolean,
    val hasArrived: Boolean,
    val travelIdentifier: String?,
    val destinationEmoji: String?,
    val stateIdentifier: String?,
    val phase: String?,
    val titleText: String?,
    val bodyText: String?,
    val targetTimeTimestamp: Long?,
    val showTimer: Boolean,
    val extras: Map<String, Any?>,
) {

    val contentIdentifier: String?
        get() = when (activityType) {
            LiveUpdateActivityType.TRAVEL -> travelIdentifier
            LiveUpdateActivityType.RACING -> stateIdentifier
        }

    fun isValidFor(activityType: LiveUpdateActivityType = this.activityType): Boolean {
        return when (activityType) {
            LiveUpdateActivityType.TRAVEL -> arrivalTimeTimestamp != null && departureTimeTimestamp != null
            LiveUpdateActivityType.RACING -> !stateIdentifier.isNullOrBlank() && !titleText.isNullOrBlank()
        }
    }

    fun withExtra(key: String, value: Any?): LiveUpdatePayload {
        val mutable = HashMap(extras)
        if (value == null) {
            mutable.remove(key)
        } else {
            mutable[key] = value
        }
        return copy(extras = mutable)
    }

    companion object {
        fun fromMap(
            activityType: LiveUpdateActivityType = LiveUpdateActivityType.TRAVEL,
            arguments: Map<String, Any?>?,
        ): LiveUpdatePayload {
            val safeMap = arguments?.toMap().orEmpty()
            return LiveUpdatePayload(
                activityType = activityType,
                currentDestinationDisplayName = safeMap["currentDestinationDisplayName"] as? String,
                currentDestinationFlagAsset = safeMap["currentDestinationFlagAsset"] as? String,
                originDisplayName = safeMap["originDisplayName"] as? String,
                originFlagAsset = safeMap["originFlagAsset"] as? String,
                arrivalTimeTimestamp = safeMap["arrivalTimeTimestamp"].toLongOrNull(),
                departureTimeTimestamp = safeMap["departureTimeTimestamp"].toLongOrNull(),
                currentServerTimestamp = safeMap["currentServerTimestamp"].toLongOrNull(),
                vehicleAssetName = safeMap["vehicleAssetName"] as? String,
                earliestReturnTimestamp = safeMap["earliestReturnTimestamp"].toLongOrNull(),
                activityStateTitle = safeMap["activityStateTitle"] as? String,
                showProgressBar = safeMap["showProgressBar"] == true,
                hasArrived = safeMap["hasArrived"] == true,
                travelIdentifier = safeMap["travelIdentifier"] as? String,
                destinationEmoji = safeMap["destinationEmoji"] as? String,
                stateIdentifier = safeMap["stateIdentifier"] as? String,
                phase = safeMap["phase"] as? String,
                titleText = safeMap["titleText"] as? String,
                bodyText = safeMap["bodyText"] as? String,
                targetTimeTimestamp = safeMap["targetTimeTimestamp"].toLongOrNull(),
                showTimer = safeMap["showTimer"] == true,
                extras = safeMap,
            )
        }

        private fun Any?.toLongOrNull(): Long? = when (this) {
            is Int -> this.toLong()
            is Long -> this
            is Double -> this.toLong()
            is Float -> this.toLong()
            is String -> this.toLongOrNull()
            else -> null
        }

        private fun Map<String, Any?>?.toMap(): Map<String, Any?> {
            if (this == null) return emptyMap()
            return HashMap(this)
        }
    }
}
