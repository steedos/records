FlowRouter.route '/',
	action: (params, queryParams)->
		
		BlazeLayout.render 'appLayout',
			main: "appHome"