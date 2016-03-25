.PHONY: put

put:
	git commit -am auto
	cp -f MailAttachmentLog.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/
	cp -f MailAttachmentLog.txt /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/
	cp -f Bindings.xml          /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/
