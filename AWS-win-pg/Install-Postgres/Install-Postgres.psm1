#################################################################################  
##  
## PostgreSQL unattended install 
## Author: Stefan Prodan   
## Date : 16 Oct 2014  
## Company: VeriTech.io    
################################################################################

﻿Function Set-Owner {
    <#
        .SYNOPSIS
            Changes owner of a file or folder to another user or group.

        .DESCRIPTION
            Changes owner of a file or folder to another user or group.

        .PARAMETER Path
            The folder or file that will have the owner changed.

        .PARAMETER Account
            Optional parameter to change owner of a file or folder to specified account.

            Default value is 'Builtin\Administrators'

        .PARAMETER Recurse
            Recursively set ownership on subfolders and files beneath given folder.

        .NOTES
            Name: Set-Owner
            Author: Boe Prox
            Version History:
                 1.0 - Boe Prox
                    - Initial Version

        .EXAMPLE
            Set-Owner -Path C:\temp\test.txt

            Description
            -----------
            Changes the owner of test.txt to Builtin\Administrators

        .EXAMPLE
            Set-Owner -Path C:\temp\test.txt -Account 'Domain\bprox

            Description
            -----------
            Changes the owner of test.txt to Domain\bprox

        .EXAMPLE
            Set-Owner -Path C:\temp -Recurse 

            Description
            -----------
            Changes the owner of all files and folders under C:\Temp to Builtin\Administrators

        .EXAMPLE
            Get-ChildItem C:\Temp | Set-Owner -Recurse -Account 'Domain\bprox'

            Description
            -----------
            Changes the owner of all files and folders under C:\Temp to Domain\bprox
    #>
    [cmdletbinding(
        SupportsShouldProcess = $True
    )]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]$Path,
        [parameter()]
        [string]$Account = 'Builtin\Administrators',
        [parameter()]
        [switch]$Recurse
    )
    Begin {
        #Prevent Confirmation on each Write-Debug command when using -Debug
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Try {
            [void][TokenAdjuster]
        } Catch {
            $AdjustTokenPrivileges = @"
            using System;
            using System.Runtime.InteropServices;

             public class TokenAdjuster
             {
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
              ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
              [DllImport("kernel32.dll", ExactSpelling = true)]
              internal static extern IntPtr GetCurrentProcess();
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
              phtok);
              [DllImport("advapi32.dll", SetLastError = true)]
              internal static extern bool LookupPrivilegeValue(string host, string name,
              ref long pluid);
              [StructLayout(LayoutKind.Sequential, Pack = 1)]
              internal struct TokPriv1Luid
              {
               public int Count;
               public long Luid;
               public int Attr;
              }
              internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
              internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
              internal const int TOKEN_QUERY = 0x00000008;
              internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
              public static bool AddPrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_ENABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
              public static bool RemovePrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_DISABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
             }
"@
            Add-Type $AdjustTokenPrivileges
        }

        #Activate necessary admin privileges to make changes without NTFS perms
        [void][TokenAdjuster]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
        [void][TokenAdjuster]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
        [void][TokenAdjuster]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions
    }
    Process {
        ForEach ($Item in $Path) {
            Write-Verbose "FullName: $Item"
            #The ACL objects do not like being used more than once, so re-create them on the Process block
            $DirOwner = New-Object System.Security.AccessControl.DirectorySecurity
            $DirOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $FileOwner = New-Object System.Security.AccessControl.FileSecurity
            $FileOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $DirAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $FileAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $AdminACL = New-Object System.Security.AccessControl.FileSystemAccessRule('Builtin\Administrators','FullControl','ContainerInherit,ObjectInherit','InheritOnly','Allow')
            $FileAdminAcl.AddAccessRule($AdminACL)
            $DirAdminAcl.AddAccessRule($AdminACL)
            Try {
                $Item = Get-Item -LiteralPath $Item -Force -ErrorAction Stop
                If (-NOT $Item.PSIsContainer) {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set File Owner')) {
                        Try {
                            $Item.SetAccessControl($FileOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Directory.FullName)"
                            $Item.Directory.SetAccessControl($FileAdminAcl)
                            $Item.SetAccessControl($FileOwner)
                        }
                    }
                } Else {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set Directory Owner')) {                        
                        Try {
                            $Item.SetAccessControl($DirOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Parent.FullName)"
                            $Item.Parent.SetAccessControl($DirAdminAcl) 
                            $Item.SetAccessControl($DirOwner)
                        }
                    }
                    If ($Recurse) {
                        [void]$PSBoundParameters.Remove('Path')
                        Get-ChildItem $Item -Force | Set-Owner @PSBoundParameters
                    }
                }
            } Catch {
                Write-Warning "$($Item): $($_.Exception.Message)"
            }
        }
    }
    End {  
        #Remove priviledges that had been granted
        [void][TokenAdjuster]::RemovePrivilege("SeRestorePrivilege") 
        [void][TokenAdjuster]::RemovePrivilege("SeBackupPrivilege") 
        [void][TokenAdjuster]::RemovePrivilege("SeTakeOwnershipPrivilege")     
    }
}

