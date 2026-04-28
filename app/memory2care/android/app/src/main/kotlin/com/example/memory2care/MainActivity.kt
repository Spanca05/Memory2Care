package com.example.memory2care

import java.util.TimeZone
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val timeZoneChannel = "memory2care/timezone"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, timeZoneChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getTimeZoneId" -> result.success(TimeZone.getDefault().id)
					else -> result.notImplemented()
				}
			}
	}
}
