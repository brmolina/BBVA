({ //eslint-disable-line
  doint: function(cmp, evt, helper) {
    var myfield = cmp.get('v.fieldName');
    var mapObject = cmp.get('v.mapObject');
    var value = cmp.get('v.theMapValue');
    var n0DecimalPlaces = cmp.get('v.numberOfDecimals');

    for (var i = 0; i < mapObject.childFieldDescriptions.childFieldDescriptionList.length; i++) {
      if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldName === myfield) {
        cmp.set('v.fieldType', mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType);
        break;
      }
    }

    cmp.set('v.FieldValue', myfield);
  },

  mapValueIsChanged: function(cmp, evt, helper) {
    var myfield = cmp.get('v.fieldName');
    var mapObject = cmp.get('v.mapObject');
    var n0DecimalPlaces = cmp.get('v.numberOfDecimals');
    var value = cmp.get('v.theMapValue');
    var currencyCode = mapObject.ParentRecords.ParentRecord[0].CurrencyIsoCode;

    if (n0DecimalPlaces && !isNaN(n0DecimalPlaces)) {
      for (var i = 0; i < mapObject.childFieldDescriptions.childFieldDescriptionList.length; i++) {
        if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldName === myfield) {
          if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'CURRENCY') {
            helper.setCurrency(cmp, n0DecimalPlaces, currencyCode, value);
          } else if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'NUMBER') {
            helper.setNumber(cmp, n0DecimalPlaces, value);
          } else if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'PERCENT') {
            helper.setPercent(cmp, n0DecimalPlaces, value);
          } else if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'DOUBLE') {
            helper.setDouble(cmp, n0DecimalPlaces, value);
          }
        }
      }
    }
  }

});