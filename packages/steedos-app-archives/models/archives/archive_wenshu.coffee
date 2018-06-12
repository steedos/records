# logger = new Logger 'ARCHIVE_WENSHU'

set_archivecode = (record_id)->
	record = Creator.Collections["archive_wenshu"].findOne(record_id,{fields:{archival_code:1,fonds_name:1,retention_peroid:1,organizational_structure:1,year:1,item_number:1}})
	if record?.item_number and record?.fonds_name and  record?.retention_peroid and record?.organizational_structure and record?.year
		fonds_name_code = Creator.Collections["archive_fonds"].findOne(record.fonds_name,{fields:{code:1}})?.code
		retention_peroid_code = Creator.Collections["archive_retention"].findOne(record.retention_peroid,{fields:{code:1}})?.code
		organizational_structure_code = Creator.Collections["archive_organization"].findOne(record.organizational_structure,{fields:{code:1}})?.code
		#organizational_structure_code = "BGS"
		year = record.year
		item_number = (Array(6).join('0') + record.item_number).slice(-4)
		archive_code = fonds_name_code + "-WS" + "-"+year + "-"+ retention_peroid_code + "-"+ organizational_structure_code + "-"+item_number
		Creator.Collections["archive_wenshu"].direct.update(record_id,{$set:{archival_code:archive_code}})
		
