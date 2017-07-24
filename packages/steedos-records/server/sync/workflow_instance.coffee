import { HTTP } from 'meteor/http'
logger = new Logger 'Records_ES_Instances'
@Records = {}
@es_server=Meteor.settings.public.webservices?.elasticsearch?.url
# 定时器
Meteor.startup ()->
	if Meteor.settings.records?.sync_interval>0
		Meteor.setInterval(Records.syncInstances,Meteor.settings.records.sync_interval)

_syncApproves = (tracesArr,index)->
	type="approves"
	tracesArr?.forEach (trace)->
		if trace?.approves?.length
			trace.approves.forEach (approveObj)->
				approve_id=approveObj._id
				ping_approve_url=es_server+'/'+index+'/'+type+'/'+approve_id
				delete approveObj._id
				delete approveObj?.values
				delete approveObj?.next_steps
				try
					result = HTTP.call(
						'POST', ping_approve_url,
						{data: approveObj}
					)
					if result?.statusCode!=200
						logger.error("#{approve_id} is not sync")
				catch e
					logger.error("#{approve_id} is not sync")

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
			Instances.update({'_id':instance_id},{$currentDate:{record_synced: true}})
			Attachment.syncAttachments instance_id
		catch e
			logger.error "#{instance_id} is not sync"

# 同步任务主函数
Records.syncInstances=()->

	logger.info "Run Records.syncInstances"

	console.time "Records.syncInstances"

	i = 0
	limit_num = 10
	total = Instances.find({
		$or:[
			{'record_synced':{$exists:false}},
			# {'modified':{'$gte':'record_synced'}}
			{$where:"this.modified>=this.record_synced"}
		]}).count()

	times = parseInt total/limit_num+1

	while(i<times)
		i++
		instances = Instances.find({
			$or:[
				{'record_synced':{$exists:false}},
				# {'modified':{'$gte':'record_synced'}}
				{$where:"this.modified>=this.record_synced"}
			]},
			{ limit : limit_num },
			{ sort: { 'modified': 1 } }
		)
		_syncInstances instances

	console.timeEnd "Records.syncInstances"

# 第一次初始化ES
Records.buildIndex=()->
	Records.syncInstances
	
# 测试
Records.syncTest=(instance_id)->
	instances=Instances.find(
		{'_id':instance_id}
	)
	_syncInstances instances

# Records.syncTest('oJfg3AQRx5nFoDA8s')