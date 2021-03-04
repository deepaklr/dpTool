# Author: deepak ramabhat - deepaklr@in.ibm.com,deepaklr@outlook.com
# History: 8-1-21 - 1.0 - Initial
# Script updates the given yaml file with example values from the input file for each of the matching field names
# Dependency: Powershell-yaml module -- https://github.com/cloudbase/powershell-yaml
#
# Usage : .\update-yaml-examples <yaml file> <example file> [yaml definition name]
#      <yaml file> : Input yaml file that needs all example values to be updated on wither request,response or error objects  
#      <example file> : file containing JSON data for the respective request,response or error
#      [yaml definition name] : Optional, Object definition from yaml which needs example to be updated like xyzRequest, successResponse default is "*req*"
#
#      Example: .\update-yaml-examples "./myservice_1.0.0.yaml" "./request.json" "ChallanRequest"
#------------------------------------------------------------------------------------------------------

if($args[0] -eq $null -or $args[1] -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}


$defmatch_pattern="*req*"
if($args[2] -ne $null){
    $defmatch_pattern=$args[2]
}

$yamlFile=$args[0]
$jsonFile=$args[1]


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


$encJson = get-content $jsonFile | ConvertFrom-Json


[string[]]$fileContent = Get-Content $yamlFile

$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }
$yaml = ConvertFrom-YAML -Ordered $content

    
$global:upCnt=0

function loopNode([PSObject]$jsNode, [String]$pNode){

    foreach($req in $jsNode.properties)
    {

        foreach($k in $req.Keys){

            $val = $encJson.$k
            if($pNode){
                $val = $($encJson.$pNode.$k)
            }
            
            #write-output "$k, $pNode, $val"

            if($req.$k.type -eq 'array'){
        

                if($req.$k.items.Keys -match "properties"){
                    foreach($inreq in $req.$k.items){
            
                        loopNode $inReq $k
                    }
                } else{
                    $req.$k.items.example = $val
                    $global:upCnt++
                    if($val -eq $null -or $val -eq ''){
                        write-output "$k example not found"
                    }
                }
            }
            elseif($req.$k.type -eq 'object'){
                loopNode $req.$k $k
            } 
            else {
                $req.$k.example = $val
                $global:upCnt++
                if($val -eq $null -or $val -eq ''){
                    write-output "$k example not found"
                }
            }
        }

    }
}

$defupdated=0
foreach($def in $yaml.definitions.keys){
    if($def -ilike $defmatch_pattern){

        write-output "Updating Definition named: $($def)"
        loopNode $yaml.definitions.$def
        write-output "$($global:upCnt) example fields updated"
        $defupdated++
    }
}

if($defupdated -gt 0){
    $fname= Split-Path $yamlFile -leaf

    #folder of output yaml files
    $out='.\out'

    $fldr=New-Item -ItemType Directory -Force -Path $out

    ConvertTo-Yaml $yaml | out-file "$out\$fname" 

    write-output "Output file saved : $out\$fname)"
}
else{
    write-output "No matching definitions found in yaml for $defmatch_pattern"
}
    




