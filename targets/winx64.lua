ImportTarget("targets/windows.lua")

function Target.Execute()
	target.arch = "x86_64"
	target.bits = 64
	target.platform = "winx64"
	target.settings.cc.defines:Add("WIN32")
	target.settings.cc.defines:Add("PLATFORM_WINX64")
	target.settings.cc.defines:Add("ARCH_X86")
	target.settings.cc.defines:Add("ARCH_X86_64")
	target.settings.lib.flags:Add("/MACHINE:X64")
	target.settings.dll.flags:Add("/MACHINE:X64")
	target.settings.link.flags:Add("/MACHINE:X64")
end
