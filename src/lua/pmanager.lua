-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2016 INPE and TerraLAB/UFOP -- www.terrame.org

-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.

-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this software and its documentation.
--
-------------------------------------------------------------------------------------------

local comboboxExamples
local comboboxModels
local comboboxPackages
local comboboxProjects
local aboutButton
local configureButton
local projButton
local docButton
local installLocalButton
local installButton
local quitButton
local runButton
local dialog
local oldState

local function breakLines(str)
	local result = ""
	local lineWidth = 50
	local lines = 1

	spaceLeft = lineWidth

	words = {}
	for word in str:gmatch("%g+") do table.insert(words, word) end

	forEachElement(words, function(_, word)
    	if string.len(word) + 1 > spaceLeft then
			result = result.."\n"..word.." "
			lines = lines + 1
			spaceLeft = lineWidth - string.len(word)
    	else
			result = result..word.." "
        	spaceLeft = spaceLeft - (string.len(word) + 1)
		end
	end)
	return result, lines
end

local function disableAll()
	oldState = {
		[comboboxExamples] = comboboxExamples.enabled,
		[comboboxModels]   = comboboxModels.enabled,
		[comboboxProjects] = comboboxProjects.enabled,
		[projButton]       = projButton.enabled,
		[docButton]        = docButton.enabled,
		[configureButton]  = configureButton.enabled,
		[runButton]        = runButton.enabled
	}

	comboboxExamples.enabled   = false
	comboboxModels.enabled     = false
	comboboxPackages.enabled   = false
	comboboxProjects.enabled   = false
	aboutButton.enabled        = false
	configureButton.enabled    = false
	projButton.enabled         = false
	docButton.enabled          = false
	installLocalButton.enabled = false
	installButton.enabled      = false
	quitButton.enabled         = false
	runButton.enabled          = false
end

local function enableAll()
	comboboxExamples.enabled = oldState[comboboxExamples]
	comboboxModels.enabled   = oldState[comboboxModels]
	comboboxProjects.enabled   = oldState[comboboxProjects]
	configureButton.enabled  = oldState[configureButton]
	projButton.enabled       = oldState[projButton]
	docButton.enabled        = oldState[docButton]
	runButton.enabled        = oldState[runButton]

	comboboxPackages.enabled   = true
	aboutButton.enabled        = true
	installLocalButton.enabled = true
	installButton.enabled      = true
	quitButton.enabled         = true
end

local function buildComboboxPackages(default)
	comboboxPackages:clear()
	local pos = 0
	local index = 0
	local pkgDir = sessionInfo().path.."packages"
	forEachDirectory(pkgDir, function(dir)
		if dir:name() == "luadoc" then return end
	
		qt.combobox_add_item(comboboxPackages, dir:name())
	
		if file == default then
			index = pos
		else
			pos = pos + 1
		end
	end)

	return index
end

local function aboutButtonClicked()
	disableAll()
	local msg = "Package "..comboboxPackages.currentText
	local info = packageInfo(comboboxPackages.currentText)

	msg = msg.."\n\nVersion: "..tostring(info.version)
	msg = msg.."\n\nAuthors: "..tostring(info.authors)
	msg = msg.."\n\nContact: "..tostring(info.contact)

	if info.url then
		msg = msg.."\n\nURL: "..info.url
	end

	qt.dialog.msg_about(msg)
	enableAll()
end

local function docButtonClicked()
	disableAll()
	_Gtme.showDoc(comboboxPackages.currentText)
	enableAll()
end

local function configureButtonClicked()
	disableAll()

    local ok, res = _Gtme.execConfigure(comboboxModels.currentText, comboboxPackages.currentText)
    if not ok then
       qt.dialog.msg_critical(res)
    end	
	
	enableAll()
end

local function runButtonClicked()
	disableAll()

    local ok, res = _Gtme.execExample(comboboxExamples.currentText, comboboxPackages.currentText)
    if not ok then
       qt.dialog.msg_critical(res)
    end

	enableAll()
end

local function projButtonClicked()
	disableAll()

	local ok, res = _Gtme.execProject(comboboxProjects.currentText, comboboxPackages.currentText)
	if not ok then
		qt.dialog.msg_critical(res)
	end

	enableAll()
end

