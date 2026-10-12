package com.example.frontend

import com.csdcorp.speech_to_text.SpeechToTextPlugin
import com.llfbandit.record.RecordPlugin
import com.eyedeadevelopment.fluttertts.FlutterTtsPlugin
import com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin
import io.flutter.plugins.imagepicker.ImagePickerPlugin
import io.flutter.plugins.pathprovider.PathProviderPlugin
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
import xyz.luan.audioplayers.AudioplayersPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val plugins = flutterEngine.plugins
        if (!plugins.has(AudioplayersPlugin::class.java)) plugins.add(AudioplayersPlugin())
        if (!plugins.has(FlutterAndroidLifecyclePlugin::class.java)) plugins.add(FlutterAndroidLifecyclePlugin())
        if (!plugins.has(FlutterSecureStoragePlugin::class.java)) plugins.add(FlutterSecureStoragePlugin())
        if (!plugins.has(ImagePickerPlugin::class.java)) plugins.add(ImagePickerPlugin())
        if (!plugins.has(PathProviderPlugin::class.java)) plugins.add(PathProviderPlugin())
        if (!plugins.has(RecordPlugin::class.java)) plugins.add(RecordPlugin())
        if (!plugins.has(SharedPreferencesPlugin::class.java)) plugins.add(SharedPreferencesPlugin())
        if (!plugins.has(SpeechToTextPlugin::class.java)) plugins.add(SpeechToTextPlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yathra/lazy_tts")
            .setMethodCallHandler { call, result ->
                if (call.method != "initialize") {
                    result.notImplemented()
                } else {
                    try {
                        if (!plugins.has(FlutterTtsPlugin::class.java)) plugins.add(FlutterTtsPlugin())
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("tts_init_failed", "Could not initialize voice narration.", error.message)
                    }
                }
            }
    }
}
