import { HTTP } from 'meteor/http'
@Records = {}
es_server=Meteor.settings.elasticsearch.es_server
# syncTime='2014-12-11 12:04:40.386Z'
# i=0
# Meteor.startup ()->
# 	Meteor.setInterval(Records.syncInstances,Meteor.settings.elasticsearch.sync_interval)

# Records.timeDemo=()->
# 	console.log 'enter'+ i++





# 同步问题解决测试方案
Records.syncTest=()->
	instances=db.instances.find(
		# {'is_recorded':false},
		{'_id':'51bfc7c649203b55740000ea'},
		limit:1,
		sort: { 'modified': 1 }
	)
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
			instance.values=JSON.stringify(instance.values)
		instanceObj=instance
		console.log instanceObj
		# try
		# 	result = HTTP.call(
		# 		'POST', ping_instance_url,
		# 		{data: instanceObj}
		# 	)
		# 	db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
		# catch e
		# 	console.log e+'  instances error  '+instance_id+ '   '+result
		
		tracesArr.forEach (trace)->
			console.log trace.approves.length
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


















# Records.syncInstances=()->
# 	#以后从数据库单独一张表中读取
# 	# syncTime='2016-12-11 12:04:40.386Z'
# 	instances=db.instances.find(
# 		{'is_recorded':false},
# 		limit:1,
# 		sort: { 'modified': 1 }
# 	)
# 	instances.forEach (instance)->
# 		tracesArr=instance.traces
# 		index='steedos'
# 		instance_type='instances'
# 		instance_id=instance._id
# 		ping_instance_url=es_server+'/'+index+'/'+instance_type+'/'+instance_id
# 		delete instance.traces
# 		delete instance._id
# 		delete instance.attachments
# 		instanceObj=instance
# 		console.log instanceObj
# 		try
# 			result = HTTP.call(
# 				'POST', ping_instance_url,
# 				{data: instanceObj}
# 			)
# 			db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
# 			#同步的时间添加到数据库中
# 		catch e
# 			console.log e+'  instances error  '+instance_id
		
# 		tracesArr.forEach (trace)->
# 			if trace.approves.length
# 				approveObj=trace.approves[0]
# 				approve_type='approves'
# 				approve_id=approveObj._id
# 				ping_approve_url=es_server+'/'+index+'/'+approve_type+'/'+approve_id
# 				delete approveObj._id
#				delete approveObj.values
# 				delete approveObj.next_steps
# 				try
# 					result = HTTP.call(
# 						'POST', ping_approve_url,
# 						{data: approveObj}
# 					)
# 				catch e
# 					console.log e+'  approves error  '+instance_id
	

# #######第一次初始化ES
Records.buildIndex=()->
	i=0
	while(i<320)
		i++
		skip_num=i*100
		instances=db.instances.find({'is_recorded':false},
			limit:100,
			skip:skip_num
		)
		instances.forEach (instance)->
			# console.log instance._id
			tracesArr=instance.traces
			index='steedos'
			instance_type='instances'
			instance_id=instance._id
			ping_instance_url=es_server+'/'+index+'/'+instance_type+'/'+instance_id
			delete instance.traces
			delete instance._id
			delete instance.attachments
			delete instance.is_recorded
			if instance.values
				instance.values=JSON.stringify(instance.values)
			instanceObj=instance
			try
				result = HTTP.call(
					'POST', ping_instance_url,
					{data: instanceObj}
				)
				db.instances.update({'_id':instance_id},{$set: {is_recorded: true}})
			catch e
				console.log e+'  instances error  '+instance_id

			#循环traces下面的approves数组
			
			tracesArr.forEach (trace)->
				if trace.approves&&trace.approves.length
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

			# 同步附件
			# TODO
			#  1、获取附件
			#  2、下载附件：下载完成后才可执行第3步，下载可能报错，如何处理?
			#  3、转换附件：转换可能报错，如何处理?
			#  4、上传附件


		console.log i