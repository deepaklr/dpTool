##
# Reboots given set of devices after quiescing all domains and disabling any domains if required
# Once device is rebooted, it will enable all disabled domains
# Set EMAIL properties within the script as initial setup
#
# Arguments
# <deviceListFile> : Required. File path containing List of datapower console IPs which needs to be rebooted
#                    Syntax of the file entries: device-ip,llgin-id,login-password
# [domainListFile] : Optional. File path containing List of domains that needs to be disabled before rebooting
#                    Syntax of the file entries: domain-name list (on each line)
# [EnvName] : Optional. Provide env name for logging/status mail
#
#  Example: .\datapower-reboot "c:\reboot\prod-devices.txt" "c:\reboot\prod-domains.txt" "PROD"
#
# Author: deepaklr@in.ibm.com, deepaklr@outlook.com
# v1.0

#Email listing to send the status - if its empty no emails will be sent
$emails="deepaklr@in.ibm.com"

$deviceFile=$args[0]
$domainFile=$args[1]
$envname=$args[2]

if($deviceFile -eq $null){
    write-output "Device List argument not passed."
    exit
}

if($envname -eq $null){
    $envname=$deviceFile.ToString().Replace('.txt','')
}


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


Write-Output "Start: $(Get-Date)"

$mailFile="Reboot-mail-$($envname).html"
$error_st=0
$partial_st=0
$trial_run=1

Write-Output '<HTML><head><meta content="text/html; charset=UTF-8" http-equiv="Content-Type"><title>DP Reboot</title><style type="text/css">
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
				    </style></head><h4>Datapower Reboot Status </h4><table>
    <tr><th>Device</th><th>Step</th><th>Status</th><th>Log</th></tr>' | out-file $mailFile -Force


