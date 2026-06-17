({
    init: function(cmp, event, helper, component) {
        helper.setColumns(cmp);
        helper.setData(cmp);
      },

    buttonAddHandler : function(cmp,event, helper){
      helper.buttonAddAction(cmp, event, helper);
    },
    buttonDeleteHandler: function(cmp,event,helper){
      helper.buttonDeleteAction(cmp,event,helper);
    },
    bundleSelector : function(cmp,event,helper){
      helper.selectionAction(cmp,event,helper);
    },
    checkboxHandler : function(cmp, event, helper){
      helper.checkpointAction(cmp, event, helper);
    },
    sendEmailHandler : function(component, event, helper) {
      helper.sendEmailAction(component, event, helper);
    },
    viewComment : function(component, event, helper) {
      let newCmpParams ;
      if(component.get('v.isPreview')){
         newCmpParams = {
          bundle : component.get('v.data'),
          isPreview : component.get('v.isPreview'),
          masterData : component.get('v.masterDataPreview')
        }
      }else{
        newCmpParams = {
        bundle : component.get('v.data'),
        isAvailable :component.get('v.bundleAvailable')
        };
      }
      var cmpName = 'PRW_BundleComment';
      helper.createComponent(component, helper,cmpName, newCmpParams).then($A.getCallback(newCmp => { //NOSONAR
        let body = [];
        body.push(newCmp);
        component.set('v.body', body);
      }));
    },
    addBundleProduct : function(cmp, event, helper) {
      var newCmpParams = {
        dataTable : cmp.get('v.dataProductsAdded'),
        bundleProds  : cmp.get('v.dataProductsPreview'),
        catalog : cmp.get('v.catalog')
      };
      var cmpName = 'PRW_AddBundleProduct'
      if(cmp.get('v.catalog') === undefined){
        setTimeout(function() {
        newCmpParams.catalog = null;
        helper.createComponent(cmp, helper,cmpName, newCmpParams).then($A.getCallback(newCmp => { //NOSONAR
            let body = [];
            body.push(newCmp);
            cmp.set('v.body', body);
          }));
        }, 3000);
      }else{
        helper.createComponent(cmp, helper,cmpName, newCmpParams).then($A.getCallback(newCmp => { //NOSONAR
          let body = [];
          body.push(newCmp);
          cmp.set('v.body', body);
        }));
      }
    },
    addBundleProductEventHandler : function(cmp, event, helper) {
      helper.bundleProductEventHandle(cmp,event,helper);
    },

    addBundle : function(cmp,event,helper){
      helper.addBundleHandle(cmp,event);
    },

    handleCellEdition : function (cmp, event, helper) {
      var draftValues = event.getParam('draftValues');
      helper.handleCellChange(cmp, event, draftValues);
    },

    handleCellEditionAdded : function (cmp, event, helper) {
      var draftValues = event.getParam('draftValues');
      helper.handleCellChangeAdded(cmp, event, draftValues);
    },

    resetBundle : function(cmp,event,helper){
      helper.handleResetBundle(cmp,event);
    },

    changeInput : function(cmp,event,helper){
      helper.changeInputHandler(cmp,event);
    },

    changeInputNotPreview : function(cmp,event,helper){
      helper.changeInputNotPreviewHandler(cmp,event);
    },

    handleRowAction: function (cmp, event, helper) {
      var action = event.getParam('action');
      var row = event.getParam('row');
      if(action.name === 'delete') {
        helper.handleDelete(cmp,row);
      }
    },
    handleCalculate : function(component, event,helper){
      helper.handleCalculation(component, event,helper);
    },
    catalogEvtHandler : function(component, event,helper){
      helper.setCatalog(component, event,helper);
    }
})