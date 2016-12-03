--
-- Created by ranger on 25.11.16.
--

local LrLogger = import "LrLogger"("Brightroom")
--LrLogger:enable("logfile")

local LrFileUtils = import "LrFileUtils"
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
	instance.path = LrFtp.appendFtpPaths(instance.path, path)
end

local function createTree(instance, path)
	local index = 0

	repeat
		createDirectory(instance, string.sub(path, 0, index))
		index = string.find(path, "/", index + 1)
	until index == nil
end

local function uploadPhoto(instance, photoPath, remoteName)
	if not instance then return false end
	if not photoPath then return false end

	local success = instance:putFile(photoPath, remoteName)
	return success
end

local function deletePhoto(instance, photoPath)
	if not instance then return end
	if not photoPath then return end

	instance:removeFile(photoPath)
end

local function deleteCollection(instance, path)
	if path == "." or path == ".." then return end

	local originalPath = instance.path
	instance.path = LrFtp.appendFtpPaths(instance.path, path)

	local entry = instance:exists("")
	if entry == false then return end

	local contents = instance:getContents("/")
	for type, token in string.gmatch(contents, "(.).-:%d%d%s(.-)%c") do
		if type == "d" then deleteCollection(instance, token) end
		if type == "-" then instance:removeFile(token) end
	end

	instance.path = originalPath
	instance:removeDirectory(path)
end

function BrUploadTask.processRenderedPhotos(functionContext, exportContext)
	local exportSettings = assert(exportContext.propertyTable)
	local exportSession = exportContext.exportSession

	local instance = connect(exportSettings.ftpPreset)
	if instance == nil then return end

	local count = exportSession:countRenditions()
	local progress = exportContext:configureProgress {
		title = count > 1
				and LOC("$$$/Brightroom/Publish/Progress=Publishing ^1 photos to Brightroom", count)
				or LOC "$$$/Brightroom/Publish/Progress/One=Publishing one photo to Brightroom",
	}

	if exportSettings.fullPath then
		createTree(instance, exportSettings.fullPath)
	end

	local collectionInfo = exportContext.publishedCollectionInfo
	for _, parent in pairs(collectionInfo.parents) do
		changeDirectory(instance, parent.name)
	end

	changeDirectory(instance, collectionInfo.name)
	exportSession:recordRemoteCollectionId(instance.path)

	for i, rendition in exportContext:renditions{ stopIfCanceled = true } do
		progress:setPortionComplete(i / count)

		local success, pathOrMessage = rendition:waitForRender()
		if progress:isCanceled() then break end

		if success then
			local filename = LrPathUtils.leafName(pathOrMessage)

			if uploadPhoto(instance, pathOrMessage, filename) then
				local remotePath = LrFtp.appendFtpPaths(instance.path, filename)
				LrFileUtils.delete(pathOrMessage)
				rendition:recordPublishedPhotoId(remotePath)
			end
		end
	end

	instance:disconnect()
end

function BrUploadTask.deletePhotosFromPublishedCollection(publishSettings, arrayOfPhotoIds, deletedCallback, localCollectionId)
	local instance = connect(publishSettings.ftpPreset)
	if instance == nil then return end

	for _, photoID in ipairs(arrayOfPhotoIds) do
		deletePhoto(instance, photoID)
		deletedCallback(photoID)
	end
end

function BrUploadTask.renamePublishedCollection(publishSettings, info)
	LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/FtpRenameUnsupported=Renaming collections is unsupported by FTP provider.")
end

function BrUploadTask.reparentPublishedCollection(publishSettings, info)
	LrErrors.throwUserError(LOC "$$$/Brightroom/Upload/Errors/FtpMoveUnsupported=Moving collections is unsupported by FTP provider.")
end

function BrUploadTask.deletePublishedCollection(publishSettings, info)
	local instance = connect(publishSettings.ftpPreset)
	if instance == nil then return end

	deleteCollection(instance, info.remoteId)
end
