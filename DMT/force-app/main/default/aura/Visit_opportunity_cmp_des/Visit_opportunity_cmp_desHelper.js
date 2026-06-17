({
  fetchPickListVal: function(cmp, fieldName, elementId, empty) {
      var action = cmp.get('c.getselectOptions');
      action.setParams({
          'objObject': cmp.get('v.objInfo'),
          'fld': fieldName,
          'empty': empty
      });
			var opts = [];
      action.setCallback(this, function(response) {
          if (response.getState() === 'SUCCESS') {
							var allValuesObj = response.getReturnValue();
							console.log(allValuesObj);
              if (allValuesObj !== null) {
                  for (var k in allValuesObj) {
                      if ((cmp.get('v.rtName') === $A.get("$Label.c.DES_RT_Inside_opp") || cmp.get('v.rtName') === $A.get("$Label.c.DES_RT_Inside_GM_opp"))
                          && allValuesObj[k] !== $A.get("$Label.c.DES_OP_NOT_APPLICABLE") && allValuesObj[k] !== $A.get("$Label.c.DES_OP_CONFIDENTIAL")) {
                          this.optsPush(opts, k, allValuesObj[k]);
                      } else if (cmp.get('v.rtName') !== $A.get("$Label.c.DES_RT_Inside_opp") && cmp.get('v.rtName') !== $A.get("$Label.c.DES_RT_Inside_GM_opp")
                                 && allValuesObj[k] !== $A.get("$Label.c.DES_OP_Inside")) {
                          this.optsPush(opts, k, allValuesObj[k]);
                      }

                  }
              }
              cmp.find(elementId).set('v.options', opts);
          }
      });
      $A.enqueueAction(action);
  },
  optsPush: function(opts, valueToPush, labelToPush) {
      opts.push({
          class: 'optionClass',
          label: labelToPush,
          value: valueToPush
      });
  },
  newVisit: function(cmp, evt) {
    var namevisit = cmp.get('v.visitName');
    var startdate = cmp.get('v.startdate');
    var durationval = cmp.get('v.durationval');
    var typeval = cmp.get('v.typeval');
    var purposetypeval = cmp.get('v.purposetypeval');
    var topicval = cmp.get('v.topicval');
    var locationval = cmp.get('v.locationval');
    var action = cmp.get('c.newVisit');
    var disclosure = cmp.get('v.disclosureval');
    var message = '';
    if (startdate !== null && startdate.length === 0) {
    startdate = null;
  }

    action.setParams({
      name: namevisit,
      recordId: cmp.get('v.recordId'),
      duration: durationval,
      startdate: startdate,
      topic: topicval,
      location: locationval,
      typeValue: typeval,
      purposeTypeValue: purposetypeval,
      disclosure: disclosure
      //countryValue: countryval
    });
    action.setCallback(this, function(response) {

      if (cmp.isValid() && response.getState() === 'SUCCESS') {
        var result = response.getReturnValue();
        if (result === 'OK') {
          var actionClicked = evt.getSource().getLocalId();
          var navigate = cmp.get("v.navigateFlow");
          navigate(actionClicked);
        } else if (result === 'EMPTY') {
          message = $A.get('$Label.dwp_kitv.EmptyFields');
          this.logicEmpty(cmp, message, namevisit, startdate, durationval);
          this.logicEmptyAux(cmp, message, topicval, typeval, purposetypeval);
        } else if (result === 'NOLEAD') {
          $A.get('e.force:closeQuickAction').fire();
          $A.get('e.force:refreshView').fire();
          message = $A.get('$Label.dwp_kitv.ErrorcustomLeadInfo');
          this.showToast('Error!', 'error', message, 'sticky');
        } else if (result === 'KOACCLEADVISIT') {
          $A.get('e.force:closeQuickAction').fire();
          $A.get('e.force:refreshView').fire();
          message = $A.get('$Label.dwp_kitv.NoAccNoLeadVisit');
          this.showToast('Error!', 'error', message, 'sticky');
        }
      }
    });
    $A.enqueueAction(action);
  },
  logicEmpty: function(cmp, message, namevisit, startdate, durationval) {
    var cmpname = cmp.find('visitname');
    var cmpstart = cmp.find('today');
    var cmpduration = cmp.find('duration');

    if (namevisit === undefined || namevisit === '') {
      cmpname.set('v.errors', [ {message} ]);
    } else {
      cmpname.set('v.errors', null);
    }
    if (startdate === null || startdate === '') {
      cmpstart.set('v.errors', [ {message} ]);
    } else {
      cmpstart.set('v.errors', null);
    }
    if (durationval === '') {
      cmpduration.set('v.errors', [ {message} ]);
    } else {
      cmpduration.set('v.errors', null);
    }
  },
  logicEmptyAux: function(cmp, message, topicval, typeval, purposetypeval) { //eslint-disable-line
    var cmptopic = cmp.find('topic');
    var cmptype = cmp.find('type');
    var cmppurposetype = cmp.find('purposetype');

    if (topicval === undefined || topicval === '') {
      cmptopic.set('v.errors', [ {message} ]);
    } else {
      cmptopic.set('v.errors', null);
    }
    if (typeval === undefined || typeval === '') {
      cmptype.set('v.errors', [ {message} ]);
    } else {
      cmptype.set('v.errors', null);
    }
    if (purposetypeval === undefined || purposetypeval === '') {
      cmppurposetype.set('v.errors', [ {message} ]);
    } else {
      cmppurposetype.set('v.errors', null);
    }
  },
  showToast: function(title, type, message, mode) {
    var toast = $A.get('e.force:showToast');
    toast.setParams({
      'title': title,
      'type': type,
      'message': message,
      'mode': mode
    });
    toast.fire();
  },
  getDisclosure: function(cmp) {
      var action = cmp.get('c.isShowDisclosure');

      action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var showDisclosure = response.getReturnValue();
        cmp.set('v.showDisclosure', showDisclosure);
      }
    });
    $A.enqueueAction(action);
  },
    getAccId: function(cmp, evt) {
        var action = cmp.get('c.getAccId');
        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if (cmp.isValid() && response.getState() === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.accId', result);
                if (result === null) {
                    this.getLeadId(cmp, evt);
                }
            }
        });
        $A.enqueueAction(action);
    },
     getLeadId: function(cmp, evt) {
        var action = cmp.get('c.getLeadId');
        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if (cmp.isValid() && response.getState() === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.leadId', result);
            }
        });
        $A.enqueueAction(action);
    },
     getRecordTypeName: function(cmp, evt) {
        var action = cmp.get('c.recordTypeName');
        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if (cmp.isValid() && response.getState() === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.rtName', result);
            }
        });
        $A.enqueueAction(action);
    }
});