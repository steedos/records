Package.describe({
	name: 'steedos:records',
	version: '0.0.1',
	summary: 'Steedos records system',
	git: ''
});


Npm.depends({
    'request':'2.40.0',
    mkdirp: "0.3.5"
});

Package.onUse(function(api) {
	api.versionsFrom('1.0');

    api.use('ecmascript');
    
	api.use('reactive-var');
    api.use('reactive-dict');
    api.use('coffeescript');
    api.use('random');
    api.use('ddp');
    api.use('check');
    api.use('ddp-rate-limiter');
    api.use('underscore');
    api.use('tracker');
    api.use('session');
    api.use('blaze');
    api.use('templating');
    api.use('flemay:less-autoprefixer');
    api.use('simple:json-routes');
    api.use('nimble:restivus');
    api.use('aldeed:simple-schema');
    api.use('aldeed:collection2');
    api.use('aldeed:tabular');
    api.use('aldeed:autoform');
    api.use('matb33:collection-hooks');
    api.use('cfs:standard-packages');
    api.use('kadira:blaze-layout');
    api.use('kadira:flow-router');
    api.use('iyyang:cfs-aliyun')
    api.use('cfs:s3');
    
    api.use('aldeed:autoform-bs-datetimepicker');

    api.use('meteorhacks:ssr');
    api.use('tap:i18n');
    api.use('meteorhacks:subs-manager');

    api.use(['webapp'], 'server');

    api.use('momentjs:moment', 'client');
    api.use('mrt:moment-timezone', 'client');

	api.use('steedos:adminlte@2.3.12_3');

    api.use('steedos:base');
    api.use('steedos:accounts');
    api.use('steedos:theme');
    api.use('steedos:theme-qhd');
    api.use('steedos:i18n');
    api.use('steedos:records-i18n@0.0.1');
    
    api.use('simple:json-routes@2.1.0');
    api.use('steedos:logger@0.0.2');
    api.use('http');


    // api.addFiles('client/admin/record_types.html', 'client');
    // api.addFiles('client/admin/record_types.coffee', 'client');
    // api.addFiles('client/admin/record_types.less', 'client');

    // api.addFiles('client/home/home.html', 'client');

    // api.addFiles('client/layout/layout.html', 'client');
    // api.addFiles('client/layout/layout.less', 'client');
    // api.addFiles('client/layout/sidebar.html', 'client');

    // api.addFiles('client/search/records_repository.html', 'client');
    // api.addFiles('client/search/records_repository.coffee', 'client');
    // api.addFiles('client/search/records_repository.less', 'client');

    // api.addFiles('client/core.coffee', 'client');
    // api.addFiles('client/router.coffee', 'client');

    api.addFiles('models/record_types.coffee');
    api.addFiles('models/instances.coffee');
    api.addFiles('models/attachments.coffee');

    // api.addFiles('server/api/search/search_api.coffee','server');
    // api.addFiles('server/api/delete/delete_api.coffee','server');


    api.addFiles('server/sync/workflow_instance.coffee','server');
    api.addFiles('server/sync/workflow_attachment.coffee','server');
    
    api.addFiles('server/test/testConverter.coffee','server');


    api.addFiles('server/main.coffee','server');
});

