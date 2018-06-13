_syncToObject = (doc) ->
	object_triggers = Creator.getCollection("object_triggers").find({object: doc.object, is_enable: true}, {
		fields: {
			created: 0,
			modified: 0,
			owner: 0,
			created_by: 0,
			modified_by: 0
		}
	}).fetch()

	triggers = {}

	_.forEach object_triggers, (f)->
		triggers[f.name] = f

	Creator.getCollection("objects").update({name: doc.object}, {
		$set:
			triggers: triggers
	})

isRepeatedName = (doc, name)->
	other = Creator.getCollection("object_triggers").find({object: doc.object, _id: {$ne: doc._id}, name: name || doc.name}, {fields:{_id: 1}})
	if other.count() > 0
		return true
	return false

check = (userId, doc)->
	if Steedos.isSpaceAdmin(userId, doc.space)
		throw new Meteor.Error 500, "只有工作去管理员才能配置触发器"

	if doc.on == 'server' && !Steedos.isLegalVersion(doc.space,"workflow.enterprise")
		throw new Meteor.Error 500, "只有企业版支持配置服务端的触发器"

Creator.Objects.object_triggers =
	name: "object_triggers"
	icon: "asset_relationship"
	label:"触发器"
	fields:
		name:
			type: "text"
			searchable: true
			index: true
			required: true
			regEx: SimpleSchema.RegEx.code
		label:
			type: "text"
		object:
			type: "master_detail"
			reference_to: "objects"
			required: true
			optionsFunction: ()->
				_options = []
				_.forEach Creator.objectsByName, (o, k)->
					_options.push {label: o.label, value: k, icon: o.icon}
				return _options
		on:
			type: "lookup"
			required: true
			optionsFunction: ()->
				return [{label: "客户端", value: "client", icon: "address"}, {label: "服务端", value: "server", icon: "address"}]
		when:
			type: "lookup"
			required: true
			optionsFunction: ()->
				[
					{label: "新增记录之前", value: "before.insert", icon: "asset_relationship"}
					{label: "新增记录之后", value: "after.insert", icon: "asset_relationship"}
					{label: "修改记录之前", value: "before.update", icon: "asset_relationship"}
					{label: "修改记录之后", value: "after.update", icon: "asset_relationship"}
					{label: "删除记录之前", value: "before.remove", icon: "asset_relationship"}
					{label: "删除记录之后", value: "after.remove", icon: "asset_relationship"}
				]
		is_enable:
			type: "boolean"
		todo:
			type: "textarea"
			required: true
			is_wide:true

	list_views:
		all:
			columns: ["name", "label", "object", "on", "when", "is_enable"]
			filter_scope: "space"

	permission_set:
		user:
			allowCreate: false
			allowDelete: false
			allowEdit: false
			allowRead: false
			modifyAllRecords: false
			viewAllRecords: false
		admin:
			allowCreate: true
			allowDelete: true
			allowEdit: true
			allowRead: true
			modifyAllRecords: true
			viewAllRecords: true

	triggers:
		"after.insert.server.object_triggers":
			on: "server"
			when: "after.insert"
			todo: (userId, doc)->
				_syncToObject(doc)
		"after.update.server.object_triggers":
			on: "server"
			when: "after.update"
			todo: (userId, doc)->
				_syncToObject(doc)
		"after.remove.server.object_triggers":
			on: "server"
			when: "after.remove"
			todo: (userId, doc)->
				_syncToObject(doc)

		"before.delete.server.object_actions":
			on: "server"
			when: "before.remove"
			todo: (userId, doc)->
				check(userId, doc)

		"before.update.server.object_actions":
			on: "server"
			when: "before.update"
			todo: (userId, doc, fieldNames, modifier, options)->
				check(userId, doc)
				if modifier?.$set?.name && isRepeatedName(doc, modifier.$set.name)
					throw new Meteor.Error 500, "对象名称不能重复"

		"before.insert.server.object_actions":
			on: "server"
			when: "before.insert"
			todo: (userId, doc)->
				check(userId, doc)
				if isRepeatedName(doc)
					throw new Meteor.Error 500, "对象名称不能重复"