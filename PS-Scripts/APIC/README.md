# Contains Powershell scripts to query APIConnect configuration via REST management API calls #

## [1] download-all-api.ps1
	Script downloads all API definitions from the given catalog
	Usage : ./download-all-api <APIC BASE URL> <apic-user-id> <apic-user-password> <apic-user-registry> <app-client-id> <app-client-password> <catalog/product>
	Example: ./download-all-api https://management.apps.nonprod.mycompany.com user-1 pass-1 "provider/default-idp-1" appid appsecret "sandbox/dev"
	
## [2] list-all-api.ps1
	Script lists all API definitions from the given catalog - name version and last updated columns only
	Usage : ./list-all-api <APIC BASE URL> <apic-user-id> <apic-user-password> <apic-user-registry> <app-client-id> <app-client-password> <catalog/product>
	Example: ./list-all-api https://management.apps.nonprod.mycompany.com user-1 pass-1 "provider/default-idp-1" appid appsecret "sandbox/dev"
	
## [3] update-yaml-examples.ps1
	Script updates the given yaml file with example values from the input file for each of the matching field names
	Dependency: Powershell-yaml module -- https://github.com/cloudbase/powershell-yaml
	Usage : .\update-yaml-examples <yaml file> <example file> [yaml definition name]
      		<yaml file> : Input yaml file that needs all example values to be updated on wither request,response or error objects  
      		<example file> : file containing JSON data for the respective request,response or error
      		[yaml definition name] : Optional, Object definition from yaml which needs example to be updated like xyzRequest, SuccessResponse default is "*req*"
      Example: .\update-yaml-examples "./myservice_1.0.0.yaml" "./request.json" "ChallanRequest"
  
  
