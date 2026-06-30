package com.manuito.tornpda.liveupdates

import com.manuito.tornpda.R

object TravelLiveUpdateAssets {

    fun flagIconFor(displayName: String?): Int {
        return when (displayName?.trim()?.lowercase()) {
            "torn" -> R.drawable.action_torn
            "abroad" -> R.drawable.action_travel
            "hospital" -> R.drawable.hospital
            "argentina" -> R.drawable.flag_argentina
            "canada" -> R.drawable.flag_canada
            "cayman islands", "cayman", "cayman island" -> R.drawable.flag_cayman
            "china" -> R.drawable.flag_china
            "hawaii" -> R.drawable.flag_hawaii
            "japan" -> R.drawable.flag_japan
            "mexico" -> R.drawable.flag_mexico
            "south africa" -> R.drawable.flag_south_africa
            "switzerland" -> R.drawable.flag_switzerland
            "uae", "united arab emirates" -> R.drawable.flag_uae
            "united kingdom", "uk" -> R.drawable.flag_uk
            else -> R.drawable.plane_right
        }
    }

    fun trackerIconFor(destinationDisplayName: String?): Int {
        return when (destinationDisplayName?.trim()?.lowercase()) {
            "torn" -> R.drawable.plane_left
            else -> R.drawable.plane_right
        }
    }
}
