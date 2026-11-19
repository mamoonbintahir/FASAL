# Windows/PowerShell version of tool/setup_platforms.sh.
# Generates android/ and ios/ (only missing files; lib/ is never touched) and
# applies the native tweaks FASAL needs.
#
#   powershell -ExecutionPolicy Bypass -File tool\setup_platforms.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

flutter create . --project-name fasal --org pk.fasal --platforms android,ios
if ($LASTEXITCODE -ne 0) { throw 'flutter create failed' }

$utf8 = New-Object System.Text.UTF8Encoding($false)   # write without BOM

$manifest = 'android\app\src\main\AndroidManifest.xml'
if (Test-Path -LiteralPath $manifest) {
    $xml = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $manifest), $utf8)

    # 1) App name under the launcher icon
    $xml = $xml.Replace('android:label="fasal"', 'android:label="Fasal"')

    # 2) Android 11+: let flutter_tts find the text-to-speech engine
    if ($xml -notmatch 'android.intent.action.TTS_SERVICE') {
        $tts = "        <intent>`n            <action android:name=`"android.intent.action.TTS_SERVICE`" />`n        </intent>`n"
        if ($xml.Contains('</queries>')) {
            $xml = $xml.Replace('</queries>', "$tts    </queries>")
        } else {
            $xml = $xml.Replace('</manifest>', "    <queries>`n$tts    </queries>`n</manifest>")
        }
    }

    # 3) Internet access for the FASAL server (release builds)
    if ($xml -notmatch 'android.permission.INTERNET') {
        $open = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
        $xml = $xml.Replace($open, "$open`n    <uses-permission android:name=`"android.permission.INTERNET`" />")
    }
    [IO.File]::WriteAllText((Resolve-Path -LiteralPath $manifest), $xml, $utf8)
    Write-Host 'OK  AndroidManifest patched (label, TTS query, internet)'
}

# Debug builds only: allow plain HTTP so the emulator/phone can reach a local server.
$debugManifest = 'android\app\src\debug\AndroidManifest.xml'
if (Test-Path -LiteralPath $debugManifest) {
    $xml = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $debugManifest), $utf8)
    if ($xml -notmatch 'usesCleartextTraffic') {
        $xml = $xml.Replace('</manifest>', "    <application android:usesCleartextTraffic=`"true`" />`n</manifest>")
        [IO.File]::WriteAllText((Resolve-Path -LiteralPath $debugManifest), $xml, $utf8)
        Write-Host 'OK  Debug manifest allows local HTTP'
    }
}

# `flutter create` adds a counter-app sample test if none exists - remove it.
$sample = 'test\widget_test.dart'
if ((Test-Path -LiteralPath $sample) -and (Select-String -LiteralPath $sample -Pattern 'MyApp' -Quiet)) {
    Remove-Item -LiteralPath $sample
    Write-Host 'OK  Removed template test\widget_test.dart'
}

Write-Host 'Done. Next: flutter pub get; flutter run'
