set DB_SERVER=localhost
set MONGO_URL=mongodb://%DB_SERVER%/steedos
set MONGO_OPLOG_URL=mongodb://%DB_SERVER%/local
set MULTIPLE_INSTANCES_COLLECTION_NAME=workflow_instances
set METEOR_PACKAGE_DIRS=C:\Users\steedos\Documents\GitHub\creator\packages
set ROOT_URL=http://127.0.0.1:3086
meteor run --settings settings.json --port 3086