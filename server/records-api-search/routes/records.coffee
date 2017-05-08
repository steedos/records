Meteor.startup ->
	JsonRoutes.add "get", "/records/:search", (req, res, next) ->
		#传入的参数  ----  draw：直接返回|columns:列|start:开始|length：页长度|...|自定义参数...
		#从ES中查询数据
		# console.log req
		address="http://localhost:9200"
		index=req.query.index
		type=req.query.type
		from=req.query.start+""  #string型
		size=req.query.length+""  #string型,默认是10
		q=req.query.q+""
		# console.log q
		if req.query.q==""||req.query.q==null
			q="*"
		query_url=address+"/"+index+"/"+type+"/_search"
		
		data = {
			# "query": {
			# 	"multi_match": {
			# 		"query": "#{q}",
			# 		"type": "cross_fields",
			# 		"fields": [
			# 			"name",
			# 			"values",
			# 			"attachments.cfs_*"
			# 		],
			# 		"operator": "or"
			# 	}
			# }
			"query": {
				"bool" : {
					"must" : {
						"multi_match": {
							"query": "#{q}",
							"type": "cross_fields",
							"fields": [
								"name",
								"values",
								"attachments.*"
							],
							"operator": "or"
						}
					},
					"filter" : {
						"match": {
							"users": {
								# 用户ID
								"query": "5474355f527eca77fc00c25d",
								"type": "phrase"
							}
						}
					}
				}
			}
			,
			"sort": { "modified": { "order": "desc" }},
			"highlight": {
				"pre_tags":["<strong>"],
				"post_tags":["</strong>"]
				"fields": {
					"name":{},
					"values": {},
					"attachments.*": {}
				}
			}
		};

		params = {size:size,from:from}

		# console.log "#{query_url}"

		# console.log "#{JSON.stringify(data)}"

		result=HTTP.call(
			'POST',
			query_url,
			{
				params: params,
				data: data
			}
		)
		# console.log JSON.stringify(result)
		jsonData={
			"draw":0,
			"recordsTotal":0,
			"recordsFiltered":0,
			"data":[]
		}
		if result.statusCode==200
			srcData=result.data.hits
			# console.log "111111"+JSON.stringify(srcData)
			jsonData.recordsTotal=srcData.total
			jsonData.recordsFiltered=srcData.total
			jsonData.data=srcData.hits
		else
			jsonData.error="Network is error,Please try again!"

		# console.log "222222"+JSON.stringify(jsonData)
		# if result._shards.failed==0
		#     data={
		#         "draw":req.query.draw,
		#         "recordsTotal":3,
		#         "recordsFiltered":3,
		#         "data":[],
		#         "error":"Elasticsearch error,Please try again!"
		#     }
		# else
		#     console.log result
		#     data={
		#         "draw":0,
		#         "recordsTotal":0,
		#         "data":[],
		#         "error":"Elasticsearch error,Please try again!"
		#     }
		JsonRoutes.sendResult res,data:jsonData
		return