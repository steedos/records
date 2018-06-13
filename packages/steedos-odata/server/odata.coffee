Meteor.startup ->

	odataV4Mongodb = Npm.require 'odata-v4-mongodb'
	querystring = Npm.require 'querystring'

	visitorParser = (visitor)->
		parsedOpt = {}
		if visitor.projection
			parsedOpt.fields = visitor.projection
		if visitor.hasOwnProperty('limit')
			parsedOpt.limit = visitor.limit

		if visitor.hasOwnProperty('skip')
			parsedOpt.skip = visitor.skip

		if visitor.sort
			parsedOpt.sort = visitor.sort

		parsedOpt
	dealWithExpand = (createQuery, entities, key,action)->
		if _.isEmpty createQuery.includes
			return

		obj = Creator.objectsByName[key]
		_.each createQuery.includes, (include)->
			# console.log 'include: ', include
			navigationProperty = include.navigationProperty
			# console.log 'navigationProperty: ', navigationProperty
			field = obj.fields[navigationProperty]
			if field and (field.type is 'lookup' or field.type is 'master_detail')
				if _.isFunction(field.reference_to)
					field.reference_to = field.reference_to()
				if field.reference_to
					queryOptions = visitorParser(include)
					if _.isString field.reference_to
						referenceToCollection = Creator.Collections[field.reference_to]
						_.each entities, (entity, idx)->
							if entity[navigationProperty]
								if field.multiple
									originalData = _.clone(entity[navigationProperty])
									multiQuery = _.extend {_id: {$in: entity[navigationProperty]}}, include.query
									entities[idx][navigationProperty] = referenceToCollection.find(multiQuery, queryOptions).fetch()
									if !entities[idx][navigationProperty].length
										entities[idx][navigationProperty] = originalData
									#排序
									entities[idx][navigationProperty] = Creator.getOrderlySetByIds(entities[idx][navigationProperty], originalData)
								else
									singleQuery = _.extend {_id: entity[navigationProperty]}, include.query

									# 特殊处理在相关表中没有找到数据的情况，返回原数据
									entities[idx][navigationProperty] = referenceToCollection.findOne(singleQuery, queryOptions) || entities[idx][navigationProperty]

					if _.isArray field.reference_to
						_.each entities, (entity, idx)->
							if entity[navigationProperty]?.ids
								referenceToCollection = Creator.Collections[entity[navigationProperty].o]
								if referenceToCollection
									if field.multiple
										_ids = _.clone(entity[navigationProperty].ids)
										multiQuery = _.extend {_id: {$in: entity[navigationProperty].ids}}, include.query
										entities[idx][navigationProperty] = _.map referenceToCollection.find(multiQuery, queryOptions).fetch(), (o)->
											o['reference_to.o'] = referenceToCollection._name
											return o
										#排序
										entities[idx][navigationProperty] = Creator.getOrderlySetByIds(entities[idx][navigationProperty], _ids)
									else
										singleQuery = _.extend {_id: entity[navigationProperty].ids[0]}, include.query
										entities[idx][navigationProperty] = referenceToCollection.findOne(singleQuery, queryOptions)
										if entities[idx][navigationProperty]
											entities[idx][navigationProperty]['reference_to.o'] = referenceToCollection._name

				else
				# TODO


		return

	setOdataProperty=(entities,space,key)->
		entities_OdataProperties = []
		_.each entities, (entity, idx)->
			entity_OdataProperties = {}
			id = entities[idx]["_id"]
			entity_OdataProperties['@odata.id'] = SteedosOData.getODataNextLinkPath(space,key)+ '(\'' + "#{id}" + '\')'
			entity_OdataProperties['@odata.etag'] = "W/\"08D589720BBB3DB1\""
			entity_OdataProperties['@odata.editLink'] = entity_OdataProperties['@odata.id']
			_.extend entity_OdataProperties,entity
			entities_OdataProperties.push entity_OdataProperties
		return entities_OdataProperties

	setErrorMessage = (statusCode,collection,key,action)->
		body = {}
		error = {}
		innererror = {}
		if statusCode == 404
			if collection
				if action == 'post'
					innererror['message'] = t("creator_odata_post_fail")
					innererror['type'] = 'Microsoft.OData.Core.UriParser.ODataUnrecognizedPathException'
					error['code'] = 404
					error['message'] = "creator_odata_post_fail"
				else
					innererror['message'] = t("creator_odata_record_query_fail")
					innererror['type'] = 'Microsoft.OData.Core.UriParser.ODataUnrecognizedPathException'
					error['code'] = 404
					error['message'] = "creator_odata_record_query_fail"
			else
				innererror['message'] = t("creator_odata_collection_query_fail")+ key
				innererror['type'] = 'Microsoft.OData.Core.UriParser.ODataUnrecognizedPathException'
				error['code'] = 404
				error['message'] = "creator_odata_collection_query_fail"
		if  statusCode == 401
			innererror['message'] = t("creator_odata_authentication_required")
			innererror['type'] = 'Microsoft.OData.Core.UriParser.ODataUnrecognizedPathException'
			error['code'] = 401
			error['message'] = "creator_odata_authentication_required"
		if statusCode == 403
			switch action
				when 'get' then innererror['message'] = t("creator_odata_user_access_fail")
				when 'post' then innererror['message'] = t("creator_odata_user_create_fail")
				when 'put' then innererror['message'] = t("creator_odata_user_update_fail")
				when 'delete' then innererror['message'] = t("creator_odata_user_remove_fail")
			innererror['message'] = t("creator_odata_user_access_fail")
			innererror['type'] = 'Microsoft.OData.Core.UriParser.ODataUnrecognizedPathException'
			error['code'] = 403
			error['message'] = "creator_odata_user_access_fail"
		error['innererror'] = innererror
		body['error'] = error
		return body
	SteedosOdataAPI.addRoute(':object_name', {authRequired: true, spaceRequired: false}, {
		get: ()->
			try
				key = @urlParams.object_name
				object = Creator.objectsByName[key]
				if not object?.enable_api
					return {
						statusCode: 401
						body:setErrorMessage(401)
					}
				collection = Creator.Collections[key]
				if not collection
					return {
						statusCode: 404
						body:setErrorMessage(404,collection,key)
					}
				spaceId = @urlParams.spaceId
				permissions = Creator.getObjectPermissions(spaceId, @userId, key)
				if permissions.viewAllRecords or (permissions.allowRead and @userId)
					qs = decodeURIComponent(querystring.stringify(@queryParams))
					createQuery = if qs then odataV4Mongodb.createQuery(qs) else odataV4Mongodb.createQuery()
					if key is 'cfs.files.filerecord'
						createQuery.query['metadata.space'] = spaceId
					else if key is 'spaces'
						createQuery.query._id = spaceId
					else
						createQuery.query.space = spaceId

					if spaceId is 'guest'
						delete createQuery.query.space
					else if Creator.isCommonSpace(spaceId)
						if Creator.isSpaceAdmin(spaceId, @userId)
							if key is 'spaces'
								delete createQuery.query._id
							else
								delete createQuery.query.space
						else
							user_spaces = Creator.getCollection("space_users").find({user: @userId}, {fields: {space: 1}}).fetch()
							if key is 'spaces'
								# space 对所有用户记录为只读
								delete createQuery.query._id
#								createQuery.query._id = {$in: _.pluck(user_spaces, 'space')}
							else
								createQuery.query.space = {$in: _.pluck(user_spaces, 'space')}

					if not createQuery.sort or !_.size(createQuery.sort)
						createQuery.sort = { modified: -1 }
					is_enterprise = Steedos.isLegalVersion(spaceId,"workflow.enterprise")
					is_professional = Steedos.isLegalVersion(spaceId,"workflow.professional")
					is_standard = Steedos.isLegalVersion(spaceId,"workflow.standard")
					if createQuery.limit
						limit = createQuery.limit
						if is_enterprise and limit>100000
							createQuery.limit = 100000
						else if is_professional and limit>10000 and !is_enterprise
							createQuery.limit = 10000
						else if is_standard and limit>1000 and !is_professional and !is_enterprise
							createQuery.limit = 1000
					else
						if is_enterprise
							createQuery.limit = 100000
						else if is_professional and !is_enterprise
							createQuery.limit = 10000
						else if is_standard and !is_enterprise and !is_professional
							createQuery.limit = 1000
					unreadable_fields = permissions.unreadable_fields || []
					if createQuery.projection
						projection = {}
						_.keys(createQuery.projection).forEach (key)->
							if _.indexOf(unreadable_fields, key) < 0
								#if not ((fields[key]?.type == 'lookup' or fields[key]?.type == 'master_detail') and fields[key].multiple)
								projection[key] = 1
						createQuery.projection = projection
					if not createQuery.projection or !_.size(createQuery.projection)
						readable_fields = Creator.getFields(key, spaceId, @userId)
						fields = Creator.getObject(key).fields
						_.each readable_fields,(field)->
							if field.indexOf('$')<0
								if fields[field]?.multiple!= true
									createQuery.projection[field] = 1
					if not permissions.viewAllRecords
						if object.enable_share
							# 满足共享规则中的记录也要搜索出来
							delete createQuery.query.owner
							shares = []
							orgs = Steedos.getUserOrganizations(spaceId, @userId, true)
							shares.push {"owner": @userId}
							shares.push { "sharing.u": @userId }
							shares.push { "sharing.o": { $in: orgs } }
							createQuery.query["$or"] = shares
						else
							createQuery.query.owner = @userId
					entities = []
					if @queryParams.$top isnt '0'
						entities = collection.find(createQuery.query, visitorParser(createQuery)).fetch()
					scannedCount = collection.find(createQuery.query,{fields:{_id: 1}}).count()
					if entities
						dealWithExpand(createQuery, entities, key)
						#scannedCount = entities.length
						body = {}
						headers = {}
						body['@odata.context'] = SteedosOData.getODataContextPath(spaceId, key)
					#	body['@odata.nextLink'] = SteedosOData.getODataNextLinkPath(spaceId,key)+"?%24skip="+ 10
						body['@odata.count'] = scannedCount
						entities_OdataProperties = setOdataProperty(entities,spaceId, key)
						body['value'] = entities_OdataProperties
						headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
						headers['OData-Version'] = SteedosOData.VERSION
						{body: body, headers: headers}
					else
						return{
							statusCode: 404
							body: setErrorMessage(404,collection,key)
						}
				else
					return{
						statusCode: 403
						body: setErrorMessage(403,collection,key,"get")
					}
			catch e
				console.error e.stack
				body = {}
				error = {}
				error['message'] = e.message
				error['code'] = 500
				body['error'] = error
				return {
					statusCode: 500
					body:body
				}
		post: ()->
			try
				key = @urlParams.object_name
				if not Creator.objectsByName[key]?.enable_api
					return {
						statusCode: 401
						body:setErrorMessage(401)
				}

				collection = Creator.Collections[key]
				if not collection
					return {
						statusCode: 404
						body:setErrorMessage(404,collection,key)
					}

				permissions = Creator.getObjectPermissions(@urlParams.spaceId, @userId, key)
				if permissions.allowCreate
					@bodyParams.space = @urlParams.spaceId
					entityId = collection.insert @bodyParams
					entity = collection.findOne entityId
					entities = []
					if entity
						body = {}
						headers = {}
						entities.push entity
						body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key) + '/$entity'
						entity_OdataProperties = setOdataProperty(entities,@urlParams.spaceId, key)
						body['value'] = entity_OdataProperties
						headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
						headers['OData-Version'] = SteedosOData.VERSION
						{body: body, headers: headers}
					else
						return{
							statusCode: 404
							body: setErrorMessage(404,collection,key,'post')
						}
				else
					return{
						statusCode: 403
						body: setErrorMessage(403,collection,key,'post')
					}
			catch e
				body = {}
				error = {}
				error['message'] = e.message
				error['code'] = 500
				body['error'] = error
				return {
					statusCode: 500
					body:body
				}

	})
	SteedosOdataAPI.addRoute(':object_name/recent', {authRequired: true, spaceRequired: false}, {
		get:()->
			try
				key = @urlParams.object_name
				if not Creator.objectsByName[key]?.enable_api
					return{
						statusCode: 401
						body: setErrorMessage(401)
					}
				collection = Creator.Collections[key]
				if not collection
					return {
						statusCode: 404
						body: setErrorMessage(404,collection,key)
					}
				permissions = Creator.getObjectPermissions(@urlParams.spaceId, @userId, key)
				if permissions.allowRead
					recent_view_collection = Creator.Collections["object_recent_viewed"]
					recent_view_selector = {"record.o":key,created_by:@userId}
					recent_view_options = {}
					recent_view_options.sort = {created: -1}
					recent_view_options.fields = {record:1}
					recent_view_records = recent_view_collection.find(recent_view_selector,recent_view_options).fetch()
					recent_view_records_ids = _.pluck(recent_view_records,'record')
					recent_view_records_ids = recent_view_records_ids.getProperty("ids")
					recent_view_records_ids = _.flatten(recent_view_records_ids)
					recent_view_records_ids = _.uniq(recent_view_records_ids)
					qs = decodeURIComponent(querystring.stringify(@queryParams))
					createQuery = if qs then odataV4Mongodb.createQuery(qs) else odataV4Mongodb.createQuery()
					if key is 'cfs.files.filerecord'
						createQuery.query['metadata.space'] = @urlParams.spaceId
					else
						createQuery.query.space = @urlParams.spaceId
					if not createQuery.limit
						createQuery.limit = 100
					if createQuery.limit and recent_view_records_ids.length>createQuery.limit
						recent_view_records_ids = _.first(recent_view_records_ids,createQuery.limit)
					createQuery.query._id = {$in:recent_view_records_ids}
					unreadable_fields = permissions.unreadable_fields || []
				#	fields = Creator.getObject(key).fields
					if createQuery.projection
						projection = {}
						_.keys(createQuery.projection).forEach (key)->
							if _.indexOf(unreadable_fields, key) < 0
							#	if not ((fields[key]?.type == 'lookup' or fields[key]?.type == 'master_detail') and fields[key].multiple)
								projection[key] = 1
						createQuery.projection = projection
					if not createQuery.projection or !_.size(createQuery.projection)
						readable_fields = Creator.getFields(key, @urlParams.spaceId, @userId)
						fields = Creator.getObject(key).fields
						_.each readable_fields,(field)->
							if field.indexOf('$')<0
								if fields[field]?.multiple!= true
									createQuery.projection[field] = 1
					if @queryParams.$top isnt '0'
						entities = collection.find(createQuery.query, visitorParser(createQuery)).fetch()
					entities_index = []
					entities_ids = _.pluck(entities,'_id')
					sort_entities = []
					if not createQuery.sort or !_.size(createQuery.sort)
						_.each recent_view_records_ids ,(recent_view_records_id)->
							index = _.indexOf(entities_ids,recent_view_records_id)
							if index>-1
								sort_entities.push entities[index]
					else
						sort_entities = entities
					if sort_entities
						dealWithExpand(createQuery, sort_entities, key)
						body = {}
						headers = {}
						body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key)
					#	body['@odata.nextLink'] = SteedosOData.getODataNextLinkPath(@urlParams.spaceId,key)+"?%24skip="+ 10
						body['@odata.count'] = sort_entities.length
						entities_OdataProperties = setOdataProperty(sort_entities,@urlParams.spaceId, key)
						body['value'] = entities_OdataProperties
						headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
						headers['OData-Version'] = SteedosOData.VERSION
						{body: body, headers: headers}
					else
						return{
							statusCode: 404
							body: setErrorMessage(404,collection,key,'get')
						}
				else
					console.error e
					return{
						statusCode: 403
						body: setErrorMessage(403,collection,key,'get')
					}
			catch e
				body = {}
				error = {}
				error['message'] = e.message
				error['code'] = 500
				body['error'] = error
				return {
					statusCode: 500
					body:body
				}
})

	SteedosOdataAPI.addRoute(':object_name/:_id', {authRequired: true, spaceRequired: false}, {
		post: ()->
			try
				key = @urlParams.object_name
				if not Creator.objectsByName[key]?.enable_api
					return{
						statusCode: 401
						body: setErrorMessage(401)
					}
				collection = Creator.Collections[key]
				if not collection
					return{
						statusCode: 404
						body: setErrorMessage(404,collection,key)
					}
				permissions = Creator.getObjectPermissions(@urlParams.spaceId, @userId, key)
				if permissions.allowCreate
					@bodyParams.space = @urlParams.spaceId
					entityId = collection.insert @bodyParams
					entity = collection.findOne entityId
					entities = []
					if entity
						body = {}
						headers = {}
						entities.push entity
						body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key) + '/$entity'
						entity_OdataProperties = setOdataProperty(entities,@urlParams.spaceId, key)
						body['value'] = entity_OdataProperties
						headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
						headers['OData-Version'] = SteedosOData.VERSION
						{body: body, headers: headers}
					else
						return{
							statusCode: 404
							body: setErrorMessage(404,collection,key,'post')
						}
				else
					return{
						statusCode: 403
						body: setErrorMessage(403,collection,key,'post')
					}
			catch e
				body = {}
				error = {}
				error['message'] = e.message
				error['code'] = 500
				body['error'] = error
				return {
					statusCode: 500
					body:body
				}
		get:()->

			key = @urlParams.object_name
			if key.indexOf("(") > -1
				body = {}
				headers = {}
				collectionInfo = key
				fieldName = @urlParams._id.split('_expand')[0]
				collectionInfoSplit = collectionInfo.split('(')
				collectionName = collectionInfoSplit[0]
				id = collectionInfoSplit[1].split('\'')[1]

				collection = Creator.Collections[collectionName]
				fieldsOptions = {}
				fieldsOptions[fieldName] = 1
				entity = collection.findOne({_id: id}, {fields: fieldsOptions})

				fieldValue = null
				if entity
					fieldValue = entity[fieldName]

				obj = Creator.objectsByName[collectionName]
				field = obj.fields[fieldName]

				if field  and fieldValue and (field.type is 'lookup' or field.type is 'master_detail')
					lookupCollection = Creator.Collections[field.reference_to]
					lookupObj = Creator.objectsByName[field.reference_to]
					queryOptions = {fields: {}}
					_.each lookupObj.fields, (v, k)->
						queryOptions.fields[k] = 1

					if field.multiple
						body['value'] = lookupCollection.find({_id: {$in: fieldValue}}, queryOptions).fetch()
						body['@odata.context'] = SteedosOData.getMetaDataPath(@urlParams.spaceId) + "##{collectionInfo}/#{@urlParams._id}"
					else
						body = lookupCollection.findOne({_id: fieldValue}, queryOptions) || {}
						body['@odata.context'] = SteedosOData.getMetaDataPath(@urlParams.spaceId) + "##{field.reference_to}/$entity"

				else
					body['@odata.context'] = SteedosOData.getMetaDataPath(@urlParams.spaceId) + "##{collectionInfo}/#{@urlParams._id}"
					body['value'] = fieldValue

				headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
				headers['OData-Version'] = SteedosOData.VERSION

				{body: body, headers: headers}
			else
				try
					object = Creator.objectsByName[key]
					if not object?.enable_api
						return {
							statusCode: 401
							body: setErrorMessage(401)
						}
					collection = Creator.Collections[key]
					if not collection
						return{
							statusCode: 404
							body: setErrorMessage(404,collection,key)
						}

					permissions = Creator.getObjectPermissions(@urlParams.spaceId, @userId, key)
					if permissions.allowRead
						unreadable_fields = permissions.unreadable_fields || []
						qs = decodeURIComponent(querystring.stringify(@queryParams))
						createQuery = if qs then odataV4Mongodb.createQuery(qs) else odataV4Mongodb.createQuery()
						createQuery.query._id =  @urlParams._id
						if key is 'cfs.files.filerecord'
							createQuery.query['metadata.space'] = @urlParams.spaceId
						else
							createQuery.query.space =  @urlParams.spaceId
						unreadable_fields = permissions.unreadable_fields || []
						#fields = Creator.getObject(key).fields
						if createQuery.projection
							projection = {}
							_.keys(createQuery.projection).forEach (key)->
								if _.indexOf(unreadable_fields, key) < 0
								#	if not ((fields[key]?.type == 'lookup' or fields[key]?.type == 'master_detail') and fields[key].multiple)
									projection[key] = 1
							createQuery.projection = projection
						if not createQuery.projection or !_.size(createQuery.projection)
							readable_fields = Creator.getFields(key, @urlParams.spaceId, @userId)
							fields = Creator.getObject(key).fields
							_.each readable_fields,(field)->
								if field.indexOf('$')<0
									createQuery.projection[field] = 1
						entity = collection.findOne(createQuery.query,visitorParser(createQuery))
						entities = []
						if entity
							isAllowed = entity.owner == @userId or permissions.viewAllRecords
							if object.enable_share and !isAllowed
								shares = []
								orgs = Steedos.getUserOrganizations(@urlParams.spaceId, @userId, true)
								shares.push { "sharing.u": @userId }
								shares.push { "sharing.o": { $in: orgs } }
								isAllowed = collection.findOne({ _id: @urlParams._id, "$or": shares }, { fields: { _id: 1 } })
							if isAllowed
								body = {}
								headers = {}
								entities.push entity
								dealWithExpand(createQuery, entities, key)
								body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key) + '/$entity'
								entity_OdataProperties = setOdataProperty(entities,@urlParams.spaceId, key)
								_.extend body,entity_OdataProperties[0]
								headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
								headers['OData-Version'] = SteedosOData.VERSION
								{body: body, headers: headers}
							else
								return{
									statusCode: 403
									body: setErrorMessage(403,collection,key,'get')
								}
						else
							return{
								statusCode: 404
								body: setErrorMessage(404,collection,key,'get')
							}
					else
						return{
							statusCode: 403
							body: setErrorMessage(403,collection,key,'get')
						}
				catch e
					body = {}
					error = {}
					error['message'] = e.message
					error['code'] = 500
					body['error'] = error
					return {
						statusCode: 500
						body:body
					}

		put:()->
			try
				key = @urlParams.object_name
				object = Creator.objectsByName[key]
				if not object?.enable_api
					return{
						statusCode: 401
						body: setErrorMessage(401)
					}

				collection = Creator.Collections[key]
				if not collection
					return{
						statusCode: 404
						body: setErrorMessage(404,collection,key)
					}
				permissions = Creator.getObjectPermissions(@urlParams.spaceId, @userId, key)
				record_owner = collection.findOne({_id: @urlParams._id, space: @urlParams.spaceId})?.owner
				isAllowed = permissions.modifyAllRecords or (permissions.allowEdit and record_owner == @userId )
				if isAllowed
					selector = {_id: @urlParams._id, space: @urlParams.spaceId}
					fields_editable = true
					_.keys(@bodyParams.$set).forEach (key)->
						if _.indexOf(permissions.uneditable_fields, key) > -1
							fields_editable = false
					if fields_editable
						entityIsUpdated = collection.update selector, @bodyParams
						if entityIsUpdated
							#statusCode: 201
							# entity = collection.findOne @urlParams._id
							# entities = []
							# body = {}
							headers = {}
							body = {}
							# entities.push entity
							# body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key) + '/$entity'
							# entity_OdataProperties = setOdataProperty(entities,@urlParams.spaceId, key)
							# _.extend body,entity_OdataProperties[0]
							headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
							headers['OData-Version'] = SteedosOData.VERSION
							{headers: headers,body:body}
						else
							return{
								statusCode: 404
								body: setErrorMessage(404,collection,key)
							}
					else
						return{
							statusCode: 403
							body: setErrorMessage(403,collection,key,'put')
						}
				else
					return{
						statusCode: 403
						body: setErrorMessage(403,collection,key,'put')
					}
			catch e
				body = {}
				error = {}
				error['message'] = e.message
				error['code'] = 500
				body['error'] = error
				return {
					statusCode: 500
					body:body
				}
		delete:()->
			try
				key = @urlParams.object_name
				object = Creator.objectsByName[key]
				if not object?.enable_api
					return{
						statusCode: 401
						body: setErrorMessage(401)
						}

				collection = Creator.Collections[key]
				if not collection
					return{
						statusCode: 404
						body: setErrorMessage(404,collection,key)
					}
				permissions = Creator.getObjectPermissions(@urlParams.spaceId, @userId, key)
				record_owner = collection.findOne({_id: @urlParams._id, space: @urlParams.spaceId})?.owner
				isAllowed = permissions.modifyAllRecords or (permissions.allowDelete and record_owner==@userId )
				if isAllowed
					selector = {_id: @urlParams._id, space: @urlParams.spaceId}
					if collection.remove selector
						headers = {}
						body = {}
						# entities.push entity
						# body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key) + '/$entity'
						# entity_OdataProperties = setOdataProperty(entities,@urlParams.spaceId, key)
						# _.extend body,entity_OdataProperties[0]
						headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
						headers['OData-Version'] = SteedosOData.VERSION
						{headers: headers,body:body}
					else
						return{
							statusCode: 404
							body: setErrorMessage(404,collection,key)
						}
				else
					return {
						statusCode: 403
						body: setErrorMessage(403,collection,key)
					}
			catch e
				body = {}
				error = {}
				error['message'] = e.message
				error['code'] = 500
				body['error'] = error
				return {
					statusCode: 500
					body:body
				}
	})

	#TODO remove
	_.each [], (value, key, list)-> #Creator.Collections
		if not Creator.objectsByName[key]?.enable_api
			return

		if SteedosOdataAPI

			SteedosOdataAPI.addCollection Creator.Collections[key],
				excludedEndpoints: []
				routeOptions:
					authRequired: true
					spaceRequired: false
				endpoints:
					getAll:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@urlParams.spaceId, @userId, key)
							if permissions.viewAllRecords or (permissions.allowRead and @userId)
									qs = decodeURIComponent(querystring.stringify(@queryParams))
									createQuery = if qs then odataV4Mongodb.createQuery(qs) else odataV4Mongodb.createQuery()

									if key is 'cfs.files.filerecord'
										createQuery.query['metadata.space'] = @urlParams.spaceId
									else
										createQuery.query.space = @urlParams.spaceId

									if not permissions.viewAllRecords
										createQuery.query.owner = @userId

									entities = []
									if @queryParams.$top isnt '0'
										entities = collection.find(createQuery.query, visitorParser(createQuery)).fetch()
									scannedCount = collection.find(createQuery.query).count()

									if entities
										dealWithExpand(createQuery, entities, key)

										body = {}
										headers = {}
										body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key)
										body['@odata.count'] = scannedCount
										body['value'] = entities
										headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
										headers['OData-Version'] = SteedosOData.VERSION
										{body: body, headers: headers}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Unable to retrieve items from collection'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					post:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowCreate
									@bodyParams.space = @spaceId
									entityId = collection.insert @bodyParams
									entity = collection.findOne entityId
									if entity
										statusCode: 201
										{status: 'success', value: entity}
									else
										statusCode: 404
										body: {status: 'fail', message: 'No item added'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					get:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowRead
									selector = {_id: @urlParams.id, space: @spaceId}
									entity = collection.findOne selector
									if entity
										{status: 'success', value: entity}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Item not found'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					put:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowEdit
									selector = {_id: @urlParams.id, space: @spaceId}
									entityIsUpdated = collection.update selector, $set: @bodyParams
									if entityIsUpdated
										entity = collection.findOne @urlParams.id
										{status: 'success', value: entity}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Item not found'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					delete:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowDelete
									selector = {_id: @urlParams.id, space: @spaceId}
									if collection.remove selector
										{status: 'success', message: 'Item removed'}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Item not found'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
