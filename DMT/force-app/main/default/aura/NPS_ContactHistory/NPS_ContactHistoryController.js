({
  doInit : function(cmp, event, helper){
    helper.getTableData(cmp);
    cmp.set('v.columns', [
      {label: 'YEAR', fieldName: 'year', type: 'number', typeAttributes: { label: { fieldName: 'year' }} },
      {label: 'NPS', fieldName: 'nps', type: 'boolean'},
      {label: 'OWNER', fieldName: 'ownerURL', type: 'url', typeAttributes: { label: { fieldName: 'ownerName' }} },
      {label: 'SUBMITTER', fieldName: 'submitterURL', type: 'url', typeAttributes: { label: { fieldName: 'submitterName' }} },
      {label: 'UNCHECKING DATE', fieldName: 'uncheckingDate', type: 'Datetime'},
      {label: 'UNCHECKING REASON', fieldName: 'uncheckingReason', type: 'String'}
    ]);
  },

  navigateToMyComponent : function(component, event, helper) {
    var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
      componentDef : "c:OpportunitiesInProgressByFamAll",
      componentAttributes: {
        idAcc : component.get("v.recordId"),
        famParamAll : component.get("v.familyParam"),
        country : component.get("v.country"),
        breadcrumbsActive : component.get("v.breadcrumbsActive"),
        filial : component.get("v.filial")
      }
    });
    evt.fire();
  }
})