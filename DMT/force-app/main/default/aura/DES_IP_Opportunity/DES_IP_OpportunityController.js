({
  doInit : function(cmp, event, helpr) {
        //Executed when component initializes
      helpr.getUrlIp(cmp, event, helpr).then(
        $A.getCallback(function(result) {
        helpr.initComponent(cmp, event, helpr);
      }),
      $A.getCallback(function(error) {
        console.error( 'Error action getUrlIp with state: ' + error.message );
      }));
  },
  handleCancel : function(component, event, helper) {
    helper.showHide(component);
    event.preventDefault();
  },
  navToRecord : function(component, event, helper) {
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId" : component.get("v.opportunity.Id")
    });
    navEvt.fire();
  },
  editRecord : function(component, event, helper) {
    helper.showHide(component);
  },
  changeStateNeed : function changeState(component) {
    component.set('v.isexpandedNeed', !component.get('v.isexpandedNeed'));
  },
  changeStateSolution : function changeState(component) {
    component.set('v.isexpandedSolution', !component
        .get('v.isexpandedSolution'));
  },
  handleSuccess : function(component, event, helper) {
    var toastEvent = $A.get("e.force:showToast");
    _ipUtils
        .sucess(toastEvent, "Success!", "Information has been updated.");
    helper.showHide(component);
  },
  changeStateStatus : function changeState(component) {
    component.set('v.isexpandedStatus', !component
        .get('v.isexpandedStatus'));
  },
  changeStateIP : function changeState(component) {
    component.set('v.isexpandedIP', !component.get('v.isexpandedIP'));
  },
  editRecordIP : function(component, event, helper) {
    helper.showHideIP(component);
  },
  handleCancelIP : function(component, event, helper) {
    helper.showHideIP(component);
    helper.fetchData(component, event, helper);
    event.preventDefault();
  },
  handleSaveIP : function(component, event, helper) {
      var toastEvent = $A.get("e.force:showToast");
      if(component.get('v.isClosed')) {
          _ipUtils.validation(toastEvent,
          $A.get("$Label.c.DES_ERROR_OPP_CLOSED"));
      } else {
          var opp = component.get("v.opp");
            var selectedOption = component.find("selectOptions").get("v.value");
            if(selectedOption !== undefined) {
                 opp.bbvaCountriesParticipants = selectedOption.join(";");
            }
            var booking = component.find("bookingId").get("v.value");
             opp.bookingGeography = booking;
            if (opp.needDescription === undefined || opp.needDescription === null ||opp.needDescription === ""
            || opp.bbvaCountriesParticipants === undefined || opp.bbvaCountriesParticipants === null
            || opp.bbvaCountriesParticipants === "" || opp.bookingGeography === undefined || opp.bookingGeography === "") {
                _ipUtils.validation(toastEvent,
                "Please check the fields that are not completed");
            } else {
              helper.modifyOpp(component).catch(function(e){
                       });
              helper.showHideIP(component);
              helper.showCountryLabel(component, event, helper);
              helper.showBookingLabel(component, event, helper);
            }
      }
  }

})