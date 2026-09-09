package io.github.mxwf.weeko.adapter.wakeup

import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WakeUpScheduleAdapterTest {
    @Test
    fun parsesTheFiveLineWakeUpBackup() {
        val resource = javaClass.classLoader.getResource("sample.wakeup_schedule")
        requireNotNull(resource)
        val text = String(Files.readAllBytes(Paths.get(resource.toURI())), StandardCharsets.UTF_8)

        val draft = WakeUpScheduleAdapter().parse(text)

        assertEquals("默认作息", draft.timeTable.name)
        assertEquals(2, draft.timeDetails.size)
        assertEquals("示例课表", draft.table.tableName)
        assertEquals("高等数学", draft.courses.single().courseName)
        assertEquals(1, draft.sessions.single().day)
        assertEquals(2, draft.sessions.single().step)
        assertTrue(draft.ignoredTrailingLines.isEmpty())
    }

    @Test
    fun keepsLegacyTrailingLinesVisibleWithoutWritingData() {
        val resource = javaClass.classLoader.getResource("sample.wakeup_schedule")
        requireNotNull(resource)
        val original = String(Files.readAllBytes(Paths.get(resource.toURI())), StandardCharsets.UTF_8)

        val draft = WakeUpScheduleAdapter().parse("$original\nlegacy-extension")

        assertEquals(listOf("legacy-extension"), draft.ignoredTrailingLines)
    }
}
