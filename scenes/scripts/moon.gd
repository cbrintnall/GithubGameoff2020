extends Sprite

signal do_pulse(energy)

export(float) var max_pulse
export(float) var min_pulse

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
	
	next_energy_emitted = rand_range(
		min_pulse, 
		max_pulse
	)
	
	timer.start()
