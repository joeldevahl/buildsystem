function Target.Execute()
	target.family = "unix"
	target.settings.cc.defines:Add("NO_CORE_DETECT_H")
	target.settings.cc.defines:Add("FAMILY_UNIX")
	target.settings.cc.defines:Add("COMPILER_GCC")
end
