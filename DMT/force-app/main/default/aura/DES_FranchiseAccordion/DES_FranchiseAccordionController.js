({
  	handleSectionToggle: function (cmp, event) {
        var openSections = event.getParam('openSections');
        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
        }
    },

    doInit: function (component, event, helper) {
    window.scrollTo(0, 0);
    var accountId = component.get('v.recordId');
    var franchiseValues = component.get('c.returnFracnhise');

    franchiseValues.setParams({
      'accountId': accountId
    });

    franchiseValues.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        component.set('v.franchiseObject', response.getReturnValue());
        var franchiseList = new Array();
        franchiseList = component.get('v.franchiseObject');
        for (var cn = 0; cn < franchiseList.length; cn++) {
          console.log(franchiseList[cn]);
          if (franchiseList[cn].DES_Entity__c === 'BBVA PORTUGAL') {
            component.set('v.ptTrue', true);
            component.set('v.ptSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          } else if (franchiseList[cn].DES_Entity__c === 'ALTURA') {
            component.set('v.alturaTrue', true);
            component.set('v.alturaSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          } else if (franchiseList[cn].DES_Entity__c === 'BBVA SA') {
            component.set('v.bbvasaSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          } else if (franchiseList[cn].DES_Entity__c === 'BBVA BANCOMER') {
            component.set('v.bancomerTrue', true);
            component.set('v.bancomerSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          } else if (franchiseList[cn].DES_Entity__c === 'BBVA COLOMBIA') {
            component.set('v.colombiaTrue', true);
            component.set('v.colombiaSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          } else if (franchiseList[cn].DES_Entity__c === 'BBVA CONTINENTAL') {
            component.set('v.continentalTrue', true);
            component.set('v.continentalSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          } else if (franchiseList[cn].DES_Entity__c === 'COMPASS BANK') {
            component.set('v.compassTrue', true);
            component.set('v.compassSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          } else if (franchiseList[cn].DES_Entity__c === 'BBVA BANCO PROVINCIAL') {
            component.set('v.provincialTrue', true);
            component.set('v.provincialSalesRoom', franchiseList[cn].DES_Sales_Rooms__c);
          }
        }
      }
    });
    $A.enqueueAction(franchiseValues);
  },

  sectionOne: function (component, event, helper) {
    var idx = event.currentTarget.dataset.id;
    helper.helperFun(component, event, idx);
    helper.helperFunTable(component, event, idx);
  },

  sectionTwo: function (component, event, helper) {
    var idx = event.currentTarget.dataset.id;
    helper.helperFun(component, event, idx);
    helper.helperFunTable(component, event, idx);
  },

  bbvasaTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');

    //var TabOnedata = component.find('bbvasaDataId'); 
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');

    var tab2 = component.find('ptId');

    //var TabTwoData = component.find('ptDataId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');

    var tab3 = component.find('alturaId');

    //var TabThreeData = component.find('ColorTabDataId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');

    var tab4 = component.find('bancomerId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');

    var tab5 = component.find('colombiaId');

    //var TabFiveData = component.find('ColorTabDataId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');

    //var TabFiveData = component.find('continentalTabDataId');
    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');

    //var TabSevenData = component.find('ColorTabDataId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');

    //var TabEightData = component.find('ColorTabDataId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    //show and Active fruits tab
    $A.util.addClass(tab1, 'slds-active');
    $A.util.addClass(tab1, 'active-color');

    //$A.util.addClass(TabOnedata, 'slds-show');
    $A.util.removeClass(TabOnedata, 'slds-hide');
    $A.util.removeClass(TabOnedata_asset, 'slds-hide');
    $A.util.removeClass(TabOnedata_salesRoom, 'slds-hide');

    // Hide and deactivate others tab
    // 
    $A.util.removeClass(tab2, 'slds-active');
    $A.util.removeClass(tab2, 'active-color');

    //$A.util.removeClass(TabTwoData, 'slds-show');
    $A.util.addClass(TabTwoData, 'slds-hide');
    $A.util.addClass(TabTwoData_asset, 'slds-hide');
    $A.util.addClass(TabTwoData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab3, 'slds-active');
    $A.util.removeClass(tab3, 'active-color');

    //$A.util.removeClass(TabThreeData, 'slds-show');
    $A.util.addClass(TabThreeData, 'slds-hide');
    $A.util.addClass(TabThreeData_asset, 'slds-hide');
    $A.util.addClass(TabThreeData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab4, 'slds-active');
    $A.util.removeClass(tab4, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabFourData, 'slds-hide');
    $A.util.addClass(TabFourData_asset, 'slds-hide');
    $A.util.addClass(TabFourData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab5, 'slds-active');
    $A.util.removeClass(tab5, 'active-color');

    //$A.util.removeClass(TabFiveData, 'slds-show');
    $A.util.addClass(TabFiveData, 'slds-hide');
    $A.util.addClass(TabFiveData_asset, 'slds-hide');
    $A.util.addClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab6, 'slds-active');
    $A.util.removeClass(tab6, 'active-color');

    //$A.util.removeClass(TabSixData, 'slds-show');
    $A.util.addClass(TabSixData, 'slds-hide');
    $A.util.addClass(TabSixData_asset, 'slds-hide');
    $A.util.addClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab7, 'slds-active');
    $A.util.removeClass(tab7, 'active-color');

    //$A.util.removeClass(TabSevenData, 'slds-show');
    $A.util.addClass(TabSevenData, 'slds-hide');
    $A.util.addClass(TabSevenData_asset, 'slds-hide');
    $A.util.addClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab8, 'slds-active');
    $A.util.removeClass(tab8, 'active-color');
    //$A.util.removeClass(TabEightData, 'slds-show');
    $A.util.addClass(TabEightData, 'slds-hide');
    $A.util.addClass(TabEightData_asset, 'slds-hide');
    $A.util.addClass(TabEightData_salesRoom, 'slds-hide');
  },

  ptTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');

    //var TabOnedata = component.find('bbvasaDataId');
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');
    var tab2 = component.find('ptId');

    //var TabTwoData = component.find('ptDataId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');
    var tab3 = component.find('alturaId');

    //var TabThreeData = component.find('ColorTabDataId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');
    var tab4 = component.find('bancomerId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');

    var tab5 = component.find('colombiaId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');
    //var TabEightData = component.find('ColorTabDataId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    //show and Active vegetables Tab
    $A.util.addClass(tab2, 'slds-active');
    $A.util.addClass(tab2, 'active-color');
    $A.util.removeClass(TabTwoData, 'slds-hide');
    $A.util.removeClass(TabTwoData_asset, 'slds-hide');
    $A.util.removeClass(TabTwoData_salesRoom, 'slds-hide');

    //$A.util.addClass(TabTwoData, 'slds-show');
    // Hide and deactivate others tab
    $A.util.removeClass(tab1, 'slds-active');
    $A.util.removeClass(tab1, 'active-color');

    //$A.util.removeClass(TabOnedata, 'slds-show');
    $A.util.addClass(TabOnedata, 'slds-hide');
    $A.util.addClass(TabOnedata_asset, 'slds-hide');
    $A.util.addClass(TabOnedata_salesRoom, 'slds-hide');
    $A.util.removeClass(tab3, 'slds-active');
    $A.util.removeClass(tab3, 'active-color');

    //$A.util.removeClass(TabThreeData, 'slds-show');
    $A.util.addClass(TabThreeData, 'slds-hide');
    $A.util.addClass(TabThreeData_asset, 'slds-hide');
    $A.util.addClass(TabThreeData_salesRoom, 'slds-hide');
    $A.util.removeClass(tab4, 'slds-active');
    $A.util.removeClass(tab4, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabFourData, 'slds-hide');
    $A.util.addClass(TabFourData_asset, 'slds-hide');
    $A.util.addClass(TabFourData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab5, 'slds-active');
    $A.util.removeClass(tab5, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabFiveData, 'slds-hide');
    $A.util.addClass(TabFiveData_asset, 'slds-hide');
    $A.util.addClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab6, 'slds-active');
    $A.util.removeClass(tab6, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSixData, 'slds-hide');
    $A.util.addClass(TabSixData_asset, 'slds-hide');
    $A.util.addClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab7, 'slds-active');
    $A.util.removeClass(tab7, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSevenData, 'slds-hide');
    $A.util.addClass(TabSevenData_asset, 'slds-hide');
    $A.util.addClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab8, 'slds-active');
    $A.util.removeClass(tab8, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabEightData, 'slds-hide');
    $A.util.addClass(TabEightData_asset, 'slds-hide');
    $A.util.addClass(TabEightData_salesRoom, 'slds-hide');
  },

  alturaTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');
    var tab2 = component.find('ptId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');
    var tab3 = component.find('alturaId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');
    var tab4 = component.find('bancomerId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');
    var tab5 = component.find('colombiaId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');

    //var TabEightData = component.find('ColorTabDataId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    //show and Active color Tab
    $A.util.addClass(tab3, 'slds-active');
    $A.util.addClass(tab3, 'active-color');

    //$A.util.addClass(TabThreeData, 'slds-show');
    // Hide and deactivate others tab
    $A.util.removeClass(tab1, 'slds-active');
    $A.util.removeClass(tab1, 'active-color');

    //$A.util.removeClass(TabOnedata, 'slds-show');
    $A.util.addClass(TabOnedata, 'slds-hide');
    $A.util.addClass(TabOnedata_asset, 'slds-hide');
    $A.util.addClass(TabOnedata_salesRoom, 'slds-hide');
    $A.util.removeClass(tab2, 'slds-active');
    $A.util.removeClass(tab2, 'active-color');

    //$A.util.removeClass(TabTwoData, 'slds-show');
    $A.util.addClass(TabTwoData, 'slds-hide');
    $A.util.addClass(TabTwoData_asset, 'slds-hide');
    $A.util.addClass(TabTwoData_salesRoom, 'slds-hide');
    $A.util.removeClass(TabThreeData, 'slds-hide');
    $A.util.removeClass(TabThreeData_asset, 'slds-hide');
    $A.util.removeClass(TabThreeData_salesRoom, 'slds-hide');
    $A.util.removeClass(tab4, 'slds-active');
    $A.util.removeClass(tab4, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabFourData, 'slds-hide');
    $A.util.addClass(TabFourData_asset, 'slds-hide');
    $A.util.addClass(TabFourData_salesRoom, 'slds-hide');
    $A.util.removeClass(tab5, 'slds-active');
    $A.util.removeClass(tab5, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabFiveData, 'slds-hide');
    $A.util.addClass(TabFiveData_asset, 'slds-hide');
    $A.util.addClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab6, 'slds-active');
    $A.util.removeClass(tab6, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSixData, 'slds-hide');
    $A.util.addClass(TabSixData_asset, 'slds-hide');
    $A.util.addClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab7, 'slds-active');
    $A.util.removeClass(tab7, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSevenData, 'slds-hide');
    $A.util.addClass(TabSevenData_asset, 'slds-hide');
    $A.util.addClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab8, 'slds-active');
    $A.util.removeClass(tab8, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabEightData, 'slds-hide');
    $A.util.addClass(TabEightData_asset, 'slds-hide');
    $A.util.addClass(TabEightData_salesRoom, 'slds-hide');
  },

  bancomerTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');
    var tab2 = component.find('ptId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');
    var tab3 = component.find('alturaId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');
    var tab4 = component.find('bancomerId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');
    var tab5 = component.find('colombiaId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');
    //var TabFourData = component.find('ColorTabDataId');

    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');

    //var TabEightData = component.find('ColorTabDataId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    //$A.util.addClass(TabThreeData, 'slds-show');
    $A.util.addClass(tab4, 'slds-active');
    $A.util.addClass(tab4, 'active-color');

    // Hide and deactivate others tab
    $A.util.removeClass(tab1, 'slds-active');
    $A.util.removeClass(tab1, 'active-color');

    //$A.util.removeClass(TabOnedata, 'slds-show');
    $A.util.addClass(TabOnedata, 'slds-hide');
    $A.util.addClass(TabOnedata_asset, 'slds-hide');
    $A.util.addClass(TabOnedata_salesRoom, 'slds-hide');
    $A.util.removeClass(tab2, 'slds-active');
    $A.util.removeClass(tab2, 'active-color');

    //$A.util.removeClass(TabTwoData, 'slds-show');
    $A.util.addClass(TabTwoData, 'slds-hide');
    $A.util.addClass(TabTwoData_asset, 'slds-hide');
    $A.util.addClass(TabTwoData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab3, 'slds-active');
    $A.util.removeClass(tab3, 'active-color');

    //$A.util.removeClass(TabTwoData, 'slds-show');
    $A.util.addClass(TabThreeData, 'slds-hide');
    $A.util.addClass(TabThreeData_asset, 'slds-hide');
    $A.util.addClass(TabThreeData_salesRoom, 'slds-hide');

    $A.util.removeClass(TabFourData, 'slds-hide');
    $A.util.removeClass(TabFourData_asset, 'slds-hide');
    $A.util.removeClass(TabFourData_salesRoom, 'slds-hide');
    $A.util.removeClass(tab5, 'slds-active');
    $A.util.removeClass(tab5, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabFiveData, 'slds-hide');
    $A.util.addClass(TabFiveData_asset, 'slds-hide');
    $A.util.addClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab6, 'slds-active');
    $A.util.removeClass(tab6, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSixData, 'slds-hide');
    $A.util.addClass(TabSixData_asset, 'slds-hide');
    $A.util.addClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab7, 'slds-active');
    $A.util.removeClass(tab7, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSevenData, 'slds-hide');
    $A.util.addClass(TabSevenData_asset, 'slds-hide');
    $A.util.addClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab8, 'slds-active');
    $A.util.removeClass(tab8, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabEightData, 'slds-hide');
    $A.util.addClass(TabEightData_asset, 'slds-hide');
    $A.util.addClass(TabEightData_salesRoom, 'slds-hide');
  },

  colombiaTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');
    var tab2 = component.find('ptId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');
    var tab3 = component.find('alturaId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');
    var tab4 = component.find('bancomerId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');
    var tab5 = component.find('colombiaId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');

    //var TabFourData = component.find('ColorTabDataId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');

    //var TabEightData = component.find('ColorTabDataId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    //$A.util.addClass(TabThreeData, 'slds-show');
    $A.util.addClass(tab5, 'slds-active');
    $A.util.addClass(tab5, 'active-color');

    // Hide and deactivate others tab
    $A.util.removeClass(tab1, 'slds-active');
    $A.util.removeClass(tab1, 'active-color');

    //$A.util.removeClass(TabOnedata, 'slds-show');
    $A.util.addClass(TabOnedata, 'slds-hide');
    $A.util.addClass(TabOnedata_asset, 'slds-hide');
    $A.util.addClass(TabOnedata_salesRoom, 'slds-hide');
    $A.util.removeClass(tab2, 'slds-active');
    $A.util.removeClass(tab2, 'active-color');

    //$A.util.removeClass(TabTwoData, 'slds-show');
    $A.util.addClass(TabTwoData, 'slds-hide');
    $A.util.addClass(TabTwoData_asset, 'slds-hide');
    $A.util.addClass(TabTwoData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab3, 'slds-active');
    $A.util.removeClass(tab3, 'active-color');

    //$A.util.removeClass(TabTwoData, 'slds-show');
    $A.util.addClass(TabThreeData, 'slds-hide');
    $A.util.addClass(TabThreeData_asset, 'slds-hide');
    $A.util.addClass(TabThreeData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab4, 'slds-active');
    $A.util.removeClass(tab4, 'active-color');
    $A.util.addClass(TabFourData, 'slds-hide');
    $A.util.addClass(TabFourData_asset, 'slds-hide');
    $A.util.addClass(TabFourData_salesRoom, 'slds-hide');

    $A.util.removeClass(TabFiveData, 'slds-hide');
    $A.util.removeClass(TabFiveData_asset, 'slds-hide');
    $A.util.removeClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab6, 'slds-active');
    $A.util.removeClass(tab6, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSixData, 'slds-hide');
    $A.util.addClass(TabSixData_asset, 'slds-hide');
    $A.util.addClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab7, 'slds-active');
    $A.util.removeClass(tab7, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabSevenData, 'slds-hide');
    $A.util.addClass(TabSevenData_asset, 'slds-hide');
    $A.util.addClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab8, 'slds-active');
    $A.util.removeClass(tab8, 'active-color');

    //$A.util.removeClass(TabFourData, 'slds-show');
    $A.util.addClass(TabEightData, 'slds-hide');
    $A.util.addClass(TabEightData_asset, 'slds-hide');
    $A.util.addClass(TabEightData_salesRoom, 'slds-hide');
  },

  continentalTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');

    var tab2 = component.find('ptId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');

    var tab3 = component.find('alturaId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');

    var tab4 = component.find('bancomerId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');

    var tab5 = component.find('colombiaId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');
    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    $A.util.addClass(tab6, 'slds-active');
    $A.util.addClass(tab6, 'active-color');

    $A.util.removeClass(tab1, 'slds-active');
    $A.util.removeClass(tab1, 'active-color');
    $A.util.addClass(TabOnedata, 'slds-hide');
    $A.util.addClass(TabOnedata_asset, 'slds-hide');
    $A.util.addClass(TabOnedata_salesRoom, 'slds-hide');

    $A.util.removeClass(tab2, 'slds-active');
    $A.util.removeClass(tab2, 'active-color');
    $A.util.addClass(TabTwoData, 'slds-hide');
    $A.util.addClass(TabTwoData_asset, 'slds-hide');
    $A.util.addClass(TabTwoData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab3, 'slds-active');
    $A.util.removeClass(tab3, 'active-color');
    $A.util.addClass(TabThreeData, 'slds-hide');
    $A.util.addClass(TabThreeData_asset, 'slds-hide');
    $A.util.addClass(TabThreeData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab4, 'slds-active');
    $A.util.removeClass(tab4, 'active-color');
    $A.util.addClass(TabFourData, 'slds-hide');
    $A.util.addClass(TabFourData_asset, 'slds-hide');
    $A.util.addClass(TabFourData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab5, 'slds-active');
    $A.util.removeClass(tab5, 'active-color');
    $A.util.addClass(TabFiveData, 'slds-hide');
    $A.util.addClass(TabFiveData_asset, 'slds-hide');
    $A.util.addClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(TabSixData, 'slds-hide');
    $A.util.removeClass(TabSixData_asset, 'slds-hide');
    $A.util.removeClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab7, 'slds-active');
    $A.util.removeClass(tab7, 'active-color');
    $A.util.addClass(TabSevenData, 'slds-hide');
    $A.util.addClass(TabSevenData_asset, 'slds-hide');
    $A.util.addClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab8, 'slds-active');
    $A.util.removeClass(tab8, 'active-color');
    $A.util.addClass(TabEightData, 'slds-hide');
    $A.util.addClass(TabEightData_asset, 'slds-hide');
    $A.util.addClass(TabEightData_salesRoom, 'slds-hide');
  },

  compassTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');

    var tab2 = component.find('ptId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');

    var tab3 = component.find('alturaId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');

    var tab4 = component.find('bancomerId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');

    var tab5 = component.find('colombiaId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');
    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    $A.util.addClass(tab7, 'slds-active');
    $A.util.addClass(tab7, 'active-color');

    $A.util.removeClass(tab1, 'slds-active');
    $A.util.removeClass(tab1, 'active-color');
    $A.util.addClass(TabOnedata, 'slds-hide');
    $A.util.addClass(TabOnedata_asset, 'slds-hide');
    $A.util.addClass(TabOnedata_salesRoom, 'slds-hide');

    $A.util.removeClass(tab2, 'slds-active');
    $A.util.removeClass(tab2, 'active-color');
    $A.util.addClass(TabTwoData, 'slds-hide');
    $A.util.addClass(TabTwoData_asset, 'slds-hide');
    $A.util.addClass(TabTwoData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab3, 'slds-active');
    $A.util.removeClass(tab3, 'active-color');
    $A.util.addClass(TabThreeData, 'slds-hide');
    $A.util.addClass(TabThreeData_asset, 'slds-hide');
    $A.util.addClass(TabThreeData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab4, 'slds-active');
    $A.util.removeClass(tab4, 'active-color');
    $A.util.addClass(TabFourData, 'slds-hide');
    $A.util.addClass(TabFourData_asset, 'slds-hide');
    $A.util.addClass(TabFourData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab5, 'slds-active');
    $A.util.removeClass(tab5, 'active-color');
    $A.util.addClass(TabFiveData, 'slds-hide');
    $A.util.addClass(TabFiveData_asset, 'slds-hide');
    $A.util.addClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab6, 'slds-active');
    $A.util.removeClass(tab6, 'active-color');
    $A.util.addClass(TabSixData, 'slds-hide');
    $A.util.addClass(TabSixData_asset, 'slds-hide');
    $A.util.addClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(TabSevenData, 'slds-hide');
    $A.util.removeClass(TabSevenData_asset, 'slds-hide');
    $A.util.removeClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab8, 'slds-active');
    $A.util.removeClass(tab8, 'active-color');
    $A.util.addClass(TabEightData, 'slds-hide');
    $A.util.addClass(TabEightData_asset, 'slds-hide');
    $A.util.addClass(TabEightData_salesRoom, 'slds-hide');
  },

  provincialTab: function (component, event, helper) {
    var tab1 = component.find('bbvasaId');
    var TabOnedata = document.getElementById('bbvasaDataId');
    var TabOnedata_asset = document.getElementById('bbvasaDataId_asset');
    var TabOnedata_salesRoom = document.getElementById('bbvasaSalesRoomDataId');

    var tab2 = component.find('ptId');
    var TabTwoData = document.getElementById('ptDataId');
    var TabTwoData_asset = document.getElementById('ptDataId_asset');
    var TabTwoData_salesRoom = document.getElementById('ptSalesRoomDataId');

    var tab3 = component.find('alturaId');
    var TabThreeData = document.getElementById('alturaDataId');
    var TabThreeData_asset = document.getElementById('alturaDataId_asset');
    var TabThreeData_salesRoom = document.getElementById('alturaSalesRoomDataId');

    var tab4 = component.find('bancomerId');
    var TabFourData = document.getElementById('bancomerDataId');
    var TabFourData_asset = document.getElementById('bancomerDataId_asset');
    var TabFourData_salesRoom = document.getElementById('bancomerSalesRoomDataId');

    var tab5 = component.find('colombiaId');
    var TabFiveData = document.getElementById('colombiaDataId');
    var TabFiveData_asset = document.getElementById('colombiaDataId_asset');
    var TabFiveData_salesRoom = document.getElementById('colombiaSalesRoomDataId');

    var tab6 = component.find('continentalId');
    var TabSixData = document.getElementById('continentalDataId');
    var TabSixData_asset = document.getElementById('continentalDataId_asset');
    var TabSixData_salesRoom = document.getElementById('continentalSalesRoomDataId');

    var tab7 = component.find('compassId');
    var TabSevenData = document.getElementById('compassDataId');
    var TabSevenData_asset = document.getElementById('compassDataId_asset');
    var TabSevenData_salesRoom = document.getElementById('compassSalesRoomDataId');

    var tab8 = component.find('provincialId');
    var TabEightData = document.getElementById('provincialDataId');
    var TabEightData_asset = document.getElementById('provincialDataId_asset');
    var TabEightData_salesRoom = document.getElementById('provincialSalesRoomDataId');

    $A.util.addClass(tab8, 'slds-active');
    $A.util.addClass(tab8, 'active-color');

    $A.util.removeClass(tab1, 'slds-active');
    $A.util.removeClass(tab1, 'active-color');
    $A.util.addClass(TabOnedata, 'slds-hide');
    $A.util.addClass(TabOnedata_asset, 'slds-hide');
    $A.util.addClass(TabOnedata_salesRoom, 'slds-hide');

    $A.util.removeClass(tab2, 'slds-active');
    $A.util.removeClass(tab2, 'active-color');
    $A.util.addClass(TabTwoData, 'slds-hide');
    $A.util.addClass(TabTwoData_asset, 'slds-hide');
    $A.util.addClass(TabTwoData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab3, 'slds-active');
    $A.util.removeClass(tab3, 'active-color');
    $A.util.addClass(TabThreeData, 'slds-hide');
    $A.util.addClass(TabThreeData_asset, 'slds-hide');
    $A.util.addClass(TabThreeData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab4, 'slds-active');
    $A.util.removeClass(tab4, 'active-color');
    $A.util.addClass(TabFourData, 'slds-hide');
    $A.util.addClass(TabFourData_asset, 'slds-hide');
    $A.util.addClass(TabFourData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab5, 'slds-active');
    $A.util.removeClass(tab5, 'active-color');
    $A.util.addClass(TabFiveData, 'slds-hide');
    $A.util.addClass(TabFiveData_asset, 'slds-hide');
    $A.util.addClass(TabFiveData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab6, 'slds-active');
    $A.util.removeClass(tab6, 'active-color');
    $A.util.addClass(TabSixData, 'slds-hide');
    $A.util.addClass(TabSixData_asset, 'slds-hide');
    $A.util.addClass(TabSixData_salesRoom, 'slds-hide');

    $A.util.removeClass(tab7, 'slds-active');
    $A.util.removeClass(tab7, 'active-color');
    $A.util.addClass(TabSevenData, 'slds-hide');
    $A.util.addClass(TabSevenData_asset, 'slds-hide');
    $A.util.addClass(TabSevenData_salesRoom, 'slds-hide');

    $A.util.removeClass(TabEightData, 'slds-hide');
    $A.util.removeClass(TabEightData_asset, 'slds-hide');
    $A.util.removeClass(TabEightData_salesRoom, 'slds-hide');
  },
})