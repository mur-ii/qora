package com.example.qora

import android.app.ActivityManager
import android.content.Context
import android.os.Process
import android.os.SystemClock
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "qora/performance_metrics"

	private var lastCpuTimeMs: Long? = null
	private var lastWallTimeMs: Long? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				if (call.method == "getSystemMetrics") {
					result.success(getSystemMetrics())
				} else {
					result.notImplemented()
				}
			}
	}

	private fun getSystemMetrics(): Map<String, Any?> {
		return mapOf(
			"cpuPercent" to readCpuPercent(),
			"memoryMb" to readAppMemoryMb(),
		)
	}

	private fun readCpuPercent(): Double? {
		return try {
			val currentCpuTimeMs = Process.getElapsedCpuTime()
			val currentWallTimeMs = SystemClock.elapsedRealtime()

			val previousCpuTimeMs = lastCpuTimeMs
			val previousWallTimeMs = lastWallTimeMs

			lastCpuTimeMs = currentCpuTimeMs
			lastWallTimeMs = currentWallTimeMs

			if (previousCpuTimeMs == null || previousWallTimeMs == null) {
				return null
			}

			val cpuDelta = (currentCpuTimeMs - previousCpuTimeMs).toDouble()
			val wallDelta = (currentWallTimeMs - previousWallTimeMs).toDouble()

			if (wallDelta <= 0) {
				return null
			}

			val coreCount = Runtime.getRuntime().availableProcessors().coerceAtLeast(1)
			val normalized = (cpuDelta / (wallDelta * coreCount)) * 100.0
			normalized.coerceIn(0.0, 100.0)
		} catch (_: Throwable) {
			null
		}
	}

	private fun readAppMemoryMb(): Double? {
		return try {
			val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
			val pid = Process.myPid()
			val processMemoryInfo = activityManager.getProcessMemoryInfo(intArrayOf(pid))

			if (processMemoryInfo.isEmpty()) {
				return null
			}

			val totalPssKb = processMemoryInfo[0].totalPss.toDouble()
			totalPssKb / 1024.0
		} catch (_: Throwable) {
			null
		}
	}
}
