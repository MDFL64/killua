-- A function context. This is the core and most basic building block of the Killua VM
-- It represents a single function call on the stack.
local KIL_CONTEXT = {}
KIL_CONTEXT.__index = KIL_CONTEXT

-- Makes a context from a proto, parent context, and env.
local function NEW_CONTEXT(closure_tbl)
	local self = {}
	self.code = closure_tbl.proto.code
	self.const = closure_tbl.proto.const
	self.nargs = closure_tbl.proto.nargs
	--self.nvars = proto.nvars
	self.upvars = closure_tbl.proto.upvars
	self.env = closure_tbl.env
	self.parent_context = closure_tbl.parent_context
	if closure_tbl.proto.vargs then
		self.vargs = {}
	end
	self.vars = {}
	self.pc = 1
	setmetatable(self,KIL_CONTEXT)
	return self
end

local band  = bit.band

-- VM stepper function. Return:
	-- table of return values	-OR-
	-- function to call			-OR-
	-- string upon error		-OR-
	-- nil if situation normal
function KIL_CONTEXT:step()
	local bc = self.code[self.pc]

	local op = band(bc,255)

	local stepper = killua.op_steppers[op]

	if !stepper then
		local name = killua.op_names[op]
		return "Opcode unimplemented: #"..op.." "..(name or "?")
	end

	local r, args = stepper(self,bc)

	self.pc = self.pc + 1

	return r, args
end

function KIL_CONTEXT:handleReturns(rets)
	local start = self.ret_start
	local count = self.ret_count

	self.ret_start=nil
	self.ret_count=nil

	if count<=0 then
		local i = start
		for _,v in pairs(rets) do
			self.vars[i]=v
			i=i+1
		end
		self.multres = i-start
	else
		local i2 = 1
		for i=start,start+count-1 do //-2 or -1? wtf
			self.vars[i]=rets[i2]
			i2=i2+1
		end
	end
end

-- A thread is a wrapper around a stack of contexts.
-- An optional error callback can be provided, otherwise real errors are thrown.
local KIL_THREAD = {}
KIL_THREAD.__index = KIL_THREAD

local function NEW_THREAD(error_callback)
	local self = {}
	self.stack = {}
	self.error_callback = error_callback
	self.error_msg = false -- or string if error
	self.return_tbl = false -- or table if completed
	setmetatable(self,KIL_THREAD)
	return self
end

-- Advance the thread a single step by calling the underlying context's step method.
-- Handle errors if applicable.
-- Return true if finished OR errored
function KIL_THREAD:step()
	if !self.top then return true end

	local r, args = self.top:step()

	if r==nil then return end

	if isfunction(r) then
		self:call(r,args)
		return
	elseif istable(r) then
		return self:pop(r)
	else
		self:error(r)
	end

	return true
end

-- Attempt to finish the thread
-- Optional argument for number of steps, default nil=infinite
-- Pass 0 if you just want a return value.
-- Throw error (via handler if applicable) and return nil if could not complete in specified amount of steps.
function KIL_THREAD:complete(n)
	if n==nil then n=math.huge end
	/*if n==0 then
		if istable(self.return_tbl) then

		end
	end*/
	if !self:run(n) then
		if !self.error_msg then self:error("Thread completion failed.") end
		return
	end
	return unpack(self.return_tbl)
end

-- Runs for a specified amount of steps, or until finished.
-- Step count is required.
-- Return true if finished
function KIL_THREAD:run(n)
	for i=1,n do
		if self:step() then return istable(self.return_tbl) end
	end
	return istable(self.return_tbl)
end

-- Runs for a specified amount of time. Returns true if finished + number of ops executed
-- This is mainly for benchmarking!
function KIL_THREAD:runT(t)
	local n=0
	local tStart = SysTime()
	while (SysTime()-tStart)<t do
		if self:step() then return istable(self.return_tbl),n+1 end
		n=n+1
	end
	return istable(self.return_tbl),n
end

