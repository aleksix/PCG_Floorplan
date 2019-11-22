extends TileMap

# imports
const squarify = preload("res://squarify.gd")
onready var sq = squarify.new()
const array_func = preload("res://array_funcs.gd")
onready var af = array_func.new()

class PseudoDictionaryInverseSorter:
	static func sort(a, b):
		if a[1] > b[1]:
			return true
		return false

func pseudodict_values(pseudodict, index = 1):
	var out = []
	for item in pseudodict:
		out.append(item[index])
	return out

export(int) var width = 100
export(int) var height = 100

export(Array, Array) var service_room_sizes = [["kitchen", 2], ["pantry", 0], ["laundry", 1]]
export(Array, Array) var social_room_sizes = [["living", 5], ["dining", 0], ["toilet", 0]]
export(Array, Array) var private_room_sizes = [["bedroom", 4], ["master", 0], ["bathroom", 2], ["secondary", 0]]

func draw_box(rect):
	var pos_x = rect.position.x
	var pos_y = rect.position.y
	var width = rect.size.x
	var height = rect.size.y
	for x in range(pos_x, pos_x + width):
		set_cell(x, pos_y, 0)
		set_cell(x, pos_y + height - 1, 0)
	for y in range(pos_y, pos_y + height):
		set_cell(pos_x, y, 0)
		set_cell(pos_x + width - 1, y, 0)

func label_area(rect, text):
	var label = Label.new()
	label.rect_scale = Vector2(7, 7)
	label.text = text
	label.rect_position = rect.position * cell_size
	label.rect_position.x += cell_size.x
	label.rect_position.y += cell_size.y
	label.rect_size = rect.size
	# Make the text black
	label.add_color_override("font_color", Color(0, 0, 0))
	add_child(label)

func fill_area(rect, cell):
	var pos_x = rect.position.x
	var pos_y = rect.position.y
	var width = rect.size.x
	var height = rect.size.y
	for x in range(pos_x, pos_x + width):
		for y in range(pos_y, pos_y + height):
			set_cell(x, y, cell)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up
	# Set the random seed
	randomize()
	# Adjust the camera
	$camera.current = true
	$camera.position = position
	$camera.zoom = cell_size / 5

	# Generation step
	var build_area = Vector2(width, height)
	
	# Generate zones for different areas
	var areas = [
	["service", af.array_sum(pseudodict_values(service_room_sizes)), service_room_sizes], 
	["social", af.array_sum(pseudodict_values(social_room_sizes)), social_room_sizes], 
	["private", af.array_sum(pseudodict_values(private_room_sizes)), private_room_sizes]]
	areas.sort_custom(PseudoDictionaryInverseSorter, "sort")
	var area_sizes = pseudodict_values(areas)
	area_sizes = sq.normalize_sizes(area_sizes, build_area)
	for c in range(0, len(area_sizes)):
		areas[c][1] = area_sizes[1]
	var rects = sq.squarify(area_sizes, Vector2(0, 0), build_area)
	for c in range(0, len(rects)):
		areas[c].append(rects[c])
		if areas[c][0] == "service":
			fill_area(rects[c], 2)
		elif areas[c][0] == "private":
			fill_area(rects[c], 3)
		else:
			fill_area(rects[c], 4)
		
	for box in rects:
		draw_box(box)
		
	# Generate the rooms
	for area in areas:
		for c in range(len(area[2]) - 1, 0, -1):
			if(area[2][c][1] == 0):
				area[2].remove(c)
		var area_values = pseudodict_values(area[2]) 
		area_values.sort()
		area_values.invert()
		var sizes = sq.normalize_sizes(area_values, area[3].size)
		var rooms = sq.squarify(sizes, area[3].position, area[3].size)
		for c in range(0, len(rooms)):
			area[2][c].append(rooms[c])
			draw_box(rooms[c])
			label_area(rooms[c], area[2][c][0])
	
	# Create final borders
	for x in range(0, width):
		set_cell(x, 0, 0)
		set_cell(x, height - 1, 0)
	for y in range(0, height):
		set_cell(0, y, 0)
		set_cell(width - 1, y, 0)