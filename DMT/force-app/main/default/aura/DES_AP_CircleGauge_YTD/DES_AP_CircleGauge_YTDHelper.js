({
    doInit : function(component, event, helper)  {
        helper.getData(component, event, helper);
    },

    getData : function(component, event, helper) {
        var action = component.get("c.calculateCircleInfo");
        action.setParams({
            'recordId': component.get('v.recordId')
        });

        // Register the callback function
        action.setCallback(this, function(response) {
            // Set the component attributes using values returned by the API call
            console.log(response.getState());
            console.log(response.getReturnValue());
            var revenuesList = response.getReturnValue();
            if(component.get('v.typeOfCircle') === 'revenues') {
                component.set("v.chartTitle" , 'Client Revenues: YTD vs Projections');
                component.set("v.perText", revenuesList[0] + '%');
                if(parseInt(revenuesList[0]) > 100) {
                    component.set('v.cirDeg', 360);
                } else {
                    component.set('v.cirDeg', parseInt(revenuesList[0])/100 * 360);
                }
                component.set("v.currentRevenues", revenuesList[2] + ' ' + $A.get("$Locale.currency") + ' YTD Client Revenues');
                if(revenuesList[4] === 0 || revenuesList[4] === 0.00) {
                    component.set("v.noExpDataInfo",'No revenues projection data');
                }
                component.set("v.yoyPer", revenuesList[6] + ' % YoY');
                component.set("v.chartInformation",'Last year data is estimated based on current data');
            } else {
                component.set("v.chartTitle" , 'Cross Border YTD vs Projections');
                component.set("v.perText", revenuesList[1] + '%');
                if(parseInt(revenuesList[1]) > 100) {
                    component.set('v.cirDeg', 360);
                } else {
                    component.set('v.cirDeg', parseInt(revenuesList[1])/100 * 360);
                }
                component.set("v.currentRevenues", revenuesList[3] + ' ' +  $A.get("$Locale.currency")  + ' YTD Cross Border Revenues');
                if(revenuesList[5] === 0 || revenuesList[5] === 0.00) {
                    component.set("v.noExpDataInfo",'No revenues projection data');
                }
                component.set("v.yoyPer", revenuesList[7] + ' % YoY');
                component.set("v.chartInformation",'Last year data is estimated based on current data');
            }

        });
        $A.enqueueAction(action);
    },
})