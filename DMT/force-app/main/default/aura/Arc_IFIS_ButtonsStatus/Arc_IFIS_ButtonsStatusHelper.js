({
  setModalParams: function(component) {
    const inputAttributes = component.get('v.inputAttributes');
    const recIdImputAtt = inputAttributes.recordId;
    const lastClickedButton = inputAttributes.source;
    const sObjName = inputAttributes.sObjectName;

    component.set('v.ahaId', recIdImputAtt);

    let modalHeader = '';
    if (sObjName) {
      switch (lastClickedButton) {
        case 'Arc_IFIS_BtnCancel':
          modalHeader = $A.get('$Label.arce.Arc_IFIS_BtnCancel');
          break;
        case 'Arc_IFIS_BtnReturn':
          modalHeader = $A.get('$Label.arce.Arc_IFIS_BtnReturn');
          break;
        case 'Arc_IFIS_BtnPropose':
          modalHeader = $A.get('$Label.arce.Arc_IFIS_BtnPropose');
          break;
        case 'Arc_IFIS_BtnFinalize':
          modalHeader = $A.get('$Label.arce.Arc_IFIS_BtnFinalize');
          break;
        case 'Arc_IFIS_BtnValidate':
          modalHeader = $A.get('$Label.arce.Arc_IFIS_BtnValidate');
          break;
        case 'Arc_IFIS_BtnGetRating':
          modalHeader = $A.get('$Label.arce.Arc_IFIS_BtnGetRating');
          break;
        case 'Arc_IFIS_BtnRefreshServices':
          modalHeader = $A.get('$Label.arce.Arc_IFIS_BtnRefreshServices');
          break;
        default:
          this.error(`${lastClickedButton} is not an avaliable button`, '');
      }
      component.set('v.modalHeader', modalHeader);
      component.set('v.modalButton', lastClickedButton);
    } else {
      console.log('Error', `${sObjName} not exist`);
    }
  }
});