max_line_length = false

exclude_files = {
}

ignore = {
	-- Ignore global writes/accesses/mutations on anything prefixed with "Musician".
	-- This is the standard prefix for all of our global frame names and mixins.
	"11./^Musician",

	-- Ignore unused self. This would popup for Mixins and Objects
	"212/self",

	-- Ignore unused event. This would popup for event handlers
	"212/event",

	-- Ignore Live play handler variables.
}

globals = {
	"Musician",
	"MusicianLooper",

	-- Globals

	-- AddOn Overrides
}

read_globals = {
	-- Libraries
	"LibStub",

	-- 3rd party add-ons
}

std = "lua51+wow"

stds.wow = {
	-- Globals that we mutate.
	globals = {
	},

	-- Globals that we access.
	read_globals = {
		-- Lua function aliases and extensions

		-- Global Functions
		"tAppendAll",
		"debugprofilestop",
		"GetLocale",
		"IsAltKeyDown",
		"GetTime",

		-- Global Mixins and UI Objects

		-- Global Constants

	},
}
