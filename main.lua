









local ffi = require('ffi')
ffi.cdef(
[[
	int kwarto_set_mode(const int);
	int kwarto_initialize(const int);
	int kwarto_reset(void);
	int kwarto_input_board(char *);
	int kwarto_group_masks(void);
	int kwarto_solve(int);
]]
)
local lib = ffi.load(string.format('./kwarto_%s.%s', ffi.arch,
	ffi.os == 'Linux' and 'so' or 'dll'))
	-- more detailed discussion later

local bit = require('bit')


local mode = 0

local _z = 'y'


local hex = {}
	-- hex[i] == string.sub('.0123456789abcdef', i+1, i+1) for i = 0 to 16


local image = {}
	-- images for pieces (from 1 through 16) and symbols (characters of 'ouxyz')
local coord = {}
	-- coordinates of (real) stock positions (from 1 through 16), the stage (0),
	-- the board (from -1 through -16) and the controls ('u', 'x', 'y', 'z')
local ckeys = {}
	-- ckeys[ coord[k][1] ][ coord[k][2] ] == k
	-- since 'columns' are evenly spaced, on mouse (touch) events
	-- stock indices need to be looked up in ckeys[x] table only

local stock = {}
	-- image indices: image[ stock[k] ] is drawn at coord[k]
local locat = {}
	-- keeps track where pieces (from 1 through 16) are located in the stock
	-- the identity stock[ locat[i] ] == i must hold

local alpha = {}
	-- if there is at least one matching group on the board (i.e. quarto),
	-- the other pieces on board are made transparent with a smaller alpha


local board = {}
	-- board[i] == hex[ stock[-i] ] for i = 1 to 16, so that
	-- table.concat(board) is a string representation of pieces on board
local count = 0  -- number of pieces on board
local masks = 0  -- bitmaps of matching groups or-ed together

local b_map  -- bitmap of empty places on board


local _board = ffi.new('char[?]', 16 + 1)  -- to convert the lua string

local setup = function()
	if mode >= 0 then
		-- delay initialization
		return
	end
	lib.kwarto_reset()
	ffi.copy(_board, table.concat(board))
	lib.kwarto_input_board(_board)
	masks = lib.kwarto_group_masks()  -- group data is set up here actually,
		-- _must_ be called before kwarto_solve
	if masks == 0 then
		for i = 1, 16 do
			alpha[-i] = 255
		end
	else
		local m = masks
		for i = 1, 16 do
			alpha[-i] = stock[-i] ~= 0 and bit.band(m, 1) == 0 and 85 or 255
			m = bit.rshift(m, 1)
		end
	end
end


local autom = { place = 0, piece = 0 }  -- solver's choices

local _lb = function(n)
	return math.log(n, 2)
end

local solve = function()
	if mode >= 0 then
		lib.kwarto_set_mode(mode)
		mode = mode - 2
		lib.kwarto_initialize(os.time())
		setup()
	end

	autom.place, autom.piece = 0, 0
	if masks ~= 0 then
		-- nothing to do
		return
	end
--[[
	if count == 15 then
		autom.place = _lb(b_map)
		return
	end
--]]
	local t = stock[0]
	local s = lib.kwarto_solve(t - 1)
	local p = bit.band(s, 15) + 1
	local q = bit.arshift(bit.lshift(s, 16), 20) + 1
	local r = bit.arshift(s, 16)
	if count == 15 then
		-- if the last piece is on stage and the result is a tie, q is set to 1
		-- from the return value of kwarto_solve (carelessness!), correction:
		q = 0
	end
	autom.place, autom.piece = p, q
end


local reset = function()
	-- shuffle
	locat[1] = 1
	for i = 2, 16 do
		local r = math.random(i)
		locat[r], locat[i] = i, locat[r]
	end

	-- put pieces in the real stock
	for i, l in ipairs(locat) do
		stock[l] = i
	end
	for l = -16, 0 do
		stock[l] = 0
	end

	-- restore alpha values and empty the board
	for i = 1, 16 do
		alpha[-i] = 255
		board[i] = hex[0]
	end
	-- more (re)initialization
	b_map = bit.lshift((bit.lshift(1, 16) - 1), 1)
	count = 0
	masks = 0
	autom.place, autom.piece = 0, 0
	setup()
end


local set_stage
local get_stock
local set_board

set_stage = function(t)
	-- put piece t on stage
	stock[0] = t
	locat[t] = 0
	solve()
end

get_stock = function(t)
	-- put piece t to stage (from stock)
	local l = locat[t]
	table.remove(stock, l)  -- slide left all pieces that were to the right of it
		-- (this is why stock in indexed the way it is)
	-- adjust values of locat table to hold the identity
	for k = l, table.getn(stock) do
		locat[ stock[k] ] = k
	end
	setup()
	set_stage(t)
	if count ~= 15 then
		return
	end
	set_board(_lb(b_map))  -- put the last piece to the last empty place
end

