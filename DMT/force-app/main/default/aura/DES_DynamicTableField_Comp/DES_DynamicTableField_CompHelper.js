({ // eslint-disable-line

  dointForChildObjectList: function (cmp, evt, helper, mapObject, myfield) {
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

  dointForNoChildObjectList: function (cmp, evt, helper, mapObject, myfield) {
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

  setDecimals: function (cmp, evt) {
    var n0DecimalPlaces = cmp.get('v.numberOfDecimals');
    var mapObject = cmp.get('v.mapObject');
    var z = cmp.get('v.fieldIndex');
    var fieldName = cmp.get('v.Field');
    var myfield = fieldName[z];
    var value = cmp.get('v.FieldValue');

    var currencyCode = $A.get("$Locale.currencyCode");

    var userCurrency = cmp.get('v.userCurrency');

    console.log('>>>>> userCurrency : ' + userCurrency);
    console.log('>>>:::::::>> value INIT::::::::::::: : ' + value);



    /*Check the current users locales and retrieve the currencyFormat.
    Split the format by decimal point and add post decimal places dynamically
    */
    if (!n0DecimalPlaces || isNaN(n0DecimalPlaces)) {
      n0DecimalPlaces = 2;
    }
    if (n0DecimalPlaces != null) { //NOSONAR
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

  _setCurrency: function (cmp, n0DecimalPlaces, currencyCode, value) {
    console.log('>>>:::::::>> value' + value);

    console.log('>>>:::::::>> value] : ' + value);
    if ((parseFloat(value) / 1000000).toFixed(2) < 0.01) { //} && parseFloat(outputMillions) != 0) {
      console.log('>>>:::::::>> menor 0,01 : ' );
      cmp.set('v.FieldValue', '< 0,01');
    } else {
      var outputMillionsFormatted = ((parseFloat(value) / 1000000).toFixed(2)).replace('.', ',');
      let auxOutputSeparators = this.numberWithDelimiter(outputMillionsFormatted.substr(0, outputMillionsFormatted.lastIndexOf(',')), '.');
      console.log('>>>:::::::>> auxOutputSeparators : ' + auxOutputSeparators);
      let finalValue = auxOutputSeparators + outputMillionsFormatted.substr(outputMillionsFormatted.lastIndexOf(','));
      console.log('>>>:::::::>> finalValue : ' + finalValue);
      cmp.set('v.FieldValue', outputMillionsFormatted);
      console.log('>>>:::::::>> outputMillionsFormatted : ' + outputMillionsFormatted);
    }
    cmp.set('v.currency', currencyCode);
  },

  _setNumber: function (cmp, n0DecimalPlaces, value) {

    //alert('ES NUMERO: ' + value);
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

  _setPercent: function (cmp, n0DecimalPlaces, value) {
    var h = '0';
    var f = '';

    for (var t = 0; t < n0DecimalPlaces; t++) {
      f = f + h;
    }

    var newCurrencyFormat = '';
    if (parseFloat(value).toString().split('.')[0] === '0') {
      //alert('AQUI NO');
      newCurrencyFormat = '0.' + f;
    } else {
      //alert('AQUI SI v2');
      newCurrencyFormat = '###,###,###,###0.' + f;
    }
    cmp.set('v.theNumberFormat', newCurrencyFormat);
  },

  _setDouble: function (cmp, n0DecimalPlaces, value) {
    //alert('ES double: ' + value);
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

  replaceLast: function (find, replace, string) {
    let lastIndex = string.lastIndexOf(find);

    if (lastIndex === -1) {
      return string;
    }

    let beginString = string.substring(0, lastIndex);
    let endString = string.substring(lastIndex + find.length);

    return beginString + replace + endString;
  },
   numberWithDelimiter: function(value , delimiter) {
    value = value.toString();
    var pattern = /(-?\d+)(\d{3})/;
    while (pattern.test(value))
      value = value.replace(pattern, "$1" + delimiter + "$2");
    return value;
  }
});