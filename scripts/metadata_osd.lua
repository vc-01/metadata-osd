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

require 'mp'
require 'mp.options'
require 'mp.utils'
require 'mp.msg'

-- defaults
local options = {
    -- Master enable (on mpv start)
    enable_on_start = true,

    -- Enable for tracks
    enable_for_audio = true,
    enable_for_audio_withalbumart = true,
    enable_for_video = true,
    enable_for_image = true,

    -- Enable OSD-2
    enable_osd_2 = true,

    -- Autohide for tracks
    autohide_for_audio = false,
    autohide_for_audio_withalbumart = false,
    autohide_for_video = true,
    autohide_for_image = true,

    -- Autohide delay in seconds
    autohide_timeout_sec = 5,
    autohide_statusosd_timeout_sec = 10,

    -- Key bindings

    -- Master enable / disable switch key (killswitch)
    key_toggleenable = 'F1',

    -- OSD autohide enable / disable switch key
    key_toggleautohide = 'F5',

    -- Show / hide OSD-1 switch key (current autohide state applies)
    key_toggleosd_1 = '',

    -- Show / hide OSD-2 switch key (current autohide state applies)
    key_toggleosd_2 = '',

    -- Reset user-toggled switches
    key_reset_usertoggled = 'F6',

    -- Show status OSD key
    key_showstatusosd = '',

    osd_message_maxlength = 96,

    -- Styling options

    -- OSD-1 layout:
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- ├─────────────────┤
    -- │ TEXT AREA 2     │
    -- ├─────────────────┤
    -- │ TEXT AREA 3     │
    -- ├─────────────────┤
    -- │ TEXT AREA 4     │
    -- └─────────────────┘

    -- OSD-2 layout:
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- └─────────────────┘

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

    -- Style: Font style
    -- Values may be (multiple separated by semicolon ';'):
    --   regular (or) italic ';' bold
    style_fontstyle_osd_1_textarea_1 = "bold",
    style_fontstyle_osd_1_textarea_2 = "bold",
    style_fontstyle_osd_1_textarea_2_releasedate = "regular",
    style_fontstyle_osd_1_textarea_3 = "italic",
    style_fontstyle_osd_1_textarea_4 = "regular",
    style_fontstyle_osd_2_textarea_1 = "regular",

    -- Style: Padding top (in number of lines)
    -- Values may be:
    --   0, 1, .. 40
    style_paddingtop_osd_1_textarea_1 = 1,
    style_paddingtop_osd_1_textarea_2 = 1,
    style_paddingtop_osd_1_textarea_3 = 3,
    style_paddingtop_osd_1_textarea_4 = 4,
    style_paddingtop_osd_2_textarea_1 = 3,

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

read_options(options, "metadata-osd") -- underscore character blends in better,
                                      -- keeping this for backward compat.
read_options(options)

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
local unicode_ellipsis = "\u{2026}"

-- String helper functions

local function utf8_nextcharoffs(u_b1, u_b2, u_b3, u_b4)
    local nextcharoffs = nil

    -- UTF-8 Byte Sequences: Unicode Version 15.0.0, Section 3.9, Table 3-7
    -- The Unicode Consortium. The Unicode Standard, Version 15.0.0, (Mountain View, CA: The Unicode Consortium, 2022. ISBN 978-1-936213-32-0)
    -- https://www.unicode.org/versions/Unicode15.0.0/

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
    return type(arg) == "string" and string.len(arg) == 0
end

local function str_isnonempty(arg)
    return type(arg) == "string" and string.len(arg) > 0
end

local function str_trunc(str)
    local result = str
    local str_truncpos = options.osd_message_maxlength

    if str_isnonempty(str) and
        str_truncpos > 0
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
                mp.msg.debug("str_trunc(): found invalid UTF-8 character; falling back to byte-oriented string truncate.")
            elseif u_b1 ~= nil and nextcharoffs ~= nil -- string needs to be trunc-ed
            then
                str_truncpos = str_bytepos - 1
            end
        end

        if string.len(str) > str_truncpos
        then
            result =
                string.sub(str, 1, str_truncpos) ..
                unicode_ellipsis
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

-- SSA/ASS helper functions
--   spec. url: http://www.tcax.org/docs/ass-specs.htm

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
                mp.msg.debug("str_split_styleoption(): found: " .. styleopt_pass2)
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
        string.rep(ass_newline(), res_paddingtop)
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

local ass_style = {}

local function parse_style_options()
    ass_style.osd_1 = {}
    ass_style.osd_1.textarea_1 = {}
    ass_style.osd_1.textarea_2 = {}
    ass_style.osd_1.textarea_2_releasedate = {}
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

    ass_style.osd_1.textarea_2_releasedate.fontstyle = {}
    ass_style.osd_1.textarea_2_releasedate.fontstyle.is_italic,
    ass_style.osd_1.textarea_2_releasedate.fontstyle.is_bold =
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

    ass_style.osd_1.textarea_3.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_1_textarea_3)

    ass_style.osd_1.textarea_4.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_1_textarea_4)

    ass_style.osd_2.textarea_1.fsp =
        parse_styleoption_fsp(
            options.style_fsp_osd_2_textarea_1)
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
    mp.msg.debug("show_osd_1()")

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
    mp.msg.debug("show_osd_2()")

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
    mp.msg.debug("hide_osd()")

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
    mp.msg.debug("toggle_osd_1()")

    if osd_enabled then
        if curr_state == state.SHOWING_OSD_1 then
            hide_osd()
        else
            show_osd_1()
        end
    end
