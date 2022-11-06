--[[
metadata_osd. Version 0.4.1

Copyright (c) 2022 Vladimir Chren

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local opt = require 'mp.options'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- defaults
local options = {
    -- Master enable (on mpv start)
    enable_on_start = true,

    -- Enable for tracks
    enable_for_audio = true,
    enable_for_audio_withalbumart = true,
    enable_for_video = true,
    enable_for_image = false,

    -- Enable OSD-2
    enable_osd_2 = true,

    -- Autohide for tracks
    autohide_for_audio = false,
    autohide_for_audio_withalbumart = false,
    autohide_for_video = true,
    autohide_for_image = true,

    -- Autohide delay in seconds
    autohide_timeout_sec = 5,
    autohide_statusosd_timeout_sec = 5,

    -- Key bindings

    -- Master enable / disable switch key (killswitch)
    key_toggleenable = 'F1',

    -- OSD autohide enable / disable switch key
    key_toggleautohide = 'F5',

    -- Show / hide OSD-1 switch key
    --   - current autohide state applies
    key_toggleosd_1 = '',

    -- Show / hide OSD-2 switch key
    --   - current autohide state applies
    --   - OSD-2 needs to be enabled in 'enable_osd_2' config option
    --   - OSD-2 needs to have data
    key_toggleosd_2 = '',

    -- Reset user-toggled switches
    key_reset_usertoggled = 'F6',

    -- Show status OSD key
    key_showstatusosd = '',

    -- Show current chapter number in addition to the current playlist position.
    -- Can be useful also for audio files with internal chapters having a song
    -- per chapter.
    show_chapternumber = false,
    show_current_chapter_number = false, -- old option name, * will be removed *

    -- Show album's current track number (if not equal to the current playlist
    -- position); Playlists can be long, traversing multiple directories.
    -- This will show the album's current track number in addition
    -- to the (encompassing) playlist position (if present in metadata).
    show_albumtracknumber = false,
    show_current_albumtrack_number = false, -- old option name, * will be removed *
    show_albumtrack_number = false, -- old option name, * will be removed *

    osd_message_maxlength = 96,

    -- Styling options

    -- OSD-1 layout:
    -- ┌─────────────────┐
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 1     │
    -- ├─────────────────┤
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 2     │
    -- ├─────────────────┤
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 3     │
    -- ├─────────────────┤
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 4     │
    -- └─────────────────┘

    -- OSD-2 layout:
    -- ┌─────────────────┐
    -- │ padding top     │
    -- ├─────────────────┤
    -- │ TEXT AREA 1     │
    -- └─────────────────┘

    -- Style: Padding top (in number of half-a-lines)
    -- Values may be:
    --   0, 1, .. 40
    style_paddingtop_osd_1_textarea_1 = 1,
    style_paddingtop_osd_1_textarea_2 = 0,
    style_paddingtop_osd_1_textarea_3 = 2,
    style_paddingtop_osd_1_textarea_4 = 3,
    style_paddingtop_osd_2_textarea_1 = 3,

    -- Style: Alignment
    -- Values may be (multiple separated by semicolon ';'):
    --   left_justified (or) centered (or) right_justified ';' subtitle (or) midtitle (or) toptitle
    style_alignment_osd_1 = "left_justified;midtitle",
    style_alignment_osd_2 = "centered;midtitle",

    -- Style: Border width of the outline around the text
    -- Values may be:
    --   0, 1, 2, 3 or 4
    style_bord_osd_1 = 3,
    style_bord_osd_2 = 3,

    -- Style: Font style override
    -- Values may be (multiple separated by semicolon ';'):
    --   italic ';' bold
    style_fontstyle_osd_1_textarea_1 = "bold",
    style_fontstyle_osd_1_textarea_2 = "bold",
    style_fontstyle_osd_1_textarea_2_releasedate = "",
    style_fontstyle_osd_1_textarea_3 = "italic",
    style_fontstyle_osd_1_textarea_4 = "",
    style_fontstyle_osd_2_textarea_1 = "",

    -- Style: Shadow depth of the text
    -- Values may be:
    --   0, 1, 2, 3 or 4
    style_shad_osd_1_textarea_1 = 0,
    style_shad_osd_1_textarea_2 = 0,
    style_shad_osd_1_textarea_3 = 1,
    style_shad_osd_1_textarea_4 = 0,
    style_shad_osd_2_textarea_1 = 0,

    -- Style: Font scale (in percent)
    -- Values may be:
    --   10, 11, .. 400
    style_fsc_osd_1_textarea_1 = 100,
    style_fsc_osd_1_textarea_2 = 100,
    style_fsc_osd_1_textarea_3 = 100,
    style_fsc_osd_1_textarea_4 = 60,
    style_fsc_osd_2_textarea_1 = 100,

    -- Style: Distance between letters
    -- Values may be:
    --   0, 1, .. 40
    style_fsp_osd_1_textarea_1 = 0,
    style_fsp_osd_1_textarea_2 = 0,
    style_fsp_osd_1_textarea_3 = 10,
    style_fsp_osd_1_textarea_4 = 0,
    style_fsp_osd_2_textarea_1 = 0,
}

opt.read_options(options, "metadata-osd")   -- underscore character blends in better,
                                            -- keeping this for backward compat.;
                                            -- * will be removed *
opt.read_options(options)

local state = {
    SHOWING_OSD_1 = 1,
    SHOWING_OSD_2 = 2,
    OSD_HIDDEN = 3,
}

local mediatype = {
    UNKNOWN = "Unknown",
    AUDIO = "Audio",
    AUDIO_ALBUMART = "Audio with albumart",
    VIDEO = "Video",
    IMAGE = "Image",
}

local osd_enabled = false
local osd_autohide = false
local osd_enabled_usertoggled = false
local osd_autohide_usertoggled = false
local curr_mediatype = mediatype.UNKNOWN
local curr_state = state.OSD_HIDDEN
local osd_overlay_osd_1 = mp.create_osd_overlay("ass-events")
local osd_overlay_osd_2 = mp.create_osd_overlay("ass-events")
local osd_timer -- forward declaration
local charencode_utf8 = false
local ellipsis_str = "..."  -- could have been "\u{2026}" but unicode escaping doesn't
                            -- work on all platforms, as e.g. Debian Testing;
                            -- once supported, will be replaced.

-- String helper functions

local function utf8_nextcharoffs(u_b1, u_b2, u_b3, u_b4)
    local nextcharoffs = nil

    --[[
    The built-in Lua5.1 byte-oriented string functions are limited,
    for variable length encoded characters present in the UTF-8
    encoding standard, insufficient.

    Until LuaJIT has compile support for Lua5.3, coming with its own
    native UTF-8 string library, a custom implementation deems to be
    necessary.
    ]]

    --[[
    UTF-8 Byte Sequences: Unicode Version 15.0.0, Section 3.9, Table 3-7.
    The Unicode Consortium. The Unicode Standard, Version 15.0.0, (Mountain View, CA: The Unicode Consortium, 2022. ISBN 978-1-936213-32-0)
    https://www.unicode.org/versions/Unicode15.0.0/
    ]]

    -- U+0000..U+007F
    if type(u_b1) == "number"
    then
        if u_b1 >= 0x00 and u_b1 <= 0x7F
        then
            nextcharoffs = 1
        -- U+0080..U+07FF
        elseif u_b1 >= 0xC2 and u_b1 <= 0xDF
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    nextcharoffs = 2
                end
            end
        -- U+0800..U+0FFF
        elseif u_b1 == 0xE0
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0xA0 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+1000..U+CFFF
        elseif u_b1 >= 0xE1 and u_b1 <= 0xEC
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+D000..U+D7FF
        elseif u_b1 == 0xED
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0x9F
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+E000..U+FFFF
        elseif u_b1 >= 0xEE and u_b1 <= 0xEF
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            nextcharoffs = 3
                        end
                    end
                end
            end
        -- U+10000..U+3FFFF
        elseif u_b1 == 0xF0
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x90 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            if type(u_b4) == "number"
                            then
                                if u_b4 >= 0x80 and u_b4 <= 0xBF
                                then
                                    nextcharoffs = 4
                                end
                            end
                        end
                    end
                end
            end
        -- U+40000..U+FFFFF
        elseif u_b1 >= 0xF1 and u_b1 <= 0xF3
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0xBF
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            if type(u_b4) == "number"
                            then
                                if u_b4 >= 0x80 and u_b4 <= 0xBF
                                then
                                    nextcharoffs = 4
                                end
                            end
                        end
                    end
                end
            end
        -- U+100000..U+10FFFF
        elseif u_b1 == 0xF4
        then
            if type(u_b2) == "number"
            then
                if u_b2 >= 0x80 and u_b2 <= 0x8F
                then
                    if type(u_b3) == "number"
                    then
                        if u_b3 >= 0x80 and u_b3 <= 0xBF
                        then
                            if type(u_b4) == "number"
                            then
                                if u_b4 >= 0x80 and u_b4 <= 0xBF
                                then
                                    nextcharoffs = 4
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return nextcharoffs
end

local function str_isempty(arg)
    return type(arg) ~= "string" or string.len(arg) == 0
end

local function str_isnonempty(arg)
    return type(arg) == "string" and string.len(arg) > 0
end

local function str_trunc(str)
    local result = str
    local str_truncpos = options.osd_message_maxlength

    if str_isnonempty(str)
    then
        str = string.gsub(str, "[\r\n]", "")
        if str_truncpos > 0
        then
            if charencode_utf8
            then
                local str_bytepos = 1
                local str_charcount = 0
                local nextcharoffs = nil
                local u_b1, u_b2, u_b3, u_b4 = nil, nil, nil, nil

                repeat
                    u_b1, u_b2, u_b3, u_b4 =
                        string.byte(str, str_bytepos, str_bytepos + 4)
                    nextcharoffs =
                        utf8_nextcharoffs(
                            u_b1, u_b2, u_b3, u_b4)
                    if nextcharoffs
                    then
                        str_charcount = str_charcount + 1
                        str_bytepos = str_bytepos + nextcharoffs
                    end
                until nextcharoffs == nil or
                    str_charcount >= options.osd_message_maxlength

                if u_b1 == nil and nextcharoffs == nil -- reached end of string
                then
                    goto exit
                elseif u_b1 ~= nil and nextcharoffs == nil -- found invalid utf-8 char
                then
                    msg.debug("str_trunc(): found invalid UTF-8 character; falling back to byte-oriented string truncate.")
                elseif u_b1 ~= nil and nextcharoffs ~= nil -- string needs to be trunc-ed
                then
                    str_truncpos = str_bytepos - 1
                end
            end

            if string.len(str) > str_truncpos
            then
                result =
                    string.sub(str, 1, str_truncpos) ..
                    ellipsis_str
            end
        end
    end

    ::exit::
    return result
end

local function str_capture4digits(s)
    res = ""
    if str_isnonempty(s) then
        local _, _, s_match = string.find(s, '([%d][%d][%d][%d])')
        if s_match then
            res = s_match
        end
    end
    return res
end

local function bool2enabled_str(arg)
    local result = "Disabled"

    if type(arg) == "boolean" and arg then
        result = "Enabled"
    end

    return result
end

local function str_split_styleoption(styleopt_str)
    local styleopt_pass1 = nil
    local styleopt_pass2 = nil
    local res_t = {}

    if str_isnonempty(styleopt_str)
    then
        for styleopt_pass1 in string.gmatch(styleopt_str, '([^;]+)')
        do
            styleopt_pass2 =
                string.match(
                    styleopt_pass1, '^[%s%p]*(.-)[%s%p]*$')

            if str_isnonempty(styleopt_pass2)
            then
                msg.debug("str_split_styleoption(): found: " .. styleopt_pass2)
                res_t[styleopt_pass2] = true
            end
        end
    end

    return res_t
end

local function parse_styleoption_int_inrange(styleopt_int, range_min, range_max)
    local styleopt_int = tonumber(styleopt_int)
    local res = nil

    if styleopt_int
    then
        styleopt_int = math.floor(styleopt_int)

        if styleopt_int >= range_min and styleopt_int <= range_max
        then
            res = styleopt_int
        end
    end

    return res
end

local function parse_styleoption_alignment(styleopt_alignment)
    local ass_alignment_leftjustified = 1
    local ass_alignment_centered = 2
    local ass_alignment_rightjustified = 3
    local ass_alignment_subtitle = 0
    local ass_alignment_toptitle = 4
    local ass_alignment_midtitle = 8

    local opt_t =
        str_split_styleoption(
            styleopt_alignment)

    local alignment_justification =
        ass_alignment_centered

    if opt_t["left_justified"]
    then
        alignment_justification =
            ass_alignment_leftjustified
    elseif opt_t["centered"]
    then
        alignment_justification =
            ass_alignment_centered
    elseif opt_t["right_justified"]
    then
        alignment_justification =
            ass_alignment_rightjustified
    end

    local alignment_position =
        ass_alignment_midtitle

    if opt_t["subtitle"]
    then
        alignment_position =
            ass_alignment_subtitle
    elseif opt_t["toptitle"]
    then
        alignment_position =
            ass_alignment_toptitle
    elseif opt_t["midtitle"]
    then
        alignment_position =
            ass_alignment_midtitle
    end

    return
        "{\\a" ..
        tostring(alignment_justification + alignment_position) ..
        "}"
end

local function parse_styleoption_bord(styleopt_bord)
    local res_bord = 0
    local styleopt_bord =
        parse_styleoption_int_inrange(styleopt_bord, 0, 4)

    if styleopt_bord
    then
        res_bord = styleopt_bord
    end

    return
        "{\\bord" ..
        tostring(res_bord) ..
        "}"
end

local function parse_styleoption_paddingtop(styleopt_paddingtop)
    local res_paddingtop = 0
    local styleopt_paddingtop =
        parse_styleoption_int_inrange(styleopt_paddingtop, 0, 40)

    if styleopt_paddingtop
    then
        res_paddingtop = styleopt_paddingtop
    end

    return
        string.rep("\\N", res_paddingtop)
end

local function parse_styleoption_shad(styleopt_shad)
    local res_shad = 0
    local styleopt_shad =
        parse_styleoption_int_inrange(styleopt_shad, 0, 4)

    if styleopt_shad
    then
        res_shad = styleopt_shad
    end

    return
        "{\\shad" ..
        tostring(res_shad) ..
        "}"
end

local function parse_styleoption_fsc(styleopt_fsc)
    local res_fsc = 100
    local styleopt_fsc =
        parse_styleoption_int_inrange(styleopt_fsc, 10, 400)

    if styleopt_fsc
    then
        res_fsc = styleopt_fsc
    end

    return
        "{\\fscx" ..
        tostring(res_fsc) ..
        "}" ..
        "{\\fscy" ..
        tostring(res_fsc) ..
        "}"
end

local function parse_styleoption_fsp(styleopt_fsp)
    local res_fsp = 0
    local styleopt_fsp =
        parse_styleoption_int_inrange(styleopt_fsp, 0, 40)

    if styleopt_fsp
    then
        res_fsp = styleopt_fsp
    end

    return
        "{\\fsp" ..
        tostring(res_fsp) ..
        "}"
end

local function parse_styleoption_fontstyle(styleopt_fontstyle)
    local opt_t =
        str_split_styleoption(
            styleopt_fontstyle)
    local italic, bold = false, false

    if opt_t["italic"]
    then
        italic = true
    end

    if opt_t["bold"]
    then
        bold = true
    end

    return italic, bold
end

local function parse_style_options()
    local ass_style = {}

    ass_style.osd_1 = {}
    ass_style.osd_1.textarea_1 = {}
    ass_style.osd_1.textarea_2 = {}
    ass_style.osd_1.textarea_2_reldate = {}
    ass_style.osd_1.textarea_3 = {}
    ass_style.osd_1.textarea_4 = {}
    ass_style.osd_2 = {}
    ass_style.osd_2.textarea_1 = {}

    -- Style: Alignment
    ass_style.osd_1.alignment =
        parse_styleoption_alignment(
            options.style_alignment_osd_1)

    ass_style.osd_2.alignment =
        parse_styleoption_alignment(
            options.style_alignment_osd_2)

    -- Style: Border width of the outline around the text
    ass_style.osd_1.bord =
        parse_styleoption_bord(
            options.style_bord_osd_1)

    ass_style.osd_2.bord =
        parse_styleoption_bord(
            options.style_bord_osd_2)

    -- Style: Font style
    ass_style.osd_1.textarea_1.fontstyle = {}
    ass_style.osd_1.textarea_1.fontstyle.is_italic,
    ass_style.osd_1.textarea_1.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_1_textarea_1)

    ass_style.osd_1.textarea_2.fontstyle = {}
    ass_style.osd_1.textarea_2.fontstyle.is_italic,
    ass_style.osd_1.textarea_2.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_1_textarea_2)

    ass_style.osd_1.textarea_2_reldate.fontstyle = {}
    ass_style.osd_1.textarea_2_reldate.fontstyle.is_italic,
    ass_style.osd_1.textarea_2_reldate.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_1_textarea_2_releasedate)

    ass_style.osd_1.textarea_3.fontstyle = {}
    ass_style.osd_1.textarea_3.fontstyle.is_italic,
    ass_style.osd_1.textarea_3.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_1_textarea_3)

    ass_style.osd_1.textarea_4.fontstyle = {}
    ass_style.osd_1.textarea_4.fontstyle.is_italic,
    ass_style.osd_1.textarea_4.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_1_textarea_4)

    ass_style.osd_2.textarea_1.fontstyle = {}
    ass_style.osd_2.textarea_1.fontstyle.is_italic,
    ass_style.osd_2.textarea_1.fontstyle.is_bold =
        parse_styleoption_fontstyle(
            options.style_fontstyle_osd_2_textarea_1)

    -- Style: Padding top
    ass_style.osd_1.textarea_1.paddingtop =
        parse_styleoption_paddingtop(
            options.style_paddingtop_osd_1_textarea_1)

    ass_style.osd_1.textarea_2.paddingtop =
        parse_styleoption_paddingtop(
            options.style_paddingtop_osd_1_textarea_2)

    ass_style.osd_1.textarea_3.paddingtop =
        parse_styleoption_paddingtop(
            options.style_paddingtop_osd_1_textarea_3)

    ass_style.osd_1.textarea_4.paddingtop =
        parse_styleoption_paddingtop(
            options.style_paddingtop_osd_1_textarea_4)

    ass_style.osd_2.textarea_1.paddingtop =
        parse_styleoption_paddingtop(
            options.style_paddingtop_osd_2_textarea_1)

    -- Style: Shadow depth of the text
    ass_style.osd_1.textarea_1.shad =
        parse_styleoption_shad(
            options.style_shad_osd_1_textarea_1)

    ass_style.osd_1.textarea_2.shad =
        parse_styleoption_shad(
            options.style_shad_osd_1_textarea_2)

    ass_style.osd_1.textarea_2_reldate.shad =
        parse_styleoption_shad(
            nil)

    ass_style.osd_1.textarea_3.shad =
        parse_styleoption_shad(
            options.style_shad_osd_1_textarea_3)

    ass_style.osd_1.textarea_4.shad =
        parse_styleoption_shad(
            options.style_shad_osd_1_textarea_4)

    ass_style.osd_2.textarea_1.shad =
        parse_styleoption_shad(
            options.style_shad_osd_2_textarea_1)

    -- Style: Font scale in percent
    ass_style.osd_1.textarea_1.fsc =
        parse_styleoption_fsc(
            options.style_fsc_osd_1_textarea_1)

    ass_style.osd_1.textarea_2.fsc =
        parse_styleoption_fsc(
            options.style_fsc_osd_1_textarea_2)

    ass_style.osd_1.textarea_2_reldate.fsc =
        parse_styleoption_fsc(
            nil)

    ass_style.osd_1.textarea_3.fsc =
        parse_styleoption_fsc(
            options.style_fsc_osd_1_textarea_3)

    ass_style.osd_1.textarea_4.fsc =
        parse_styleoption_fsc(
            options.style_fsc_osd_1_textarea_4)

    ass_style.osd_2.textarea_1.fsc =
        parse_styleoption_fsc(
            options.style_fsc_osd_2_textarea_1)

    -- Style: Distance between letters
    ass_style.osd_1.textarea_1.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_1_textarea_1)

    ass_style.osd_1.textarea_2.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_1_textarea_2)

    ass_style.osd_1.textarea_2_reldate.fsp =
        parse_styleoption_fsp(
            nil)

    ass_style.osd_1.textarea_3.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_1_textarea_3)

    ass_style.osd_1.textarea_4.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_1_textarea_4)

    ass_style.osd_2.textarea_1.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_2_textarea_1)

    return ass_style
