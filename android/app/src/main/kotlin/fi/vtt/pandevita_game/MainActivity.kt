package fi.vtt.pandevita_game

import android.os.Bundle
import android.os.Process
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity: FlutterActivity() {
    override fun onDestroy() {
        super.onDestroy()
        Process.killProcess(Process.myPid())
    }
}
