DefaultUnit                     = {}
DefaultUnit.name                = nil
DefaultUnit.path                = nil
DefaultUnit.targetname          = nil
DefaultUnit.settings            = {}

function NewUnit(name, path)
	local unit = TableDeepCopy(DefaultUnit)
	unit.name = name
	unit.path = path
	unit.targetname = PathBase(PathFilename(path))
	return unit
end
