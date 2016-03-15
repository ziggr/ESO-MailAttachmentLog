local MailAttachmentLog = {}
MailAttachmentLog.name            = "MailAttachmentLog"
MailAttachmentLog.version         = "2.3.5.1"
MailAttachmentLog.savedVarVersion = 1
MailAttachmentLog.default = {
      history = {}
}

-- MailRecord ----------------------------------------------------------------

local MailRecord = {}

function MailRecord:FromMailId(mail_id)
    from_user,_, subject,_,_,_,_,_, attach_ct, attach_gold,
         _,_, since_secs = GetMailItemInfo(mail_id)

    o = { mail_id   = mail_id
        , from      = from_user
        , subject   = subject
        , gold      = attach_gold
        , attach_ct = attach_ct
        , ts        = GetTimeStamp() - since_secs
        }
    setmetatable(o, self)
    self.__index = self
    o:LoadAttachments(mail_id)
    return o
end

function MailRecord:LoadAttachments(mail_id)
    for i = 1, self.attach_ct do
        _,ct = GetAttachedItemInfo(mail_id, i)
        link = GetAttachedItemLink(mail_id, i, LINK_STYLE_DEFAULT)
        if not self.attach then
            self.attach = {}
        end
        self.attach[i] = { ct   = ct
                         , link = link
                         }
    end
end

function MailRecord:ToString()
    return "from:"     ..tostring(self.from)
        .." subject:"  ..tostring(self.subject)
        .." attach_ct:"..tostring(self.attach_ct)
end

-- Init ----------------------------------------------------------------------

function MailAttachmentLog.OnAddOnLoaded()
    if addonName ~= MailAttachmentLog.name then return end
    MailAttachmentLog:Initialize()
end

function MailAttachmentLog:Initialize()
    --
end

-- Do It ---------------------------------------------------------------------

function MailAttachmentLog:DoIt()
    d(":DoIt")

    mail_id = GetNextMailId(nil)
    while mail_id do
          -- senderDisplayName,
          -- _,
          -- subject,
          -- _,
          -- _,
          -- _,
          -- _,
          -- _,
          -- numbernumAttachments,
          -- attachedMoney,
          -- _,
          -- _,
          -- secsSinceReceived
          -- = GetMailItemInfo(mail_id)
          -- d(tostring(senderDisplayName).." "..tostring(subject).." att:"..tostring(numbernumAttachments))
        mr = MailRecord:FromMailId(mail_id)
        d(mr:ToString())
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
