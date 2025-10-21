package com.ck.astrolotto

import android.os.Bundle
import android.widget.Toast
import com.google.android.ump.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var consentInformation: ConsentInformation
    private var consentForm: ConsentForm? = null

    // Channel name must match Flutter side
    private val CHANNEL = "consent_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize UMP consent check once on app start
        initializeConsentFlow()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Optional: still keep this channel if you ever want to call native side manually
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "showConsentForm") {
                    showConsentFormManually()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    // 🔹 Called automatically on app start (matches Flutter auto check)
    private fun initializeConsentFlow() {
        consentInformation = UserMessagingPlatform.getConsentInformation(this)

        val params = ConsentRequestParameters.Builder()
            .setTagForUnderAgeOfConsent(false)
            .build()

        consentInformation.requestConsentInfoUpdate(
            this,
            params,
            {
                // When consent info updated successfully
                if (consentInformation.isConsentFormAvailable) {
                    UserMessagingPlatform.loadAndShowConsentFormIfRequired(this) { formError ->
                        if (formError != null) {
                            Toast.makeText(
                                this,
                                "Consent form error: ${formError.message}",
                                Toast.LENGTH_SHORT
                            ).show()
                        } else {
                            println("✅ Consent handled automatically.")
                        }
                    }
                } else {
                    println("✅ No consent form required right now.")
                }
            },
            { error ->
                Toast.makeText(
                    this,
                    "Consent info update error: ${error.message}",
                    Toast.LENGTH_LONG
                ).show()
            }
        )
    }

    // 🔮 Manual call for “Manage Consent” button (matches Flutter's _showConsentForm)
    private fun showConsentFormManually() {
        println("🌀 User tapped Manage Consent → trying to open form...")
        consentInformation = UserMessagingPlatform.getConsentInformation(this)

        val params = ConsentRequestParameters.Builder()
            .setTagForUnderAgeOfConsent(false)
            .build()

        consentInformation.requestConsentInfoUpdate(
            this,
            params,
            {
                if (consentInformation.isConsentFormAvailable) {
                    UserMessagingPlatform.loadAndShowConsentFormIfRequired(this) { formError ->
                        if (formError != null) {
                            println("❌ Manual consent form error: ${formError.message}")
                            Toast.makeText(
                                this,
                                "Consent form error: ${formError.message}",
                                Toast.LENGTH_SHORT
                            ).show()
                        } else {
                            println("✅ Consent form opened successfully.")
                        }
                    }
                } else {
                    println("ℹ️ Consent form not available (already set).")
                    Toast.makeText(
                        this,
                        "Consent already set — nothing to update.",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            },
            { error ->
                println("❌ Failed to update consent info: ${error.message}")
                Toast.makeText(
                    this,
                    "Consent update failed: ${error.message}",
                    Toast.LENGTH_SHORT
                ).show()
            }
        )
    }
}
