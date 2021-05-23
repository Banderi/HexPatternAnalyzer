#tool
extends Node2D

export(int, 1, 2000) var size_of_chunk = 200 setget update_size

#####

func update_size(_size, display = true):
	size_of_chunk = _size
	do_update(display)
	$HSlider.value = size_of_chunk

var all_chunks = []
var text_no_space = ""
func get_text(n):
	var start = size_of_chunk * n * 2
	var t = text_no_space.substr(start, size_of_chunk * 2)
	return t.replace("0", " ")

var size_of_text = 0
var howmany_chunks = 0
var num_of_text_fields = 100

func do_text_update():
	text_no_space = $main.text.replace(" ", "")
	size_of_text = text_no_space.length() / 2 # number of bytes
	do_update()

func do_update(display = true):

	if $main == null:
		return
	howmany_chunks = size_of_text / size_of_chunk

	print("updating: " + str(size_of_text) + " long, " + str(ceil(howmany_chunks)) + " " + str(size_of_chunk) + "-byte chunks")

	all_chunks = []
	var text_fields = $Node2D.get_children()
	for n in range(0, howmany_chunks):
		var txt = get_text(n).to_upper()
		all_chunks.push_back(txt)
		if display:
			if n < text_fields.size():
				var t = text_fields[n]
				t.visible = true
				t.text = txt
				t.modulate.a = max(1.0 / float(min(howmany_chunks, num_of_text_fields)), 0.01)
	if howmany_chunks < text_fields.size():
		for n in range(howmany_chunks, text_fields.size()):
			text_fields[n].visible = false

	var matching = 0
	var nonzero = 0
	var character_mapping = []

#	var results_to_display_text = ""

	var hex_digits_total = size_of_chunk * 2
	for i in range(0, hex_digits_total): # go through every character (hex digit) in the chunk...

#		if display:
#			results_to_display_text += "position " + str(i) + ":\n"

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
			if h == " ":
				nonz_score_at_index = 1.0 - (float(character_mapping[i][h]) / float(all_chunks.size()))
			else:
				matchin_score_at_index += float(pow(character_mapping[i][h], 2)) / float(character_mapping[i].size())

		matching += float(matchin_score_at_index) / float(hex_digits_total)
		nonzero += float(nonz_score_at_index) / float(hex_digits_total)

#	var coeff = 2.0
#	var corr = 1 / (coeff * pow(2.718282, -(size_of_chunk) * coeff))
	var corr = pow((size_of_chunk), 1.4)

	last_score[0] = size_of_chunk
	last_score[1] = ((matching) / 1000.0) * corr #pow((size_of_chunk), 1.4)
	last_score[2] = matching
	last_score[3] = nonzero

	if display:
		$Label.text = str(size_of_text) + " long, " + str(ceil(howmany_chunks)) + " " + str(size_of_chunk) + "-byte chunks"

		$Label2.text = "                CURRENT\n"
		$Label2.text += "Score:      " + str(last_score[1]) + "\n"
		$Label2.text += "Matches: " + str(last_score[2]) + "\n"
		$Label2.text += "Nonzero: " + str(last_score[3])

		$Label3.text = "BEST\n"
		$Label3.text += str(best_score[1]) + "\n"
		$Label3.text += str(best_score[2]) + "\n"
		$Label3.text += str(best_score[3])

#		$main2.text = results_to_display_text


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

func _ready():
	do_text_update()
