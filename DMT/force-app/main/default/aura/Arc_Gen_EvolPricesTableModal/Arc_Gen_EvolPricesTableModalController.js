({
  doInit: function(cmp, event, helper) {
    let loadRec = helper.loadRecords(cmp, event, helper);
    loadRec.then(result => {
      if (result.length === 0) {
        cmp.set('v.noRecords', true);
      } else {
        var k = 1;
        cmp.set('v.year', result[0].arce__year_id__c);
        for (var j = 0; j < result.length; j++) {
          $A.createComponent(
            'c:Arc_Gen_EvolPricesTableRow',
            {
              prodname: result[j].arce__gf_commodity_product_name__c,
              prodId0: result[j].Id,
              val0: result[j].arce__gf_comod_prd_avg_price_amount__c,
              prodId1: result[j + 1].Id,
              val1: result[j + 1].arce__gf_comod_prd_avg_price_amount__c,
              prodId2: result[j + 2].Id,
              val2: result[j + 2].arce__gf_comod_prd_avg_price_amount__c,
              deleteId: k,
              clickAction: cmp.getReference('c.handleDelete')
            },
            function(html1, status, errorMessage) {
              if (status === 'SUCCESS') {
                var body = cmp.get('v.body');
                if (!body) {
                  body = [];
                }
                body.push(html1);
                cmp.set('v.body', body);
              } else {
                cmp.set('v.error', true);
              }
            }
          );
          k++;
          j = j + 2;//NOSONAR
        }
        cmp.set('v.counter', k - 1);
        cmp.set('v.disable', false);
      }
    });
  },
  addRow: function(cmp, event, helper) {
    var counter = cmp.get('v.counter') + 1;
    cmp.set('v.noRecords', false);
    var parameters = {
      accHasId: cmp.get('v.accHasId'),
      deleteId: counter,
      clickAction: cmp.getReference('c.handleDelete')
    };
    cmp.set('v.counter', counter);
    $A.createComponent('c:Arc_Gen_EvolPricesTableRow', parameters, function(//NOSONAR
      html1,
      status,
      errorMessage
    ) {
      if (status === 'SUCCESS') {
        var body = cmp.get('v.body');
        if (!body) {
          body = [];
        }
        body.push(html1);
        cmp.set('v.body', body);
      } else {
        cmp.set('v.error', true);
      }
    });
    cmp.set('v.disable', cmp.get('v.counter') > 0 ? false : true);
  },
  handleDelete: function(cmp, event, helper) {
    helper.handleDelete(cmp, event, helper);
  },
  saveRecords: function(cmp, event, helper) {
    cmp.set('v.disable', true);
    let yearCmp = cmp.find('yearInput');
    if (yearCmp.get('v.validity').valid) {
      helper.saveRecords(cmp, event, helper);
    } else {
      yearCmp.showHelpMessageIfInvalid();
      cmp.set('v.disable', false);
    }
  }
});