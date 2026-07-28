package com.manuito.tornpda.liveupdates

import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/** Result of a background Travel API fetch. Each case drives a different alarm chain. */
sealed class TravelFetchResult {
    /** In the air. */
    data class Flying(val state: TravelLiveUpdateState) : TravelFetchResult()

    /** Standing abroad. */
    data class Abroad(val destination: String) : TravelFetchResult()

    /** In Torn, nothing left to track. */
    object Home : TravelFetchResult()

    /** Network, HTTP or API error: state unknown. */
    object TransientError : TravelFetchResult()
}

object TravelLiveUpdateApiClient {

    fun fetchLatestState(apiKey: String): TravelFetchResult {
        return try {
            // "status" is not a selection, it comes nested inside basic
            val connection = URL("https://api.torn.com:443/user/?selections=travel,basic&key=$apiKey&comment=PDA-TravelLiveUpdate")
                .openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "GET"
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                connection.setRequestProperty("source-app", "torn-pda")
                connection.setRequestProperty("User-Agent", "TornPDA-Android")

                val code = connection.responseCode
                if (code !in 200..299) {
                    val errBody = try {
                        (connection.errorStream ?: connection.inputStream)
                            .bufferedReader().use { it.readText() }
                            .take(500)
                    } catch (_: Exception) { "(unreadable)" }
                    Log.w(TAG, "API: HTTP $code — body: $errBody")
                    TravelFetchResult.TransientError
                } else {
                    val body = connection.inputStream.bufferedReader().use { it.readText() }
                    val result = parseResponse(JSONObject(body))
                    when (result) {
                        is TravelFetchResult.Flying -> Log.d(TAG, "API: flying to ${result.state.destination}")
                        is TravelFetchResult.Abroad -> Log.d(TAG, "API: abroad in ${result.destination}")
                        TravelFetchResult.Home -> Log.d(TAG, "API: in Torn")
                        TravelFetchResult.TransientError -> Log.w(TAG, "API: unusable response — ${body.take(500)}")
                    }
                    result
                }
            } finally {
                connection.disconnect()
            }
        } catch (e: Exception) {
            Log.w(TAG, "API: exception: ${e.message}")
            TravelFetchResult.TransientError
        }
    }

    /** Kept free of Android calls so it can be unit tested. Callers log. */
    fun parseResponse(
        json: JSONObject,
        nowSeconds: Long = System.currentTimeMillis() / 1000,
    ): TravelFetchResult {
        if (json.has("error")) return TravelFetchResult.TransientError

        val travel = json.optJSONObject("travel") ?: return TravelFetchResult.TransientError
        val destination = travel.optString("destination").trim()
        val timeLeft = travel.optLong("time_left", 0L)

        if (timeLeft <= 0L) {
            // Blank destination means the player never flew, so treat it as home
            return if (destination.isEmpty() || destination.equals(TORN, ignoreCase = true)) {
                TravelFetchResult.Home
            } else {
                TravelFetchResult.Abroad(destination)
            }
        }

        val arrival = travel.optLong("timestamp", 0L)
        val departure = travel.optLong("departed", 0L)
        if (destination.isEmpty() || arrival <= 0L || departure <= 0L) return TravelFetchResult.TransientError

        val status = json.optJSONObject("status")
        val hospitalUntil = status?.optLong("until", 0L) ?: 0L
        val isRepatriation = destination.equals(TORN, ignoreCase = true) &&
            status?.optString("state").equals("Hospital", ignoreCase = true) &&
            // basic may not carry "until", so don't require it
            (hospitalUntil <= 0L || hospitalUntil > nowSeconds)

        return TravelFetchResult.Flying(
            TravelLiveUpdateState(
                destination = destination,
                arrivalTimestamp = arrival,
                departureTimestamp = departure,
                timeLeftSeconds = timeLeft,
                isRepatriation = isRepatriation,
            ),
        )
    }

    private const val TAG = "TravelLiveUpdate"
    private const val TORN = "Torn"
}
