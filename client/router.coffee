FlowRouter.route '/',
	action: (params, queryParams)->
		BlazeLayout.render 'steedosLayout',
			main: "recordsHome"