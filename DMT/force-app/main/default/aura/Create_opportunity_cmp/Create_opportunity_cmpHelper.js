({
    getRTName: function(component, event, helper) {
        var actionCtrl = component.get("c.getRecordTypeId");
        actionCtrl.setParams({
            'sObjecType': 'Opportunity',
            'rtName': $A.get("$Label.c.DES_RT_Inside_opp")
        })
        actionCtrl.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS" && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
                component.set("v.rtId", response.getReturnValue());
            }
        })
        $A.enqueueAction(actionCtrl);
    },
    fetchQuestionsForm: function(component, event, helper) {
        var items = [{
            "label": "Yes",
            "value": "Yes",
        },
        {
            "label": "No",
            "value": "No",
        },{
            "label": "N.A.",
            "value": "N.A.",
        }];
        component.set("v.optionsForm", items);
    },
    newOpp: function(component, evt) {
        var disclosureVal = component.find("disclosureField").get("v.value");
        var nameVal = component.find("nameField").get("v.value");
        var descriptionVal = component.find("descriptionField").get("v.value");
        var bookingVal;
        if (component.find("bookingField") !== undefined) {
            bookingVal = component.find("bookingField").get("v.value");
        } else if (component.find("bookingField2") !== undefined) {
            bookingVal = component.find("bookingField2").get("v.value");
        }

        var countriesVal = component.find("countriesField").get("v.value");
        var currencyVal = component.find("currencyField").get("v.value");
        var closedateVal = component.find("closedateField").get("v.value");
        var message = '';

        this.setVal(component, "v.disclosureVal", disclosureVal);
        this.setVal(component, "v.nameVal", nameVal);
        this.setVal(component, "v.descriptionVal", descriptionVal);
        this.setVal(component, "v.bookingVal", bookingVal);
        this.setVal(component, "v.countriesVal", countriesVal);
        this.setVal(component, "v.currencyVal", currencyVal);
        this.setVal(component, "v.closedateVal", closedateVal);

        if (component.find("form1Field") !== undefined) {
            var form1Val = component.find("form1Field").get("v.value");
            var form2Val = component.find("form2Field").get("v.value");
            this.setVal(component, "v.form1Val", form1Val);
            this.setVal(component, "v.form2Val", form2Val);
        }
        message = this.logicRequired(component, message, disclosureVal, nameVal, descriptionVal, countriesVal,bookingVal);
        message = this.logicRequiredAux(component, message, disclosureVal, closedateVal, currencyVal, form1Val, form2Val);
        message = message.slice(0, -1);
        this.setErrorValues(component, message);
        console.log('Error fields: ', message);
    },
    setVal: function(component, field, val) {
        if (val !== undefined) {
            component.set(field, val);
        }
    },
    logicRequired: function(component, message, disclosureVal, nameVal, descriptionVal, countriesVal, bookingVal) {
        message = this.checkDisclosure(component, disclosureVal, message);
        message = this.checkName(component, nameVal, message);
        message = this.checkDescription(component, descriptionVal, message);
        message = this.checkCountries(component, countriesVal, message);
        message = this.checkBooking(component, bookingVal, message, disclosureVal);
        return message;
    },
    logicRequiredAux: function(component, message, disclosureVal, closedateVal, currencyVal, form1Val, form2Val) {
        message = this.checkDate(component, closedateVal, message);
        message = this.checkCurrency(component, currencyVal, message);
        message = this.checkform1(component, form1Val, disclosureVal, message);
        message = this.checkform2(component, form2Val, disclosureVal, message);
        return message;
    },
    logicNullStyles: function(component, idDiv, classDiv, idError, classToAdd, classToRemove) {
        $A.util.addClass(component.find(idDiv), classDiv);
        $A.util.addClass(component.find(idError), classToAdd);
        $A.util.removeClass(component.find(idError), classToRemove);
    },
    logicNotNullStyles: function(component, idDiv, classDiv, idError, classToAdd, classToRemove) {
        $A.util.removeClass(component.find(idDiv), classDiv);
        $A.util.removeClass(component.find(idError), classToRemove);
        $A.util.addClass(component.find(idError), classToAdd);
    },
    checkDisclosure: function(component, disclosureVal, message) {
        if (disclosureVal === null || disclosureVal === '') {
            message += 'Information disclosure,';
            this.logicNullStyles(component, 'divdisclosure','slds-has-error', 'error-disclosure', 'slds-visible', 'slds-hidden');
        }
        else {
            this.logicNotNullStyles(component, 'divdisclosure','slds-has-error', 'error-disclosure', 'slds-hidden', 'slds-visible');
        }
        return message;
    },
    checkDescription: function(component, descriptionVal, message) {
        if (descriptionVal === null || descriptionVal === '') {
            message += 'Need\'s Description,';
            this.logicNullStyles(component, 'divdescription','slds-has-error', 'error-description', 'slds-visible', 'slds-hidden');
        }
        else {
            this.logicNotNullStyles(component, 'divdescription','slds-has-error', 'error-description', 'slds-hidden', 'slds-visible');
        }
        return message;
    },
    checkCountries: function(component, countriesVal, message) {
        if (countriesVal === null || countriesVal === '' || countriesVal === undefined) {
            message += 'BBVA Countries Participants,';
            this.logicNullStyles(component, 'divcountries','slds-has-error', 'error-countries', 'slds-visible', 'slds-hidden');
        }
        else {
            this.logicNotNullStyles(component, 'divcountries','slds-has-error', 'error-countries', 'slds-hidden', 'slds-visible');
        }
        return message;
    },
    checkName: function(component, nameVal, message) {
        if (nameVal === null || nameVal === '') {
            message += 'Opportunity Name,';
            $A.util.addClass(component.find('divname'), 'slds-has-error');
        }
        else {
            $A.util.removeClass(component.find('divname'), 'slds-has-error');
        }
        return message;
    },
    checkDate: function(component, closedateVal, message) {
        if (closedateVal === null || closedateVal === '' || closedateVal === undefined) {
            message += 'Estimated Closing Date,';
            $A.util.addClass(component.find('divdate'), 'slds-has-error');
        }
        else {
            $A.util.removeClass(component.find('divdate'), 'slds-has-error');
        }
        return message;
    },
    checkCurrency: function(component, currencyVal, message) {
        if (currencyVal === null || currencyVal === '' || currencyVal === undefined) {
            message += 'Currency,';
            this.logicNullStyles(component, 'divcurrency','slds-has-error', 'error-currency', 'slds-visible', 'slds-hidden');
        }
        else {
            this.logicNotNullStyles(component, 'divcurrency','slds-has-error', 'error-currency', 'slds-hidden', 'slds-visible');
        }
        return message;
    },
    checkform1: function(component, form1Val, disclosureVal, message) {
        if ((form1Val === null || form1Val === '' || form1Val === undefined) && disclosureVal === $A.get("$Label.c.DES_OP_Inside")) {
            message += 'first question,';
            this.logicNullStyles(component, 'divform1','slds-has-error', 'error-form1', 'slds-visible', 'slds-hidden');
        }
        else {
            this.logicNotNullStyles(component, 'divform1','slds-has-error', 'error-form1', 'slds-hidden', 'slds-visible');
        }
        return message;
    },
    checkform2: function(component, form2Val, disclosureVal, message) {
        if ((form2Val === null || form2Val === '' || form2Val === undefined) && disclosureVal === $A.get("$Label.c.DES_OP_Inside")) {
            message += 'second question,';
            this.logicNullStyles(component, 'divform2','slds-has-error', 'error-form2', 'slds-visible', 'slds-hidden');
        }
        else {
            this.logicNotNullStyles(component, 'divform2','slds-has-error', 'error-form2', 'slds-hidden', 'slds-visible');
        }
        return message;
    },
    setErrorValues: function(component, mesage) {
        if (mesage === '' || mesage === undefined) {
            component.set('v.showError', false);
        }
        else {
            var messageAux = 'These required fields must be completed: ' + mesage;
            component.set('v.errorMessage', messageAux);
            component.set('v.showError', true);
        }
    },
    getQuestions: function(component, event, helper) {
        var action = component.get("c.complianceQuestions");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS" && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
                component.set("v.preguntas", response.getReturnValue());
            }
        })
        $A.enqueueAction(action);
    },
    completeDays: function(component, event, helper) {
        var date = new Date();
        date.setDate(date.getDate() + 45);
        var dateMonth = date.getMonth() + 1;
        var formatDate = date.getFullYear() + '-' + dateMonth + '-' + date.getDate();
        component.set('v.formatDate',formatDate);
    },
    checkBooking: function(component, bookingVal, message, disclosureVal) {
        if (disclosureVal === $A.get("$Label.c.DES_OP_Inside")) {
        	if (bookingVal === null || bookingVal === '') {
            	message += 'Booking,';
            	this.logicNullStyles(component, 'divbooking','slds-has-error', 'error-booking', 'slds-visible', 'slds-hidden');
            }
            else {
                this.logicNotNullStyles(component, 'divbooking','slds-has-error', 'error-booking', 'slds-hidden', 'slds-visible');
            }
        }
        return message;
    }
})