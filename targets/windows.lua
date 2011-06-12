function Target.Execute()
	target.settings.cc.defines:Add("PLATFORM_WINDOWS")
	target.settings.cc.defines:Add("COMPILER_MSVC")
end
