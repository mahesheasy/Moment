package app.moment.moment.widget

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

class WidgetBackgroundSyncWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val ok = WidgetSupabaseSync.sync(applicationContext, promoteLatest = false)
        return if (ok) Result.success() else Result.retry()
    }
}

object WidgetSyncScheduler {
    private const val PERIODIC = "moment_widget_periodic_sync"
    private const val BACKUP = "moment_widget_backup_sync"

    fun schedulePeriodic(context: Context) {
        if (WidgetSyncCredentialsStore.load(context) == null) return
        val request =
            PeriodicWorkRequestBuilder<WidgetBackgroundSyncWorker>(15, TimeUnit.MINUTES)
                .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            PERIODIC,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun enqueueBackup(context: Context) {
        if (WidgetSyncCredentialsStore.load(context) == null) return
        val request =
            OneTimeWorkRequestBuilder<WidgetBackgroundSyncWorker>()
                .setInitialDelay(8, TimeUnit.SECONDS)
                .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            BACKUP,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(PERIODIC)
        WorkManager.getInstance(context).cancelUniqueWork(BACKUP)
    }
}
