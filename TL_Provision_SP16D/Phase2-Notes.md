#
# Phase2-Notes.md
#

After the SQL Server virtual machine restarts, reconnect to it using the local administrator account.
Prepare the extra data disk for use with SQL Server 
In the left pane of Server Manager, click File and Storage Services, and then click Disks.
In the contents pane, in the Disks group, click disk 2 (with the Partition set to Unknown).
Click Tasks, and then click New Volume.
On the Before you begin page of the New Volume Wizard, click Next.
On the Select the server and disk page, click Disk 2, and then click Next. When prompted, click OK.
On the Specify the size of the volume page, click Next.
On the Assign to a drive letter or folder page, click Next.
On the Select file system settings page, click Next.
On the Confirm selections page, click Create.
When complete, click Close.
Run the following commands from a Windows PowerShell command prompt.

md f:\Data
md f:\Log
md f:\Backup

Next, configure the SQL server to use the F: drive for new databases and for accounts and permissions.
Configure the SQL server 
On the Start screen, type SQL Studio, and then click SQL Server 2014 Management Studio.
In Connect to Server, click Connect.
In the left pane, right-click the top node—the default instance named after the machine—and then click Properties.
In Server Properties, click Database Settings.
In Database default locations, set the following values:
For Data, set the path to f:\Data.
For Log, set the path to f:\Log.
For Backup, set the path to f:\Backup.
Click OK to close the window.
In the left pane, expand the Security folder.
Right-click Logins, and then click New login.
In Login name, type CORP\<ADMIN_NAME>.
Under Select a page, click Server Roles, click sysadmin, and then click OK.
Close SQL Server 2014 Management Studio.

SQL Server requires a port that clients use to access the database server. It also needs ports to connect with the SQL Server Management Studio. Run the following command at an administrator-level Windows PowerShell command prompt on the SQL Server virtual machine.
New-NetFirewallRule -DisplayName "SQL Server ports 1433, 1434, and 5022" -Direction Inbound -Protocol TCP -LocalPort 1433,1434,5022 -Action Allow