end

-- SSA/ASS helper functions
--   spec. url: http://www.tcax.org/docs/ass-specs.htm

local ass_tmpl_osd_1 = nil
local ass_tmpl_osd_2 = nil
local ass_tmpl_strid_textarea_1_str = "##TEXTAREA_1_STR##"
local ass_tmpl_strid_textarea_2_str = "##TEXTAREA_2_STR##"
local ass_tmpl_strid_textarea_2_reldate_str = "##TEXTAREA_2_RELDATE_STR##"
local ass_tmpl_strid_textarea_3_str = "##TEXTAREA_3_STR##"
local ass_tmpl_strid_textarea_4_str = "##TEXTAREA_4_STR##"

local function ass_styleoverride_fontstyle(italic, bold, str)
    res = ""

    if italic
    then
        res = res ..
            "{\\i1}"
    end

    if bold
    then
        res = res ..
            "{\\b1}"
    end

    res = res ..
        str

    if bold
    then
        res = res ..
            "{\\b0}"
    end

    if italic
    then
        res = res ..
            "{\\i0}"
    end

    return res
end

local function ass_newline()
    return "\\N"
end

local function ass_prepare_template_textarea(ass_style_textarea, textmsg_strid)
    res = nil

    if type(ass_style_textarea) == "table" and
        str_isnonempty(textmsg_strid)
    then
        res =
            ass_style_textarea.shad ..
            ass_style_textarea.fsc ..
            ass_style_textarea.fsp ..
            ass_styleoverride_fontstyle(
                ass_style_textarea.fontstyle.is_italic,
                ass_style_textarea.fontstyle.is_bold,
                textmsg_strid)
            -- tags are *always* opened, not resetting back to defaults...
            -- "{\\fsp0}" ..
            -- "{\\fscx100}" ..
            -- "{\\fscy100}" ..
            -- "{\\shad0}"
    end

    return res
