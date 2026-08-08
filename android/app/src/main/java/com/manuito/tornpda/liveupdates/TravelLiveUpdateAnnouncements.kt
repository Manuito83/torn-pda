package com.manuito.tornpda.liveupdates

/**
 * Cabin announcements for the travel card, chosen from how far along the flight is
 */
object TravelLiveUpdateAnnouncements {

    private const val TORN = "Torn"
    private const val HOSPITAL = "Hospital"

    fun announcementFor(
        destination: String?,
        origin: String?,
        routeCountry: String?,
        departureTimestamp: Long?,
        arrivalTimestamp: Long?,
        travelIdentifier: String?,
        nowSeconds: Long,
    ): String? {
        if (departureTimestamp == null || arrivalTimestamp == null) return null
        val total = arrivalTimestamp - departureTimestamp
        if (total <= 0L) return null

        val goingHome = destination?.trim().equals(TORN, ignoreCase = true)
        if (goingHome && origin?.trim().equals(HOSPITAL, ignoreCase = true)) {
            return pick(REPATRIATION, travelIdentifier, 0)
        }

        // The travel API says "UAE", not the full name
        val country = (if (goingHome) routeCountry else destination)?.trim()?.lowercase()
            ?.let { if (it == "uae") "united arab emirates" else it }
        val route = ROUTES[country]
        val segments = when {
            route != null -> if (goingHome) route.homeSegments() else route.outboundSegments()
            goingHome -> GENERIC_HOME
            else -> return null
        }
        val elapsed = (nowSeconds - departureTimestamp).coerceIn(0L, total)
        val index = ((elapsed * segments.size) / total).toInt().coerceIn(0, segments.size - 1)
        return pick(segments[index], travelIdentifier, index)
    }

    /** Stable per trip and segment, so a repaint never reshuffles the wording. */
    private fun pick(variants: List<String>, travelIdentifier: String?, index: Int): String? {
        if (variants.isEmpty()) return null
        val seed = ("${travelIdentifier.orEmpty()}:$index".hashCode().toLong() and 0x7FFFFFFFL).toInt()
        return variants[seed % variants.size]
    }

    private class Route(
        val departure: List<String>,
        val cruise: List<List<String>>,
        val arrival: List<String>,
        val homeDeparture: List<String>,
        val homeCruise: List<List<String>>,
    ) {
        fun outboundSegments(): List<List<String>> = buildList {
            add(departure)
            addAll(cruise)
            add(arrival)
        }

        fun homeSegments(): List<List<String>> = buildList {
            add(homeDeparture)
            addAll(homeCruise)
            add(HOME_ARRIVAL)
        }
    }

    /** Arriving at Torn reads the same whichever country you left */
    private val HOME_ARRIVAL = listOf(
        "Torn ahead. Starting our descent.",
        "Beginning our approach into Torn.",
        "Torn in sight. Welcome back, watch yourselves.",
        "Last stretch. Torn lights on the horizon.",
        "Descent into Torn. You know the drill down there.",
        "Torn traffic on the radio. Nearly home.",
    )

    private val REPATRIATION = listOf(
        "Medical flight to Torn. Try to rest.",
        "Heading home. The doctors say you will live.",
        "Lie still. We have you on the way back to Torn.",
    )

    /** For flights home when we never learned where they started */
    private val GENERIC_HOME: List<List<String>> = listOf(
        listOf(
            "Wheels up. Heading home.",
            "Climbing out. Torn at the end of this one.",
            "Up and pointed at Torn. Settle in.",
            "Homeward. Belts on for a while.",
        ),
        listOf(
            "Cruising. Nothing to report from up here.",
            "Somewhere over the middle of it. All quiet.",
            "Long stretch. Torn at the far end.",
            "Quiet up here. Enjoy it while it lasts.",
        ),
        HOME_ARRIVAL,
    )

