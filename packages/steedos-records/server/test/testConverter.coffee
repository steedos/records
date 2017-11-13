@Test = {}
request = Npm.require('request')
mkdirp = Npm.require('mkdirp')
fs = Npm.require('fs')
path = Npm.require('path')
execSync = Npm.require('child_process').execSync

# 测试控制台转换文件
Test.converter=()->
	downloadFile = 'D:\\OfficeConverter\\File\\Error.docx'
	converterFile = 'D:\\OfficeConverter\\File\\Error.txt'
	cmd = ''
	cmd += Meteor.settings.records.office_converter_path
	cmd += ' ' + downloadFile
	cmd += ' ' + converterFile
	console.log cmd+'----'
	try
		execSync cmd,{encoding: 'utf8'}
		console.log 'success'
		readStream = fs.readFileSync converterFile,{encoding:'utf8'}
		content = readStream.toString().substring 1
		console.log content
	catch e
		console.log e
		console.log 'error'

	