--#########################################################################################
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2014 INPE and TerraLAB/UFOP -- www.terrame.org
--
-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.
--
-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this library and its documentation.
--
-- Authors: Pedro R. Andrade
--          Raian Vargas Maretto
--#########################################################################################

--@header Functions to work with packages in TerraME.

--- Return the path to a file of a given package. The file must be inside the folder data
-- within the package.
-- @arg filename A string with the name of the file.
-- @arg package A string with the name of the package. As default, it uses paciage base.
-- @usage cs = CellularSpace{database = file("simple.map")}
function file(filename, package)
	if package == nil then package = "base" end

	local s = sessionInfo().separator
	local file = packageInfo(package).data..s..filename
	if isFile(file) or isDir(file) then
		return file
	else
		customError("File '"..file.."' does not exist in package '"..package.."'.")
	end
end

--- Return a table with the files of a package that have a given extension. 
-- @arg package A string with the name of the package.
-- @arg extension A string with the extension.
-- @usage filesByExtension("base", "csv")
function filesByExtension(package, extension)
	mandatoryArgument(1, "string", package)
	mandatoryArgument(2, "string", extension)

	local size = string.len(extension)
	local result = {}

	forEachFile(packageInfo(package).data, function(file)
		if string.sub(file, -size) == extension then
			table.insert(result, string.sub(file, 1, -size - 1))
		end
	end)

	return result
end

--- Load a given package. If the package is not installed, it tries to load from
-- a folder in the current directory.
-- @arg package A package name.
-- @usage -- DONTRUN
-- import("calibration")
function import(package)
	mandatoryArgument(1, "string", package)

	if isLoaded(package) then
		customWarning("Package '"..package.."' is already loaded.")
	else
		local s = sessionInfo().separator
		local package_path = packageInfo(package).path

		_Gtme.verifyDepends(package)

		local load_file = package_path..s.."load.lua"
		local all_files = dir(package_path..s.."lua")
		local load_sequence

		if isFile(load_file) then -- SKIP
			xpcall(function() load_sequence = _Gtme.include(load_file) end, function(err)
				_Gtme.customError("Package '"..package.."' could not be loaded:"..err) -- SKIP
			end)

			verifyUnnecessaryArguments(load_sequence, {"files"})

			load_sequence = load_sequence.files -- SKIP
			if load_sequence == nil then -- SKIP
				_Gtme.printError("Package '"..package.."' could not be loaded.")
				_Gtme.printError("load.lua should declare table 'files', with the order of the files to be loaded.")
				os.exit() -- SKIP
			elseif type(load_sequence) ~= "table" then
				_Gtme.printError("Package '"..package.."' could not be loaded.")
				_Gtme.printError("In load.lua, 'files' should be table, got "..type(load_sequence)..".")
				os.exit() -- SKIP
			end
		else
			load_sequence = all_files -- SKIP
		end

		local count_files = {}
		for _, file in ipairs(all_files) do
			count_files[file] = 0 -- SKIP
		end

		local i, file

		if load_sequence then -- SKIP
			for _, file in ipairs(load_sequence) do
				local mfile = package_path..s.."lua"..s..file
				if not isFile(mfile) then -- SKIP
					customWarning("Cannot open "..mfile..". No such file. Please check "..package_path..s.."load.lua.") -- SKIP
				else
					local merror
					xpcall(function() dofile(mfile) end, function(err)
						merror = "Package '"..package.."' could not be loaded: "..err -- SKIP
					end)

					if merror then -- SKIP
						_Gtme.customError(merror) -- SKIP
					end

					count_files[file] = count_files[file] + 1 -- SKIP
				end
			end
		end

		for mfile, count in pairs(count_files) do
			local attr = attributes(package_path..s.."lua"..s..mfile, "mode")
			if count == 0 and attr ~= "directory" then -- SKIP
				customWarning("File lua"..s..mfile.." is ignored by load.lua.") -- SKIP
			elseif count > 1 then
				customWarning("File lua"..s..mfile.." is loaded "..count.." times in load.lua.") -- SKIP
			end
		end

		local files = _Gtme.fontFiles(package)
		forEachElement(files, function(_, file)	
			if not _Gtme.loadedFonts[file] then -- SKIP
				cpp_loadfont(package_path..s.."font"..s..file) -- SKIP
				_Gtme.loadedFonts[file] = true -- SKIP
			end
		end)

		if package == "base" then -- SKIP
			cpp_setdefaultfont() -- SKIP
		end

		rawset(_G, "font", function(data)	
			_Gtme.fonts[data.name] = data.symbol -- SKIP
		end)

		if isFile(package_path..s.."font.lua") then -- SKIP
			dofile(package_path..s.."font.lua")
		end

		font = nil -- SKIP

		_Gtme.loadedPackages[package] = true -- SKIP
	end
end

--- Return whether a given package is loaded.
-- @arg package A string with the name of the package.
-- @usage if isLoaded("base") then
--     print("is loaded")
-- end
function isLoaded(package)
	mandatoryArgument(1, "string", package)
	return _Gtme.loadedPackages[package] == true
end

