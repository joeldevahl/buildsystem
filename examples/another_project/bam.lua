-- Assume there is a project in <dir>/base_lib that uses the build system.
-- This project can then be imported into <dir>/project by using the folowing
-- code in <dir>/project/bam.lua

Import("../base_lib/bam.lua")
Init()
AddUnitsInDir("units") -- will import units in <dir>/project/units
Build()
