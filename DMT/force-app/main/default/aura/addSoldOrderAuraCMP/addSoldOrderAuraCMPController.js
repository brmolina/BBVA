({
  doInit: function (component, event, helper) {
    var oppRecordId = component.get('v.inputAttributes').recordId;
    component.set('v.oppRecordId', oppRecordId);
    component.set('v.recordId', oppRecordId);
    helper.oppCurrencyISOCode(component, event);
    helper.oppLineItemProrrataAmount(component);
    component.set('v.isOpen', true);
  },

  handleLoad: function (component, event, helper) {
    component.set('v.showSpinner', false);
  },

  handleSubmit: function (component, event, helper) {
    event.preventDefault();
    var eventFields = event.getParam('fields');
    if (component.get('v.soldOrderAmount') !== null && component.get('v.soldOrderAmount') !== '') {
      eventFields.gf_ctpty_sold_order_amount__c = component.get('v.soldOrderAmount');
    } else {
      eventFields.gf_ctpty_sold_order_amount__c = 0;
    }
    if (component.get('v.settledAmount') !== null && component.get('v.settledAmount') !== '') {
      eventFields.gf_sold_ord_ctpty_setl_amount__c = component.get('v.settledAmount');
    } else {
      eventFields.gf_sold_ord_ctpty_setl_amount__c = 0;
    }
    eventFields.gf_sold_orders_fees_bps_amount__c = component.get('v.feesPaidBPS');
    eventFields.gf_sold_order_fees_paid_amount__c = component.get('v.feesPaidAmount');
    eventFields.gf_loan_br_ctpty_id__c = component.get('v.selectIdSeeker');
    eventFields.CurrencyISOCode = eventFields.Currency__c;
    eventFields.opportunity_id__c = component.get('v.recordId');
    eventFields.gf_assur_bbva_so_prort_amount__c = component.get('v.prorrataAmount');
    eventFields.gf_bbva_assur_prtcp_per__c = component.get('v.underwritingPercent');
    component.find('newSoldOrderForm').submit(eventFields);

    component.set('v.disabled', true);
    component.set('v.showSpinner', true);

  },
  handleSuccess: function (component, event, helper) {
    window.setTimeout(
      $A.getCallback(function () {
        component.set('v.showSpinner', false);
        component.set('v.saved', true);
        helper.closeModel(component, event, helper);
        helper.fireRefreshView(component, event, helper);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          "title": "Success!",
          "message": "The Sold Order has been created succesfully.",
          "type": "success"
        });
        toastEvent.fire();

      }), 2000 //HAY 2 SEGUNDOS DE DELAY PORQUE EL PUSH TOPIC SE EJECUTA NADA MAS ENTRAR EN BASE DE DATOS, ANTES DE QUE TERMINE EL TRIGGER
      // POR LO QUE AL RECARGAR EL FORMULARIO DE PRODUCTOS NO DABA TIEMPO A MOSTRAR LA FORMULA DE POTENTIAL REVENUES BIEN CALCULADA
      // YA QUE NO DABA TIEMPO A QUE TERMINASE EL TRIGGER, POR LO QUE SIN EL DELAY SE MOSTRABA EL VALOR ANTIGUO, LO CUAL OBLIGABA AL USUARIO A HACER F5
      // HACIENDO ESTE DELAY ES MÁS LENTA LA HERRAMIENTA, PERO HASTA ENCONTRAR OTRA SOLUCION QUE PERMITA EJECUTAR EL REFRESHVIEW AL TERMINAR LA
      // EJECUCION DEL TRIGGER ES NECESARIO EL DELAY
    );

  },
  handleError: function (component, event, helper) {
    var eventError = event.getParam("error");
    helper.closeModel(component, event, helper);
    console.error(eventError);
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      "title": "Error!",
      "message": "You have not permissions to modify this Opportunity.",
      "type": "error"
    });
    toastEvent.fire();
  },
  runCloseModel: function (component, event, helper) {
    helper.closeModel(component, event, helper);
  },

  handleChangeSeeker: function (cmp, evt, helper) {
    var data = evt.getParam('data');
    if (data.length !== 0) {
      cmp.set('v.selectIdSeeker', data[0].salesforceId);
      var cmpTarget = cmp.find('divInputSeeker');
      $A.util.addClass(cmpTarget, 'hidden');
    }
  },

  handleOnload: function (cmp, evt, helper) {
    var fieldSeeker = cmp.get('v.fieldSeeker');
    if (fieldSeeker !== undefined && fieldSeeker !== null && fieldSeeker !== '') {
      var seekerInput = cmp.find('seekerInput').get('v.value');
      var cmpTargetSeeker = cmp.find('divSeeker');
      var cmpTargetInputSeeker = cmp.find('divInputSeeker');
      if (seekerInput === undefined || seekerInput === '' || seekerInput === null) {
        $A.util.removeClass(cmpTargetSeeker, 'hidden');
        $A.util.addClass(cmpTargetInputSeeker, 'hidden');
      } else {
        $A.util.addClass(cmpTargetSeeker, 'hidden');
        $A.util.removeClass(cmpTargetInputSeeker, 'hidden');
        cmp.set('v.selectIdSeeker', seekerInput);
      }
    }
    if (cmp.get('v.newEntry')) {
      cmp.set('v.spinnerNewEntry', false);
      var cmpNewEntry = cmp.find('divNewEntry');
      $A.util.removeClass(cmpNewEntry, 'hidden');
    }
    var evtRowComplete = cmp.getEvent('LoadRowComplete');
    evtRowComplete.fire();
  }

})