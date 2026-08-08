package com.manuito.tornpda.liveupdates

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TravelLiveUpdateApiClientTest {

    private val now = 1_700_000_000L

    private fun response(travel: String, status: String? = null): JSONObject {
        val statusPart = status?.let { ""","status":$it""" } ?: ""
        return JSONObject("""{"travel":$travel$statusPart}""")
    }

    @Test
    fun flyingAbroadIsDetected() {
        val json = response("""{"destination":"Switzerland","timestamp":5000,"departed":2000,"time_left":1800}""")
        val result = TravelLiveUpdateApiClient.parseResponse(json, now)

        assertTrue(result is TravelFetchResult.Flying)
        val state = (result as TravelFetchResult.Flying).state
        assertEquals("Switzerland", state.destination)
        assertEquals(5000L, state.arrivalTimestamp)
        assertEquals(2000L, state.departureTimestamp)
        assertEquals(1800L, state.timeLeftSeconds)
    }

    @Test
    fun flyingBackHomeIsDetected() {
        val json = response("""{"destination":"Torn","timestamp":5000,"departed":2000,"time_left":1800}""")
        val result = TravelLiveUpdateApiClient.parseResponse(json, now)
        assertEquals("Torn", (result as TravelFetchResult.Flying).state.destination)
    }

    @Test
    fun standingAbroadIsNotAFlight() {
        val json = response("""{"destination":"Switzerland","timestamp":5000,"departed":2000,"time_left":0}""")
        val result = TravelLiveUpdateApiClient.parseResponse(json, now)
        assertEquals(TravelFetchResult.Abroad("Switzerland"), result)
    }

    @Test
    fun backInTornIsTerminal() {
        val json = response("""{"destination":"Torn","timestamp":5000,"departed":2000,"time_left":0}""")
        assertEquals(TravelFetchResult.Home, TravelLiveUpdateApiClient.parseResponse(json, now))
    }

    @Test
    fun playerWhoNeverTravelledCountsAsHome() {
        val json = response("""{"destination":"","timestamp":0,"departed":0,"time_left":0}""")
        assertEquals(TravelFetchResult.Home, TravelLiveUpdateApiClient.parseResponse(json, now))
    }

    @Test
    fun hospitalisedFlightHomeIsRepatriation() {
        val json = response(
            travel = """{"destination":"Torn","timestamp":5000,"departed":2000,"time_left":1800}""",
            status = """{"state":"Hospital","until":${now + 600}}""",
        )
        val result = TravelLiveUpdateApiClient.parseResponse(json, now)
        assertTrue((result as TravelFetchResult.Flying).state.isRepatriation)
    }

    @Test
    fun hospitalWithoutUntilStillCountsAsRepatriation() {
        val json = response(
            travel = """{"destination":"Torn","timestamp":5000,"departed":2000,"time_left":1800}""",
            status = """{"state":"Hospital"}""",
        )
        val result = TravelLiveUpdateApiClient.parseResponse(json, now)
        assertTrue((result as TravelFetchResult.Flying).state.isRepatriation)
    }

    @Test
    fun expiredHospitalTimeIsNotRepatriation() {
        val json = response(
            travel = """{"destination":"Torn","timestamp":5000,"departed":2000,"time_left":1800}""",
            status = """{"state":"Hospital","until":${now - 600}}""",
        )
        val result = TravelLiveUpdateApiClient.parseResponse(json, now)
        assertTrue(!(result as TravelFetchResult.Flying).state.isRepatriation)
    }

    @Test
    fun outboundFlightIsNeverRepatriation() {
        val json = response(
            travel = """{"destination":"Mexico","timestamp":5000,"departed":2000,"time_left":1800}""",
            status = """{"state":"Hospital","until":${now + 600}}""",
        )
        val result = TravelLiveUpdateApiClient.parseResponse(json, now)
        assertTrue(!(result as TravelFetchResult.Flying).state.isRepatriation)
    }

    // ── failures ─────────────────────────────────────────────────────────

    @Test
    fun apiErrorIsTransient() {
        val json = JSONObject("""{"error":{"code":5,"error":"Too many requests"}}""")
        assertEquals(TravelFetchResult.TransientError, TravelLiveUpdateApiClient.parseResponse(json, now))
    }

    @Test
    fun missingTravelBlockIsTransient() {
        val json = JSONObject("""{"status":{"state":"Okay"}}""")
        assertEquals(TravelFetchResult.TransientError, TravelLiveUpdateApiClient.parseResponse(json, now))
    }

    @Test
    fun flyingWithUnusableTimestampsIsTransient() {
        val json = response("""{"destination":"Switzerland","timestamp":0,"departed":0,"time_left":1800}""")
        assertEquals(TravelFetchResult.TransientError, TravelLiveUpdateApiClient.parseResponse(json, now))
    }
}
