class_name FallingSandSim extends TextureRect







signal run_simulation

## Defines the Size of the Sim Viewport and by Definition, the Simulation.
@export var viewport_size := Vector2i(128, 128)
@export var viewport_scale := Vector2i(1, 1)

## Cell Dict
@onready var cell_data := {}
@onready var cell_list := []

@onready var current_cell := cellObject
@onready var current_cell_index := 0

@onready var cells := [cellNameStone, cellNameSand, cellNameWater, cellNameOil,cellNameFire]

var mouse_held_down = false

func _ready() -> void:
	init_viewport()
	render_simulation()

func init_viewport():
	self.size = viewport_size * viewport_scale
	texture_filter = TEXTURE_FILTER_NEAREST
	Engine.max_fps = 60.0
	get_window().size = viewport_size * viewport_scale
	get_window().unresizable = true

func _input(event: InputEvent) -> void:
	mouse_held_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP): current_cell_index = wrapi(current_cell_index + 1, 0, cells.size())
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN): current_cell_index = wrapi(current_cell_index - 1, 0, cells.size())


func _process(delta: float) -> void:
	if mouse_held_down:
		var event_position = get_local_mouse_position() / Vector2(viewport_scale)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and get_rect().has_point(event_position): 
			var cell = get_cell_at_position(event_position)
			if not cell: set_cell_at_position(event_position, current_cell.new())
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and get_rect().has_point(event_position): 
			var cell = get_cell_at_position(event_position)
			if cell: set_cell_at_position(event_position, null)
	
	if cell_data.size() > 0: 
		render_simulation()

## Runs then Renders the Simulation
func render_simulation() -> void:
	current_cell = cells[current_cell_index]
	get_window().title = str("Falling Sand Sim - Currently Selected: %s" % str(current_cell.new().cell_name))
	
	run_simulation.emit()
	## Create Image for Frame.
	var frame = Image.create_empty(viewport_size.x, viewport_size.y, false, Image.FORMAT_RGB8)
	frame.fill(Color.BLACK)
	
	for cell_pos in cell_data.keys():
		if cell_pos is Vector2i:
			var cell = get_cell_at_position(cell_pos)
			if cell and get_rect().has_point(cell_pos * viewport_scale): frame.set_pixelv(cell_pos, cell.color)
	for cell in cell_list:
		if is_instance_valid(cell):
			if not get_rect().has_point(Vector2(cell.position * viewport_scale)):
				set_cell_at_position(cell.position, null, false)
				print('deleting off screen cell')
	
	if not frame.is_empty():
		texture = ImageTexture.create_from_image(frame)

## Sets the Cell at the Given Position to the Given Type
func set_cell_at_position(cell_position : Vector2i, cell : cellObject, avoid_deletion := false) -> bool:
	if not get_rect().has_point(cell_position * viewport_scale): return false
	if cell == null:
		var cell_at_pos = cell_data.get(cell_position)
		if cell_data.has(cell_position):  cell_data.erase(cell_position)
		if not avoid_deletion and cell_at_pos:
			cell_at_pos.queue_free()
			
		
		return false
	
	cell_data[cell_position] = cell
	
	
	if cell:
		
		if not cell_list.has(cell): cell_list.append(cell)
		cell.simulator = self
		cell.position = cell_position
		if cell.has_method("simulate") and not run_simulation.is_connected(cell.simulate): run_simulation.connect(cell.simulate)
		
		return true
	
	return false
## Returns the Cell at the Given Position
func get_cell_at_position(cell_position : Vector2i) -> cellObject: 
	if cell_data.has(cell_position) and is_instance_valid(cell_data[cell_position]): return cell_data[cell_position]
	return null

## Base Cell Class, what All Others use.
class cellObject extends Node:
	static var cell_name := "New Cell"
	static var simulator : FallingSandSim
	
	var position : Vector2i = Vector2i.ZERO
	var ignitable : bool = false
	var decay : int = 0
	var color : Color = Color.WHITE
	
	func get_cell(point): 
		var p = simulator.get_cell_at_position(point); 
		if is_instance_valid(p): return p;  
		else: return null
	
	func set_cell(point : Vector2i, cell : cellObject, nodel : = false): simulator.set_cell_at_position(point, cell, nodel)
	
	func move(point1, point2, cell1, cell2):
		set_cell(point1, cell1, true)
		set_cell(point2, cell2)
	
	func is_cell_solid(cell): 
		return cell is cellTypeSolid
	
	func is_cell_valid(cell): return is_instance_valid(cell)


## Solid Cell Class.
class cellTypeSolid extends cellObject:
	func _init() -> void: pass

## Sand Cell Class.
class cellTypeGravity extends cellTypeSolid:
	func _init() -> void: pass
	func simulate():
		
		var up_cell_pos = position + Vector2i(0, -1); var up_cell = get_cell(up_cell_pos)
		var down_cell_pos = position + Vector2i(0, 1); var down_cell = get_cell(down_cell_pos)
		var left_cell_pos = position + Vector2i(-1, 1); var left_cell = get_cell(left_cell_pos)
		var right_cell_pos = position + Vector2i(1, 1); var right_cell = get_cell(right_cell_pos)
		
		if not is_cell_solid(down_cell): move(position, down_cell_pos, down_cell, self)
		else:
			if not is_cell_solid(right_cell): move(position, right_cell_pos, right_cell, self)
			if not is_cell_solid(left_cell): move(position, left_cell_pos, left_cell, self)


