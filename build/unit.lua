function Using(self, other_unit)
	table.insert(self.using_table, other_unit)
end
function UsingHeaders(self, other_unit)
	table.insert(self.usingheaders_table, other_unit)
end
function DependsOn(self, other_unit)
	table.insert(self.dependson_table, other_unit)
end
function Default(self)
	self.static_library = false
	self.shared_library = false
	self.executable = false

	self.settings = {}
end
function DefaultInit(self)
	self.static_library = true
end
function DefaultPatchHeaders(self, settings)
	settings.cc.includes:Add(PathJoin(self.path, "include"))
end
function DefaultPatch(self, settings)
	self:PatchHeaders(settings)

	if self.shared_library or self.static_library then
		settings.link.libs:Add(self.targetname)
	end
end
function DefaultBuild(self)
	local c_src = Collect(PathJoin(self.path, "src/*.c"))
	local cpp_src = Collect(PathJoin(self.path, "src/*.cpp"))
	local objc_src = Collect(PathJoin(self.path, "src/*.m"))
	if next(c_src) ~= nil or next(cpp_src) ~= nil or next(objc_src) ~= nil then
		local obj = Compile(self.settings, c_src, cpp_src, objc_src)
		if self.static_library then
			local bin = StaticLibrary(self.settings, self.targetname, obj)
		elseif self.shared_library then
			local bin = SharedLibrary(self.settings, self.targetname, obj)
		elseif self.executable then
			local bin = Link(self.settings, self.targetname, obj)
		end
	end
end

function NewUnit(path)
	unit = {}
	unit.path = path
	unit.targetname = PathBase(PathFilename(path))
	unit.static_library = false
	unit.shared_library = false
	unit.executable = false

	unit.using_table = {}
	unit.Using = Using
	unit.usingheaders_table = {}
	unit.UsingHeaders = UsingHeaders
	unit.dependson_table = {}
	unit.DependsOn = DependsOn
	unit.settings = {}

	unit.Default = Default
	unit.Init = DefaultInit
	unit.DefaultInit = DefaultInit
	unit.PatchHeaders = DefaultPatchHeaders
	unit.DefaultPatchHeaders = DefaultPatchHeaders
	unit.Patch = DefaultPatch
	unit.DefaultPatch = DefaultPatch
	unit.Build = DefaultBuild
	unit.DefaultBuild = DefaultBuild

	return unit
end
