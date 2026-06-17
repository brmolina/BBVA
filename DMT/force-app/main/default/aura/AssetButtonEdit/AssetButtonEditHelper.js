({
  canEdit: function (component, event, helper) {

    var idrecord = component.get('v.inputAttributes').recordId;
    console.log('Record id '+idrecord);
    component.set('v.recordId',idrecord);
    var appEvent = $A.get("e.c:AssetSalesEditEvent");
    appEvent.setParams({
        "message": 'edit-asset',
        "record" : idrecord
    });
    appEvent.fire();
    $A.get("e.force:closeQuickAction").fire();

  }
})