npm install --global --production windows-build-tools
npm install -g node-gyp

meteor build --server https://cn.steedos.com/records --directory C:/records-build/
cd C:/records-build/bundle/programs/server
rd /s /q node_modules
npm install --registry https://registry.npm.taobao.org -d

cd ../../
node main.js
pm2 restart records.0