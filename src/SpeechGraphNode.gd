tool
extends "res://addons/Godot-DialogGraphPlugin/src/GraphNode.gd"

func set_node_line(node_line):
	node_line.set_label("Speech Code " + String(node_lines.size()) + ":")
