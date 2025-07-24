# Get-UserMFARegState.ps1

## ✨ Summary

`Get-UserMFARegState.ps1` retrieves the Multi-Factor Authentication (MFA) registration details of Microsoft 365 users via Microsoft Graph API. You can query a single user by UPN or retrieve details for **all users** in your organization.

The script outputs a summary including:

* Display Name
* User Principal Name
* Admin status
* MFA capability
* MFA registration status
* Default MFA method
* List of registered MFA methods

Optionally, the output can be saved to a CSV file.

---

## ✅ Requirements

* PowerShell 5.1 or later
* Microsoft Graph PowerShell SDK
  Install using:

  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```

* Microsoft Graph permissions:

  * `Reports.Read.All`
  * `User.Read.All`

> ⚠️ You must be connected to Microsoft Graph with the required scopes before running the script:

```powershell
Connect-MgGraph -Scopes "Reports.Read.All", "User.Read.All"
```

---

## 📌 Parameters

### `-UserPrincipalName <string>`

Retrieves MFA registration details for a **single** user specified by UPN (e.g., `jdoe@contoso.com`).

### `-AllUsers`

Retrieves MFA registration details for **all users** in the tenant.

> 🚩 This switch is **mutually exclusive** with `-UserPrincipalName`.

### `-OutputCsv <string>`

(Optional) Path to a CSV file where the results will be exported. If not specified, the report will be output to the console.

---

## 🚀 Usage Examples

### 🔍 Get MFA status of a single user

```powershell
.\Get-UserMFARegState.ps1 -UserPrincipalName jane.doe@contoso.com
```

### 📋 Get MFA status for all users

```powershell
.\Get-UserMFARegState.ps1 -AllUsers
```

### 📆 Export all MFA registration data to a CSV file

```powershell
.\Get-UserMFARegState.ps1 -AllUsers -OutputCsv "C:\Reports\MFA_Report.csv"
```

---

## 📄 Output Fields

| Field Name           | Description                                          |
| -------------------- | ---------------------------------------------------- |
| DisplayName          | Full display name of the user                        |
| UserPrincipalName    | The user's login/UPN                                 |
| Administator         | Indicates if the user is an admin                    |
| MFACapable           | True if user can register for MFA                    |
| MFARegistered        | True if user has completed MFA registration          |
| MFADefaultMethod     | The default MFA method set (e.g., Authenticator app) |
| MFAMethodsRegistered | Comma-separated list of all registered MFA methods   |

---

## 🔍 Notes

* The script uses the `beta` endpoint of Microsoft Graph API.
* MFA method names are automatically prettified (e.g., `phoneAppNotification` becomes `Phone App Notification`).
* Script includes a progress bar for processing multiple users.
* If no users are found, the script returns `$null`.

---

## 🧱 Sample Output (Console)

```

DisplayName         : Jane Doe
UserPrincipalName   : jane.doe@contoso.com
Administator        : False
MFACapable          : True
MFARegistered       : True
MFADefaultMethod    : Phone App Notification
MFAMethodsRegistered: Phone App Notification, Email
```

---

## 🧑‍💻 Author

June Castillote ([june.castillote@gmail.com](mailto:june.castillote@gmail.com))