-- what to do when a new package is selected
local function selectPackage()
	local s = sessionInfo().separator
	comboboxExamples:clear()
	comboboxModels:clear()
	local models

	local result = xpcall(function() getPackage(comboboxPackages.currentText) end, function(err)
		sessionInfo().fullTraceback = true
		local trace = _Gtme.traceback(err)
		local merr = "Error: Package '"..comboboxPackages.currentText.."' could not be loaded:\n\n"..trace

		qt.dialog.msg_critical(merr)
	end)

	if result then
		result = xpcall(function() models = _Gtme.findModels(comboboxPackages.currentText) end, function(err)
			sessionInfo().fullTraceback = true
			local trace = _Gtme.traceback(err)
			local merr = "Error: Package '"..comboboxPackages.currentText.."' could not be loaded:\n\n"..trace
	
			qt.dialog.msg_critical(merr)
		end)
	end

	if not result then
		comboboxModels.enabled = false
		configureButton.enabled = false
		comboboxExamples.enabled = false
		runButton.enabled = false
		projButton.enabled = false
		docButton.enabled = false
		return
	end

	local docpath = packageInfo(comboboxPackages.currentText).path
	docpath = docpath.."doc"..s.."index.html"

	docButton.enabled = File(docpath):exists()

	comboboxModels.enabled = #models > 1
	configureButton.enabled = #models > 0

	forEachElement(models, function(_, value)
		qt.combobox_add_item(comboboxModels, value)
	end)

	local ex = _Gtme.findExamples(comboboxPackages.currentText)

	comboboxExamples.enabled = #ex > 1
	runButton.enabled = #ex > 0

	forEachElement(ex, function(_, value)
		qt.combobox_add_item(comboboxExamples, value)
	end)

	local files = _Gtme.projectFiles(comboboxPackages.currentText)

	comboboxProjects.enabled = #files > 1
	projButton.enabled = #files > 0

	forEachElement(files, function(_, value)
		local _, file = value:split()
		qt.combobox_add_item(comboboxProjects, file)
	end)
end

