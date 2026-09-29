extends Reference

# Optional compatibility bridge for six666-BrotatoOnline.
#
# Capybara remains fully functional when BrotatoOnline is not installed. During an
# online session, combat entities and persistent RunData changes must be created by
# the Host only; BrotatoOnline will replicate the resulting entities/state to Clients.

const ONLINE_API_GROUP = "brotato_online_api"
const ONLINE_MANAGER_PATH = "/root/ModLoader/six666-BrotatoOnline/BrotatoOnlineSteamLobbyManager"


static func should_run_authoritative_logic(context: Node) -> bool:
	if context == null or not is_instance_valid(context):
		return true

	var tree = context.get_tree()
	if tree == null or tree.root == null:
		return true

	# Prefer BrotatoOnline's public compatibility API.
	var online_apis = tree.get_nodes_in_group(ONLINE_API_GROUP)
	for api in online_apis:
		if api != null and is_instance_valid(api) and api.has_method("should_run_authoritative_logic"):
			return bool(api.should_run_authoritative_logic())

	# The API node can be unavailable for a few frames during scene startup. Fall
	# back to the session marker and Steam manager instead of accidentally allowing
	# a Client to enqueue Host-owned entities in that window.
	if not bool(tree.root.get_meta("brotato_online_session_active", false)):
		return true

	var steam_manager = tree.root.get_node_or_null(ONLINE_MANAGER_PATH)
	if steam_manager != null and is_instance_valid(steam_manager):
		if steam_manager.has_method("is_game_host"):
			return bool(steam_manager.is_game_host())
		if steam_manager.has_method("bo_api_is_host"):
			return bool(steam_manager.bo_api_is_host())

	# An active online session with no resolved role is not safe for authoritative
	# mutation. The Host will run it once its role is available; Clients must not.
	return false
