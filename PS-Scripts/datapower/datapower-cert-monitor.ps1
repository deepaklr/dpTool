# Author: deepak ramabhat - deepaklr@in.ibm.com,deepaklr@outlook.com
# History: 8-1-21 - 1.0 - Initial
# Script monitors the datapower for all the certificate objects and if any certificate is found to be expiring, it will trigger an email with details
# 
# Dependency: dpTool service - deployed & configured on any one device - https://github.com/deepaklr/dpTool
#
# Usage : .\datapower-cert-monitor
#        Before running - edit this file to set following variables
#        Line 14 & 15 - pass datapower credentials if security is enabled on the dpTool service
#        Line 21 - pass URLs to monitor
#        Line 135 : SMPT serve IP and email subject/from details
#
#------------------------------------------------------------------------------------------------------

$datapower_loginid="USER01"
$datapower_password="PASSWORD01"

$Credential = [System.Management.Automation.PSCredential]::new($datapower_loginid,(ConvertTo-SecureString $datapower_password -AsPlainText -Force))

#provide certificate monitoring URL for each device in your env
$urls=@('https://127.0.0.1:8008/dpTool/cert/?device=DEV-GW',
        'https://127.0.0.1:8008/dpTool/cert/?device=INT-GW',
        'https://127.0.0.1:8008/dpTool/cert/?device=MO-GW1',
        'https://127.0.0.1:8008/dpTool/cert/?device=MO-GW2',
        'https://127.0.0.1:8008/dpTool/cert/?device=STG-GW',
        'https://127.0.0.1:8008/dpTool/cert/?device=PROD-GW1',
        'https://127.0.0.1:8008/dpTool/cert/?device=PROD-GW2')

#provide email ids to notify
$alert_days=30

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

$event_found=0

foreach($url in $urls){
    
    $device=$url.substring($url.IndexOf("=")+1)

    write-output $device

    [String]$body=Invoke-WebRequest -Credential $Credential -Uri $url -Method Get -TimeoutSec 30
    $body=$body.replace("`n","")
    $body=$body.replace("<TR>","`r`n<TR>")

    write-output $body | Out-File temp.txt

    $rows=$body | Select-String '<TR>(.*)</TR>' -AllMatches
    foreach($row in Get-Content temp.txt){

        #$cells=$row | Select-String '<TD>(.*)</TD>' -AllMatches
        $row_s=$row.replace("<TD>","")

        $cells=$row_s -split "</TD>"

        if( $cells.Length -ge 7 -and $cells[7] -ne "Valid Till"){
            $dt_str=$cells[7].substring(0,20)
            $dt=[datetime]::ParseExact($dt_str,'dd MMM yyyy HH:mm:ss', $null)
            $today=Get-Date

            $diff=New-TimeSpan -Start $today -End $dt

            #write-output $dt $diff.Days

            if($diff.days -le $alert_days){

                if($event_found -eq 0){
                
                    Write-Output '<HTML xmlns:dyn="http://exslt.org/dynamic"><head><meta content="text/html; charset=UTF-8" http-equiv="Content-Type"><title>Cert Monitor</title><style type="text/css">
					    .labels,body,table,tr,td,th{
						    FONT-SIZE: 10pt; MARGIN: 1px; COLOR: BLACK;FONT-STYLE:normal;text-align:left;white-space:nowrap;min-width:100px;
						    FONT-FAMILY: Calibri,verdana,helvetica,arial,sans-serif;
						    border:.5pt solid #8EA9DB;
						    border-collapse:collapse;
						    height:15.0pt;padding:4px;
					    }
					    tr.red, tr.oth{
						    FONT-SIZE: 10pt; MARGIN: 0px; COLOR: BLACK;FONT-STYLE:bold;background-color:cyan;text-align:left;white-space:nowrap;	
						    FONT-FAMILY: Calibri,verdana,helvetica,arial,sans-serif;
						    border:1px solid #1fffff;
						    cursor:pointer;
						    display:table-row;
						    background-color:#9abbbb;
						    height:15.0pt;padding:4px;
					    }
					    a { FONT-SIZE: 10pt; MARGIN: 0px; COLOR: BLACK;FONT-STYLE:normal;text-align:left;text-decoration:none;
						    FONT-FAMILY: Calibri,verdana,helvetica,arial,sans-serif; }

					    span.icn{ FONT-FAMILY: webdings;white-space:nowrap;FONT-SIZE: 14pt;}
					
					    td.err {FONT-SIZE: 11pt; MARGIN: 0px; COLOR: red;FONT-STYLE:bold;}
					    th {background-color:#9abbbb}
				    </style></head><h4>Datapower Certificate EXPIRY IN NEXT 30 DAYS</h4><table>
    <tr><th>Device</th><th>Days to Expiry</th><th>Domain</th><th>File</th><th>Crypto Cert</th><th>Issued To</th>
    <th>Issuer</th><th>Version</th><th>Valid from</th><th>Valid Till</th><th>Serial #</th><th>Type</th></tr>' | out-file cert-mon-mail.html -Force

                }

                $row=$row.replace("<TR>","")
                $row=$row.replace("</TR>","")

                 Write-Output "<TR><TD>$($device)</TD><TD>$($diff.Days)</TD>$($row)</TR>" | out-file cert-mon-mail.html -Append
                $event_found=1
            }
        }
    }

    
}



if($event_found -eq 1){
    Write-Output '</TABLE></HTML>' | out-file cert-mon-mail.html -Append

    #Start-Process -FilePath "D:\CXT_Monitor\jre7\bin\java" -ArgumentList '-cp', '.;D:\CXT_Monitor\lib\*;', '-Djava.net.preferIPv6Stack=true',"EMailer ""D:\DP-Monitor\cert-mon-mail.html"" ""$($emails)"" ""[DPMONITOR] Certificates Expiring in 30 days  - "" " -RedirectStandardOutput '.\mailer_cert.log' -RedirectStandardError '.\mailer_cert.err.log'

    $emails="deepaklr@in.ibm.com,deepaklr@outlook.com"

    $params = @{
    To = "$($emails)"
    From = “DP-Automation<deepaklr@in.ibm.com>”
    SMTPServer = “theIP”
    Subject = “[DPMONITOR] Certificates Expiring in 30 days”
    BodyAsHTML = $true
    Body = Get-Content ".\cert-mon-mail.html"
    }

    Send-MailMessage @params
}

