package com.manuito.tornpda.liveupdates

data class RacingLiveUpdateState(
    val phase: String,
    val titleText: String,
    val bodyText: String,
    val stateIdentifier: String,
    val targetTimestamp: Long? = null,
) {
    val hasTimer: Boolean
        get() = targetTimestamp != null && !phase.equals("finished", ignoreCase = true)
}

object RacingLiveUpdateParser {
    private val durationRegex = Regex(
        pattern = "(\\d+)\\s+(day|days|hour|hours|minute|minutes|second|seconds)",
        option = RegexOption.IGNORE_CASE,
    )

    fun parse(icon17: String?, icon18: String?, baseTimestamp: Long): RacingLiveUpdateState? {
        val normalizedIcon17 = icon17?.trim()
        val normalizedIcon18 = icon18?.trim()

        if (!normalizedIcon17.isNullOrEmpty()) {
            if (normalizedIcon17.contains("Currently racing", ignoreCase = true)) {
                val detail = stripRacingPrefix(normalizedIcon17)
                val remainingSeconds = parseRelativeSeconds(detail)
                val targetTimestamp = remainingSeconds?.let { baseTimestamp + it }
                return RacingLiveUpdateState(
                    phase = "racing",
                    titleText = "Currently racing",
                    bodyText = detail,
                    stateIdentifier = targetTimestamp?.let { "racing-${bucketize(it)}" } ?: "racing-unknown",
                    targetTimestamp = targetTimestamp,
                )
            }

            if (normalizedIcon17.contains("Waiting for a race to start", ignoreCase = true)) {
                val detail = stripRacingPrefix(normalizedIcon17)
                val remainingSeconds = parseRelativeSeconds(detail)
                if (remainingSeconds != null) {
                    val targetTimestamp = baseTimestamp + remainingSeconds
                    return RacingLiveUpdateState(
                        phase = "waiting",
                        titleText = "Waiting to race",
                        bodyText = detail,
                        stateIdentifier = "waiting-${bucketize(targetTimestamp)}",
                        targetTimestamp = targetTimestamp,
                    )
                }

                return RacingLiveUpdateState(
                    phase = "waitingUnknown",
                    titleText = "Waiting to race",
                    bodyText = "Start time pending",
                    stateIdentifier = "waiting-unknown",
                )
            }
        }

        if (!normalizedIcon18.isNullOrEmpty()) {
            val detail = stripRacingPrefix(normalizedIcon18)
            return RacingLiveUpdateState(
                phase = "finished",
                titleText = "Race finished",
                bodyText = detail,
                stateIdentifier = "finished-${sanitizeIdentifier(detail)}",
            )
        }

        return null
    }

    private fun parseRelativeSeconds(input: String): Long? {
        var totalSeconds = 0L
        var foundAny = false

        durationRegex.findAll(input).forEach { match ->
            val value = match.groupValues.getOrNull(1)?.toLongOrNull() ?: 0L
            val unit = match.groupValues.getOrNull(2)?.lowercase().orEmpty()
            foundAny = true

            totalSeconds += when {
                unit.startsWith("day") -> value * 24 * 60 * 60
                unit.startsWith("hour") -> value * 60 * 60
                unit.startsWith("minute") -> value * 60
                unit.startsWith("second") -> value
                else -> 0L
            }
        }

        return if (foundAny) totalSeconds else null
    }

    private fun stripRacingPrefix(input: String): String {
        return input.replace(Regex("^Racing\\s*-\\s*", RegexOption.IGNORE_CASE), "").trim()
    }

    /** Rounds to nearest 120s bucket so small API drift doesn't change the identifier. */
    private fun bucketize(timestamp: Long): Long = (timestamp / 120) * 120

    private fun sanitizeIdentifier(input: String): String {
        val sanitized = input.lowercase()
            .replace(Regex("[^a-z0-9]+"), "-")
            .replace(Regex("-+"), "-")
            .replace(Regex("(^-|-$)"), "")
        return if (sanitized.length <= 80) sanitized else sanitized.substring(0, 80)
    }
}