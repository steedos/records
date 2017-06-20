npm install --global --production windows-build-tools
npm install -g node-gyp

meteor build --directory C:/records-build/
cd C:/records-build/bundle/programs/server
rm -rf node_modules
npm install

cd ../../
node main.js
pm2 restart records.0