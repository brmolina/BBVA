export const CATALOG = Object.freeze({ FAMILY: 'H780', PRODUCT: 'H812', SUBPRODUCT_N1: 'H817', SUBPRODUCT_N2: 'H818' });
export const RELATIONSHIP = Object.freeze({
  L1: 'H744',
  L2: 'H926',
  L3: 'H927',
  LEVEL_1: 'L1',
  LEVEL_2: 'L2',
  LEVEL_3: 'L3'
});
export const LEVEL_PROPERTIES = Object.freeze({ familyValue: 'familyValue', productValue: 'productValue', subProductN1Value: 'subProductN1Value'});

export const MESSAGES = Object.freeze({
    FETCH_ERROR: 'Error fetching CIB catalog values.',
    ID_REQUIRED_ERROR: 'saveHandler: recordId is required to save product family selection.',
    NEXT_LEVEL_ERROR: 'Error loading next level values.',
    SAVED: 'Saved',
    UPDATE_SUCCESS: 'CIB products successfully updated.',
    UPDATE_ERROR: 'Could not save the selection. Please try again.',
    SUCCESS: 'success',
    ERROR: 'error',

    TOAST_SAVED_TITLE: 'Saved',
    TOAST_ERROR_TITLE: 'Error',
    TOAST_UPDATE_SUCCESS: 'CIB products successfully updated.',
    TOAST_UPDATE_ERROR: 'Could not save the selection. Please try again.',
    LOG_FETCH_CATALOG_ERROR: 'Error fetching CIB catalog values.',
    LOG_FETCH_COMMITMENT_ERROR: 'Error fetching Commitment values.',
    LOG_SAVE_ID_REQUIRED: 'saveHandler: recordId is required to save product family selection.',
    LOG_SAVE_ERROR: 'Error saving product family selection.',
    LOG_NEXT_LEVEL_ERROR: 'Error loading next level values.',
    LOG_LEVEL_ERROR: 'Error on levels.'  
});

export const COMMITMENT_FIELDS_DEF = Object.freeze({
    OBJECT: 'FCSC_Commitment__c',
    API: Object.freeze({FAMILY: 'FCSC_CIB_Products_Family__c',PRODUCT: 'FCSC_CIB_Products__c',
      SUBPRODUCT_N1: 'FCSC_CIB_SubProducts_N1__c',SUBPRODUCT_N2: 'FCSC_CIB_SubProducts_N2__c'
    })
  });
  
const qualify = (apiName) => `${COMMITMENT_FIELDS_DEF.OBJECT}.${apiName}`;
export const COMMITMENT_FIELDS = Object.freeze([
  qualify(COMMITMENT_FIELDS_DEF.API.FAMILY),
  qualify(COMMITMENT_FIELDS_DEF.API.PRODUCT),
  qualify(COMMITMENT_FIELDS_DEF.API.SUBPRODUCT_N1),
  qualify(COMMITMENT_FIELDS_DEF.API.SUBPRODUCT_N2)
]);