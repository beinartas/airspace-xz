$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$port = 8767
$prefix = "http://localhost:$port/"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $root "index.html"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "AIRSPACE XY+XZ SERVER RUNNING AT $prefix" -ForegroundColor Yellow
Write-Host "Press Ctrl+C or close this window to stop." -ForegroundColor DarkGray

Start-Process $prefix

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response
        try {
            $path = $req.Url.AbsolutePath
            if ($path -eq "/" -or $path -eq "/index.html") {
                $bytes = [System.IO.File]::ReadAllBytes($indexPath)
                $res.ContentType = "text/html; charset=utf-8"
                $res.StatusCode = 200
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            elseif ($path -eq "/countries-50m.json" -or $path -eq "/airports.json") {
                $fileName = $path.TrimStart("/")
                $mapPath = Join-Path $root $fileName
                if (-not (Test-Path $mapPath) -and $fileName -eq "countries-50m.json") {
                    $mapPath = Join-Path (Split-Path -Parent $root) "airspace-radar\countries-50m.json"
                }
                if (Test-Path $mapPath) {
                    $bytes = [System.IO.File]::ReadAllBytes($mapPath)
                    $res.ContentType = "application/json; charset=utf-8"
                    $res.StatusCode = 200
                    $res.ContentLength64 = $bytes.Length
                    $res.OutputStream.Write($bytes, 0, $bytes.Length)
                } else { $res.StatusCode = 404 }
            }
            elseif ($path -eq "/api/adsb") {
                $lat = $req.QueryString["lat"]
                $lon = $req.QueryString["lon"]
                $dist = $req.QueryString["dist"]
                $ts = (Get-Date).ToString("HH:mm:ss")
                $url = "https://api.adsb.lol/v2/lat/$lat/lon/$lon/dist/$dist"
                try {
                    $wc = New-Object System.Net.WebClient
                    $wc.Encoding = [System.Text.Encoding]::UTF8
                    $wc.Headers.Add("User-Agent", "AirspaceXYXZ/1.0")
                    $json = $wc.DownloadString($url)
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $res.ContentType = "application/json; charset=utf-8"
                    $res.Headers.Add("Cache-Control", "no-store")
                    $res.StatusCode = 200
                    $res.ContentLength64 = $bytes.Length
                    $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    Write-Host "[$ts] 200 $url ($($bytes.Length) bytes)" -ForegroundColor DarkGreen
                } catch {
                    Write-Host "[$ts] 502 UPSTREAM ERROR: $($_.Exception.Message)" -ForegroundColor Red
                    $res.StatusCode = 502
                }
            } else { $res.StatusCode = 404 }
        } catch {
            $res.StatusCode = 500
        } finally {
            try { $res.OutputStream.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
