package io.github.mxwf.weeko.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        SemesterEntity::class,
        ScheduleEntity::class,
        CourseEntity::class,
        CourseSessionEntity::class,
        SessionWeekEntity::class,
        TimeProfileEntity::class,
        TimeSlotEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class WeekoDatabase : RoomDatabase() {
    abstract fun semesterDao(): SemesterDao

    abstract fun scheduleDao(): ScheduleDao

    abstract fun courseDao(): CourseDao

    abstract fun courseSessionDao(): CourseSessionDao

    abstract fun sessionWeekDao(): SessionWeekDao

    abstract fun timeProfileDao(): TimeProfileDao

    abstract fun timeSlotDao(): TimeSlotDao

    companion object {
        fun build(context: Context): WeekoDatabase =
            Room.databaseBuilder(
                context.applicationContext,
                WeekoDatabase::class.java,
                "weeko.db",
            ).build()
    }
}

