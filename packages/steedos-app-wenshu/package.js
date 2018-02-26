Package.describe({
	name: 'steedos:app-archive',
	version: '0.0.1',
	summary: 'Creator archive',
	git: ''
});

Package.onUse(function(api) {

	api.use('steedos:creator');
	api.use('coffeescript@1.11.1_4');
	api.addFiles('models/archive_audit.coffee');
	api.addFiles('models/archive_borrow.coffee');
	api.addFiles('models/archive_classification.coffee');
	api.addFiles('models/archive_destroy.coffee');
	api.addFiles('models/archive_entity_relation.coffee');
	api.addFiles('models/archive_fonds.coffee');
	api.addFiles('models/archive_retention.coffee');
	api.addFiles('models/archive_rules.coffee');
	
	api.addFiles('models/archive_wenshu.coffee');
	api.addFiles('archive.coffee');
})