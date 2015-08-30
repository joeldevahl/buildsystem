ImportTarget("targets/linux.lua")

function Target.Execute()
	target.arch = "x86_64"
	target.bits = 64
	target.platform = "linux_x86_64"
	target.settings.cc.defines:Add("PLATFORM_LINUX")
	target.settings.cc.defines:Add("PLATFORM_LINUX_X86_64")
	target.settings.cc.defines:Add("ARCH_X86_64")
	target.settings.cc.defines:Add("ARCH_X86_32")
	target.settings.cc.defines:Add("SIMD_SSE=3")
end
