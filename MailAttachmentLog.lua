local MailAttachmentLog = {}
MailAttachmentLog.name            = "MailAttachmentLog"
MailAttachmentLog.version         = "2.3.5.1"
MailAttachmentLog.savedVarVersion = 1
MailAttachmentLog.history         = {}
MailAttachmentLog.current_mr      = nil     -- MailRecord
MailAttachmentLog.default = {
      history = {}
}

-- Init ----------------------------------------------------------------------

function MailAttachmentLog.OnAddOnLoaded()
    if addonName ~= MailAttachmentLog.name then return end
    MailAttachmentLog:Initialize()
end

function MailAttachmentLog:Initialize()
    -- so far nothing to init
end

-- Do It ---------------------------------------------------------------------

function MailAttachmentLog:DoIt()
    -- d(":DoIt")

    self.history = {}

                        -- Rather than register/unregister over and over as we
                        -- iterate through mail, just register once at the
                        -- start and unregister once at the end.
    self:Register()

    self:FetchStart()
end

function MailAttachmentLog_DoIt()
    d("_DoIt")
    MailAttachmentLog:DoIt()
end

-- Start fetching all mail messages and their attachments.
-- It's an async fetch/callback/next cycle not a for-loop.
function MailAttachmentLog:FetchStart()
    self:FetchNext(nil)
end

function MailAttachmentLog:FetchNext(prev_mail_id)
                        -- Increment iteration.
    mail_id = GetNextMailId(prev_mail_id)
    d("fn "..tostring(mail_id))
    if not mail_id then
        d("fn done")
        return
    end
    d("fn requesting "..tostring(mail_id))
    RequestReadMail(mail_id)
    d("fn waiting " ..tostring(mail_id))
end

-- Resume from FetchNext()'s async server request for attachment data.
function MailAttachmentLog.OnMailReadable(event_id, mail_id)
    self = MailAttachmentLog
    d("omr " .. tostring(mail_id))
    self:FetchNext(mail_id)
end

-- Done fetching all mail messages and their attachments.
function MailAttachmentLog:FetchDone()
end

function MailAttachmentLog:Register()
    d("reg")
    EVENT_MANAGER:RegisterForEvent( self.name
                                  , EVENT_MAIL_READABLE
                                  , MailAttachmentLog.OnMailReadable )
end

function MailAttachmentLog:Deregister()
    d("unreg")
    EVENT_MANAGER:UnregisterForEvent( self.name
                                    , EVENT_MAIL_READABLE )
end


-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( MailAttachmentLog.name
                              , EVENT_ADD_ON_LOADED
                              , MailAttachmentLog.OnAddOnLoaded
                              )

ZO_CreateStringId("SI_BINDING_NAME_MailAttachmentLog_DoIt", "Record Mail Attachments")



--[[

Starting at keyboard MailInbox:New()
                manager:RefreshData()
    self:RefreshData()
    control:RegisterForEvent(EVENT_MAIL_INBOX_UPDATE, function() manager:OnInboxUpdate() end)
    control:RegisterForEvent(EVENT_MAIL_READABLE, function(_, mailId) manager:OnMailReadable(mailId) end)

    Done in outer loop, before any RequestReadMail()
        ZO_MailInboxShared_PopulateMailData(mailData, mailId)

function MailInbox:OnSelectionChanged(previouslySelected, selected, reselectingDuringRebuild)
    self:RequestReadMessage(selected.mailId)
    RequestReadMail(mailId)



function MailInbox:OnMailReadable(mailId)
    self.mailId = mailId
    self.messageControl:SetHidden(false)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.selectionKeybindStripDescriptor)

    local mailData = self:GetMailData(mailId)
    ZO_MailInboxShared_PopulateMailData(mailData, mailId)
    ZO_ScrollList_RefreshVisible(self.list, mailData)

    ZO_MailInboxShared_UpdateInbox(mailData, GetControl(self.messageControl, "From"), GetControl(self.messageControl, "Subject"), GetControl(self.messageControl, "Expires"), GetControl(self.messageControl, "Received"), GetControl(self.messageControl, "Body"))
    ZO_Scroll_ResetToTop(GetControl(self.messageControl, "Pane"))

    self:RefreshMoneyControls()
    self:RefreshAttachmentsHeaderShown()
    self:RefreshAttachmentSlots()

function ZO_MailInboxShared_PopulateMailData(dataTable, mailId)
    local ...  = GetMailItemInfo(mailId)

function MailInbox:RefreshAttachmentSlots()
    local mailData = self:GetMailData(self.mailId)
    local numAttachments = mailData.numAttachments
    for i = 1, numAttachments do
        self.attachmentSlots[i]:SetHidden(false)
        local icon, stack, creator = GetAttachedItemInfo(self.mailId, i)

    ]]


--[[

From sirinsidiator

local function OpenNextMail(nextMailId)
 nextMailId = GetNextMailId(nextMailId)
 if(nextMailId) then
  RequestReadMail(nextMailId)
 end
end

local function OnMailReadable(_, mailId)
 -- process attachments
 OpenNextMail(mailId)
end

EVENT_MANAGER:RegisterForEvent(EVENT_MAIL_READABLE, OnMailReadable)
OpenNextMail()

]]
