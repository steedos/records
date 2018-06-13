Package.describe({
  name: 'steedos:creator-autoform-modals',
  summary: "Create, update and delete collections with modals",
  version: "0.0.1",
  git: "https://github.com/yogiben/meteor-autoform-modals"
});

Package.on_use(function (api) {
  api.versionsFrom('METEOR@1.2.0.1');

  api.use('coffeescript@1.11.1_4');

  api.use([
    'jquery',
    'templating',
    'less@2.5.0_2',
    'session',
    'ui',
    'aldeed:autoform@5.5.1',
    'raix:handlebar-helpers@0.2.5',
    'mpowaga:string-template@0.1.0'
  ], 'client');

  api.add_files('lib/server/core.coffee', 'server');
  
  api.add_files('lib/client/modals.html', 'client');
  api.add_files('lib/client/modals.coffee', 'client');
  api.add_files('lib/client/modals.less', 'client');

	api.add_files('lib/client/object-modal.html', 'client');
	api.add_files('lib/client/object-modal.coffee', 'client');

  api.add_files('lib/client/coreform-table/steedos-table.html', 'client');
  api.add_files('lib/client/coreform-table/steedos-table.js', 'client');
  api.add_files('lib/client/coreform-table/steedos-table.less', 'client');
});
