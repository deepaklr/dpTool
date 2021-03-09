
# Author: deepak ramabhat - deepaklr@in.ibm.com, deepaklr@outlook.com
# History: 9-3-21 - 1.0 - Initial
# Script collects API details of all yaml files in a given folder and creates a HTML table with details
#
# Usage: .\print-api-details.ps1 "<folder path>"
# Example : .\print-api-details.ps1 "C:\Workspace\APIC\WS1\"
#------------------------------------------------------------------------------------------------------

if($args[0] -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}


$folder=$args[0]
$files=Get-ChildItem $folder -Filter *.yaml

if($files.count -eq 0){
   write-output "Folder does not coantain any yaml files"
   exit
}

$html_line="<HTML><BODY>"
$html_line+='<head><style type="text/css">td,th	{FONT-FAMILY: verdana,helvetica,arial,sans-serif;FONT-SIZE: 8pt; MARGIN: 0px; COLOR: #000000;border:1px solid #1fffff;} th{COLOR: #0000ff;TEXT-DECORATION:	bold;}</style></head>'
$html_line += "<TABLE border='1'><TR><TH>API</TH><TH>Paths</TH><TH>Backend URL</TH></TR>"

foreach($f in  $files){

    write-output "Processing $f"

    [string[]]$fileContent = Get-Content "$folder\$f"
    $content = ''
    foreach ($line in $fileContent) { $content = $content + "`n" + $line }
    $yaml = ConvertFrom-YAML -Ordered $content

    $bp=$yaml.basePath
    $html_line+="<TR><TD>$($yaml.info.title) $($yaml.info.version)</TD><TD>"
    foreach($path in $yaml.paths.keys){
        
        foreach($method in $yaml.paths.$path.keys){
            if($method -ne 'parameters'){
                $html_line += "<b>$($method)</b> $($bp)$($path)<br/>"
            }
        }
        
    }
    $html_line += "</TD><TD>"
    foreach($urls in $yaml."x-ibm-configuration".properties.keys){
        if($urls -ilike '*url*'){
            $html_line += "$($yaml."x-ibm-configuration".properties.$urls.value)<br/>"
        }
    }
    $html_line += "</TD></TR>"
}
$html_line += "</TABLE></BODY></HTML>"

$fldr=Split-Path $folder -leaf 

$html_line | out-file ".\$fldr-api-details.html" 

write-output "Output file saved : .\$fldr-api-details.html"
