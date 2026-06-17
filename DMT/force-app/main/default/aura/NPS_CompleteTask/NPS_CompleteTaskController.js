({
  openModel: function(cmp, event, helper) {
    // Set isModalOpen attribute to true
    helper.haveNPSContact(cmp);
  },

  closeModel: function(cmp, event, helper) {
    // Set isModalOpen attribute to false
    //cmp.set("v.isModalOpen", false);
    window.location = '/lightning/o/Contact/list?filterName=00B0C000000ynOlUAI';
  },

  submitDetails: function(cmp, event, helper) {
    // Set isModalOpen attribute to false
    //Add your code to call apex method or do some processing
    helper.completeTask(cmp); 
    //cmp.set("v.isModalOpen", false);
    window.location = '/lightning/o/Contact/list?filterName=00B0C000000ynOlUAI';
  },
})