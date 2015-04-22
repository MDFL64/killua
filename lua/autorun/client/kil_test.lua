require("kil")

concommand.Add("kil_test",function()
	local env = killua.Env{
		print=print,
		pairs=pairs,
		get_n=function() return 55 end
	}

	local testCode = [[
		local n=1
		while true do
			local t = {}
			t['a']=7
			print(n,t.a)

			n=n+1
		end
	]]

	testClosure = env:digest(testCode)

	local r = SysTime()
	local testThread = killua.Thread(testClosure,function(err) print("OH NO:",err) end,10,20,30,40)
	local _,num_ops = testThread:runT(1)
	print("Executed "..num_ops.." ops in 1 second.")
end)

concommand.Add("kil_test2",function(ply)
	//PrintTable(FindMetaTable("Player"))

	local env = killua.Env(_G,{
		Player=FindMetaTable("Player")
	})

	ply.asdf="ass"
	print(">===>",ply.asdf)

	local testCode = [[
		local a = ...
		print(a)
		PrintTable(a:GetWeapons())

		PrintTable{
			eyy="lmao"
		}

		a.asdf = "dicks"


	]]

	testClosure = env:digest(testCode)
	testClosure(ply)

	print(">===>",ply.asdf)
end)