param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage2Script = Join-Path $PSScriptRoot "replay-weeko-v07-stage2-patches.ps1"

& $stage2Script -ProjectPath $project
if (!$?) { throw "Stage 2 patch replay failed; Stage 3 was not applied." }

function Replace-Stage3ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r`n", "`n")
    $oldLf = $Old.Replace("`r`n", "`n")
    $newLf = $New.Replace("`r`n", "`n")
    $first = $content.IndexOf($oldLf, [StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Expected original text was not found in $RelativePath" }
    $second = $content.IndexOf($oldLf, $first + $oldLf.Length, [StringComparison]::Ordinal)
    if ($second -ge 0) { throw "Expected original text occurs more than once in $RelativePath" }
    $updated = $content.Remove($first, $oldLf.Length).Insert($first, $newLf)
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

Replace-Stage3ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-stage2
'@ @'
  versionCode: 7
  versionName: 0.7.0-stage3
'@

Replace-Stage3ExactText "res/values/public.xml" @'
    <public type="string" name="weeko_nav_share" id="0x7f12023a" />
'@ @'
    <public type="string" name="weeko_nav_share" id="0x7f12023a" />
    <public type="string" name="weeko_nav_adjust_week" id="0x7f12023b" />
    <public type="string" name="weeko_nav_switch_manage" id="0x7f12023c" />
'@

Replace-Stage3ExactText "res/values/strings.xml" @'
    <string name="weeko_nav_share">Share</string>
'@ @'
    <string name="weeko_nav_share">Share</string>
    <string name="weeko_nav_adjust_week">Adjust week</string>
    <string name="weeko_nav_switch_manage">Switch/manage schedules</string>
'@

$zhStringsPath = Join-Path $project "res/values-zh-rCN/strings.xml"
$zhStrings = [IO.File]::ReadAllText($zhStringsPath)
$zhStrings = [Text.RegularExpressions.Regex]::Replace(
    $zhStrings,
    '(?m)^\s*<string name="weeko_nav_share">.*</string>\r?$\r?\n?',
    ('    <string name="weeko_nav_share">&#x5206;&#x4EAB;</string>' + [Environment]::NewLine)
)
[IO.File]::WriteAllText($zhStringsPath, $zhStrings, [Text.UTF8Encoding]::new($false))

Replace-Stage3ExactText "res/values-zh-rCN/strings.xml" @'
</resources>
'@ @'
    <string name="weeko_nav_adjust_week">&#x8C03;&#x6574;&#x5468;&#x6570;</string>
    <string name="weeko_nav_switch_manage">&#x5207;&#x6362;/&#x7BA1;&#x7406;&#x8BFE;&#x8868;</string>
</resources>
'@

# Give the left navigation entry its own label while preserving the original
# bottom-sheet copy, then replace the conditional/new-schedule tail with one
# always-available “back to current week” action.
Replace-Stage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    .line 48
    .line 49
    const v3, 0x7f120125
'@ @'
    .line 48
    .line 49
    const v3, 0x7f12023b
'@

Replace-Stage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    .line 69
    .line 70
    .line 71
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    const v3, 0x7f120225
'@ @'
    .line 69
    .line 70
    .line 71
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    const v3, 0x7f12023c
'@

Replace-Stage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    .line 74
    .line 75
    .line 76
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;

    .line 72
    .line 73
    .line 74
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;

    .line 75
    .line 76
    .line 77
    move-result-object v3

    .line 78
    iget v3, v3, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I

    .line 79
    .line 80
    if-lez v3, :cond_1

    .line 81
    .line 82
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;

    .line 83
    .line 84
    .line 85
    move-result-object v3

    .line 86
    iget v3, v3, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I

    .line 87
    .line 88
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;

    .line 89
    .line 90
    .line 91
    move-result-object v4

    .line 92
    invoke-virtual {v4}, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o()Lcom/suda/yzune/wakeupschedule/bean/TableConfig;

    .line 93
    .line 94
    .line 95
    move-result-object v4

    .line 96
    invoke-virtual {v4}, Lcom/suda/yzune/wakeupschedule/bean/TableConfig;->getMaxWeek()I

    .line 97
    .line 98
    .line 99
    move-result v4

    .line 100
    if-gt v3, v4, :cond_1

    .line 101
    .line 102
    iget-object v3, v13, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    .line 103
    .line 104
    if-eqz v3, :cond_0

    .line 105
    .line 106
    iget-object v3, v3, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0OO:Landroidx/viewpager2/widget/ViewPager2;

    .line 107
    .line 108
    invoke-virtual {v3}, Landroidx/viewpager2/widget/ViewPager2;->getCurrentItem()I

    .line 109
    .line 110
    .line 111
    move-result v3

    .line 112
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;

    .line 113
    .line 114
    .line 115
    move-result-object v4

    .line 116
    iget v4, v4, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I

    .line 117
    .line 118
    sub-int/2addr v4, v14

    .line 119
    if-eq v3, v4, :cond_1

    .line 120
    .line 121
    const v3, 0x7f12011f

    .line 122
    .line 123
    .line 124
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;

    .line 125
    .line 126
    .line 127
    move-result-object v3

    .line 128
    check-cast v3, LOooOO0/o00Ooo;

    .line 129
    .line 130
    invoke-virtual {v3, v9}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;

    .line 131
    .line 132
    .line 133
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    .line 134
    .line 135
    const/16 v5, 0x9

    .line 136
    .line 137
    invoke-direct {v4, v13, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 138
    .line 139
    .line 140
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    .line 141
    .line 142
    .line 143
    goto :goto_0

    .line 144
    :cond_0
    const-string v1, "ui"

    .line 145
    .line 146
    invoke-static {v1}, Lkotlin/jvm/internal/OooOO0O;->OooOO0o(Ljava/lang/String;)V

    .line 147
    .line 148
    .line 149
    throw v16

    .line 150
    :cond_1
    :goto_0
    const v3, 0x7f120120

    .line 151
    .line 152
    .line 153
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;

    .line 154
    .line 155
    .line 156
    move-result-object v2

    .line 157
    check-cast v2, LOooOO0/o00Ooo;

    .line 158
    .line 159
    const v3, 0x7f0800cb

    .line 160
    .line 161
    .line 162
    invoke-virtual {v2, v3}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;

    .line 163
    .line 164
    .line 165
    new-instance v3, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    .line 166
    .line 167
    const/16 v4, 0xa

    .line 168
    .line 169
    invoke-direct {v3, v13, v4}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 170
    .line 171
    .line 172
    invoke-interface {v2, v3}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;
'@ @'
    const v3, 0x7f12011f

    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;

    move-result-object v3

    check-cast v3, LOooOO0/o00Ooo;

    invoke-virtual {v3, v9}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;

    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    const/16 v5, 0x9

    invoke-direct {v4, v13, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;
'@

Write-Output "Applied v0.7 Stage 3 left-navigation migration patch to $project"
