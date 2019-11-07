function Target.Execute()
	target.family = "unix"
	target.settings.cc.defines:Add("NO_DETECT_H")
	target.settings.cc.defines:Add("FAMILY_UNIX")
	target.settings.cc.defines:Add("DYNAMIC_LIBRARY_EXTENSION=\\\".so\\\"")
	target.settings.cc.defines:Add("BINARY_EXTENSION=\\\"\\\"")
	target.settings.cc.defines:Add("COMPILER_GCC") -- todo: clang?
	target.settings.cc.flags_cxx:Add("-std=c++11")
end
