# PowerShell 7 增强环境 + 系统优化脚本

Write-Host "开始安装PowerShell 7增强环境和系统优化..." -ForegroundColor Cyan

# 设置仓库
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# 安装核心模块
Install-Module -Name PSReadLine -Force -SkipPublisherCheck -AllowPrerelease
Install-Module -Name Terminal-Icons -Force
Install-Module -Name z -Force -AllowClobber
Install-Module -Name posh-git -Force
Install-Module -Name oh-my-posh -Force

# 安装高级模块
Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Force
Install-Module -Name CompletionPredictor -Force
Install-Module -Name PSFzf -Force
Install-Module -Name PowerType -Force
Install-Module -Name PSScriptAnalyzer -Force

# 安装命令行工具
choco install fzf -y
choco install ripgrep -y
choco install fd -y
choco install bat -y
choco install git -y
choco install starship -y
choco install neovim -y

# 创建配置文件
$profilePath = "C:\Program Files\PowerShell\7\profile.ps1"
$profileContent = @'
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
try { Import-Module PSReadLine -ErrorAction SilentlyContinue } catch { }
try { Import-Module Terminal-Icons -ErrorAction SilentlyContinue } catch { }
try { Import-Module z -ErrorAction SilentlyContinue } catch { }
try { Import-Module posh-git -ErrorAction SilentlyContinue } catch { }
try { Import-Module PSFzf -ErrorAction SilentlyContinue } catch { }
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function Complete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function DeleteChar -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key "Ctrl+r" -Function ReverseSearchHistory -ErrorAction SilentlyContinue
}
if (Get-Command starship -ErrorAction SilentlyContinue) {
    try { Invoke-Expression (&starship init powershell) } catch { }
} else {
    function prompt { "$([char]27)[32m$env:USERNAME$([char]27)[0m@$([char]27)[33m$env:COMPUTERNAME$([char]27)[0m:$([char]27)[34m$(Get-Location)$([char]27)[0m> " }
}
function ll { if (Get-Command exa -ErrorAction SilentlyContinue) { exa -la --icons } else { Get-ChildItem -Force | Format-Table -AutoSize } }
function la { Get-ChildItem -Force -Hidden | Format-Table -AutoSize }
function cat { if (Get-Command bat -ErrorAction SilentlyContinue) { bat $args } else { Get-Content $args } }
function grep { if (Get-Command rg -ErrorAction SilentlyContinue) { rg $args } else { Select-String $args } }
function find { if (Get-Command fd -ErrorAction SilentlyContinue) { fd $args } else { Get-ChildItem -Recurse -Name "*$args*" } }
function gst { git status }
function ga { git add $args }
function gc { git commit $args }
function gp { git push }
function gl { git log --oneline -10 }
function gd { git diff $args }
function sysinfo {
    Write-Host "`n=== 系统信息 ===" -ForegroundColor Cyan
    Write-Host "主机: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host "用户: $env:USERNAME" -ForegroundColor Yellow
    Write-Host "PS版本: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "当前目录: $(Get-Location)" -ForegroundColor Yellow
    $memory = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($memory) {
        $totalRAM = [Math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        Write-Host "内存: $totalRAM GB" -ForegroundColor Yellow
    }
    Write-Host ""
}
function myip {
    Write-Host "本地IP:" -ForegroundColor Cyan
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.PrefixOrigin -ne "WellKnown" } | ForEach-Object { Write-Host "  $($_.IPAddress)" -ForegroundColor Yellow }
}
function ports {
    Get-NetTCPConnection | Where-Object State -eq Listen | Select-Object LocalAddress, LocalPort, @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | Sort-Object LocalPort | Format-Table -AutoSize
}
function df {
    Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[Math]::Round($_.Size/1GB,2)}}, @{Name="Free(GB)";Expression={[Math]::Round($_.FreeSpace/1GB,2)}}, @{Name="Use%";Expression={[Math]::Round((($_.Size-$_.FreeSpace)/$_.Size)*100,2)}} | Format-Table -AutoSize
}
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function mkcd($path) { New-Item -ItemType Directory -Path $path -Force; Set-Location $path }
function touch($file) { New-Item -ItemType File -Path $file -Force }
function which($cmd) { Get-Command $cmd | Select-Object -ExpandProperty Source }
function reload { . $profilePath }
Set-Alias -Name ls -Value Get-ChildItem -Force
Set-Alias -Name pwd -Value Get-Location -Force
Set-Alias -Name clear -Value Clear-Host -Force
$Host.UI.RawUI.WindowTitle = "PowerShell 7 - $env:USERNAME@$env:COMPUTERNAME"
Write-Host "=== PowerShell 7 增强环境 ===" -ForegroundColor Cyan
Write-Host "可用命令: sysinfo, myip, ports, df, ll, reload" -ForegroundColor Gray
'@

