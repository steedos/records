FlowRouter.route '/',
	action: (params, queryParams)->
		
		BlazeLayout.render 'searchLayout',
			main: "searchHome"