end

local function toggle_osd_2()
    mp.msg.debug("toggle_osd_2()")

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

local function toggle_osd_autohide()
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
    mp.msg.debug("reset_usertoggled()")
    osd_enabled_usertoggled = false
    osd_autohide_usertoggled = false
    reeval_osd_enabled()
    reeval_osd_autohide()
    show_statusosd()
end

local function on_metadata_change(propertyname, propertyvalue)
    if type(propertyname.event) == "string" then
        propertyname = propertyname.event
    elseif type(propertyname) ~= "string" then
        propertyname = ""
    end
    mp.msg.debug("on_metadata_change(): " .. propertyname)

    local prop_path           = mp.get_property_osd("path")
    local prop_streamfilename = mp.get_property_osd("stream-open-filename")
    local prop_fileformat     = mp.get_property_osd("file-format")
    local prop_mediatitle     = mp.get_property_osd("media-title")

    local prop_meta_album     = mp.get_property("metadata/by-key/Album")
    local prop_meta_title     = mp.get_property("metadata/by-key/Title")

    local prop_playlist_curr  = mp.get_property("playlist-pos-1")
    local prop_playlist_total = mp.get_property("playlist-count")
    local prop_chapter_curr   = mp.get_property("chapter")
    local prop_chapters_total = mp.get_property("chapters")
    local prop_chaptertitle   = mp.get_property("chapter-list/" .. tostring(prop_chapter_curr) .. "/title")

    local playing_file =
        (prop_fileformat ~= "hls") and -- not 'http live streaming'
        (prop_path == prop_streamfilename) -- not processed by yt-dlp/youtube-dl

    -- OSD-1 layout:
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- ├─────────────────┤
    -- │ TEXT AREA 2     │
    -- ├─────────────────┤
    -- │ TEXT AREA 3     │
    -- ├─────────────────┤
    -- │ TEXT AREA 4     │
    -- └─────────────────┘

    local osd_str =
        ass_style.osd_1.alignment ..
        ass_style.osd_1.bord

    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- └─────────────────┘
    local text_area_1_str = nil

    if playing_file then
        -- meta: Artist
        local prop_meta_artist = mp.get_property("metadata/by-key/artist")

        if str_isempty(prop_meta_artist) then
            prop_meta_artist = mp.get_property("metadata/by-key/album_artist")
        end

        if str_isempty(prop_meta_artist) then
            prop_meta_artist = mp.get_property("metadata/by-key/composer")
        end

        if str_isnonempty(prop_meta_artist) then
            text_area_1_str = prop_meta_artist

        -- Foldername-artist fallback
        else
            local folder_upup_pattern = ".*/(.*)/(.*)/.*"

            if prop_path:match(folder_upup_pattern) then
                foldername_artist = prop_path:gsub(folder_upup_pattern, "%1")
                foldername_artist = foldername_artist:gsub("_", " ")
                text_area_1_str = foldername_artist
            end
        end
    else -- playing from remote source
        -- meta: Uploader
        local prop_uploader = mp.get_property_osd("metadata/by-key/Uploader")

        if str_isnonempty(prop_uploader) then
            text_area_1_str = prop_uploader
        end
    end

    osd_str = osd_str ..
        ass_style.osd_1.textarea_1.paddingtop

    if text_area_1_str
    then
        osd_str = osd_str ..
            ass_style.osd_1.textarea_1.shad ..
            ass_style.osd_1.textarea_1.fsc ..
            ass_style.osd_1.textarea_1.fsp ..
            ass_styleoverride_fontstyle(
                ass_style.osd_1.textarea_1.fontstyle.is_italic,
                ass_style.osd_1.textarea_1.fontstyle.is_bold,
                str_trunc(text_area_1_str))
    end

    -- ┌─────────────────┐
    -- │ TEXT AREA 2     │
    -- └─────────────────┘
    local text_area_2_str = nil
    local text_area_2_releasedate_str = nil

    if playing_file then
        -- For files with internal chapters ...
        -- meta: Title (album name usually)
        if prop_chapter_curr and prop_chapters_total and str_isnonempty(prop_meta_title) then
            text_area_2_str = prop_meta_title

            -- meta: Track (release year _usually_)
            local prop_meta_track = mp.get_property("metadata/by-key/Track")
            prop_meta_track = str_capture4digits(prop_meta_track)

            if str_isnonempty(prop_meta_track) then
                text_area_2_releasedate_str = " (" .. prop_meta_track .. ")"
            end

        -- meta: Album
        elseif str_isnonempty(prop_meta_album) then
            text_area_2_str = prop_meta_album

            -- meta: Album release date
            local prop_meta_reldate   = mp.get_property("metadata/by-key/Date")
            prop_meta_reldate = str_capture4digits(prop_meta_reldate)

            if str_isnonempty(prop_meta_reldate) then
                text_area_2_releasedate_str = " (" .. prop_meta_reldate .. ")"
            end

        -- Foldername-album fallback
        else
            local folder_up_pattern = ".*/(.*)/.*"

            if prop_path:match(folder_up_pattern) then
                foldername_album = prop_path:gsub(folder_up_pattern, "%1")
                foldername_album = foldername_album:gsub("_", " ")
                text_area_2_str = foldername_album
            end
        end
    else -- playing from remote source
        -- <Text area empty in this release>
    end

    osd_str = osd_str ..
        ass_style.osd_1.textarea_2.paddingtop

    if text_area_2_str
    then
        osd_str = osd_str ..
            ass_style.osd_1.textarea_2.shad ..
            ass_style.osd_1.textarea_2.fsp ..
            ass_style.osd_1.textarea_2.fsc ..
            ass_styleoverride_fontstyle(
                ass_style.osd_1.textarea_2.fontstyle.is_italic,
                ass_style.osd_1.textarea_2.fontstyle.is_bold,
                str_trunc(text_area_2_str))

        if text_area_2_releasedate_str
        then
            osd_str = osd_str ..
                ass_styleoverride_fontstyle(
                    ass_style.osd_1.textarea_2_releasedate.fontstyle.is_italic,
                    ass_style.osd_1.textarea_2_releasedate.fontstyle.is_bold,
                    text_area_2_releasedate_str)
        end
    end

    -- ┌─────────────────┐
    -- │ TEXT AREA 3     │
    -- └─────────────────┘
    local text_area_3_str = nil

    if playing_file then
        -- For files with internal chapters ...
        -- meta: Chapter title
        if curr_mediatype ~= mediatype.VIDEO and prop_chapter_curr and prop_chapters_total and str_isnonempty(prop_chaptertitle) then
            text_area_3_str = prop_chaptertitle

        -- meta: Title
        elseif str_isnonempty(prop_meta_title) then
            text_area_3_str = prop_meta_title

        -- Filename fallback
        else
            filename_noext = mp.get_property_osd("filename/no-ext")
            assumed_title = filename_noext:gsub("_", " ")
            text_area_3_str = assumed_title
        end
    else -- playing from remote source
        -- meta: Media Title
        if str_isnonempty(prop_mediatitle) then
            text_area_3_str = prop_mediatitle
        end
    end

    osd_str = osd_str ..
        ass_style.osd_1.textarea_3.paddingtop

    if text_area_3_str
    then
        osd_str = osd_str ..
            ass_style.osd_1.textarea_3.shad ..
            ass_style.osd_1.textarea_3.fsc ..
            ass_style.osd_1.textarea_3.fsp ..
            ass_styleoverride_fontstyle(
                ass_style.osd_1.textarea_3.fontstyle.is_italic,
                ass_style.osd_1.textarea_3.fontstyle.is_bold,
                str_trunc(text_area_3_str))
    end

    -- ┌─────────────────┐
    -- │ TEXT AREA 4     │
    -- └─────────────────┘
    local text_area_4_str = nil

    -- For files with chapters...
    -- meta: Chapter current / chapters total
    if str_isnonempty(prop_chapter_curr) and str_isnonempty(prop_chapters_total) then
        text_area_4_str =
            tostring(prop_chapter_curr + 1) ..
            "/" ..
            tostring(prop_chapters_total)

    -- meta: Playlist position
    elseif str_isnonempty(prop_playlist_curr) and str_isnonempty(prop_playlist_total) then
        text_area_4_str =
            tostring(prop_playlist_curr) ..
            "/" ..
            tostring(prop_playlist_total)

        local prop_meta_track = mp.get_property("metadata/by-key/Track")

        if str_isnonempty(prop_meta_track)
        then
            local i, j = string.find(prop_meta_track, '[%d]+')
            if i and j
            then
                local prop_meta_track_digits = string.sub(prop_meta_track, i, j)
                if str_isnonempty (prop_meta_track_digits)
                then
                    prop_playlist_curr_n = tonumber(prop_playlist_curr)
                    prop_playlist_total_n = tonumber(prop_playlist_total)
                    prop_meta_track_n = tonumber(prop_meta_track_digits)
                    if prop_playlist_curr_n and
                        prop_playlist_total_n and
                        prop_meta_track_n
                    then
                        if prop_playlist_curr_n ~= prop_meta_track_n or
                            prop_playlist_total_n == 1
                        then
                            text_area_4_str = text_area_4_str ..
                                "  (Album Track: " .. prop_meta_track .. ")"
                        end
                    end
                end
            end
        end
    end

    osd_str = osd_str ..
        ass_style.osd_1.textarea_4.paddingtop

    if text_area_4_str
    then
        osd_str = osd_str ..
            ass_style.osd_1.textarea_4.shad ..
            ass_style.osd_1.textarea_4.fsc ..
            ass_style.osd_1.textarea_4.fsp ..
            ass_styleoverride_fontstyle(
                ass_style.osd_1.textarea_4.fontstyle.is_italic,
                ass_style.osd_1.textarea_4.fontstyle.is_bold,
                str_trunc(text_area_4_str))
    end

    osd_overlay_osd_1.data = osd_str

    -- OSD-2 layout:
    -- ┌─────────────────┐
    -- │ TEXT AREA 1     │
    -- └─────────────────┘
    -- meta: Chapter Title
    if options.enable_osd_2 and str_isnonempty(propertyname) and propertyname == "chapter-metadata/title" and str_isnonempty(propertyvalue) then
        osd_overlay_osd_2.data =
            ass_style.osd_2.alignment ..
            ass_style.osd_2.bord ..
            ass_style.osd_2.textarea_1.paddingtop ..
            ass_style.osd_2.textarea_1.shad ..
            ass_style.osd_2.textarea_1.fsc ..
            ass_style.osd_2.textarea_1.fsp ..
            ass_styleoverride_fontstyle(
                ass_style.osd_2.textarea_1.fontstyle.is_italic,
                ass_style.osd_2.textarea_1.fontstyle.is_bold,
                str_trunc(propertyvalue))
    end

    if str_isnonempty(propertyname) and propertyname == "chapter-metadata/title" and (curr_state == state.SHOWING_OSD_2 or (osd_autohide and curr_state == state.OSD_HIDDEN)) then
        show_osd_2()
    else
        show_osd_1()
    end
