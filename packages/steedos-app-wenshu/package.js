Package.describe({
	name: 'steedos:app-wenshu',
	version: '0.0.1',
	summary: 'Creator wenshu',
	git: ''
});

Package.onUse(function(api) {

	api.use('steedos:creator');
	api.use('coffeescript@1.11.1_4');
	api.addFiles('models/archive_borrow.coffee');
	api.addFiles('models/archive_classification.coffee');
	api.addFiles('models/archive_destroy.coffee');
	api.addFiles('models/archive_entity_relation.coffee');
	api.addFiles('models/archive_fonds.coffee');
	api.addFiles('models/archive_records.coffee');
	api.addFiles('models/archive_retention.coffee');
	api.addFiles('models/archive_rules.coffee');
	api.addFiles('models/archive_audit.coffee');
	api.addFiles('server/methods/archive_borrow.coffee', 'server');
	api.addFiles('server/methods/archive_destroy.coffee', 'server');
	api.addFiles('server/methods/archive_receive.coffee', 'server');
	api.addFiles('server/methods/archive_transfer.coffee', 'server');
	api.addFiles('archive.coffee');
})