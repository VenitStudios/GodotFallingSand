class_name FSSUI extends Control

@onready var simulator : FallingSandSim = get_parent()

func create():
	size = simulator.viewport_size * (simulator.viewport_scale + Vector2i(0, 1))
	add_elements()

func add_elements():
	await get_tree().process_frame
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
		%Selection.text = str("%s" % e)

func clear_button_pressed() -> void: 
	get_tree().paused = true
	for cell in simulator.cell_list: if is_instance_valid(cell): cell.queue_free()
	simulator.cell_data.clear()
	simulator.cell_list.clear()
	%Clear.release_focus()
	get_tree().paused = false