set_board = function(i)
	-- put the piece on stage to place i
	local t = stock[0]
	stock[-i], stock[0] = t, 0
	locat[t] = -i
	board[i] = hex[t]
	b_map = bit.bxor(b_map, bit.lshift(1, i))
	count = count + 1
	setup()
	if count ~= 15 or masks ~= 0 then
		return
	end
	t, stock[1] = stock[1]  -- put the last piece on stage . . .
	set_stage(t)
	set_board(_lb(b_map))  -- . . . and then to the last empty place
end


local function action(k)
	if type(k) == type(0) then
		-- a piece is possibly on the move
		local t = stock[k]
		if k == 0 and t ~= 0 then  ---- FROM STAGE TO STOCK
			table.insert(stock, t)
				-- append to the (right) end of stock . . .
			-- . . . and here is its index
			locat[t] = table.getn(stock)
			stock[0] = 0
			return
		end
		local o = stock[0]
		if k > 0 then
			if o == 0 then  ----------- FROM STOCK TO STAGE
				get_stock(t)
			end
			return
		end
		-- k < 0 from here on
		if o == 0 then
			if t ~= 0 then  ----------- FROM BOARD TO STAGE
				stock[k] = 0
				board[-k] = hex[0]
				b_map = bit.bxor(b_map, bit.lshift(1, -k))
				count = count - 1
				setup()
				set_stage(t)
			end
		elseif t == 0 then  ----------- FROM STAGE TO BOARD
			set_board(-k)
		end
		return
	end

	-- controls section
	if k == 'u' then
		-- auto move
		if masks ~= 0 or count == 16 then
			return
		end
		if stock[0] ~= 0 then
			set_board(autom.place)
		end
		if masks ~= 0 then
			return
		end
		local t = autom.piece
		if t == 0 then
			local n = table.getn(stock)
			if n == 0 then
				return
			end
			t = stock[math.random(n)]
		end
		get_stock(t)
		return
	end

	if k == 'z' then
		reset()
		return
	end

	if k == _z  then
		if mode < 0 then
			return
		end
		mode = bit.bxor(mode, 1)
		_z = string.char(bit.bxor(string.byte(_z), 1))
			-- just be thankful for string.byte('x') being even
		coord[_z], coord[k] = coord[k]
		local x, y = unpack(coord[_z])
		ckeys[x][y] = _z
		return
	end
end



local dimen_unit = 50
local dimen_half = dimen_unit*.5
local dimen_left
local scale = 1.


function love.load(a)
	if a[table.getn(a)] == '-debug' then  -- zbs
		require('mobdebug').start()
	end

	for i = 1, 16 do
		hex[i] = bit.tohex(i-1, 1)
	end
	hex[0] = '.'

	local g = love.graphics
	g.setBackgroundColor(255, 255, 225, 128)

	-- images, coordinates and static stock elements (unaffected by reset)
	local _i = function(n)
		return string.format('images/%s.png', n)
	end

	local x, y = 900, 450
	love.window.setMode(x, y, { borderless = true })
--	x, y = love.window.getMode()
	local u, h = dimen_unit, dimen_half
	x = x*.5 - u*8
	dimen_left = x
	x = x + h
	local v = y*.5 - u*4

	y = u*6 + v*2 + h
	for i = 1, 16 do
		image[i] = g.newImage(_i(hex[i]))
		coord[i] = { (i-1)*u + x, y }
	end

	y = u*5 + v*1 + h
	local i = -2
	for k in string.gmatch('ouxyz', '%a') do
		image[k] = g.newImage(_i(k))
		local l = math.floor(i*(2/3) + 3)  -- to have { 1, 2, 3, 3, 4 }
		coord[k] = { (l-1)*u + x, y }
		stock[k] = k
		i = i + 1
	end
	image[0], image.o = image.o
	coord[0], coord.o = coord.o
	stock[0], stock.o = stock.o

	for i = 1, 4 do
		local l = 1 - i
		for j = 1, 4 do
			coord[l*4 - j] = { (j-1)*u + x, i*u + h }
		end
	end

	coord.x = nil
	for k, z in pairs(coord) do
		local x, y = unpack(z)
		local t = ckeys[x] or {}
		t[y] = k
		ckeys[x] = t
		alpha[k] = 255
	end
	alpha.x = 255

	math.randomseed(os.time())
	reset()
end


function love.mousereleased(x, y, button)
	if button ~= 1 then
		return
	end
	local u, h, l = dimen_unit, dimen_half, dimen_left
	x = math.floor((x - l)/u)*u + l + h
	for v, k in pairs(ckeys[x] or {}) do
		if stock[k] and math.abs(v - y) < h then
			return action(k)
		end
	end
end


function love.draw()
	local g = love.graphics
	local h = dimen_half
	local s = scale
	for k, z in pairs(coord) do
		local i = stock[k]
		if i then
			local x, y = unpack(z)
			g.setColor(255, 255, 255, alpha[k])
			g.draw(image[i], x, y, 0, s, s, h, h)
		end
	end
	g.setColor(255, 255, 255, 255)
	love.timer.sleep(.10)  -- don't need all 60 fps
end


function love.quit()
	-- TODO stuff
end