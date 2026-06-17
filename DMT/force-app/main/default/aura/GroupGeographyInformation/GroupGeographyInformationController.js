({
	navigateToUser: function (cmp) {
		console.log('::::navigateToUser init::: ' );
		var userId = cmp.get("v.nameId");
		userId = userId.split('\'').join('');//without quotes

		var sObjectEvent = $A.get("e.force:navigateToSObject");
		console.log('::::userId::: ' + userId);
		sObjectEvent.setParams({
			"recordId": userId,
			"slideDevName": "detail"
		});
		sObjectEvent.fire();

	}
})