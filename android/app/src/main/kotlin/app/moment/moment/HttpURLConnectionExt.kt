package app.moment.moment

import java.net.HttpURLConnection

internal inline fun <T> HttpURLConnection.useConnection(
    block: (HttpURLConnection) -> T,
): T {
    return try {
        block(this)
    } finally {
        disconnect()
    }
}
