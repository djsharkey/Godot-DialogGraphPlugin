extends Node

export (String, FILE, "*.json") var dialog_file = null

enum ACTION_TYPES {
	SPEECH,
	CHOICE
}

var nodes = {}
var conversations = {}
var default_conversation = null
var current

signal new_speech(speech_codes)
signal new_choice(choices)
signal dialog_finished()

func _ready():
	parse_dialog_data()

func parse_dialog_data():
	if dialog_file:
		var file = File.new()
		file.open(dialog_file, File.READ)
		var data = parse_json(file.get_as_text())
		file.close()
		for graph_node in data["nodes"]:
			match data["nodes"][graph_node]["type"]:
				"Conversation": create_conversation(data, graph_node)
				"Speech": create_speech(data, graph_node)
				"Choice": create_choice(data, graph_node)
				"Condition": create_condition(data, graph_node)
				"Mux": create_mux(data, graph_node)
				"Jump": create_jump(data, graph_node)

func start_dialog(conversation = default_conversation):
	current = conversations[conversation]
	process_conversation()

func continue_dialog():
	process()

func process(conversation = default_conversation):
	if !current:
		current = conversations[conversation]
	match nodes[current]["type"]:
		"Conversation":
			return process_conversation()
		"Speech":
			return process_speech()
		"Choice":
			return process_choice()
		"Condition":
			return process_condition()
		"Mux":
			return process_mux()
		"Jump":
			return process_jump()
	return null # TODO: This should really log an error at this point

func create_conversation(data, graph_node):
	var next = null
	if data["sc"].has(graph_node):
		next = data["sc"][graph_node]["0"]["to"]
	nodes[graph_node] = {"type": "Conversation", "next": next}
	conversations[data["nodes"][graph_node]["Lines"][0]] = graph_node
	if data["default_conversation"] == graph_node:
		default_conversation = data["nodes"][graph_node]["Lines"][0]

func process_conversation():
	return move_to_node(nodes[current]["next"], true)

func create_speech(data, graph_node):
	var next = null
	var size = data["nodes"][graph_node]["Size"]
	if data["sc"].has(graph_node):
		next = data["sc"][graph_node]["0"]["to"]
	nodes[graph_node] = {"type": "Speech", "next": next, "size": size}
	nodes[graph_node]["speech"] = data["nodes"][graph_node]["Lines"]

func process_speech():
	var lines = nodes[current]["speech"]
	emit_signal("new_speech", lines)
	move_to_node(nodes[current]["next"], false)
	return {
		"type": ACTION_TYPES.SPEECH,
		"lines": lines,
	}

func create_choice(data, graph_node):
	var size = data["nodes"][graph_node]["Size"]
	nodes[graph_node] = {"type": "Choice", "size": size}
	if data["sc"].has(graph_node):
		var next = []
		for i in range(size):
			if data["sc"][graph_node].has(String(i)):
				next.append(data["sc"][graph_node][String(i)]["to"])
			else:
				next.append(null)
		nodes[graph_node]["next"] = next
	nodes[graph_node]["choices"] = data["nodes"][graph_node]["Lines"]

func process_choice():
	var choices = nodes[current]["choices"]
	emit_signal("new_choice", nodes[current]["choices"])
	return {
		"type": ACTION_TYPES.CHOICE,
		"lines": choices,
		"callback": funcref(self, "choice_picked")
	}

func choice_picked(choice_idx):
	return move_to_node(nodes[current]["next"][choice_idx], true)

func create_condition(data, graph_node):
	var next_true = null
	var next_false = null
	if data["sc"].has(graph_node):
		next_true = data["sc"][graph_node]["0"]["to"]
		next_false = data["sc"][graph_node]["1"]["to"]
	nodes[graph_node] = {"type": "Condition", "next_true": next_true, "next_false": next_false}
	var full_path = data["nodes"][graph_node]["Line0"]
	var split = full_path.find_last("/")
	var path = full_path.substr(0,split)
	var property = full_path.substr(split+1, full_path.length() - 1 - split)
	nodes[graph_node]["path"] = path
	nodes[graph_node]["property"] = property

func process_condition():
	var condition = get_parent().get_node(nodes[current]["path"]).get(nodes[current]["property"])
	if condition:
		return move_to_node(nodes[current]["next_true"], true)
	else:
		return move_to_node(nodes[current]["next_false"], true)

func create_mux(data, graph_node):
	var next = null
	if data["sc"].has(graph_node):
		next = data["sc"][graph_node]["0"]["to"]
	nodes[graph_node] = {"type": "Mux", "next": next}

func process_mux():
	return move_to_node(nodes[current]["next"], true)

func create_jump(data, graph_node):
	var next = data["nodes"][graph_node]["Lines"][0]
	nodes[graph_node] = {"type": "Jump", "to": next}

func process_jump():
	return move_to_node(conversations[nodes[current]["to"]], true)

# move_to_node updates the current node reference to a new node if avaliable
# if continue_processing is true the process function will also we invoked for this new node
func move_to_node(node, continue_processing):
	if !node:
		emit_signal("dialog_finished")
		return
	current = node
	if continue_processing:
		return process()
