extends Control

#ui elements
@onready var dialogue_box = $Panel/VBoxContainer/DialogueLabel
@onready var speaker_label = $Panel/VBoxContainer/SpeakerLabel
@onready var options_container = $Panel/OptionsContainer

#dialogue data
var dialogue_data = {}
var current_node = "start"

func _ready():
	load_dialogue("res://dialogue/dialogue.txt") # replace this with any dialogue
	print("Loaded dialogue nodes: ", dialogue_data.keys())
	display_current_node()

#loads the dialogue
func load_dialogue(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open dialogue file: " + file_path)
		return
	
	var current_id = ""
	var current_speaker = ""
	var current_text = ""
	var current_options = []
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		#skip empty lines and comments
		if line == "" or line.begins_with("#"):
			continue
		
		#node id line
		if line.begins_with("[") and line.ends_with("]"):
			#save previous node if it exists
			if current_id != "":
				dialogue_data[current_id] = {
					"speaker" : current_speaker,
					"text" : current_text,
					"options" : current_options.duplicate()
				}
			
			#start a new node
			current_id = line.substr(1, line.length() - 2)
			current_speaker = ""
			current_text = ""
			current_options = []
		
		#speaker line
		elif line.begins_with("speaker:"):
			current_speaker = line.substr(8).strip_edges()
		
		#text line
		elif line.begins_with("text:"):
			current_text = line.substr(5).strip_edges()
		
		#option line
		elif line.begins_with("option:"):
			var option_data = line.substr(7).strip_edges()
			var parts = option_data.split("->")
			if parts.size() == 2:
				current_options.append({
					"text" : parts[0].strip_edges(),
					"next" : parts[1].strip_edges()
				})
	
	#save last node
	if current_id != "":
		dialogue_data[current_id] = {
			"speaker" : current_speaker,
			"text" : current_text,
			"options" : current_options.duplicate()
		}
	
	file.close()

func display_current_node():
	if not dialogue_data.has(current_node):
		push_error("Node not found: " + current_node)
		return
	
	var node_data = dialogue_data[current_node]
	
	#display speaker and text
	speaker_label.text = node_data["speaker"]
	dialogue_box.text = node_data["text"]
	
	#clear previous options
	for child in options_container.get_children():
		child.queue_free()
	
	#create option buttons
	for option in node_data["options"]:
		var button = Button.new()
		options_container.add_child(button)
		button.text = option["text"]
		button.pressed.connect(_on_option_selected.bind(option["next"]))
	
	#if no options, create a continue button
	if node_data["options"].size() == 0:
		var button = Button.new()
		button.text = "Continue"
		button.pressed.connect(_on_dialogue_end)
		options_container.add_child(button)

func _on_option_selected(next_node: String):
	if next_node == "end":
		_on_dialogue_end()
	else:
		current_node = next_node
		display_current_node()

func _on_dialogue_end():
	print("Dialogue ended")
	queue_free()  # or hide() if you want to reuse
