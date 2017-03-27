FlowRouter.route '/',
	action: (params, queryParams)->
		BlazeLayout.render 'recordsLayout',
			main: "records_home"

FlowRouter.route '/admin/record_types',
	action: (params, queryParams)->
		BlazeLayout.render 'recordsLayout',
			main: "admin_record_types"