extends Sprite

signal do_pulse(energy)

onready var timer: Timer = get_node("Timer")

var max_distance_in_tiles = 5
var next_energy_emitted := 100

func _ready():
	timer.connect("timeout", self, "_pulse")
	
	# do first pulse
	_pulse()

func _pulse():
	var amt_energy = int(ceil(next_energy_emitted))
	
	emit_signal("do_pulse", amt_energy)
	
	print("Energy emitted: %d" % amt_energy)
	
	next_energy_emitted = rand_range(75, 125)
	
	timer.start()
