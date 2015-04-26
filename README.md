# killua
A LuaJIT VM written in GLua.

##Applications
 - **Sandboxing**: You can sandbox stuff pretty easily with this. It has entirely seperate metatables for each environment, so you don't have to worry about people using those pesky metamethods. You can also limit scripts to a certain number of operations, or just split execution up between a number of frames if you feel like it. I don't recommend using it to sandbox entire addons, because there is a lot of overhead, but it could be really good for E2 esque stuff.
 - **Obfuscation**: I do not recommend this by any means, but if you wanted to be a real dick you could theoretically obfuscate all your code with this. Again, there will be quite a big slowdown, but it might be worth it depending on your project.
 - **Debugging**: This is another thing you can do but probably shouldn't, but you could probably use it to make a full featured Lua debugger.
 
 ##Future Stuff
 - Address really obscure edge cases
 - Use varargs consistently throughout the code
 - Add memory/allocation qoutas
 - Recompile to protected/unprotected lua
 - Bytecode analysis
