rem set DB_SERVER=127.0.0.1
set DB_SERVER=192.1.1.141
rem set DB_SERVER=192.1.1.215,192.1.1.216,192.1.1.217
set MONGO_URL=mongodb://%DB_SERVER%/steedos
rem set MONGO_URL=mongodb://dbnormal:oaoper@%DB_SERVER%/steedos?replicaSet=steedos
set MONGO_OPLOG_URL=mongodb://%DB_SERVER%/local
rem set MONGO_OPLOG_URL=mongodb://dbnormal:oaoper%DB_SERVER%/local?replicaSet=steedos&authSource=steedos
set MULTIPLE_INSTANCES_COLLECTION_NAME=workflow_instances
set ROOT_URL=http://127.0.0.1:3000/records
rem set MAIL_URL=smtp://noreply@message.steedos.com:lw3YEbNUbmkoSJDuAAAb@smtpdm.aliyun.com:25
meteor run --settings settings.json 
rem--port 3007