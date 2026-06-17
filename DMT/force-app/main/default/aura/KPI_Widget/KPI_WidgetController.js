({
    onButtonPressed : function() {
        var urlVar = '/lightning/n/KPI_Sustanaible_DealsTab/?c__doSearch=true&';
        let eUrl = $A.get("e.force:navigateToURL");
        eUrl.setParams({
            "url": urlVar
        });
        eUrl.fire();
    }
})