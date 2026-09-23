param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
& $pwsh -NoProfile -File (Join-Path $root "tools\replay-weeko-v112-patches.ps1") -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "v1.1.2 patch replay failed; v1.1.3 patches were not applied." }

function Replace-V113ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $oldLf = $Old.Replace("`r", "").TrimEnd("`n")
    $newLf = $New.Replace("`r", "").TrimEnd("`n")
    if ([regex]::Matches($content, [regex]::Escape($oldLf)).Count -ne 1) {
        throw "Expected one v1.1.3 patch target in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

Replace-V113ExactText "apktool.yml" "  versionCode: 16`n  versionName: 1.1.2" "  versionCode: 17`n  versionName: 1.1.3"

function Replace-V113StyleFallback {
    param(
        [Parameter(Mandatory = $true)] [string] $Method,
        [Parameter(Mandatory = $true)] [string] $Key,
        [Parameter(Mandatory = $true)] [string] $NewConstant
    )
    $relativePath = "smali\com\suda\yzune\wakeupschedule\bean\ScheduleStyleConfig.smali"
    $path = Join-Path $project $relativePath
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $pattern = '(?ms)(\.method public final ' + [regex]::Escape($Method) + '\(\)[IZ].*?const-string v1, "' + [regex]::Escape($Key) + '".*?)(^\s*const(?:/[0-9]+)? v2, [^\r\n]*)'
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -ne 1) { throw "Expected one v1.1.3 default in $Method for $relativePath" }
    $replacement = $matches[0].Groups[1].Value + "    " + $NewConstant
    $updated = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement })
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

# Match the settings currently selected on the connected v1.1.2 device.
# Per-table SharedPreferences still win; these are only the fresh-table defaults.
$styleDefaults = @(
    @{ Method = "getItemHeight"; Key = "itemHeight"; Constant = "const/16 v2, 0x3e" },
    @{ Method = "getItemAlpha"; Key = "itemAlpha"; Constant = "const/16 v2, 0x3c" },
    @{ Method = "getRadius"; Key = "radius"; Constant = "const/16 v2, 0x8" },
    @{ Method = "getTextColor"; Key = "textColor"; Constant = "const v2, -0xededee" },
    @{ Method = "getCourseTextColor"; Key = "courseTextColor"; Constant = "const/4 v2, -0x1" },
    @{ Method = "getStrokeColor"; Key = "strokeColor"; Constant = "const v2, -0x7f000001" },
    @{ Method = "getShowOtherWeekCourse"; Key = "showOtherWeekCourse"; Constant = "const/4 v2, 0x0" },
    @{ Method = "getItemCenterHorizontal"; Key = "itemCenterHorizontal"; Constant = "const/4 v2, 0x1" },
    @{ Method = "getItemCenterVertical"; Key = "itemCenterVertical"; Constant = "const/4 v2, 0x1" },
    @{ Method = "getTextColorCompose"; Key = "textColorCompose"; Constant = "const/4 v2, 0x1" },
    @{ Method = "getStrokeColorCompose"; Key = "strokeColorCompose"; Constant = "const/4 v2, 0x1" },
    @{ Method = "getShowTeacher"; Key = "schedule_teacher"; Constant = "const/4 v2, 0x0" }
)
foreach ($setting in $styleDefaults) {
    Replace-V113StyleFallback $setting.Method $setting.Key $setting.Constant
}

# Keep the schedule's underlying per-table background visible through the
# pager and each week page instead of covering it with opaque theme surfaces.
Replace-V113ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0OO:Landroidx/viewpager2/widget/ViewPager2;
    invoke-virtual {v3, v0}, Landroid/view/View;->setBackgroundColor(I)V
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0OO:Landroidx/viewpager2/widget/ViewPager2;
    const/4 v4, 0x0
    invoke-virtual {v3, v4}, Landroid/view/View;->setBackgroundColor(I)V
'@

Replace-V113ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette.smali" @'
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOo0:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-virtual {v5, v1}, Landroid/view/View;->setBackgroundColor(I)V
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOOO:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-virtual {v5, v1}, Landroid/view/View;->setBackgroundColor(I)V
'@ @'
    const/4 v1, 0x0
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOo0:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-virtual {v5, v1}, Landroid/view/View;->setBackgroundColor(I)V
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOOO:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-virtual {v5, v1}, Landroid/view/View;->setBackgroundColor(I)V
'@

# Preserve the installed app's original gradient as the no-custom-background
# default; the transparent pager surfaces above now allow per-table backgrounds through.

Replace-V113ExactText "res\layout\item_table_list.xml" 'android:id="@id/ib_delete" android:layout_width="0.0dip"' 'android:id="@id/ib_delete" android:contentDescription="删除课表" android:tooltipText="删除课表" android:layout_width="0.0dip"'

Write-Output "Applied Weeko v1.1.3 schedule-background, device appearance defaults and delete-label patches to $project"
