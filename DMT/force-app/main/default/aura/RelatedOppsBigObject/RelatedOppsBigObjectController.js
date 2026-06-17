({
	doInit : function(component, event, helper) {
	  helper.fetchOppsVisits(component, event);

	},
	navigateAux: function(component, event, helper) {
	  var target = event.target.id;
	  var createdDate = target.split('.||.')[0];
	  var oppId = target.split('.||.')[1];
	  var accountId = target.split('.||.')[2];
	  let date4years = new Date(new Date().getFullYear()-4, 0, 1);
	  var dateOpp = new Date(new Date(createdDate).getFullYear(),new Date(createdDate).getMonth(),new Date(createdDate).getDate());
	  if(dateOpp > date4years) {
		helper.navigateOpp(component, event, helper, oppId);
	  } else {
		helper.navigateRecord(component, event, helper, accountId, oppId);
	  }
	}
  })