#!/bin/bash
meteor build --server https://cn.steedos.com/records --directory /srv/creator_records --allow-superuser
cd /srv/workflow/bundle/programs/server
rm -rf node_modules
rm -f npm-shrinkwrap.json
npm install --registry https://registry.npm.taobao.org -d

cd /srv/creator_records/
pm2 restart creator_records.0