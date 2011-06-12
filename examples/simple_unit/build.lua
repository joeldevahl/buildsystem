Unit:Using("another_unit") -- will pull in another_unit and all dependencies

-- overridden Init to mark this unit as both lib and bin
function Unit.Init(self)
	self.executable = true
	self.static_library = true
	self.targetname = "simple"
end

-- PatchHeaders not overridden, "./include" will be added as include dir

-- Patch not overridden, targetname will be added as lib to any unit that uses this unit

-- overridden Build to output lib and bin
function Unit.Build(self)
	local libsrc = {
		PathJoin(self.path, "src/simple.c")
	}
	local binsrc = {
		PathJoin(self.path, "src/main.c")
	}

	local libobj = Compile(self.settings, libsrc)
	local binobj = Compile(self.settings, binsrc)
	local lib = StaticLibrary(self.settings, self.targetname, libobj)
	local bin = Link(self.settings, "simple", libobj, binobj)
end