end

local function ass_prepare_templates()
    local ass_style =
        parse_style_options()

    ass_tmpl_osd_1 =
        ass_style.osd_1.alignment ..
        ass_style.osd_1.bord ..

        ass_style.osd_1.textarea_1.paddingtop ..

        ass_prepare_template_textarea(
            ass_style.osd_1.textarea_1,
            ass_tmpl_strid_textarea_1_str) ..

        string.rep(ass_newline(), 1) ..
        ass_style.osd_1.textarea_2.paddingtop ..

        ass_prepare_template_textarea(
            ass_style.osd_1.textarea_2,
            ass_tmpl_strid_textarea_2_str) ..

        ass_prepare_template_textarea(
            ass_style.osd_1.textarea_2_reldate,
            ass_tmpl_strid_textarea_2_reldate_str) ..

        string.rep(ass_newline(), 1) ..
        ass_style.osd_1.textarea_3.paddingtop ..

        ass_prepare_template_textarea(
            ass_style.osd_1.textarea_3,
            ass_tmpl_strid_textarea_3_str) ..

        string.rep(ass_newline(), 1) ..
        ass_style.osd_1.textarea_4.paddingtop ..

        ass_prepare_template_textarea(
            ass_style.osd_1.textarea_4,
            ass_tmpl_strid_textarea_4_str)

    ass_tmpl_osd_2 =
        ass_style.osd_2.alignment ..
        ass_style.osd_2.bord ..

        ass_style.osd_2.textarea_1.paddingtop ..

        ass_prepare_template_textarea(
            ass_style.osd_2.textarea_1,
            ass_tmpl_strid_textarea_1_str)

    msg.debug(
        "ass_prepare_templates(): osd_1 template: " .. ass_tmpl_osd_1)
    msg.debug(
        "ass_prepare_templates(): osd_2 template: " .. ass_tmpl_osd_2)
