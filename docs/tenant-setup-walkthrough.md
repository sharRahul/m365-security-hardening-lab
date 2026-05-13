**Tenant Setup Walkthrough**

This section helps configure the environment from scratch.

**1. Create Break-Glass Administrative Account**
```
Account: emergencyadmin@yourtenant.onmicrosoft.com

Password: _Strong and stored offline_

MFA: Disabled (only for break-glass)

Directory role: Global Administrator

Sign-in risk policy: Excluded

CA policies: Excluded
```
Add an alert in Azure AD:

* "Notify if break-glass account signs in"

**2. Enable Security Defaults (optional)**

If using E3 or basic:
* Enforces MFA
* Blocks legacy authentication

**3. Disable Legacy Authentication (recommended for all tenants)**

PowerShell:
```
Connect-AzureAD
Set-AzureADMSAuthorizationPolicy -DefaultUserRolePermissions @{AllowedToCreateApps=$false}
```
Azure portal → Entra ID → Sign-in Logs → Legacy Auth → Block all.

**4. Configure Global Password Protection**

Enable banned password list
Set mandatory MFA for admins

**5. Assign Admin Roles based on Least Privilege**

Roles:
Global Administrator — none except break-glass
Security Administrator — 1
Exchange Administrator — 1
Compliance Administrator — 1
