checkUserSigned = (context, redirect) ->
	if !Meteor.userId()
		FlowRouter.go '/steedos/sign-in?redirect=' + context.path;

recordsSpaceRoutes = FlowRouter.group
	triggersEnter: [ checkUserSigned ],
	prefix: '/',
	name: 'records'

recordsSpaceRoutes.route '/',
	action: (params, queryParams)->
		BlazeLayout.render 'recordsLayout',
			main: "search_records_repository"

# recordsSpaceRoutes.route '/admin/record_types',
# 	action: (params, queryParams)->
# 		BlazeLayout.render 'recordsLayout',
# 			# main: "admin_record_types"

# recordsSpaceRoutes.route '/search/records_repository',
# 	action: (params, queryParams)->
# 		BlazeLayout.render 'recordsLayout',
# 			main: "search_records_repository"
