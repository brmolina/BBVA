({
  doInit : function(cmp, event, helper){
    helper.getTableData(cmp);
    cmp.set('v.columns', [
      {label: 'Name', fieldName: 'campaignURL', type: 'url', typeAttributes: { label: { fieldName: 'campaignName' }} },
      {label: 'End Date', fieldName: 'campaignEndDate', type: 'String'},
      {label: 'Priority', fieldName: 'campaignPriority', type: 'String'/*, initialWidth: 900*/},
      {label: 'Status', fieldName: 'campaignStatus', type: 'String'},
      {label: 'Product', fieldName: 'campaignProduct', type: 'String'},
      {label: 'Owner', fieldName: 'campaignOwnerURL', type: 'url', typeAttributes: { label: { fieldName: 'campaignOwner' }} }
    ]);
  },

  navigateToMyComponent : function(component, event, helper) {
    var evnt = $A.get("e.force:navigateToComponent");
    evnt.setParams({
      componentDef : "c:Campaign_Initiative_RelatedList",
      componentAttributes: {
        recordId : component.get("v.recordId"),
        familyParam : component.get("v.familyParam"),
        detailForm : 'true',
        tableSize : null
      }
    });
    evnt.fire();
  }
})