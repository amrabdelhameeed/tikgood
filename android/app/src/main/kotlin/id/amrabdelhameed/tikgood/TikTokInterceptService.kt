package id.amrabdelhameed.tikgood

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.AlertDialog
import android.content.Intent
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent

class TikTokInterceptService : AccessibilityService() {

    private var dialogShowing = false
    private var userAllowedTikTok = false
    private var lastHandledPkg = ""
    private val handler = Handler(Looper.getMainLooper())

    private val resetAllowanceRunnable = Runnable {
        userAllowedTikTok = false
    }

    override fun onServiceConnected() {
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            packageNames = arrayOf(
                "com.zhiliaoapp.musically",
                "com.ss.android.ugc.trill",
                "id.amrabdelhameed.tikgood",
            )
            notificationTimeout = 300
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // Our app came to foreground — clear dialog state but keep userAllowedTikTok
        // so coming back from TikGood → TikTok doesn't re-trigger unless they
        // fully left and re-opened TikTok fresh
        if (pkg == "id.amrabdelhameed.tikgood") {
            handler.removeCallbacksAndMessages(null)
            dialogShowing = false
            lastHandledPkg = ""
            return
        }

        val isTikTok = pkg == "com.zhiliaoapp.musically" || pkg == "com.ss.android.ugc.trill"

        if (!isTikTok) {
            // Fully left TikTok to somewhere else — reset allowance
            if (lastHandledPkg == "com.zhiliaoapp.musically" ||
                lastHandledPkg == "com.ss.android.ugc.trill"
            ) {
                handler.removeCallbacks(resetAllowanceRunnable)
                userAllowedTikTok = false
            }
            lastHandledPkg = pkg
            return
        }

        // TikTok came to foreground (fresh open OR from recents)
        if (pkg == lastHandledPkg && dialogShowing) return

        // ── Every time TikTok appears — pause media immediately ───────────
        pauseTikTokMedia()

        lastHandledPkg = pkg

        if (userAllowedTikTok) {
            // They were allowed before — revoke after 3s and let them use it
            handler.removeCallbacks(resetAllowanceRunnable)
            handler.postDelayed(resetAllowanceRunnable, 3000)
            return
        }

        if (dialogShowing) return
        dialogShowing = true
        handler.post { showInterceptDialog() }
    }

    private fun pauseTikTokMedia() {
        // Send media pause key event — works without any extra permission
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        val downEvent = KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE)
        val upEvent   = KeyEvent(KeyEvent.ACTION_UP,   KeyEvent.KEYCODE_MEDIA_PAUSE)
        audioManager.dispatchMediaKeyEvent(downEvent)
        audioManager.dispatchMediaKeyEvent(upEvent)
    }

    private fun showInterceptDialog() {
        val dialog = AlertDialog.Builder(this, R.style.InterceptDialogTheme)
            .setTitle("🎓 Open TikGood instead?")
            .setMessage("You were about to open TikTok.\nWatch something that actually teaches you something!")
            .setCancelable(false)
            .setPositiveButton("Open TikGood") { _, _ ->
                userAllowedTikTok = false

                handler.postDelayed({
                    dialogShowing = false
                    lastHandledPkg = ""
                }, 1500)

                // Launch TikGood — TikTok stays in background, paused
                val intent = packageManager
                    .getLaunchIntentForPackage("id.amrabdelhameed.tikgood")
                    ?.apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_TASK_ON_HOME
                        )
                    }
                if (intent != null) startActivity(intent)
            }
            .setNegativeButton("Open TikTok anyway") { _, _ ->
                userAllowedTikTok = true
                handler.postDelayed({
                    dialogShowing = false
                }, 1500)
            }
            .create()

        dialog.window?.setType(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY)
        dialog.show()
    }

    override fun onInterrupt() {
        handler.removeCallbacksAndMessages(null)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
    }
}