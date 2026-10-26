package com.speedygo.speedygo_driver_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureMatchChannel()
    }

    /** High-importance channel for match-offer pushes (id shared with backend). */
    private fun ensureMatchChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(MATCH_CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                MATCH_CHANNEL_ID,
                "Offres de course",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alertes pour les nouvelles offres de livraison"
            },
        )
    }

    private companion object {
        const val MATCH_CHANNEL_ID = "driver_match_offers"
    }
}
