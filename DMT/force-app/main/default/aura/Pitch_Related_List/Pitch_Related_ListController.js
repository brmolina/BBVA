({
  doInit : function(cmp, event, helper){
    helper.getTableData(cmp);
    cmp.set('v.columns', [
      {label: 'Pitch Name', fieldName: 'pitchURL', type: 'url', typeAttributes: { label: { fieldName: 'pitchName' }} },
      {label: 'Pitch Client', fieldName: 'clientURL', type: 'url', typeAttributes: { label: { fieldName: 'clientName' }}},
      {label: 'Pitch product', fieldName: 'pitchProduct', type: 'String'/*, initialWidth: 900*/},
      {label: 'Pitch country', fieldName: 'pitchCountry', type: 'String'}
    ]);
  },

  navigateToMyComponent : function(component, event, helper) {
    var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
      componentDef : "c:Pitch_Related_List",
      componentAttributes: {
        recordId : component.get("v.recordId"),
        familyParam : component.get("v.familyParam"),
        detailForm : 'true',
        tableSize : null
      }
    });
    evt.fire();
  }
})