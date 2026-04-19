package com.manuito.tornpda.liveupdates

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class TravelLiveUpdateAssetsTest {

    @Test
    fun flagIconForKnownDestinationsReturnsDistinctDrawables() {
        val destinations = listOf(
            "Argentina", "Canada", "Cayman Islands", "China", "Hawaii",
            "Japan", "Mexico", "South Africa", "Switzerland", "UAE", "United Kingdom", "Torn",
        )
        val icons = destinations.map { TravelLiveUpdateAssets.flagIconFor(it) }.toSet()
        assertEquals("each known destination maps to a unique drawable", destinations.size, icons.size)
    }

    @Test
    fun flagIconForHandlesCaseAndWhitespace() {
        assertEquals(
            TravelLiveUpdateAssets.flagIconFor("Mexico"),
            TravelLiveUpdateAssets.flagIconFor("  mexico  "),
        )
    }

    @Test
    fun flagIconForUnknownFallsBackToDefault() {
        val unknown = TravelLiveUpdateAssets.flagIconFor("Atlantis")
        val mexico = TravelLiveUpdateAssets.flagIconFor("Mexico")
        assertNotEquals(mexico, unknown)
    }

    @Test
    fun trackerIconFlipsForHomewardTrip() {
        assertNotEquals(
            TravelLiveUpdateAssets.trackerIconFor("Mexico"),
            TravelLiveUpdateAssets.trackerIconFor("Torn"),
        )
    }
}
