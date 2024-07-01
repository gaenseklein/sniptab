VERSION = "1.1.0"

local micro = import("micro")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")

local RTSnippets = config.NewRTFiletype()
local RTEmmetAbbr = config.NewRTFiletype()

local current_bp = nil
local current_filetype = nil
local snippets_by_filetype = {}
local current_snippet = nil



local function ReadSnippets(filetype)
	-- debug1("ReadSnippets(filetype)",filetype)
	local snippets = {}
	local allSnippetFiles = config.ListRuntimeFiles(RTSnippets)
	-- consoleLog(allSnippetFiles, "allSnippetFiles",3)
	local exists = false

	for i = 1, #allSnippetFiles do
		if allSnippetFiles[i] == filetype then
			exists = true
			break
		end
	end

	if not exists then
		micro.InfoBar():Error("No snippets file for \""..filetype.."\"")
		return snippets
	end

	local snippetFile = config.ReadRuntimeFile(RTSnippets, filetype)

	local curSnip = nil
	local curSnipLine = nil
	local lineNo = 0
	local raw_code = {}
	local raw_code_ind = 0
	
	for line in string.gmatch(snippetFile, "(.-)\r?\n") do
		lineNo = lineNo + 1
		if string.match(line,"^#") then
			-- comment
		elseif line:match("^snippet") then
			if curSnip ~= nil then 				
				-- consoleLog(curSnip, "curSnip")
				-- consoleLog(raw_code, "raw_code",2)
				snippets[curSnip] = create_snippets(raw_code)
				raw_code = {}
				raw_code_ind = 0
				-- for snipName in line:gmatch("%s(%S+)") do  -- %s space  .+ one or more non-empty sequence
					-- snippets[snipName] = snippets[curSnip]
				-- end
				
			end
			curSnip = line:match("%s(%S+)")--line:gsub(8) -- only non-white-chars, only first word
			curSnipLine = line			
		elseif line:match("^\t(.*)$") then
			raw_code_ind = raw_code_ind + 1
			raw_code[raw_code_ind] = line:sub(2)			
			-- local codeLine = line:match("^\t(.*)$")
			-- if codeLine ~= nil then
				-- curSnip:AddCodeLine(codeLine)
			-- elseif line ~= "" then
				-- micro.InfoBar():Error("Invalid snippets file (Line #"..tostring(lineNo)..")")
			-- end
		end
	end
	-- consoleLog(curSnip, "curSnip")
	if curSnip ~= nil then 
		snippets[curSnip] = create_snippets(raw_code)
		raw_code = {}
		raw_code_ind = 0
		-- for snipName in line:gmatch("%s(%S+)") do  -- %s space  .+ one or more non-empty sequence
			-- snippets[snipName] = snippets[curSnip]
		-- end
	end
	-- debugt("ReadSnippets(filetype) snippets = ",snippets)
	return snippets
end

function load_snippets(bp)
	local filetype = bp.Buf.Settings["filetype"]
	current_filetype = filetype
	if snippets_by_filetype[filetype]==nil then
		snippets_by_filetype[filetype] = ReadSnippets(filetype)
	end
	-- consoleLog(snippets_by_filetype[filetype], "loaded snippets",5)
	return snippets_by_filetype[filetype]
	
end