end

-- OSD functions

local function show_statusosd()
    if osd_enabled then
        mp.osd_message(
            "Metadata OSD: Enabled " ..
            "(" .. options.key_toggleenable .. "), " ..
            "Autohide: " .. bool2enabled_str(osd_autohide) .. " " ..
            "(" .. options.key_toggleautohide .. ")",
            options.autohide_statusosd_timeout_sec
            )
    else
        mp.osd_message(
            "Metadata OSD: Disabled " ..
            "(" .. options.key_toggleenable .. ")",
            1 -- hide abruptly after one second,
              -- exiting ought to be quick
            )
    end
end

local function osd_has_data(osd_overlay)
    return str_isnonempty(osd_overlay.data)
end

local function show_osd_1()
    msg.debug("show_osd_1()")

    if osd_enabled then
        if osd_has_data(osd_overlay_osd_1) then
            osd_overlay_osd_2:remove()
            osd_overlay_osd_1:update()

            if osd_autohide then
                osd_timer:kill()
                osd_timer:resume()
            end

        curr_state = state.SHOWING_OSD_1
        end
    end
end

local function show_osd_2()
    msg.debug("show_osd_2()")

    if osd_enabled then
        if osd_has_data(osd_overlay_osd_2) then
            osd_overlay_osd_1:remove()
            osd_overlay_osd_2:update()

            if osd_autohide then
                osd_timer:kill()
                osd_timer:resume()
            end

        curr_state = state.SHOWING_OSD_2
        end
    end
