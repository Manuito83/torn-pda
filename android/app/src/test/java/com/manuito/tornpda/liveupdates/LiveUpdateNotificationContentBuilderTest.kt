package com.manuito.tornpda.liveupdates

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LiveUpdateNotificationContentBuilderTest {

    // ── helpers ──────────────────────────────────────────────────────────

    private fun builderAt(nowMillis: Long) =
        LiveUpdateNotificationContentBuilder(timeProvider = { nowMillis })

    private fun payload(
        hasArrived: Boolean = false,
        arrivalTimestamp: Long? = null,
        departureTimestamp: Long? = null,
    ) = LiveUpdatePayload(
        currentDestinationDisplayName = "Mexico",
        currentDestinationFlagAsset = null,
        originDisplayName = "Torn",
        originFlagAsset = null,
        arrivalTimeTimestamp = arrivalTimestamp,
        departureTimeTimestamp = departureTimestamp,
        currentServerTimestamp = null,
        vehicleAssetName = null,
        earliestReturnTimestamp = null,
        activityStateTitle = "Traveling to",
        showProgressBar = true,
        hasArrived = hasArrived,
        travelIdentifier = "travel-1",
        destinationEmoji = null,
        extras = emptyMap(),
    )

    // ── hasActuallyArrived ──────────────────────────────────────────────

    @Test
    fun hasActuallyArrived_falseWhenEnRouteAndArrivalInFuture() {
        val now = 1_000_000_000L * 1000  // millis
        val arrival = 1_000_000_100L      // seconds — 100 s in the future
        val builder = builderAt(now)
        assertFalse(builder.hasActuallyArrived(payload(arrivalTimestamp = arrival)))
    }

    @Test
    fun hasActuallyArrived_trueWhenFlutterSaysArrived() {
        val now = 1_000_000_000L * 1000
        val arrival = 1_000_000_100L  // still in the future, but Flutter says arrived
        val builder = builderAt(now)
        assertTrue(builder.hasActuallyArrived(payload(hasArrived = true, arrivalTimestamp = arrival)))
    }

    @Test
    fun hasActuallyArrived_trueWhenTimePastArrival() {
        val arrivalSec = 1_000_000_000L
        val now = (arrivalSec + 5) * 1000  // 5 s past arrival
        val builder = builderAt(now)
        assertTrue(builder.hasActuallyArrived(payload(arrivalTimestamp = arrivalSec)))
    }

    @Test
    fun hasActuallyArrived_falseWhenNoArrivalTimestamp() {
        val builder = builderAt(System.currentTimeMillis())
        assertFalse(builder.hasActuallyArrived(payload(arrivalTimestamp = null)))
    }

    @Test
    fun hasActuallyArrived_trueWhenArrivalExactlyNow() {
        val arrivalSec = 1_000_000_000L
        val now = arrivalSec * 1000  // exactly at arrival
        val builder = builderAt(now)
        assertTrue(builder.hasActuallyArrived(payload(arrivalTimestamp = arrivalSec)))
    }

    // ── computeProgress ─────────────────────────────────────────────────

    @Test
    fun computeProgress_zeroAtDeparture() {
        val departure = 1_000L
        val arrival = 2_000L
        val now = departure * 1000  // at departure
        val builder = builderAt(now)

        val progress = builder.computeProgress(payload(departureTimestamp = departure, arrivalTimestamp = arrival))
        assertNotNull(progress)
        assertEquals(0L, progress!!.elapsedSeconds)
        assertEquals(arrival - departure, progress.totalSeconds)
    }

    @Test
    fun computeProgress_fiftyPercentAtMidpoint() {
        val departure = 1_000L
        val arrival = 2_000L
        val mid = (departure + arrival) / 2
        val now = mid * 1000
        val builder = builderAt(now)

        val progress = builder.computeProgress(payload(departureTimestamp = departure, arrivalTimestamp = arrival))
        assertNotNull(progress)
        assertEquals(mid - departure, progress!!.elapsedSeconds)
    }

    @Test
    fun computeProgress_hundredPercentAtArrival() {
        val departure = 1_000L
        val arrival = 2_000L
        val now = arrival * 1000
        val builder = builderAt(now)

        val progress = builder.computeProgress(payload(departureTimestamp = departure, arrivalTimestamp = arrival))
        assertNotNull(progress)
        assertEquals(progress!!.totalSeconds, progress.elapsedSeconds)
    }

    @Test
    fun computeProgress_clampedWhenPastArrival() {
        val departure = 1_000L
        val arrival = 2_000L
        val now = (arrival + 500) * 1000  // 500 s past arrival
        val builder = builderAt(now)

        val progress = builder.computeProgress(payload(departureTimestamp = departure, arrivalTimestamp = arrival))
        assertNotNull(progress)
        assertEquals(progress!!.totalSeconds, progress.elapsedSeconds)
    }

    @Test
    fun computeProgress_nullWhenTimestampsMissing() {
        val builder = builderAt(1_000_000L)
        assertNull(builder.computeProgress(payload(departureTimestamp = null, arrivalTimestamp = null)))
        assertNull(builder.computeProgress(payload(departureTimestamp = 100L, arrivalTimestamp = null)))
        assertNull(builder.computeProgress(payload(departureTimestamp = null, arrivalTimestamp = 200L)))
    }

    @Test
    fun computeProgress_handlesArrivalBeforeDeparture() {
        // Edge case: arrival < departure — totalSeconds clamps to 1
        val departure = 2_000L
        val arrival = 1_000L
        val now = 1_500L * 1000
        val builder = builderAt(now)

        val progress = builder.computeProgress(payload(departureTimestamp = departure, arrivalTimestamp = arrival))
        assertNotNull(progress)
        assertEquals(1L, progress!!.totalSeconds)  // max(1, arrival - departure) = 1
    }

    // ── computeRemainingTime ────────────────────────────────────────────

    @Test
    fun computeRemainingTime_hoursAndMinutesForLongTravel() {
        val arrivalSec = 10_000L
        val nowMillis = (arrivalSec - 5000) * 1000  // 5000 s remaining → 1h 23m (5000/3600=1, (5000%3600)/60=23)
        val builder = builderAt(nowMillis)

        val remaining = builder.computeRemainingTime(payload(arrivalTimestamp = arrivalSec))
        assertNotNull(remaining)
        assertEquals(1L, remaining!!.hours)
        assertEquals(23L, remaining.minutes)
        assertEquals("1h 23m", remaining.toCompact())
    }

    @Test
    fun computeRemainingTime_justMinutesForShortTravel() {
        val arrivalSec = 10_000L
        val nowMillis = (arrivalSec - 900) * 1000  // 900 s remaining → 15m
        val builder = builderAt(nowMillis)

        val remaining = builder.computeRemainingTime(payload(arrivalTimestamp = arrivalSec))
        assertNotNull(remaining)
        assertEquals(0L, remaining!!.hours)
        assertEquals(15L, remaining.minutes)
        assertEquals("15m", remaining.toCompact())
    }

    @Test
    fun computeRemainingTime_nullWhenArrived() {
        val arrivalSec = 10_000L
        val nowMillis = arrivalSec * 1000
        val builder = builderAt(nowMillis)

        // Arrived via time check
        assertNull(builder.computeRemainingTime(payload(arrivalTimestamp = arrivalSec)))
        // Arrived via Flutter flag
        assertNull(builder.computeRemainingTime(payload(hasArrived = true, arrivalTimestamp = arrivalSec + 100)))
    }

    @Test
    fun computeRemainingTime_nullWhenRemainingIsZero() {
        val arrivalSec = 10_000L
        val nowMillis = arrivalSec * 1000  // exactly at arrival → hasActuallyArrived=true
        val builder = builderAt(nowMillis)
        assertNull(builder.computeRemainingTime(payload(arrivalTimestamp = arrivalSec)))
    }

    @Test
    fun computeRemainingTime_nullWhenNoArrivalTimestamp() {
        val builder = builderAt(5_000_000L)
        assertNull(builder.computeRemainingTime(payload(arrivalTimestamp = null)))
    }

    // ── shouldShowEta ───────────────────────────────────────────────────

    @Test
    fun shouldShowEta_trueWhenEnRoute() {
        val arrivalSec = 10_000L
        val now = (arrivalSec - 100) * 1000
        val builder = builderAt(now)
        assertTrue(builder.shouldShowEta(payload(arrivalTimestamp = arrivalSec)))
    }

    @Test
    fun shouldShowEta_falseWhenArrived() {
        val arrivalSec = 10_000L
        val now = (arrivalSec + 1) * 1000
        val builder = builderAt(now)
        assertFalse(builder.shouldShowEta(payload(arrivalTimestamp = arrivalSec)))
    }

    // ── shouldShowChronometer ───────────────────────────────────────────

    @Test
    fun shouldShowChronometer_trueWhenEnRouteWithValidArrival() {
        val arrivalSec = 10_000L
        val now = (arrivalSec - 100) * 1000
        val builder = builderAt(now)
        assertTrue(builder.shouldShowChronometer(payload(arrivalTimestamp = arrivalSec)))
    }

    @Test
    fun shouldShowChronometer_falseWhenArrived() {
        val arrivalSec = 10_000L
        val now = (arrivalSec + 1) * 1000
        val builder = builderAt(now)
        assertFalse(builder.shouldShowChronometer(payload(arrivalTimestamp = arrivalSec)))
    }

    @Test
    fun shouldShowChronometer_falseWhenNoArrivalTimestamp() {
        val now = 5_000_000L
        val builder = builderAt(now)
        assertFalse(builder.shouldShowChronometer(payload(arrivalTimestamp = null)))
    }
}
