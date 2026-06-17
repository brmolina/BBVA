/* eslint-disable no-unused-expressions */
({
  handleMessage: function(component, event) {
    if (event != null && event.getParam("contextId") != null) {
      var contextId =event.getParam("contextId");
      var inputAttributes = {
        recordId: contextId,
        sObjectName: 'Account',
        source: 'QA'
      };
      $A.createComponent( 'cuco:profitabilityList_cmp', {
          inputAttributes: inputAttributes
        },
        function(newCmp, status, errorMessage) {
          if (status !== 'SUCCESS') {
            console.error(errorMessage);
          } else {
            var body = [];
            body.push(newCmp);
            component.set('v.body', body);
          }
        }
      );
    }
  },
  doNextComponent: function(component, event) {
    $A.createComponent(
      event.getParam('nextComponent'),
      {
        'inputAttributes': event.getParam('inputAttributes')
      },
      function(newCmp, status, errorMessage) {
        if (status === 'SUCCESS') {
          var body = [];
          body.push(newCmp);
          component.set('v.body', body);
        }
      }
    );
  },
  doCancelFlow: function(component, event)  {
    let body = component.get('v.body');
      if (body.length === 1) {
        body[0].destroy();
      }
  }
});