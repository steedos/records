# @search_route=eteor.settings.records_search_api.search_route			#配置后的接口路径，系统中暂时未使用
@search_records_url='http://localhost:3000/records/:search'
@index='records'
@type='instances'
# pageLength=10
Template.search_records_repository.events
	'click .btn.btn-search':(event)->
		seatch_txt=$('.txt-search.form-control').val()+''
		ajaxUrl=search_records_url+'?index='+index+'&type='+type+'&q='+seatch_txt
		$('.table-records-result').DataTable().ajax.url(ajaxUrl).load();

Template.search_records_repository.onRendered ->
	seatch_txt=$('.txt-search.form-control').val()+''
	ajaxUrl=search_records_url+'?index='+index+'&type='+type+'&q='+seatch_txt
	$('.table-records-result').dataTable({
		'paginate': true, #翻页功能
		'lengthChange': false, #改变每页显示数据数量
		'filter': false, #过滤功能
		'sort': false, #排序功能
		'info': true,  #页脚信息
		'processing': true,
		'language': {
			'thousands': ','    #千级别的数据显示格式
		}
		'pageLength':10,
		'autoWidth': false,#不自动计算列宽度
		'serverSide': true,
		'columns': [
			{ 'data': '_source.name'},
			{ 'data': '_type'},
			{ 'data': '_source.submitter_name'}
		],
		# 高版本datatables插件的服务器端分页方法
		'ajax': {
			type: 'GET',
			url: ajaxUrl,
			dataType: 'json'
			# data: {
			# 	'q':seatch_txt,
			# 	'index':'records',
			# 	'type':'instances'
			# }
		}
		# 创建行时候改变行的样式，调样式在这里写
		'createdRow': ( row, data, index )->
			console.log data

		#####################################################
		# 低版本datatables插件的服务器端分页方法
		# 'sAjaxSource':search_records_url,
		# 'fnServerData': (sSource, aoData, fnCallback)->
		# 	console.log JSON.stringify(aoData)
		# 	console.log JSON.stringify(sSource)
		# 	$.ajax({
		# 		'type': 'get', 
		# 		'contentType': 'application/json', 
		# 		'url': sSource, 
		# 		'dataType': 'json', 
		# 		'data': (auto)->
					# aoData:JSON.stringify(aoData)
					# auto.push('key1','value1')
		# 		}, #以json格式传递
		# 		'success': (resp)->
		# 			console.log JSON.stringify(resp)
		# 			fnCallback(resp) 
		# 	})
		#####################################################
	})
