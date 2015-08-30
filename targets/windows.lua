function Target.Execute()
	target.family = "windows"
	target.settings.cc.defines:Add("NO_CORE_DETECT_H")
	target.settings.cc.defines:Add("FAMILY_WINDOWS")
	target.settings.cc.defines:Add("COMPILER_MSVC")
	target.settings.cc.defines:Add("SIMD_SSE=3")
	target.settings.cc.flags:Add("/FS")
end
