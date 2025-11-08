--[[
    User patch for Project: Title plugin to center the page navigation controls.
    
    This moves the pagination controls (◄ ► and page numbers) to the center
    of the screen instead of the right or left side.
    
    To use this patch:
    1. Save this file in your KOReader patches directory
    2. Restart KOReader
--]]

local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local RightContainer = require("ui/widget/container/rightcontainer")
    local TextWidget = require("ui/widget/textwidget")
    
    -- Store originals
    local RightContainer_paintTo_orig = RightContainer.paintTo
    local TextWidget_paintTo_orig = TextWidget.paintTo
    local Menu = require("ui/widget/menu")
    local updatePageInfo_orig = Menu.updatePageInfo

    Menu.updatePageInfo = function(self, select_number)
        self.footer_config = {
            order = {
            },
            wifi_show_disabled = true,
            frontlight_show_off = true,
        }
        updatePageInfo_orig(self, select_number)
    end
    
    -- Override RightContainer.paintTo to center horizontally
    RightContainer.paintTo = function(self, bb, x, y)
        -- Check if this looks like page_info_container (width around 98% of screen)
        if self.dimen and self.dimen.w then
            local Screen = require("device").screen
            local screen_w = Screen:getWidth()
            local ratio = self.dimen.w / screen_w
            if ratio > 0.95 and ratio < 1.0 then
                -- Calculate and store the centered x position on first paint
                if not self._pt_centered_x then
                    local content_w = self[1]:getSize().w
                    self._pt_centered_x = x - (self.dimen.w - content_w) / 2
                end
                x = self._pt_centered_x
            end
        end
        return RightContainer_paintTo_orig(self, bb, x, y)
    end
    
    -- Override TextWidget.paintTo to adjust page text vertically
    TextWidget.paintTo = function(self, bb, x, y)
        -- Check if this text looks like it's the page info (contains "of")
        if self.text and type(self.text) == "string" and self.text:match("%d+%s+of%s+%d+") then
            -- Calculate and store the adjusted y position on first paint
            if not self._pt_adjusted_y then
                self._pt_adjusted_y = y + 2
            end
            y = self._pt_adjusted_y
        end
        return TextWidget_paintTo_orig(self, bb, x, y)
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
