--- Looper frame
-- @module MusicianLooper.Frame

MusicianLooper.Frame = LibStub("AceAddon-3.0"):NewAddon("MusicianLooper.Frame", "AceEvent-3.0")

local MODULE_NAME = "LooperFrame"
Musician.AddModule(MODULE_NAME)

local NOTE = Musician.Song.Indexes.NOTE

local isAltDown = false
local lastAltDown = 0
local isDoublePress = false
local isLongPress = false

local loopId = 0
local recordStartTime
local isRecording = false
local isPlaying = false
local loopingSong

local layerInstruments = {}

--- Initialize looper frame
--
function MusicianLooper.Frame.Init()
	MusicianLooperFrame:SetClampedToScreen(true)
	Musician.EnableHyperlinks(MusicianLooperFrame)
	MusicianLooperFrame:SetScript("OnUpdate", MusicianLooper.Frame.OnUpdate)
	MusicianLooper.Frame:RegisterMessage(Musician.Events.LiveNoteOn, MusicianLooper.Frame.OnLiveNoteOn)
	MusicianLooper.Frame:RegisterMessage(Musician.Events.LiveNoteOff, MusicianLooper.Frame.OnLiveNoteOff)
	MusicianLooper.Frame:RegisterMessage(Musician.Events.NoteOn, MusicianLooper.Frame.OnNoteOn)
	MusicianLooper.Frame:RegisterMessage(Musician.Events.NoteOff, MusicianLooper.Frame.OnNoteOff)
	MusicianLooper.Frame:RegisterMessage(Musician.Events.SongStop, MusicianLooper.Frame.OnSongStop)
end

--- OnUpdate handler: Implements ALT pedal key
--
function MusicianLooper.Frame.OnUpdate()
	if isAltDown ~= IsAltKeyDown() then
		isAltDown = IsAltKeyDown()
		if isAltDown then
			local now = debugprofilestop()
			isDoublePress = now - lastAltDown <= MusicianLooper.DOUBLE_PRESS_RATE
			lastAltDown = now
		else
			isLongPress = false
		end
		MusicianLooper.Frame.OnPedal(isAltDown, isDoublePress)
	end

	if isAltDown and not isLongPress and debugprofilestop() - lastAltDown > MusicianLooper.LONG_PRESS_DELAY then
		isLongPress = true
		MusicianLooper.Frame.OnLongPress()
	end
end

--- Pedal press handler
--
function MusicianLooper.Frame.OnPedal(down, double)
	if not double then
		if down and not isPlaying and not isRecording then
			-- Start recording (initial recording that will determine the song length)
			print("REC")
			MusicianLooper.Frame.Record()
		elseif down and isRecording then
			-- Play
			print("PLAY")
			MusicianLooper.Frame.Play()
		elseif down and isPlaying then
			-- Dub recording
			print("DUB")
			MusicianLooper.Frame.Record()
		end
	elseif down and double then
		print("STOP")
		MusicianLooper.Frame.Stop()
	end
end

--- Pedal long press handler
--
function MusicianLooper.Frame.OnLongPress()
	-- Undo / redo last section
	-- Only possible in PLAY mode
	if isRecording and isPlaying then -- Pressing the pedal down just turned on DUB mode
		print("UNDO / REDO")
		-- TODO: Toggle mute the latest recorded tracks
	end
end

--- Stop and erase the current loop
--
function MusicianLooper.Frame.Reset()
	isRecording = false
	isPlaying = false
	loopId = 0
	if loopingSong then
		loopingSong:Stop()
		loopingSong:Wipe()
	end
	loopingSong = nil
end

--- Start playing the current loop
--
function MusicianLooper.Frame.Play()
	if not loopingSong then return end

	-- Update song bounds if ending the first recording
	if isRecording and not isPlaying then
		loopingSong.cropTo = GetTime() - recordStartTime
		loopingSong.duration = loopingSong.cropTo
	end

	isRecording = false
	isPlaying = true
	if not loopingSong:IsPlaying() then
		loopId = 1
		loopingSong:Play()
	end
end

--- Start recording a new loop or dubbing new notes into the current one
--
function MusicianLooper.Frame.Record()
	if not loopingSong then
		-- Create loop song
		loopingSong = Musician.Song.create()
		loopingSong.loopTrackIndexes = {}
	end
	isRecording = true
	recordStartTime = GetTime()
end

--- Stop the current loop
--
function MusicianLooper.Frame.Stop()
	if not loopingSong then return end
	isRecording = false
	isPlaying = false
	loopingSong:Stop()
	MusicianLooper.Frame.Reset() -- TODO: Remove and add a dedicated button in the UI
