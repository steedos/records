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

_syncInstances = (instances)->
	instances.forEach (instance)->
		tracesArr=instance.traces
		index='steedos'
		instance_type='instances'
		instance_id=instance._id
		ping_instance_url=es_server+'/'+index+'/'+instance_type+'/'+instance_id
		delete instance.traces
		delete instance._id
		delete instance.attachments
		if instance.values
			instance.values = JSON.stringify instance.values
		instanceObj=instance

		instanceObj.attachments = []
		try
			result = HTTP.call(
				'POST', ping_instance_url,
				{data: instanceObj}
			)
			db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
			#同步的时间添加到数据库中

			Attachment.syncAttachments(instance_id)
		catch e
			console.log e+'  instances error  '+instance_id

		# 循环traces下面的approves数组
		tracesArr.forEach (trace)->
			if trace.approves.length
				approveObj=trace.approves[0]
				approve_type='approves'
				approve_id=approveObj._id
				ping_approve_url=es_server+'/'+index+'/'+approve_type+'/'+approve_id
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
		instances=db.instances.find {"is_recorded":false,""},limit:skip_num
		_syncInstances instances
	console.timeEnd "Records.syncInstances"
		

# 同步问题解决测试方案
Records.syncTest=()->
	instances=db.instances.find(
		{'_id':'53a6a38b3349045c050038c4'},
		limit:1,
		sort: { 'modified': 1 }
	)
	_syncInstances instances