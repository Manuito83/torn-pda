package com.manuito.tornpda.liveupdates

import java.util.HashMap

/**
 * Parsed representation of the Live Activity payload sent from Flutter
 * Keeps the most common fields typed while preserving the raw map for adapters that need it
 */
data class LiveUpdatePayload(
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
    val extras: Map<String, Any?>,
) {

    val isValid: Boolean
        get() = arrivalTimeTimestamp != null && departureTimeTimestamp != null

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
        fun fromMap(arguments: Map<String, Any?>?): LiveUpdatePayload {
            val safeMap = arguments?.toMap().orEmpty()
            return LiveUpdatePayload(
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
