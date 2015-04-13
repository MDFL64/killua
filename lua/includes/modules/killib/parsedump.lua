function killua.parseDump(dump)
	local i = 1
	local function readStr(len)
		local temp = dump:sub(i,i+len-1)
		i=i+len
		return temp
	end

	local function readByte()
		local temp = dump:byte(i)
		i=i+1
		return temp
	end

	local function readShort()
		local b1,b2 = dump:byte(i,i+1)
		i=i+2
		return b2*256+b1
	end

	local function readLong()
		local b1,b2,b3,b4 = dump:byte(i,i+3)
		i=i+4
		return b4*16777216+b3*65536+b2*256+b1
	end

	local function readULEB128()
		local b = readByte()
		local n = bit.band(b,127)
		local shift=0
		while b>=128 do
			shift=shift+7
			b=readByte()
			n=n+bit.lshift(bit.band(b,127),shift)
		end
		return n
	end

	-- Komm, süsser Tod
	local function readULEB128_WTF()
		local n = readULEB128()
		local dubs = n%2==1
		n = bit.rshift(n,1)
		if dubs then
			local hi = readULEB128()
			local exp = bit.rshift(hi,20)
			local frac = n+bit.band(hi,1048575)*2^32 --lshift doesn't seem to work for really big numbers.

			frac = 1+(frac/(0xFFFFFFFFFFFFF))
			exp = exp - 1023

			local rebuilt
			if bit.band(exp,2^11)>0 then --negative
				exp = exp - 2^11
				return -math.ldexp(frac,exp), n
			else
				return math.ldexp(frac,exp), n
			end
		else
			return n, n
		end
	end

	local function readTableItem()
		local item_type = readULEB128()
		if item_type==0 then
			return nil
		elseif item_type==1 then
			return false
		elseif item_type==2 then
			return true
		elseif item_type==3 then
			return readULEB128()
		elseif item_type==4 then
			error("tabitem num")
		else
			return readStr(item_type-5)
		end
	end

	if readStr(3)!="\x1BLJ" then
		error("Function dump format incorrect. Something went very badly wrong!")
	end

	if readByte()!=1 then
		error("Function dump version incorrect. This shouldn't ever actually happen!")
	end

	local chunk_flags = readULEB128()
	local chunk_name = readStr(readULEB128()) //(blen+10)

	//Protos
	local proto_queue = {}
	while true do
		local proto_len = readULEB128()
		if proto_len==0 then break end

		local proto = {}

		local proto_flags = readByte()
		proto.vargs = bit.band(proto_flags,2)==2

		local proto_nParams = readByte()
		proto.nvars = readByte()
		local proto_nUpvars = readByte()

		proto.nargs = proto_nParams

		local proto_nConst_gc = readULEB128()
		local proto_nConst_nums = readULEB128()
		local proto_bcLen = readULEB128()

		local proto_dbg_len = readULEB128()

		local proto_dbg_firstLine = readULEB128()
		local proto_dbg_lineCount = readULEB128()

		proto.code = {}
		for i=1,proto_bcLen do
			table.insert(proto.code,readLong()) //todo fuck the header?
		end
		
		proto.upvars={}
		for i=1,proto_nUpvars do
			table.insert(proto.upvars,readShort())
			//print("UPVAR PLZ",readShort()) //2 bytes per
		end // local slot|0x8000 or parent uv idx

		proto.const = {}
		for i=-proto_nConst_gc,-1 do
			local const_type = readULEB128()
			if const_type==0 then
				proto.const[i]=table.remove(proto_queue,1) //TODO not sure if a stack or queue
			elseif const_type==1 then
				local size_array = readULEB128()
				local size_hash = readULEB128()
				
				local t = {}
				for i=1,size_array do
					table.insert(t,readTableItem())
				end

				for i=1,size_hash do
					local k = readTableItem()
					local v = readTableItem()
					t[k] = v
				end

				proto.const[i]=t
			elseif const_type==2 then
				//i64
				error("const type")
			elseif const_type==3 then
				//u64
				//error("const type")
				print(readULEB128())
				print(readULEB128())
				proto.const[i]=666
				error("const type")
			elseif const_type==4 then
				//complex
				error("const type")
			else
				proto.const[i]=readStr(const_type-5)
			end
		end

		for i=1,proto_nConst_nums do
			proto.const[i-1], proto.const["wtf_"..(i-1)] =readULEB128_WTF()
		end

		//PrintTable(proto.const)

		for i=1,proto_dbg_len do
			readByte() //idk lol
		end

		table.insert(proto_queue,proto)
	end

	local main = table.remove(proto_queue,1)
	
	return main
end