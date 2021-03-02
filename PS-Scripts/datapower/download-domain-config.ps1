# Author: deepak ramabhat - deepaklr@in.ibm.com,deepaklr@outlook.com
# History: 8-1-21 - 1.0 - Initial
# Script downloads datapower configuration for a given device/domain and zips the file
# Usage : ./download-domain-config <datapower-xmi-url> <login-id> <password> <domain name>
#
#      Example: ./download-domain-config https://127.0.0.1:5550/service/mgmt/current admin admin POC-Domain
#------------------------------------------------------------------------------------------------------


$datapower_xmi_url=$args[0]
$datapower_login_id=$args[1]
$datapower_login_password=$args[2]
$datapower_domain=$args[3]

if($datapower_xmi_url -eq $null -or $datapower_login_id -eq $null -or $datapower_login_password -eq $null -or $datapower_domain -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}


$bytes = [System.Text.Encoding]::ASCII.GetBytes($datapower_login_id + ":" + $datapower_login_password)
$base64 = [System.Convert]::ToBase64String($bytes)
$AUTH = "Basic $base64"
#write-output $AUTH $datapower_xmi_url

$Body = '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
   <env:Body>
      <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="' + $($datapower_domain) + '">
         <dp:get-config/>
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

$resp.Content | Out-File ".\export.xml" -Force

if($resp.StatusCode -eq 200){
    $fname=".\$($datapower_domain)-$((get-date -Format "ddMMyy-HHmmssfff").ToString()).zip"
    Compress-Archive -path ".\export.xml" -DestinationPath $fname -force
 
    Write-Output "Output file $fname"
}
