Creator.Objects.archive_kuaiji =
	name: "archive_kuaiji"
	icon: "record"
	label: "会计档案"
	enable_search: true
	enable_files: true
	enable_api: true
	fields:
		archival_code:
			type:"text"
			label:"档号"
		year:
			type: "text"
			label:"年度"
			sortable:true
		docket_number:
			type: "text"
			label:"案卷号"
			required:true
		title:
			type:"textarea"
			label:"题名"
			is_wide:true
			is_name:true
			sortable:true
			searchable:true
			required:true
		retention_peroid:
			type:"master_detail"
			label:"保管期限(会计)"
			reference_to:"archive_retention"
			sortable:true
			required:true
		security_classification:
			type:"select"
			label:"密级"
			defaultValue: "非密"
			options: [
				{label: "绝密", value: "绝密"},
				{label: "机密", value: "机密"},
				{label: "秘密", value: "秘密"},
				{label: "非密", value: "非密"}
			]
			sortable:true
		original_voucher_number:
			type: "text"
			label:"原凭证号"
		start_date:
			type:"date"
			label:"起始日期"
			format:"YYYYMMDD"
		closing_date:
			type:"date"
			label:"截止日期"
			format:"YYYYMMDD"

