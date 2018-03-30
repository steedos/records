Meteor.methods
	archive_transfer: (record_id,space) ->
		result = []
		successNum = 0
		related_object_name = Creator.Collections["archive_transfer"].findOne(_id:record_id)?.transfer_category
		if related_object_name
			collection = Creator.Collections[related_object_name]
			related_acrhive_records = Creator.Collections[related_object_name].find({archive_transfer_id:record_id},{fields:{_id:1}}).fetch()
			totalNum = related_acrhive_records.length
			result.push totalNum
			related_acrhive_records.forEach (related_acrhive_record)->	
				newSuccessNum = collection.update({_id:related_acrhive_record._id},{$set:{is_transfered:true,transfered_by:Meteor.userId(),transfered:new Date()}})
				successNum = successNum+ newSuccessNum
				if newSuccessNum
					Meteor.call("archive_new_audit",related_acrhive_record._id,"移交档案","成功",space)
				else
					Meteor.call("archive_new_audit",related_acrhive_record._id,"移交档案","失败",space)
			result.push successNum
		return result