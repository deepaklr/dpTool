#Enter your user id and password
$userid="JOKER"
$password="JOKER"

$bytes = [System.Text.Encoding]::ASCII.GetBytes($userid + ":" + $password)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
Write-Output $basicAuthValue


