import { HTTP } from 'meteor/http'
@Records = {}

syncTime='2014-12-11 12:04:40.386Z'
i=0

Meteor.startup ()->
	Meteor.setInterval(Records.syncInstances,Meteor.settings.elasticsearch.sync_interval)

Records.timeDemo=()->
	console.log 'enter'+ i++

Records.syncInstances=()->
	#以后从数据库单独一张表中读取
	# syncTime='2016-12-11 12:04:40.386Z'
	es_server=Meteor.settings.elasticsearch.es_server
	instances=db.instances.find(
		{'is_recorded':false},
		limit:100,
		sort: { 'modified': 1 }
	)
	instances.forEach (instance)->
		tracesArr=instance.traces
		index=instance.space
		instance_type='instances'
		instance_id=instance._id
		ping_instance_url=es_server+'/'+index+'/'+instance_type+'/'+instance_id
		delete instance.traces
		delete instance._id
		instanceObj=instance
		try
			result = HTTP.call(
				'POST', ping_instance_url,
				{data: instanceObj}
			)
			db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
			#同步的时间添加到数据库中
		catch e
		
		tracesArr.forEach (trace)->
			if !trace.is_finished
				approveObj=trace.approves[0]
				approve_type='approves'
				approve_id=approveObj._id
				ping_approve_url=es_server+'/'+index+'/'+approve_type+'/'+approve_id
				delete approveObj._id
				try
					result = HTTP.call(
						'POST', ping_approve_url,
						{data: approveObj}
					)
				catch e
					console.log e+'  approves error  '+instance_id
	

# 第一次初始化ES
# Records.buildIndex=()->
# 	i=0
# 	es_server=Meteor.settings.elasticsearch.es_server
# 	while(i<23000)
# 		i++
# 		skip_num=i*10
# 		instances=db.instances.find({'is_recorded':false},
# 			limit:10,
# 			skip:skip_num
# 		)
# 		instances.forEach (instance)->
# 			tracesArr=instance.traces

# 			index=instance.space

# 			instance_type='instances'
# 			instance_id=instance._id
# 			ping_instance_url=es_server+'/'+index+'/'+instance_type+'/'+instance_id
# 			delete instance.traces
# 			delete instance._id
# 			instanceObj=instance
# 			# console.log instanceObj
# 			try
# 				result = HTTP.call(
# 					'POST', ping_instance_url,
# 					{data: instanceObj}
# 				)
# 				db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
# 			catch e
# 				console.log e+'  i  '+instance_id

# 			#循环traces下面的approves数组
			
# 			tracesArr.forEach (trace)->
# 				if !trace.is_finished
# 					approveObj=trace.approves[0]
# 					approve_type='approves'
# 					approve_id=approveObj._id
# 					ping_approve_url=es_server+'/'+index+'/'+approve_type+'/'+approve_id
# 					delete approveObj._id
# 					try
# 						result = HTTP.call(
# 							'POST', ping_approve_url,
# 							{data: approveObj}
# 						)
# 					catch e
# 						console.log e+'  t  '+instance_id
# 		console.log i