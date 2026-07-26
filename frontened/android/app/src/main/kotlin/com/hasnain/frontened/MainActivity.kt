package com.hasnain.smartassistant

import android.os.Bundle // 🔥 Import mandatory for Bundle state management
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen // 🔥 Custom Splash Library Import
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // 🔥 Flutter activity initialize hone se pehle splash library inject karein
        // Yeh line first-time installation par image draw hone tak frame block rakhegi
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)
    }
}