end

--- OnSongStop handler: Plays the looping song when it ends
-- @param event (string)
-- @param song (Musician.Song)
function MusicianLooper.Frame.OnSongStop(event, song)
	-- Loop the looping song being played
	if song == loopingSong and isPlaying then
		-- Unmute all muted tracks
		for _, track in pairs(song.tracks) do
			if track.muted then
				song:SetTrackMuted(track, false)
			end
		end
		song:Play()
		-- Increment loop ID when recording
		if isRecording then
			loopId = loopId + 1
		end
	end
end

--- Send live note event from the looped song
-- @param noteOn (boolean) Note on/off
-- @param song (Musician.Song)
-- @param track (table) Track object of the song
-- @param key (number) MIDI key of the note
local function sendLiveNote(noteOn, song, track, key)
	if song ~= loopingSong then return end
	Musician.Live.InsertNote(noteOn, key, track.layer, track.instrument)
end

--- OnNoteOn handler: Send live note on event from the looped song
-- @param event (string)
-- @param song (Musician.Song)
-- @param track (table) Track object of the song
-- @param key (number) MIDI key of the note
function MusicianLooper.Frame.OnNoteOn(event, song, track, key)
	sendLiveNote(true, song, track, key)
end

--- OnNoteOff handler: Send live note off event from the looped song
-- @param event (string)
-- @param song (Musician.Song)
-- @param track (table) Track object of the song
-- @param key (number) MIDI key of the note
function MusicianLooper.Frame.OnNoteOff(event, song, track, key)
	sendLiveNote(false, song, track, key)
end

--- OnLiveNoteOn handler: Record note on event into the looping song
-- @param event (string)
-- @param key (number)
-- @param layer (number)
-- @param instrumentData (table)
function MusicianLooper.Frame.OnLiveNoteOn(event, key, layer, instrumentData)
	if not instrumentData then return end
	local instrument = instrumentData.midi
	layerInstruments[layer] = instrumentData.midi
	MusicianLooper.Frame.InsertNote(true, key, layer, instrument)
end

--- OnLiveNoteOff handler: Record note off event into the looping song
-- @param event (string)
-- @param key (number)
-- @param layer (number)
function MusicianLooper.Frame.OnLiveNoteOff(event, key, layer)
	local instrument = layerInstruments[layer]
	MusicianLooper.Frame.InsertNote(false, key, layer, instrument)
end

--- Get the looping song track for the given layer and instrument.
--- The track is created if it doesn't exist.
-- @param song (Musician.Song)
-- @param layer (int)
-- @param instrument (int)
-- @return track (table)
local function getLoopTrack(song, layer, instrument)
	local trackId = loopId .. '-' .. layer .. '-' .. instrument
	local trackIndex = song.loopTrackIndexes[trackId]

	-- Existing track
	if trackIndex ~= nil then
		return song.tracks[trackIndex]
	end

	-- Create new track
	trackIndex = #song.tracks + 1
	local track = {
		index = trackIndex,
		layer = layer,
		loopId = loopId,
		midiInstrument = instrument,
		instrument = instrument,
		notes = {},
		playIndex = 1,
		muted = false,
		solo = false,
		audible = true,
		transpose = 0,
		notesOn = {},
		polyphony = 0
	}

	table.insert(song.tracks, track)
	song.loopTrackIndexes[trackId] = trackIndex
	song:SetTrackMuted(track, loopId ~= 0) -- Mute track to prevent notes in the current loop from being played back

	return track
end

--- Insert live note event into the looping song when recording
-- @param noteOn (boolean) Note on/off
-- @param key (int) MIDI key index
-- @param layer (int)
-- @param instrument (int)
function MusicianLooper.Frame.InsertNote(noteOn, key, layer, instrument)
	if not isRecording then
		return
	end

	-- Key is out of range
	if key < Musician.MIN_KEY or key > Musician.MAX_KEY then return end

	-- Register note activity
	Musician.Utils.Debug(MODULE_NAME, 'InsertNote', noteOn, key, layer, instrument)

	-- Insert note in track
	local track = getLoopTrack(loopingSong, layer, instrument)
	local noteTime = isPlaying and loopingSong.cursor or (GetTime() - recordStartTime)

	table.insert(track.notes, {
		[NOTE.ON] = noteOn,
		[NOTE.KEY] = key,
		[NOTE.TIME] = noteTime
	})
end
