# Author: deepak ramabhat - deepaklr@in.ibm.com,deepaklr@outlook.com
# History: 8-1-21 - 1.0 - Initial
# Script parses all latency logs given and calculates average grouped by service name
#
# Usage : ./latency-avg-by-svc <path/files to be parsed>
#
#      Example: ./latency-avg-by-svc "C:\logs\latency*"
#
#   Explanation of Arguments found in the Latency log message
#		Position	Argument
#		1	request header read
#		2	request header sent
#		3	front side transform begun
#		4	front side transform complete
#		5	entire request transmitted
#		6	front side style-sheet ready
#		7	front side parsing complete
#		8	response header received
#		9	response headers sent
#		10	back side transform begun
#		11	back side transform complete
#		12	response transmitted
#		13	back side style-sheet read
#		14	back side parsing complete
#		15	back side connection attempted
#		16	back side connection completed
#------------------------------------------------------------------------------------------------------

$input_files=$args[0]
if($input_files -eq $null){
    write-output "Invalid list of arguments passed, check the input"
    exit
}

#f12 -- response transmitted  -- is used as total average round trip time in this script, change the field value to any other based on your requirement

$hdr = "day","mon","dt","yr","time","code","mpgw","tid","gtid","hdr","f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12","f13","f14","f15","f16","svc"
(Get-Content $input_files) -replace '\s+',' ' | ConvertFrom-csv -Header $hdr -Delimiter ' ' | Group-Object mpgw | Select-Object Name,@{Name="Count"; Expression={$_.Group.Count}},@{Name="DP_AVG"; Expression={ ($_.Group| Measure-Object f12 -Average).Average }}