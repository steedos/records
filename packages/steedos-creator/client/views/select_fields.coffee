Template.select_fields.onCreated ->
    _self = this
    this.autorun (c)->
        list_view_obj = Creator.Collections.object_listviews.findOne(Session.get("list_view_id"))
        if list_view_obj and Session.get("object_name")
            all_fields = Creator.getSchema(Session.get("object_name"))._firstLevelSchemaKeys
            visible_fields = list_view_obj.columns
            available_fields = _.difference(all_fields, visible_fields)
            schema = Creator.getSchema(Session.get("object_name"))._schema

            available_fields = _.map available_fields, (field) ->
                obj = _.pick(schema, field)
                label = obj[field].label
                return {label: label, value: field}

            visible_fields = _.map visible_fields, (field) ->
                obj = _.pick(schema, field)
                label = obj[field].label
                return {label: label, value: field}

            _self.available_fields = new ReactiveVar(available_fields)
            _self.visible_fields = new ReactiveVar(visible_fields)

Template.select_fields.helpers Creator.helpers

Template.select_fields.helpers
    available_fields: ()->
        available_fields = Template.instance().available_fields?.get()
        available_fields = _.sortBy available_fields, (field) ->
            return field.value
        return available_fields
    
    visible_fields: ()->
        visible_fields = Template.instance().visible_fields?.get()
        return visible_fields

         

Template.select_fields.events 
    'click .add-columns': (event, template) ->
        available_fields = template.available_fields.get()
        visible_fields = template.visible_fields.get()
        selected_fields = []
        $('#column-add-select option:selected').each ->
            value = $(this).val()
            label = $(this).text()

            selected_fields.push value

            available_fields = _.filter available_fields, (field) ->
                if field.value == value
                    return undefined
                else
                    return field
            
            visible_fields.push({label: label, value: value})

        template.available_fields.set(available_fields)
        template.visible_fields.set(visible_fields)

        $('#column-add-select option:selected').attr("selected", false)

        setTimeout ->
            $('#column-sub-select option').each ->
                if _.indexOf(selected_fields, $(this).val()) > -1
                    $(this).prop("selected", true)
        , 10

    'click .sub-columns': (event, template) ->
        available_fields = template.available_fields.get()
        visible_fields = template.visible_fields.get()
        selected_fields = []
        $('#column-sub-select option:selected').each ->
            value = $(this).val()
            label = $(this).text()

            selected_fields.push value

            visible_fields = _.filter visible_fields, (field) ->
                if field.value == value
                    return undefined
                else
                    return field
            
            available_fields.push({label: label, value: value})

        template.available_fields.set(available_fields)
        template.visible_fields.set(visible_fields)
         
        $('#column-sub-select option:selected').attr("selected", false)

        setTimeout ->
            $('#column-add-select option').each ->
                if _.indexOf(selected_fields, $(this).val()) > -1
                    $(this).prop("selected", true)
        , 10

    'click .btn-save-columns': (event, template)->
        visible_fields = template.visible_fields.get()
        columns = visible_fields.getProperty("value")
        listview_id = Session.get("list_view_id")

        Session.set("list_view_visible", false)

        Meteor.call "update_columns", listview_id, columns, (error, result) -> 
            Session.set("list_view_visible", true)
            if error 
                console.log "error", error
                toastr.error(error.reason)
            if result
                toastr.success("List view updated.")

            Modal.hide(template)

    'click .up-column': (event, template)->
        visible_fields = template.visible_fields.get()
        first_selected_index = $("#column-sub-select option:selected").index()
        select_fields_length = $("#column-sub-select option:selected").length
        if first_selected_index > 0
            visible_fields.splice(first_selected_index + select_fields_length, 0, visible_fields[first_selected_index - 1])
            visible_fields[first_selected_index - 1] = undefined
            visible_fields = _.compact(visible_fields)
            template.visible_fields.set(visible_fields)
            $('#column-sub-select option').each ->
                if $(this).index() >= (first_selected_index - 1) and $(this).index() < (first_selected_index + select_fields_length - 1)
                    $(this).prop("selected", true)
                else
                    $(this).attr("selected", false)

    'click .down-column': (event, template)->
        visible_fields = template.visible_fields.get()
        first_selected_index = $("#column-sub-select option:selected").index()
        select_fields_length = $("#column-sub-select option:selected").length
        if first_selected_index + select_fields_length < visible_fields.length
            visible_fields.splice(first_selected_index, 0, visible_fields[first_selected_index + select_fields_length])
            visible_fields[first_selected_index + select_fields_length + 1] = undefined
            visible_fields = _.compact(visible_fields)
            template.visible_fields.set(visible_fields)

            $('#column-sub-select option').each ->
                if $(this).index() >= (first_selected_index + 1) and $(this).index() < (first_selected_index + select_fields_length + 1)
                    $(this).prop("selected", true)
                else
                    $(this).attr("selected", false)