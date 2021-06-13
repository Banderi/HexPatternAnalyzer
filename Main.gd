#tool
extends Node2D

export(int, 1, 2000) var size_of_chunk = 200 setget update_size

#####

var update_score_on_text_change = true
func update_autofit_option(check):
	update_score_on_text_change = check
	save_setting("update_score_on_text_change", update_score_on_text_change)

var replace_zeroes_with = "."
func update_zeroes_replace(c):
	if c == " ":
		c = " "
	if c == "":
		$LineEdit.text = replace_zeroes_with
		return
	replace_zeroes_with = c
	save_setting("replace_zeroes_with", replace_zeroes_with)
	display_update()
	$LineEdit.select_all()
func zeroes_replace_focused():
	$LineEdit.text = ""
func zeroes_replace_unfocused():
	$LineEdit.text = replace_zeroes_with

func update_size(_size, display = true):
	size_of_chunk = _size
	full_update(display)
	$HSlider.value = size_of_chunk

var all_chunks = []
var text_no_empty_bytes = ""
var text_no_space = ""
func get_text(n):
	var start = size_of_chunk * n * 2
	var t = text_no_space.substr(start, size_of_chunk * 2)
	return t.to_upper()

var size_of_text = 0
var howmany_chunks = 0
var num_of_text_fields = 100

func do_text_update():
	text_no_empty_bytes = $main.text.replace("00", "__")
	text_no_space = text_no_empty_bytes.replace(" ", "")
	size_of_text = text_no_space.length() / 2 # number of bytes
	if update_score_on_text_change:
		find_best_fit()
	else:
		full_update()

func display_update():
	var text_fields = $Node2D.get_children()
	for n in range(0, howmany_chunks):
		var txt = get_text(n)
		if n < text_fields.size():
			var t = text_fields[n]
			t.visible = true
			if replace_zeroes_with != "_":
				t.text = txt.replace("_", replace_zeroes_with)
			else:
				t.text = txt
			t.modulate.a = max(1.0 / float(min(howmany_chunks, num_of_text_fields)), 0.01)
	if howmany_chunks < text_fields.size():
		for n in range(howmany_chunks, text_fields.size()):
			text_fields[n].visible = false

func full_update(display = true):
	if $main == null:
		return
	howmany_chunks = size_of_text / size_of_chunk

#	print("updating: " + str(size_of_text) + " long, " + str(ceil(howmany_chunks)) + " " + str(size_of_chunk) + "-byte chunks")

	all_chunks = []
	for n in range(0, howmany_chunks):
		all_chunks.push_back(get_text(n))

	var matching = 0
	var nonzero = 0
	var character_mapping = []

	var hex_digits_total = size_of_chunk * 2
	for i in range(0, hex_digits_total): # go through every character (hex digit) in the chunk...

		# count up the matches for this index across all the chunk cycles
		character_mapping.push_back({})
		for chunk_string in all_chunks:
			var halfbyte = chunk_string.substr(i, 1)
			if !character_mapping[i].has(halfbyte):
				character_mapping[i][halfbyte] = 1
			character_mapping[i][halfbyte] += 1

		var matchin_score_at_index = 0
		var nonz_score_at_index = 0

		# sum up scores at every index...
		for h in character_mapping[i]:

			# score (0-1) of "how many characters were not zero"
			if h == " " || h == "_":
				nonz_score_at_index = 1.0 - (float(character_mapping[i][h]) / float(all_chunks.size()))
			else:
				matchin_score_at_index += float(pow(character_mapping[i][h], 2)) / float(character_mapping[i].size())

		matching += float(matchin_score_at_index) / float(hex_digits_total)
		nonzero += float(nonz_score_at_index) / float(hex_digits_total)

	var corr = pow((size_of_chunk), 1.4)

	last_score[0] = size_of_chunk
	last_score[1] = ((matching) / 1000.0) * corr #pow((size_of_chunk), 1.4)
	last_score[2] = matching
	last_score[3] = nonzero

	if display:
		display_update()
		$Label.text = str(size_of_text) + " long, " + str(ceil(howmany_chunks)) + " " + str(size_of_chunk) + "-byte chunks"

		$Control/Label2.text = "                CURRENT\n"
		$Control/Label2.text += "Score:      " + str(last_score[1]) + "\n"
		$Control/Label2.text += "Matches: " + str(last_score[2]) + "\n"
		$Control/Label2.text += "Nonzero: " + str(last_score[3])

		$Control/Label3.text = "BEST\n"
		$Control/Label3.text += str(best_score[1]) + "\n"
		$Control/Label3.text += str(best_score[2]) + "\n"
		$Control/Label3.text += str(best_score[3])


var last_score = [1,0,0,0]
var best_score = [1,0,0,0]
func find_best_fit():
	best_score = [1,0,0,0]

	# find divisors!
	var divisors = []
	for d in range(4, sqrt(size_of_text)):
		if size_of_text % d == 0:
			divisors.push_front(d)
			divisors.push_front(size_of_text / d)

	# find best score!
	for d in divisors:
		if d < 600:
			update_size(d, false)
		if last_score[1] > best_score[1]:
			best_score = last_score.duplicate()

	# display the best!
	update_size(best_score[0])

###

var config = ConfigFile.new()
func get_setting(setting, default):
	return config.get_value("settings", setting, default)
func save_setting(setting, value):
	config.set_value("settings", setting, value)
	config.save("user://settings.cfg")

func _ready():
	$BG/dummy.free()
	$main.text = ""

	var err = config.load("user://settings.cfg")
	if err:
		print(err)
	replace_zeroes_with = get_setting("replace_zeroes_with", ".")
	update_score_on_text_change = get_setting("update_score_on_text_change", true)

	$LineEdit.text = replace_zeroes_with
	do_text_update()
