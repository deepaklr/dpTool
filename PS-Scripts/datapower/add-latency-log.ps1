# Author: deepak ramabhat - deepaklr@in.ibm.com,deepaklr@outlook.com
# History: 8-1-21 - 1.0 - Initial
# Script Adds latency log target on the given device/domain, provide FTP sever details in the below section
#
# Usage : ./add-latency-log <datapower-xmi-url> <login-id> <password> <domain names;comma separated>
#
#      Example: ./add-latency-log https://127.0.0.1:5550/service/mgmt/current admin admin "POC-Domain,apigw"
#------------------------------------------------------------------------------------------------------

#Enter FTP details where logs need to be rolled off

$device="non-prod"
$ftp_server = "127.0.0.1"
$ftp_login = "ftpuser"
$ftp_password = "ftppassword"
$ftp_path="/%2Froot/dplogs/latency"
#--------------------------------------------------

$datapower_xmi_url=$args[0]
$datapower_login_id=$args[1]
$datapower_login_password=$args[2]
$datapower_domains=$args[3]

if($datapower_xmi_url -eq $null -or $datapower_login_id -eq $null -or $datapower_login_password -eq $null -or $datapower_domains -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}

$datapower_domains=$args[3].split(",")


$bytes = [System.Text.Encoding]::ASCII.GetBytes($datapower_login_id + ":" + $datapower_login_password)
$base64 = [System.Convert]::ToBase64String($bytes)
$AUTH = "Basic $base64"
$headers = @{ Authorization = $AUTH }


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

foreach($domain in $datapower_domains){

    $Body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
     <soapenv:Body>
       <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="' + $($domain) + '">
         <dp:set-config>
     
                <LogTarget name="LatencyMetricsLogTarget" xmlns:env="http://www.w3.org/2003/05/soap-envelope">
                   <mAdminState>enabled</mAdminState>
                   <UserSummary>Application Log</UserSummary>
                   <Type>file</Type>
                   <Priority>normal</Priority>
                   <SoapVersion>soap11</SoapVersion>
                   <Format>text</Format>
                   <TimestampFormat>syslog</TimestampFormat>
                   <FixedFormat>off</FixedFormat>
                   <Size>2048</Size>
                   <LocalFile>logstore:///' + $($domain) + '-LatencyMetrics-' + $($device) + '.log</LocalFile>
                   <ArchiveMode>upload</ArchiveMode>
                   <UploadMethod>ftp</UploadMethod>
                   <Rotate>3</Rotate>
                   <UseANSIColor>off</UseANSIColor>
                   <RemoteAddress>' + $($ftp_server) + '</RemoteAddress>
                   <RemotePort>21</RemotePort>
                   <RemoteLogin>' + $($ftp_login) + '</RemoteLogin>
                   <RemotePassword>' + $($ftp_password) + '</RemotePassword>
                   <RemoteDirectory>' + $($ftp_path) +'</RemoteDirectory>
                   <SyslogFacility>user</SyslogFacility>
                   <RateLimit>100</RateLimit>
                   <ConnectTimeout>60</ConnectTimeout>
                   <IdleTimeout>15</IdleTimeout>
                   <ActiveTimeout>0</ActiveTimeout>
                   <FeedbackDetection>off</FeedbackDetection>
                   <IdenticalEventSuppression>off</IdenticalEventSuppression>
                   <IdenticalEventPeriod>10</IdenticalEventPeriod>
                   <SSLClientConfigType>proxy</SSLClientConfigType>
                   <RetryInterval>1</RetryInterval>
                   <RetryAttempts>1</RetryAttempts>
                   <LongRetryInterval>20</LongRetryInterval>
                   <LogPrecision>second</LogPrecision>
                   <LogEvents>
                      <Class class="LogLabel">latency</Class>
                      <Priority>info</Priority>
                   </LogEvents>
                </LogTarget>
          </dp:set-config>
        </dp:request>
      </soapenv:Body>
    </soapenv:Envelope>'


    #Write-Output $Body

    try{
        $resp=Invoke-WebRequest -Headers $headers -Uri $datapower_xmi_url -Method Post -Body $Body -ContentType text/xml
        write-output "Success: $($domain)"  $resp.Content
    }
    catch{
        write-output "Error: $($domain) $($_)" 
    }
}
