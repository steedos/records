Meteor.startup ()->
	JsonRoutes.add "get", "/delete", (req, res, next) ->
		address=es_server
		index=Meteor.settings.records.es_search_index
		type="instances"
		instanceId=req.instanceId
		delete_url=address+"/"+index+"/"+type+"/"+instanceId
		result = HTTP.call(
			'DELETE',
			delete_url
		)
		console.log result
		if result.statusCode == 200
			srcData = result.data.hits
			jsonData.recordsTotal = srcData.total
			jsonData.recordsFiltered = srcData.total
			jsonData.data = srcData.hits
		else
			jsonData.error = "网络异常！"
		JsonRoutes.sendResult res,data:jsonData
		return
