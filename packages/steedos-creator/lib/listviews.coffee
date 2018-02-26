Creator.getInitWidthPercent = (object_name, columns) ->
	_schema = Creator.getSchema(object_name)?._schema
	column_num = 0
	if _schema
		_.each columns, (field_name) ->
			field = _.pick(_schema, field_name)
			is_wide = field[field_name]?.autoform?.is_wide
			if is_wide
				column_num += 2
			else
				column_num += 1

		init_width_percent = 100 / column_num
		return init_width_percent

Creator.getFieldIsWide = (object_name, field_name) ->
	_schema = Creator.getSchema(object_name)._schema
	if _schema
		field = _.pick(_schema, field_name)
		is_wide = field[field_name]?.autoform?.is_wide
		return is_wide

Creator.getTabularColumns = (object_name, columns, is_related) ->
	obj = Creator.getObject(object_name)
	cols = []
	if Meteor.isClient
		init_width_percent = Creator.getInitWidthPercent(object_name, columns)

	_.each columns, (field_name)->
		field = obj.fields[field_name]
		if /\w+\.\$\.\w+/g.test(field_name)
			# object类型带子属性的field_name要去掉中间的美元符号，否则显示不出字段值
			field_name = field_name.replace(/\$\./,"")
		if field?.type and !field.hidden
			col = {}
			col.data = field_name
			col.sTitle = "<a class='slds-th__action slds-text-link_reset' href='javascript:void(0);' role='button' tabindex='-1' aria-label='#{field_name}'>
							<span class='slds-assistive-text'>Sort by: </span>
							<span class='slds-truncate' title='Name'>" +  field.label + "</span>
							<div class='slds-icon_container'>
								<svg class='slds-icon slds-icon_x-small slds-icon-text-default slds-is-sortable__icon' aria-hidden='true'>
									<use xmlns:xlink='http://www.w3.org/1999/xlink' xlink:href='/packages/steedos_lightning-design-system/client/icons/utility-sprite/symbols.svg#arrowdown'>
									</use>
								</svg>
							</div>
						</a>"
			col.className = "slds-cell-edit cellContainer slds-is-resizable"
			if field.sortable
				col.className = col.className + " slds-is-sortable"
			else
				col.orderable = false
			
			if Meteor.isClient
				list_view_id = Session.get("list_view_id")
				setting = Creator.Collections?.settings?.findOne({object_name: object_name, record_id: "object_listviews"})
				if setting and setting.settings
					column_width = setting.settings[list_view_id]?.column_width
					if column_width
						_.each column_width, (width, key)->
							if field_name == key
								col.width = width
					else
						if Creator.getFieldIsWide(object_name, field_name)
							col.width = "#{2 * init_width_percent}%"
						else
							col.width = "#{init_width_percent}%"
				else
					if Creator.getFieldIsWide(object_name, field_name)
						col.width = "#{2 * init_width_percent}%"
					else
						col.width = "#{init_width_percent}%"

			col.render =  (val, type, doc) ->
				return
			col.createdCell = (cell, val, doc) ->
				$(cell).attr("data-label", field.label)
				Blaze.renderWithData(Template.creator_table_cell, {_id: doc._id, val: val, doc: doc, field: field, field_name: field_name, object_name:object_name}, cell);

			cols.push(col)

	objectColName = "tabular-col-#{object_name.replace(/\./g,'_')}"

	action_col = 
		title: '<div class="slds-th__action slds-cell-fixed" style="width: 100%;"></div>'
		data: "_id"
		width: '20px'
		className: "tabular-col-actions #{objectColName}"
		orderable: false
		createdCell: (node, cellData, rowData) ->
			record = rowData
			userId = Meteor.userId()
			record_permissions = Creator.getRecordPermissions object_name, record, Meteor.userId()
			$(node).attr("data-label", "Actions")
			$(node).html(Blaze.toHTMLWithData Template.creator_table_actions, {_id: cellData, object_name: object_name, record_permissions: record_permissions, is_related: is_related}, node)
	cols.push(action_col)

	unless is_related
		checkbox_col = 
			title: ''
			data: "_id"
			width: '20px'
			className: "slds-cell-edit cellContainer tabular-col-checkbox #{objectColName}"
			orderable: false
			createdCell: (node, cellData, rowData) ->
				$(node).attr("data-label", "Checkbox").empty()
				Blaze.renderWithData Template.creator_table_checkbox, {_id: cellData, object_name: object_name}, node
		cols.splice(0, 0, checkbox_col)
	
	return cols

Creator.getTabularOrder = (object_name, list_view_id, columns) ->
	setting = Creator.Collections?.settings?.findOne({object_name: object_name, record_id: "object_listviews"})
	obj = Creator.getObject(object_name)
	columns = _.map columns, (column)->
		field = obj.fields[column]
		if field?.type and !field.hidden
			return column
		else
			return undefined
	columns = _.compact columns
	if setting and setting.settings
		sort = setting.settings[list_view_id]?.sort || []
		sort = _.map sort, (order)->
			key = order[0]
			index = _.indexOf(columns, key)
			order[0] = index + 1
			return order
		return sort
	return []


