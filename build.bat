cd C:\Users\steedos\Documents\GitHub\records
meteor build --server https://cn.steedos.com/records --directory C:/creator_records-build/
cd C://creator_records-build/bundle/programs/server
rd /s /q node_modules
npm install --registry https://registry.npm.taobao.org -d

cd C://creator_records-build/
pm2 restart creator_records.0