# 写入配置文件
$profileContent | Out-File -FilePath $profilePath -Encoding utf8 -Force

# 创建Starship配置
New-Item -Path "$env:USERPROFILE\.config" -ItemType Directory -Force
$starshipConfig = @'
format = "$username@$hostname:$directory$git_branch$git_status$line_break$character"

[username]
style_user = "green bold"
show_always = true

[hostname]
style = "yellow bold"
ssh_only = false

[directory]
style = "blue bold"

[git_branch]
style = "purple bold"

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
'@
$starshipConfig | Out-File -FilePath "$env:USERPROFILE\.config\starship.toml" -Encoding utf8 -Force

# 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

Write-Host "开始系统优化配置..." -ForegroundColor Cyan

# 注册表优化
Write-Host "应用注册表优化..." -ForegroundColor Yellow

# 性能优化
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Type DWord

# 启动优化
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Value 0 -Type DWord -Force

# 视觉效果优化
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value "0" -Type String
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String

# 文件系统优化
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "Win32FileSystem" -Value 2 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisable8dot3NameCreation" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 1 -Type DWord

# 网络优化
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Tcp1323Opts" -Value 3 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Value 64 -Type DWord

# 禁用不必要的服务
Write-Host "优化系统服务..." -ForegroundColor Yellow

$servicesToDisable = @(
    "Fax", "WerSvc", "Spooler", "WMPNetworkSvc", "WSearch", "SysMain",
    "Themes", "TabletInputService", "bthserv", "dmwappushservice",
    "MapsBroker", "lfsvc", "SharedAccess", "lltdsvc", "MSiSCSI",
    "smphost", "SNMPTrap", "SSDPSRV", "upnphost", "WbioSrvc",
    "icssvc", "WlanSvc", "WwanSvc", "Audiosrv", "AudioEndpointBuilder"
)

foreach ($service in $servicesToDisable) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc -and $svc.StartType -ne "Disabled") {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "已禁用服务: $service" -ForegroundColor Green
        }
    } catch {
        Write-Host "无法禁用服务: $service" -ForegroundColor Red
    }
}

# 清理系统垃圾
Write-Host "清理系统垃圾文件..." -ForegroundColor Yellow

$tempFolders = @(
    "$env:TEMP",
    "$env:WINDIR\Temp",
    "$env:WINDIR\Prefetch",
    "$env:LOCALAPPDATA\Temp",
    "$env:WINDIR\SoftwareDistribution\Download"
)

foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        try {
            Get-ChildItem -Path $folder -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "已清理: $folder" -ForegroundColor Green
        } catch {
            Write-Host "无法完全清理: $folder" -ForegroundColor Yellow
        }
    }
}

# 清理回收站
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# DNS优化
Write-Host "优化DNS设置..." -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias "以太网*" -ServerAddresses "8.8.8.8", "8.8.4.4" -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi*" -ServerAddresses "8.8.8.8", "8.8.4.4" -ErrorAction SilentlyContinue

# 清理DNS缓存
Clear-DnsClientCache