    private val ROUTES: Map<String, Route> = mapOf(
        "mexico" to Route(
            departure = listOf(
                "Wheels up. Texas for the whole of this one.",
                "Climbing out west. Short hop today.",
                "Up and turning west. Belts stay on, it is quick.",
            ),
            cruise = listOf(
                listOf(
                    "West Texas below. Dry, flat and mostly empty.",
                    "Pecos country down there. Not a lot to report.",
                    "Scrubland the whole way. Enjoy the quiet.",
                ),
            ),
            arrival = listOf(
                "Desert ahead, then the river. Starting down.",
                "Border coming up. Beginning our descent.",
                "Juarez in sight. Mind the heat on the steps.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Juarez. Heading east.",
                "Climbing out over the desert. Short one home.",
                "Up and turning for home. Belts stay on.",
                "Juarez behind us. Torn across the desert.",
            ),
            homeCruise = listOf(
                listOf(
                    "West Texas below again. Still dry, still empty.",
                    "Pecos country down there. Torn before long.",
                    "Scrubland below. Nearly home already.",
                    "Same desert as on the way out. Quick one.",
                ),
            ),
        ),

        "cayman islands" to Route(
            departure = listOf(
                "Wheels up, turning southeast over the Gulf.",
                "Climbing out. Open water for most of this one.",
                "Up and out over the Gulf. Short flight today.",
            ),
            cruise = listOf(
                listOf(
                    "Yucatan channel below. Cuba off to the left.",
                    "Blue water and the odd boat. Very quiet radio.",
                    "Passing Cuba. We have been asked not to linger.",
                ),
            ),
            arrival = listOf(
                "Reef below, so we are close. Starting down.",
                "Grand Cayman ahead. Beginning our descent.",
                "Coming down over the water. Belts on, please.",
            ),
            homeDeparture = listOf(
                "Wheels up out of George Town. Turning north.",
                "Climbing out over the reef. Home in a moment.",
                "Up and heading north. Short hop back.",
                "George Town behind us. The Gulf, then home.",
            ),
            homeCruise = listOf(
                listOf(
                    "Yucatan channel below. Cuba off to the right this time.",
                    "Back over the Gulf. Blue water and the odd boat.",
                    "Passing Cuba again. Still not lingering.",
                    "Open water below. Torn within the hour.",
                ),
            ),
        ),

        "canada" to Route(
            departure = listOf(
                "Wheels up, turning northeast. Short one today.",
                "Climbing out. It gets colder from here.",
                "Up and heading north. Belts on for a while.",
            ),
            cruise = listOf(
                listOf(
                    "Ohio valley below. Farmland as far as it goes.",
                    "Rivers and fields down there. Nothing to report.",
                    "Cutting northeast. Cloud building up ahead.",
                ),
            ),
            arrival = listOf(
                "Lake Erie below. Toronto just past it.",
                "Starting down over the lake. Coats ready.",
                "Toronto ahead. Beginning our descent.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Toronto. Turning south.",
                "Climbing out over the lake. Warmer where we are going.",
                "Up and heading south. Short one home.",
                "Toronto behind us. Torn by dinner.",
            ),
            homeCruise = listOf(
                listOf(
                    "Ohio valley below, southbound this time.",
                    "Fields and rivers down there. Warmer every mile.",
                    "Cutting southwest across the farmland.",
                    "Same square fields, other direction. Quiet flight.",
                ),
            ),
        ),

        "hawaii" to Route(
            departure = listOf(
                "Wheels up, turning west. Long one over water.",
                "Climbing out. Two hours of Pacific ahead.",
                "Up and heading west. Get comfortable.",
            ),
            cruise = listOf(
                listOf(
                    "Northern Mexico below. Desert most of the way.",
                    "Dry country down there, and getting drier.",
                    "Crossing the sierra. Last of the land coming up.",
                ),
                listOf(
                    "That is the coast gone. Pacific from here.",
                    "Baja behind us. Nothing but water now.",
                    "Out over the ocean. Long stretch ahead.",
                ),
                listOf(
                    "Middle of the Pacific. Nearest land is below us.",
                    "Nothing on the radar for a thousand miles.",
                    "Open ocean all round. Very quiet up here.",
                ),
            ),
            arrival = listOf(
                "Islands ahead. Starting our descent.",
                "Honolulu in sight. Belts on, please.",
                "Coming down over the water. Mind the humidity.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Honolulu. Turning east.",
                "Climbing out over the water. Long one home.",
                "Up and heading east. Settle in.",
                "Honolulu behind us. Ocean, then more ocean.",
            ),
            homeCruise = listOf(
                listOf(
                    "Middle of the Pacific. Torn a long way ahead.",
                    "Open ocean all round. Settle in, this takes a while.",
                    "Nothing on the radar for a thousand miles. Again.",
                    "Islands long gone. Water until further notice.",
                ),
                listOf(
                    "Mainland coast ahead. First land in a while.",
                    "Baja coming up. The water ends eventually.",
                    "Coast on the radar at last. Nearly over the water.",
                    "Land ahead. You can stop counting waves.",
                ),
                listOf(
                    "Over the sierra now. Desert the rest of the way.",
                    "Dry country below. Torn on the other side of it.",
                    "Crossing northern Mexico. Not far now.",
                    "Mountains behind us, scrubland ahead. Almost there.",
                ),
            ),
        ),

        "united kingdom" to Route(
            departure = listOf(
                "Wheels up, turning northeast. Long one today.",
                "Climbing out. Atlantic crossing ahead.",
                "Up and heading northeast. Make yourselves comfortable.",
            ),
            cruise = listOf(
                listOf(
                    "Midwest below. Straight roads and square fields.",
                    "Farmland the whole way. Nothing to report.",
                    "Cutting northeast across the plains.",
                ),
                listOf(
                    "Newfoundland coming up. Last land for a while.",
                    "Cold country below. Coast approaching.",
                    "Quebec behind us. Water ahead.",
                ),
                listOf(
                    "Open Atlantic. Three miles of cold water below.",
                    "Halfway across. Nothing on the radar.",
                    "Middle of the ocean, middle of the flight.",
                ),
            ),
            arrival = listOf(
                "Ireland off the left. England ahead.",
                "Crossed the coast. Starting our descent.",
                "London ahead. Belts on, and bring a coat.",
            ),
            homeDeparture = listOf(
                "Wheels up out of London. Turning west.",
                "Climbing out. The Atlantic again, the long way.",
                "Up and heading west. Long one home.",
                "London behind us. Ocean for most of this one.",
            ),
            homeCruise = listOf(
                listOf(
                    "Out over the Atlantic. The long way back.",
                    "Ireland behind us. Ocean for a good while.",
                    "Open Atlantic below. Westbound and slow.",
                    "Cold water for the next stretch. Get comfortable.",
                ),
                listOf(
                    "Newfoundland ahead. First land since Ireland.",
                    "Canadian coast coming up. Ocean nearly done.",
                    "Landfall over Newfoundland. Cold down there.",
                    "Quebec ahead. Back over solid ground soon.",
                ),
                listOf(
                    "Midwest below. Square fields mean nearly home.",
                    "Cutting southwest across the plains.",
                    "Farmland down there again. Torn before long.",
                    "Straight roads below. The last stretch.",
                ),
            ),
        ),

        "argentina" to Route(
            departure = listOf(
                "Wheels up, turning southeast over the Gulf.",
                "Climbing out. Long one south today.",
                "Up and heading south. Settle in.",
            ),
            cruise = listOf(
                listOf(
                    "Caribbean below. Islands scattered to the left.",
                    "Blue water and small islands. Quiet down there.",
                    "Crossing the Caribbean. Venezuela coming up.",
                ),
                listOf(
                    "That green carpet below is the Amazon.",
                    "Rainforest as far as you can see. It goes on.",
                    "River country down there, cloud building over it.",
                ),
                listOf(
                    "Central Brazil below. The green is thinning out.",
                    "Highlands down there. Long way from anywhere.",
                    "Past the forest now. Open country ahead.",
                ),
            ),
            arrival = listOf(
                "Pampas below. Buenos Aires just ahead.",
                "Starting our descent over the plains.",
                "Buenos Aires in sight. Belts on, please.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Buenos Aires. Turning north.",
                "Climbing out over the pampas. Long one home.",
                "Up and heading north. Get comfortable.",
                "Buenos Aires behind us. Half a continent to go.",
            ),
            homeCruise = listOf(
                listOf(
                    "Pampas behind us. Brazil ahead.",
                    "Central Brazil below. Greener by the mile.",
                    "Highlands down there. Long way still to go.",
                    "Northbound over open country. Settle in.",
                ),
                listOf(
                    "The Amazon again. Still green, still endless.",
                    "Rainforest below for the next while.",
                    "River country down there. Cloud over most of it.",
                    "That carpet below is the Amazon. Halfway soon.",
                ),
                listOf(
                    "Caribbean below. Islands off to the right now.",
                    "Blue water again. The Gulf is next.",
                    "Crossing the Caribbean, northbound this time.",
                    "Venezuela behind us. Torn across the water.",
                ),
            ),
        ),

        "switzerland" to Route(
            departure = listOf(
                "Wheels up, turning northeast. Long one today.",
                "Climbing out. Atlantic crossing ahead.",
                "Up and heading northeast. Settle in.",
            ),
            cruise = listOf(
                listOf(
                    "Midwest below. Fields out to the horizon.",
                    "Straight roads and square farms. Nothing to report.",
                    "Cutting northeast across the plains.",
                ),
                listOf(
                    "Newfoundland coming up. Last land for a while.",
                    "Cold country below. Coast approaching.",
                    "Quebec behind us. Water ahead.",
                ),
                listOf(
                    "Open Atlantic. Three miles of cold water below.",
                    "Halfway across. Iceland somewhere off the left.",
                    "Middle of the ocean. Very quiet up here.",
                ),
            ),
            arrival = listOf(
                "Crossed the coast. France below, Alps ahead.",
                "Those white peaks on the right are the Alps.",
                "Starting down over the mountains. Belts on.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Zurich. Turning west.",
                "Climbing out over the Alps. Long one home.",
                "Up and heading west. The Atlantic again.",
                "Zurich behind us. France, then the ocean.",
            ),
            homeCruise = listOf(
                listOf(
                    "France behind us. Atlantic ahead, all of it.",
                    "Out over the ocean. Westbound for hours.",
                    "Open Atlantic below. Iceland somewhere north.",
                    "Cold water from here. Get comfortable.",
                ),
                listOf(
                    "Newfoundland ahead. The ocean is nearly done.",
                    "Canadian coast coming up at last.",
                    "Landfall soon. Cold country first, then home.",
                    "Quebec ahead. Solid ground the rest of the way.",
                ),
                listOf(
                    "Plains below. Straight roads pointing home.",
                    "Midwest down there. Torn before long.",
                    "Farmland to the horizon. The last stretch.",
                    "Cutting southwest across the fields.",
                ),
            ),
        ),

        "japan" to Route(
            departure = listOf(
                "Wheels up, turning northwest. Long one today.",
                "Climbing out. We will be chasing the sun west.",
                "Up and heading northwest. Get comfortable.",
            ),
            cruise = listOf(
                listOf(
                    "Rockies below. Snow on them most of the year.",
                    "Mountains down there, and not much else.",
                    "Crossing the ranges. It gets emptier from here.",
                ),
                listOf(
                    "Coast behind us. Gulf of Alaska below.",
                    "Cold water down there. Aleutians coming up.",
                    "Turning out over the north Pacific.",
                ),
                listOf(
                    "North Pacific. Nothing on the radar for hours.",
                    "Open ocean and a very quiet radio.",
                    "Chasing the sun west, and losing.",
                ),
            ),
            arrival = listOf(
                "Japanese coast ahead. Starting our descent.",
                "Tokyo in sight. It is tomorrow down there.",
                "Coming down over the bay. Belts on, please.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Tokyo. Turning east.",
                "Climbing out over the bay. Long one home.",
                "Up and heading east. We get the day back.",
                "Tokyo behind us. The Pacific, the wide way.",
            ),
            homeCruise = listOf(
                listOf(
                    "North Pacific below. Eastbound and patient.",
                    "Open ocean for hours yet. Try the nap.",
                    "The sun is chasing us this time.",
                    "Nothing on the radar. Aleutians somewhere ahead.",
                ),
                listOf(
                    "Gulf of Alaska below. Coast coming up.",
                    "Mainland ahead. First land since Japan.",
                    "Cold water nearly done. Mountains next.",
                    "Aleutians behind us. Landfall ahead.",
                ),
                listOf(
                    "Rockies below. Home on the far side.",
                    "Mountains down there, then it flattens out.",
                    "Crossing the ranges. Torn before long.",
                    "Snow on the peaks below. Warmer ahead.",
                ),
            ),
        ),

        "china" to Route(
            departure = listOf(
                "Wheels up, turning north. One of the long ones.",
                "Climbing out. Polar route today.",
                "Up and heading north. Settle in properly.",
            ),
            cruise = listOf(
                listOf(
                    "Great Plains below. Straight lines to the horizon.",
                    "Farmland and grain silos. Nothing to report.",
                    "Cutting north across the plains.",
                ),
                listOf(
                    "Canadian Rockies below. Emptier from here on.",
                    "Mountains and forest. Last towns for a while.",
                    "Crossing the ranges. Cold country ahead.",
                ),
                listOf(
                    "Over the ice now. Nothing down there but white.",
                    "Arctic below. No airports, no lights, nothing.",
                    "Polar cap. The compass gets confused up here.",
                ),
                listOf(
                    "Siberia for the next hour. Try to sleep.",
                    "Forest and frozen river. Very few lights.",
                    "Crossing Russia. Long way from anywhere.",
                ),
            ),
            arrival = listOf(
                "Mongolia behind us. Starting our descent.",
                "Beijing ahead. Belts on, please.",
                "Coming down through the haze. Nearly there.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Beijing. Turning north.",
                "Climbing out. The long way home over the ice.",
                "Up and heading north. Get comfortable.",
                "Beijing behind us. Over the ice, then home.",
            ),
            homeCruise = listOf(
                listOf(
                    "Siberia below again. Still very few lights.",
                    "Crossing Russia northbound. Long way to go.",
                    "Frozen rivers down there. The ice is next.",
                    "Forest and snow below. Settle in.",
                ),
                listOf(
                    "Over the pole. White in every direction.",
                    "Arctic below. The compass is guessing again.",
                    "Ice from horizon to horizon. Halfway home.",
                    "No lights down there. None expected.",
                ),
                listOf(
                    "Canadian Rockies below. Back over the map.",
                    "Mountains and forest again. Towns soon.",
                    "Crossing the ranges southbound. Warmer ahead.",
                    "First towns in hours off the nose.",
                ),
                listOf(
                    "Great Plains below. Straight lines mean home.",
                    "Grain country down there. Torn before long.",
                    "Cutting south across the plains.",
                    "Farmland to the horizon. The last stretch.",
                ),
            ),
        ),

        "united arab emirates" to Route(
            departure = listOf(
                "Wheels up, turning northeast. Very long one.",
                "Climbing out. Half the world to cross today.",
                "Up and heading northeast. Settle in properly.",
            ),
            cruise = listOf(
                listOf(
                    "Great Lakes below. Water in every direction.",
                    "Cutting northeast. Cold country coming up.",
                    "Lakes and forest down there. Nothing to report.",
                ),
                listOf(
                    "Greenland below. Ice from coast to coast.",
                    "Labrador behind us. White down there, all of it.",
                    "Crossing the ice. No lights for a long while.",
                ),
                listOf(
                    "Scandinavia below. Forest and frozen lakes.",
                    "Crossing Russia now. Very few lights down there.",
                    "North of everything. Long stretch ahead.",
                ),
                listOf(
                    "Caspian off to the left. Mountains ahead.",
                    "Crossing Iran. Dry country from here on.",
                    "Desert below, and hotter by the mile.",
                ),
            ),
            arrival = listOf(
                "The Gulf ahead. Starting our descent.",
                "Dubai in sight. Those lights cost more than this plane.",
                "Coming down over the sand. Belts on, please.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Dubai. Turning northwest.",
                "Climbing out over the sand. Very long one home.",
                "Up and heading home. The long way round.",
                "Dubai behind us. Most of a planet to cross.",
            ),
            homeCruise = listOf(
                listOf(
                    "Desert behind us. Mountains ahead.",
                    "Crossing Iran, northbound. Cooler by the mile.",
                    "Caspian off to the right this time.",
                    "Dry country below. It greens up ahead.",
                ),
                listOf(
                    "Crossing Russia. Very few lights, as ever.",
                    "Scandinavia ahead. Forest and frozen lakes.",
                    "North of everything again. Long stretch.",
                    "Snow country below. Greenland is next.",
                ),
                listOf(
                    "Greenland below. Ice from one coast to the other.",
                    "Crossing the ice cap. Labrador ahead.",
                    "White down there, all of it. Again.",
                    "No lights below. Canada coming up.",
                ),
                listOf(
                    "Great Lakes below. Nearly back on the map.",
                    "Lakes and forest down there. Torn before long.",
                    "Cutting southwest. Warmer every mile.",
                    "Water in every direction, the last of the cold.",
                ),
            ),
        ),

        "south africa" to Route(
            departure = listOf(
                "Wheels up, turning southeast. One of the long ones.",
                "Climbing out over the Gulf. Africa tonight.",
                "Up and heading southeast. Settle in properly.",
            ),
            cruise = listOf(
                listOf(
                    "Caribbean below. Islands off to the right.",
                    "Blue water and small islands. Quiet down there.",
                    "Crossing the Caribbean. Ocean ahead.",
                ),
                listOf(
                    "Crossing the equator. No bump, sorry.",
                    "Open Atlantic. Nothing on the radar at all.",
                    "Middle of the ocean. Very quiet up here.",
                ),
                listOf(
                    "African coast ahead. Land at last.",
                    "Crossed the coast. Green country below.",
                    "West Africa below, cloud building over it.",
                ),
                listOf(
                    "Congo basin below. Green and unbroken.",
                    "Crossing Zambia. Storms off to the left.",
                    "Long way from anywhere down there.",
                ),
            ),
            arrival = listOf(
                "Highveld ahead. Starting our descent.",
                "Johannesburg in sight. Belts on, please.",
                "Coming down onto the plateau. Nearly there.",
            ),
            homeDeparture = listOf(
                "Wheels up out of Johannesburg. Turning northwest.",
                "Climbing out over the veld. Longest one home.",
                "Up and heading northwest. Get comfortable.",
                "Johannesburg behind us. Africa first, then the sea.",
            ),
            homeCruise = listOf(
                listOf(
                    "Highveld behind us. The Congo basin ahead.",
                    "Crossing Zambia. Storms off to the right now.",
                    "Green and unbroken below. Long way to go.",
                    "Africa below for a while yet. Settle in.",
                ),
                listOf(
                    "West African coast ahead. Then the ocean.",
                    "Leaving the continent behind. Water next.",
                    "Coast below. Last land for a long while.",
                    "Green country below, ocean on the nose.",
                ),
                listOf(
                    "Crossing the equator again. Still no bump.",
                    "Open Atlantic. Radar empty in every direction.",
                    "Middle of the ocean. Halfway home, roughly.",
                    "Blue below, blue above. Quiet up here.",
                ),
                listOf(
                    "Caribbean below. Islands off to the left now.",
                    "Blue water and small boats. The Gulf is next.",
                    "Crossing the Caribbean, homeward this time.",
                    "Islands down there. Torn across the Gulf.",
                ),
            ),
        ),
    )
}
