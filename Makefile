.PHONY: get put

put:
	git commit -am auto
	cp -f MailAttachmentLog.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/
	cp -f MailAttachmentLog.txt /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/
	cp -f Bindings.xml          /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/MailAttachmentLog.lua ../../SavedVariables/

csv:
	lua MailAttachmentLog_to_csv.lua
	cp -f ../../SavedVariables/MailAttachmentLog.csv data/

