import { HTTP } from 'meteor/http'
logger = new Logger 'Records_ES_Instances'
@Records = {}
@es_server=Meteor.settings.public.webservices?.elasticsearch?.url
# 定时器
Meteor.startup ()->
	if Meteor?.settings?.records?.sync_interval>0
		Meteor.setInterval(Records?.syncInstances,Meteor?.settings?.records?.sync_interval)

index = Meteor?.settings?.records?.es_search_index
type = "instances"

_addInstance = (instance)->
	instance_id=instance._id
	ping_instance_url=es_server+'/'+index+'/'+type+'/'+instance_id
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
		Instances.direct.update(
			instance_id,
			{
				$set:{is_recorded: true}
			})
		Attachment.syncAttachments instance_id
	catch e
		logger.error "#{instance_id} can not sync"


insertSyne = ()->
	limit_num = Meteor?.settings?.records?.sync_limit_num
	instances = Instances.find(
		{
			$or:[
					{is_recorded:{$exists:false}},
					{is_recorded:false}
				]
		},
		{ limit : limit_num }
		{ fields : {_id: 1}}
		).fetch()

	instances.forEach (mini_ins)->
		instance = Instances.findOne({_id:mini_ins._id})
		if instance
			_addInstance instance

_deleteInstance = (delete_ins_id)->
	ping_instance_url = es_server+'/'+index+'/'+type+'/'+delete_ins_id
	try
		result = HTTP.call(
			'DELETE', ping_instance_url
		)
		deletedInstances.direct.update(
			delete_ins_id,
			{
				$set:{is_recorded: undefined}
			})
	catch e
		logger.error "#{delete_ins_id} can not deleted"

deleteSyne = ()->
	deleted_instances = deletedInstances.find(
		{is_recorded:true},
		{fields: {_id: 1}}).fetch()

	deleted_instances.forEach (mini_del_ins) ->
		_deleteInstance mini_del_ins._id

# 同步任务主函数
Records.syncInstances=()->
	logger.info "Run Records.syncInstances"

	console.time "Records.syncInstances"

	# 需要同步的表单
	insertSyne()

	# 删除同步的表单
	deleteSyne()

	console.timeEnd "Records.syncInstances"
	
# 测试增加
Records.addTest=(instance_id)->
	instances=Instances.find(
		{_id:instance_id}
	)
	_addInstance instance

# Records.addTest('M9WEJ7EMChAPMES54')

# 测试删除
Records.deleteTest=(instance_id)->
	instances=deletedInstances.find(
		{_id:instance_id}
	)
	_deleteInstances instances

# Records.deleteTest('M9WEJ7EMChAPMES54')	


# 第一次初始化ES
Records.buildIndex=()->
	Records.syncInstances()