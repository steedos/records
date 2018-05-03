Meteor.methods
	archive_new_audit: (record_id,business_activity,description,space) ->		
		auditdoc = {}
		auditdoc.business_status = "历史行为"
		auditdoc.business_activity = business_activity
		auditdoc.action_time = new Date()
		auditdoc.action_user = Meteor.userId()
		auditdoc.action_description = description
		auditdoc.space = space
		auditdoc.action_administrative_records_id = record_id
		Creator.Collections["archive_audit"].insert auditdoc
	archive_item_number: (object_name,SelectedIds,init_num) ->
		SelectedIds.forEach (SelectedId)->
			Creator.Collections[object_name].update(SelectedId,{$set:item_number:init_num})
			init_num++
