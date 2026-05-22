package com.vacman.apexaura

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 스크롤 캡처 + 스크린샷 허용 (FLAG_SECURE 명시 해제)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
