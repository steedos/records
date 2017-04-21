FlowRouter.route '/',
	action: (params, queryParams)->
		BlazeLayout.render 'recordsLayout',
			main: "records_home"

FlowRouter.route '/admin/record_types',
	action: (params, queryParams)->
		BlazeLayout.render 'recordsLayout',
			main: "admin_record_types"

FlowRouter.route '/search/records_repository',
	action: (params, queryParams)->
		BlazeLayout.render 'recordsLayout',
			main: "search_records_repository"