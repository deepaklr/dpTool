# Author: deepak ramabhat - deepaklr@in.ibm.com,deepaklr@outlook.com
# History: 11-3-21 - 1.0 - Initial
# Script captures cpu usage of the given device, schedule to run at every 10 minutes or so to capture continuous usage
# Output file format - comma separated: 
# local-time,datapower-time,cpu-last-10s,cpu-last-1m,cpu-last-10m,cpu-last-1h,cpu-last-1d
#
# Usage : ./monitor-cpu <datapower-xmi-url> <login-id> <password> <output gfile name>
#
#      Example: ./monitor-cpu https://127.0.0.1:5550/service/mgmt/current admin admin ".\dev-esb-cpu.csv"
#------------------------------------------------------------------------------------------------------


$datapower_xmi_url=$args[0]
$datapower_login_id=$args[1]
$datapower_login_password=$args[2]

if($datapower_xmi_url -eq $null -or $datapower_login_id -eq $null -or $datapower_login_password -eq $null -or $args[3] -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}


$bytes = [System.Text.Encoding]::ASCII.GetBytes($datapower_login_id + ":" + $datapower_login_password)
$base64 = [System.Convert]::ToBase64String($bytes)
$AUTH = "Basic $base64"
#write-output $AUTH $datapower_xmi_url

$Body = '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
   <env:Body>
      <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="default">
         <dp:get-status class="CPUUsage"/>
      </dp:request>
   </env:Body>
</env:Envelope>'

   add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#Write-Output $Body

$headers = @{ Authorization = $AUTH }
$resp=Invoke-WebRequest -Uri $datapower_xmi_url -Headers $headers  -Method Post -Body $Body -ContentType text/xml 

$resp.Content | Out-File ".\temp-cpu.xml" -Force

if($resp.StatusCode -eq 200){
    [xml] $respXML = $resp.Content

 
    $dt=select-xml -Xml $respXML -XPath "//dp:timestamp" -Namespace @{dp="http://www.datapower.com/schemas/management"}
    $10s=select-xml -Xml $respXML -XPath "//tenSeconds" -Namespace @{dp="http://www.datapower.com/schemas/management"}
    $1m=select-xml -Xml $respXML -XPath "//oneMinute" -Namespace @{dp="http://www.datapower.com/schemas/management"}
    $10m=select-xml -Xml $respXML -XPath "//tenMinutes" -Namespace @{dp="http://www.datapower.com/schemas/management"}
    $1h=select-xml -Xml $respXML -XPath "//oneHour" -Namespace @{dp="http://www.datapower.com/schemas/management"}
    $1d=select-xml -Xml $respXML -XPath "//oneDay" -Namespace @{dp="http://www.datapower.com/schemas/management"}

    $line="$(get-date),$($dt),$($10s),$($1m),$($10m),$($1h),$($1d)`n"
    write-output $line | Out-File -FilePath $args[3] -Append
    Write-Output $line
}
