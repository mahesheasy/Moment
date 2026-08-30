package app.moment.moment.widget

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import java.io.FileOutputStream

object WidgetBitmap {
    private const val MAX_SIZE = 480

    fun blur(source: Bitmap): Bitmap = blur(source, 1f)

    /** [strength] 0 = clear, 1 = full privacy blur. */
    fun blur(source: Bitmap, strength: Float): Bitmap {
        val amount = strength.coerceIn(0f, 1f)
        if (amount <= 0.001f) return source
        if (amount >= 0.999f) {
            val width = (source.width / 12).coerceAtLeast(8)
            val height = (source.height / 12).coerceAtLeast(8)
            val small = Bitmap.createScaledBitmap(source, width, height, true)
            return Bitmap.createScaledBitmap(small, source.width, source.height, true)
        }
        val divisor = 12f - (11f * amount)
        val width = (source.width / divisor).toInt().coerceAtLeast(8)
        val height = (source.height / divisor).toInt().coerceAtLeast(8)
        val small = Bitmap.createScaledBitmap(source, width, height, true)
        return Bitmap.createScaledBitmap(small, source.width, source.height, true)
    }

    fun decode(path: String?): Bitmap? {
        if (path.isNullOrBlank()) return null
        val file = File(path)
        if (!file.exists()) return null

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        val options =
            BitmapFactory.Options().apply {
                inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight, MAX_SIZE)
                inPreferredConfig = Bitmap.Config.RGB_565
            }
        return BitmapFactory.decodeFile(path, options)
    }

    fun writeDownsampled(bytes: ByteArray, output: File): String? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)

        val bitmap =
            if (bounds.outWidth > 0 && bounds.outHeight > 0) {
                val options =
                    BitmapFactory.Options().apply {
                        inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight, MAX_SIZE)
                        inPreferredConfig = Bitmap.Config.RGB_565
                    }
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
            } else {
                null
            }

        return try {
            FileOutputStream(output).use { stream ->
                if (bitmap != null) {
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
                    bitmap.recycle()
                } else {
                    stream.write(bytes)
                }
            }
            output.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun sampleSize(width: Int, height: Int, max: Int): Int {
        var sample = 1
        while (width / sample > max || height / sample > max) {
            sample *= 2
        }
        return sample
    }
}
