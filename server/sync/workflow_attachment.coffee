import { HTTP } from 'meteor/http'
@Attachment = {}
cfs_instance = new Mongo.Collection('cfs.instances.filerecord')
request = Npm.require('request')
fs =  require('fs')
path = require('path')
execSync = require('child_process').execSync

# 同步附件
# TODO
#  1、获取附件：cfs_instance = new Mongo.Collection("cfs.instances.filerecord");
#             	cfs_instance
# 				cfs_instance.find({'metadata.instance': '5359bfb533490418ab006160'})
#  2、下载附件：下载完成后才可执行第3步，下载可能报错，如何处理?
#				获取附件的地址 
#				Meteor.absoluteUrl("api/files/instances/") + f._id + "/" + encodeURI(f.original.name)

#  3、转换附件：转换可能报错，如何处理?
#  4、上传附件

#  附件下载地址：Meteor.absoluteUrl("api/files/instances/") + f._id + "/" + encodeURI(f.original.name)
Attachment.syncAttachments=()->
	cfs_instances=cfs_instance.find({'metadata.instance': '53a6a38b3349045c050038c4'})
	cfs_instances.forEach (cfs_file)->
		downloadFile(cfs_file)

# 下载文件
downloadFile=(cfs_file)->
	# 附件地址
	url = Meteor.absoluteUrl("api/files/instances/") + cfs_file._id + "/" + encodeURI(cfs_file.original.name)
	# 附件名称
	fileName = cfs_file.original.name
	# 附件下载到本地地址{space}\{instance_id}\{cfs_id}.doc
	filePath = path.format({
		dir : path.join(Meteor.settings.records.txt_file_path,cfs_file.metadata.space, cfs_file.metadata.instance),
		base : cfs_file._id + path.extname(fileName)
		})

	# console.log url
	console.log filePath

	# 路径初始化不存在,创建路径
	i=0
	if !fs.existsSync filePath
		dirArr = path.dirname(filePath).split('\\')
		tempPath = ''
		for dir in dirArr
			if dir
				tempPath += dir
				existPath = fs.existsSync tempPath
				if !existPath
					fs.mkdirSync tempPath
				tempPath += '\\'
	stream = fs.createWriteStream(filePath,{encoding:'utf8'})
	request.get({
	  url: url,
	  headers: {
	    'referer': Meteor.absoluteUrl()
	  }
	}).pipe(stream)

	stream.on 'close', Meteor.bindEnvironment ()->
		converterFile(cfs_file, filePath)

# 判断转换附件转换的类型
isConvertibleType = (extname)->
	extname = extname.toUpperCase()
	convertibleArr = [
		'DOC', 'DOCX', 'XLS', 'XLSX'
	]
	if convertibleArr.indexOf(extname) > -1
		return true
	else
		return false

# 利用控制台调用转换程序，转换成txt文件
converterFile = (cfs_file, filePath)->
	# 后缀名带'.'
	extName=path.extname filePath
	convertibleType = isConvertibleType(extName.substring 1)
	# console.log convertibleType
	if convertibleType
		converterPath = filePath.substring(0,filePath.length-extName.length) + '.txt'
		cmd = ''
		cmd += Meteor.settings.records.office_converter_path
		cmd += ' '+filePath
		cmd += ' '+converterPath
		# console.log cmd
		try
			execSync cmd,{encoding: 'utf8'}
			
			fs.unlinkSync filePath
			
			readFile(cfs_file,converterPath)
		catch e
			console.log e
				

# 读取转换后的txt文件信息
readFile=(cfs_file,converterPath)->
	readStream = fs.readFileSync converterPath,{encoding:'utf8'}
	# readStream.on 'open',(fd)->
	# 	console.log '文件已打开'
	# readStream.on 'data',(data)->
	# console.log readStream
	# toString后面必须加（），不然会报错
	content = readStream.toString().substring 1
	# console.log content
	# 将获取的content存到ES中
	index='steedos'
	instance_type='instances'
	instance_id = cfs_file.metadata.instance
	ping_url=es_server+'/'+index+'/'+instance_type+'/'+instance_id
	# HTTP.call('GET',ping_url,{}, (error, result)->
	# 	if !error
	# 		console.log result
	# )
	# 先判断ES中是否存在该申请单
	# try
	# 	result = HTTP.call('GET', 'http://localhost:9200/steedos/instances/54d70b00527eca5fbc009c51')
	# 	console.log result
	# catch e
	# 	console.log e + ' not found'



	ping_attachment_url=ping_url
	# console.log ping_attachment_url

	attachment = {
		cfs_id:cfs_file._id,
		cfs_owner_name:cfs_file.metadata.owner_name,
		cfs_title:cfs_file.original.name,
		cfs_file:content
	}
	strattch = JSON.stringify attachment

	_post(ping_attachment_url, strattch)

_post = (ping_attachment_url, strattch) ->
	console.log ping_attachment_url
	console.log strattch
	try
		result = HTTP.call(
				'POST', ping_attachment_url,
				{data: strattch}
			)
	catch e
		console.log e + "result is #{result}"
