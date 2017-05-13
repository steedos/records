set DB_SERVER=192.168.0.21
set MONGO_URL=mongodb://%DB_SERVER%/steedos
set MONGO_OPLOG_URL=mongodb://%DB_SERVER%/local
set MULTIPLE_INSTANCES_COLLECTION_NAME=workflow_instances
set ROOT_URL=http://localhost:3000/
rem set MAIL_URL=smtp://noreply@message.steedos.com:lw3YEbNUbmkoSJDuAAAb@smtpdm.aliyun.com:25
meteor run --settings settings.json 
rem--port 3007