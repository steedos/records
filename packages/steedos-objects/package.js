Package.describe({

	name: 'steedos:objects',
	version: '0.0.1',
	summary: 'Steedos Creator',
	git: ''
});

Package.onUse(function(api) {
	api.versionsFrom('1.0');

	api.use('reactive-var@1.0.10');
	api.use('reactive-dict@1.1.8');
	api.use('coffeescript@1.11.1_4');
	api.use('random@1.0.10');
	api.use('ddp@1.2.5');
	api.use('check@1.2.3');
	api.use('ddp-rate-limiter@1.0.5');
	api.use('underscore@1.0.10');
	api.use('tracker@1.1.0');
	api.use('session@1.1.6');
	api.use('blaze@2.1.9');
	api.use('templating@1.2.15');
	// api.use('modules');  //此package 不能移除，否则会导致eval执行异常
	api.use('flemay:less-autoprefixer@1.2.0');
	api.use('simple:json-routes@2.1.0');
	api.use('nimble:restivus@0.8.7');
	api.use('aldeed:simple-schema@1.3.3');
	api.use('aldeed:schema-index@1.1.0');
	api.use('aldeed:collection2@2.5.0');
	api.use('aldeed:tabular@1.6.1');
	api.use('matb33:collection-hooks@0.8.1');


	api.use(['webapp@1.3.11'], 'server');

	api.use('raix:push@3.0.2');

	api.use('steedos:logger@0.0.2');

	api.use('tap:i18n@1.7.0');

	tapi18nFiles = ['i18n/en.i18n.json', 'i18n/zh-CN.i18n.json']
	api.addFiles(tapi18nFiles, ['client', 'server']);


	api.addFiles('core.coffee');

	api.addFiles('lib/object.coffee');
	api.addFiles('lib/fields.coffee');
	api.addFiles('lib/triggers.coffee');
	api.addFiles('lib/actions.coffee');
	api.addFiles('lib/permission_sets.coffee');
	api.addFiles('lib/listviews.coffee');
	api.addFiles('lib/apps.coffee');
	api.addFiles('lib/eval.js');
	api.addFiles('lib/formula_engine.coffee');

});
