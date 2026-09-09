package io.github.mxwf.weeko.designsystem

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.shape.RoundedCornerShape

private val WeekoLightColorScheme = lightColorScheme(
    primary = Color(0xFF335C81),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFD1E4FF),
    onPrimaryContainer = Color(0xFF001D35),
    secondary = Color(0xFF4F6174),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFD3E5FA),
    onSecondaryContainer = Color(0xFF0B1D2C),
    tertiary = Color(0xFF655F7A),
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFEAE0FF),
    onTertiaryContainer = Color(0xFF20163A),
    error = Color(0xFFBA1A1A),
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
    background = Color(0xFFF9F9FC),
    onBackground = Color(0xFF1A1B1E),
    surface = Color(0xFFF9F9FC),
    onSurface = Color(0xFF1A1B1E),
    surfaceVariant = Color(0xFFDFE3EB),
    onSurfaceVariant = Color(0xFF43474E),
    outline = Color(0xFF73777F),
)

private val WeekoDarkColorScheme = darkColorScheme(
    primary = Color(0xFFA5C8F0),
    onPrimary = Color(0xFF073352),
    primaryContainer = Color(0xFF19496B),
    onPrimaryContainer = Color(0xFFD1E4FF),
    secondary = Color(0xFFB7C9DC),
    onSecondary = Color(0xFF213340),
    secondaryContainer = Color(0xFF374A5A),
    onSecondaryContainer = Color(0xFFD3E5FA),
    tertiary = Color(0xFFCEC2E8),
    onTertiary = Color(0xFF352D49),
    tertiaryContainer = Color(0xFF4C4261),
    onTertiaryContainer = Color(0xFFEAE0FF),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),
    background = Color(0xFF111417),
    onBackground = Color(0xFFE2E2E6),
    surface = Color(0xFF111417),
    onSurface = Color(0xFFE2E2E6),
    surfaceVariant = Color(0xFF43474E),
    onSurfaceVariant = Color(0xFFC3C7CF),
    outline = Color(0xFF8D9199),
)

private val WeekoTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 36.sp,
        lineHeight = 44.sp,
    ),
    headlineSmall = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.SemiBold,
        fontSize = 24.sp,
        lineHeight = 32.sp,
    ),
    titleLarge = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.SemiBold,
        fontSize = 22.sp,
        lineHeight = 28.sp,
    ),
    titleMedium = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        lineHeight = 24.sp,
    ),
    bodyLarge = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = FontFamily.SansSerif,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
)

private val WeekoShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(16.dp),
    large = RoundedCornerShape(24.dp),
    extraLarge = RoundedCornerShape(28.dp),
)

@Immutable
data class WeekoSpacingTokens(
    val xxs: Dp = 4.dp,
    val xs: Dp = 8.dp,
    val sm: Dp = 12.dp,
    val md: Dp = 16.dp,
    val lg: Dp = 24.dp,
    val xl: Dp = 32.dp,
    val xxl: Dp = 48.dp,
    val page: Dp = 20.dp,
    val section: Dp = 24.dp,
)

private val DefaultWeekoSpacing = WeekoSpacingTokens()

val LocalWeekoSpacing = staticCompositionLocalOf { DefaultWeekoSpacing }

object WeekoSpacing {
    val current: WeekoSpacingTokens
        @Composable get() = LocalWeekoSpacing.current
}

/** Stable colors for course cards; these values are independent of dynamic system colors. */
object WeekoCoursePalette {
    val Blue = Color(0xFF3F6D9A)
    val Sage = Color(0xFF557D72)
    val Amber = Color(0xFFB47737)
    val Plum = Color(0xFF7A5D86)
    val Coral = Color(0xFFB75D57)

    private val stableColors = listOf(Blue, Sage, Amber, Plum, Coral)

    val all: List<Color> = stableColors

    fun fromSeed(seed: Long): Color = stableColors[Math.floorMod(seed, stableColors.size.toLong()).toInt()]
}

@Composable
fun WeekoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && darkTheme ->
            dynamicDarkColorScheme(context)

        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            dynamicLightColorScheme(context)

        darkTheme -> WeekoDarkColorScheme
        else -> WeekoLightColorScheme
    }

    CompositionLocalProvider(LocalWeekoSpacing provides DefaultWeekoSpacing) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = WeekoTypography,
            shapes = WeekoShapes,
            content = content,
        )
    }
}
