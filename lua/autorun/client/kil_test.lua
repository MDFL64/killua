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
			print(n)
			n=n+1
		end
	]]

	testClosure = env:digest(testCode)

	local r = SysTime()
	local testThread = killua.Thread(testClosure,function(err) print("OH NO:",err) end,10,20,30,40)
	local _,num_ops = testThread:runT(1)
	print("Executed "..num_ops.." ops in 1 second.")
end)