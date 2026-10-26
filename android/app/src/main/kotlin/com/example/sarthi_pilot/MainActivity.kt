package com.example.sarthi_pilot

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), LocationListener {
    private val METHOD_CHANNEL = "com.sarthi.pilot/location"
    private val EVENT_CHANNEL = "com.sarthi.pilot/location_stream"
    private val PERMISSION_REQUEST_CODE = 5001

    private var locationManager: LocationManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var lastLocation: Location? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (hasPermission()) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "checkPermission" -> {
                    result.success(hasPermission())
                }
                "getCurrentLocation" -> {
                    val loc = lastLocation ?: getBestLocation()
                    if (loc != null) {
                        result.success(
                            mapOf(
                                "latitude" to loc.latitude,
                                "longitude" to loc.longitude,
                                "heading" to loc.bearing.toDouble(),
                                "accuracy" to loc.accuracy.toDouble()
                            )
                        )
                    } else {
                        // If no cached location yet, kick off listening and return null
                        if (hasPermission()) {
                            startLocationListening()
                        }
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startLocationListening()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopLocationListening()
                }
            }
        )
    }

    private fun hasPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
        return fine == PackageManager.PERMISSION_GRANTED || coarse == PackageManager.PERMISSION_GRANTED
    }

    private fun startLocationListening() {
        if (!hasPermission()) return

        try {
            val lm = locationManager ?: return

            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )

            for (provider in providers) {
                if (lm.isProviderEnabled(provider)) {
                    lm.requestLocationUpdates(
                        provider,
                        1000L,
                        0.5f,
                        this,
                        Looper.getMainLooper()
                    )
                }
            }

            // Immediately emit best known location if available
            val current = getBestLocation()
            if (current != null) {
                onLocationChanged(current)
            }
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
    }

    private fun stopLocationListening() {
        try {
            locationManager?.removeUpdates(this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getBestLocation(): Location? {
        if (!hasPermission()) return null
        try {
            val lm = locationManager ?: return null
            var bestLoc: Location? = null

            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )

            for (provider in providers) {
                try {
                    val loc = lm.getLastKnownLocation(provider) ?: continue
                    if (bestLoc == null || loc.time > bestLoc.time || loc.accuracy < bestLoc.accuracy) {
                        bestLoc = loc
                    }
                } catch (e: Exception) {
                    // Ignore provider specific errors
                }
            }
            return bestLoc
        } catch (e: SecurityException) {
            return null
        }
    }

    override fun onLocationChanged(location: Location) {
        lastLocation = location
        runOnUiThread {
            eventSink?.success(
                mapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude,
                    "heading" to location.bearing.toDouble(),
                    "accuracy" to location.accuracy.toDouble()
                )
            )
        }
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {
        startLocationListening()
    }
    override fun onProviderDisabled(provider: String) {}

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
            if (granted) {
                startLocationListening()
            }
        }
    }

    override fun onDestroy() {
        stopLocationListening()
        super.onDestroy()
    }
}