end

local function hide_osd()
    msg.debug("hide_osd()")

    if osd_enabled then
        osd_overlay_osd_1:remove()
        osd_overlay_osd_2:remove()

        if osd_autohide then
            osd_timer:kill()
        end

        curr_state = state.OSD_HIDDEN
    end
end

local function toggle_osd_1()
    msg.debug("toggle_osd_1()")

    if osd_enabled then
        if curr_state == state.SHOWING_OSD_1 then
            hide_osd()
        else
            show_osd_1()
        end
    end
end

local function toggle_osd_2()
    msg.debug("toggle_osd_2()")

    if osd_enabled then
        if curr_state == state.SHOWING_OSD_2 then
            hide_osd()
        else
            show_osd_2()
        end
    end
end

local function osd_timeout_handler()
    if osd_enabled then
        if osd_autohide then
            if curr_state == state.SHOWING_OSD_1 then
                if osd_has_data(osd_overlay_osd_2) then
                    show_osd_2()
                else
                    hide_osd()
                end
            elseif curr_state == state.SHOWING_OSD_2 then
                hide_osd()
            end
        end
    end
end

local function autohide_resettimer()
    if osd_enabled then
        if osd_autohide then
            osd_timer:kill()
            osd_timer:resume()
        else
            osd_timer:kill()
            show_osd_1()
        end
    end