end

local function master_osd_enable()
    mp.msg.debug("master_osd_enable()")

    mp.add_key_binding(
        options.key_toggleosd_1,
        "toggle_osd_1",
        toggle_osd_1)

    mp.add_key_binding(
        options.key_toggleosd_2,
        "toggle_osd_2",
        toggle_osd_2)

    mp.add_key_binding(
        options.key_toggleautohide,
        "toggle_osd_autohide",
        toggle_osd_autohide)

    mp.add_key_binding(
        options.key_reset_usertoggled,
        "reset_usertoggled",
        reset_usertoggled)

    mp.observe_property(
        "metadata",
        "string",
        on_metadata_change)

    mp.observe_property(
        "chapter-metadata/title",
        "string",
        on_metadata_change)

    osd_enabled = true
    show_osd_1()
end

local function master_osd_disable()
    mp.msg.debug("master_osd_disable()")

    mp.remove_key_binding(
        "toggle_osd_autohide")
    mp.remove_key_binding(
        "toggle_osd_1")
    mp.remove_key_binding(
        "toggle_osd_2")
    mp.remove_key_binding(
        "reset_usertoggled")

    mp.unobserve_property(
        on_metadata_change)

    hide_osd()
    osd_enabled = false
end

local function toggle_osd_enabled()
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
    mp.msg.debug("on_tracklist_change()")

    curr_mediatype = mediatype.UNKNOWN

    if tracklist then
        mp.msg.debug("on_tracklist_change(): num of tracks: " .. tostring(#tracklist))

        for _, track in ipairs(tracklist) do
            if not track.selected then
                goto continue
            end

            if track.type == "audio" and curr_mediatype == mediatype.UNKNOWN then
                mp.msg.debug("on_tracklist_change(): audio track selected")
                curr_mediatype = mediatype.AUDIO
            elseif track.type == "video" then
                mp.msg.debug("on_tracklist_change(): video track selected")
                curr_mediatype = mediatype.VIDEO
                if track.image then
                    mp.msg.debug("on_tracklist_change(): video track is image")
                    curr_mediatype = mediatype.IMAGE
                    if track.albumart then
                        mp.msg.debug("on_tracklist_change(): video track is albumart.")
                        curr_mediatype = mediatype.AUDIO_ALBUMART
                    end
                end
            end

            ::continue::
        end
    end

    mp.msg.debug("on_tracklist_change(): current media type: " .. curr_mediatype)

    reeval_osd_enabled()
    reeval_osd_autohide()
end

mp.add_key_binding(
    options.key_toggleenable,
    "toggleenable",
    toggle_osd_enabled)

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

local ffi = require("ffi")
if jit.os == "Linux" then
    charencode_utf8 = true
end

parse_style_options()
