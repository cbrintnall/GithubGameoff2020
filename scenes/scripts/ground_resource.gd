extends Resource

class_name GroundResource

"""
this class is a resource for all things that periodically spawn on the ground

grass, rocks, etc
"""

# should be kv of item -> float where float is between 0 - 100
export(Dictionary) var drop_table = {}
export(AudioStream) var on_break
export(String) var ground_resource_name
export(Texture) var normal_texture
export(Texture) var hovered_texture