## Liquid Cell Class.
class cellTypeLiquid extends cellObject:
	func _init() -> void: pass
	func simulate():
		var up_cell_pos = position + Vector2i(0, -1); var up_cell = get_cell(up_cell_pos)
		var down_cell_pos = position + Vector2i(0, 1); var down_cell = get_cell(down_cell_pos)
		
		var left_cell_pos = position + Vector2i(-1, 0); var left_cell = get_cell(left_cell_pos)
		var right_cell_pos = position + Vector2i(1, 0); var right_cell = get_cell(right_cell_pos)
		
		if not is_cell_valid(down_cell): move(position, down_cell_pos, down_cell, self)
		if is_cell_valid(down_cell):
			var valids = []
			if not is_cell_valid(right_cell): valids.append(right_cell_pos)
			if not is_cell_valid(left_cell): valids.append(left_cell_pos)
			if valids.size() > 0:
				var v = valids.pick_random()
				move(position, v, get_cell(v), self)
				return
			move(position, right_cell_pos, right_cell, self)

## Gas Cell Class.
class cellTypeGas extends cellObject:
	func _init() -> void: pass
	func simulate():
		var up_cell_pos = position + Vector2i(0, -1); var up_cell = get_cell(up_cell_pos)
		var down_cell_pos = position + Vector2i(0, 1); var down_cell = get_cell(down_cell_pos)
		
		var left_cell_pos = position + Vector2i(-1, 0); var left_cell = get_cell(left_cell_pos)
		var right_cell_pos = position + Vector2i(1, 0); var right_cell = get_cell(right_cell_pos)
		
		if not is_cell_valid(up_cell): move(position, up_cell_pos, up_cell, self)
		
		if is_cell_valid(up_cell):
			var valids = []
			if not is_cell_valid(right_cell): valids.append(right_cell_pos)
			if not is_cell_valid(left_cell): valids.append(left_cell_pos)
			if valids.size() > 0:
				var v = valids.pick_random()
				move(position, v, get_cell(v), self)
				return
			move(position, right_cell_pos, right_cell, self)

## Fire Cell Class.
class cellTypeFire extends cellObject:
	func _init() -> void: self.color = Color.WHITE; decay += randi_range(0, 10)
	func simulate(): 
		decay += 1
		color -= Color(decay * 0.01, decay * 0.01, decay * 0.01)
		if decay >= 50 and simulator.get_cell_at_position(position): 
			simulator.set_cell_at_position(position, null)
			queue_free()
			return
		 
		if not simulator.get_cell_at_position(position) == self: return
		## Fire ignition code.
		
		for ang in [0, 45, 90, 135, 180, 225, 270, 315]:
			var p = position + Vector2i(Vector2.UP.rotated(ang).round())
			var loop_cell = simulator.get_cell_at_position(p)
			if loop_cell:
				if loop_cell.ignitable: 
					set_cell(p, cellNameFire.new())
		
		var up_cell_pos = position + Vector2i(0, -1); var up_cell = get_cell(up_cell_pos)
		var down_cell_pos = position + Vector2i(0, 1); var down_cell = get_cell(down_cell_pos)
		
		var left_cell_pos = position + Vector2i(-1, 0); var left_cell = get_cell(left_cell_pos)
		var right_cell_pos = position + Vector2i(1, 0); var right_cell = get_cell(right_cell_pos)
		
		if not is_cell_valid(up_cell): move(position, up_cell_pos, up_cell, self)
		if is_cell_valid(up_cell):
			var valids = []
			if not is_cell_valid(right_cell): valids.append(right_cell_pos)
			if not is_cell_valid(left_cell): valids.append(left_cell_pos)
			
			if valids.size() > 0:
				var v = valids.pick_random()
				move(position, v, get_cell(v), self)
				return
			move(position, right_cell_pos, right_cell, self)


class cellNameStone extends cellTypeSolid:
	func _init() -> void:
		cell_name = "Stone"
		self.color = Color.GRAY

class cellNameSand extends cellTypeGravity:
	func _init() -> void:
		cell_name = "Sand"
		self.color = Color.SANDY_BROWN

class cellNameWater extends cellTypeLiquid:
	func _init() -> void:  
		cell_name = "Water"
		self.color = Color.MEDIUM_BLUE + Color(randf() * 0.25, randf() * 0.25, randf() * 0.25)

class cellNameOil extends cellTypeLiquid:
	func _init() -> void:  
		cell_name = "Oil"
		self.ignitable = true
		self.color = Color.DARK_GREEN - Color(randf() * 0.25, randf() * 0.25, randf() * 0.25)

class cellNameFire extends cellTypeFire:
	func _init() -> void:  
		cell_name = "Fire"
		self.color = Color.DARK_ORANGE + Color(randf() * 0.5, randf() * 0.5, randf() * 0.5)

class cellNameSmoke extends cellTypeGas:
	func _init() -> void:
		cell_name = "Smoke"
		self.color = Color.LIGHT_GRAY
