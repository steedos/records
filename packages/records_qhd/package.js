Package.describe({
	name: 'steedos:records-qhd',
	version: '0.0.10',
	summary: 'Steedos libraries',
	git: ''
});

Npm.depends({
	'form-data': '2.1.4'
});

Package.onUse(function (api) {
	api.versionsFrom('METEOR@1.3');

	api.use('session');
	api.use('coffeescript');
	api.use('ecmascript');
	api.use('blaze-html-templates');
	api.use('underscore');
	api.use('reactive-var');
	api.use('tracker');

	api.use('flemay:less-autoprefixer@1.2.0');
	api.use('kadira:flow-router@2.10.1');
	api.use('meteorhacks:subs-manager@1.6.4');

	api.use('tap:i18n@1.8.2');

	api.addFiles('lib/core.coffee');

	api.addFiles('lib/models/instance.coffee');

	api.addFiles('server/lib/instances_to_archive.coffee', 'server');

	api.addFiles('server/lib/records_qhd.coffee', 'server');

	api.export('db');

	api.export('InstancesToArchive');

	api.export('RecordsQHD');

});

Package.onTest(function (api) {

});