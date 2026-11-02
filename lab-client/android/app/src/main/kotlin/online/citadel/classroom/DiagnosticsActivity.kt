package online.citadel.classroom
import android.app.Activity
import android.os.Bundle
import android.widget.TextView
import android.widget.ScrollView
import java.io.File

// C10: unlike the launcher, this internal component must not be exported.
class DiagnosticsActivity : Activity() {
    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        val session = File(applicationInfo.dataDir, "app_flutter/session.json")
        val value = if (session.exists()) session.readText() else "No saved session. Load demo as Alice first."
        val text = TextView(this).apply {
            textSize = 17f
            setPadding(36, 60, 36, 36)
            text = "Internal diagnostics\n\n$value\n\nCLASSROOM{EXPORTED_IS_A_DOOR}"
            setTextIsSelectable(true)
        }
        setContentView(ScrollView(this).apply { addView(text) })
    }
}