Creator.Objects.archive_wenshu =
	name: "archive_wenshu"
	icon: "record"
	label: "文书档案"
	enable_search: true
	enable_files: true
	enable_api: true
	fields:
		old_id:
			type:"text"
			label:"编号"
			omit:true
			group:"来源"
		archives_name:
			type:"text"
			label:"档案馆名称"
			# omit:true
			group:"来源"
		archives_identifier:
			type:"text"
			label:"档案馆代码"
			# omit:true
			group:"来源"
		fonds_name:
			type:"master_detail"
			label:"全宗名称"
			reference_to:"archive_fonds"
			# omit:true
			group:"来源"
		archival_category_code:
			type: "text"
			label:"档案门类代码"
			defaultValue: "WS"
			group:"内容描述"
			# omit:true

		fonds_constituting_unit_name:
			type: "text"
			label:"立档单位名称"
			defaultValue: ""
			# omit:true
			group:"来源"

		aggregation_level:
			type: "select"
			label:"聚合层次"
			defaultValue: "文件"
			options:[
				{label:"案卷",value:"案卷"},
				{label:"文件",value:"文件"}]
			# omit:true
			group:"内容描述"

		electronic_record_code:
			type: "text"
			label:"电子文件号"
			defaultValue: ""
			group:"电子文件号"
			# omit:true

		archival_code:
			type:"text"
			label:"档号"
			group:"档号"
			# omit:true
		fonds_identifier:
			type:"master_detail"
			label:"全宗号"
			reference_to:"archive_fonds"
			group:"档号"
			omit:true
		year:
			type: "text"
			label:"年度"
			defaultValue: "2018"
			#required:true
			sortable:true
			group:"档号"

		retention_peroid:
			type:"master_detail"
			label:"保管期限"
			reference_to:"archive_retention"
			#required:true
			sortable:true
			group:"档号"

		category_code:
			type:"master_detail"
			label:"类别号"
			defaultValue: ""
			reference_to: "archive_classification"
			#required:true
			group:"档号"

		organizational_structure:
			type:"master_detail"
			label:"机构"
			reference_to: "archive_organization"
			group:"档号"

		file_number:
			type:"text"
			label:"保管卷号"
			group:"档号"
			# omit:true

		classification_number:
			type:"text"
			label:"分类卷号"
			group:"档号"
			# omit:true

		item_number:
			type: "number"
			label:"件号"
			group:"档号"
			sortable:true
			# omit:true

		document_sequence_number:
			type: "number"
			label:"文档序号"
			group:"档号"

		page_number:
			type: "number"
			label:"页号"
			group:"档号"

		title:
			type:"textarea"
			label:"题名"
			is_wide:true
			is_name:true
			#required:true
			sortable:true
			searchable:true
			group:"内容描述"

		parallel_title:
			type: "text"
			label:"并列题名"
			group:"内容描述"

		other_title_information:
			type:"text"
			label:"说明题名文字"
			group:"内容描述"
		annex_title:
			type:"textarea"
			label:"附件题名"
			is_wide:true
			group:"内容描述"
		descriptor:
			type:"text"
			label:"主题词"
			# omit:true
			group:"内容描述"
		keyword:
			type:"text"
			label:"关键词"
			# omit:true
			group:"内容描述"
		personal_name:
			type:"text"
			label:"人名"
			group:"内容描述"
		abstract:
			type:"text"
			label:"摘要"
			# omit:true
			group:"内容描述"
		document_number:
			type:"text"
			label:"文件编号"
			group:"内容描述"
			sortable:true
		author:
			type:"text"
			label:"责任者"
			#required:true
			group:"内容描述"
		document_date:
			type:"date"
			label:"文件日期"
			format:"YYYYMMDD"
			#required:true
			group:"内容描述"
			sortable:true

		start_date:
			type:"date"
			label:"起始日期"
			format:"YYYYMMDD"
			group:"内容描述"
			# omit:true

		closing_date:
			type:"date"
			label:"截止日期"
			format:"YYYYMMDD"
			group:"内容描述"
			# omit:true
		destroy_date:
			type:"date"
			label:"销毁日期"
			format:"YYYYMMDD"
			group:"内容描述"
			omit:true
		precedence:
			type:"text"
			label:"紧急程度"
			# omit:true
			group:"内容描述"
		prinpipal_receiver:
			type:"text",
			label:"主送",
			group:"内容描述"

		other_receivers:
			type:"text",
			label:"抄送",
			group:"内容描述"

		report:
			type:"text",
			label:"抄报",
			group:"内容描述"

		security_classification:
			type:"select"
			label:"密级"
			defaultValue: "公开"
			options: [
				{label: "公开", value: "公开"},
				{label: "限制", value: "限制"},
				{label: "秘密", value: "秘密"},
				{label: "机密", value: "机密"},
				{label: "绝密", value: "绝密"},
				{label: "非密", value: "非密"}
			]
			allowedValues:["公开","限制","秘密","机密","绝密","非密","普通"]
			#required:true
			sortable:true
			group:"内容描述"

		applicant_name:
			type:"text"
			label:"拟稿人"
			group:"内容描述"
			# omit:true

		applicant_organization_name:
			type:"text"
			label:"拟稿单位"
			group:"内容描述"
			# omit:true

		secrecy_period:
			type:"select"
			label:"保密期限"
			options: [
				{label: "10年", value: "10年"},
				{label: "20年", value: "20年"},
				{label: "30年", value: "30年"}
			]
			group:"内容描述"

		document_aggregation:
			type:"select",
			label:"文件组合类型",
			defaultValue: "单件"
			options: [
				{label: "单件", value: "单件"},
				{label: "组合文件", value: "组合文件"}
			]
			group:"形式特征"

		total_number_of_items:
			type: "text"
			label:"卷内文件数"
			group:"形式特征"
			# omit:true

		total_number_of_pages:
			type:"number"
			label:"页数"
			group:"形式特征"

		document_type:
			type:"text"
			label:"文件类型"
			group:"形式特征"
			# omit:true

		document_status:
			type:"select",
			label:"文件状态",
			defaultValue: "不归档"
			options: [
				{label: "不归档", value: "不归档"},
				{label: "电子归档", value: "电子归档"},
				{label: "暂存", value: "暂存"},
				{label: "待归档", value: "待归档"},
				{label: "实物归档", value: "实物归档"}
			]
			allowedValues:["不归档","电子归档","待归档","暂存","实物归档"]
			group:"形式特征"

		language:
			type:"text"
			label:"语种"
			defaultValue: "汉语"
			group:"形式特征"

		orignal_document_creation_way:
			type:"text"
			label:"电子档案生成方式"
			defaultValue: "原生"
			options: [
				{label: "数字化", value: "数字化"},
				{label: "原生", value: "原生"}
			]
			group:"形式特征"
			# omit:true

		format_name:
			type:"text"
			label:"格式名称"
			# omit:true
			group:"电子属性"
		format_version:
			type:"text"
			label:"格式版本"
			# omit:true
			group:"电子属性"
		computer_file_name:
			type:"text"
			label:"计算机文件名"
			# omit:true
			group:"电子属性"
		document_size:
			type:"text"
			label:"计算机文件大小"
			# omit:true
			group:"电子属性"
		physical_record_characteristics:
			type:"text"
			label:"数字化对象形态"
			# omit:true
			group:"数字化属性"
		scanning_resolution:
			type:"text"
			label:"扫描分辨率"
			# omit:true
			group:"数字化属性"
		scanning_color_model:
			type:"text"
			label:"扫描色彩模式"
			# omit:true
			group:"数字化属性"
		image_compression_scheme:
			type:"text"
			label:"图像压缩方案"
			# omit:true
			group:"数字化属性"
		device_type:
			type:"text"
			label:"设备类型"
			# omit:true
			group:"数字化设备信息"
		device_manufacturer:
			type:"text"
			label:"设备制造商"
			# omit:true
			group:"数字化设备信息"
		device_model_number:
			type:"text"
			label:"设备型号"
			# omit:true
			group:"数字化设备信息"
		device_model_serial_number:
			type:"text"
			label:"设备序列号"
			# omit:true
			group:"数字化设备信息"
		software_type:
			type:"text"
			label:"软件类型"
			# omit:true
			group:"数字化设备信息"
		software_name:
			type:"text"
			label:"软件名称"
			# omit:true
			group:"数字化设备信息"
		signature_rules:
			type:"text"
			label:"签名规则"
			# omit:true
			group:"电子签名"
		signature_time:
			type:"datetime"
			label:"签名时间"
			# omit:true
			group:"电子签名"
		signer:
			type:"text"
			label:"签名人"
			# omit:true
			group:"电子签名"
		signature:
			type:"text"
			label:"签名结果"
			# omit:true
			group:"电子签名"
		certificate:
			type:"text"
			label:"证书"
			# omit:true
			group:"电子签名"
		certificate_reference:
			type:"text"
			label:"证书引证"
			# omit:true
			group:"电子签名"
		signature_algorithm_identifier:
			type:"text"
			label:"签名算法标识"
			# omit:true
			group:"电子签名"
		current_location:
			type:"text"
			label:"当前位置"
			# omit:true
			group:"存储位置"
		offline_medium_identifier:
			type:"text"
			label:"脱机载体编号"
			group:"存储位置"
		offline_medium_storage_location:
			type:"text"
			label:"脱机载体存址"
			group:"存储位置"
		intelligent_property_statement:
			type: "text"
			label:"知识产权说明"
			group:"权限管理"
		authorized_agent:
			type: "text"
			label:"授权对象"
			group:"权限管理"
		permission_assignment:
			type: "select"
			label:"授权行为"
			options: [
				{label: "公布", value: "公布"},
				{label: "复制", value: "复制"},
				{label: "浏览", value: "浏览"},
				{label: "解密", value: "解密"}

			]
			# omit:true
			group:"权限管理"
		control_identifier:
			type: "select"
			label:"控制标识"
			options: [
				{label: "开放", value: "开放"},
				{label: "控制", value: "控制"}
			]
			# omit:true
			group:"权限管理"
		agent_type:
			type: "select"
			label:"机构人员类型"
			defaultValue:"部门"
			options: [
				{label: "单位", value: "单位"},
				{label: "部门", value: "部门"},
				{label: "个人", value: "个人"}
			]
			group:"机构人员"
			# omit:true
		agent_name:
			type: "text"
			label:"机构人员名称"
			group:"机构人员"
			# omit:true
		organization_code:
			type: "text"
			label:"组织机构代码"
			group:"机构人员"
			# omit:true
		agent_belongs_to:
			type: "text"
			label:"机构人员隶属"
			group:"机构人员"
			# omit:true

		archive_date:
			type:"date"
			label:"归档日期"
			group:"内容描述"
			# omit:true

		archive_dept:
			type:"text"
			label:"归档部门"
			defaultValue: ""
			group:"内容描述"

		produce_flag:
			type:"select",
			label:"处理标志",
			defaultValue: "在档"
			options: [
				{label: "在档", value: "在档"},
				{label: "暂存", value: "暂存"},
				{label: "移出", value: "移出"},
				{label: "销毁", value: "销毁"},
				{label: "出借", value: "出借"}
			]
			group:"内容描述"
			# omit:true

		main_dept:
			type:"text",
			label:"主办部室",
			is_wide:true
			defaultValue: ""
			group:"内容描述"

		annotation:
			type:"textarea",
			label:"备注",
			is_wide:true
			group:"内容描述"

		storage_location:
			type:"text"
			label:"存放位置"
			group:"内容描述"
			# omit:true

		reference:
			type: "text"
			label:"参见"
			group:"内容描述"
			# omit:true
		#是否接收，默认是未接收
		is_received:
			type:"boolean"
			label:"是否接收"
			defaultValue:false
			omit:true

		received:
			type:"datetime"
			label:"接收时间"
			omit:true

		received_by:
			type: "lookup"
			label:"接收人"
			reference_to: "users"
			omit: true
		#是否移交，默认是不存在，在“全部”视图下点击移交，进入“待移交”视图，此时is_transfer=false
		#审核通过之后，is_transfer = true
		is_transfered:
			type:"boolean"
			omit:true
			label:"是否移交"
		transfered:
			type:"datetime"
			label:"移交时间"
			omit:true
		transfered_by:
			type: "lookup"
			label:"移交人"
			reference_to: "users"
			omit: true

		#是否销毁，默认是不存在，在“全部”视图下点击销毁，进入“待销毁”视图，此时is_destroy=false
		#审核通过之后，is_transfer = true
		is_destroyed:
			type:"boolean"
			label:'是否销毁'
			omit:true
			group:"销毁"
		destroyed:
			type:"datetime"
			label:'实际销毁时间'
			omit:true
			group:"销毁"
		destroyed_by:
			type: "lookup"
			label:"销毁人"
			reference_to: "users"
			omit: true
			group:"销毁"
		is_borrowed:
			type:"boolean"
			defaultValue:false
			label:'是否借阅'
			omit:true
		borrowed:
			type:"datetime"
			label:"借阅时间"
			omit:true
		borrowed_by:
			type: "lookup"
			label:"借阅人"
			reference_to: "users"
			omit: true
		#如果是从OA归档过来的档案，则值为表单Id,否则不存在改字段
		external_id:
			type:"text"
			label:'表单Id'
			omit:true
			group:"内容描述"
		archive_destroy_id:
			type:"master_detail"
			label:"销毁单"
			filters:[["destroy_state", "$eq", "未销毁"]]
			depend_on:["destroy_state"]
			reference_to:"archive_destroy"
			group:"销毁"
		related_modified:
			type:"datetime"
			label:"附属更新时间"
			omit:true
		related_archives:
			label:'关联文件'
			type:'lookup'
			reference_to:'archive_wenshu'
			multiple:true
		archive_transfer_id:
			type:"master_detail"
			label:"移交单"
			reference_to:"archive_transfer"
			group:"移交"
	list_views:
		recent:
			label: "最近查看"
			filter_scope: "space"
		all:
			label: "全部"
			filter_scope: "space"
			filters: [["is_received", "=", true]]
			#columns: ["year","retention_peroid","item_number","title","archival_code","document_date","author","category_code",
					#	"archive_date","archive_dept","security_classification"]
			columns:['item_number','archival_code',"author","title","electronic_record_code","total_number_of_pages","annotation",'archive_transfer_id']
		borrow:
            label:"查看"
            filter_scope: "space"
            filters: [["is_received", "=", true]]
            columns:['document_sequence_number',"author","title","document_date","total_number_of_pages","annotation"]
		receive:
			label:"待接收"
			filter_scope: "space"
			filters: [["is_received", "=", false]]
		transfered:
			label:"已移交"
			filter_scope: "space"
			filters: [["is_transfered", "=", true]]
			columns:["title","fonds_name","archive_transfer_id","transfered","transfered_by"]
		destroy:
			label:"待销毁"
			filter_scope: "space"
			filters: [["is_received", "=", true],["destroy_date","<=",new Date()],["is_destroyed", "=", false]]
			columns:["year","title","document_date","destroy_date","archive_destroy_id"]
	permission_set:
		user:
			allowCreate: false
			allowDelete: false
			allowEdit: false
			allowRead: true
			modifyAllRecords: false
			viewAllRecords: true
			list_views:["default","recent","all","borrow"]
			actions:["borrow"]
		admin:
			allowCreate: true
			allowDelete: true
			allowEdit: true
			allowRead: true
			modifyAllRecords: true
			viewAllRecords: true
			list_views:["default","recent","all","borrow"]
			actions:["borrow"]
	triggers:
		"before.insert.server.default":
			on: "server"
			when: "before.insert"
			todo: (userId, doc)->
				doc.is_received = false
				doc.is_destroyed = false
				doc.is_borrowed = false
				rules = Creator.Collections["archive_rules"].find({fieldname:'title'},{fields:{keywords:1}}).fetch()
				rules_keywords = _.pluck rules, "keywords"
				i = 0
				while i < rules_keywords.length
					is_matched = true
					j = 0
					arrs = rules_keywords[i]
					while j < arrs.length
						if doc.title.indexOf(arrs[j])<0
							is_matched = false
							break;
						j++
					if is_matched
						match_rule = rules_keywords[i]
						rule_id = rules[i]._id
						break;
					i++
				if rule_id
					category_retention = Creator.Collections["archive_rules"].findOne({_id:rule_id},{fields:{classification:1,retention:1}})
					doc.category_code = category_retention.classification
					doc.retention_peroid = category_retention.retention
					duration = Creator.Collections["archive_retention"].findOne({_id:doc.retention_peroid}).years
					year = doc.document_date.getFullYear()+duration
					month = doc.document_date.getMonth()
					day = doc.document_date.getDate()
					doc.destroy_date = new Date(year,month,day)
				return true

		"before.update.server.default":
			on: "server"
			when: "before.update"
			todo: (userId, doc, fieldNames, modifier, options)->
				doc.retention_peroid = "DRmxfw7ByKd92gXsK"

		"after.update.server.default":
			on: "server"
			when: "after.update"
			todo: (userId, doc, fieldNames, modifier, options)->
				if modifier['$set']?.item_number or modifier['$set']?.organizational_structure or modifier['$set']?.retention_peroid or modifier['$set']?.fonds_name or modifier['$set']?.year
                    set_archivecode(doc._id)
                if modifier['$set']?.retention_peroid
                	duration = Creator.Collections["archive_retention"].findOne({_id:doc.retention_peroid})?.years
					if duration
						year = doc.document_date.getFullYear()+duration
						month = doc.document_date.getMonth()
						day = doc.document_date.getDate()
						destroy_date = new Date(year,month,day)
						Creator.Collections["archive_wenshu"].direct.update({_id:doc._id},{$set:{destroy_date:destroy_date}})
				# logger.info "AAA"

	actions:
		number_adjuct:
			label:'编号调整'
			visible:true
			on:'list'
			todo:(object_name)->
				if Creator.TabularSelectedIds?[object_name].length == 0
					swal("请先选择要接收的档案")
					return
				init_num = prompt("输入初始件号值")
				Meteor.call("archive_item_number",object_name,Creator.TabularSelectedIds?[object_name],init_num)
		receive:
			label: "接收"
			visible: true
			on: "list"
			todo:(object_name)->
				if Session.get("list_view_id")== "receive"
					if Creator.TabularSelectedIds?[object_name].length == 0
						swal("请先选择要接收的档案")
						return
					space = Session.get("spaceId")
					Meteor.call("archive_receive",object_name,Creator.TabularSelectedIds?[object_name],space,
						(error,result) ->
							if result
								text = "共接收"+result[0]+"条,"+"成功"+result[1]+"条"
								swal(text)
							)
		export2xml:
			label:"导出XML"
			visible:true
			on: "list"
			todo:(object_name, record_id)->
				# 转为XML文件
				Meteor.call("archive_export",object_name,
						(error,result) ->
							if result
								text = "记录导出路径："
								swal(text + result)
							)
		borrow:
			label:"借阅"
			visible:true
			on: "record"
			todo:(object_name, record_id, fields)->
				borrower = Creator.Collections[object_name].findOne({_id:record_id})?.borrowed_by
				if borrower == Meteor.userId()
					swal("您已借阅了此档案，归还之前无需重复借阅")
					return
				doc = Archive.createBorrowObject(object_name, record_id)
				Creator.createObject("archive_borrow",doc)