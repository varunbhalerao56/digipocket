package com.vtbh.chuckit

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.TextView
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import android.webkit.MimeTypeMap
import android.graphics.Color

class ShareActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create full-screen dark overlay
        val rootView = View(this).apply {
            setBackgroundColor(Color.parseColor("#333A56"))
        }
        setContentView(rootView)

        // Add "Saved to Chuck'it" text
        val textView = TextView(this).apply {
            text = "✓ Saved to Chuck'it"
            textSize = 18f
            setTextColor(Color.parseColor("#FAFAF6"))
            gravity = Gravity.CENTER
        }

        addContentView(
            textView,
            android.view.ViewGroup.LayoutParams(
                android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                android.view.ViewGroup.LayoutParams.MATCH_PARENT
            )
        )

        // Process share in background
        handleShare()

        // Close after 800ms (like iOS)
        window.decorView.postDelayed({
            finish()
        }, 800)
    }
    private fun handleShare() {
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            val sharedData = JSONObject()
            sharedData.put("timestamp", System.currentTimeMillis())
            sharedData.put("source_app", "android_share_sheet")

            // Check for Image
            val imageUri = if (android.os.Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
            }

            if (imageUri != null) {
                val savedPath = saveImageToInternalStorage(imageUri)
                if (savedPath != null) {
                    sharedData.put("image_path", savedPath)
                    sharedData.put("type", "image")
                }
            } else {
                // Check Text/URL
                intent.getStringExtra(Intent.EXTRA_TEXT)?.let { text ->
                    if (android.util.Patterns.WEB_URL.matcher(text).matches()) {
                        sharedData.put("url", text)
                        sharedData.put("type", "url")
                    } else {
                        sharedData.put("text", text)
                        sharedData.put("type", "text")
                    }
                }
            }

            if (sharedData.has("type")) {
                saveToQueue(sharedData)
            }
        }
    }

    private fun saveImageToInternalStorage(uri: Uri): String? {
        try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val imagesDir = File(filesDir, "images")
            if (!imagesDir.exists()) imagesDir.mkdirs()

            val mime = contentResolver.getType(uri)
            val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: "jpg"
            val filename = "${UUID.randomUUID()}.$ext"
            val file = File(imagesDir, filename)

            FileOutputStream(file).use { outputStream ->
                inputStream.copyTo(outputStream)
            }
            inputStream.close()

            return file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun saveToQueue(jsonData: JSONObject) {
        try {
            val queueDir = File(filesDir, "share_queue")
            if (!queueDir.exists()) queueDir.mkdirs()

            val filename = "${UUID.randomUUID()}.json"
            val file = File(queueDir, filename)
            file.writeText(jsonData.toString(2))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}