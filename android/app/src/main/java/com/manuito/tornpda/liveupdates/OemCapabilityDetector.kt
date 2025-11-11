package com.manuito.tornpda.liveupdates

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/**
 * Lightweight OEM capability detector. Currently only checks the OnePlus capsule/island surface.
 */
class OemCapabilityDetector(private val context: Context) {

    fun isOnePlusCapsuleAvailable(): Boolean {
        if (!Build.MANUFACTURER.equals("OnePlus", ignoreCase = true)) return false
        return hasPackage(ONEPLUS_CAPSULE_PACKAGE)
    }

    private fun hasPackage(packageName: String): Boolean {
        return try {
            val packageManager = context.packageManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        private const val ONEPLUS_CAPSULE_PACKAGE = "com.oneplus.capsule"
    }
}
