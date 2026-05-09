local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end

_G.LobbySettings = _G.LobbySettings or {}
LobbySettings._path = ModPath
LobbySettings._data_path = SavePath .. 'lobby_settings.txt'
LobbySettings.settings = {
	infamy_permission = 0,
}

function LobbySettings:Save()
	local file = io.open(self._data_path, 'w+')
	if file then
		local settings = self.settings
		settings.infamy_permission = Global.game_settings.infamy_permission
		file:write(json.encode(settings))
		file:close()
	end
end

function LobbySettings:Load()
	local file = io.open(self._data_path, 'r')
	if file then
		for k, v in pairs(json.decode(file:read('*all')) or {}) do
			self.settings[k] = v
		end
		file:close()
	end
	Global.game_settings.infamy_permission = self.settings.infamy_permission or 0
end

Hooks:Add('LocalizationManagerPostInit', 'LocalizationManagerPostInit_LobbySettings', function(loc)
	local language_filename
	for _, filename in pairs(file.GetFiles(LobbySettings._path .. 'loc/')) do
		local str = filename:match('^(.*).txt$')
		if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
			language_filename = filename
			break
		end
	end
	if language_filename then
		loc:load_localization_file(LobbySettings._path .. 'loc/' .. language_filename)
	end
	loc:load_localization_file(LobbySettings._path .. 'loc/english.txt', false)
end)

Hooks:Add('MenuManagerInitialize', 'MenuManagerInitialize_LobbySettings', function(menu_manager)
	LobbySettings:Load()

	function MenuCallbackHandler:ls_choice_lobby_infamy_permission(item)
		Global.game_settings.infamy_permission = item:value()
		LobbySettings:Save()
	end

	function MenuCallbackHandler:ls_infamy_check(data)
		return data:value() <= managers.experience:current_rank()
	end
end)

local function _insertmenuitems(nodes)
	if Global.statistics_manager and Global.statistics_manager.play_time.minutes > 0 then
		LobbySettings:InsertInfamyLimiter(nodes.edit_game_settings)
	else
		DelayedCalls:Add('DelayedModLS_insertmenuitems', 1, function()
			_insertmenuitems(nodes)
		end)
	end
end

Hooks:Add('MenuManagerBuildCustomMenus', 'MenuManagerBuildCustomMenus_LobbySettings', function(menu_manager, nodes)
	if nodes.edit_game_settings then
		_insertmenuitems(nodes)
	end
end)

function LobbySettings:InsertInfamyLimiter(node)
	local data = { type = 'MenuItemMultiChoice' }
	for i = 0, 25 do
		table.insert(data, {
			_meta = 'option',
			localize = false,
			text_id = i,
			value = i,
			visible_callback = 'ls_infamy_check'
		})
	end

	local params = {
		name = 'ls_multi_infamy_permission',
		text_id = 'ls_menu_infamy_permission',
		help_id = 'ls_menu_infamy_permission_help',
		callback = 'ls_choice_lobby_infamy_permission',
		localize = true,
		visible_callback = 'is_multiplayer'
	}

	local item = node:create_item(data, params)
	item:set_value(Global.game_settings.infamy_permission)
	item:set_callback_handler(node.callback_handler)

	for k, v in pairs(node._items) do
		if v._parameters.name == 'lobby_reputation_permission' then
			table.insert(node._items, k, item)
			break
		end
	end

	return item
end