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
    local LeftContainer = require("ui/widget/container/leftcontainer")
    local TextWidget = require("ui/widget/textwidget")
    
    -- Store originals
    local RightContainer_paintTo_orig = RightContainer.paintTo
    local LeftContainer_paintTo_orig = LeftContainer.paintTo
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
                local logger = require("logger")
                local content_w = self[1]:getSize().w
                logger.info("PT Patch RIGHT: x=", x, "screen_w=", screen_w, "content_w=", content_w, "dimen.w=", self.dimen.w)
                
                -- Calculate the offset needed to center
                if not self._pt_offset then
                    self._pt_offset = -(self.dimen.w - content_w) / 2
                    logger.info("PT Patch RIGHT: Calculated offset=", self._pt_offset)
                end
                x = x + self._pt_offset
                logger.info("PT Patch RIGHT: Final x=", x)
            end
        end
        return RightContainer_paintTo_orig(self, bb, x, y)
    end
    
    -- Override LeftContainer.paintTo to center horizontally  
    LeftContainer.paintTo = function(self, bb, x, y)
        -- Check if this looks like page_info_container (width around 98% of screen)
        if self.dimen and self.dimen.w then
            local Screen = require("device").screen
            local screen_w = Screen:getWidth()
            local ratio = self.dimen.w / screen_w
            if ratio > 0.95 and ratio < 1.0 then
                local logger = require("logger")
                local content_w = self[1]:getSize().w
                logger.info("PT Patch LEFT: x=", x, "screen_w=", screen_w, "content_w=", content_w, "dimen.w=", self.dimen.w)
                
                -- Calculate the offset needed to center
                if not self._pt_offset then
                    -- For LeftContainer, we need to add to move it right toward center
                    self._pt_offset = (screen_w - self.dimen.w - content_w) / 2
                    logger.info("PT Patch LEFT: Calculated offset=", self._pt_offset)
                end
                x = x + self._pt_offset
                logger.info("PT Patch LEFT: Final x=", x)
            end
        end
        return LeftContainer_paintTo_orig(self, bb, x, y)
    end
    
    -- Override TextWidget.paintTo to adjust page text vertically
    TextWidget.paintTo = function(self, bb, x, y)
        -- Check if this text looks like it's the page info (contains "of")
        -- AND check if y position suggests it's in the footer (bottom of screen)
        if self.text and type(self.text) == "string" and self.text:match("%d+%s+of%s+%d+") then
            local Screen = require("device").screen
            local screen_h = Screen:getHeight()
            -- Only adjust if it's in the bottom 15% of screen (footer area)
            if y > screen_h * 0.85 then
                -- Move the text down slightly
                y = y + 2
            end
        end
        return TextWidget_paintTo_orig(self, bb, x, y)
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
