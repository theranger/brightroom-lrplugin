--
-- Created by ranger on 25.11.16.
--

local LrErrors = import "LrErrors"
local LrFtp = import "LrFtp"

BrUploadTask = {}

local function connect(ftpPreset)
	if ftpPreset == nil then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/FTPPresetNotFound=FTP preset not found, aborting...")
	end

	if not LrFtp.queryForPasswordIfNeeded(ftpPreset) then return nil end

	local instance = LrFtp.create(ftpPreset, true)
	if not instance then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/InvalidFtpParameters=The specified FTP preset is incomplete and cannot be used.")
	end

	return instance
end

local function createDirectory(instance, subPath)
	if not instance then return end
	if not subPath or subPath == '' then return end

	local entry = instance:exists(subPath)
	if exists == 'directory' then return end

	if exists == 'file' then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/UploadDestinationIsAFile=Cannot upload to a destination that already exists as a file.")
	end

	if exists == true then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/CannotCheckForDestination=Unable to upload because Lightroom cannot ascertain if the target destination exists.")
	end

	if not instance:makeDirectory(subPath) then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/CannotMakeDirectoryForUpload=Cannot upload because Lightroom could not create the destination directory.")
	end
end

local function createTree(instance, path)
	local index = 0

	repeat
		createDirectory(instance, string.sub(path, 0, index))
		index = string.find(path, "/", index + 1)
	until index == nil
end

function BrUploadTask.processRenderedPhotos(functionContext, exportContext)
	local exportSettings = assert(exportContext.propertyTable)

	local instance = connect(exportSettings.ftpPreset)
	if instance == nil then return end

	if exportSettings.fullPath then
		createTree(instance, exportSettings.fullPath)
	end

	instance:disconnect()
end
