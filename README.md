# EntraMail

EntraMail is a PowerShell tool designed to identify valid users in Azure Active Directory (Azure AD). The tool attempts to determine if specific usernames exist within a specified domain using various combinations of given and last names.

## Features

- **Username Generation:** Automatically generates possible username combinations from given and last names.
- **Azure AD Verification:** Checks if the generated usernames exist in Azure AD.
- **IP Blocking Detection:** Stops the script and notifies the user if a potential IP block is detected.
- **Custom Output:** Generates a styled HTML report and provides an option to download the results as a TXT file.

## Usage

### Prerequisites

- PowerShell 5.0 or higher
- Internet connection

### Command Line Usage

```powershell
# To check a single set of names
Invoke-EntraMail -PrivateName "Shaked" -LastName "Wiessman" -DomainName "example.com" -OutputFilePath "results.html"

# To check multiple names from a file
Invoke-EntraMail -NamesFilePath "names.txt" -DomainName "example.com" -OutputFilePath "results.html"

# To check a list of usernames from a file
Invoke-EntraMail -FilePath "usernames.txt" -DomainName "example.com" -OutputFilePath "results.html"
