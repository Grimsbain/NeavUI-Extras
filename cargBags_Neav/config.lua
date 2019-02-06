local addon, ns = ...

ns.options = {
    itemSlotSize = 34,
    borderSize = 1,

    fonts = {
        -- Font to use for bag captions and other strings.
        standard = { [[Fonts\ARIALN.ttf]], 12, "OUTLINE" },

        --Font to use for the dropdown menu
        dropdown = { [[Fonts\ARIALN.ttf]], 12, nil },

        -- Font to use for durability and item level
        itemInfo = { [[Fonts\ARIALN.ttf]], 9, "OUTLINE" },

        -- Font to use for number of items in a stack
        itemCount = { [[Fonts\ARIALN.ttf]], 12, "OUTLINE" },
    },

    -- r, g, b, opacity
    colors = {
        background = {0.05, 0.05, 0.05, 0.8},
    },
}