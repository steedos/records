import { HTTP } from 'meteor/http'
@Records = {}
@es_server=Meteor.settings.elasticsearch.es_server

# 定时器
# syncTime='2014-12-11 12:04:40.386Z'
# i=0
# Records.timeDemo=()->
# 	console.log 'enter'+ i++
# Meteor.startup ()->
# 	Meteor.setInterval(Records.syncInstances,Meteor.settings.elasticsearch.sync_interval)

_syncApproves = (tracesArr,index)->
	# 循环traces下面的approves数组
	type='approves'
	tracesArr.forEach (trace)->
		if trace.approves.length
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
				console.log e+'  approves error  '+instance_id

_pushUser = (instance)->
	users = []
	console.log instance.hasOwnProperty 'submitter'
	console.log instance.submitter!=''
	console.log users.indexOf(instance.submitter)==-1
	console.log (instance.hasOwnProperty 'submitter') && (instance.submitter!='') && (users.indexOf(instance.submitter)==-1)
	if (instance.hasOwnProperty 'submitter') && (instance.submitter!='') && (users.indexOf(instance.submitter)==-1)
		users.push instance.submitter
	if (instance.hasOwnProperty 'applicant') && (instance.applicant!='') && (users.indexOf(instance.applicant)==-1)
		users.push instance.applicant
	if (instance.hasOwnProperty 'created_by') && (instance.created_by!='') && (users.indexOf(instance.created_by)==-1)
		users.push instance.created_by
	if (instance.hasOwnProperty 'modified_by') && (instance.modified_by!='') && (users.indexOf(instance.modified_by)==-1)
		users.push instance.modified_by
	if instance.hasOwnProperty 'inbox_users'
		instance.inbox_users.forEach (inbox_user)->
			if (users.indexOf(inbox_user)==-1)
				users.push inbox_user
	if instance.hasOwnProperty 'cc_users'
		instance.cc_users.forEach (cc_user)->
			if (users.indexOf(cc_user)==-1)
				users.push cc_user
	console.log instance.outbox_users.length

	if instance.hasOwnProperty 'outbox_users'
		instance.outbox_users.forEach (outbox_user)->
			if (users.indexOf(outbox_user)==-1)
				console.log outbox_user
				users.push outbox_user
	return users

_syncInstances = (instances)->
	instances.forEach (instance)->
		console.log '开始同步表单：'+instance
		index='steedos'
		type='instances'
		instance_id=instance._id
		ping_instance_url=es_server+'/'+index+'/'+type+'/'+instance_id
		tracesArr = []
		if instance.hasOwnProperty 'traces'
			tracesArr = instance.traces
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
			#同步申请流程
			_syncApproves tracesArr,index
			#同步附件
			Attachment.syncAttachments instance_id

			db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
		catch e
			console.log e+'  instances error  '+instance_id

# 同步任务主函数
Records.syncInstances=()->
  	#TODO 确认查询条件是否合理
	instances=db.instances.find(
		{'is_recorded':false},
		limit:1,
		sort: { 'modified': 1 }
	)
	_syncInstances instances

	

# 第一次初始化ES
Records.buildIndex=()->
	console.time "Records.syncInstances"
	i=0
	# 动态查询总数
	total = db.instances.find({'is_recorded':false}).count()
	times = parseInt total/10+1
	while(i<times)
		i++
		skip_num=i*10
		instances=db.instances.find {"is_recorded":false},limit:skip_num
		_syncInstances instances
	console.timeEnd "Records.syncInstances"
		

# 同步问题解决测试方案
Records.syncTest=()->
	instances=db.instances.find(
		{'_id':'54fe8699527eca5fbc01b508'},
		limit:1,
		sort: { 'modified': 1 }
	)
	_syncInstances instances