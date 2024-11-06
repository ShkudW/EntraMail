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
  Invoke-EntraMail -FirstName Shaked -LastName Wiessman -DomainName domain.co.il
```
```powershell
# Searching by Names-File it is recommended to use -StopOnFirstMatch flag
  Invoke-EntraMail -NamesFile names.txt -DomainName domain.co.il -StopOnFirstMatch
```
```powershell
# Searching by NUserNames File
  Invoke-EntraMail -UsernameFile usernames.txt -DomainName domain.co.il -OutputFilePath report.html
```

```powershell
# Convert NamesFile to UserNames File :
  Invoke-EntraMail -ConvertNameFile names.txt -Style firstl 
```

### PoC

![image](https://github.com/user-attachments/assets/11e2771c-78c7-46c9-b049-6a1634bbf9c1)

![image](https://github.com/user-attachments/assets/18117c85-3413-4094-bcd0-4726bbf75f8a)

![image](https://github.com/user-attachments/assets/a7670d0c-4525-476e-8c8c-715231619409)

![image](https://github.com/user-attachments/assets/f0470fb4-e6f5-44fa-b4bb-96a938642633)

![image](https://github.com/user-attachments/assets/024f808e-9c00-4f8a-9c7f-c03d82b88b60)


