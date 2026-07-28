package com.manuito.tornpda.liveupdates

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TravelLiveUpdateParserTest {

    private val now = 1_700_000_000L

    private fun state(
        destination: String = "Switzerland",
        arrival: Long = 5_000L,
        departure: Long = 2_000L,
        timeLeft: Long = 1_800L,
        isRepatriation: Boolean = false,
    ) = TravelLiveUpdateState(
        destination = destination,
        arrivalTimestamp = arrival,
        departureTimestamp = departure,
        timeLeftSeconds = timeLeft,
        isRepatriation = isRepatriation,
    )

    // ── device-relative timestamps ───────────────────────────────────────

    @Test
    fun arrivalIsDeviceRelativeAndKeepsServerDuration() {
        val args = TravelLiveUpdateParser.buildEnRouteArguments(state(), now, apiKey = null)

        // 3000 s of flight, 1800 s still to go
        assertEquals(now + 1_800L, args["arrivalTimeTimestamp"])
        assertEquals(now + 1_800L - 3_000L, args["departureTimeTimestamp"])
        assertEquals(now, args["currentServerTimestamp"])
    }

    @Test
    fun buildsAPayloadTheNotificationLayerAccepts() {
        val args = TravelLiveUpdateParser.buildEnRouteArguments(state(), now, apiKey = null)
        val payload = LiveUpdatePayload.fromMap(LiveUpdateActivityType.TRAVEL, args)
        assertTrue(payload.isValidFor(LiveUpdateActivityType.TRAVEL))
        assertFalse(payload.hasArrived)
    }

    // ── outbound / return / repatriation ─────────────────────────────────

    @Test
    fun outboundTripIsLabelledAndGetsAnEarliestReturn() {
        val args = TravelLiveUpdateParser.buildEnRouteArguments(state(), now, apiKey = null)

        assertEquals("Traveling to", args["activityStateTitle"])
        assertEquals("Switzerland", args["currentDestinationDisplayName"])
        assertEquals("Torn", args["originDisplayName"])
        // arrival + one more leg of the same duration
        assertEquals(now + 1_800L + 3_000L, args["earliestReturnTimestamp"])
    }

    @Test
    fun returnTripFlipsOriginAndDropsEarliestReturn() {
        val args = TravelLiveUpdateParser.buildEnRouteArguments(state(destination = "Torn"), now, apiKey = null)

        assertEquals("Returning to", args["activityStateTitle"])
        assertEquals("Torn", args["currentDestinationDisplayName"])
        assertEquals("Abroad", args["originDisplayName"])
        assertNull(args["earliestReturnTimestamp"])
    }

    @Test
    fun repatriationComesFromHospital() {
        val args = TravelLiveUpdateParser.buildEnRouteArguments(
            state(destination = "Torn", isRepatriation = true),
            now,
            apiKey = null,
        )

        assertEquals("Repatriating to", args["activityStateTitle"])
        assertEquals("Hospital", args["originDisplayName"])
        assertEquals("Torn", args["currentDestinationDisplayName"])
    }

    // ── identifiers ──────────────────────────────────────────────────────

    @Test
    fun identifierUsesServerTimestampsSoItIsStableAcrossPolls() {
        val early = TravelLiveUpdateParser.buildEnRouteArguments(state(timeLeft = 1_800L), now, null)
        val late = TravelLiveUpdateParser.buildEnRouteArguments(state(timeLeft = 60L), now + 1_740, null)
        assertEquals(early["travelIdentifier"], late["travelIdentifier"])
        assertEquals("Switzerland-5000-2000", early["travelIdentifier"])
    }

    @Test
    fun repatriationIdentifierIsDistinctFromAPlainReturn() {
        val plain = TravelLiveUpdateParser.travelIdentifier(state(destination = "Torn"))
        val repat = TravelLiveUpdateParser.travelIdentifier(state(destination = "Torn", isRepatriation = true))
        assertEquals("$plain-repat", repat)
    }

    // ── api key ──────────────────────────────────────────────────────────

    @Test
    fun apiKeyIsForwardedSoTheChainCanKeepPolling() {
        val args = TravelLiveUpdateParser.buildEnRouteArguments(state(), now, apiKey = "abc123")
        assertEquals("abc123", args[LiveUpdateNotificationReceiver.EXTRA_API_KEY])
    }

    @Test
    fun blankApiKeyIsNotForwarded() {
        val args = TravelLiveUpdateParser.buildEnRouteArguments(state(), now, apiKey = "  ")
        assertFalse(args.containsKey(LiveUpdateNotificationReceiver.EXTRA_API_KEY))
    }
}