foreach($line in Get-Content $deviceFile){
    
    if($line.ToString().startsWith("#") -eq $False){
        
        $flds=$line.split(",")

        if($flds.Length -le 2) {
            write-output "Device List file is inavlid.."
            exit
        }
        $url="https://$($flds[0]):5550/service/mgmt/amp/3.0"
        $url2="https://$($flds[0]):5550/service/mgmt/amp/1.0"

        $bytes = [System.Text.Encoding]::ASCII.GetBytes( $flds[1] + ":" +  $flds[2])
        $base64 = [System.Convert]::ToBase64String($bytes)

        $AUTH="Basic $base64"
        $headers = @{ Authorization = $AUTH }

        $quiesce='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.datapower.com/schemas/appliance/management/3.0">
                   <soapenv:Header/>
                   <soapenv:Body>
                      <ns:QuiesceRequest>
                         <ns:Device>
                            <ns:Timeout>10</ns:Timeout>
                         </ns:Device>
                      </ns:QuiesceRequest>
                   </soapenv:Body>
                </soapenv:Envelope>'

        write-output "Quiescing device $($url)" 

        $ns=@{amp="http://www.datapower.com/schemas/appliance/management/3.0"}

        $quiesceStatus=0

        try{
            if($trial_run -eq 0){
                $resp=Invoke-WebRequest -Headers $headers -Uri $url -Method Post -Body $quiesce -ContentType text/xml
                [xml]$respXML=$resp.Content

            } else {
             [xml]$respXML='<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
                           <env:Body>
                              <dp:response xmlns:dp="http://www.datapower.com/schemas/management">
                                 <dp:timestamp>2020-09-17T06:42:09-04:00</dp:timestamp>
                                 <result>OK</result>
                              </dp:response>
                           </env:Body>
                        </env:Envelope>' 

            }

            $result=Select-XML -Xml $respXML -XPath "//result" -Namespace $ns
            if($result.ToString().ToUpper() -eq "OK"){
                write-output "Quiesce Success"
                $quiesceStatus=1

                write-output "<tr><td>$($flds[0])</td><td>Quiesce</td><td>Success</td><td>$((get-date).ToString())</td></tr>" | out-file $mailFile -Append
            } else{
                write-output "Quiesce Failed:[ $($result) ] $($resp)"
                write-output "<tr><td>$($flds[0])</td><td>Quiesce</td><td>Failed</td><td>$((get-date).ToString()) - $($result)</td></tr>" | out-file $mailFile -Append
                $error_st=1
            }
        }
        catch{
            write-output "Quiesce Request Failed: $($resp) $($_)" 
            write-output "<tr><td>$($flds[0])</td><td>Quiesce</td><td>Error</td><td>$((get-date).ToString()) - $($resp) - $($_)</td></tr>" | out-file $mailFile -Append
            $error_st=1
        }

        $ns2=@{amp="http://www.datapower.com/schemas/appliance/management/1.0"}

        #disable given domains
        if($quiesceStatus -eq 1){
            
            write-output "Waiting for 30 seconds..."
            Start-Sleep -Seconds 30

            foreach($line1 in Get-Content $domainFile){

                $disDomain='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.datapower.com/schemas/appliance/management/1.0">
                           <soapenv:Header/>
                           <soapenv:Body>
                              <ns:StopDomainRequest>
                                 <ns:Domain>_DOMAIN_</ns:Domain>
                              </ns:StopDomainRequest>
                           </soapenv:Body>
                        </soapenv:Envelope>'
                $disDomain_req=$disDomain.Replace("_DOMAIN_",$line1)
                #Write-Output $disDomain_req

                try{
                    if($trial_run -eq 0){
                        $resp=Invoke-WebRequest -Headers $headers -Uri $url2 -Method Post -Body $disDomain_req -ContentType text/xml
                        [xml]$respXML=$resp.Content
                    } else {
                     [xml]$respXML='<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:amp="http://www.datapower.com/schemas/appliance/management/1.0">
                                   <env:Body>
                                      <dp:response xmlns:dp="http://www.datapower.com/schemas/management">
                                         <dp:timestamp>2020-09-17T06:42:09-04:00</dp:timestamp>
                                         <amp:Status>OK</amp:Status>
                                      </dp:response>
                                   </env:Body>
                                </env:Envelope>'
                     }

                    $result=Select-XML -Xml $respXML -XPath "//amp:Status" -Namespace $ns2
                    if($result.ToString().ToUpper() -eq "OK"){
                        write-output "Domain $($line1) Disabled"
                        write-output "<tr><td>$($flds[0])</td><td>Disable Domain $($line1)</td><td>Success</td><td></td></tr>" | out-file $mailFile -Append
                    } else{
                        write-output "Domain $($line1) Failed to disable:[ $($result) ] $($resp)"
                        write-output "<tr><td>$($flds[0])</td><td>Disable Domain $($line1)</td><td>Failed</td><td>$($result)</td></tr>" | out-file $mailFile -Append
                        $partial_st=1
                    }
                }
                catch{
                    write-output "Domain $($line1) disable request failed: $($resp) $($_)"
                    write-output "<tr><td>$($flds[0])</td><td>Disable Domain $($line1)</td><td>Error</td><td>$($resp) - $($_)</td></tr>" | out-file $mailFile -Append 
                    $partial_st=1
                }

            }
        }


        #continue with reboot
        $rebootStatus=0
        if($quiesceStatus -eq 1){

            write-output "Rebooting device $($url)" 

            $reboot='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.datapower.com/schemas/appliance/management/3.0">
                   <soapenv:Header/>
                   <soapenv:Body>
                      <ns:RebootRequest>
                         <ns:Mode>reboot</ns:Mode>
                      </ns:RebootRequest>
                   </soapenv:Body>
                </soapenv:Envelope>'

            try{
                if($trial_run -eq 0){
                    $resp=Invoke-WebRequest -Headers $headers -Uri $url -Method Post -Body $reboot -ContentType text/xml
                    [xml]$respXML=$resp.Content
                } else {
                    [xml]$respXML='<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:amp="http://www.datapower.com/schemas/appliance/management/3.0">
                               <env:Body>
                                  <dp:response xmlns:dp="http://www.datapower.com/schemas/management">
                                     <dp:timestamp>2020-09-17T06:42:09-04:00</dp:timestamp>
                                     <amp:Status>OK</amp:Status>
                                  </dp:response>
                               </env:Body>
                            </env:Envelope>'
                }
                $result=Select-XML -Xml $respXML -XPath "//amp:Status" -Namespace $ns
                if($result.ToString().ToUpper() -eq "OK"){
                    write-output "Rebooting Successfully Initialised"
                     $rebootStatus=1
                    write-output "<tr><td>$($flds[0])</td><td>Reboot</td><td>Initialised</td><td>$((get-date).ToString())</td></tr>" | out-file $mailFile -Append 
                } else{
                    write-output "Rebooting Failed:[ $($result) ] $($resp)"
                    write-output "<tr><td>$($flds[0])</td><td>Reboot</td><td>Failed</td><td>$($result)</td></tr>" | out-file $mailFile -Append 
                    $error_st=1
                }
            }
            catch{
                write-output "Rebooting Request Failed: $($resp) $($_)" 
                write-output "<tr><td>$($flds[0])</td><td>Reboot</td><td>Error</td><td>$($resp) - $($_)</td></tr>" | out-file $mailFile -Append 
                $error_st=1
            }

        }

        #continue with enabling domains
        if($rebootStatus -eq 1){

            for($i=1; $i -le 1; $i++){
                write-output "Waiting for 1 minute.."
                Start-Sleep -Seconds 60

                $chkStatus='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.datapower.com/schemas/appliance/management/1.0">
                           <soapenv:Header/>
                           <soapenv:Body>
                              <ns:GetDeviceInfoRequest/>
                           </soapenv:Body>
                        </soapenv:Envelope>'


                try{
                    $resp=Invoke-WebRequest -Headers $headers -Uri $url2 -Method Post -Body $chkStatus -ContentType text/xml
                    [xml]$respXML=$resp.Content

                    $result=Select-XML -Xml $respXML -XPath "//amp:DeviceID" -Namespace $ns2
                    if($result.ToString().Length -gt 0){
                       write-output "Device Rebooted"
                       write-output "<tr><td>$($flds[0])</td><td>Reboot</td><td>Complete</td><td>$((get-date).ToString())</td></tr>" | out-file $mailFile -Append
                       break
                    }
                }
                catch{
                    write-output "Device still not up (try $($i)): $($_)" 
                }

            }

            foreach($line1 in Get-Content $domainFile){

                $disDomain='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.datapower.com/schemas/appliance/management/1.0">
                           <soapenv:Header/>
                           <soapenv:Body>
                              <ns:StartDomainRequest>
                                 <ns:Domain>_DOMAIN_</ns:Domain>
                              </ns:StartDomainRequest>
                           </soapenv:Body>
                        </soapenv:Envelope>'
                $disDomain_req=$disDomain.Replace("_DOMAIN_",$line1)
                #Write-Output $disDomain_req

                try{
                    if($trial_run -eq 0){
                        $resp=Invoke-WebRequest -Headers $headers -Uri $url2 -Method Post -Body $disDomain_req -ContentType text/xml
                        [xml]$respXML=$resp.Content
                    } else {
                         [xml]$respXML='<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:amp="http://www.datapower.com/schemas/appliance/management/1.0">
                                   <env:Body>
                                      <dp:response xmlns:dp="http://www.datapower.com/schemas/management">
                                         <dp:timestamp>2020-09-17T06:42:09-04:00</dp:timestamp>
                                          <amp:Status>error</amp:Status>
                                      </dp:response>
                                   </env:Body>
                                </env:Envelope>'
                    }

                    $result=Select-XML -Xml $respXML -XPath "//amp:Status" -Namespace $ns2
                    if($result.ToString().ToUpper() -eq "OK"){
                        write-output "Domain $($line1) Enabled"
                        write-output "<tr><td>$($flds[0])</td><td>Enable Domain $($line1)</td><td>Success</td><td>$((get-date).ToString())</td></tr>" | out-file $mailFile -Append

                    } else{
                        write-output "Domain $($line1) Failed to enable:[ $($result) ] $($resp)"
                        write-output "<tr><td>$($flds[0])</td><td>Enable Domain $($line1)</td><td>Failed</td><td>$($($result))</td></tr>" | out-file $mailFile -Append
                        $partial_st=1
                    }
                }
                catch{
                    write-output "Domain $($line1) enable request failed: $($resp) $($_)" 
                    write-output "<tr><td>$($flds[0])</td><td>Enable Domain $($line1)</td><td>Error</td><td>$($_)</td></tr>" | out-file $mailFile -Append
                    $partial_st=1
                }

            }

         }

    }

}

