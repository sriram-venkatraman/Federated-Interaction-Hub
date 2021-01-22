({
    handleInteractionViewEvent : function(cmp, event) {
        cmp.set("v.recordId", event.getParam("CurrentInteractionId"));
        cmp.set("v.headerMsg", event.getParam("HeaderMessage"));
        cmp.set("v.subHeaderMsg", event.getParam("SubHeaderMessage"));
        cmp.set("v.icon", event.getParam("Icon"));
        cmp.set("v.sObject", event.getParam("SObject"));
        cmp.set("v.versionData", event.getParam("VersionData"));
    }
})