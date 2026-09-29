class_name CapybaraContentData
extends Resource

# Standard ItemService content.
export (Array, Resource) var characters = []
export (Array, Resource) var items = []
export (Array, Resource) var weapons = []
export (Array, Array, Resource) var weapons_characters = []
export (Array, Resource) var sets = []
export (Array, Resource) var challenges = []
export (Array, Resource) var upgrades = []
export (Array, Resource) var consumables = []
export (Array, Resource) var elites = []
export (Array, Resource) var bosses = []
export (Array, Resource) var difficulties = []

# ContentLoader does not normally register these ItemService resources.
export (Array, Resource) var entities = []
export (Array, Resource) var effects = []
export (Array, Resource) var stats = []
export (Array, Resource) var icons = []
export (Array, Resource) var backgrounds = []
export (Array, Color) var background_colors = []
export (Array, Resource) var title_screen_backgrounds = []
export (Array, StyleBox) var frames_element_level = []

# ZoneService content. A custom ZoneData.my_id must equal its final array index.
export (Array, Resource) var zones = []
export (Array, Resource) var groups_in_all_zones = []
export (Array, Resource) var endless_groups = []
export (Array, Resource) var endless_unit_groups = []
export (Array, Resource) var extra_enemy_scenes = []
export (Array, PackedScene) var bullets_hell = []

# EffectBehaviorService content.
export (Array, Resource) var scene_effect_behaviors = []
export (Array, Resource) var enemy_effect_behaviors = []
export (Array, Resource) var player_effect_behaviors = []

# Debug and optional presentation content.
export (Array, Resource) var debug_items = []
export (Array, Resource) var debug_weapons = []
export (Array, Resource) var debug_enemies = []
export (Array, Resource) var music_tracks = []
export (Array, Translation) var translations = []

# Optional runtime registries used by the base game and other content loaders.
export (Dictionary) var translation_keys_needing_operator = {}
export (Dictionary) var translation_keys_needing_percent = {}
export (Dictionary) var tracked_items = {}
export (Dictionary) var tracked_effects = {}
export (Array, String) var quiet_stat_keys = []
export (Array, String) var primary_stats_list = []
export (Array, String) var effect_keys_full_serialization = []
export (Array, String) var effect_keys_with_weapon_stats = []
