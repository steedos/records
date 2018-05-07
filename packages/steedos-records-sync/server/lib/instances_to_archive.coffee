request = Npm.require('request')
path = Npm.require('path')
fs = Npm.require('fs')

logger = new Logger 'Records_QHD -> InstancesToArchive'


#	校验必填
_checkParameter = (formData) ->
	if !formData.fonds_name
		return false
	return true

# 按年度计算件数,生成电子文件号的最后组成
buildElectronicRecordCode = (formData) ->
	num = db.archive_wenshu.find({'year':formData?.year}).count() + 1
	strCount = (Array(6).join('0') + num).slice(-6)
	strElectronicRecordCode = formData?.fonds_identifier +
								formData?.archival_category_code +
								formData?.year + strCount
	return strElectronicRecordCode

# 整理档案表数据
_minxiInstanceData = (formData, instance) ->
	if !instance
		return
	dateFormat = "YYYY-MM-DD HH:mm:ss"

	formData.space = instance.space

	formData.owner = instance.submitter

	formData.created_by = instance.created_by

	formData.created = new Date()

	# 字段映射:表单字段对应到formData
	field_values = InstanceManager.handlerInstanceByFieldMap(instance)

	formData.applicant_name = field_values?.nigaorens
	formData.document_status = field_values?.guidangzhuangtai
	formData.archive_dept = field_values?.guidangbumen
	formData.applicant_organization_name=field_values?.nigaodanwei || field_values?.FILE_CODE_fzr
	formData.total_number_of_pages = field_values?.PAGE_COUNT
	formData.security_classification = field_values?.miji
	formData.document_type = field_values?.wenjianleixing
	formData.document_date = field_values?.wenjianriqi
	formData.archival_code = field_values?.wenjianzihao
	formData.author = field_values?.FILE_CODE_fzr
	formData.title = instance.name

	# 机构：FILING_DEPT字段（发文是拟稿单位，收文是所属部门）
	if field_values?.FILING_DEPT
		orgObj = Creator.Collections["archive_organization"].findOne({'name':field_values?.FILING_DEPT})
	if orgObj
		formData.organizational_structure = orgObj._id

	# 根据FONDSID查找全宗号和全总名称
	fondObj = Creator.Collections["archive_fonds"].findOne({'name':field_values?.FONDSID})
	if fondObj
		formData.fonds_identifier = fondObj?._id
		formData.fonds_name = fondObj?.name

	# 保管期限代码查找
	retentionObj = Creator.Collections["archive_retention"].findOne({'name':field_values?.baocunqixian})
	if retentionObj
		formData.retention_peroid = retentionObj?._id
		# 根据保管期限,处理标志
		if retentionObj?.years >= 10
			formData.produce_flag = "在档"
		else
			formData.produce_flag = "暂存"

	# 电子文件号，不生成，点击接收的时候才生成
	# formData.electronic_record_code = buildElectronicRecordCode formData
	
	# 归档日期
	formData.archive_date = moment(new Date()).format(dateFormat)

	# OA表单的ID，作为判断OA归档的标志
	formData.external_id = instance._id

	formData.is_received = false

	fieldNames = _.keys(formData)

	fieldNames.forEach (key)->
		fieldValue = formData[key]
		if _.isDate(fieldValue)
			fieldValue = moment(fieldValue).format(dateFormat)

		if _.isObject(fieldValue)
			fieldValue = fieldValue?.name

		if _.isArray(fieldValue) && fieldValue.length > 0 && _.isObject(fieldValue)
			fieldValue = fieldValue?.getProperty("name")?.join(",")

		if _.isArray(fieldValue)
			fieldValue = fieldValue?.join(",")

		if !fieldValue
			fieldValue = ''

	console.log("_minxiInstanceData end", instance._id)

	return formData


