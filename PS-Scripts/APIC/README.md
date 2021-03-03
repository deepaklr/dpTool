# Contains Powershell scripts to query APIConnect configuration via REST management API calls #

## [1] download-all-api.ps1
	Script downloads all API definitions from the given catalog
	Usage : ./download-all-api <APIC BASE URL> <apic-user-id> <apic-user-password> <apic-user-registry> <app-client-id> <app-client-password> <catalog/product>
	Example: ./download-all-api https://management.apps.nonprod.mycompany.com user-1 pass-1 "provider/default-idp-1" appid appsecret "sandbox/dev"
	
## [2] list-all-api.ps1
	Script lists all API definitions from the given catalog - name version and last updated columns only
	Usage : ./list-all-api <APIC BASE URL> <apic-user-id> <apic-user-password> <apic-user-registry> <app-client-id> <app-client-password> <catalog/product>
	Example: ./list-all-api https://management.apps.nonprod.mycompany.com user-1 pass-1 "provider/default-idp-1" appid appsecret "sandbox/dev"
  
