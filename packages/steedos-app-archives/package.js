Package.describe({
	name: 'steedos:app-archive',
	version: '0.0.1',
	summary: 'Creator archive',
	git: ''
});

Package.onUse(function(api) {

	api.use('steedos:creator');
	api.use('coffeescript@1.11.1_4');
	api.addFiles('models/archive_keji.coffee');
	api.addFiles('models/archive_kejiditu.coffee');
	api.addFiles('models/archive_wenshu.coffee');
	api.addFiles('models/archive_kuaiji.coffee');
	api.addFiles('models/archive_kejiditu.coffee');
	api.addFiles('models/archive_rongyu.coffee');
	api.addFiles('models/archive_shengxiang.coffee');
	api.addFiles('models/archive_dianzi.coffee');
	api.addFiles('models/archive_tongji.coffee');
	api.addFiles('models/archive_shenji.coffee');
	// api.addFiles('models/archive_hetong.coffee');
	// api.addFiles('models/archive_dichan.coffee');
	// api.addFiles('models/archive_yinjian.coffee');
	// api.addFiles('models/archive_renshi.coffee');
	// api.addFiles('models/archive_wuzi.coffee');

	api.addFiles('server/methods/archive_borrow.coffee', 'server');
	api.addFiles('server/methods/archive_destroy.coffee', 'server');
	api.addFiles('server/methods/archive_receive.coffee', 'server');
	api.addFiles('server/methods/archive_transfer.coffee', 'server');
	api.addFiles('server/methods/archive_new_audit.coffee', 'server');

	api.addFiles('archive.coffee');
})