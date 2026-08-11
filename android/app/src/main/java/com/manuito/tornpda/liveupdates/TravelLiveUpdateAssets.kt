package com.manuito.tornpda.liveupdates

import com.manuito.tornpda.R

object TravelLiveUpdateAssets {

    /**
     * Status-bar icon, and the only glyph an OEM capsule (OnePlus Fluid Cloud) shows
     * next to the ETA. There is no progress bar there to give it context, so this is
     * the one place where direction carries information: outbound vs heading home.
     */
    fun notificationIcon(destinationDisplayName: String?): Int {
        return when (destinationDisplayName?.trim()?.lowercase()) {
            "torn" -> R.drawable.plane_left
            else -> R.drawable.plane_right
        }
    }

    /**
     * Icon for either end of the ProgressStyle bar, from the round "ball" set shared
     * with the iOS Live Activity. [routeCountry] resolves the generic "Abroad" origin
     * the API hands us on the homeward leg back into an actual flag.
     */
    fun flagIconFor(displayName: String?, routeCountry: String? = null): Int {
        val normalized = displayName?.trim()?.lowercase()
        if (normalized == "abroad" && routeCountry != null) {
            val resolved = ballFor(routeCountry.trim().lowercase())
            if (resolved != null) return resolved
        }
        return when (normalized) {
            "torn" -> R.drawable.ball_torn
            "hospital" -> R.drawable.hospital
            else -> ballFor(normalized) ?: R.drawable.ball_world
        }
    }

    private fun ballFor(normalized: String?): Int? {
        return when (normalized) {
            "argentina" -> R.drawable.ball_argentina
            "canada" -> R.drawable.ball_canada
            "cayman islands", "cayman", "cayman island" -> R.drawable.ball_cayman
            "china" -> R.drawable.ball_china
            "hawaii" -> R.drawable.ball_hawaii
            "japan" -> R.drawable.ball_japan
            "mexico" -> R.drawable.ball_mexico
            "south africa" -> R.drawable.ball_south_africa
            "switzerland" -> R.drawable.ball_switzerland
            "uae", "united arab emirates" -> R.drawable.ball_uae
            "united kingdom", "uk" -> R.drawable.ball_uk
            else -> null
        }
    }

    /**
     * Icon riding the bar. The bar fills left-to-right regardless of travel direction,
     * so the plane never mirrors; a flipped plane would fly against its own motion.
     */
    fun trackerIconFor(): Int = R.drawable.plane_right
}
