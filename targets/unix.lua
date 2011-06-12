function Target.Execute()
	target.settings.cc.defines:Add("FAMILY_UNIX")
	target.settings.cc.defines:Add("COMPILER_GCC")
	target.settings.cc.flags:Add("-Wall")
end
