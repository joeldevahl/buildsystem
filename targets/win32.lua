ImportTarget("targets/windows.lua")

function Target.Execute()
	target.arch = "x86"
	target.bits = 32
	target.settings.cc.defines:Add("ARCH_X86_32")
	target.settings.link.flags:Add("/MACHINE:X86")
end