Creator.initListViews = (object_name)->
	object = Creator.getObject(object_name)
	columns = ["name"]
	if object.list_views?.default?.columns
		columns = object.list_views.default.columns
	extra_columns = ["owner"]
	if object.list_views?.default?.extra_columns
		extra_columns = _.union extra_columns, object.list_views.default.extra_columns

	order = []
	if object.list_views?.default?.order
		order = object.list_views.default.order

	if Meteor.isClient
		Creator.TabularSelectedIds[object_name] = []

	tabularOptions = {
		name: "creator_" + object_name
		collection: Creator.Collections[object_name]
		pub: "steedos_object_tabular"
		columns: Creator.getTabularColumns(object_name, columns)
		headerCallback: ( thead, data, start, end, display )->
			firstTh = $(thead).find('th').eq(0)
			if firstTh.hasClass("tabular-col-checkbox")
				firstTh.css("width","32px").empty()
				Blaze.renderWithData Template.creator_table_checkbox, {_id: "#", object_name: object_name}, firstTh[0]

		drawCallback:(settings)->
			self = this

			Tracker.nonreactive ->
				# 仅对list视图的tabular进行表格宽度设置
				if $(self).closest(".list-table-container").length
					object_name = Session.get("object_name")
					list_view_id = Session.get("list_view_id")
					setting = Creator.Collections.settings.findOne({object_name: object_name, record_id: "object_listviews"})
					column_width = setting?.settings[list_view_id]?.column_width

					if !column_width
						$(self).css("width", "100%")
					else
						checkbox_col_width = $("th:first", $(self)).outerWidth()
						action_col_width = $("th:last", $(self)).outerWidth()

						sum_width = checkbox_col_width + action_col_width
						_.each column_width, (width, field) ->
							width = parseInt(width)
							sum_width += width

						$(self).css({"width": "#{sum_width}px", "min-width": "#{sum_width}px"})

			# 当数据库数据变化时会重新生成datatable，需要重新把勾选框状态保持住
			Tracker.nonreactive ->
				Creator.remainCheckboxState(self)

		dom: "tp"
		extraFields: extra_columns
		lengthChange: false
		ordering: true
		pageLength: 20
		info: false
		searching: true
		autoWidth: false
		changeSelector: (selector, userId)->
			if object_name == "cfs.files.filerecord"
				if !selector["metadata.space"] and !selector._id
					selector =
						_id: "nothing"
			else
				if !selector.space and !selector._id
					selector =
						_id: "nothing"
			return selector
	}

	if order.length > 0
		tabularOptions.order = order

	new Tabular.Table tabularOptions




if Meteor.isClient
	Creator.getRelatedList = (object_name, record_id)->
		list = []
		related_object_names = Creator.getRelatedObjects(object_name)

		_.each Creator.Objects, (related_object, related_object_name)->
			if _.indexOf(related_object_names, related_object_name) > -1
				_.each related_object.fields, (related_field, related_field_name)->
					if related_field.type=="master_detail" and related_field.reference_to and related_field.reference_to == object_name
						tabular_name = "creator_" + related_object_name
						if Tabular.tablesByName[tabular_name]
							columns = ["name"]
							if related_object.list_views?.default?.columns
								columns = related_object.list_views.default.columns
							columns = _.without(columns, related_field_name)
							Tabular.tablesByName[tabular_name].options?.columns = Creator.getTabularColumns(related_object_name, columns, true);

							if /\w+\.\$\.\w+/g.test(related_field_name)
								# object类型带子属性的related_field_name要去掉中间的美元符号，否则显示不出字段值
								related_field_name = related_field_name.replace(/\$\./,"")
							related =
								object_name: related_object_name
								columns: columns
								tabular_table: Tabular.tablesByName[tabular_name]
								related_field_name: related_field_name

							list.push related

		if Creator.Objects[object_name]?.enable_files and _.indexOf(related_object_names, "cms_files") > -1
			file_object_name = "cms_files"
			file_tabular_name = "creator_" + file_object_name
			file_related_field_name = "parent"
			file_related_object = Creator.Objects[file_object_name]
			
			if Tabular.tablesByName[file_tabular_name]
				columns = ["name"]
				if file_related_object.list_views?.default?.columns
					columns = file_related_object.list_views.default.columns
				columns = _.without(columns, file_related_field_name)
				Tabular.tablesByName[file_tabular_name].options?.columns = Creator.getTabularColumns(file_object_name, columns, true);

				file_related =
					object_name: file_object_name
					columns: columns
					tabular_table: Tabular.tablesByName[file_tabular_name]
					related_field_name: file_related_field_name
					is_file: true

				list.push file_related

		if Creator.Objects[object_name]?.enable_tasks
			task_related =
				object_name: "tasks"
				columns: ["name", "end_date", "assigned_to"]
				tabular_table: Tabular.tablesByName["creator_tasks"]
				related_field_name: "related_to"

			list.push task_related


		return list


Creator.getListView = (object_name, list_view_id)->
	object = Creator.getObject(object_name)
	custom_list_view = Creator.Collections.object_listviews.findOne(list_view_id)
	if object.list_views
		if object.list_views[list_view_id]
			list_view = object.list_views[list_view_id]
		else if custom_list_view
			list_view = 
				columns: custom_list_view.columns
				filter_scope: custom_list_view.filter_scope
				label: custom_list_view.name
				name: custom_list_view.name
				_id: list_view_id
		else
			view_ids = _.keys(object.list_views) 
			view_ids = _.without(view_ids, "default")
			list_view = object.list_views[view_ids[0]]
		Creator.getTable(object_name)?.options.columns = Creator.getTabularColumns(object_name, list_view.columns);
		Creator.getTable(object_name)?.options.language.zeroRecords = t("list_view_no_records")
		Creator.getTable(object_name)?.options.order = Creator.getTabularOrder(object_name, list_view_id, list_view.columns)
	return list_view