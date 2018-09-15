.PHONY: get put csv zip

put:
	git commit -am auto
	cp -f MailAttachmentLog.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/
	cp -f MailAttachmentLog.txt /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/
	cp -f Bindings.xml          /Volumes/Elder\ Scrolls\ Online/live/AddOns/MailAttachmentLog/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/MailAttachmentLog.lua ../../SavedVariables/
	cp ../../SavedVariables/MailAttachmentLog.lua data/

csv:
	lua MailAttachmentLog_to_csv.lua
	cp -f ../../SavedVariables/MailAttachmentLog.csv data/

auction:
	lua MailAttachmentLog_to_auction.lua | pbcopy
	cp -f ../../SavedVariables/MailAttachmentLog_auction.csv data/
	echo "Copied to clipboard. Go paste somewhere."

zip:
	-rm -rf published/MailAttachmentLog published/MailAttachmentLog\ x.x.x.x.zip
	mkdir -p published/MailAttachmentLog
	cp ./MailAttachmentLog* published/MailAttachmentLog/
	cp ./Bindings.xml       published/MailAttachmentLog/
	cd published; zip -r MailAttachmentLog\ x.x.x.x.zip MailAttachmentLog
