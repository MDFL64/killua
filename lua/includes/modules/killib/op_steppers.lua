-- This code is not meant to optimized or pretty
-- It generates stepper functions for all the opcodes.

killua.op_steppers = {}

for op, meta_instructions in pairs(killua.ops) do
	local src = {"local band=bit.band local rshift=bit.rshift return function(context,bc)"}

	local function add_src(str)
		table.insert(src,str)
	end

	for _,ins in pairs(meta_instructions) do
		local mop, dst, src1, src2 = unpack(string.Explode(" ",ins))
		if mop=="ld" then
			add_src("local "..dst.." =")
			
			local loader
			if dst=="a" then
				loader="band(rshift(bc,8),255)"
			elseif dst=="b" then
				loader="rshift(bc,24)"
			elseif dst=="c" then
				loader="band(rshift(bc,16),255)"
			elseif dst=="d" then
				loader="rshift(bc,16)"
			else
				error("Bad dst.")
			end

			if src1=="lit" then
				add_src(loader)
			elseif src1=="lits" then
				add_src(loader)
				add_src("if "..dst..">=32768 then "..dst.." = "..dst.." - 65536 end")
			elseif src1=="var" then
				add_src("context.vars["..loader.."]")
			elseif src1=="num" then
				add_src("context.const["..loader.."]")
			elseif src1=="wtf" then
				add_src("context.const['wtf_'..("..loader..")]")
			elseif src1=="str" then
				add_src("context.const[-1-"..loader.."]")
			elseif src1=="tbl" then
				add_src("table.Copy(context.const[-1-"..loader.."])")
			elseif src1=="func" then
				add_src("context.env:Closure(context.const[-1-"..loader.."],context)")
			elseif src1=="pri" then
				add_src(loader)
				add_src("if "..dst.."==1 then "..dst.."=false")
				add_src("elseif "..dst.."==2 then "..dst.."=true")
				add_src("else "..dst.."=nil")
				add_src("end")
			else
				error("Bad type.")
			end
		elseif mop=="sv" then
			if dst=="nils" then
				add_src("for i=a,d do context.vars[i]=nil end")
			elseif dst=="vargs" then
				add_src("context.ret_start=a context.ret_count=b context:handleReturns(context.vargs)")
			else
				if dst=="t" then dst="{}" end
				add_src("context.vars[a] = "..dst)
			end
		elseif mop=="cmp" then
			if (dst!="eq" and dst!="neq") then
				add_src("if !isnumber(a) or !isnumber(d) then return 'Attempt to compare '..type(a)..' with '..type(d)..'.' end")
			end
			
			add_src("if !(")
			if dst=="lt" then
				add_src("a<d")
			elseif dst=="ge" then
				add_src("a>=d")
			elseif dst=="le" then
				add_src("a<=d")
			elseif dst=="gt" then
				add_src("a>d")
			elseif dst=="eq" then
				add_src("a==d")
			elseif dst=="neq" then
				add_src("a!=d")
			end
			add_src(") then context.pc=context.pc+1 end")
		elseif mop=="is" then
			if dst=="next" then
				add_src("local func =context.vars[a-3]")
				add_src("local tbl =context.vars[a-2]")
				add_src("local ctrl =context.vars[a-1]")
				add_src("local is_next = (func==next and istable(tbl) and ctrl==nil)")
				add_src("if !is_next then return 'ISNEXT assumptions wrong. Fix not implemented. When implementing, beware of possible, very unlikely fuckups when swapping out BCs.' end")
			else
				if dst=="t" then
					add_src("if !d then")
				elseif dst=="f" then
					add_src("if d then")
				end

				add_src("context.pc=context.pc+1")

				if src1=="c" then
					add_src("context.vars[a] = d")
				end

				add_src("end")
			end
		elseif mop=="un" then
			if dst=="not" then
				add_src("d = !d")
			elseif dst=="minus" then
				add_src("if !isnumber(d) then return 'Attempt to perform arithmetic on '..type(d)..'.' end")
				add_src("d = -d")
			elseif dst=="len" then
				add_src("if !istable(d) and !isstring(d) then return 'Attempt to get length of '..type(d)..'.' end")
				add_src("d = #d")
			end
		elseif mop=="math" then
			add_src("if !isnumber("..src1..") or !isnumber("..src2..") then return 'Attempt to perform arithmetic on '..type("..src1..")..' and '..type("..src2..")..'.' end")
			add_src(src1.." = "..src1)
			if dst=="add" then
				add_src("+")
			elseif dst=="sub" then
				add_src("-")
			elseif dst=="mul" then
				add_src("*")
			elseif dst=="div" then
				add_src("/")
			elseif dst=="mod" then
				add_src("%")
			elseif dst=="pow" then
				add_src("^")
			end
			add_src(src2)
		elseif mop=="cat" then
			add_src("for i=b,c do local v = context.vars[i] if (!isstring(v) and !isnumber(v)) then return 'Attempt to concat '..type(v)..'.' end end")
			add_src("b = table.concat(context.vars,'',b,c)")
		elseif mop=="uv" then
			if dst=="close" then
				//add_src("print('UV CLOSE->',a)") nop it for now
			else
				add_src("local ctx = context")
				if dst=="get" then
					add_src("local i = ctx.upvars[d+1]")
				elseif dst=="set" then
					add_src("local i = ctx.upvars[a+1]")
				end
				add_src("while i<0x8000 do ctx=ctx.parent_context i = ctx.upvars[i+1] end")
				if dst=="get" then
					//add_src("if i>=0xC000 then return 'wat '..(i-0xC000) end")
					add_src("d= ctx.parent_context.vars[i%0x4000]") //This is a guess, was i-0x8000, but that was fucking up.
				elseif dst=="set" then
					add_src("ctx.parent_context.vars[i%0x4000] = d") //Not sure if we need to change it here, doesn't seem to be subject to the same fuckuppery.. might as well.
				end
			end
		elseif mop=="tget" then
			if dst=="g" then
				dst="context.env.globals"
			else
				add_src("if !istable("..dst..") then return 'Attempt to index '..type(d)..'.' end")
			end
			add_src(src1.." = "..dst.."["..src1.."]")
		elseif mop=="tset" then
			if dst=="multi" then
				add_src("local tbl=context.vars[a-1]")
				add_src("local n = 0")
				add_src("for i=a,a+context.multres-1 do tbl[d+n]=context.vars[i] n=n+1 end")
				--add_src("print('TSETM',a,d) return '-'")
			else
				if dst=="g" then
					dst="context.env.globals"
				else
					add_src("if !istable("..dst..") then return 'Attempt to index '..type(d)..'.' end")
				end
				add_src(dst.."["..src1.."] = "..src2)
			end
		elseif mop=="jmp" then
			add_src("context.pc=context.pc+d-0x8000")
		elseif mop=="call" then
			add_src("local v = context.vars")
			local arg_end = "a+c-1"
			if dst=="iter" or dst=="next" then
				add_src("v[a] = v[a-3]")
				add_src("v[a+1] = v[a-2]")
				add_src("v[a+2] = v[a-1]")
				arg_end="a+2"
			elseif dst=="multi" then
				arg_end="a+c+context.multres"
			end
			if dst=="next" then
				add_src("local rets = {next(v[a+1],v[a+2])}")
				add_src("context.ret_start=a")
				add_src("context.ret_count=b-1")
				add_src("context:handleReturns(rets)")
			else
				add_src("local f = v[a]")
				add_src("if !isfunction(f) then return 'Attempt to call '..type(f)..'.' end")
				add_src("context.ret_start=a")
				add_src("context.ret_count=b-1")
				if dst=="tail" or src1=="tail" then
					add_src("context.tail_crush=true")
				end
				add_src("local args = {}")
				add_src("for i=a+1,"..arg_end.." do table.insert(args,v[i]) end")
				add_src("return f, args")
				//add_src("local err")
				//add_src("local rets={xpcall(f,function(e) err=e end,unpack(v,a+1,"..arg_end.."))}")
				//add_src("local success = table.remove(rets,1)")
				//add_src("if !success then return err end")
				//add_src("if context.buried then return end")
			end
			if dst=="tail" or src1=="tail" then
				//add_src("return rets")
			else
				//add_src("context:handleReturns(rets)")
			end
		elseif mop=="ret" then
			if dst=="zero" then
				add_src("return {}")
			elseif dst=="one" then
				add_src("return {a}")
			elseif dst=="multi" then
				add_src("local rets = {} for i=a,a+d+context.multres-1 do table.insert(rets,context.vars[i]) end return rets")
			else
				add_src("local rets = {} for i=a,a+d-2 do table.insert(rets,context.vars[i]) end return rets")
			end
		elseif mop=="for" then
			if dst=="iter" then
				add_src("local v = context.vars[a]")
				add_src("if v==nil then return end")
				add_src("context.vars[a-1]=v")
			else
				add_src("local start = context.vars[a]")
				add_src("local stop = context.vars[a+1]")
				add_src("local step = context.vars[a+2]")
				add_src("local i_iter = a+3")
				if dst=="init" then
					add_src("context.vars[i_iter]= start")
					add_src("if (step>0 and context.vars[i_iter]<=stop) or (step<0 and context.vars[i_iter]>=stop) then return end")
				elseif dst=="loop" then
					add_src("context.vars[i_iter]= context.vars[i_iter]+step")
					add_src("if (step>0 and context.vars[i_iter]>stop) or (step<0 and context.vars[i_iter]<stop) then return end")
				end
			end
		else
			error("idk: "..mop)
		end
	end

	add_src("end")

	killua.op_steppers[op]=CompileString(table.concat(src," "),"KIL-STEPPER-"..killua.op_names[op])()
end