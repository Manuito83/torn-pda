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
        assertNotEquals("unknown endpoints must not render as a plane", TravelLiveUpdateAssets.trackerIconFor(), unknown)
    }

    @Test
    fun contextualOriginsDoNotRenderAsTrackerPlane() {
        assertNotEquals(
            TravelLiveUpdateAssets.trackerIconFor(),
            TravelLiveUpdateAssets.flagIconFor("Abroad"),
        )
        assertNotEquals(
            TravelLiveUpdateAssets.trackerIconFor(),
            TravelLiveUpdateAssets.flagIconFor("Hospital"),
        )
        assertNotEquals(
            TravelLiveUpdateAssets.trackerIconFor(),
            TravelLiveUpdateAssets.flagIconFor("Torn"),
        )
    }

    @Test
    fun abroadOriginResolvesToTheRouteCountryFlag() {
        assertEquals(
            "the homeward leg must show the country it departed from",
            TravelLiveUpdateAssets.flagIconFor("Switzerland"),
            TravelLiveUpdateAssets.flagIconFor("Abroad", routeCountry = "Switzerland"),
        )
        assertEquals(
            TravelLiveUpdateAssets.flagIconFor("Cayman Islands"),
            TravelLiveUpdateAssets.flagIconFor("Abroad", routeCountry = "  cayman islands  "),
        )
    }

    @Test
    fun abroadFallsBackToTheGlobeWhenRouteCountryIsUselessOrAbsent() {
        val globe = TravelLiveUpdateAssets.flagIconFor("Abroad")
        assertEquals(globe, TravelLiveUpdateAssets.flagIconFor("Abroad", routeCountry = null))
        assertEquals(globe, TravelLiveUpdateAssets.flagIconFor("Abroad", routeCountry = "Atlantis"))
        // Torn is never a valid foreign origin, so it must not leak in as a ball_torn origin
        assertEquals(globe, TravelLiveUpdateAssets.flagIconFor("Abroad", routeCountry = "Torn"))
    }

    @Test
    fun routeCountryOnlyOverridesTheGenericAbroadOrigin() {
        assertEquals(
            "a named origin must ignore routeCountry",
            TravelLiveUpdateAssets.flagIconFor("Japan"),
            TravelLiveUpdateAssets.flagIconFor("Japan", routeCountry = "Mexico"),
        )
        assertEquals(
            TravelLiveUpdateAssets.flagIconFor("Hospital"),
            TravelLiveUpdateAssets.flagIconFor("Hospital", routeCountry = "Mexico"),
        )
    }

    @Test
    fun notificationIconFlipsForHomewardTrip() {
        assertNotEquals(
            TravelLiveUpdateAssets.notificationIcon("Mexico"),
            TravelLiveUpdateAssets.notificationIcon("Torn"),
        )
        assertEquals(
            TravelLiveUpdateAssets.notificationIcon("Torn"),
            TravelLiveUpdateAssets.notificationIcon("  torn  "),
        )
        // Outbound shares the tracker's right-facing plane; only the capsule flips
        assertEquals(
            TravelLiveUpdateAssets.trackerIconFor(),
            TravelLiveUpdateAssets.notificationIcon("Mexico"),
        )
    }
}
