extends PanelContainer

signal source_changed

var widget : BaseWidget setget set_widget
onready var data_source := DataSource.new() setget set_data_source

onready var metrics_options := $VBoxContainer/DatasourceSettings/VBoxContainer2/MetricsOptions
onready var filters_widget := $VBoxContainer/DatasourceSettings/HBoxContainer/FilterWidget
onready var legend_edit := $VBoxContainer/DatasourceSettings/VBoxContainer5/LegendEdit
onready var function_options := $VBoxContainer/DatasourceSettings/VBoxContainer3/FunctionComboBox
onready var date_offset_edit := $VBoxContainer/DatasourceSettings/VBoxContainer/DateOffsetLineEdit
onready var stacked_check_box := $VBoxContainer/DatasourceSettings/StackedCheckBox
onready var by_line_edit := $VBoxContainer/DatasourceSettings/VBoxContainer4/ByLineEdit
onready var query_edit := $VBoxContainer/VBoxContainer/QueryEdit

var interval : int = 3600

func _ready() -> void:
	data_source.interval = interval
	data_source.widget = widget

func _on_Button_toggled(button_pressed : bool) -> void:
	$VBoxContainer/DatasourceSettings.visible = not button_pressed

func _on_DeleteButton_pressed() -> void:
	queue_free()


func set_metrics(metrics : Dictionary) -> void:
	metrics_options.clear()
	for metric in  metrics:
		metrics_options.add_item(metric)


func _on_MetricsOptions_option_changed(option : String) -> void:
	update_query()
	API.query_tsdb("resoto_"+option, self, "_on_metrics_query_finished")


func _on_metrics_query_finished(error:int, response) -> void:
	var labels := []
	var data = response.transformed.result
	for label in data.data.result[0].metric:
		if not label.begins_with("__"):
			labels.append(label)
	
	filters_widget.labels.set_items(labels)
	
	filters_widget.value.set_items([])


func update_query() -> void:
	var query = "resoto_"+metrics_options.text
	var filters : String = filters_widget.get_node("VBoxContainer/LineEdit").text
	var offset : String = date_offset_edit.text
	if filters != "":
		query = "%s{%s}" % [query, filters]
	if offset != "":
		offset = "offset " + offset
		query = "%s %s" % [query, offset]
	if function_options.text != "":
		if "_over_time" in function_options.text:
			query = "%s[$interval]" % [query]
		query = "%s(%s)" % [function_options.text, query]
	if by_line_edit.text != "":
		query = "sum(%s) by %s" % [query, by_line_edit.text]
		
	if data_source.query != query:
		data_source.query = query
		query_edit.text = query
		emit_signal("source_changed")
	
func set_widget(new_widget : BaseWidget) -> void:
	widget = new_widget
	data_source.widget = new_widget
	var ranged : bool = widget.data_type == BaseWidget.DATA_TYPE.RANGE
	stacked_check_box.visible = ranged
	legend_edit.get_parent().visible = ranged


func _on_StackedCheckBox_toggled(button_pressed : bool) -> void:
	data_source.stacked = button_pressed
	update_query()


func _on_LegendEdit_text_entered(new_text : String) -> void:
	data_source.legend = new_text
	update_query()


func _on_FunctionComboBox_option_changed(_option) -> void:
	update_query()


func _on_FilterWidget_filter_changed(_filter) -> void:
	update_query()


func _on_DateOffsetLineEdit_text_entered(_new_text) -> void:
	update_query()


func _on_ByLineEdit_text_entered(_new_text) -> void:
	update_query()


func _on_QueryEdit_text_entered(new_text : String) -> void:
	data_source.query = new_text
	emit_signal("source_changed")

func set_data_source(new_data_source : DataSource) -> void:
	query_edit.text = new_data_source.query
	data_source.query = new_data_source.query
	legend_edit.text = new_data_source.legend
	data_source.legend = new_data_source.legend
	
