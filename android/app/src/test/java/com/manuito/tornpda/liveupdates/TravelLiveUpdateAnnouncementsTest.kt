package com.manuito.tornpda.liveupdates

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TravelLiveUpdateAnnouncementsTest {

    private val departure = 1_000_000L
    private val arrival = 1_010_000L

    private val countries = listOf(
        "Mexico", "Cayman Islands", "Canada", "Hawaii", "United Kingdom", "Argentina",
        "Switzerland", "Japan", "China", "UAE", "South Africa",
    )

    private fun outbound(
        destination: String,
        at: Long,
        travelIdentifier: String = "trip-1",
    ) = TravelLiveUpdateAnnouncements.announcementFor(
        destination = destination,
        origin = "Torn",
        routeCountry = destination,
        departureTimestamp = departure,
        arrivalTimestamp = arrival,
        travelIdentifier = travelIdentifier,
        nowSeconds = at,
    )

    private fun home(
        country: String,
        at: Long,
        travelIdentifier: String = "trip-2",
    ) = TravelLiveUpdateAnnouncements.announcementFor(
        destination = "Torn",
        origin = "Abroad",
        routeCountry = country,
        departureTimestamp = departure,
        arrivalTimestamp = arrival,
        travelIdentifier = travelIdentifier,
        nowSeconds = at,
    )

    private fun at(fraction: Double) = departure + ((arrival - departure) * fraction).toLong()

    // ── coverage ─────────────────────────────────────────────────────────

    @Test
    fun everyDestinationHasAnnouncementsBothWays() {
        for (country in countries) {
            for (fraction in listOf(0.0, 0.25, 0.5, 0.75, 0.99)) {
                assertNotNull("$country outbound at $fraction", outbound(country, at(fraction)))
                assertNotNull("$country home at $fraction", home(country, at(fraction)))
            }
        }
    }

    @Test
    fun everyLineFitsOnOneNotificationLine() {
        for (country in countries + "") {
            for (step in 0..40) {
                val fraction = step / 40.0
                for (id in listOf("a", "b", "c", "d", "e")) {
                    outbound(country, at(fraction), id)?.let {
                        assertTrue("too long for $country: \"$it\" (${it.length})", it.length <= 60)
                    }
                    home(country, at(fraction), id)?.let {
                        assertTrue("too long for $country: \"$it\" (${it.length})", it.length <= 60)
                    }
                }
            }
        }
    }

    @Test
    fun caseAndPaddingDoNotBreakTheLookup() {
        assertEquals(outbound("Mexico", at(0.5)), outbound("  mexico  ", at(0.5)))
    }

    @Test
    fun uaeGoesByItsApiName() {
        assertEquals(outbound("United Arab Emirates", at(0.5)), outbound("UAE", at(0.5)))
        assertNotNull(outbound("UAE", at(0.5)))
    }

    @Test
    fun unknownDestinationHasNoAnnouncement() {
        assertNull(outbound("Atlantis", at(0.5)))
    }

    // ── progress drives the segment ──────────────────────────────────────

    @Test
    fun theFlightMovesThroughItsSegments() {
        val seen = (0..20).map { outbound("South Africa", at(it / 20.0)) }.distinct()
        assertEquals("six segments on the longest route", 6, seen.size)
    }

    @Test
    fun shortRoutesUseFewerSegments() {
        val seen = (0..20).map { outbound("Mexico", at(it / 20.0)) }.distinct()
        assertEquals(3, seen.size)
    }

    @Test
    fun departureAndArrivalSitAtTheEnds() {
        val takeoff = outbound("Switzerland", departure)
        val landing = outbound("Switzerland", arrival)
        assertNotEquals(takeoff, landing)
        assertEquals("still the takeoff line a moment later", takeoff, outbound("Switzerland", departure + 60))
    }

    @Test
    fun clockOutsideTheFlightIsClamped() {
        assertEquals(outbound("Japan", departure), outbound("Japan", departure - 5_000))
        assertEquals(outbound("Japan", arrival), outbound("Japan", arrival + 5_000))
    }

    // ── stability ────────────────────────────────────────────────────────

    @Test
    fun theSameSegmentAlwaysRepeatsTheSameLine() {
        val first = outbound("Hawaii", at(0.5))
        repeat(20) { assertEquals(first, outbound("Hawaii", at(0.5))) }
    }

    @Test
    fun differentTripsCanGetDifferentWording() {
        val lines = (1..40).map { outbound("China", at(0.5), travelIdentifier = "trip-$it") }.toSet()
        assertTrue("variants should not collapse to one", lines.size > 1)
    }

    // ── direction ────────────────────────────────────────────────────────

    @Test
    fun theWayHomeWalksTheRouteBackwards() {
        val outboundLegs = (0..20).map { outbound("United Kingdom", at(it / 20.0)) }.distinct()
        val homeLegs = (0..20).map { home("United Kingdom", at(it / 20.0)) }.distinct()
        assertEquals(outboundLegs.size, homeLegs.size)
        assertNotEquals("takeoff differs by direction", outboundLegs.first(), homeLegs.first())
        assertNotEquals("landing differs by direction", outboundLegs.last(), homeLegs.last())
    }

    @Test
    fun comingHomeEndsAtTorn() {
        val landing = home("Japan", arrival)
        assertNotNull(landing)
        assertTrue("should name Torn: \"$landing\"", landing!!.contains("Torn"))
    }

    @Test
    fun repatriationHasItsOwnLine() {
        val line = TravelLiveUpdateAnnouncements.announcementFor(
            destination = "Torn",
            origin = "Hospital",
            routeCountry = null,
            departureTimestamp = departure,
            arrivalTimestamp = arrival,
            travelIdentifier = "repat",
            nowSeconds = at(0.5),
        )
        assertNotNull(line)
        assertFalse(line!!.contains("Wheels up"))
    }

    @Test
    fun aLegHomeWithoutAKnownCountryGetsTheGenericCaptain() {
        val seen = (0..20).map { home(country = "", at = at(it / 20.0)) }.distinct()
        assertEquals("takeoff, cruise, arrival", 3, seen.size)
        seen.forEach { assertNotNull(it) }
        assertTrue("should end at Torn: \"${seen.last()}\"", seen.last()!!.contains("Torn"))
    }

    @Test
    fun homeCruiseNeverRepeatsTheOutboundWording() {
        for (country in countries) {
            val outboundLines = (0..40).flatMap { step ->
                listOf("a", "b", "c", "d", "e").mapNotNull { outbound(country, at(step / 40.0), it) }
            }.toSet()
            val homeLines = (0..40).flatMap { step ->
                listOf("a", "b", "c", "d", "e").mapNotNull { home(country, at(step / 40.0), it) }
            }.toSet()
            val shared = outboundLines.intersect(homeLines)
            assertTrue("$country reuses outbound lines on the way home: $shared", shared.isEmpty())
        }
    }

    // ── guards ───────────────────────────────────────────────────────────

    @Test
    fun missingOrBackwardsTimestampsAreIgnored() {
        assertNull(
            TravelLiveUpdateAnnouncements.announcementFor(
                "Mexico", "Torn", "Mexico", null, arrival, "x", at(0.5),
            ),
        )
        assertNull(
            TravelLiveUpdateAnnouncements.announcementFor(
                "Mexico", "Torn", "Mexico", arrival, departure, "x", at(0.5),
            ),
        )
    }
}
