--
-- Created by ranger on 25.11.16.
--

local LrView = import "LrView"
local LrFtp = import "LrFtp"

BrPublishDialog = {}

local function setError(propertyTable, message)
	if message == nil then
		propertyTable.message = nil
		propertyTable.hasError = false
		propertyTable.hasNoError = true
		propertyTable.LR_cantExportBecause = nil
	else
		propertyTable.message = message
		propertyTable.hasError = true
		propertyTable.hasNoError = false
		propertyTable.LR_cantExportBecause = message
	end
end

local function validateProperties(propertyTable)
	setError(propertyTable, nil)

	if propertyTable.ftpPreset == nil then
		setError(propertyTable, LOC "$$$/FtpUpload/ExportDialog/Messages/SelectPreset=Select or Create an FTP preset")
		return
	end

end

function BrPublishDialog.startDialog(propertyTable)
	propertyTable:addObserver("ftpPreset", validateProperties)
	validateProperties(propertyTable)
end

function BrPublishDialog.sectionsForTopOfDialog(f, propertyTable)
	local share = LrView.share

	local ret =	{
		title = LOC "$$$/Brightroom/ExportDialog/FtpSettings=FTP Server",

		f:row {
			f:static_text {
				title = LOC "$$$/Brightroom/ExportDialog/Destination=Destination:",
				alignment = "right",
				width = share "labelWidth"
			},

			LrFtp.makeFtpPresetPopup {
				factory = f,
				properties = propertyTable,
				valueBinding = "ftpPreset",
				itemsBinding = "items",
				fill_horizontal = 1,
			},
		},
	}

	return { ret }
end


