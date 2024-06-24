VERSION = "0.1.0"

local micro = import("micro")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")

local RTSnippets = config.NewRTFiletype()

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
				replength = endpos - separator - 2				
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
	local c = bp.Cursor
	local pos_start = buffer.Loc(x-1,y-1) 
	local pos_end = pos_start
	c.X = pos_start.X
	c.Y = pos_start.Y
	if selection_length > 0 then
		pos_end = buffer.Loc(x+selection_length,y-1)
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

function init()
    -- Insert a snippet
    config.MakeCommand("snip", snip_from_terminal, config.NoComplete)
    
    config.AddRuntimeFile("sniptab", config.RTHelp, "help/sniptab.md")
    config.AddRuntimeFilesFromDirectory("sniptab", RTSnippets, "snippets", "*.snippets")

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