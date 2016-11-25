--
-- Created by ranger on 25.11.16.
--

return {
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 1.3,
	LrToolkitIdentifier = "eu.brightroom.plugin",

	LrPluginName = LOC "$$$/Brightroom/PluginName=Brightroom",

	LrExportServiceProvider = {
		title = "Brightroom",
		file = "BrPublishServiceProvider.lua",
	},

	VERSION = { major=0, minor=1, revision=0, build=0, },
}
