MusicianLooper = LibStub("AceAddon-3.0"):NewAddon("MusicianLooper", "AceEvent-3.0")

local MODULE_NAME = "Looper"
Musician.AddModule(MODULE_NAME)

local isInitialized = false

local MusicianGetCommands
local MusicianButtonGetMenu

--- OnEnable
--
function MusicianLooper:OnEnable()
	Musician.Utils.Debug(MODULE_NAME, 'MusicianLooper', 'OnInitialize')

	-- Init bindings names
	_G.BINDING_NAME_MUSICIANLooperTOGGLE = MusicianLooper.Msg.COMMAND_LIVE_KEYBOARD

	-- Incompatible Musician version
	if MusicianLooper.MUSICIAN_API_VERSION > (Musician.API_VERSION or 0) or
		MusicianDialogTemplateMixin.DisableEscape == nil
	then
		Musician.Utils.Error(MusicianLooper.Msg.ERROR_MUSICIAN_VERSION_TOO_OLD)
		Musician.Utils.PrintError(MusicianLooper.Msg.ERROR_MUSICIAN_VERSION_TOO_OLD)
		return
	elseif MusicianLooper.MUSICIAN_API_VERSION < Musician.API_VERSION then
		Musician.Utils.Error(MusicianLooper.Msg.ERROR_MUSICIAN_LOOPER_VERSION_TOO_OLD)
		Musician.Utils.PrintError(MusicianLooper.Msg.ERROR_MUSICIAN_LOOPER_VERSION_TOO_OLD)
		return
	end

	-- Initialize main frame
	MusicianLooper.Frame.Init()

	-- Hook Musician functions
	MusicianButtonGetMenu = MusicianButton.GetMenu
	MusicianButton.GetMenu = MusicianLooper.GetMenu
	MusicianGetCommands = Musician.GetCommands
	Musician.GetCommands = MusicianLooper.GetCommands

	-- Initialization complete
	isInitialized = true
end

--- Indicates if the plugin is properly initialized
-- @return isInitialized (table)
function MusicianLooper.IsInitialized()
	return isInitialized
end

--- Initialize a locale and returns the initialized message table
-- @param languageCode (string) Short language code (ie 'en')
-- @param languageName (string) Locale name (ie "English")
-- @param localeCode (string) Long locale code (ie 'enUS')
-- @param[opt] ... (string) Additional locale codes
-- @return msg (table) Initialized message table
function MusicianLooper.InitLocale(languageCode, languageName, localeCode, ...)
	local localeCodes = { localeCode, ... }

	-- Set English (en) as base locale
	local baseLocale = languageCode == 'en' and MusicianLooper.LocaleBase or MusicianLooper.Locale.en

	-- Init table
	local msg = Musician.Utils.DeepCopy(baseLocale)
	MusicianLooper.Locale[languageCode] = msg
	msg.LOCALE_NAME = languageName
	msg.LOCALE_CODES = localeCodes

	-- Set English (en) as the current language by default
	if languageCode == 'en' then
		MusicianLooper.Msg = msg
	else
		-- Set localized messages
		for _, locale in pairs(localeCodes) do
			if GetLocale() == locale then
				MusicianLooper.Msg = msg
				break
			end
		end
	end

	return msg
end

--- Return main menu elements
-- @return menu (table)
function MusicianLooper.GetMenu()
	local menu = MusicianButtonGetMenu()

	-- Show easy keyboard
	for index, row in pairs(menu) do
		-- Insert before the standard "Options" section
		if row.text == Musician.Msg.MENU_OPTIONS then
			table.insert(menu, index, {
				notCheckable = true,
				text = MusicianLooper.Msg.MENU_OPEN_LOOPER,
				func = function()
					MusicianLooperFrame:Show()
				end
			})
			return menu
		end
	end

	return menu
end

--- Get command definitions
-- @return commands (table)
function MusicianLooper.GetCommands()
	local commands = MusicianGetCommands()

	for index, command in pairs(commands) do
		if command.text == Musician.Msg.COMMAND_LIVE_KEYBOARD then
			table.insert(commands, index + 1, {
				command = { "loop", "looper" },
				text = MusicianLooper.Msg.COMMAND_OPEN_LOOPER,
				func = function()
					MusicianLooperFrame:Show()
				end
			})
			break
		end
	end

	return commands
end
