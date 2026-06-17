({ //eslint-disable-line
  setCurrency: function(cmp, n0DecimalPlaces, currencyCode, value) {
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

    cmp.set('v.FieldValue', outputString);
  },

  setNumber: function(cmp, n0DecimalPlaces, value) {
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

  setPercent: function(cmp, n0DecimalPlaces, value) {
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

  setDouble: function(cmp, n0DecimalPlaces, value) {
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