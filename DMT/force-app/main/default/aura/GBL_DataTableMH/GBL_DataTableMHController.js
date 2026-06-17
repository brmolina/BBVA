({ //eslint-disable-line no-unused-expressions
  doInit: function(cmp, event, helper) {
    //Executed when the component initializes
    helper.initComponent(cmp, event);
  },

  //Handles when a node is clicked on the AccountMultiHierarchy Component
  handleNodeClicked: function(cmp, event, helper) {
    var accountId = event.getParam('accountId');
    var vision = event.getParam('selectedVision');
    var types = event.getParam('selectedHTypes');
    var visibleNodeIds = event.getParam('visibleNodeIds');

    cmp.set('v.accountId', accountId);
    cmp.set('v.selectedVision', vision);
    cmp.set('v.selectedHTypes', types);
    cmp.set('v.visibleNodeIds', visibleNodeIds);
    cmp.set('v.ACMHAvailable', true); // ← importante

    cmp.set('v.startFromRow', 'START');

    helper.fetchData(cmp, event, helper); // ← aquí SÍ se llama
  },

  //Handles when search key changed when looking for child accounts
  handleSearchKeyChangeEvent: function(cmp, event, helper) {
    var init = [];
    cmp.set('v.objData', init);
    cmp.set('v.startFromRow', 'START');
    cmp.set('v.enableInfiniteLoading', true);
    cmp.set('v.searchKey', event.getParam('searchKey'));
    helper.fetchData(cmp, event, helper);
  },

  loadMoreData: function(cmp, event, helper) {
    //helper.fetchData(cmp,event, helper);
    helper.getData(cmp, event, helper);
  }
});