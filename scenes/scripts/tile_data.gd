var default_energy_cap: int = 100
var energy_cap: int = 100
var tilled: bool
var current_energy: int
var distance_from_moon: int
var max_distance: int

func set_distance(moon_distance: int, max_distance: int):
	distance_from_moon = moon_distance

func add_energy(amt: int):
	current_energy = int(clamp(current_energy + amt, 0.0, energy_cap))
