({ // eslint-disable-line
  doint: function(cmp, evt, helper) {
    var z = cmp.get('v.fieldIndex');
    var fieldName = cmp.get('v.Field');
    var myfield = fieldName[z];
    var mapObject = cmp.get('v.mapObject');

    var navigateLink = myfield === 'Name' && cmp.get('v.linkToDetail');
    cmp.set('v.navigateLink', navigateLink);

    if (mapObject.hasOwnProperty('ChildObjectList')) {
      helper.dointForChildObjectList(cmp, evt, helper, mapObject, myfield);
    } else {
      helper.dointForNoChildObjectList(cmp, evt, helper, mapObject, myfield);
    }
  },

  navigateToObject: function(cmp, evt, helper) {
    var navEvt = $A.get('e.force:navigateToSObject');
    if (navEvt) {
      navEvt.setParams({
        recordId: cmp.get('v.fielid'),
        slideDevName: 'detail'
      });
      navEvt.fire();
    } else {
      window.location.href = '/' + cmp.get('v.fielid');
    }
  }
});