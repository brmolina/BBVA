({
    url : function(component, event, helper) {
     var urlfinal = event.target.getAttribute("data-produto");
    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      "url":   urlfinal
    });
    urlEvent.fire();
}
})