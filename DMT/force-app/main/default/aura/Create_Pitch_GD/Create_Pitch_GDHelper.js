({
  newPitch: function (component, evt) {
	console.log('::::: DENTRO DE NEW PITCH ');
    var nameField = component.find('nameField').get('v.value');
    var clientField = component.find('clientFields').get('v.value');
    var productFamilyField = component.find('productFamilyField').get('v.value');
    var productField = component.find('productField').get('v.value');
    var CountryVisivility = component.get('v.CountryIsVisible');
    var countryField;
    console.log('::::: nameField: ', nameField);
    console.log('::::: clientField: ', clientField);
    console.log('::::: productFamilyField: ', productFamilyField);
    console.log('::::: productField: ', productField);
    console.log('::::: CountryVisivility: ', CountryVisivility);
    if (CountryVisivility === true) {
      countryField = component.find('countryField').get('v.value');
    } else {
      countryField = 'Spain';
    }
    console.log('::::: countryField: ', countryField);
    var descriptionField = component.find('descriptionField').get('v.value');
    var message = '';
    component.set('v.Name', nameField);
    component.set('v.ClientName', clientField);
    component.set('v.ProductFamily', productFamilyField);
    component.set('v.Product', productField);
    component.set('v.Country', countryField);
    component.set('v.Description', descriptionField);
    message = this.logicRequired(component, message, nameField, clientField, productFamilyField, productField, countryField);
    console.log('::::: message: ', message);
      if(message != null) {
          message = message.slice(0, -1);
          this.setErrorValues(component, message);
      }
  },
  logicRequired: function (component, message, nameField, clientField, productFamilyField, productField, countryField) {
    console.log('::::: DENTRO DE LOGIC REQUIRED ');
    message = this.checkRequiredFields(component, message, nameField, clientField, productFamilyField, productField, countryField);
    console.log('::::: message: ', message);
    return message;
  },
  setErrorValues: function (component, mesage) {
	console.log('::::: mesage: ', mesage);
    if (mesage === '' || mesage === undefined) {
      component.set('v.showError', false);
    } else {
      var messageAux = 'These required fields must be completed: ' + mesage;
      component.set('v.errorMessage', messageAux);
      component.set('v.showError', true);
    }
  },
  logicNotNullStyles: function (component, idDiv, classDiv, idError, classToAdd, classToRemove) {
    console.log('::::: DENTRO DE logicNotNullStyles ');
    $A.util.removeClass(component.find(idDiv), classDiv);
    $A.util.removeClass(component.find(idError), classToRemove);
    $A.util.addClass(component.find(idError), classToAdd);
  },
  logicNullStyles: function (component, idDiv, classDiv, idError, classToAdd, classToRemove) {
    console.log('::::: DENTRO DE logicNullStyles ');
    $A.util.addClass(component.find(idDiv), classDiv);
    $A.util.addClass(component.find(idError), classToAdd);
    $A.util.removeClass(component.find(idError), classToRemove);
  },
  checkRequiredFields: function (component, message, nameField, clientField, productFamilyField, productField, countryField) {
    console.log('::::: DENTRO DE checkRequiredFields ');
    var CountryVisivility = component.get('v.CountryIsVisible');
    if (nameField === undefined || nameField === null || nameField === '') {
      message += 'Name, ';
      this.logicNullStyles(component, 'divnames', 'slds-has-error', 'error-name', 'slds-visible', 'slds-hidden');
    } else {
      this.logicNotNullStyles(component, 'divnames', 'slds-has-error', 'error-name', 'slds-hidden', 'slds-visible');
    }
    if (clientField === undefined || clientField === null || clientField === '') {
      message += 'Client, ';
      this.logicNullStyles(component, 'divclient', 'slds-has-error', 'error-client', 'slds-visible', 'slds-hidden');
    } else {
      this.logicNotNullStyles(component, 'divclient', 'slds-has-error', 'error-client', 'slds-hidden', 'slds-visible');
    }
    if (productFamilyField === undefined || productFamilyField === null || productFamilyField === '') {
      message += 'SProduct Family, ';
      this.logicNullStyles(component, 'divproductF', 'slds-has-error', 'error-productF', '.slds-has-error .slds-form-element__help', 'slds-hidden');
    } else {
      this.logicNotNullStyles(component, 'divproductF', 'slds-has-error', 'error-productF', 'slds-hidden', 'slds-visible');
    }
    /*if (productField === undefined || productField === null || productField === '') {
      message += 'Product, ';
      this.logicNullStyles(component, 'divproduct', 'slds-has-error', 'error-product', 'slds-visible', 'slds-hidden');
    } else {
      this.logicNotNullStyles(component, 'divproduct', 'slds-has-error', 'error-product', 'slds-hidden', 'slds-visible');
    }
    if (CountryVisivility === true) {
      if (countryField === undefined || countryField === null || countryField === '') {
        message += 'Country, ';
        this.logicNullStyles(component, 'divcountry', 'slds-has-error', 'error-country', 'slds-visible', 'slds-hidden');
      } else {
        this.logicNotNullStyles(component, 'divcountry', 'slds-has-error', 'error-country', 'slds-hidden', 'slds-visible');
      }
    }*/
    
    this.checkRequiredFields2(component, message, nameField, clientField, productFamilyField, productField, countryField, CountryVisivility);
    //return message;
  },
 
  checkRequiredFields2: function(component, message, nameField, clientField, productFamilyField, productField, countryField, CountryVisivility) {
	  console.log('::::: DENTRO DE checkRequiredFields2');
	  if (productField === undefined || productField === null || productField === '') {
      message += 'Product, ';
      this.logicNullStyles(component, 'divproduct', 'slds-has-error', 'error-product', 'slds-visible', 'slds-hidden');
    } else {
      this.logicNotNullStyles(component, 'divproduct', 'slds-has-error', 'error-product', 'slds-hidden', 'slds-visible');
    }
    if (CountryVisivility === true) {
      if (countryField === undefined || countryField === null || countryField === '') {
        message += 'Country, ';
        this.logicNullStyles(component, 'divcountry', 'slds-has-error', 'error-country', 'slds-visible', 'slds-hidden');
      } else {
        this.logicNotNullStyles(component, 'divcountry', 'slds-has-error', 'error-country', 'slds-hidden', 'slds-visible');
      }
    }
    console.log('::::: message: ', message);
    return message;
  }
 
  
})