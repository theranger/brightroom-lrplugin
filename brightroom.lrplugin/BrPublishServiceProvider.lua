--
-- Created by ranger on 25.11.16.
--

require "BrPublishDialog"
require "BrUploadTask"

return {
	supportsIncrementalPublish = "only",

	hideSections = { "exportLocation" },
	allowFileFormats = { "JPEG" },
	hidePrintResolution = true,
	canExportVideo = false,

	exportPresetFields = {
		{ key = "ftpPreset", default = nil },
	},

	sectionsForTopOfDialog = BrPublishDialog.sectionsForTopOfDialog,
	startDialog = BrPublishDialog.startDialog,
	processRenderedPhotos = BrUploadTask.processRenderedPhotos,
	deletePhotosFromPublishedCollection = BrUploadTask.deletePhotosFromPublishedCollection,
	renamePublishedCollection = BrUploadTask.renamePublishedCollection,
	reparentPublishedCollection = BrUploadTask.reparentPublishedCollection,
}
