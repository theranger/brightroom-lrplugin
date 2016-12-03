--
-- Created by ranger on 25.11.16.
--

local LrLogger = import "LrLogger"("Brightroom")
--LrLogger:enable("logfile")

local LrPathUtils = import "LrPathUtils"
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
	if entry == 'directory' then return end

	if entry == 'file' then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/UploadDestinationIsAFile=Cannot upload to a destination that already exists as a file.")
	end

	if entry == true then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/CannotCheckForDestination=Unable to upload because Lightroom cannot ascertain if the target destination exists.")
	end

	if not instance:makeDirectory(subPath) then
		LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/CannotMakeDirectoryForUpload=Cannot upload because Lightroom could not create the destination directory " .. subPath ..".")
	end
end

local function changeDirectory(instance, path)
	if not instance then return end
	if not path then return end

	createDirectory(instance, path)
	instance.path = instance.path .. "/" .. path
end

local function createTree(instance, path)
	local index = 0

	repeat
		createDirectory(instance, string.sub(path, 0, index))
		index = string.find(path, "/", index + 1)
	until index == nil
end

local function uploadPhoto(instance, photoPath)
	if not instance then return false end
	if not photoPath then return false end

	local filename = LrPathUtils.leafName(photoPath)
	local success = instance:putFile(photoPath, filename)

	return success
end

function BrUploadTask.processRenderedPhotos(functionContext, exportContext)
	local exportSettings = assert(exportContext.propertyTable)

	local instance = connect(exportSettings.ftpPreset)
	if instance == nil then return end

	if exportSettings.fullPath then
		createTree(instance, exportSettings.fullPath)
	end

	local collectionInfo = exportContext.publishedCollectionInfo
	for _, parent in pairs(collectionInfo.parents) do
		changeDirectory(instance, parent.name)
	end

	changeDirectory(instance, collectionInfo.name)

	for i, rendition in exportContext:renditions{ stopIfCanceled = true } do
		local success, pathOrMessage = rendition:waitForRender()

		if success then
			uploadPhoto(instance, pathOrMessage)
		end
	end

	instance:disconnect()
end
