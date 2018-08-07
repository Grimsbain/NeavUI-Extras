local addon, ns = ...
ns.options = {

filterArtifactPower = true, --set to 'false' to disable the category for items that give Artifact Power

itemSlotSize = 34,	-- Size of item slots (32)
borderSize = 1,

sizes = {
	bags = {
		columnsSmall = 8, --8
		columnsLarge = 8, --10
		largeItemCount = 64,	-- Switch to columnsLarge when >= this number of items in your bags
	},
	bank = {
		columnsSmall = 12,
		columnsLarge = 14,
		largeItemCount = 96,	-- Switch to columnsLarge when >= this number of items in the bank
	},	
},

fonts = {
	-- Font to use for bag captions and other strings
	standard = {
		[[Fonts\ARIALN.ttf]], 	-- Font path
		12, 						-- Font Size
		"THINOUTLINE",	-- Flags
	},
	
	--Font to use for the dropdown menu
	dropdown = {
		[[Fonts\ARIALN.ttf]], 	-- Font path
		12, 						-- Font Size
		nil,	-- Flags
	},

	-- Font to use for durability and item level
	itemInfo = {
		[[Fonts\ARIALN.ttf]], 	-- Font path
		9, 						-- Font Size
		"THINOUTLINE",	-- Flags
	},

	-- Font to use for number of items in a stack
	itemCount = {
		[[Fonts\ARIALN.ttf]], 	-- Font path
		12, 						-- Font Size
		"THINOUTLINE",	-- Flags
	},

},

colors = {
	background = {0.05, 0.05, 0.05, 0.8},	-- r, g, b, opacity
},

}