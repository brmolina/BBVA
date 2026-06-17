({
closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"
      component.set("v.isOpen", false);
},
doInit: function(component, event, helper) {
    helper.checkError(component, event, helper);
}
})