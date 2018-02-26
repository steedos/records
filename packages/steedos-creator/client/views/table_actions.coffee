Template.creator_table_actions.helpers Creator.helpers

Template.creator_table_actions.helpers
	object_name: ()->
		return Template.instance().data.object_name
	
	record_id: ()->
		return Template.instance().data._id

	actions: ()->
		object_name = this.object_name
		record_id = this._id
		record_permissions = this.record_permissions
		obj = Creator.getObject(object_name)
		actions = Creator.getActions()
		actions = _.filter actions, (action)->
			if action.on == "record" or action.on == "record_more"
				if action.only_detail
					return false
				if typeof action.visible == "function"
					return action.visible(object_name, record_id, record_permissions)
				else
					return action.visible
			else
				return false
		if _.isEmpty(actions)
			Meteor.defer ()->
				objectColName = "tabular-col-#{object_name.replace(/\./g,'_')}"
				$(".tabular-col-actions.#{objectColName}").hide()
		return actions