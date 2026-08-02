package com.manuito.tornpda.liveupdates

/** A flight in progress, as reported by the Torn API. */
data class TravelLiveUpdateState(
    val destination: String,
    val arrivalTimestamp: Long,
    val departureTimestamp: Long,
    val timeLeftSeconds: Long,
    val isRepatriation: Boolean = false,
)

/**
 * Builds the payload for a flight found by the abroad poll. Keep in sync with
 * `_buildArgs` in live_activity_travel_controller.dart. Fields Android never
 * reads (vehicleAssetName, destinationEmoji, flag assets) are left out.
 */
object TravelLiveUpdateParser {

    fun buildEnRouteArguments(
        state: TravelLiveUpdateState,
        nowSeconds: Long,
        apiKey: String?,
        originCountry: String? = null,
    ): Map<String, Any?> {
        val duration = (state.arrivalTimestamp - state.departureTimestamp).coerceAtLeast(0L)

        // Device-relative, same as computeDeviceRelativeTimestamps on the Dart side
        val arrival = nowSeconds + state.timeLeftSeconds
        val departure = arrival - duration

        val destinationName: String
        val originName: String
        val title: String
        var earliestReturn: Long? = null

        when {
            state.isRepatriation -> {
                destinationName = TORN
                originName = "Hospital"
                title = "Repatriating to"
            }
            state.destination.equals(TORN, ignoreCase = true) -> {
                destinationName = TORN
                originName = "Abroad"
                title = "Returning to"
            }
            else -> {
                destinationName = state.destination
                originName = TORN
                title = "Traveling to"
                if (duration > 0) earliestReturn = arrival + duration
            }
        }

        val arguments = mutableMapOf<String, Any?>(
            "currentDestinationDisplayName" to destinationName,
            "originDisplayName" to originName,
            "arrivalTimeTimestamp" to arrival,
            "departureTimeTimestamp" to departure,
            "currentServerTimestamp" to nowSeconds,
            "activityStateTitle" to title,
            "showProgressBar" to true,
            "hasArrived" to false,
            "travelIdentifier" to travelIdentifier(state),
        )
        earliestReturn?.let { arguments["earliestReturnTimestamp"] = it }
        if (!apiKey.isNullOrBlank()) arguments[LiveUpdateNotificationReceiver.EXTRA_API_KEY] = apiKey

        val routeCountry = if (destinationName == TORN) originCountry else state.destination
        if (!routeCountry.isNullOrBlank() && !routeCountry.equals(TORN, ignoreCase = true)) {
            arguments["routeCountry"] = routeCountry
        }
        return arguments
    }

    /** Same as `_buildTravelId`: server timestamps, so it survives polls. */
    fun travelIdentifier(state: TravelLiveUpdateState): String {
        val base = "${state.destination}-${state.arrivalTimestamp}-${state.departureTimestamp}"
        return if (state.isRepatriation) "$base-repat" else base
    }

    private const val TORN = "Torn"
}
