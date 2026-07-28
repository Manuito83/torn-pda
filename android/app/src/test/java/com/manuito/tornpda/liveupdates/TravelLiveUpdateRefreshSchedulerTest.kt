package com.manuito.tornpda.liveupdates

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TravelLiveUpdateRefreshSchedulerTest {

    private val threeMinutes = 3 * 60L
    private val fifteenMinutes = 15 * 60L

    @Test
    fun freshArrivalPollsFast() {
        assertEquals(threeMinutes, TravelLiveUpdateRefreshScheduler.abroadPollDelaySeconds(0))
        assertEquals(threeMinutes, TravelLiveUpdateRefreshScheduler.abroadPollDelaySeconds(59 * 60))
    }

    @Test
    fun backsOffAfterTheFirstHour() {
        assertEquals(fifteenMinutes, TravelLiveUpdateRefreshScheduler.abroadPollDelaySeconds(60 * 60))
        assertEquals(fifteenMinutes, TravelLiveUpdateRefreshScheduler.abroadPollDelaySeconds(11 * 60 * 60))
    }

    @Test
    fun givesUpOnPeopleParkedAbroad() {
        assertNull(TravelLiveUpdateRefreshScheduler.abroadPollDelaySeconds(12 * 60 * 60))
        assertNull(TravelLiveUpdateRefreshScheduler.abroadPollDelaySeconds(48 * 60 * 60))
    }
}
