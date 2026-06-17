({
	doInit : function(cmp, event, helpr) {
        //Executed when component initializes
      helpr.getJson(cmp, event, helpr);
  },
  refreshVotes : function(cmp, event, helpr) {

    helpr.getJson(cmp, event, helpr).then(
				$A.getCallback(function(result) {
					 var eventRefresh = $A.get('e.qvcd:GBL_Refresh_EVT');
					eventRefresh.setParam('inputJson', cmp.get( 'v.inputJson'));
					eventRefresh.setParam('relationMode', true);
					eventRefresh.setParam('refreshinputJson', true);
					eventRefresh.fire();
				}),
				$A.getCallback(function(error) {
				  console.error( 'Error calling action getUrlIp with state: ' + error.message );
				})
		).catch(function(e){
		});
  }
})