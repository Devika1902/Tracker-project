Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$data = Get-Content (Join-Path $root 'data/project.json') -Raw | ConvertFrom-Json
$outDir = Join-Path $root 'powerbi-dashboards'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$script:W = 1600
$script:H = 1000
$script:C = @{
    navy = '#18394C'; ink = '#1B3444'; muted = '#758692'; soft = '#9AA8B0'
    bg = '#F4F7F8'; white = '#FFFFFF'; line = '#E4EAED'; teal = '#197C70'
    teal2 = '#4D9B88'; mint = '#E9F4F0'; amber = '#D69A39'; amberBg = '#FBF4E6'
    red = '#C96C5B'; redBg = '#F9ECE9'; blue = '#6E9DB5'; paleBlue = '#EDF3F6'
}

function Brush($hex) { return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex)) }
function Pen($hex, [float]$width = 1) { return [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($hex), $width) }
function Font([float]$size, [bool]$bold = $false) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    return [System.Drawing.Font]::new('Segoe UI', $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}
function Text($g, [string]$value, [float]$x, [float]$y, [float]$size = 16, [string]$color = '#1B3444', [bool]$bold = $false) {
    $g.DrawString($value, (Font $size $bold), (Brush $color), $x, $y)
}
function Rect($g, [float]$x, [float]$y, [float]$w, [float]$h, [string]$fill, [string]$stroke = '') {
    $g.FillRectangle((Brush $fill), $x, $y, $w, $h)
    if ($stroke) { $g.DrawRectangle((Pen $stroke), $x, $y, $w, $h) }
}
function Line($g, [float]$x1, [float]$y1, [float]$x2, [float]$y2, [string]$color = '#E4EAED', [float]$width = 1) {
    $g.DrawLine((Pen $color $width), $x1, $y1, $x2, $y2)
}
function Dot($g, [float]$x, [float]$y, [float]$r, [string]$color) {
    $g.FillEllipse((Brush $color), $x - $r, $y - $r, $r * 2, $r * 2)
}
function Panel($g, [float]$x, [float]$y, [float]$w, [float]$h, [string]$title, [string]$subtitle = '') {
    Rect $g $x $y $w $h $script:C.white $script:C.line
    Text $g $title ($x + 24) ($y + 20) 20 $script:C.ink $true
    if ($subtitle) { Text $g $subtitle ($x + 24) ($y + 49) 13 $script:C.muted }
}
function Badge($g, [float]$x, [float]$y, [string]$label, [string]$kind = 'teal') {
    $back = $script:C.mint; $fore = $script:C.teal
    if ($kind -eq 'amber') { $back = $script:C.amberBg; $fore = '#986B20' }
    if ($kind -eq 'red') { $back = $script:C.redBg; $fore = '#B65E50' }
    if ($kind -eq 'blue') { $back = $script:C.paleBlue; $fore = '#567E96' }
    $g.FillRectangle((Brush $back), $x, $y, 104, 25)
    Text $g $label ($x + 10) ($y + 5) 12 $fore $true
}
function PageBase([string]$title, [string]$pageNo) {
    $bmp = [System.Drawing.Bitmap]::new($script:W, $script:H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    Rect $g 0 0 $script:W $script:H $script:C.bg
    Rect $g 0 0 224 $script:H $script:C.navy
    Rect $g 0 0 224 90 '#143246'
    $g.FillRectangle((Brush $script:C.teal), 25, 24, 42, 42)
    Text $g 'N' 38 28 30 $script:C.white $true
    Text $g 'NORTHSTAR' 80 27 18 $script:C.white $true
    Text $g 'DELIVERY OFFICE' 80 52 10 '#AFC3CB' $true
    Text $g 'WORKSPACE' 28 119 11 '#9DB2BC' $true
    $nav = @(@('01','Project overview'), @('02','Task tracker'), @('03','Issues & dependencies'), @('04','Milestones'))
    for ($i = 0; $i -lt $nav.Count; $i++) {
        $yy = 150 + $i * 54
        if ($nav[$i][0] -eq $pageNo) { Rect $g 14 $yy 196 42 '#245568' }
        Text $g $nav[$i][0] 28 ($yy + 12) 12 '#9BC8C1' $true
        Text $g $nav[$i][1] 62 ($yy + 11) 14 $(if ($nav[$i][0] -eq $pageNo) { $script:C.white } else { '#C2D0D5' }) ($nav[$i][0] -eq $pageNo)
    }
    Line $g 22 835 202 835 '#456171'
    Dot $g 40 874 6 $script:C.amber
    Text $g 'Clearing service' 59 860 14 $script:C.white $true
    Text $g 'Implementation · 2026' 59 883 12 '#AFC3CB'
    Text $g 'FICTIONAL CASE STUDY' 27 956 10 '#AFC3CB' $true

    Rect $g 224 0 1376 70 $script:C.white
    Text $g 'Projects' 262 25 13 $script:C.muted
    Text $g '/' 317 25 13 '#B0BBC1'
    Text $g 'Clearing service' 332 25 13 $script:C.ink $true
    Rect $g 1364 22 206 28 $script:C.mint
    Dot $g 1380 36 4 $script:C.teal2
    Text $g 'FICTIONAL PROJECT DATA' 1392 28 10 $script:C.teal $true

    Text $g 'CLEARING SERVICE LAUNCH' 263 96 12 $script:C.teal $true
    Text $g $title 263 119 31 $script:C.ink $true
    Text $g 'Cross-functional implementation readiness · Target launch 18 Dec 2026' 263 159 15 $script:C.muted
    Text $g 'WEEK 48  ·  UPDATED 25 NOV 2026' 1245 162 11 $script:C.soft $true
    return @{ Bitmap = $bmp; Graphics = $g }
}
function SavePage($page, [string]$name) {
    $path = Join-Path $outDir $name
    $page.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $page.Graphics.Dispose(); $page.Bitmap.Dispose()
}
function Kpi($g, [float]$x, [string]$label, [string]$value, [string]$hint, [string]$kind = 'teal') {
    Rect $g $x 190 300 112 $script:C.white $script:C.line
    Text $g $label ($x + 20) 207 14 $script:C.muted
    Text $g $value ($x + 20) 232 31 $(if ($kind -eq 'red') { $script:C.red } elseif ($kind -eq 'amber') { '#B77D22' } else { $script:C.ink }) $true
    Text $g $hint ($x + 20) 274 12 $script:C.soft
}

$tasks = @($data.tasks)
$issuesOpen = @($data.issues | Where-Object status -eq 'Open')
$completed = @($tasks | Where-Object status -eq 'Complete').Count
$overdue = @($tasks | Where-Object { $_.status -ne 'Complete' -and $_.dueDate -lt $data.project.asOf }).Count
$avgProgress = [math]::Round(($tasks | Measure-Object progress -Average).Average)
$teams = @($tasks.team | Sort-Object -Unique)

# 01 — Project overview
$p = PageBase 'Project overview' '01'; $g = $p.Graphics
Kpi $g 263 'TOTAL TASKS' $tasks.Count 'Across five workstreams'
Kpi $g 583 'COMPLETED' $completed "$([math]::Round(100*$completed/$tasks.Count))% of planned tasks"
Kpi $g 903 'OVERDUE' $overdue 'Open tasks past due date' 'red'
Kpi $g 1223 'OPEN ISSUES' $issuesOpen.Count '1 high · 1 medium · 1 low' 'amber'
Panel $g 263 326 610 295 'Workstream progress' 'Completion by accountable team'
Text $g 'COMPLETE' 725 351 10 $script:C.muted $true
for ($i = 0; $i -lt $teams.Count; $i++) {
    $team = $teams[$i]; $ts = @($tasks | Where-Object team -eq $team)
    $avg = [math]::Round(($ts | Measure-Object progress -Average).Average)
    $done = @($ts | Where-Object status -eq 'Complete').Count
    $yy = 405 + $i * 38
    Text $g $team 287 $yy 13 $script:C.ink
    Rect $g 458 ($yy + 4) 280 10 '#EAF0F1'
    if ($avg -gt 0) { Rect $g 458 ($yy + 4) ([math]::Max(8, 280 * $avg / 100)) 10 $script:C.teal2 }
    Text $g "$done/$($ts.Count)" 755 $yy 12 $script:C.muted $true
}
Panel $g 893 326 667 295 'Launch readiness' 'Milestones against target date'
$readiness = @($data.milestones | Where-Object status -ne 'Complete' | Select-Object -First 4)
for ($i = 0; $i -lt $readiness.Count; $i++) {
    $m = $readiness[$i]; $yy = 405 + $i * 45
    Dot $g 920 ($yy + 9) 5 $(if ($m.status -eq 'At risk') { $script:C.amber } else { '#B7C5C9' })
    Text $g $m.name 940 $yy 13 $script:C.ink
    Text $g ([datetime]$m.plannedDate).ToString('dd MMM') 1370 $yy 12 $script:C.muted
    Badge $g 1430 ($yy - 3) $(if ($m.status -eq 'At risk') { 'AT RISK' } else { 'UPCOMING' }) $(if ($m.status -eq 'At risk') { 'amber' } else { 'blue' })
}
Panel $g 263 645 1297 280 'Tasks to watch' 'Open delivery work and immediate launch dependencies'
$watch = @($tasks | Where-Object status -ne 'Complete' | Sort-Object @{Expression={ if ($_.status -eq 'Blocked') {0} elseif ($_.dueDate -lt $data.project.asOf) {1} else {2} }}, dueDate | Select-Object -First 5)
$cols = @(287, 350, 850, 1055, 1260, 1395)
Text $g 'ID' $cols[0] 705 10 $script:C.soft $true; Text $g 'TASK' $cols[1] 705 10 $script:C.soft $true
Text $g 'WORKSTREAM' $cols[2] 705 10 $script:C.soft $true; Text $g 'OWNER' $cols[3] 705 10 $script:C.soft $true
Text $g 'DUE' $cols[4] 705 10 $script:C.soft $true; Text $g 'STATUS' $cols[5] 705 10 $script:C.soft $true
Line $g 287 727 1535 727
for ($i = 0; $i -lt $watch.Count; $i++) {
    $t = $watch[$i]; $yy = 742 + $i * 34
    Text $g $t.id $cols[0] $yy 12 $script:C.muted $true
    Text $g $t.name $cols[1] $yy 12 $script:C.ink $true
    Text $g $t.team $cols[2] $yy 12 $script:C.muted
    Text $g $t.owner $cols[3] $yy 12 $script:C.muted
    Text $g ([datetime]$t.dueDate).ToString('dd MMM') $cols[4] $yy 12 $(if ($t.dueDate -lt $data.project.asOf) { $script:C.red } else { $script:C.muted })
    Badge $g $cols[5] ($yy - 5) $t.status $(if ($t.status -eq 'Blocked') { 'red' } else { 'blue' })
}
Text $g "OVERALL TASK PROGRESS  $avgProgress%" 1265 950 11 $script:C.teal $true
SavePage $p '01-project-overview.png'

# 02 — Issues and dependencies
$p = PageBase 'Issues & dependencies' '03'; $g = $p.Graphics
Kpi $g 263 'OPEN ISSUES' $issuesOpen.Count 'Items requiring follow-up' 'amber'
Kpi $g 583 'HIGH SEVERITY' @($issuesOpen | Where-Object severity -eq 'High').Count 'Environment stability risk' 'red'
Kpi $g 903 'BLOCKED TASKS' @($tasks | Where-Object status -eq 'Blocked').Count 'Waiting on prerequisites' 'red'
Kpi $g 1223 'AFFECTED TEAMS' 3 'Infrastructure · Testing · Business' 'blue'
Panel $g 263 326 785 535 'Open issues' 'Severity, accountable owner and business impact'
$issueRows = $issuesOpen | Sort-Object @{Expression={ if ($_.severity -eq 'High') {0} elseif ($_.severity -eq 'Medium') {1} else {2} }}, targetDate
for ($i = 0; $i -lt $issueRows.Count; $i++) {
    $issue = $issueRows[$i]; $yy = 395 + $i * 128
    Dot $g 291 ($yy + 9) 6 $(if ($issue.severity -eq 'High') { $script:C.red } elseif ($issue.severity -eq 'Medium') { $script:C.amber } else { $script:C.blue })
    Text $g $issue.title 310 $yy 15 $script:C.ink $true
    Text $g "$($issue.team)  ·  $($issue.owner)  ·  Due $(([datetime]$issue.targetDate).ToString('dd MMM'))" 310 ($yy + 27) 12 $script:C.muted
    Text $g "Impact: $($issue.impact)" 310 ($yy + 52) 12 '#516875'
    Badge $g 905 ($yy - 3) ($issue.severity.ToUpper() + ' SEVERITY') $(if ($issue.severity -eq 'High') { 'red' } elseif ($issue.severity -eq 'Medium') { 'amber' } else { 'blue' })
    if ($i -lt $issueRows.Count - 1) { Line $g 287 ($yy + 91) 1020 ($yy + 91) }
}
Panel $g 1068 326 492 266 'Dependency chain' 'Certification depends on environment recovery'
$chain = @('Provision test environment', 'Configure network connectivity', 'Run end-to-end certification')
for ($i = 0; $i -lt $chain.Count; $i++) {
    $yy = 407 + $i * 62
    Rect $g 1095 $yy 430 42 $(if ($i -lt 2) { '#F8F3E8' } else { '#EDF4F2' })
    Dot $g 1116 ($yy + 21) 6 $(if ($i -lt 2) { $script:C.amber } else { $script:C.teal2 })
    Text $g $chain[$i] 1134 ($yy + 12) 13 $script:C.ink $true
    if ($i -lt 2) { Line $g 1116 ($yy + 43) 1116 ($yy + 61) $script:C.soft 2 }
}
Panel $g 1068 615 492 246 'Responsible teams' 'Open items by ownership group'
$issueTeams = @($issuesOpen | Group-Object team | Sort-Object Count -Descending)
for ($i = 0; $i -lt $issueTeams.Count; $i++) {
    $grp = $issueTeams[$i]; $yy = 690 + $i * 45
    Text $g $grp.Name 1095 $yy 13 $script:C.ink
    Rect $g 1260 ($yy + 3) 205 12 '#EAF0F1'
    Rect $g 1260 ($yy + 3) ([math]::Max(14, 205 * $grp.Count / $issuesOpen.Count)) 12 $script:C.teal2
    Text $g "$($grp.Count)" 1480 $yy 12 $script:C.muted $true
}
Text $g 'MANAGEMENT ACTION  ·  Stabilise the test environment and confirm a ready date by 27 Nov.' 263 891 14 '#8D671F' $true
Text $g 'Testing to reserve a recovery certification slot immediately after Infrastructure sign-off.' 263 918 13 $script:C.muted
SavePage $p '02-issues-and-dependencies.png'

# 03 — Milestone tracking
$p = PageBase 'Milestone tracking' '04'; $g = $p.Graphics
Kpi $g 263 'TOTAL MILESTONES' @($data.milestones).Count 'From scope agreement to launch'
Kpi $g 583 'COMPLETE' @($data.milestones | Where-Object status -eq 'Complete').Count 'Delivered to plan'
Kpi $g 903 'AT RISK' @($data.milestones | Where-Object status -eq 'At risk').Count 'Environment readiness checkpoint' 'amber'
Kpi $g 1223 'TARGET LAUNCH' '18 Dec' 'Business go / no-go: 16 Dec' 'blue'
Panel $g 263 326 1297 510 'Milestone timeline' 'Planned checkpoints, actual completion and accountable workstream'
$ms = @($data.milestones)
$xLine = 360; $xEnd = 1485; $dateStart = [datetime]'2026-10-19'; $dateEnd = [datetime]'2026-12-20'
Line $g $xLine 422 $xEnd 422 '#D9E3E6' 3
Text $g 'DELIVERY CHECKPOINT' 292 480 11 $script:C.soft $true
Text $g 'OWNER' 900 480 11 $script:C.soft $true
Text $g 'PLANNED' 1130 480 11 $script:C.soft $true
Text $g 'ACTUAL / STATUS' 1300 480 11 $script:C.soft $true
for ($i = 0; $i -lt $ms.Count; $i++) {
    $m = $ms[$i]; $planned = [datetime]$m.plannedDate
    $ratio = ($planned - $dateStart).TotalDays / ($dateEnd - $dateStart).TotalDays
    $xx = $xLine + ($xEnd - $xLine) * $ratio
    $color = if ($m.status -eq 'Complete') { $script:C.teal2 } elseif ($m.status -eq 'At risk') { $script:C.amber } else { '#BBC8CC' }
    Dot $g $xx 422 9 $script:C.white
    $g.DrawEllipse((Pen $color 3), $xx - 9, 413, 18, 18)
    $yy = 518 + $i * 47
    Text $g $m.name 292 $yy 13 $script:C.ink $true
    Text $g $m.owner 900 $yy 13 $script:C.muted
    Text $g $planned.ToString('dd MMM yyyy') 1130 $yy 13 $script:C.muted
    if ($m.status -eq 'Complete') {
        Text $g ([datetime]$m.actualDate).ToString('dd MMM yyyy') 1300 $yy 13 $script:C.teal $true
    } else {
        Badge $g 1300 ($yy - 5) $(if ($m.status -eq 'At risk') { 'AT RISK' } else { 'UPCOMING' }) $(if ($m.status -eq 'At risk') { 'amber' } else { 'blue' })
    }
    if ($i -lt $ms.Count - 1) { Line $g 292 ($yy + 30) 1535 ($yy + 30) }
}
Text $g 'OCT' 365 435 10 $script:C.soft $true
Text $g 'NOV' 795 435 10 $script:C.soft $true
Text $g 'DEC' 1365 435 10 $script:C.soft $true
Panel $g 263 858 1297 81 'Launch confidence checkpoint' 'Environment readiness was planned for 20 Nov and is at risk. Confirm recovery date and certification slot at the next weekly review.'
Text $g 'RECOMMENDED ACTION  ·  Infrastructure to confirm stable test environment by 27 Nov.' 900 886 13 '#8D671F' $true
SavePage $p '03-milestone-tracking.png'

Write-Output "Rendered three Power BI dashboard images to $outDir"
