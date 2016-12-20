function Step.Init(self)
	DefaultUnit.project_guid = ""
end

local function GenerateGUID()
	local template ='{xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx}'
	local res = string.gsub(template, '[xy]', function (c)
		local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
	end)
	return string.upper(res)
end

function Step.PostBuild(self)
	if not engine.projgen then
		return
	end

	local sln = io.open(engine.project_name .. ".sln", "w")

	sln:write("Microsoft Visual Studio Solution File, Format Version 12.00\n")
	sln:write("VisualStudioVersion = 14.0.25420.1\n")
	sln:write("MinimumVisualStudioVersion = 10.0.40219.1\n")

	-- TODO: use folders for units/externals/applications
	for name,unit in pairs(engine.units) do
		unit.project_guid = GenerateGUID()

		local prj = io.open(name .. ".vcxproj", "w")

		prj:write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
		prj:write("<Project DefaultTargets=\"Build\" ToolsVersion=\"14.0\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">\n")
		prj:write("  <ItemGroup Label=\"ProjectConfigurations\">\n")
		prj:write("	<ProjectConfiguration Include=\"Debug|x64\">\n")
		prj:write("	  <Configuration>Debug</Configuration>\n")
		prj:write("	  <Platform>x64</Platform>\n")
		prj:write("	</ProjectConfiguration>\n")
		prj:write("	<ProjectConfiguration Include=\"Release|x64\">\n")
		prj:write("	  <Configuration>Release</Configuration>\n")
		prj:write("	  <Platform>x64</Platform>\n")
		prj:write("	</ProjectConfiguration>\n")
		prj:write("  </ItemGroup>\n")
		prj:write("  <PropertyGroup Label=\"Globals\">\n")
		prj:write("	<ProjectGuid>" .. unit.project_guid .. "</ProjectGuid>\n")
		prj:write("	<Keyword>MakeFileProj</Keyword>\n")
		prj:write("	<WindowsTargetPlatformVersion>10.0.14393.0</WindowsTargetPlatformVersion>\n")
		prj:write("  </PropertyGroup>\n")
		prj:write("  <Import Project=\"$(VCTargetsPath)\\Microsoft.Cpp.Default.props\" />\n")
		prj:write("  <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Debug|x64'\" Label=\"Configuration\">\n")
		prj:write("	<ConfigurationType>Makefile</ConfigurationType>\n")
		prj:write("	<UseDebugLibraries>true</UseDebugLibraries>\n")
		prj:write("	<PlatformToolset>v140</PlatformToolset>\n")
		prj:write("  </PropertyGroup>\n")
		prj:write("  <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Release|x64'\" Label=\"Configuration\">\n")
		prj:write("	<ConfigurationType>Makefile</ConfigurationType>\n")
		prj:write("	<UseDebugLibraries>false</UseDebugLibraries>\n")
		prj:write("	<PlatformToolset>v140</PlatformToolset>\n")
		prj:write("  </PropertyGroup>\n")
		prj:write("  <Import Project=\"$(VCTargetsPath)\\Microsoft.Cpp.props\" />\n")
		prj:write("  <ImportGroup Label=\"ExtensionSettings\">\n")
		prj:write("  </ImportGroup>\n")
		prj:write("  <ImportGroup Label=\"Shared\">\n")
		prj:write("  </ImportGroup>\n")
		prj:write("  <ImportGroup Label=\"PropertySheets\" Condition=\"'$(Configuration)|$(Platform)'=='Debug|x64'\">\n")
		prj:write("	<Import Project=\"$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props\" Condition=\"exists('$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props')\" Label=\"LocalAppDataPlatform\" />\n")
		prj:write("  </ImportGroup>\n")
		prj:write("  <ImportGroup Label=\"PropertySheets\" Condition=\"'$(Configuration)|$(Platform)'=='Release|x64'\">\n")
		prj:write("	<Import Project=\"$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props\" Condition=\"exists('$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props')\" Label=\"LocalAppDataPlatform\" />\n")
		prj:write("  </ImportGroup>\n")
		prj:write("  <PropertyGroup Label=\"UserMacros\" />\n")
		prj:write("  <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Debug|x64'\">\n")
		prj:write("	<NMakeBuildCommandLine>bam -v debug</NMakeBuildCommandLine>\n") -- TODO: only build this project?
		prj:write("	<NMakeCleanCommandLine>bam -c</NMakeCleanCommandLine>\n")
		prj:write("  </PropertyGroup>\n")
		prj:write("  <PropertyGroup Condition=\"'$(Configuration)|$(Platform)'=='Release|x64'\">\n")
		prj:write("	<NMakeBuildCommandLine>bam -v release</NMakeBuildCommandLine>\n") -- TODO: only build this project
		prj:write("	<NMakeCleanCommandLine>bam -c</NMakeCleanCommandLine>\n")
		prj:write("  </PropertyGroup>\n")
		prj:write("  <ItemDefinitionGroup>\n")
		prj:write("  </ItemDefinitionGroup>\n")

		local sources = CollectRecursive(unit.path .. "/*.c", unit.path .. "/*.cpp", unit.path .. "/*.cc") -- TODO: configure this from the unit
		prj:write("  <ItemGroup>\n")
		for _,f in ipairs(sources) do
			prj:write("	<ClCompile Include=\"" .. f .. "\" />\n")
		end
		prj:write("  </ItemGroup>\n")

		local includes = CollectRecursive(unit.path .. "/*.h", unit.path .. "/*.hpp") -- TODO: configure this from the unit
		prj:write("  <ItemGroup>\n")
		for _,f in ipairs(includes) do
			prj:write("	<ClInclude Include=\"" .. f .. "\" />\n")
		end
		prj:write("  </ItemGroup>\n")

		local others = CollectRecursive(unit.path .. "/*.lua") -- TODO: configure this from the unit
		prj:write("  <ItemGroup>\n")
		for _,f in ipairs(others) do
			prj:write("	<None Include=\"" .. f .. "\" />\n")
		end
		prj:write("  </ItemGroup>\n")
		

		prj:write("  <Import Project=\"$(VCTargetsPath)\\Microsoft.Cpp.targets\" />\n")
		prj:write("  <ImportGroup Label=\"ExtensionTargets\">\n")
		prj:write("  </ImportGroup>\n")
		prj:write("</Project>\n")

		sln:write("Project(\"{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}\") = \"" .. name  .. "\", \"" .. name .. ".vcxproj\", \"" .. unit.project_guid .. "\"\nEndProject\n")
	end

	sln:write("Global\n")

	sln:write("\tGlobalSection(SolutionConfigurationPlatforms) = preSolution\n")
	sln:write("\t\tDebug|x64 = Debug|x64\n")
	sln:write("\t\tRelease|x64 = Release|x64\n")
	sln:write("\tEndGlobalSection\n")

	sln:write("\tGlobalSection(ProjectConfigurationPlatforms) = postSolution\n")
	for name,unit in pairs(engine.units) do
		sln:write("\t\t\"" .. unit.project_guid .. "\".Debug|x64.ActiveCfg = Debug|x64\n")
		sln:write("\t\t\"" .. unit.project_guid .. "\".Release|x64.ActiveCfg = Release|x64\n")
	end
	sln:write("\tEndGlobalSection\n")

	sln:write("\tGlobalSection(ProjectConfigurationPlatforms) = postSolution\n")
	sln:write("\t\tHideSolutionNode = FALSE\n")
	sln:write("\tEndGlobalSection\n")

	sln:write("EndGlobal\n")

	sln:close(sln)
end
