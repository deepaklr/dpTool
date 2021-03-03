# Contains Powershell scripts to manage datapower configuration via XMI #

## [1] add-latency-log.ps1
    Script Adds latency log target on the given device/domain, provide FTP sever details in the below section
          Usage : ./add-latency-log <datapower-xmi-url> <login-id> <password> <domain names;comma separated>
          Example: ./add-latency-log https://127.0.0.1:5550/service/mgmt/current admin admin "POC-Domain,apigw"

## [2] datapower-cert-monitor.ps1
    Script monitors the datapower for all the certificate objects and if any certificate is found to be expiring, it will trigger an email with details
    Dependency: dpTool service - deployed & configured on any one device - https://github.com/deepaklr/dpTool
    Usage: .\datapower-cert-monitor
    Before running - edit the script file to set few setup variables
 
## [3] datapower-reboot.ps1
    Reboots given set of devices after quiescing all domains and disabling any domains if required.Once device is rebooted, it will enable all disabled domains
    Arguments
    <deviceListFile> : Required. File path containing List of datapower console IPs which needs to be rebooted
                    Syntax of the file entries: device-ip,llgin-id,login-password
    [domainListFile] : Optional. File path containing List of domains that needs to be disabled before rebooting
                    Syntax of the file entries: domain-name list (on each line)
    [EnvName] : Optional. Provide env name for logging/status mail
    Example: .\datapower-reboot "c:\reboot\prod-devices.txt" "c:\reboot\prod-domains.txt" "PROD"

## [4] download-domain-config.ps1
    Script downloads datapower configuration for a given device/domain and zips the file
    Usage : ./download-domain-config <datapower-xmi-url> <login-id> <password> <domain name>
    Example: ./download-domain-config https://127.0.0.1:5550/service/mgmt/current admin admin POC-Domain
  
## [5] download-wsdl.ps1
    Script downloads the WSDLs and referred schemas/resources for given ?wsdl URL 
    Arguments:
    <wsdl URL> : Required, URL of the WSDL - usually service-end-point?wsdl
    [output folder] : Optional, all files will be saved in this folder - default is current directory
    Example: .\download-wsdl "http://mycompany.com/api/v2/GetQuote?wsdl" ".\out\"
  
## [6] latency-avg-by-svc.ps1
    Script parses all latency logs given and calculates average grouped by service name
    Usage : ./latency-avg-by-svc <path/files to be parsed>
    Example: ./latency-avg-by-svc "C:\logs\latency*"