Function Install-Postgres
{
<# 
 
.SYNOPSIS 
PostgreSQL unattended install
 
.DESCRIPTION
PostgreSQL unattended install script does the following: 
creates a local windows user that PostgreSQL will use, 
the password use for the creation of this account will be the same as the one used for PostgreSQL's postgres superuser account, 
creates postgres user profile,
downloads the PostgreSQL installer provided by EnterpriseDB, 
installs Postgres unattended using the supplied parameters, 
sets postgres windows user as owner of Postgres files and folders, 
sets Postgres windows service to run under postgres local user, 
creates pgpass.conf file in AppData, 
copies configuration files to data directory, 
opens the supplied port that PostgreSQL will use in the Windows Firewall.
 
.PARAMETER User     
Local windows user that runs pg windows service
 
.PARAMETER Password 
Windows user password as well as pg superuser password 
 
.PARAMETER InstallerUrl 
Default value 'http://get.enterprisedb.com/postgresql/postgresql-9.3.5-1-windows-x64.exe'
 
.PARAMETER InstallPath 
Default value "C:\Program Files\PostgreSQL\9.3"

.PARAMETER DataPath 
Default value "C:\Program Files\PostgreSQL\9.3\data"

.PARAMETER Locale 
Default value "English, United States"

.PARAMETER Port 
Default value 5432

.PARAMETER ServiceName 
Default value "postgresql"
 
.EXAMPLE 
Install-Postgres -User postgres -Password ChangeMe!
 
.NOTES 
You need to have administrative permissions to run this script. 
 
#> 

    Param
    (
	    [Parameter(Mandatory=$true)]
	    [Alias('User')][String]$pgUser="postgres",

	    [Parameter(Mandatory=$true)]
	    [Alias('Password')][String]$pgPassword,

	    [Parameter(Mandatory=$false)]
	    [Alias('InstallerUrl')][String]$pgKitSource="http://get.enterprisedb.com/postgresql/postgresql-9.3.5-1-windows-x64.exe",

	    [Parameter(Mandatory=$false)]
	    [Alias('InstallPath')][String]$pgInstallPath="C:\Program Files\PostgreSQL\9.3",

	    [Parameter(Mandatory=$false)]
	    [Alias('DataPath')][String]$pgDataPath="C:\Program Files\PostgreSQL\9.3\data",

	    [Parameter(Mandatory=$false)]
	    [Alias('Locale')][String]$pgLocale="English, United States",

	    [Parameter(Mandatory=$false)]
	    [Alias('Port')][int]$pgPort=5432,

	    [Parameter(Mandatory=$false)]
	    [Alias('ServiceName')][String]$pgServiceName="postgresql"
    )

    $pgKit = "$PSScriptRoot\postgresql.exe";
    $pgConfigSource = "$PSScriptRoot\Config";
    $pgPassPath = "C:\Users\$pgUser\AppData\Roaming\postgresql";

    Write-Host "Creating local user $pgUser";

    try
    {
        New-LocalUser $pgUser $pgPassword;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }

    $script:nativeMethods = @();
    if (-not ([System.Management.Automation.PSTypeName]'NativeMethods').Type)
    {
        Register-NativeMethod "userenv.dll" "int CreateProfile([MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,`
         [MarshalAs(UnmanagedType.LPWStr)] string pszUserName,`
         [Out][MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszProfilePath, uint cchProfilePath)";

        Add-NativeMethods;
    }

    $localUser = New-Object System.Security.Principal.NTAccount("postgres");
    $userSID = $localUser.Translate([System.Security.Principal.SecurityIdentifier]);
    $sb = new-object System.Text.StringBuilder(260);
    $pathLen = $sb.Capacity;

    Write-Host "Creating user profile for $pgUser";

    try
    {
        [NativeMethods]::CreateProfile($userSID.Value, $pgUser, $sb, $pathLen) | Out-Null;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Installing Postgres in $pgInstallPath";

    try
    {
        Start-PostgresInstall $pgKitSource $pgKit $pgInstallPath $pgDataPath $pgLocale $pgPort $pgServiceName $pgUser $pgPassword;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Grant full control of $pgInstallPath for user $pgUser";

    try
    {
        Set-DirOwner $pgInstallPath $pgUser;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Creating pgpass.conf in $pgPassPath";

    try
    {
        New-PgPass $pgPassPath $pgUser $pgPassword;
        Set-Owner $pgPassPath $pgUser;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Copying config files to $pgDataPath";

    try
    {
        Copy-Configs $pgConfigSource $pgDataPath;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Creating firewall rule for port $pgPort";

    try
    {
        Open-Port $pgServiceName $pgPort;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }


    Write-Host "Changing $serviceName windows service user to $pgUser";

    try
    {
        Set-ServiceOwner $pgServiceName $pgUser $pgPassword;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }

    Write-Host "Postgres has been installed";
}


function New-LocalUser($userName, $password)
{
    $system = [ADSI]"WinNT://$env:COMPUTERNAME";
    $user = $system.Create("user",$userName);
    $user.SetPassword($password);
    $user.SetInfo();

    $flag=$user.UserFlags.value -bor 0x10000;
    $user.put("userflags",$flag);
    $user.SetInfo();

    $group = [ADSI]("WinNT://$env:COMPUTERNAME/Users");
    $group.PSBase.Invoke("Add", $user.PSBase.Path);
}

function Register-NativeMethod([string]$dll, [string]$methodSignature)
{
    $script:nativeMethods += [PSCustomObject]@{ Dll = $dll; Signature = $methodSignature; }
}

function Add-NativeMethods()
{
    $nativeMethodsCode = $script:nativeMethods | % { "
        [DllImport(`"$($_.Dll)`")]
        public static extern $($_.Signature);
    " }

    Add-Type @"
        using System;
        using System.Text;
        using System.Runtime.InteropServices;
        public static class NativeMethods {
            $nativeMethodsCode
        }