local function installButtonClicked()
	disableAll()

	local packages = _Gtme.downloadPackagesList()

	if getn(packages) == 0 then
		local msg = "Could not download the packages list. "..
		            "Please verify your internet connection and try again. "..
		            "If it still does not work, close and open TerraME again."
		qt.dialog.msg_critical(msg)
		enableAll()
		return
	end

	local pkgsTab = {}

	local mdialog = qt.new_qobject(qt.meta.QDialog)
	mdialog.windowTitle = "Download and install package"

	local externalLayout = qt.new_qobject(qt.meta.QVBoxLayout)

	qt.ui.layout_add(mdialog, externalLayout)

	local listPackages = qt.new_qobject(qt.meta.QListWidget)
	local hasPackageToInstall = false
	
	local setPackagesListWidget = function(pkgs)
		listPackages:clear()
		local count = 0
		forEachOrderedElement(pkgs, function(idx, data)
			data.file = data.package.."_"..data.version..".zip"
			data.newversion = true

			pkgsTab[count] = data

			local ok, info = pcall(function() return packageInfo(idx) end)
			local package = idx

			if ok then
				pkgs[info.package].currentVersion = info.version

				if _Gtme.verifyVersionDependency(info.version, ">=", data.version) then
					package = package.." (already installed)"
					pkgsTab[count].newversion = false
				else
					package = package.." (version "..data.version.." available)"
					hasPackageToInstall = true
				end
			elseif not hasPackageToInstall then
				hasPackageToInstall = true
			end

			count = count + 1
			qt.listwidget_add_item(listPackages, package)
		end)
	end
	
	setPackagesListWidget(packages)

	local installButton2 = qt.new_qobject(qt.meta.QPushButton)
	installButton2.text = "Install"
	installButton2.enabled = false
	
	local installAllButton = qt.new_qobject(qt.meta.QPushButton)
	installAllButton.text = "Install All"
	installAllButton.enabled = hasPackageToInstall
	
	local cancelButton = qt.new_qobject(qt.meta.QPushButton)
	cancelButton.text = "Cancel"
	qt.connect(cancelButton, "clicked()", function()
		mdialog:done(0)
	end)	
	
	local installRecursive
	installRecursive = function(pkgfile)
		local installed = {}
		_Gtme.print("Downloading "..pkgfile)
		_Gtme.downloadPackage(pkgfile)
		_Gtme.print("Installing "..pkgfile)
		local package = string.sub(pkgfile, 1, string.find(pkgfile, "_") - 1)

		os.execute("unzip -oq \""..pkgfile.."\"")

		_Gtme.print("Verifying dependencies")

		local pinfo = packageInfo(package)

		if pinfo.tdepends then
			forEachElement(pinfo.tdepends, function(_, dtable)
				if dtable.package == "terrame" or dtable.package == "base" then return end

				_Gtme.print("Package depends on "..dtable.package)
				local isInstalled = pcall(function() packageInfo(dtable.package) end)

				if not isInstalled then
					if not installRecursive(packages[dtable.package].file) then
						return false
					end

					installed[dtable.package] = true
					return true
				end
			end)
		end

		local status, err = pcall(function() _Gtme.installPackage(pkgfile) end)

		if not status then
			qt.dialog.msg_critical("File "..pkgfile.." could not be installed:\n"..err)
			return false
		end

		return true, installed
	end	
	
	qt.connect(installButton2, "clicked()", function()
		installButton2.enabled = false
		installAllButton.enabled = false
		cancelButton.enabled = false
		disableAll()
		
		local tmpdirectory = _Gtme.Directory{tmp = true}
		local cdir = currentDir()

		tmpdirectory:setCurrentDir()

		local mpkgfile = pkgsTab[listPackages.currentRow].file
		local result, installed = installRecursive(mpkgfile)
		local package = string.sub(mpkgfile, 1, string.find(mpkgfile, "_") - 1)

		if result then
			local msg = "Package '"..package.."' successfully installed."

			if _Gtme.getn(installed) == 1 then
				msg = msg.." One additional dependency package was installed:"
			elseif _Gtme.getn(installed) > 1 then
				msg = msg.." Additional dependency packages were installed:"
			end

			if _Gtme.getn(installed) > 0 then
				forEachOrderedElement(installed, function(idx)
					msg = msg.."\n- "..idx
				end)
			end

			qt.dialog.msg_information(msg)

			local index = buildComboboxPackages(package)
			comboboxPackages:setCurrentIndex(index)
			selectPackage()
			disableAll()
		else
			qt.dialog.msg_critical("Package '"..package.."' could not be installed.")
		end

		File(mpkgfile):delete()

		cdir:setCurrentDir()
		tmpdirectory:delete()
		setPackagesListWidget(packages)
		installAllButton.enabled = hasPackageToInstall
		cancelButton.enabled = true
	end)
	
	qt.connect(installAllButton, "clicked()", function()
		installAllButton.enabled = false
		installButton2.enabled = false
		cancelButton.enabled = false
		disableAll()
		
		local tmpdirectory = _Gtme.Directory{tmp = true}
		local cdir = currentDir()

		tmpdirectory:setCurrentDir()
		
		local msg = ""
		
		for i = 0, _Gtme.getn(pkgsTab) - 1 do
			if pkgsTab[i].newversion then
				local mpkgfile = pkgsTab[i].file
				local result, _ = installRecursive(mpkgfile)
				local package = string.sub(mpkgfile, 1, string.find(mpkgfile, "_") - 1)

				if result then
					if msg ~= "" then
						msg = msg.."\n"
					end
					
					msg = msg.."Package '"..package.."' successfully installed."
				else
					qt.dialog.msg_critical("Package '"..package.."' could not be installed.")
				end

				File(mpkgfile):delete()
				setPackagesListWidget(packages)	
			end
		end
		
		if msg ~= "" then
			qt.dialog.msg_information(msg)
		end
		
		cdir:setCurrentDir()
		tmpdirectory:delete()		
		cancelButton.enabled = true
	end)	

	local description = qt.new_qobject(qt.meta.QLabel)
	description.text = "Select a package"..
		"\n\t\t\t\t\t\t\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

	qt.connect(listPackages, "itemClicked(QListWidgetItem*)", function()
		installButton2.enabled = pkgsTab[listPackages.currentRow].newversion

		local idx = pkgsTab[listPackages.currentRow].file

        local sep = string.find(idx, "_")
        local package = string.sub(idx, 1, sep - 1)

		local lines = 0

		local text = packages[package].title.."\n"
		lines = lines + 1

		local mtext, mlines = breakLines(packages[package].content)
		lines = lines + mlines
		text = text.."\n"..mtext
		text = text.."\n\t\t\t\t\t\t"
		lines = lines + 2

		text = text.."\nNewest version: "..packages[package].version
		lines = lines + 1

		if packages[package].currentVersion then
			text = text.."\nInstalled version: "..packages[package].currentVersion
			lines = lines + 1
		end

		mtext, mlines = breakLines("Author(s): "..packages[package].authors)
		lines = lines + mlines
		text = text.."\n"..mtext

		if packages[package].depends then
			mtext, mlines = breakLines("Depends: "..packages[package].depends)
			lines = lines + mlines
			text = text.."\n"..mtext
		end

		while lines < 16 do
			text = text.."\n"
			lines = lines + 1
		end

		description.text = text
	end)

	internalLayout = qt.new_qobject(qt.meta.QHBoxLayout)

	qt.ui.layout_add(internalLayout, listPackages)
	qt.ui.layout_add(internalLayout, description)

	qt.ui.layout_add(externalLayout, internalLayout)

	internalLayout = qt.new_qobject(qt.meta.QHBoxLayout)
	qt.ui.layout_add(internalLayout, installButton2)
	qt.ui.layout_add(internalLayout, installAllButton)
	qt.ui.layout_add(internalLayout, cancelButton)

	qt.ui.layout_add(externalLayout, internalLayout)
	mdialog:show()
	mdialog:exec()
	enableAll()
