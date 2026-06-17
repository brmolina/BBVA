({
  initEng: function(component, event, helper) {
    let attributesEventJson = {
      uniqueNameEvt: 'EEFF'
    };
    let closeModalActionJson = {
      name: 'cmpw:GBL_ComponentWrapperRefresh_Evt',
      attributes: attributesEventJson
    };
    let modalFromButtonJson = {
      modalCss: 'slds-modal_medium',
      labelButton: 'Add FFSS',
      editMode: true,
      variantButton: 'brand',
      iconButton: '',
      positionButton: 'left',
      headerModal: 'FFSS',
      closeButtonModal: true,
      closeModalActionEvt: closeModalActionJson
    };

    let attributesJson = {
      isFinancialRAIP: true,
      isProposal: true,
      proposalFolderArceId: component.get('v.recordId'),
      userCanEdit: component.get('v.userCanEdit')
    };

    let componentsJson = {name: 'arce:arcGenOrderFFSS', inModalFromButton: modalFromButtonJson, attributes: attributesJson};
    let componentsListJson = [ componentsJson ];
    let json = {orientation: 'vertical', components: componentsListJson};

    component.set('v.jsonInput', JSON.stringify(json));
    component.set('v.isJsonLoad', true);

    $A.createComponent(
      'cmpw:GBL_ComponentWrapper_CMP',
      {
        'uniqueName': 'EEFF',
        'jsonInput': JSON.stringify(json),
        'buttonsMode': component.get('v.buttonsMode'),
        'recordId': component.get('v.ahaId')
      },
      function(newCmp, status, errorMessage) {
        if (status === 'SUCCESS') {
          var contentToDisplay = [];
          contentToDisplay.push(newCmp);
          component.set('v.body', contentToDisplay);
        }
      }
    );
  },
});