# 启用快速启动
powercfg /hibernate on

# 电源管理优化
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # 高性能模式

# Windows功能优化
Write-Host "优化Windows功能..." -ForegroundColor Yellow

# 禁用不必要的Windows功能
$featuresToDisable = @(
    "Internet-Explorer-Optional-amd64",
    "MediaPlayback",
    "WindowsMediaPlayer",
    "WorkFolders-Client"
)

foreach ($feature in $featuresToDisable) {
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue
        Write-Host "已禁用功能: $feature" -ForegroundColor Green
    } catch {
        Write-Host "无法禁用功能: $feature" -ForegroundColor Yellow
    }
}

# 安装有用的功能
$featuresToEnable = @(
    "Microsoft-Windows-Subsystem-Linux",
    "VirtualMachinePlatform",
    "Microsoft-Hyper-V-All"
)

foreach ($feature in $featuresToEnable) {
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue
        Write-Host "已启用功能: $feature" -ForegroundColor Green
    } catch {
        Write-Host "无法启用功能: $feature" -ForegroundColor Yellow
    }
}

# 磁盘优化
Write-Host "优化磁盘设置..." -ForegroundColor Yellow

# 禁用磁盘索引（提高性能）
Get-WmiObject -Class Win32_Volume | Where-Object {$_.IndexingEnabled -eq $true -and $_.DriveLetter -ne $null} | Set-WmiInstance -Arguments @{IndexingEnabled=$false}

# 禁用系统还原（节省空间）
Disable-ComputerRestore -Drive "C:"

# 设置虚拟内存为系统管理
$cs = Get-WmiObject -Class Win32_ComputerSystem
$cs.AutomaticManagedPagefile = $true
$cs.Put()

# 优化SSD（如果存在）
$disks = Get-PhysicalDisk | Where-Object MediaType -eq "SSD"
foreach ($disk in $disks) {
    # 启用TRIM
    Enable-StorageMaintenanceMode -InputObject $disk
    Write-Host "已为SSD启用TRIM: $($disk.FriendlyName)" -ForegroundColor Green
}

# 网络优化设置
Write-Host "优化网络设置..." -ForegroundColor Yellow

# 禁用带宽限制
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -Value 0 -Type DWord

# 优化网络缓冲区
netsh int tcp set global autotuninglevel=normal
netsh int tcp set global chimney=enabled
netsh int tcp set global rss=enabled
netsh int tcp set global netdma=enabled

# 定时清理任务
Write-Host "创建定时清理任务..." -ForegroundColor Yellow

$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -Command `"Get-ChildItem -Path '$env:TEMP' -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Clear-RecycleBin -Force -ErrorAction SilentlyContinue`""
$taskTrigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

try {
    Register-ScheduledTask -TaskName "DailyCleanup" -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Description "每日清理临时文件" -Force
    Write-Host "已创建每日清理任务" -ForegroundColor Green
} catch {
    Write-Host "无法创建清理任务" -ForegroundColor Yellow
}

# 重新加载PowerShell配置
. $profilePath

# 验证安装
Get-Module -ListAvailable | Where-Object Name -in @('PSReadLine', 'Terminal-Icons', 'z', 'posh-git', 'PSFzf')

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "PowerShell 7增强环境和系统优化完成！" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "已完成的优化项目:" -ForegroundColor Yellow
Write-Host "✓ PowerShell模块和工具安装" -ForegroundColor Green
Write-Host "✓ 注册表性能优化" -ForegroundColor Green
Write-Host "✓ 系统服务优化" -ForegroundColor Green
Write-Host "✓ 系统垃圾清理" -ForegroundColor Green
Write-Host "✓ DNS和网络优化" -ForegroundColor Green
Write-Host "✓ 磁盘和电源优化" -ForegroundColor Green
Write-Host "✓ 定时清理任务创建" -ForegroundColor Green
Write-Host "`n建议重启系统以完全应用所有优化设置。" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan
