({ // eslint-disable-line

  dointForChildObjectList: function(cmp, evt, helper, mapObject, myfield) {
    var x = cmp.get('v.mindex');

    for (var i = 0; i < mapObject.childFieldDescriptions.childFieldDescriptionList.length; i++) {
      if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldName === myfield) {
        cmp.set('v.FieldValue', mapObject.ChildObjectList.ChildObjects[x][myfield]);
        cmp.set('v.fieldType', mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType);
        cmp.set('v.fielid', mapObject.ChildObjectList.ChildObjects[x].Id);
        if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'DATE') {
          if (mapObject.ChildObjectList.ChildObjects[x][myfield] && mapObject.ChildObjectList.ChildObjects[x][myfield].length > 0) {
            cmp.set('v.FieldValue', mapObject.ChildObjectList.ChildObjects[x][myfield].substring(0, 10));
          }
        }

        var n0DecimalPlaces = cmp.get('v.numberOfDecimals');
        if (n0DecimalPlaces && !isNaN(n0DecimalPlaces)) {
          helper.setDecimals(cmp, evt);
        }

        break;
      }
    }
  },

  dointForNoChildObjectList: function(cmp, evt, helper, mapObject, myfield) {
    for (var i = 0; i < mapObject.childFieldDescriptions.childFieldDescriptionList.length; i++) {
      if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldName === myfield) {
        cmp.set('v.fieldType', mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType);
        cmp.set('v.fielid', mapObject.childFieldDescriptions.childFieldDescriptionList[i].recid);
        cmp.set('v.FieldValue', mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldValue);

        if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'DATE') {
          if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldValue && mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldValue.length > 0) {
            cmp.set('v.FieldValue', mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldValue.substring(0, 10));
          }
        }

        var n0DecimalPlaces = cmp.get('v.numberOfDecimals');
        if (n0DecimalPlaces && !isNaN(n0DecimalPlaces)) {
          helper.setDecimals(cmp, evt);
        }
        break;
      }
    }
  },

  setDecimals: function(cmp, evt) {
    var n0DecimalPlaces = cmp.get('v.numberOfDecimals');
    var mapObject = cmp.get('v.mapObject');
    var x = cmp.get('v.mindex');
    var z = cmp.get('v.fieldIndex');
    var fieldName = cmp.get('v.Field');
    var myfield = fieldName[z];
    var value = cmp.get('v.FieldValue');
    var detailsComponent = cmp.get('v.detailsComponent');
    var currencyCode;
    var outputString;
    var newCurrencyFormat;

    //var currencyCode = mapObject.ParentRecords.ParentRecord[0].CurrencyIsoCode;
    //Iterative variables
    var h;
    var f;
    var t;

    //var allFields = cmp.get('v.Field');
    if (detailsComponent) {
      currencyCode = mapObject.ParentRecords.ParentRecord[0].CurrencyIsoCode;
    } else {
      currencyCode = mapObject.ChildObjectList.ChildObjects[x].CurrencyIsoCode;
    }

    //Check the current users locales and retrieve the currencyFormat.
    //Split the format by decimal point and add post decimal places dynamically
    if (!n0DecimalPlaces || isNaN(n0DecimalPlaces)) {
      n0DecimalPlaces = 2;
    }
    if (n0DecimalPlaces !== null) {
      for (var i = 0; i < mapObject.childFieldDescriptions.childFieldDescriptionList.length; i++) {
        if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldName === myfield) {
          if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'CURRENCY') {
            this._setCurrency(cmp, n0DecimalPlaces, currencyCode, value);
          } else if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'NUMBER') {
            this._setNumber(cmp, n0DecimalPlaces, value);
          } else if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'PERCENT') {
            this._setPercent(cmp, n0DecimalPlaces, value);
          } else if (mapObject.childFieldDescriptions.childFieldDescriptionList[i].fieldType === 'DOUBLE') {
            this._setDouble(cmp, n0DecimalPlaces, value);
          }
        }
      }
    }
  },

  _setCurrency: function(cmp, n0DecimalPlaces, currencyCode, value) {
    var fixtoLocaleString = n0DecimalPlaces;
    n0DecimalPlaces = 2;

    var outputString = '';
    if (currencyCode === 'EUR') {
      outputString = parseFloat(value).toLocaleString('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: n0DecimalPlaces});

      if (fixtoLocaleString > 0) {
        outputString = outputString.substring(0, outputString.length - (2 - fixtoLocaleString) - 2) + ' €';
      } else {
        outputString = outputString.substring(0, outputString.length - (2 - fixtoLocaleString) - 3) + ' €';
      }
    } else {
      if (currencyCode === 'GBP') {
        outputString = parseFloat(value).toLocaleString('en-US', { style: 'currency', currency: 'GBP', maximumFractionDigits: n0DecimalPlaces});
      } else if (currencyCode === 'USD') {
        outputString = parseFloat(value).toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: n0DecimalPlaces});
      } else if (currencyCode === 'JPY') {
        outputString = parseFloat(value).toLocaleString('ja-JP', { style: 'currency', currency: 'JPY', maximumFractionDigits: n0DecimalPlaces});
      } else {
        outputString = parseFloat(value).toLocaleString('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: n0DecimalPlaces});
      }

      if (fixtoLocaleString > 0) {
        outputString = outputString.substring(0, outputString.length - (2 - fixtoLocaleString));
      } else {
        outputString = outputString.substring(0, outputString.length - (2 - fixtoLocaleString) - 1);
      }
    }
	
    var outputMillions='';   
    var i;
    for(i=0; i<outputString.length; i++){ 
        if(outputString.charAt(i)=='.'){
            outputMillions = outputMillions;
        } else outputMillions = outputMillions + outputString.charAt(i);
    }
	
    var outputMillionsFormatted =  ((parseFloat(outputMillions)/1000000).toFixed(2)).replace('.',',');
    cmp.set('v.FieldValue', outputMillionsFormatted);
  },

  _setNumber: function(cmp, n0DecimalPlaces, value) {
    var h = '0';
    var f = '';

    for (var t = 0; t < n0DecimalPlaces; t++) {
      f = f + h;
    }

    var newCurrencyFormat = '';
    if (parseFloat(value).toString().split('.')[0] === '0') {
      newCurrencyFormat = '0.' + f;
    } else {
      newCurrencyFormat = '###,###,###,###.' + f;
    }
    cmp.set('v.theNumberFormat', newCurrencyFormat);
  },

  _setPercent: function(cmp, n0DecimalPlaces, value) {
    var h = '0';
    var f = '';

    for (var t = 0; t < n0DecimalPlaces; t++) {
      f = f + h;
    }

    var newCurrencyFormat = '';
    if (parseFloat(value).toString().split('.')[0] === '0') {
      newCurrencyFormat = '0.' + f;
    } else {
      newCurrencyFormat = '###,###,###,###.' + f;
    }
    cmp.set('v.theNumberFormat', newCurrencyFormat);
  },

  _setDouble: function(cmp, n0DecimalPlaces, value) {
    var h = '0';
    var f = '';

    for (var t = 0; t < n0DecimalPlaces; t++) {
      f = f + h;
    }

    var newCurrencyFormat = '';
    if (parseFloat(value).toString().split('.')[0] === '0') {
      newCurrencyFormat = '0.' + f;
    } else {
      newCurrencyFormat = '###,###,###,###.' + f;
    }

    cmp.set('v.theNumberFormat', newCurrencyFormat);
  }
});