# 整理关联档案
_minxiRelatedArchives = (instance, record_id) ->
	# 当前归档的文件有关联的文件
	if instance?.related_instances
		related_archives = []
		instance.related_instances.forEach (related_instance) ->
			relatedObj = Creator.Collections["archive_wenshu"].findOne({'external_id':related_instance},{fields:{_id:1}})
			if relatedObj
				related_archives.push relatedObj?._id
		Creator.Collections["archive_wenshu"].update(
			{_id:record_id},
			{
				$set:{ related_archives:related_archives }
			})

	# 查找当前 instance 是否被其他的 主instance 关联
	mainRelatedObjs = Creator.Collections["instances"].find(
		{'related_instances':instance._id},
		{fields: {_id: 1}}).fetch()
	# 如果被其他的主instance关联该文件，则更新主instance的related_archives字段
	if mainRelatedObjs.length > 0
		mainRelatedObjs.forEach (mainRelatedObj) ->
			# 查找该主 instance对应的主关联档案
			mainRelatedObj = Creator.Collections["archive_wenshu"].findOne({'external_id':mainRelatedObj._id})
			if mainRelatedObj
				related_archives = mainRelatedObj?.related_archives || []
				related_archives.push record_id
				Creator.Collections["archive_wenshu"].update(
					{_id:mainRelatedObj._id},
					{
						$set:{ related_archives:related_archives }
					})

# 整理文件数据
_minxiAttachmentInfo = (instance, record_id) ->
	# 对象名
	object_name = RecordsQHD?.settings_records_qhd?.to_archive?.object_name
	parents = []
	spaceId = instance?.space

	# 查找最新版本的文件(包括正文附件)
	currentFiles = cfs.instances.find({
		'metadata.instance': instance._id,
		'metadata.current': true
	}).fetch()

	currentFiles.forEach (cf)->
		try
			versions = []
			# 根据当前的文件,生成一个cms_files记录
			cmsFileId = db.cms_files._makeNewID()
			db.cms_files.insert({
					_id: cmsFileId,
					versions: [],
					created_by: cf.metadata.owner,
					size: cf.size(),
					owner: cf.metadata.owner,
					modified: cf.metadata.modified,
					parent: {
						o: object_name,
						ids: [record_id]
					},
					modified_by: cf.metadata.modified_by,
					created: cf.metadata.created,
					name: cf.name(),
					space: spaceId,
					extention: cf.extension()
				})

			# 查找文件的历史版本
			historyFiles = cfs.instances.find({
				'metadata.instance': cf.metadata.instance,
				'metadata.current': {$ne: true},
				"metadata.main": {$ne: true},
				"metadata.parent": cf.metadata.parent
			}, {sort: {uploadedAt: -1}}).fetch()
			# 把当前文件放在历史版本文件的最后
			historyFiles.push(cf)
			historyFiles.forEach (hf) ->
				newFile = new FS.File()
				newFile.attachData(
					hf.createReadStream('instances'),
					{type: hf.original.type},
					(err)->
						if err
							throw new Meteor.Error(err.error, err.reason)
						newFile.name hf.name()
						newFile.size hf.size()
						metadata = {
							owner: hf.metadata.owner,
							owner_name: hf.metadata?.owner_name,
							space: spaceId,
							record_id: record_id,
							object_name: object_name,
							parent: cmsFileId,
							current: hf.metadata?.current
						}
						newFile.metadata = metadata
						fileObj = cfs.files.insert(newFile)
						if fileObj
							versions.push(fileObj._id)
					)
			# 把 cms_files 记录的 versions 更新
			db.cms_files.update(cmsFileId, {$set: {versions: versions}})
		catch e
			logger.error "正文附件下载失败：#{hf._id}. error: " + e