end

local function toggle_autohide()
    osd_autohide_usertoggled = true
    osd_autohide = not osd_autohide
    autohide_resettimer()
    show_statusosd()
end

local function reeval_osd_autohide()
    if not osd_autohide_usertoggled then
        osd_autohide = false

        if (curr_mediatype == mediatype.AUDIO and options.autohide_for_audio) or
           (curr_mediatype == mediatype.AUDIO_ALBUMART and options.autohide_for_audio_withalbumart) or
           (curr_mediatype == mediatype.VIDEO and options.autohide_for_video) or
           (curr_mediatype == mediatype.IMAGE and options.autohide_for_image)
        then
            osd_autohide = true
        end

        autohide_resettimer()
    end
end

local reeval_osd_enabled -- forward declaration

local function reset_usertoggled()
    msg.debug("reset_usertoggled()")
    osd_enabled_usertoggled = false
    osd_autohide_usertoggled = false
    reeval_osd_enabled()
    reeval_osd_autohide()
    show_statusosd()
end

local function on_metadata_change(metadata_key, metadata_val)
    msg.debug("on_metadata_change(): " ..
        tostring(metadata_key) ..
        ": " ..
        utils.to_string(metadata_val))

    --[[
    The incoming table with metadata can have all the possible letter
    capitalizations for table keys which are case sensitive in Lua ->
    properties are always querried via mp.get_property().
    ]]

    local prop_path           = mp.get_property_osd("path")
    local prop_elongatedpath  = mp.get_property_osd("working-directory") ..
        "/" ..
        prop_path
    local prop_streamfilename = mp.get_property_osd("stream-open-filename")
    local prop_fileformat     = mp.get_property_osd("file-format")
    local prop_mediatitle     = mp.get_property_osd("media-title")
    local prop_meta_track     = mp.get_property_osd("metadata/by-key/track")
    local prop_meta_title     = mp.get_property_osd("metadata/by-key/title")

    local prop_playlist_curr  = mp.get_property("playlist-pos-1")
    local prop_playlist_total = mp.get_property("playlist-count")
    prop_playlist_curr        = tonumber(prop_playlist_curr)
    prop_playlist_total       = tonumber(prop_playlist_total)

    local prop_chapter_curr   = mp.get_property("chapter")
    local prop_chapters_total = mp.get_property("chapters")
    prop_chapter_curr         = tonumber(prop_chapter_curr)
    prop_chapters_total       = tonumber(prop_chapters_total)

    local playing_file =
        (prop_fileformat ~= "hls") and -- not 'http live streaming'
        (prop_path == prop_streamfilename) -- not processed by yt-dlp/youtube-dl

    local osd_str = ass_tmpl_osd_1
    local textarea_1_str = nil
    local textarea_2_str = nil
    local textarea_2_reldate_str = nil
    local textarea_3_str = nil
    local textarea_4_str = nil

    -- OSD-1
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- └─────────────────┘
    if playing_file
    then
        -- meta: Artist
        textarea_1_str = mp.get_property_osd("metadata/by-key/artist")

        if str_isempty(textarea_1_str)
        then
            textarea_1_str = mp.get_property_osd("metadata/by-key/album_artist")

            if str_isempty(textarea_1_str)
            then
                textarea_1_str = mp.get_property_osd("metadata/by-key/composer")

                -- Foldername-Artist fallback
                if str_isempty(textarea_1_str)
                then
                    local folder_upup_pattern = ".*/(.*)/.*/.*"

                    if prop_elongatedpath:match(folder_upup_pattern)
                    then
                        textarea_1_str =
                            prop_elongatedpath:gsub(folder_upup_pattern, "%1")
                        textarea_1_str =
                            textarea_1_str:gsub("_", " ")
                    end
                end
            end
        end

    else -- playing from remote source
        -- meta: Uploader
        textarea_1_str = mp.get_property_osd("metadata/by-key/uploader")
    end

    osd_str = string.gsub(
        osd_str,
        ass_tmpl_strid_textarea_1_str,
        str_isnonempty(textarea_1_str) and
            str_trunc(textarea_1_str) or "",
        1)

    -- ┌─────────────────┐
    -- │ TEXT AREA 2     │
    -- └─────────────────┘
    if playing_file
    then
        -- meta: Album
        textarea_2_str = mp.get_property_osd("metadata/by-key/album")

        -- meta: Album release date
        local prop_meta_reldate = mp.get_property_osd("metadata/by-key/date")
        prop_meta_reldate = str_capture4digits(prop_meta_reldate)

        if str_isnonempty(prop_meta_reldate)
        then
            textarea_2_reldate_str = " (" .. prop_meta_reldate .. ")"
        end

        -- For audio files with internal chapters ...
        if prop_chapter_curr and
            prop_chapters_total and
            ( curr_mediatype == mediatype.AUDIO or
            curr_mediatype == mediatype.AUDIO_ALBUMART )
        then
            if str_isempty(textarea_2_str)
            then
                -- meta: Title
                --   contains _often_ album name, use it in a pinch.
                --   sometimes, this contains better data than 'album' property,
                --   but how would we know (switch it on a mouse click?)
                textarea_2_str = prop_meta_title
            end

            if str_isempty(textarea_2_reldate_str)
            then
                -- meta: Track
                --   contains _often_ release date, use it in a pinch.
                prop_meta_track = str_capture4digits(prop_meta_track)

                if str_isnonempty(prop_meta_track)
                then
                    textarea_2_reldate_str = " (" .. prop_meta_track .. ")"
                end
            end
        end

        -- Foldername-Album fallback
        if str_isempty(textarea_2_str)
        then
            local folder_up_pattern = ".*/(.*)/.*"

            if prop_elongatedpath:match(folder_up_pattern)
            then
                textarea_2_str =
                    prop_elongatedpath:gsub(folder_up_pattern, "%1")
                textarea_2_str =
                    textarea_2_str:gsub("_", " ")
            end
        end

    else -- playing from remote source
        -- could be filled with something useful in the future.
    end

    osd_str = string.gsub(
        osd_str,
        ass_tmpl_strid_textarea_2_str,
        str_isnonempty(textarea_2_str) and
            str_trunc(textarea_2_str) or "",
        1)

    osd_str = string.gsub(
        osd_str,
        ass_tmpl_strid_textarea_2_reldate_str,
        str_isnonempty(textarea_2_reldate_str) and
            str_trunc(textarea_2_reldate_str) or "",
        1)

    -- ┌─────────────────┐
    -- │ TEXT AREA 3     │
    -- └─────────────────┘
    if playing_file
    then
        -- For audio files with internal chapters ...
        if prop_chapter_curr and
            prop_chapters_total and
            ( curr_mediatype == mediatype.AUDIO or
            curr_mediatype == mediatype.AUDIO_ALBUMART )
        then
            -- meta: Chapter Title
            --   contains _usually_ song name
            textarea_3_str =
                mp.get_property("chapter-list/" .. tostring(prop_chapter_curr) .. "/title")

        -- meta: Title
        else
            -- meta: Title
            textarea_3_str = prop_meta_title
        end

        -- Filename fallback
        if str_isempty(textarea_3_str)
        then
            textarea_3_str = mp.get_property_osd("filename/no-ext")
            textarea_3_str = textarea_3_str:gsub("_", " ")
        end

    else -- playing from remote source
        -- meta: Media Title
        textarea_3_str = prop_mediatitle
    end

    osd_str = string.gsub(
        osd_str,
        ass_tmpl_strid_textarea_3_str,
        str_isnonempty(textarea_3_str) and
            str_trunc(textarea_3_str) or "",
        1)

    -- ┌─────────────────┐
    -- │ TEXT AREA 4     │
    -- └─────────────────┘
    -- meta: (Big) Playlist position
    if prop_playlist_curr and
        prop_playlist_total
    then
        textarea_4_str =
            tostring(prop_playlist_curr) ..
            "/" ..
            tostring(prop_playlist_total)

        -- For files with internal chapters ...
        -- meta: Chapter Number
        if prop_chapter_curr and
            prop_chapters_total
        then
            if ( options.show_chapternumber or
                options.show_current_chapter_number )
            then
                local chapternum_str = ""

                if curr_mediatype == mediatype.VIDEO
                then
                    chapternum_str = "Chapter: "
                end

                chapternum_str =
                    chapternum_str ..
                    tostring(prop_chapter_curr + 1) ..
                    "/" ..
                    tostring(prop_chapters_total)

                if prop_playlist_total ~= 1 and
                    ( prop_chapter_curr ~= prop_playlist_curr or
                    prop_chapters_total ~= prop_playlist_total )
                then
                    chapternum_str =
                        chapternum_str ..
                        ass_newline() ..
                        "[" ..
                        textarea_4_str ..
                        "]"
                end

                textarea_4_str = chapternum_str
            end

        -- meta: Track Number
        elseif ( options.show_albumtracknumber or
            options.show_current_albumtrack_number or
            options.show_albumtrack_number ) and
            ( curr_mediatype == mediatype.AUDIO or
            curr_mediatype == mediatype.AUDIO_ALBUMART ) and
            str_isnonempty(prop_meta_track)
        then
            local _, _, s_match = string.find(prop_meta_track, '^([%d]+)')
            if s_match
            then
                local tracknum = tonumber(s_match)
                if tracknum and
                    tracknum < 999 -- track number can contain release year,
                                    -- skip more-than-three-digit track numbers
                then
                    local tracknum_str = ""

                    if prop_playlist_total == 1
                    then
                        tracknum_str =
                            "Track: " ..
                            tracknum

                    elseif tracknum ~= prop_playlist_curr
                    then
                        tracknum_str =
                            "Track: " ..
                            tracknum ..
                            ass_newline() ..
                            "[" ..
                            textarea_4_str ..
                            "]"
                    end

                    if str_isnonempty(tracknum_str)
                    then
                        textarea_4_str = tracknum_str
                    end
                end
            end
        end
    end

    osd_str = string.gsub(
        osd_str,
        ass_tmpl_strid_textarea_4_str,
        str_isnonempty(textarea_4_str) and
            str_trunc(textarea_4_str) or "",
        1)

    osd_overlay_osd_1.data = osd_str

    -- OSD-2
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- └─────────────────┘
    -- meta: Chapter Title
    if options.enable_osd_2 and metadata_key == "chapter-metadata/title" and str_isnonempty(metadata_val) then
        osd_overlay_osd_2.data =
            string.gsub(
                ass_tmpl_osd_2,
                ass_tmpl_strid_textarea_1_str,
                str_trunc(metadata_val),
                1)
    end

    if metadata_key == "chapter-metadata/title" and (curr_state == state.SHOWING_OSD_2 or (osd_autohide and curr_state == state.OSD_HIDDEN)) then
        show_osd_2()
    else
        show_osd_1()
    end
