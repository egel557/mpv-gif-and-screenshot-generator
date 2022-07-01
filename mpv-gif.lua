-- Original by Ruin0x11
-- Ported to Windows by Scheliux, Dragoner7

-- Create animated GIFs with mpv
-- Requires ffmpeg.
-- Adapted from http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
-- Usage: "g" to set start frame, "G" to set end frame, "Ctrl+g" to create.

require 'mp.options'
local msg = require 'mp.msg'

local options = {
    dir = "C:/Program Files/mpv/gifs",
	screenshots_dir = "C:/Users/%USERNAME%/Desktop",
    gif_rez = 600,
	screenshot_rez = 640,
    fps = 15,
}

read_options(options, "gif")


local fps

-- Check for invalid fps values
-- Can you believe Lua doesn't have a proper ternary operator in the year of our lord 2020?
if options.fps ~= nil and options.fps >= 1 and options.fps < 30 then
    fps = options.fps
else
    fps = 15
end

-- Set this to the filters to pass into ffmpeg's -vf option.
-- filters="fps=24,scale=320:-1:flags=spline"
-- scale=iw*min(1\\,min(%s/iw\\,%s/ih)):-1
filters=string.format("fps=%s,setsar=1/1,scale=iw*min(1\\,min(%s/iw\\,%s/ih)):-1", fps, options.gif_rez / 9 * 16, options.gif_rez) --change spline to lanczos depending on preference

-- filters=string.format("fps=%s,scale='trunc(ih*dar/2)*2:trunc(ih/2)*2',setsar=1/1,scale=%s:-1:flags=spline", fps, options.gif_rez / 9 * 16) --change spline to lanczos depending on preference

-- Setup output directory
output_directory=string.gsub(options.dir, '\"', '')

start_time = -1
end_time = -1
-- palette="%TEMP%palette.png"
palette = os.getenv("TEMP") .. os.tmpname() .. "png"

-- The roundabout way has to be used due to a some weird
-- behavior with %TEMP% on the subtitles= parameter in ffmpeg
-- on Windows–it needs to be quadruple backslashed
-- subs = "C:/Users/%USERNAME%/AppData/Local/Temp/subs.srt"

function make_gif_with_subtitles()
    make_gif_internal(true)
end

function make_gif()
    make_gif_internal(false)
end    

function table_length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end


function extract_subtitles(empty)
	local temp = os.getenv("TEMP")
	local subs_path = temp .. os.tmpname() .. "srt"


	if empty then
		local text = '1\n00:00:01,000 --> 00:00:02,000\n<font size="22"></font>\n'
				
		local file = io.open(subs_path, "w")
		file:write(text)
		file:close()
		
		return subs_path
	end
	-- Determine currently active sub track

	local i = 0
	local tracks_count = mp.get_property_number("track-list/count")
	local subs_array = {}
	
	-- check for subtitle tracks

	while i < tracks_count do
		local type = mp.get_property(string.format("track-list/%d/type", i))
		local selected = mp.get_property(string.format("track-list/%d/selected", i))

		-- if it's a sub track, save it

		if type == "sub" then
			local length = table_length(subs_array)
			subs_array[length] = selected == "yes"
		end
		i = i + 1
	end

	if table_length(subs_array) > 0 then

		local correct_track = 0

		-- iterate through saved subtitle tracks until the correct one is found

		for index, is_selected in pairs(subs_array) do
			if (is_selected) then
				correct_track = index
			end
		end
				
		local path = mp.get_property("path", "")
		
		local args = string.format('ffmpeg -i "%s" -map "0:%s" "%s"', esc(path), correct_track + 2, subs_path)
		msg.debug(args)
		os.execute(args)
		
		return subs_path
	end
	
	return nil
end


function get_subtitle_track()
	-- Determine currently active sub track

	local i = 0
	local tracks_count = mp.get_property_number("track-list/count")
	local subs_array = {}
	
	-- check for subtitle tracks

	while i < tracks_count do
		local type = mp.get_property(string.format("track-list/%d/type", i))
		local selected = mp.get_property(string.format("track-list/%d/selected", i))

		-- if it's a sub track, save it

		if type == "sub" then
			local length = table_length(subs_array)
			subs_array[length] = selected == "yes"
		end
		i = i + 1
	end

	if table_length(subs_array) > 0 then

		local correct_track = 0

		-- iterate through saved subtitle tracks until the correct one is found

		for index, is_selected in pairs(subs_array) do
			if (is_selected) then
				correct_track = index
			end
		end

		return correct_track
	end
	return nil
end

-- shell escape
function esc(s)
	return string.gsub(s, '"', '"\\""')
end

