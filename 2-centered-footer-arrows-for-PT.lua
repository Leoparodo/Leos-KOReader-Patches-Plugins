--[[
    User patch for Project: Title plugin to center the page navigation controls.
    
    This moves the pagination controls (◄ ► and page numbers) to the center
    of the screen instead of the right or left side.
    
    To use this patch:
    1. Save this file in your KOReader patches directory
    2. Restart KOReader
--]]

local userpatch = require("userpatch")
local Menu = require("ui/widget/menu")
local updatePageInfo_orig = Menu.updatePageInfo

local function patchCoverBrowser(plugin)
    local RightContainer = require("ui/widget/container/rightcontainer")
    local TextWidget = require("ui/widget/textwidget")
    
    -- Store originals
    local RightContainer_paintTo_orig = RightContainer.paintTo
    local TextWidget_paintTo_orig = TextWidget.paintTo
    
    -- Override RightContainer.paintTo to center horizontally
    RightContainer.paintTo = function(self, bb, x, y)
        -- Check if this looks like page_info_container (width around 98% of screen)
        if self.dimen and self.dimen.w then
            local Screen = require("device").screen
            local screen_w = Screen:getWidth()
            local ratio = self.dimen.w / screen_w
            if ratio > 0.95 and ratio < 1.0 then
                -- This is the page controls, center the content horizontally
                local content_w = self[1]:getSize().w
                x = x - (self.dimen.w - content_w) / 2
            end
        end
        return RightContainer_paintTo_orig(self, bb, x, y)
    end
    
    Menu.updatePageInfo = function(self, select_number)
    self.footer_config = {
        order = {
        },
        wifi_show_disabled = true,
        frontlight_show_off = true,
    }
    updatePageInfo_orig(self, select_number)
end
    
    -- Override TextWidget.paintTo to adjust page text vertically
    TextWidget.paintTo = function(self, bb, x, y)
        -- Check if this text looks like it's the page info (contains "of")
        if self.text and type(self.text) == "string" and self.text:match("%d+%s+of%s+%d+") then
            -- Move the text down slightly
            y = y + 8
        end
        return TextWidget_paintTo_orig(self, bb, x, y)
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)