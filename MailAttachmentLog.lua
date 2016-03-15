local MailAttachmentLog = {}
MailAttachmentLog.name            = "MailAttachmentLog"
MailAttachmentLog.version         = "2.3.5.1"
MailAttachmentLog.savedVarVersion = 1
MailAttachmentLog.default = {
      history = {}
}

function MailAttachmentLog.OnAddOnLoaded()
    if addonName ~= MailAttachmentLog.name then return end
    MailAttachmentLog:Initialize()
end

function MailAttachmentLog:Initialize()
    --
end

function MailAttachmentLog:DoIt()
    d(":DoIt")

    mail_id = GetNextMailId(nil)
    while mail_id do
          senderDisplayName,
          _,
          subject,
          _,
          _,
          _,
          _,
          _,
          numbernumAttachments,
          attachedMoney,
          _,
          _,
          secsSinceReceived
          = GetMailItemInfo(mail_id)
          d(tostring(senderDisplayName).." "..tostring(subject).." att:"..tostring(numbernumAttachments))

        mail_id = GetNextMailId(mail_id)
    end
end

function MailAttachmentLog_DoIt()
    d("_DoIt")
    MailAttachmentLog:DoIt()
end


-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( MailAttachmentLog.name
                              , EVENT_ADD_ON_LOADED
                              , MailAttachmentLog.OnAddOnLoaded
                              )

ZO_CreateStringId("SI_BINDING_NAME_MailAttachmentLog_DoIt", "Record Mail Attachments")

--[[
1. Get a hot key hooked up
2. Iterate through mail
3. Pick an export data format
4. Define an "Mail" struct
5. Integrate with M.M.


hvy Mace   etc
lgt chest  htc
med hands  etc
med chest  etc
wood resto etc

]]
