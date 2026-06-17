({
    loadChatterContext : function(component) {
        var action = component.get("c.getChatterContext");
        action.setParams({
            recordId: component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var chatterContext = response.getReturnValue();
                if (!chatterContext) {
                    return;
                }

                component.set("v.feedRecordId", chatterContext.feedRecordId);
                component.set("v.opportunityFeedRecordId", chatterContext.opportunityFeedRecordId);
                component.set("v.showLineFeed", chatterContext.showLineFeed);
                component.set("v.showOpportunityFeed", chatterContext.showOpportunityFeed);
                var displayRecordId = chatterContext.opportunityFeedRecordId ? chatterContext.opportunityFeedRecordId : chatterContext.feedRecordId;
                var widgetTitle = chatterContext.widgetTitle;
                if (!widgetTitle) {
                    widgetTitle = chatterContext.showLineFeed ? "Line Chatter" : "Opportunity Chatter";
                }
                component.set("v.widgetTitle", widgetTitle);
                component.set("v.displayRecordId", displayRecordId);
                component.set("v.isExpanded", true);
            }
        });

        $A.enqueueAction(action);
    }
})