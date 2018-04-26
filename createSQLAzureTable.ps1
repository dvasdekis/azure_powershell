$TableFile = "d:\55000a\createtesttable.txt"
$TableScript = Get-Content $TableFile
$SQLServerName = "nycsql1"
$SQLServerLogin = "sqllogin3"
$SQLServerPassword = "Password123"
$connectionstring = "Server=tcp:$SQLServerName.database.windows.net;Database=db1;User ID=$SQLServerLogin@$SQLServerName;Password=$SQLServerPassword;Trusted_Connection=False;Encrypt=True;"

### Create SQL Azure Table
$SAConnection=New-Object System.Data.SqlClient.SqlConnection($connectionstring)
$SAConnection.Open()
$CreateTable= New-Object System.Data.SqlClient.SqlCommand($TableScript,$SAConnection)
$CreateTable.ExecuteNonQuery()
$SAConnection.Close()


