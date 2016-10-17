## nsMySQL NSIS Plugin
###### NSIS MySQL command execute from NSIS instaler with unicode and x64 support

## Install
copy ```nsMySQL.dll``` file to ```%programfiles%\NSIS\Plugins```

## Functions
```nsis
nsMySQL::ExecSQL User Passwd Host Port SQL LogFileName Encoding
nsMySQL::ExecSQLFromFile User Passwd Host Port FileName LogFileName Encoding
nsMySQL::ExecSQLCreateUser User Passwd Host Port UserAccess UserName UserHost UserPasswd SQL LogFileName Encoding
nsMySQL::ExecSQLFromFileCreateUser User Passwd Host Port UserAccess UserName UserHost UserPasswd FileName LogFileName Encoding
```
# Params

- User: user of database connection
- Passwd: password of user
- Host: address database server (default: ```'localhost'```)
- Port: port to access database (default: ```'3306'```)

- FileName: is a full filename of an SQL script
- UserAccess: Database or table that created user can access use. ```'*.*'``` to full access
- UserName: Name of new user
- UserHost: allow access only for a specified host. use ```'%'``` to access from any host
- UserPasswd: password of new user

- LogFileName: Filename for save execution log errors
- Encoding: Encoding to be used for client code page: ```'utf8'```

## License

Please see the [license file](/LICENSE.txt) for more information.