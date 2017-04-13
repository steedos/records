FormData = Npm.require('form-data');
FS = Npm.require('fs');
request = Npm.require('request')

InstancesToArchive = (spaces, archive_server, to_archive_api, contract_flows) ->
	@spaces = spaces
	@archive_server = archive_server
	@to_archive_api = to_archive_api
	@contract_flows = contract_flows
	return

InstancesToArchive::getContractInstances = ()->
	return db.instances.find({
		space: {$in: @spaces},
		flow: {$in: @contract_flows},
		is_archived: false,
		is_deleted: false,
		state: "completed",
		final_decision: "approved"
	});

InstancesToArchive::getNonContractInstances = ()->
	return db.instances.find({
		space: {$in: @spaces},
		flow: {$nin: @contract_flows},
		is_archived: false,
		is_deleted: false,
		state: "completed",
		final_decision: "approved"
	});

InstancesToArchive._postFormData = (url, formData) ->
	console.log url
#	formData.submit params, (error, response)->
#		if error
#			console.log "error is"
#			console.log error
#		if response
#			console.log "response is"
#			console.error response.statusCode

	request.post {
		url: url
		formData: formData
	}, (err, httpResponse, body) ->
		if err
			return console.error('upload failed:', err)
		console.log 'Upload successful!  Server responded with:', body
		return

InstancesToArchive::sendContractInstances = (field_map)->

	instances = @getContractInstances()
	console.log "instances count is #{instances.count()}"

	that = @

	instances.fetch().forEach (instance, i)->
		if i != 0
			return;
		console.log "instance name is #{instance.name}"
		url = that.archive_server + that.to_archive_api + '?instanceId=' + instance._id
	#	原文

	#	正文

	#	附件

	#	表单数据
#		formData = new FormData();
		formData = {}
#		formData.my_logo = request('http://nodejs.org/images/logo.png');

		fieldsValues = instance.values

		console.log fieldsValues

		console.log fieldsValues['record_fond']

		fieldNames = _.keys(field_map)

		fieldNames.forEach (fieldName)->
			key = field_map[fieldName]

			fieldValue = fieldsValues[key]

			console.info "key is #{key}, fieldName is #{fieldName}, fieldValue is #{fieldValue}"

			switch fieldName
				when 'fileID'
					fieldValue = instance._id
				when 'FILETABLE_NAME'
					fieldValue = ""
				when 'FILEEXT'
					fieldValue = ""
				when 'useridinfo'
					fieldValue = ""
				when 'FILESIZE'
					fieldValue = ""
				when 'fileNameinfo'
					fieldValue = ""

			formData[fieldName] = encodeURI(fieldValue)

		console.log "formData is "
		console.log formData

		InstancesToArchive._postFormData(url, formData);