end
	
local function installLocalButtonClicked()
	disableAll()
	local s = sessionInfo().separator
	local fname = qt.dialog.get_open_filename("Select Package", "", "*.zip")
	if fname == "" then
		enableAll()
		return
	end

	local file = _Gtme.makePathCompatibleToAllOS(fname)
	local _, pfile = string.match(file, "(.-)([^/]-([^%.]+))$") -- remove path from the file
	local package

	xpcall(function() package = string.sub(pfile, 1, string.find(pfile, "_") - 1) end, function()
		qt.dialog.msg_information(file.." is not a valid file name for a TerraME package.")
	end)

	if not package then
		enableAll()
		return
	end

	local currentVersion
	local packageDir = _Gtme.sessionInfo().path.."packages"
	if Directory(packageDir..s..package):exists() then
		currentVersion = packageInfo(package).version
		_Gtme.printNote("Package '"..package.."' is already installed")
	else
		_Gtme.printNote("Package '"..package.."' was not installed before")
	end

	local tmpdirectory = _Gtme.Directory{tmp = true}

	os.execute("cp \""..file.."\" \""..tostring(tmpdirectory).."\"")
	tmpdirectory:setCurrentDir()

	os.execute("unzip -oq \""..file.."\"")

	local newVersion = _Gtme.include(package..s.."description.lua").version

	if currentVersion then
		if not _Gtme.verifyVersionDependency(newVersion, ">=", currentVersion) then
			local msg = "New version ("..newVersion..") is older than current one ("
				..currentVersion..").".."\nDo you really want to install "
				.."an older version of package '"..package.."'?"
			local ok = 1024
			local cancel = 4194304

			if qt.dialog.msg_question(msg, "Confirm?", ok + cancel, cancel) == ok then
				_Gtme.printNote("Removing previous version of package")
				Directory(packageDir..s..package):delete()
			else
				tmpdirectory:delete()
				enableAll()
				return
			end
		end
	end

	local pkg = xpcall(function() _Gtme.installPackage(fname) end, function(err)
		qt.dialog.msg_critical("File "..fname.." could not be installed:\n"..err)
	end)

	if pkg then
		local ok = true
		xpcall(function() getPackage(package) end, function(err)
			packageInfo(package).path:delete()
			qt.dialog.msg_critical(err)
			ok = false
		end)

		if ok then
			qt.dialog.msg_information("Package '"..package.."' successfully installed.")
			local index = buildComboboxPackages(package)
			comboboxPackages:setCurrentIndex(index)
			selectPackage()
			disableAll()
		end
	end

	enableAll()
end

local function quitButtonClicked()
	dialog:done(0)
end

