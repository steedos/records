import { $ } from 'meteor/jquery';
import dataTablesBootstrap from 'datatables.net-bs';
import 'datatables.net-bs/css/dataTables.bootstrap.css';
dataTablesBootstrap(window, $);

# Steedos.setAppTitle "Steedos Records"

Tracker.autorun ()->
	if Session.get("steedos-locale") == "zh-cn"
		TAPi18n.setLanguage("zh-CN")
	else
		TAPi18n.setLanguage("en")

Meteor.startup ->
	if Meteor.isClient
		db.apps.INTERNAL_APPS = []

Meteor.startup ->
	$ ()->
		$("body").removeClass("loading")
