local tablesrc = ""
local jobs = {}

local skip = false
for k,v in ipairs(ScriptArgs) do
	if not skip then
		if v == "-o" then
			tablesrc = ScriptArgs[k + 1]
			skip = true
		else
			print(v)
			table.insert(jobs, v)
		end
	else
		skip = false
	end
end

local file = io.open(tablesrc, "w")
file:write("#include <job/system.h>\n\n")
for _,job in pairs(jobs) do
	local name = PathBase(PathFilename(job))
	file:write("void " .. name .. "(void* ptr);\n")
end
file:write("\n")
file:write("const job_ptr_descriptor_t job_table[] = {\n")
for _,job in pairs(jobs) do
	local name = PathBase(PathFilename(job))
	file:write("\t{ " .. name .. ", \"" .. name .."\" },\n")
end
file:write("\t{ 0, 0 },\n")
file:write("};\n\n")
io.close(file)