function esc_for_sub(s)
	s = string.gsub(s, [[\]], [[/]])
	s = string.gsub(s, '"', '"\\""')
	s = string.gsub(s, ":", [[\\:]])
	s = string.gsub(s, "'", [[\\']])
	s = string.gsub(s, "%[", "\\%[")
	s = string.gsub(s, "%]", "\\%]")
	return s
end

function make_gif_internal(burn_subtitles)
    local start_time_l = start_time
    local end_time_l = end_time
    if start_time_l == -1 or end_time_l == -1 or start_time_l >= end_time_l then
        mp.osd_message("Invalid start/end time.")
        return
    end

    mp.osd_message("Creating GIF.")

    -- -- shell escape
    -- function esc(s)
        -- return string.gsub(s, '"', '"\\""')
    -- end

    -- function esc_for_sub(s)
        -- s = string.gsub(s, [[\]], [[/]])
        -- s = string.gsub(s, '"', '"\\""')
        -- s = string.gsub(s, ":", [[\\:]])
        -- s = string.gsub(s, "'", [[\\']])
		-- s = string.gsub(s, "%[", "\\%[")
		-- s = string.gsub(s, "%]", "\\%]")
        -- return s
    -- end

    local pathname = mp.get_property("path", "")
    local trim_filters = esc(filters)

    local position = start_time_l
    local duration = end_time_l - start_time_l
	local subs_path = extract_subtitles(not burn_subtitles)

	trim_filters = trim_filters .. string.format(",subtitles=%s", esc_for_sub(subs_path))


    -- first, create the palette
    args = string.format('ffmpeg -v warning -ss %s -t %s -i "%s" -vf "%s,palettegen" -y "%s"', position, duration, esc(pathname), esc(trim_filters), esc(palette))
    msg.debug(args)
    os.execute(args)
	

    -- then, make the gif
    local filename = mp.get_property("filename/no-ext")
    local file_path = output_directory .. "/" .. filename

    -- increment filename
    for i=0,999 do
        local fn = string.format('%s_%03d.gif',file_path,i)
        if not file_exists(fn) then
            gifname = fn
            break
        end
    end
    if not gifname then
        mp.osd_message('No available filenames!')
        return
    end

    local copyts = ""

    if burn_subtitles then
        copyts = "-copyts"
    end

    args = string.format('ffmpeg -v warning -ss %s %s -t %s -i "%s" -i "%s" -lavfi "%s [x]; [x][1:v] paletteuse" -y "%s"', position, copyts, duration, esc(pathname), esc(palette), esc(trim_filters), esc(gifname))
    os.execute(args)
	os.remove(palette)
	
	if subs_path ~= nil then
		os.remove(subs_path)
	end

    local ok, err, code = os.rename(gifname, gifname)
	if ok then
	    msg.info("GIF created: " .. gifname)
	    mp.osd_message("GIF created: " .. gifname)
	else
	    mp.osd_message("Error creating file, check CLI for more info.")
	end
end

function make_screenshots_internal(burn_subtitles)
	mp.osd_message("Taking screenshots...")
			
	local pathname = mp.get_property("path", "")
	local filename = mp.get_property("filename", "")
	-- local dir = pathname:match("(.*[/\\])")
	-- local dir = string.gsub(pathname, "\\" .. filename, "")
	local folder = string.format('%s_%s', filename, os.time(os.date("!*t")))
	local subs_path = extract_subtitles(not burn_subtitles)
	
	
	print(subs_path)
	-- options.gif_rez / 9 * 16, options.gif_rez
	local filters = string.format("-vf scale=iw*min(1\\,min(%s/iw\\,%s/ih)):-1", options.screenshot_rez / 9 * 16, options.screenshot_rez)
	
	filters = filters .. string.format(",subtitles=%s", esc_for_sub(subs_path))


	
	os.execute(string.format('cd %s & mkdir "%s"', options.screenshots_dir, folder))
	
	local fps = math.ceil(mp.get_property("estimated-vf-fps", ""))
	
	filters = filters .. string.format(",select='not(mod(n,%s*10))',setpts='N/(%s*TB)'", 24, 24)

	
	local args = string.format('ffmpeg -i "%s" %s -f image2 "%s/%s/%%03d.png"', esc(pathname), filters, options.screenshots_dir, esc(folder))
	-- args = string.format('ffmpeg -i "%s" -r 0.1 %s "%s/%s/%%03d.png"', esc(pathname), filters, options.screenshots_dir, esc(folder))
	msg.debug(args)
	print(args)
	os.execute(args)	
	
	if subs_path ~= nil then
		os.remove(subs_path)
	end

	
end

function make_screenshots()
	make_screenshots_internal(false)
end

function make_screenshots_with_subtitles()
	make_screenshots_internal(true)
end

function set_gif_start()
    start_time = mp.get_property_number("time-pos", -1)
    mp.osd_message("GIF Start: " .. start_time)
end

function set_gif_end()
    end_time = mp.get_property_number("time-pos", -1)
    mp.osd_message("GIF End: " .. end_time)
end

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end


function debug_func()
	print(mp.get_property("estimated-vf-fps", ""))
end


mp.add_key_binding("g", "set_gif_start", set_gif_start)
mp.add_key_binding("G", "set_gif_end", set_gif_end)
mp.add_key_binding("Ctrl+g", "make_gif", make_gif)
mp.add_key_binding("Ctrl+G", "make_gif_with_subtitles", make_gif_with_subtitles)
mp.add_key_binding("Alt+s", "make_screenshots", make_screenshots)
mp.add_key_binding("Alt+S", "make_screenshots_with_subtitles", make_screenshots_with_subtitles)

mp.add_key_binding("Tab", "debug_func", debug_func)
