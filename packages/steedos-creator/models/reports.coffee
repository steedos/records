Creator.Objects.reports = 
	name: "reports"
	label: "报表"
	icon: "report"
	fields:
		name: 
			label: "名称"
			type: "text"
			required: true
			searchable:true
			index:true
		description: 
			label: "描述"
			type: "textarea"
			is_wide: true
		report_type:
			label: "报表类型"
			type: "select"
			defaultValue: "tabular"
			options: [
				{label: "表格", value: "tabular"},
				{label: "摘要", value: "summary"},
				{label: "矩阵", value: "matrix"}
			]
		object_name: 
			label: "对象名"
			type: "lookup"
			optionsFunction: ()->
				_options = []
				_.forEach Creator.Objects, (o, k)->
					_options.push {label: o.label, value: k, icon: o.icon}
				return _options
			required: true
		filter_scope:
			label: "过虑范围"
			type: "select"
			defaultValue: "space"
			omit: true
			options: [
				{label: "所有", value: "space"},
				{label: "与我相关", value: "mine"}
			]
		filters: 
			label: "过虑条件"
			type: [Object]
			omit: true
		"filters.$.field": 
			label: "字段名"
			type: "text"
		"filters.$.operation": 
			label: "操作符"
			type: "select"
			defaultValue: "="
			options: ()->
				options = [
					{label: t("creator_filter_operation_equal"), value: "="},
					{label: t("creator_filter_operation_unequal"), value: "<>"},
					{label: t("creator_filter_operation_less_than"), value: "<"},
					{label: t("creator_filter_operation_greater_than"), value: ">"},
					{label: t("creator_filter_operation_less_or_equal"), value: "<="},
					{label: t("creator_filter_operation_greater_or_equal"), value: ">="},
					{label: t("creator_filter_operation_contains"), value: "contains"},
					{label: t("creator_filter_operation_does_not_contain"), value: "notcontains"},
					{label: t("creator_filter_operation_starts_with"), value: "startswith"},
				]
		"filters.$.value": 
			label: "字段值"
			# type: "text"
			blackbox: true
		columns:
			label: "列"
			type: "lookup"
			multiple: true
			depend_on: ["object_name"]
			defaultIcon: "service_contract"
			optionsFunction: (values)->
				_options = []
				_object = Creator.getObject(values.object_name)
				fields = _object?.fields
				icon = _object?.icon

				_.forEach fields, (f, k)->
					_options.push {label: f.label || k, value: k, icon: icon}

				return _options
		rows: 
			label: "行"
			type: "lookup"
			multiple: true
			depend_on: ["object_name"]
			defaultIcon: "service_contract"
			optionsFunction: (values)->
				_options = []
				_object = Creator.getObject(values.object_name)
				fields = _object?.fields
				icon = _object?.icon

				_.forEach fields, (f, k)->
					_options.push {label: f.label || k, value: k, icon: icon}

				return _options
		values: 
			label: "统计"
			type: "[text]"
		options:
			omit: true
			blackbox: true
		# column_width: 
		# 	label: "排序"
		# 	type: "object"
		grouping:
			label: "显示小计"
			type: "boolean"
			defaultValue: true
		totaling:
			label: "显示总计"
			type: "boolean"
			defaultValue: true
		counting:
			label: "显示记录计数"
			type: "boolean"
			defaultValue: true

	list_views:
		default:
			columns: ["name", "report_type", "object_name"]
		recent:
			label: "最近查看"
			filter_scope: "space"
		all:
			label: "所有报表"
			filter_scope: "space"
		mine:
			label: "我的报表"
			filter_scope: "mine"
	permission_set:
		user:
			allowCreate: true
			allowDelete: true
			allowEdit: true
			allowRead: true
			modifyAllRecords: false
			viewAllRecords: false 
		admin:
			allowCreate: true
			allowDelete: true
			allowEdit: true
			allowRead: true
			modifyAllRecords: true
			viewAllRecords: true 