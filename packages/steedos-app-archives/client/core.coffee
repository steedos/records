Archive.createBorrowObject = (record_id)->
    doc = {}
    now = new Date()
    #collection_record = Creator.Collections["archive_records"]
    #console.log collection_record.find({},{field:{year: 1}}).sort({year:-1}).limit(1)
    doc.year = now.getFullYear().toString()
    doc.unit_info = Creator.Collections["space_users"].findOne({user:Meteor.userId(),space:Session.get("spaceId")},{fields:{company:1}})?.company
    doc.start_date = now
    doc.end_date =new Date(now.getTime()+7*24*3600*1000)
    doc.use_with = "工作查考"
    doc.use_fashion = "实体借阅"
    doc.file_type = "立卷方式(文件级)"
    doc.space = Session.get("spaceId")
    doc.is_approved = false
    doc.relate_record = record_id
    # Creator.TabularSelectedIds?["archive_records"].forEach (selectedId)->
    # 	doc.relate_documentIds.push collection_record.findOne({_id:selectedId})._id
    console.log doc
# else
# 	#swal("请在全部或已接收视图下执行操作")
    return doc