if($emails.Length -gt 3){
    Write-Output '</TABLE></HTML>' | out-file $mailFile -Append
    $finalSt="Success"
    if($partial_st -ge 1){ $finalSt = "Partial"}
    if($error_st -ge 1){ $finalSt = "Error"}

    #Start-Process -FilePath "C:\Program Files (x86)\Java\jre1.8.0_211\bin\java" -ArgumentList '-cp', '.;C:\Users\dramabha\UTIL\XMI\reboot\lib\*;', '-Djava.net.preferIPv6Stack=true','-Dmail.smtp.host=10.201.0.1','-Dmail.smtp.port=2500','-Dmail.from=Test-DP-Scripts<noreply@ibm.com>',"EMailer "".\$($mailFile)"" ""$($emails)"" ""[$($finalSt)] Weekly Datapower Reboot of $($envname) - $(get-date) "" " -RedirectStandardOutput '.\mailer_cert.log' -RedirectStandardError '.\mailer_cert.err.log'
    
    $params = @{
    To = "$($emails)"
    From = “DP-Automation<deepaklr@in.ibm.com>”
    SMTPServer = “theIP”
    Subject = “Stuff”
    BodyAsHTML = $true
    Body = Get-Content ".\$($mailFile)"
    }

    Send-MailMessage @params
    
}

Write-Output "End: $(Get-Date)"