end

local function master_osd_enable()
    msg.debug("master_osd_enable()")

    mp.add_key_binding(
        options.key_toggleosd_1,
        "toggleosd_1",
        toggle_osd_1)

    mp.add_key_binding(
        options.key_toggleosd_2,
        "toggleosd_2",
        toggle_osd_2)

    mp.add_key_binding(
        options.key_toggleautohide,
        "toggleautohide",
        toggle_autohide)

    mp.add_key_binding(
        options.key_reset_usertoggled,
        "reset_usertoggled",
        reset_usertoggled)

    mp.observe_property(
        "metadata",
        "native",
        on_metadata_change)

    mp.observe_property(
        "chapter-metadata/title",
        "string",
        on_metadata_change)

    osd_enabled = true
    show_osd_1()
end

local function master_osd_disable()
    msg.debug("master_osd_disable()")

    mp.remove_key_binding(
        "toggleautohide")
    mp.remove_key_binding(
        "toggleosd_1")
    mp.remove_key_binding(
        "toggleosd_2")
    mp.remove_key_binding(
        "reset_usertoggled")

    mp.unobserve_property(
        on_metadata_change)

    hide_osd()
    osd_enabled = false
end

local function toggle_enable()
    osd_enabled_usertoggled = true

    if osd_enabled then
        master_osd_disable()
    else
        master_osd_enable()
        reeval_osd_autohide()
    end

    show_statusosd()
