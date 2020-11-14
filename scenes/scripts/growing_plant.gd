extends Resource

class_name GrowingPlant

# the frames shown over time of this plant growing
export(SpriteFrames) var grow_frames
# should just be an item
export(Resource) var finished_plant
# amount it requires to become fully grown
export(float) var required_energy = 100
