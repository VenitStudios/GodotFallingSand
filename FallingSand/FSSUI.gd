class_name FSSUI extends Control

@onready var simulator : FallingSandSim = get_parent()

func create():
	size = get_window().size
	add_elements()

func add_elements():
	%Container.columns = %Container.size.x / 98
	await get_tree().process_frame
	%Utils.position.x = %Container.size.x + 16
	%Utils.size.y = 24
	
	for element in simulator.cells:
		var element_cell = element.new()
		var b = Button.new()
		%Container.add_child(b)
		b.pressed.connect(button_pressed.bind(element_cell.cell_name.to_upper()))
		b.custom_minimum_size = Vector2i(96, 24)
		b.text = element_cell.cell_name

func button_pressed(e):
	#this is not efficent i know i just couldnt think of anything else
	for c in simulator.cells.size():
		var item = simulator.cells[c]
		if item.new().cell_name.to_upper() == e:
			simulator.current_cell_index = c


func clear_button_pressed() -> void: 
	%ClearDialog.show()
	get_tree().paused = true
	%Clear.release_focus()

func _on_clear_dialog_confirmed() -> void:
	for cell in simulator.cell_list: if is_instance_valid(cell): cell.queue_free()
	simulator.cell_data.clear()
	get_tree().paused = false
	simulator.cell_list.clear()


func _on_clear_dialog_canceled() -> void:
	get_tree().paused = false
