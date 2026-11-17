<#
.SYNOPSIS
  Wake-on-LAN のマジックパケットを送り、(設定があれば) RDP接続可能になるまで監視してトースト通知する。
.PARAMETER Name
  config.ini のセクション名。省略時は最初のセクション。
.PARAMETER Config
  設定ファイルのパス。省略時はスクリプトと同じフォルダの config.ini。
#>
param(
    [string]$Name,
    [string]$Config = (Join-Path $PSScriptRoot "config.ini")
)

function Read-Ini($path) {
    $ini = [ordered]@{};
    $section = $null;
    foreach ($line in Get-Content $path -Encoding UTF8) {
        $line = $line.Trim();
        if ($line -eq "" -or $line.StartsWith(";") -or $line.StartsWith("#")) { continue }
        if ($line -match '^\[(.+)\]$') {
            $section = $Matches[1].Trim();
            $ini[$section] = @{};
        } elseif ($section -and $line -match '^([^=]+)=(.*)$') {
            $ini[$section][$Matches[1].Trim()] = $Matches[2].Trim();
        }
    }
    return $ini;
}

function Show-Toast($message) {
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime];
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime];
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument;
    $safe = [System.Security.SecurityElement]::Escape($message);
    $xml.LoadXml("<toast><visual><binding template=`"ToastGeneric`"><text>$safe</text></binding></visual></toast>");
    $appId = "WakeOnLan";
    $reg = "HKCU:\Software\Classes\AppUserModelId\$appId";
    if (-not (Test-Path $reg)) { New-Item $reg -Force | Out-Null }
    New-ItemProperty $reg -Name DisplayName -Value "WakeOnLan" -PropertyType String -Force | Out-Null;
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show([Windows.UI.Notifications.ToastNotification]::new($xml));
}

function Get-Setting($section, $key, $default) {
    if ($section.ContainsKey($key) -and $section[$key] -ne "") { return $section[$key] }
    return $default;
}

if (-not (Test-Path $Config)) {
    Write-Error "設定ファイルが見つかりません: $Config (config.ini.example をコピーして作成してください)";
    exit 1;
}
$ini = Read-Ini $Config;
if ($ini.Count -eq 0) { Write-Error "設定ファイルにセクションがありません: $Config"; exit 1 }
if (-not $Name) { $Name = @($ini.Keys)[0] }
if (-not $ini.Contains($Name)) { Write-Error "セクション [$Name] が $Config にありません"; exit 1 }
$s = $ini[$Name];

# --- マジックパケット送信 ---
$mac = Get-Setting $s "Mac" "";
if ($mac -eq "") { Write-Error "[$Name] に Mac が指定されていません"; exit 1 }
$macAddr = [byte[]]($mac -split "[-:]" | ForEach-Object { [Convert]::ToInt32($_, 16) });
if ($macAddr.Length -ne 6) { Write-Error "Mac の形式が不正です: $mac"; exit 1 }
$magicPacket = ([byte[]](@(0xff) * 6)) + $macAddr * 16;
$broadcast = [System.Net.IPAddress]::Parse((Get-Setting $s "Broadcast" "255.255.255.255"));
$port = [int](Get-Setting $s "Port" "9");
$udpClient = New-Object System.Net.Sockets.UdpClient;
$udpClient.Connect($broadcast, $port);
$udpClient.Send($magicPacket, $magicPacket.Length) | Out-Null;
$udpClient.Close();
Write-Output "Send MagicPacket. ($Name)";

# --- RDP接続可能になるまで監視 ---
$rdpHost = Get-Setting $s "RdpHost" "";
if ($rdpHost -eq "") { exit 0 }
$rdpPort = [int](Get-Setting $s "RdpPort" "3389");
$timeoutSec = [int](Get-Setting $s "RdpTimeoutSec" "60");
$displayName = Get-Setting $s "DisplayName" $Name;

$start = Get-Date;
while (((Get-Date) - $start).TotalSeconds -lt $timeoutSec) {
    $client = New-Object System.Net.Sockets.TcpClient;
    try {
        $async = $client.BeginConnect($rdpHost, $rdpPort, $null, $null);
        if ($async.AsyncWaitHandle.WaitOne(1000) -and $client.Connected) {
            $client.EndConnect($async);
            $client.Close();
            $sec = [int]((Get-Date) - $start).TotalSeconds;
            Show-Toast "OK RDP接続できます（${displayName}・${sec}秒）";
            exit 0;
        }
    } catch {}
    $client.Close();
    Start-Sleep -Seconds 1;
}
Show-Toast "RDP接続を確認できませんでした（${displayName}・${timeoutSec}秒）";
exit 1;
