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
    # console.log q
    # json带参数的查询
    # ping_url=address+'/'+index+'/'+type+'/_search?'
    # json_parms={
    #   "query":req.result.q
    # }
    # ping_url=address+'/'+index+'/'+type+'/_search?pretty=true -d \'' +json_parms + '\''

    # 简单查询
    query_url=address+"/"+index+"/"+type+"/_search"
    result=HTTP.call('GET',query_url,{params:{q:q,size:size,from:from}})
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