-- Sends an error to the error handler, or throws it if none exists.
function KIL_THREAD:error(msg)
	self.top = nil
	self.error_msg = msg
	if self.error_callback then
		self.error_callback(msg)
	else
		error(msg)
	end
end

-- Try to do a call. Works on both 
function KIL_THREAD:call(f,args)
	local closure_tbl = killua.closures[f]
	if closure_tbl then
		self:push(closure_tbl,unpack(args))
	else
		local rets = {pcall(f,unpack(args))}
		local success = table.remove(rets,1)
		
		if !success then
			self:error(rets[1])
			return
		end

		if self.top and self.top.tail_crush then
			self.top = table.remove(self.stack)
		end

		if self.top then
			self.top:handleReturns(rets)
		else
			self.return_tbl = rets
		end

		//error('lmao')
	end
	//print(f,args)
	//error("eyy")
end

-- Push a context with some args
function KIL_THREAD:push(closure_tbl,...)
	local context = NEW_CONTEXT(closure_tbl)

	local args = {...}
	local i=1
	while i<=#args and i<=context.nargs do
		context.vars[i-1]=args[i]
		i=i+1
	end
	if context.vargs then
		while i<=#args do
			table.insert(context.vargs,args[i])
			i=i+1
		end
	end

	if self.top and !self.top.tail_crush then
		table.insert(self.stack,self.top)
	end
	self.top = context
end

-- Pops a context from the stack
-- Returns true if there are no more contexts
function KIL_THREAD:pop(return_tbl)
	if #self.stack>0 then
		self.top = table.remove(self.stack)
		self.top:handleReturns(return_tbl)
	else
		self.top=nil
		self.return_tbl = return_tbl
		return true
	end
end

-- A set of globals, essentially a single VM instance. This is the only object you should directly be instanciating.
local KIL_ENV = {}
KIL_ENV.__index = KIL_ENV

-- Make a new env. Can pass a table -OR- getter/setter functions.
local function NEW_ENV(index1,index2)
	local self = {}
	if istable(index1) then
		self.globals = index1
	elseif isfunction(index1) and isfunction(index2) then
		self.globals = {}
		setmetatable(self.globals,{__index=index1,__newindex=index2})
	else
		error("Invalid parameters for new env.")
	end
	setmetatable(self,KIL_ENV)
	return self
end

-- Makes a kil closure from a proto table and parent context.
function KIL_ENV:Closure(proto,parent_context)
	local closure_tbl = {proto=proto,parent_context=parent_context,env=self}
	local f = function(...)
		local t = NEW_THREAD()
		t:push(closure_tbl,...)
		return t:complete()
	end
	killua.closures[f]=closure_tbl
	return f
end

-- Wraps a code string, function, or bytecode string in a kil closure. Returns the result.
-- If there was some kind of compile error, return an error string instead.
-- If you screwed up worse than that it will throw a real error.
function KIL_ENV:digest(code)
	-- Compile Lua
	if isstring(code) and code:sub(1 ,3)!="\x1BLJ" then
		code=CompileString(code,"[Kil]",false)
		if isstring(code) then
			return code
		end
	end

	-- Dump function
	if isfunction(code) then
		code=string.dump(code)
	end

	-- Undump function
	if isstring(code) and code:sub(1 ,3)=="\x1BLJ" then
		code = killua.parseDump(code)
	else
		error("Invalid parameter for digest.")
	end

	-- Convert the proto to a kil closure
	return self:Closure(code)
end

killua = {}

killua.closures = {}
setmetatable(killua.closures,{__mode="k"})

killua.Env = NEW_ENV

-- Safely calls killua closures. Wraps normal functions in a pcall so error_callback still works.
-- Note that this insta-calls normal functions.
function killua.Thread(f,error_callback,...)
	local t = NEW_THREAD(error_callback)
	t:call(f,{...})
	return t
end

include("killib/parsedump.lua")
include("killib/ops.lua")
include("killib/op_steppers.lua")