function create_snippets(lines)
	local found_positions = {}
	local found_count = 0
	local code_lines = {}
	for l=1,#lines do
		local line = lines[l]
		local startpos = string.find(line,"${",1,true)
		local separator = nil
		local endpos = nil
		if startpos ~= nil then
			separator = string.find(line,":",startpos,true)
			endpos = string.find(line,"}",startpos,true)
		end
		while startpos ~= nil and endpos ~= nil do
			-- consoleLog({startpos, endpos, separator,line, l, lines},"loop start, end, sep, line, l, lines",3)
			local rep = ""
			local replength = 0
			if separator ~= nil and separator < endpos then
				rep = string.sub(line, separator + 1, endpos -1)
				-- replength = endpos - separator - 2
				replength = string.len(rep)
			end
			line = string.sub(line, 1, startpos -1) .. rep .. string.sub(line, endpos + 1)
			-- consoleLog(line, "line shortened")
			found_count = found_count + 1
			found_positions[found_count] = {line=l, pos=startpos, filler_length = replength}
			startpos = string.find(line,"${",1,true)
			separator = string.find(line,":",startpos,true)
			endpos = string.find(line,"}",startpos,true)
		end
		-- consoleLog({startpos, endpos, separator,line},"loop start, end, sep",3)
		code_lines[l] = line
	end
	-- if not found_positions[1] then
		-- found_positions[1] = {line = #lines, pos = #lines[#lines]+1}
	-- end
	local result = {code_lines = code_lines, relative_positions = found_positions}
	-- consoleLog(result, "create_snippets:",5)
	return result
end

local function CursorWord(bp)
	-- debug1("CursorWord(bp)",bp)
	local c = bp.Cursor
	local x = c.X-1 -- start one rune before the cursor
	local result = ""
	while x >= 0 do
		local r = util.RuneStr(c:RuneUnder(x))
		if (r == " " or r == "\t") then    -- IsWordChar(r) then
			break
		else
			result = r .. result
		end
		x = x-1
	end
	-- consoleLog(result, "cursorWord")
	return result
end

local function clear()
	current_snippet = nil
end

local function get_act_line(bp)
	-- consoleLog(bp.Cursor.Y, "get_act_line")
	return bp.Buf:Line(bp.Cursor.Y)
end

local function get_cursor_pos(bp)
	local x = bp.Cursor.X + 1
	local y = bp.Cursor.Y + 1
	return x, y
end

local function set_cursor_pos(bp, x, y, selection_length)
	-- consoleLog({x=x,y=y,cx=bp.Cursor.X,cy=bp.Cursor.Y},"set cursor pos ")
	-- consoleLog({x=x,y=y,selection_length=selection_length})
	local c = bp.Cursor
	c:ResetSelection()
	local pos_start = buffer.Loc(x-1,y-1) 
	local pos_end = pos_start
	c.X = pos_start.X
	c.Y = pos_start.Y
	if selection_length > 0 then
		pos_end = buffer.Loc(x-1+selection_length,y-1)
		c:SetSelectionStart(pos_start)
		c:SetSelectionEnd(pos_end)		
	end
	-- c:ResetSelection()
	-- consoleLog({x=x,y=y,cx=bp.Cursor.X,cy=bp.Cursor.Y},"after set cursor pos ")
end
local function write_snippet_to_buf(bp, x, y, word, code)
	--bp.Buf bp.Cursor
	local l = 0
	local c = bp.Cursor
	if word ~= nil then 
		l = string.len(word)
	end
	local pos_end = buffer.Loc(x-1,y-1)
	local pos_start = buffer.Loc(x-1-l,y-1) 
	if l >=1 then
		c:SetSelectionStart(pos_start)
		c:SetSelectionEnd(pos_end)
		c:DeleteSelection()
		c:ResetSelection()
	end
	-- consoleLog({x_before = bp.Cursor.X, y_before = bp.Cursor.Y})
	bp.Buf:Insert(pos_start, code)
	-- consoleLog({x_after = bp.Cursor.X, y_after = bp.Cursor.Y})
end

local function create_whiteline(line)
	return string.gsub(line,"[^\t\f\v]",' ')
end

function move_to_current_snippet(bp)
	if current_snippet == nil then 
		return false
	end
	-- consoleLog(current_snippet, "current snippet",5)
	-- consoleLog({snippet = current_snippet, curs_x= bp.Cursor.X,curs_y= bp.Cursor.Y}, "move to current snippet", 5)
	current_snippet.act_position_index = current_snippet.act_position_index + 1
	if current_snippet.relative_positions[current_snippet.act_position_index] == nil then
			clear()
			return false
	end
	
	local act_p = current_snippet.relative_positions[current_snippet.act_position_index]
	local y = act_p.line + current_snippet.insert_pos.line - 1
	local x = act_p.pos + current_snippet.insert_pos.pos - 1
	if act_p.line > 1 then 
		x = act_p.pos + current_snippet.whiteline_length 
	end	
	if current_snippet.act_position_index > 1 and act_p.line == current_snippet.relative_positions[current_snippet.act_position_index - 1].line then 
		local act_l = get_act_line(bp)
		x = x + string.len(act_l) - string.len(current_snippet.code_lines[act_p.line])
	end
	-- consoleLog({x=x,y=y,act_line=get_act_line(bp), act_cursor_x=bp.Cursor.X, act_cursor_y=bp.Cursor.Y},"result moveto",5)
	set_cursor_pos(bp, x, y, act_p.filler_length)
	if current_snippet.relative_positions[current_snippet.act_position_index+1] == nil then
		clear()
	end
	return true
end

function snip_from_terminal(bp, args)
	-- consoleLog(args[1], "args[1]",5)
	if #args == 0 then 
		on_tab(bp, args)
	else
		 -- insert word and call on_first_tab afterwards:
		 
		 local word = args[1]
		 local pos = buffer.Loc(bp.Cursor.X, bp.Cursor.Y)
		 bp.Buf:Insert(pos, word)
		 local activated = on_first_tab(bp, word) 
		 if not activated then 		 	
		 	local endpos = buffer.Loc(bp.Cursor.X, bp.Cursor.Y)
		 	local c = bp.Cursor
			c:SetSelectionStart(pos)
			c:SetSelectionEnd(endpos)
			c:DeleteSelection()
			c:ResetSelection()
			micro.InfoBar():Error("No snippet for \""..word.."\"")
		 end
		-- consoleLog(args[1],"args[1]")
	end
	
end

function on_tab(bp, args)
	if bp ~= current_bp then
		clear()
	end
	current_bp = bp
	local activated = false
	if current_snippet ~= nil then
		-- return on_second_tab(bp)
		activated = move_to_current_snippet(bp)
		
	else 
		activated = on_first_tab(bp)
	end
	return activated
end

function on_first_tab(bp, pre_word)
	local word = pre_word
	if pre_word == nil then word = CursorWord(bp) end
	local snippets = load_snippets(bp)
	-- if next(snippets) == nil then
		-- return false
	-- end
	-- consoleLog({
		-- word= word,
		-- word_snippets= snippets[word]
	-- }, "on_first_tab", 4)
	if snippets[word] == nil then 
		-- consoleLog('no snippet found for word')
		-- return
		return false
	end
	local act_line = get_act_line(bp)
	local cursor_x, cursor_y = get_cursor_pos(bp)
	local whiteline = create_whiteline(string.sub(act_line, 1, cursor_x - string.len(word)-1))
	current_snippet = {}
	current_snippet.insert_pos = {line = cursor_y, pos = cursor_x - string.len(word)}
	current_snippet.code_lines = snippets[word].code_lines
	current_snippet.relative_positions = {}
	for i=1,#snippets[word].relative_positions do
		current_snippet.relative_positions[i]={
			line = snippets[word].relative_positions[i].line,
			pos = snippets[word].relative_positions[i].pos,	
			filler_length = snippets[word].relative_positions[i].filler_length
		}
	end
	current_snippet.whiteline = whiteline
	current_snippet.whiteline_length = string.len(whiteline)
	current_snippet.act_position_index = 0

	local insert_string = current_snippet.code_lines[1]
	for i=2,#current_snippet.code_lines do
		insert_string = insert_string .."\n".. whiteline .. current_snippet.code_lines[i]
	end
	write_snippet_to_buf(bp, cursor_x, cursor_y, word, insert_string)
	move_to_current_snippet(bp)
	-- if current_snippet ~= nil and current_snippet.relative_positions[current_snippet.act_position_index+1] == nil then
		-- clear()
	-- end
	return true
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- emmet
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~

local emmet_abbr = {}

function parse_emmet_element(str)
	local char = ""
	local tag = {
		class = "",
		id = "",
		tag = "",
		attribute = "",
		inner = "",
		multiply = "",
		multiply_count = "",
		closing_tag = true
	}
	local target = "tag"
	for pos = 1, #str do
		char = string.sub(str,pos,pos)
	    if char == "." then 
			target = "class" 
	    	if string.len(tag[target]) > 1 then 
	    		tag[target] = tag[target] .. " "
	    	end
	    elseif char == "#" then 
	    	target = "id" 
	    elseif char == "[" then 
	    	target = "attribute"
	    elseif char == "{" then 
	    	target = "inner"
	    elseif char == "}" or char == "]" then
	    	-- do nothing
	    elseif char == "*" then 
	    	target = "multiply"
    	elseif char == "@" then 
	    	target = "multiply_count"
	    elseif char == "/" then
	    	tag.closing_tag = false
	    else
	    	-- consoleLog({target=target,char=char,tag=tag},"parsing element...",3)
	    	tag[target] = tag[target] .. char
	    end
	end	
	-- if tag.tag == "" then tag.tag = "div" end
	-- TODO: defaulting span on em>.class
	-- TODO: defaulting li on ul>.class
	-- TODO: defaulting to tr / td on table, tr, td
	-- consoleLog(tag, "tag",2)
	return tag
end

function parse_emmet_raw_string(str)
	local root = {children = {}}
	local act = {raw="", children={},parent=root}
	root.children[1]=act	
	local node_group_parent = {}
	local node_group_parent_i = 0

	local new_object
	local char = ""
	for pos = 1, #str do
		char = string.sub(str,pos,pos)
		if char == ">" then 	    
			new_object = {raw="",children={},parent=act}
			table.insert(act.children, new_object)
			act = new_object
		elseif char == "+" then
		    new_object = {raw="",children={},parent=act.parent}
		    table.insert(act.parent.children, new_object)
		    act = new_object
		elseif char == "^" then
		    local target_parent = root
		    if act.parent ~= root and act.parent.parent ~= root then 
		        target_parent = act.parent.parent
		    end
		    new_object = {raw="",children={}, parent=target_parent}
		    table.insert(target_parent.children, new_object)
		    act = new_object
		elseif char == "(" then
			node_group_parent_i = node_group_parent_i + 1
			node_group_parent[node_group_parent_i] = act.parent
		elseif char == ")" then
			act = node_group_parent[node_group_parent_i]
			node_group_parent_i = node_group_parent_i - 1
			
			if pos<#str then
				local next_char = string.sub(str,pos+1,pos+1)
				if next_char == "*" or next_char == "@" then 
					act.multipos = string.len(act.raw)
					act.raw_short = act.raw
				end
			end
		else 
			act.raw = act.raw .. char
		end		
	end
	return root
end

function create_emmet_tag_nodes(node)
	if node.raw_short ~= nil then
        node.multi_raw = string.sub(node.raw, node.multipos+1)
        node.raw = string.sub(node.raw, 1, node.multipos)
    end
    if node.raw ~= nil then node.emmet = parse_emmet_element(node.raw) end
    if node.emmet ~= nil and node.emmet.tag == "" then    
		if node.parent.emmet == nil then 
			node.emmet.tag = "div"
		elseif node.parent.emmet.tag == "em" then
			node.emmet.tag = "span"
		elseif node.parent.emmet.tag == "ul" then
			node.emmet.tag = "li"
		elseif node.parent.emmet.tag == "table" then
			node.emmet.tag = "tr"
		elseif node.parent.emmet.tag == "tr" then
			node.emmet.tag = "td"
		else
			node.emmet.tag = "div"
		end
    end
    -- if emmet_abbr[node.emmet.tag]~=nil then
		-- 
    -- end
    for i=1, #node.children do
        create_emmet_tag_nodes(node.children[i])
    end	    
    -- node.emmet.children = node.children
end

function parse_attribute(str)
	local res = ""
    local complete = false
    local block_parsing = false
    local used_attributes = {}
    local startpos = 1
	local char = ""
	for pos = 1, #str do
		char = string.sub(str,pos,pos)
		if char == "=" or char == " " or pos==#str then
            local atname = string.sub(str, startpos, pos-1)
            if used_attributes[atname] then 
                res = string.sub(res, 1, startpos)
	            block_parsing = true
            end
            used_attributes[atname]=true
		end
		if char == "'" or char == '"' then
			complete = true
		end
		if char == " " then
			startpos = pos
			if not complete and not block_parsing then
				res = res .. '="${0}"'
			end
			block_parsing = false
			complete = false			
		end
		if not block_parsing then
			res = res .. char
		end		
	end
	if not block_parsing and not complete and string.len(res)>0 then
		res = res .. '="${0}"'
	end
	
	return res
end

function create_emmet_snippet_html(node)
	if node.emmet.tag == "" then return "" end
    local html
    local atstring = ""
    
    local tag = node.emmet.tag    
    if node.emmet.attribute then atstring = parse_attribute(node.emmet.attribute) end
    if node.emmet.class ~= "" then atstring = 'class="'.. node.emmet.class..'" ' .. atstring end
    if node.emmet.id ~= "" then atstring = 'id="'.. node.emmet.id..'" ' .. atstring end
    if string.len(atstring)>0 then atstring = " ".. atstring end
    if string.sub(atstring, #atstring) == " " then atstring = string.sub(atstring, 1, #atstring-1) end
    html = "<" .. tag .. atstring .. ">"    
--    local is_simple = string.sub(html, -2)=="/>"
	local line_break = #node.children > 0
	if line_break then html = html .. "\n" end
    if node.emmet.inner ~= "" then 
        html = html .. "\t" .. string.gsub(node.emmet.inner, "\n", "\n\t")
        if line_break then html = html .. "\n" end
    end
    -- local inner
    for i=1, #node.children do
        local inner = create_emmet_snippet_html(node.children[i])
        -- html = html .. ">>" .. inner .. "<<"
        html = html .. "\t" .. string.gsub(inner, "\n","\n\t")
        -- if i < #node.children then html = html .. "\n" end
        -- html = html .. "\n???" .. i .. node.emmet.tag .. node.children[i].emmet.tag
    end
--    if string.sub(html, -3,-1)~="/>" then 
    if node.emmet.closing_tag then
        -- html = html .. '\t${0}\n</'.. tag .. '>'
        if line_break then html = html .. "\t" end
        html = html .. '${0}'
        if line_break then html = html .. "\n" end
        html = html .. '</'.. tag .. '>'
    end
--    html = string.gsub(html, "$$$$", "000$")
--    html = string.gsub(html, "$$$", "00$")
--    html = string.gsub(html, "$$", "0$")

    if node.emmet.multiply ~= nil and string.len(node.emmet.multiply)>0 then 
    	-- consoleLog(node.emmet.multiply,"multiply node.emmet of "..node.emmet.tag)
        local max = tonumber(node.emmet.multiply)
        local multi_res = ""
        for i=1,max do
            multi_res = multi_res .. replace_dollar(html, i)
            if i < max then multi_res = multi_res .. "\n" end
        end
        html = multi_res
    end 
    -- html= html .. "\n" -- we have to use this to parse lines correctly!
    -- but we have to do it only once, so not here! 
    -- consoleLog({
    	-- tag = tag, atstring = atstring, closing_tag = node.emmet.no_closing_tag, html = html
    -- }, "create_html",3)
--    html = string.gsub(html, "=€{0}","=${0}")
    return html
end

function replace_dollar(str, num)
    local end_pos = nil
    local res = str
    local last_char = ""
    -- loop backwards through string with char, next_char, pos
    local char = ""
    local len = #str
    for i = 0, len-1 do
    	pos = len - i
    	char = string.sub(str,pos,pos)
        if char == "$" and end_pos == nil and last_char ~="{" then
            end_pos = pos
        elseif end_pos ~= nil then
           res = string.sub(res,1,pos) .. num .. string.sub(res,end_pos+1)
           end_pos = nil
        end
        last_char = char
    end
    return res
end

function emmet(bp, args)
	local emmet_string = args[1]
	local root = parse_emmet_raw_string(emmet_string)
	create_emmet_tag_nodes(root)
	-- consoleLog(root, "root", 3 )
	local html = ""
	local elements = root.children
	-- for i=1,#elements do
		-- local snhtml = create_emmet_snippet_html(elements[i])
		-- html = html .. snhtml
		-- -- html = html .. "\n??" .. i
		-- if i>1 then html = html .. "\n" end
	-- end
	html = create_emmet_snippet_html(elements[1])	
	html = html .. "\n" -- make shure we have an empty line at last
	local i
	for i=2,#elements do
		html = html .. create_emmet_snippet_html(elements[i])
		html = html .. "\n"
	end
	local lines = {}
	local count = 0
	for line in string.gmatch(html, "(.-)\r?\n") do
		count = count + 1
		lines[count]=line
	end
	local snippet = create_snippets(lines)
	-- consoleLog(html, "emmet-snippet",1)
	local act_line = get_act_line(bp)
	local cursor_x, cursor_y = get_cursor_pos(bp)
	local whiteline = create_whiteline(string.sub(act_line, 1, cursor_x -1))
	current_snippet = {}
	current_snippet.insert_pos = {line = cursor_y, pos = cursor_x}
	current_snippet.code_lines = snippet.code_lines
	current_snippet.relative_positions = {}
	for i=1,#snippet.relative_positions do
		current_snippet.relative_positions[i]={
			line = snippet.relative_positions[i].line,
			pos = snippet.relative_positions[i].pos,	
			filler_length = snippet.relative_positions[i].filler_length
		}
	end
	current_snippet.whiteline = whiteline
	current_snippet.whiteline_length = string.len(whiteline)
	current_snippet.act_position_index = 0

	local insert_string = current_snippet.code_lines[1]
	for i=2,#current_snippet.code_lines do
		insert_string = insert_string .."\n".. whiteline .. current_snippet.code_lines[i]
	end
	write_snippet_to_buf(bp, cursor_x, cursor_y, word, insert_string)
	move_to_current_snippet(bp)
	
end

function init_emmet_abreviations()
	local emmet_file = config.ReadRuntimeFile(RTEmmetAbbr, "html")
	consoleLog(emmet_file,'emmet file')
	local emmet_table = {}
	local key = nil
	for line in string.gmatch(emmet_file, "(.-)\r?\n") do
		if key == nil then 
			key = line
		else
			emmet_table[key]=line
			key = nil
		end
	end	
	consoleLog(emmet_table,"emmet table",2)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- end of emmet
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


function list_words(bp)
	local snippets
	if bp == nil then 
		snippets = snippets_by_filetype[current_filetype]
	else
		snippets = load_snippets(bp)
	end
	local words = {}
	local c = 0
	for i,v in pairs(snippets) do
		c = c + 1
		words[c]=i
	end
	return words
end

function init()
    -- Insert a snippet
    config.MakeCommand("snip", snip_from_terminal, config.NoComplete)
    config.MakeCommand("emmet", emmet, config.NoComplete)
    
    config.AddRuntimeFile("sniptab", config.RTHelp, "help/sniptab.md")
    -- config.AddRuntimeFile("sniptab", RTEmmetAbbr, "emmet/html.emmet")
    config.AddRuntimeFilesFromDirectory("sniptab", RTSnippets, "snippets", "*.snippets")
    config.AddRuntimeFilesFromDirectory("sniptab", RTEmmetAbbr, "emmet", "*.emmet")

	-- init_emmet_abreviations()
    -- config.TryBindKey("Alt-w", "lua:snippets.Next", false)
    -- config.TryBindKey("Alt-a", "lua:snippets.Accept", false)
    -- config.TryBindKey("Alt-s", "lua:snippets.Insert", false)
    -- config.TryBindKey("Alt-d", "lua:snippets.Cancel", false)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~
-- cancel on user interactions:
-- ~~~~~~~~~~~~~~~~~~~~~~~

function preCursorDown(view)
	clear()
end
function preCursorUp(view)
	clear()
end
function preCursorLeft(view)
	clear()
end
function preCursorRight(view)
	clear()
end
function preEscape(view)
	clear()
end
function preInsertNewline(view)
	clear()
end
-- the following should work but doesnt: 

function prePageUp(view)
	clear()
end
function prePageDown(view)
	clear()
end
function preCursorStart(view)
	clear()
end
function preCursorEnd(view)
	clear()
end
function preEnd(view)
	clear()
end
function preEndOfLine(view)
	clear()
end
function preStart(view)
	clear()
end
function preStartOfLine(view)
	clear()
end
function preStartOfText(view)
	clear()
end


-- ~~~~~~~~~~~~~~~~~~~~~~~
-- helper functions
-- ~~~~~~~~~~~~~~~~~~~~~~~

-- helper function to display booleans:
function boolstring(bol)
	if bol then return "true" else return "false" end
end

--debug function to transform table/object into a string
function dump(o, depth)
	if o == nil then return "nil" end
   if type(o) == 'table' then
      local s = string.rep(" ",depth*2).. '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         if depth > 0 then s = s .. '['..k..'] = ' .. dump(v, depth - 1) .. ',\n'
         else s = s .. '['..k..'] = ' .. '[table]'  .. ',\n'end
      end
      return s .. '} \n'
   elseif type(o) == "boolean" then
   	  return boolstring(o)   
   else
      return tostring(o)
   end
end
-- debug function to get a javascript-like console.log to inspect tables
-- expects: o: object like a table you want to debug
-- pre: text to put in front 
-- depth: depth to print the table/tree, defaults to 1
-- without depth  we are always in risk of a stack-overflow in circle-tables
function consoleLog(o, pre, depth)
	local d = depth
	if depth == nil then d = 1 end
	local text = dump(o, d)
	local begin = pre
	if pre == nil then begin = "" end	
	micro.TermError(begin, d, text)
end

--"Tab": "lua:snippets.Insert|Autocomplete|IndentSelection|InsertTab"