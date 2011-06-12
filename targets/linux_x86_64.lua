ImportTarget("targets/linux.lua")

function Target.Execute()
	target.arch = "x86_64"
	target.bits = 64
	target.settings.cc.defines:Add("ARCH_X86_64")
	target.settings.cc.flags:Add("-m64")
	target.settings.link.flags:Add("-m64")
	target.settings.dll.flags:Add("-m64")
end
