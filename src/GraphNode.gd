tool
extends GraphNode

export (PackedScene) var node_line_type = preload("GraphNodeLine.tscn")
export (Color) var slot_color
export (int) var start_amount = 1
export (int) var max_amount = 16
var node_lines = []

func _ready():
	rect_min_size = rect_size
	add_node_lines(start_amount)

func change_node_lines_amount(by_amount):
	var amount = node_lines.size()
	var new_amount = max(min(amount+by_amount, max_amount), start_amount)
	if new_amount != amount:
		var difference = new_amount - amount
		if difference > 0:
			add_node_lines(difference)
		else:
			remove_node_lines(difference)
		$NodeLineCount.set_count(new_amount)
	
func _on_Plus_pressed():
	change_node_lines_amount(1)

func _on_Minus_pressed():
	change_node_lines_amount(-1)

func get_data():
	var data = {
		"type": title,
		"editor_data": {
			"rect_x": rect_size.x,
			"rect_y": rect_size.y,
			"offset_x": offset.x,
			"offset_y": offset.y,
		},
	}
	
	var lines = []
	if $NodeLineCount.visible:
		data["Size"] = node_lines.size()
	for i in range(0,node_lines.size()):
		if node_lines[i].is_line_visible():
			lines.append(node_lines[i].get_data())
	if lines.size() > 0:
		data["Lines"] = lines
	return data

func set_data(data):
	var editor_data = data["editor_data"]
	rect_size = Vector2(editor_data["rect_x"], editor_data["rect_y"])
	offset = Vector2(editor_data["offset_x"], editor_data["offset_y"])
	if $NodeLineCount.visible:
		change_node_lines_amount(data["Size"]-start_amount)
	for i in range(0,node_lines.size()):
		if node_lines[i].is_line_visible():
			node_lines[i].set_data(data["Lines"][i])

func set_node_line(node_line):
	pass

func add_node_lines(by_amount):
	for i in range(0,by_amount):
		var node_line = node_line_type.instance()
		node_lines.append(node_line)
		set_node_line(node_line)
		add_child(node_line)

func remove_node_lines(by_amount):
	for i in range(0,-by_amount):
		var id = node_lines.size()-1
		var node_line = node_lines[id]
		if is_slot_enabled_left(id):
			get_parent().clear_left_node_connection(get_name(), id) # Signal
		if is_slot_enabled_right(id):
			get_parent().clear_right_node_connection(get_name(), id) # Signal
		node_lines.erase(node_line)
		remove_child(node_line)
		node_line.queue_free()
	_on_Node_resize_request(Vector2(rect_size.x,rect_min_size.y))

func _on_Node_resize_request(new_minsize):
	rect_size = new_minsize

func _on_Node_close_request():
	get_parent().remove_node(self) # Signal
	queue_free()