function _Gtme.packageManager()
    _Gtme.loadLibraryPath()

	require("qtluae")

	dialog = qt.new_qobject(qt.meta.QDialog)
	dialog.windowTitle = "TerraME"

	local externalLayout = qt.new_qobject(qt.meta.QVBoxLayout)
	local internalLayout = qt.new_qobject(qt.meta.QGridLayout)
	internalLayout.spacing = 8

	qt.ui.layout_add(dialog, externalLayout)

	comboboxPackages = qt.new_qobject(qt.meta.QComboBox)

	aboutButton = qt.new_qobject(qt.meta.QPushButton)
	aboutButton.text = "About"
	qt.connect(aboutButton, "clicked()", aboutButtonClicked)

	docButton = qt.new_qobject(qt.meta.QPushButton)
	docButton.text = "Documentation"
	qt.connect(docButton, "clicked()", docButtonClicked)

	label = qt.new_qobject(qt.meta.QLabel)
	label.text = "Package:"
	qt.ui.layout_add(internalLayout, label,            0, 0)
	qt.ui.layout_add(internalLayout, comboboxPackages, 0, 1)
	qt.ui.layout_add(internalLayout, aboutButton,      0, 2)
	qt.ui.layout_add(internalLayout, docButton,        0, 3)

	-- models list + execute button
	comboboxModels = qt.new_qobject(qt.meta.QComboBox)

	label = qt.new_qobject(qt.meta.QLabel)
	label.text = "Model:"

	configureButton = qt.new_qobject(qt.meta.QPushButton)
	configureButton.text = "Configure"
	qt.connect(configureButton, "clicked()", configureButtonClicked)

	qt.ui.layout_add(internalLayout, label,           1, 0)
	qt.ui.layout_add(internalLayout, comboboxModels,  1, 1)
	qt.ui.layout_add(internalLayout, configureButton, 1, 2)

	-- examples list + execute button
	comboboxExamples = qt.new_qobject(qt.meta.QComboBox)

	label = qt.new_qobject(qt.meta.QLabel)
	label.text = "Example:"

	runButton = qt.new_qobject(qt.meta.QPushButton)
	runButton.text = "Run"
	qt.connect(runButton, "clicked()", runButtonClicked)

	qt.ui.layout_add(internalLayout, label,            2, 0)
	qt.ui.layout_add(internalLayout, comboboxExamples, 2, 1)
	qt.ui.layout_add(internalLayout, runButton,        2, 2)

	-- projects list + execute button
	comboboxProjects = qt.new_qobject(qt.meta.QComboBox)

	label = qt.new_qobject(qt.meta.QLabel)
	label.text = "Project:"

	projButton = qt.new_qobject(qt.meta.QPushButton)
	projButton.text = "Create"
	qt.connect(projButton, "clicked()", projButtonClicked)

	qt.ui.layout_add(internalLayout, label,            3, 0)
	qt.ui.layout_add(internalLayout, comboboxProjects, 3, 1)
	qt.ui.layout_add(internalLayout, projButton,       3, 2)

	local index = buildComboboxPackages("base")
	comboboxPackages:setCurrentIndex(index)

	qt.connect(comboboxPackages, "activated(int)", selectPackage)

	buttonsLayout = qt.new_qobject(qt.meta.QHBoxLayout)

	installButton = qt.new_qobject(qt.meta.QPushButton)
	installButton.minimumSize = {150, 28}
	installButton.maximumSize = {160, 28}
	installButton.text = "Install package"
	qt.ui.layout_add(buttonsLayout, installButton)

	qt.connect(installButton, "clicked()", installButtonClicked)

	installLocalButton = qt.new_qobject(qt.meta.QPushButton)
	installLocalButton.minimumSize = {150, 28}
	installLocalButton.maximumSize = {160, 28}
	installLocalButton.text = "Install local package"
	qt.ui.layout_add(buttonsLayout, installLocalButton)

	qt.connect(installLocalButton, "clicked()", installLocalButtonClicked)

	quitButton = qt.new_qobject(qt.meta.QPushButton)
	quitButton.minimumSize = {100, 28}
	quitButton.maximumSize = {110, 28}
	quitButton.text = "Quit"
	qt.ui.layout_add(buttonsLayout, quitButton)

	qt.connect(quitButton, "clicked()", quitButtonClicked)

	qt.ui.layout_add(externalLayout, internalLayout)
	qt.ui.layout_add(externalLayout, buttonsLayout, 4, 0)

	selectPackage()
	dialog:show()
	dialog:exec()
end

