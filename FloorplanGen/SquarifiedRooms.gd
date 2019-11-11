extends TileMap

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

export(int) var width = 10
export(int) var height = 10
export(int) var threshold = 50
export(int) var min_area = 5

export(Array, Array) var service_room_sizes = [["kitchen", 2], ["pantry", 0], ["laundry", 1]]
export(Array, Array) var social_room_sizes = [["living", 5], ["dining", 0], ["toilet", 0]]
export(Array, Array) var private_room_sizes = [["bedroom", 4], ["master", 0], ["bathroom", 2], ["secondary", 0]]

func array_slice(array, bottom, top):
	var out = []
	for c in range(bottom, top):
		out.append(array[c])
	return out

func array_sum(array):
	var sum = 0
	for i in array:
		sum += i
	return sum
	
func array_max(array):
	var max_val = array[0]
	for i in array:
		max_val = max(max_val, i)
		
	return max_val
	
func leftoverrow(sizes, origin, size):
	var covered_area = array_sum(sizes)
	var width = covered_area / size.y
	var leftover_x = origin.x + width
	var leftover_y = origin.y
	var leftover_dx = size.x - width
	var leftover_dy = size.y
	return Rect2(leftover_x, leftover_y, leftover_dx, leftover_dy)

func leftovercol(sizes, origin, size):
	var covered_area = array_sum(sizes)
	var height = covered_area / size.x
	var leftover_x = origin.x
	var leftover_y = origin.y + height
	var leftover_dx = size.x
	var leftover_dy = size.y - height
	return Rect2(leftover_x, leftover_y, leftover_dx, leftover_dy)


func leftover(sizes, origin, size):
	if size.x >= size.y:
		return leftoverrow(sizes, origin, size)
	return leftovercol(sizes, origin, size)


func normalize_sizes(sizes, size):
	var total_size = array_sum(sizes)
	var total_area = size.x * size.y
	for c in range(0, len(sizes)):
		sizes[c] = sizes[c] * total_area / total_size
	return sizes

func worst_ratio(sizes, origin, size):
	var maxes = []
	var layouts = layout(sizes, origin, size)
	for rect in layouts:
		maxes.append(max(rect.size.x / rect.size.y, rect.size.y / rect.size.x))
	return array_max(maxes)


func layoutrow(sizes, origin, size):
	var covered_area = array_sum(sizes)
	var width = covered_area / size.y
	var rects = []
	for size in sizes:
		rects.append(Rect2(origin.x, origin.y, width, size / width))
		origin.y += size / width
	return rects


func layoutcol(sizes, origin, size):
	var covered_area = array_sum(sizes)
	var height = covered_area / size.x
	var rects = []
	for size in sizes:
		rects.append(Rect2(origin.x, origin.y, size / height, height))
		origin.x += size / width
	return rects

func layout(sizes, origin, size):
	if size.x >= size.y:
		return layoutrow(sizes, origin, size)
	return layoutcol(sizes, origin, size)

func squarify(sizes, origin, size):
	if len(sizes) == 0:
		return []
	if len(sizes) == 1:
		return layout(sizes, origin, size)

	var i = 1
	while i < len(sizes) and worst_ratio(array_slice(sizes, 0, i), origin, size) >= worst_ratio(array_slice(sizes, 0, i + 1), origin, size):
		i += 1
	var current = array_slice(sizes, 0, i)
	var remaining = array_slice(sizes, i, len(sizes))

	var leftovers = leftover(current, origin, size)
	return layout(current, origin, size) + squarify(remaining, leftovers.position, leftovers.size)

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
	$camera.position = Vector2(cell_size.x * width / 2, cell_size.y * height / 2)
	$camera.zoom = cell_size / 1.5
	# Fill the tilemap
	for x in range(0, width):
		for y in range(0, height):
			set_cell(x, y, 1)
		
	# Generation step
	var build_area = Vector2(width, height)
	
	# Generate zones for different areas
	var areas = [
	["service", array_sum(pseudodict_values(service_room_sizes)), service_room_sizes], 
	["social", array_sum(pseudodict_values(social_room_sizes)), social_room_sizes], 
	["private", array_sum(pseudodict_values(private_room_sizes)), private_room_sizes]]
	areas.sort_custom(PseudoDictionaryInverseSorter, "sort")
	var area_sizes = pseudodict_values(areas)
	area_sizes = normalize_sizes(area_sizes, build_area)
	for c in range(0, len(area_sizes)):
		areas[c][1] = area_sizes[1]
	var rects = squarify(area_sizes, Vector2(0, 0), build_area)
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
		var sizes = normalize_sizes(area_values, area[3].size)
		var rooms = squarify(sizes, area[3].position, area[3].size)
		for c in range(0, len(rooms)):
			area[2][c].append(rooms[c])
			draw_box(rooms[c])
	
	# Create final borders
	for x in range(0, width):
		set_cell(x, 0, 0)
		set_cell(x, height - 1, 0)
	for y in range(0, height):
		set_cell(0, y, 0)
		set_cell(width - 1, y, 0)