# 整理档案审计数据
_minxiInstanceTraces = (auditList, instance, record_id) ->
	# 获取步骤状态文本
	getApproveStatusText = (approveJudge) ->
		locale = "zh-CN"
		#已结束的显示为核准/驳回/取消申请，并显示处理状态图标
		approveStatusText = undefined
		switch approveJudge
			when 'approved'
				# 已核准
				approveStatusText = TAPi18n.__('Instance State approved', {}, locale)
			when 'rejected'
				# 已驳回
				approveStatusText = TAPi18n.__('Instance State rejected', {}, locale)
			when 'terminated'
				# 已取消
				approveStatusText = TAPi18n.__('Instance State terminated', {}, locale)
			when 'reassigned'
				# 转签核
				approveStatusText = TAPi18n.__('Instance State reassigned', {}, locale)
			when 'relocated'
				# 重定位
				approveStatusText = TAPi18n.__('Instance State relocated', {}, locale)
			when 'retrieved'
				# 已取回
				approveStatusText = TAPi18n.__('Instance State retrieved', {}, locale)
			when 'returned'
				# 已退回
				approveStatusText = TAPi18n.__('Instance State returned', {}, locale)
			when 'readed'
				# 已阅
				approveStatusText = TAPi18n.__('Instance State readed', {}, locale)
			else
				approveStatusText = ''
				break
		return approveStatusText

	traces = instance?.traces

	traces.forEach (trace)->
		approves = trace?.approves || []
		approves.forEach (approve)->
			auditObj = {}
			auditObj.business_status = "计划任务"
			auditObj.business_activity = trace?.name
			auditObj.action_time = approve?.start_date
			auditObj.action_user = approve?.user
			auditObj.action_description = getApproveStatusText approve?.judge
			auditObj.action_administrative_records_id = record_id
			auditObj.instace_id = instance._id
			auditObj.space = instance.space
			auditObj.owner = approve?.user
			db.archive_audit.insert auditObj
	return auditList


# =============================================

# spaces: Array 工作区ID
# contract_flows： Array 合同类流程
InstancesToArchive = (spaces, contract_flows, ins_ids) ->
	@spaces = spaces
	@contract_flows = contract_flows
	@ins_ids = ins_ids
	return

InstancesToArchive.success = (instance)->
	console.log("success, name is #{instance.name}, id is #{instance._id}")
	db.instances.direct.update({_id: instance._id}, {$set: {is_recorded: true}})

InstancesToArchive.failed = (instance, error)->
	console.log("failed, name is #{instance.name}, id is #{instance._id}. error: ")
	console.log error

#	获取非合同类的申请单：正常结束的(不包括取消申请、被驳回的申请单)
InstancesToArchive::getNonContractInstances = ()->
	query = {
		space: {$in: @spaces},
		flow: {$nin: @contract_flows},
		# is_archived字段被老归档接口占用，所以使用 is_recorded 字段判断是否归档
		$or: [
			{is_recorded: false},
			{is_recorded: {$exists: false}}
		],
		is_deleted: false,
		state: "completed",
		"values.record_need": "true",
		$or: [
			{final_decision: "approved"},
			{final_decision: {$exists: false}},
			{final_decision: ""}
		]
	}
	if @ins_ids
		query._id = {$in: @ins_ids}
	return Creator.Collections["instances"].find(query, {fields: {_id: 1}}).fetch()


InstancesToArchive.syncNonContractInstance = (instance, callback) ->
	#	表单数据
	formData = {}

	# 审计记录
	auditList = []

	_minxiInstanceData(formData, instance)

	console.log formData

	if _checkParameter(formData)
		logger.debug("_sendContractInstance: #{instance._id}")

		# 添加到相应的档案表
		record_id = Creator.Collections["archive_wenshu"].insert(formData)

		# 整理关联档案
		_minxiRelatedArchives(instance, record_id)

		# 处理审计记录
		# _minxiInstanceTraces(auditList, instance, record_id)

		# InstancesToArchive.success instance
	else
		InstancesToArchive.failed instance, "立档单位 不能为空"


@Test = {}
# Test.run('P7pEubcWpeBRprX5w')
Test.run = (ins_id)->
	instance = Creator.Collections["instances"].findOne({_id: ins_id})
	if instance
		console.log instance.name
		InstancesToArchive.syncNonContractInstance instance

InstancesToArchive::syncNonContractInstances = () ->
	console.time("syncNonContractInstances")
	instances = @getNonContractInstances()
	that = @
	console.log "instances.length is #{instances.length}"
	instances.forEach (mini_ins)->
		instance = Creator.Collections["instances"].findOne({_id: mini_ins._id})
		if instance
			console.log instance.name
			# InstancesToArchive.syncNonContractInstance instance
	console.timeEnd("syncNonContractInstances")