"@
}

function Start-PostgresInstall($installerUrl, $installerPath, $installPath, $dataPath, $locale, $port, $serviceName, $user, $password)
{
    #create folders
    New-Item -ItemType Directory -Force -Path $installPath;
    New-Item -ItemType Directory -Force -Path $dataPath;

    # download pg installer
    Invoke-WebRequest $installerUrl -OutFile $installerPath;


    # run pg installer
    Start-Process $installerPath -ArgumentList "--mode unattended", "--unattendedmodeui none",`
     "--prefix `"$installPath`"", "--datadir `"$dataPath`"", "--locale `"$locale`"", "--superpassword `"$password`"",`
     "--serverport $port", "--servicename `"$serviceName`"", "--serviceaccount `"$user`"", "--servicepassword `"$password`""`
     -Wait;
 }

 function Set-DirOwner($path, $userName)
{
    $acl = Get-Acl $path;
    $aclDef = "$env:COMPUTERNAME\$userName","FullControl",`
     "ContainerInherit,ObjectInherit", "InheritOnly", "Allow";

    $aclRule = New-Object System.Security.AccessControl.FileSystemAccessRule $aclDef;
    $acl.SetAccessRule($aclRule);
    $acl | Set-Acl $path;
}

function New-PgPass($path, $userName, $password)
{
    New-Item -ItemType Directory -Force -Path $path;

    $pgPassFilePath = Join-Path $path "pgpass.conf";
    $pgPassContent = "localhost:$pgPort`:*:$userName`:$password";
    $pgPassContent | Set-Content $pgPassFilePath;
}

function Copy-Configs($configSource, $dataPath)
{
    if ( Test-Path $pgConfigSource)
    {
        Copy-Item $pgConfigSource -Filter *.conf $dataPath -Force;
    }
}

function Open-Port($name, $port)
{
    New-NetFirewallRule -DisplayName $name -Direction Inbound –Protocol TCP –LocalPort $port -Action allow -Profile Any;
}

function Set-ServiceOwner($serviceName, $user, $password)
{
    $user = ".\$user";
    $service = gwmi win32_service -computer "." -filter "name='$serviceName'";
    $service.change($null,$null,$null,$null,$null,$null,$user,$password);
    $service.StopService();
    Start-Sleep -s 2;
    $service.StartService();
}

Export-ModuleMember -Function Install-Postgres;