--- Return a table with the content of a given package. If the package is not
-- installed, it tries to load from a folder in the current directory.
-- @arg pname A package name.
-- @usage base = getPackage("base")
-- cs = base.CellularSpace{xdim = 10}
function getPackage(pname)
	mandatoryArgument(1, "string", pname)

	local s = sessionInfo().separator
	local pname_path = packageInfo(pname).path

	_Gtme.verifyDepends(pname)

	local load_file = pname_path..s.."load.lua"
	local all_files = dir(pname_path..s.."lua")
	local load_sequence

	if isFile(load_file) then -- SKIP
		xpcall(function() load_sequence = _Gtme.include(load_file) end, function(err)
			_Gtme.printError("Package '"..pname.."' could not be loaded.")
			_Gtme.print(err)
		end)

		verifyUnnecessaryArguments(load_sequence, {"files"})

		load_sequence = load_sequence.files -- SKIP
		if load_sequence == nil then -- SKIP
			_Gtme.printError("Package '"..pname.."' could not be loaded.")
			_Gtme.printError("load.lua should declare table 'files', with the order of the files to be loaded.")
			os.exit() -- SKIP
		elseif type(load_sequence) ~= "table" then
			_Gtme.printError("Package '"..pname.."' could not be loaded.")
			_Gtme.printError("In load.lua, 'files' should be table, got "..type(load_sequence)..".")
			os.exit() -- SKIP
		end
	else
		load_sequence = all_files -- SKIP
	end

	local count_files = {}
	for _, file in ipairs(all_files) do
		count_files[file] = 0 -- SKIP
	end

	local i, file

	local overwritten = {}

	local mt = getmetatable(_G)
	setmetatable(_G, {}) -- to avoid warnings: "Variable 'xxx' is not declared."

	local result = setmetatable({}, {__index = _G, __newindex = function(t, k, v)
		if _G[k] then
			overwritten[k] = true
		end
		rawset(t, k, v)
	end})

	if load_sequence then -- SKIP
		for _, file in ipairs(load_sequence) do
			local mfile = pname_path..s.."lua"..s..file
			if not isFile(mfile) then -- SKIP
				_Gtme.printError("Cannot open "..mfile..". No such file.")
				_Gtme.printError("Please check "..pname_path.."load.lua")
				os.exit() -- SKIP
			end

			local lf = loadfile(mfile, 't', result)

 			if lf == nil then
				collectgarbage() -- SKIP
				lf = loadfile(mfile, 't', result) -- SKIP

				if lf == nil then -- SKIP
					_Gtme.printError("Could not load file "..mfile..".")
					dofile(mfile) -- this line will show the error when parsing the file
				end
			end

			lf()

			count_files[file] = count_files[file] + 1 -- SKIP
		end
	end

	for mfile, count in pairs(count_files) do
		local attr = attributes(pname_path.."lua"..s..mfile, "mode")
		if count == 0 and attr ~= "directory" then -- SKIP
			_Gtme.printWarning("File lua"..s..mfile.." is ignored by load.lua.")
		elseif count > 1 then
			_Gtme.printWarning("File lua"..s..mfile.." is loaded "..count.." times in load.lua.")
		end
	end

	setmetatable(_G, mt)
	return result, overwritten
end

--- Return the description of a package. This function tries to find the package in the TerraME
-- installation folder. If it does not exist then it checks wether the package is available in the
-- current directory. If the package does not exist then it stops with an error. Otherwise, it reads
-- file description.lua and returns the following attributes.
-- @tabular NONE
-- Attribute & Description \
-- authors & Name of the author(s) of the package.\
-- contact & E-mail of one or more authors. \
-- content & A description of the package. \
-- data & The path to folder data of the package. This attribute is added
-- by this function as it does not exist in description.lua.\
-- date & Date of the current version.\
-- depends & A comma-separated list of package names which this package depends on.\
-- license & Name of the package's license. \
-- package & Name of the package.\
-- path & Folder where the package is stored in the computer.\
-- title & Optional title for the HTML documentation of the package.\
-- url & An optional variable with a webpage of the package.\
-- version & Current version of the package, in the form <number>[.<number>]*.
-- For example: 1, 0.2, 2.5.2.
-- @arg package A string with the name of the package. If nil, packageInfo will return
-- the description of TerraME.
-- @usage str = packageInfo().version
-- print(str)
function packageInfo(package)
	if package == nil or package == "terrame" then
		package = "base"
	end

	mandatoryArgument(1, "string", package)

	local s = sessionInfo().separator
	local pkgfolder = sessionInfo().path..s.."packages"..s..package
	if not isDir(pkgfolder) then
		if isDir(package) then
			pkgfolder = package -- SKIP
		else
			customError("Package '"..package.."' is not installed.")
		end
	end
	
	local file = pkgfolder..s.."description.lua"
	
	local result 
	xpcall(function() result = _Gtme.include(file) end, function(err)
		_Gtme.printError(err)
		os.exit() -- SKIP
	end)

	if result == nil then
		customError("Could not read description.lua") -- SKIP
	end

	result.path = pkgfolder
	result.data = pkgfolder..s.."data"

	if result.depends then
		local s = string.gsub(result.depends, "([%w]+ %(%g%g %d[.%d]+%))", function(v)
			return ""
		end)

		if s ~= "" then -- SKIP
			s = string.gsub(s, "%, ", function(v)
				return ""
			end)
		end

		if s ~= "" then -- SKIP
			customError("Wrong description of 'depends' in description.lua of package '"..package.."'. Unrecognized '"..s.."'.")
		end

		local mdepends = {}
		s = string.gsub(result.depends, "([%w]+) %((%g%g) (%d[.%d]+)%)", function(value, v2, v3)
			local mversion = _Gtme.getVersion(v3) -- SKIP
			table.insert(mdepends, {package = value, operator = v2, version = mversion})
		end)

		result.tdepends = mdepends
	end

	return result
end
