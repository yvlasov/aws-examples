
#Vagrant AWS Windows Chief

http://engineering.daptiv.com/provisioning-windows-instances-with-packer-vagrant-and-chef-in-aws/

#PGSQL Windows

https://www.postgresql.org/download/windows/

#Running Vagrant with Ansible Provisioning on Windows

https://www.azavea.com/blog/2014/10/30/running-vagrant-with-ansible-provisioning-on-windows/

#Windows: How Does It Work

http://docs.ansible.com/ansible/intro_windows.html#windows-how-does-it-work

#Automated PostgreSQL install and configuration with PowerShell

https://coderwall.com/p/r6nqrw/automated-postgresql-install-and-configuration-with-powershell

```
C:\Users\Administrator\Documents\WindowsPowerShell\Modules\Install-Postgres\

Import-Module Install-Postgres -Force
Install-Postgres -User "postgres" -Password "ChangeMe!"
```
```
Install-Postgres : The term 'Set-Owner' is not recognized as the name of a cmdlet, function, script file, or operable
program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ Install-Postgres -User "postgres" -Password "ChangeMe!"
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Install-Postgres
```
```
win-2008r2 ami-a2d017cf 
region=us-east-1#Launch

3389 (RDP) 5985 (HTTP) 5986 (HTTPS).

```

