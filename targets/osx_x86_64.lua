ImportTarget("targets/osx.lua")

function Target.Execute()
	target.arch = "x86_64"
	target.bits = 64
	target.settings.cc.defines:Add("PLATFORM_OSX_X86_64")
	target.settings.cc.defines:Add("ARCH_X86")
	target.settings.cc.defines:Add("ARCH_X86_64")
	target.settings.cc.defines:Add("SIMD_SSE=3")
	target.settings.cc.flags:Add("-m64")
	target.settings.link.flags:Add("-m64")
	target.settings.dll.flags:Add("-m64")
end
