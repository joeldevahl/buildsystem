ImportTarget("targets/linux.lua")

function Target.Execute()
	target.arch = "x86"
	target.bits = 32
	target.settings.cc.defines:Add("ARCH_X86_32")
	target.settings.cc.flags:Add("-m32")
	target.settings.link.flags:Add("-m32")
	target.settings.dll.flags:Add("-m32")
end
