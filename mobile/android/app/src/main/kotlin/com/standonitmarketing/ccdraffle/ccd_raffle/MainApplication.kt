package com.standonitmarketing.ccdraffle.ccd_raffle

import android.app.Application
import com.squareup.sdk.mobilepayments.MobilePaymentsSdk

// Sandbox application ID for "CCD Raffle Mobile App" — see docs/credentials.local.md.
// Swap for the production Application ID before any real-money release.
private const val SQUARE_APPLICATION_ID = "sandbox-sq0idb-YAjXgGPlVms4aXz3ptLiTg"

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobilePaymentsSdk.initialize(SQUARE_APPLICATION_ID, this)
    }
}
