# Author: deepak ramabhat - deepaklr@in.ibm.com,deepaklr@outlook.com
# History: 8-1-21 - 1.0 - Initial
# Script downloads all API definitions from the given catalog
# Usage : ./download-all-api <APIC BASE URL> <apic-user-id> <apic-user-password> <apic-user-registry> <app-client-id> <app-client-password> <catalog/product>
#
#      Example: ./download-all-api https://management.apps.nonprod.mycompany.com user-1 pass-1 "provider/default-idp-1" appid appsecret "sandbox/dev"
#------------------------------------------------------------------------------------------------------


if($args[0] -eq $null -or $args[1] -eq $null -or $args[2] -eq $null -or $args[3] -eq $null -or $args[4] -eq $null -or $args[5] -eq $null -or $args[6] -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}

$url = "$($args[0])/api/token"

$btknReq = '{"username": "'+$args[1]+'", "password": "'+$args[2]+'", "realm": "'+$args[3]+'", "client_id": "'+$args[4]+'", "client_secret": "'+$args[5]+'", "grant_type": "password"}'


add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPoplicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

[System.Net.ServicePOintManager]::CertificatePolicy = New-Object TrustAllCertsPoplicy;

$headers = @{ Accept= "application/json" }

$response=invoke-Webrequest -Uri $url -method $method -ContentType "application/json" -Body $btknReq -Headers $headers

$resp = $response.Content
#write-output $response.Headers
#write-output $response.content


if($response.StatusCode -eq 200){

    write-output "Auth success!"

    $respJSON = $resp | convertfrom-json
    $btoken = $respJSON.access_token
    #$btoken

    $hdr = @{ Authorization="bearer $($btoken)" }

    $url1 = "$($args[0])/api/catalogs/$($args[6])/apis?fields=id,name,version"
    
    $apis_res=invoke-Webrequest -Uri $url1 -method "GET" -ContentType "application/json" -Headers $hdr

    if($apis_res.StatusCode -eq 200){
        write-output $apis_res.content | out-file ".\debug.log"

        $apis=$apis_res.content | ConvertFrom-Json
        
        write-output "$($apis.total_results) APIs found"

        foreach($apid in $apis.results){
            $url2 = "$($args[0])/api/catalogs/$($args[6])/apis/$($apid.id)/document"
            $fname=".\$($apid.name)_$($apid.version).yaml"

            $doc_res=invoke-Webrequest -Uri $url2 -method "GET" -ContentType "application/json" -Headers $hdr

            if($doc_res.StatusCode -eq 200){
               $doc_res.content | Out-File -FilePath $fname -Force 
               write-output "$fname downloaded"
            } else {
                Write-output "*Error* $fname download faild"
            }
        }

    } else{
        Write-Output "API call failed!" $apis_res
    }

} else {
    Write-Output "Auth failed"
}