({
  onInit: function(component, event, helper) {
    helper.isTeamMember(component, event, helper);
    helper.retrieveData(component, event, helper);
  },

  retrieveData: function(component, event, helper) {
    var getCountries = component.get('c.getCountries');
    getCountries.setParams({
      'recordId': component.get('v.recordId')
    });
    getCountries.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        console.log('Ha funcionado la llamada al getCountries');
        component.set('v.sectionList', response.getReturnValue());
        console.log('getCountries devuelve : ' + response.getReturnValue());
      } else {
        console.log('Ha fallado la llamada al getCountries');
      }
    });
    $A.enqueueAction(getCountries);
  },

  isTeamMember: function(component, event, helper) {
    var member = component.get('c.isTeamMember');
    member.setParams({
      'recordId': component.get('v.recordId')
    });
    member.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        console.log('Ha funcionado la llamada al getCountries');
        component.set('v.isTeamMember', response.getReturnValue());
        console.log('isTeamMember devuelve : ' + response.getReturnValue());
      } else {
        console.log('Ha fallado la llamada al isTeamMember');
      }
    });
    $A.enqueueAction(member);
  }
})