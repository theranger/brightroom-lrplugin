--
-- Created by ranger on 25.11.16.
--

local LrErrors = import "LrErrors"
local LrFtp = import "LrFtp"

BrUploadTask = {}

local function connect(ftpPreset)
	if not LrFtp.queryForPasswordIfNeeded(ftpPreset) then return nil end

	local instance = LrFtp.create(ftpPreset)
	if not instance then
		LrErrors.throwUserError( LOC "$$$/FtpUpload/Upload/Errors/InvalidFtpParameters=The specified FTP preset is incomplete and cannot be used." )
	end

end

function BrUploadTask.processRenderedPhotos(ctxFunciton, ctxExport)
	local instance = connect(ctxExport.propertyTable.ftpPreset)
	if instance == nil then return end

	instance:disconnect()
end
