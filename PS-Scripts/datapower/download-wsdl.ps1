# Author: deepak ramabhat - deepaklr@in.ibm.com
# History: 22-12-19 - 1.0 - Initial
# Script downloads the WSDLs and referred schemas/resources for given ?wsdl URL 
#
# Arguments:
# <wsdl URL> : Required, URL of the WSDL - usually service-end-point?wsdl
# [output folder] : Optional, all files will be saved in this folder - default is current directory
#
# Example: .\download-wsdl "http://mycompany.com/api/v2/GetQuote?wsdl" ".\out\"
# ----------------------------------------------------------------------------------------------------------

function downloadFile([string]$url,[string]$filename,[string]$folder, [System.Collections.ArrayList]$ondisk){

    if($url -ne $null){

        Invoke-WebRequest -URI $url -Method Get -TimeoutSec 400 -outfile ".\wsdl-out.tmp"
        $file_data=get-content ".\wsdl-out.tmp"

        if ($file_data -ne $null) {
            
            if(-not $(test-path "$($folder)")){
                $d=New-Item -ItemType Directory -Force -Path "$($folder)"
            }
            $file_data | out-file "$($folder)\$($filename)" -Encoding utf8

            $line_matched = $file_data | Select-String -Pattern "<.*:import.* location=`"([\w\.\?]*)`"" -AllMatches

            $lastWord_in_url = $($url.split("/") | Select-Object -Last 1)

            foreach($line in $line_matched) {
                $fName=$line.matches.groups[1].value
                $newURL=$url.replace($lastWord_in_url, $fName)

                if($ondisk -contains $fName){
                    Write-Output "$fName already downloaded, recursive import `r`n"
                } else {
                    #write-output $line.matches.groups[1].value 
                    #write-output $url.replace($lastWord_in_url, $fName)
                    $x=$ondisk.Add($fName)
                    $fName=$fName.replace("?","_")
                    $result=downloadFile $newURL $fName $folder $ondisk
                    Write-Output "download $result :  $newURL `r`n"
                    
                }

            }

            $line_matched = $file_data | Select-String -Pattern "<.*:import.* schemaLocation=`"([\w\.\?]*)`"" -AllMatches

            foreach($line in $line_matched) {
                $fName=$line.matches.groups[1].value
                $newURL=$url.replace($lastWord_in_url, $fName)

                if($ondisk -contains $fName){
                    Write-Output "$fName already downloaded, recursive import `r`n"
                } else {
                    #write-output $line.matches.groups[1].value
                    #write-output $url.replace($lastWord_in_url, $fName)
                    $x=$ondisk.Add($fName)
                    $fName=$fName.replace("?","_")
                    $result=downloadFile $newURL $fName $folder $ondisk
                    Write-Output "download $result :  $newURL `r`n"
                }
            }


            "success"
        } else {

            "failed"
        }
    }

}

if($args[0] -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}

$URL_in=$args[0]

$download_path=".\"
if($args[1] -ne $null){
    $download_path=$args[1]
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

    
[System.Collections.ArrayList]$wsdl_names = @()


$url_split=$URL_in.split("/")
$wsdl_name=$($url_split | Select-Object -Last 1).replace("?wsdl",".wsdl")           
         
                
[System.Collections.ArrayList]$ondisk=@()

$result=downloadFile $URL_in $wsdl_name $download_path $ondisk
if($result -eq "success"){
    $x=$wsdl_names.Add($wsdl_name)
}
Write-Output "download $($result):$($URL_in) `r`n"
