tool
extends "res://addons/Godot-DialogGraphPlugin/src/GraphNode.gd"

func set_node_line(node_line):
	node_line.set_first_label("Speech Code " + String(node_lines.size()) + ":")
	node_line.set_second_label("Translation " + String(node_lines.size()) + ":")
