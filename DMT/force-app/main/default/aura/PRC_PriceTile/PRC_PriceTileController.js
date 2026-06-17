({
    doInit: function (component, event, helper) {
        //por si acaso: if ( (component.get('v.posIndex') % (component.get('v.matrixColumns')*component.get('v.matrixColumns')) ) === component.get('v.selectedPriceId')) {
        var isSelected = component.get('v.selected');
        if (isSelected === 'yes') {
            helper.runPriceClick(component, event);
        }
    },
    onPriceClick: function (component, event, helper) {
        var myButton = component.find("buttomPrc");
        $A.util.removeClass(myButton, 'selectedInit');
        helper.runPriceClick(component, event);
    }
})