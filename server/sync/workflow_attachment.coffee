# import { HTTP } from 'meteor/http'
@Attachment = {}
cfs_instance = new Mongo.Collection('cfs.instances.filerecord')
request = Npm.require('request')
fs =  require('fs')
path = require('path')
mkdirp = require('mkdirp')
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
	cfs_instances=cfs_instance.find({'metadata.instance': '52a7f5b9334904787b0018f3'})
	cfs_instances.forEach (cfs_file)->
		downloadFile(cfs_file)

# 下载文件
downloadFile=(cfs_file)->
	# 附件地址
	url = Meteor.absoluteUrl("api/files/instances/") + cfs_file._id + "/" + encodeURI(cfs_file.original.name)
	
	# 附件下载到本地地址{space}\{instance_id}\{cfs_id}.doc
	if !filePath && __meteor_bootstrap__ && __meteor_bootstrap__.serverDir
		filePath = path.join(__meteor_bootstrap__.serverDir, "../../../records/files/#{cfs_file.metadata.space}/#{cfs_file.metadata.instance}");
		# filePath = path.format({
		# 	dir : path.join(__meteor_bootstrap__.serverDir,'..','..','..','records','files'),
		# 	base : cfs_file._id + path.extname(fileName)
		# 	})
	# 判断路径是否创建成功
	if !filePath
    	throw new Error 'FS.Store.FileSystem unable to determine path'

	# 路径不存在,创建对应的文件夹
	if !fs.existsSync filePath
		mkdirp.sync(filePath)
	# 附件名称
	fileName = cfs_file._id + path.extname(cfs_file.original.name)

	fileAddress = path.join(filePath, fileName)

	stream = fs.createWriteStream fileAddress,{encoding:'utf8'}
	request.get({
	  url: url,
	  headers: {
	    'referer': Meteor.absoluteUrl()
	  }
	}).pipe(stream)

	stream.on 'close', Meteor.bindEnvironment ()->
		converterFile cfs_file,fileAddress

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
	content = readStream.toString().substring 1
	index='steedos'
	instance_type='instances'
	instance_id = cfs_file.metadata.instance
	ping_url = es_server + '/' + index + '/' + instance_type + '/' + instance_id
	attachObj = {
		cfs_id:cfs_file._id,
		cfs_owner_name:cfs_file.metadata.owner_name,
		cfs_title:cfs_file.original.name,
		cfs_file:content
	}
	# attchment = JSON.stringify attachObj
	console.log attachObj
	_updateAttach(ping_url, attachObj)

_updateAttach = (ping_url, attchment) ->
	console.log ping_url
	data = {
		# "script" : 'ctx._source.attachment = "'+ attchment.cfs_file + '"'
		"script" : {
			"inline":'ctx._source.attachments.add(params.data)',
			"lang": "painless",
			"params":{
				data:attchment
				}
		}
	}
	try
		result = HTTP.call(
				'POST', ping_url + '/' + '_update',{data:data}
			)
	catch e
		console.log e + "result is #{result}"