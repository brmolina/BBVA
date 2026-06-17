({
	bbvaBusinessTab: function(component, event, helper) {
        var tab1 = component.find('bbvaBusinessId');
        var TabOnedata = component.find('bbvaBusinessTabId');
        var tab2 = component.find('commercialActivityId');
        var TabTwoData = component.find('commercialActivityTabId');

        //show and Active fruits tab
        $A.util.addClass(tab1, 'slds-active');
        $A.util.addClass(TabOnedata, 'slds-show');
        $A.util.removeClass(TabOnedata, 'slds-hide');

        // Hide and deactivate others tab
        $A.util.removeClass(tab2, 'slds-active');
        $A.util.removeClass(TabTwoData, 'slds-show');
        $A.util.addClass(TabTwoData, 'slds-hide');

    },

    commercialActivityTab: function(component, event, helper) {
        var tab1 = component.find('bbvaBusinessId');
        var TabOnedata = component.find('bbvaBusinessTabId');
        var tab2 = component.find('commercialActivityId');
        var TabTwoData = component.find('commercialActivityTabId');

        //show and Active vegetables Tab
        $A.util.addClass(tab2, 'slds-active');
        $A.util.removeClass(TabTwoData, 'slds-hide');
        $A.util.addClass(TabTwoData, 'slds-show');

        // Hide and deactivate others tab
        $A.util.removeClass(tab1, 'slds-active');
        $A.util.removeClass(TabOnedata, 'slds-show');
        $A.util.addClass(TabOnedata, 'slds-hide');

    },

})