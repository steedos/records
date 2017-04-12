FormData = Npm.require('form-data');
FS = Npm.require('fs');

InstancesToArchive = (spaces, archive_server, to_archive_api, contract_flows, field_map) ->
	@spaces = spaces
	@archive_server = archive_server
	@to_archive_api = to_archive_api
	@contract_flows = contract_flows
	@field_map = field_map

InstancesToArchive::getContractInstances = ()->
	return db.instances.find({
		space: {$in: @spaces},
		flow: {$in: @contract_flows},
		is_archived: false,
		is_delete: false,
		state: "completed",
		final_decision: "approved"
	});

InstancesToArchive::getNonContractInstances = ()->
	return db.instances.find({
		space: {$in: @spaces},
		flow: {$nin: @contract_flows},
		is_archived: false,
		is_delete: false,
		state: "completed",
		final_decision: "approved"
	});

InstancesToArchive._postFormData = (formData) ->
	ulr = @archive_server + @to_archive_api
	formData.submit url, (error, response)->
		console.log response.statusCode

InstancesToArchive::sendContractInstances = ()->
	instances = @getContractInstances()
	instances.fetch().forEach (instance)->
	#	原文

	#	正文

	#	附件

	#	表单数据
		formData = new FormData();

		fieldsValues = instance.values

		fieldNames = _.keys(@field_map)

		fieldNames.forEach (fieldName)->
			key = @field_map[fieldName]
			switch key
				when 'fileID'
					formData.append(key, instance._id);
				when 'FILETABLE_NAME'
					console.log("key is #{key}")
				when 'FILEEXT'
					console.log("key is #{key}")
				when 'useridinfo'
					console.log("key is #{key}")
				when 'FILESIZE'
					console.log("key is #{key}")
				when 'fileNameinfo'
					console.log("key is #{key}")
				else
					formData.append(fieldName, fieldsValues[key]);

		InstancesToArchive._postFormData(formData)