end

reeval_osd_enabled = function()
    if not osd_enabled_usertoggled then
        osd_enabled_currstate = osd_enabled
        osd_enabled_newstate = false

        if options.enable_on_start then
            if (curr_mediatype == mediatype.AUDIO and options.enable_for_audio) or
               (curr_mediatype == mediatype.AUDIO_ALBUMART and options.enable_for_audio_withalbumart) or
               (curr_mediatype == mediatype.VIDEO and options.enable_for_video) or
               (curr_mediatype == mediatype.IMAGE and options.enable_for_image)
            then
                osd_enabled_newstate = true
            end
        end

        if osd_enabled_currstate and not osd_enabled_newstate then
            master_osd_disable()
        elseif not osd_enabled_currstate and osd_enabled_newstate then
            master_osd_enable()
        end
    end
end

local function on_tracklist_change(name, tracklist)
    msg.debug("on_tracklist_change()")

    curr_mediatype = mediatype.UNKNOWN

    if tracklist then
        msg.debug("on_tracklist_change(): num of tracks: " .. tostring(#tracklist))

        for _, track in ipairs(tracklist) do
            if not track.selected then
                goto continue
            end

            if track.type == "audio" and curr_mediatype == mediatype.UNKNOWN then
                msg.debug("on_tracklist_change(): audio track selected")
                curr_mediatype = mediatype.AUDIO
            elseif track.type == "video" then
                msg.debug("on_tracklist_change(): video track selected")
                curr_mediatype = mediatype.VIDEO
                if track.image then
                    msg.debug("on_tracklist_change(): video track is image")
                    curr_mediatype = mediatype.IMAGE
                    if track.albumart then
                        msg.debug("on_tracklist_change(): video track is albumart.")
                        curr_mediatype = mediatype.AUDIO_ALBUMART
                    end
                end
            end

            ::continue::
        end
    end

    msg.debug("on_tracklist_change(): current media type: " .. curr_mediatype)

    reeval_osd_enabled()
    reeval_osd_autohide()
end

ass_prepare_templates()

mp.add_key_binding(
    options.key_toggleenable,
    "toggleenable",
    toggle_enable)

mp.add_key_binding(
    options.key_showstatusosd,
    "showstatusosd",
    show_statusosd)

mp.observe_property(
    "track-list",
    "native",
    on_tracklist_change)

-- FIXME: Create but don't start the timer. How?
osd_timer = mp.add_timeout( -- create & start the timer
        options.autohide_timeout_sec,
        osd_timeout_handler
        )
osd_timer:kill() -- stop & reset the timer

if jit and jit.os == "Linux" then
    charencode_utf8 = true  -- UTF-8 is _assumed_,
                            -- not querried from the system
end
