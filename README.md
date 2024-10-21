**EntraMail** is a PowerShell based tool for penetration testers and Red Teamers to enumerate user accounts within EntraID (Azure AD) environments. It uses multiple APIs to identify valid User Principal Names (UPNs) and provides detailed HTML reports. The tool offers flexible options for querying by first names, last names, usernames, and supports both single queries and bulk operations via files.

## Features

- **Multiple Query Options:** Supports querying by first name, last name, or full username, as well as bulk queries from files.
- **Domain-Specific UPN Enumeration:** Validate UPNs within a specific domain to identify active accounts in EntraID.
- **Stop On First Match:** Optionally stop searching after finding the first valid user to optimize large-scale enumeration efforts.
- **Customizable Delays:** Control the delay between requests to prevent rate-limiting or IP blocking.
- **Detailed HTML Reporting:** Generate comprehensive, user-friendly HTML reports of the results.
- **Flexible Input Sources:** Accepts individual names or files containing multiple names or usernames for streamlined bulk enumeration.

### Prerequisites

- PowerShell 5.0 or higher

### Command Line Usage

```powershell
# Load The Script
Import-Module .\EntraMail.psm1
```
```powershell
# Searching by single first name and last name
  Invoke-EntraMail -FirstName john -LastName doe -DomainName example.com
```
```powershell
# Searching by Names-File it is recommended to use -StopOnFirstMatch flag
  Invoke-EntraMail -NamesFile names.txt -DomainName example.com -StopOnFirstMatch
```
```powershell
# Searching by NUserNames File
  Invoke-EntraMail -UsernameFile usernames.txt -DomainName example.com -StopOnFirstMatch -OutputFilePath report.html
```

### PoC

![image](https://github.com/user-attachments/assets/99e89d7f-a2fb-4c1a-b4d2-6e53dfd64803)


![image](https://github.com/user-attachments/assets/e6daba67-0def-4bac-8b5e-e08a484a3671)

![image](https://github.com/user-attachments/assets/fb672549-ae45-462f-b950-29114f6cb06d)


![image](https://github.com/user-attachments/assets/6c7a3307-3ddd-4142-beed-95b918df325f)


![image](https://github.com/user-attachments/assets/ea0dda38-9270-4035-bba8-4f6d18b9b389)


