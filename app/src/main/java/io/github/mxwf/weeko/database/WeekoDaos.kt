package io.github.mxwf.weeko.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface SemesterDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(semester: SemesterEntity)
}

@Dao
interface ScheduleDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(schedule: ScheduleEntity)

    @Transaction
    @Query("SELECT * FROM schedules WHERE id = :scheduleId LIMIT 1")
    fun observeWithSemester(scheduleId: String): Flow<ScheduleWithSemesterEntity?>
}

@Dao
interface CourseDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(course: CourseEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAll(courses: List<CourseEntity>)

    @Update
    suspend fun update(course: CourseEntity): Int

    @Transaction
    @Query("SELECT * FROM courses WHERE id = :courseId LIMIT 1")
    fun observeWithSessions(courseId: String): Flow<CourseWithSessionsEntity?>

    @Query("DELETE FROM courses WHERE id = :courseId")
    suspend fun deleteById(courseId: String): Int
}

@Dao
interface CourseSessionDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAll(sessions: List<CourseSessionEntity>)

    @Query("DELETE FROM course_sessions WHERE course_id = :courseId")
    suspend fun deleteForCourse(courseId: String)
}

@Dao
interface SessionWeekDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAll(weeks: List<SessionWeekEntity>)
}

@Dao
interface TimeProfileDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(profile: TimeProfileEntity)

    @Query("SELECT * FROM time_profiles WHERE schedule_id = :scheduleId LIMIT 1")
    fun observeForSchedule(scheduleId: String): Flow<TimeProfileEntity?>
}

@Dao
interface TimeSlotDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAll(slots: List<TimeSlotEntity>)

    @Query("SELECT * FROM time_slots WHERE time_profile_id = :profileId ORDER BY period_index")
    fun observeForProfile(profileId: String): Flow<List<TimeSlotEntity>>
}
