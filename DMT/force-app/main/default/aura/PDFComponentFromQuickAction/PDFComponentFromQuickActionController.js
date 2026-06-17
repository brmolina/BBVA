({
  doInit: function(component, event, helper) {
    component.set(
      'v.urlWithParams',
      '/c/PDFAppContainer.app?recordId=' +
        component.get('v.recordId') +
        '&sObjectName=' +
        component.get('v.sObjectName')
    );

    // Recibe los eventos del componente embebido en el iframe
    window.addEventListener('message', function(event) {
      switch (event.data.operation) {
        case 'closeAction':
          var element = document.getElementsByClassName(
            'DESKTOP uiModal forceModal'
          );
          element.forEach(function(e, t) {
            $A.util.addClass(e, 'slds-hide');
          });
          document.body.style.overflow = 'visible';
          break;
        case 'showToast':
          helper.handleErrors(event.data.toastMsg);
          $A.get('e.force:closeQuickAction').fire();
          break;
        default:
          console.error('unknow operation received: ' + event.data.operation);
      }
    });
  }
});