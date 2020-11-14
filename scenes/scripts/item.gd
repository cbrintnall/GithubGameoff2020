extends Resource

class_name Item

# the name for this item
export(String) var item_name
# the texture for this item
export(Texture) var texture
# if not null, this is what is planted when used on tilled land
export(Resource) var plant
# how much this sells for
export(float) var value
