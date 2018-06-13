cd C:\Users\steedos\Documents\GitHub\records
meteor build --server https://cn.steedos.com/records --directory C:/Code/Build/records-build/
cd C:/Code/Build/records-build/bundle/programs/server
rd /s /q node_modules
npm install --registry https://registry.npm.taobao.org -d

cd C:/Code/Build/records-build/
pm2 restart records.0