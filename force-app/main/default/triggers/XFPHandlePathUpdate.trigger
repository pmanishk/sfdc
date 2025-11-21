trigger XFPHandlePathUpdate on Account (After Update) { 
    XFILES.XFPRenameFolders.handlePathUpdate(trigger.old, trigger.new, 'Account'); 
}