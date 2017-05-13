import { HTTP } from 'meteor/http'
@Records = {}
@es_server=Meteor.settings.public.webservices.elasticsearch.url

# 定时器

Meteor.startup ()->
	# if Meteor.settings.records?.sync_interval
	# 	Meteor.setInterval(Records.syncInstances,Meteor.settings.records.sync_interval)

_syncApproves = (tracesArr,index)->
	type="approves"
	tracesArr?.forEach (trace)->
		if trace?.approves?.length
			approveObj=trace.approves[0]
			approve_id=approveObj._id
			ping_approve_url=es_server+'/'+index+'/'+type+'/'+approve_id
			delete approveObj._id
			delete approveObj.values
			delete approveObj.next_steps
			try
				result = HTTP.call(
					'POST', ping_approve_url,
					{data: approveObj}
				)
			catch e
				console.log "#{approve_id} is not sync"

_pushUser = (instance)->
	users = []
	if (instance?.submitter!='') && (users.indexOf(instance?.submitter)==-1)
		users.push instance?.submitter
	if (instance?.applicant!='') && (users.indexOf(instance?.applicant)==-1)
		users.push instance?.applicant
	if (instance?.created_by!='') && (users.indexOf(instance?.created_by)==-1)
		users.push instance?.created_by
	if (instance?.modified_by!='') && (users.indexOf(instance?.modified_by)==-1)
		users.push instance?.modified_by
	instance?.inbox_users?.forEach (inbox_user)->
		if (users.indexOf(inbox_user)==-1)
			users.push inbox_user
	instance?.cc_users?.forEach (cc_user)->
		if (users.indexOf(cc_user)==-1)
			users.push cc_user
	instance?.outbox_users?.forEach (outbox_user)->
		if (users.indexOf(outbox_user)==-1)
			users.push outbox_user
	return users

_syncInstances = (instances)->
	instances.forEach (instance)->
		index=Meteor.settings.records.es_search_index
		type="instances"
		instance_id=instance._id
		ping_instance_url=es_server+'/'+index+'/'+type+'/'+instance_id
		tracesArr = instance?.traces
		delete instance.traces
		delete instance._id
		delete instance.attachments
		if instance.values
			instance.values = JSON.stringify instance.values
		instance.users = _pushUser instance
		instanceObj=instance
		instanceObj.attachments = []
		try
			result = HTTP.call(
				'POST', ping_instance_url,
				{data: instanceObj}
			)
			_syncApproves tracesArr,index
			Attachment.syncAttachments instance_id
			db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
		catch e
			console.log  "#{instance_id} is not sync"

# 同步任务主函数
Records.syncInstances=()->
	instances=db.instances.find(
		{'is_recorded':false},
		limit:10,
		sort: { 'modified': 1 }
	)
	_syncInstances instances

# 第一次初始化ES
Records.buildIndex=()->
	console.time "Records.syncInstances"
	i=0
	total = db.instances.find({'is_recorded':false}).count()
	times = parseInt total/10+1
	while(i<times)
		i++
		skip_num=i*10
		instances=db.instances.find {"is_recorded":false},limit:skip_num
		_syncInstances instances
	console.timeEnd "Records.syncInstances"

Records.syncTest=(instance_id)->
	instances=db.instances.find(
		{'_id':instance_id}
	)
	_syncInstances instances