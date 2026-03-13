package com.manuito.tornpda.liveupdates

import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Result of a background Racing API fetch.
 *
 * Distinguishes between "user is no longer racing" (API responded correctly
 * but icons are absent) and "could not determine state" (network/server error).
 */
sealed class RacingFetchResult {
    /** API responded and the user is actively racing. */
    data class Active(val state: RacingLiveUpdateState) : RacingFetchResult()
    /** API responded successfully but no racing icons are present — user is not racing. */
    object Inactive : RacingFetchResult()
    /** Network error, HTTP error, or API error — state is unknown. */
    object TransientError : RacingFetchResult()
}

object RacingLiveUpdateApiClient {

    fun fetchLatestState(apiKey: String): RacingFetchResult {
        return try {
            val connection = URL("https://api.torn.com:443/user/?selections=icons&key=$apiKey&comment=PDA-RacingLiveUpdate")
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
                    RacingFetchResult.TransientError
                } else {
                    val body = connection.inputStream.bufferedReader().use { it.readText() }
                    val json = JSONObject(body)
                    if (json.has("error")) {
                        Log.w(TAG, "API: error in response: ${json.optJSONObject("error")}")
                        RacingFetchResult.TransientError
                    } else {
                        val icons = json.optJSONObject("icons")
                        val icon17 = icons?.takeIf { it.has("icon17") && !it.isNull("icon17") }?.getString("icon17")
                        val icon18 = icons?.takeIf { it.has("icon18") && !it.isNull("icon18") }?.getString("icon18")
                        val state = RacingLiveUpdateParser.parse(
                            icon17 = icon17,
                            icon18 = icon18,
                            baseTimestamp = System.currentTimeMillis() / 1000,
                        )
                        if (state != null) {
                            Log.d(TAG, "API: Active → phase=${state.phase}")
                            RacingFetchResult.Active(state)
                        } else {
                            Log.d(TAG, "API: Inactive (no racing icons)")
                            RacingFetchResult.Inactive
                        }
                    }
                }
            } finally {
                connection.disconnect()
            }
        } catch (e: Exception) {
            Log.w(TAG, "API: exception: ${e.message}")
            RacingFetchResult.TransientError
        }
    }

    private const val TAG = "RacingLU"
}