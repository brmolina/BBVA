import { LightningElement, api, wire } from 'lwc';

import getFundItems from '@salesforce/apex/ONB_FundItemController.getFundItems';
import isMassFundProductAssignmentActive from '@salesforce/apex/ONB_ProductStepController.isMassFundProductAssignmentActive';
import applyMassFundProductAssignment from '@salesforce/apex/ONB_ProductStepController.applyMassFundProductAssignment';

import onb_assignProductsToFunds from 'c/onb_assignProductsToFunds';
import onb_confirmMassToggle from 'c/onb_confirmMassToggle';

import FUND_ITEM_OBJECT from '@salesforce/schema/ONB_Fund_Item__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Labels
import ONB_FUND_NAME from '@salesforce/label/c.ONB_FUND_NAME';
import ONB_FUND_TYPE from '@salesforce/label/c.ONB_FUND_TYPE';
import ONB_LEI_CIF_STARCODE from '@salesforce/label/c.ONB_LEI_CIF_STARCODE';
import ONB_FUND_CIF from '@salesforce/label/c.ONB_FUND_CIF';
import ONB_LEI_PENDING_CREATE from '@salesforce/label/c.ONB_LEI_PENDING_CREATE';
import ONB_FUND_BANNER from '@salesforce/label/c.ONB_FUND_BANNER';
import ONB_ASSIGNED_PRODUCTS from '@salesforce/label/c.ONB_ASSIGNED_PRODUCTS';
import ONB_FUND_TOOLTIP_MSG from '@salesforce/label/c.ONB_FUND_TOOLTIP_MSG';
import ONB_FUND_COLUM_LABEL from '@salesforce/label/c.ONB_FUND_COLUM_LABEL';

const ONBOARDING_OBJECT_LINE_API_NAME = 'ONB_Fund_Item__c';
const ONBOARDING_ID_API_NAME = 'OnboardingId__c';
const ONBOARDING_ICONO = 'utility:info';

export default class OnbFundsState extends LightningElement {
  @api recordId;
  @api icono = ONBOARDING_ICONO;

  rows = [];
  wiredResult;
  fundsCacheBuster = String(Date.now());

  objectApiName = ONBOARDING_OBJECT_LINE_API_NAME;
  parentFieldApiName = ONBOARDING_ID_API_NAME;

  connectAllFundsToggleValue = false;
  isApplyingMassToggle = false;

  get leiMaxLength() {
    const field = this.objectInfo?.data?.fields?.lei_id__c;
    return field ? field.length : null;
  }

  get cifMaxLength() {
    const field = this.objectInfo?.data?.fields?.ONB_CIF__c;
    return field ? field.length : null;
  }

  @wire(getObjectInfo, { objectApiName: FUND_ITEM_OBJECT })
  objectInfo;

  requiredFieldApiNames = ['ONB_FundName__c', 'ONB_Fund_Type__c'];

  conditionalRequiredRules = [
    {
      when: (row) => !row?.ONB_LEI_Pending_Create__c,
      requiredFields: ['lei_id__c']
    }
  ];

  cellDisabledWhen = (row, col) => {
    return col.fieldName === 'lei_id__c' && !!row?.ONB_LEI_Pending_Create__c;
  };

  get columns() {
    return [
      { key: 'fundType', label: ONB_FUND_TYPE, fieldName: 'ONB_Fund_Type__c', type: 'picklist' },
      { key: 'name', label: ONB_FUND_NAME, fieldName: 'ONB_FundName__c', type: 'text' },
      { key: 'lei', label: ONB_LEI_CIF_STARCODE, fieldName: 'lei_id__c', type: 'text', maxLength: this.leiMaxLength },
      { key: 'leiPending', label: ONB_LEI_PENDING_CREATE, fieldName: 'ONB_LEI_Pending_Create__c', type: 'boolean' },
      { key: 'cif', label: ONB_FUND_CIF, fieldName: 'ONB_CIF__c', type: 'text', maxLength: this.cifMaxLength }
    ];
  }

  label = {
    ONB_FUND_BANNER,
    ONB_FUND_TOOLTIP_MSG,
    ONB_FUND_COLUM_LABEL
  };

  connectedCallback() {
    this.refreshMassToggleState();
  }

  @wire(getFundItems, { onboardingId: '$recordId', cacheBuster: '$fundsCacheBuster' })
  wiredFundItems(result) {
    this.wiredResult = result;

    if (result.data) {
      this.rows = (result.data || []).map(r => {
        return {
          Id: r.fundId,
          ONB_FundName__c: r.fundName,
          ONB_Fund_Type__c: r.fundType,
          lei_id__c: r.leiId,
          ONB_LEI_Pending_Create__c: r.leiPendingCreate,
          ONB_CIF__c: r.cif,
          OnboardingId__c: r.onboardingId
        };
      });

      this.refreshMassToggleState();
    } else if (result.error) {
      console.error(JSON.stringify(result.error));
      this.rows = [];
    }
  }

  async refreshMassToggleState() {
    if (!this.recordId || this.isApplyingMassToggle) {
      return;
    }

    try {
      this.connectAllFundsToggleValue = await isMassFundProductAssignmentActive({
        onboardingId: this.recordId
      });
    } catch (e) {
      console.error('refreshMassToggleState', e);
    }
  }

  async handleConnectRow(event) {
    const { row } = event.detail;
    const fundId = row?.Id;

    if (!fundId) {
      return;
    }

    const result = await onb_assignProductsToFunds.open({
      size: 'medium',
      header: ONB_ASSIGNED_PRODUCTS,
      recordOnboardingId: this.recordId,
      fundId
    });

    if (result?.action === 'added') {
      await this.handleRowChange();
      await this.refreshMassToggleState();
    }
  }

  async handleConnectAllFundsToggleChange(event) {
    const requestedValue = !!event.detail.value;
    const previousValue = this.connectAllFundsToggleValue;

    const modalResult = await onb_confirmMassToggle.open({
      size: 'small',
      header: requestedValue ? 'Activate automatic product association' : 'Remove product associations',
      message: requestedValue
        ? 'This action will associate all FX Spot and Bonds products to all funds.'
        : 'This action will remove all product associations from all funds, including manual selections.',
      confirmLabel: requestedValue ? 'Confirm' : 'Remove',
      cancelLabel: 'Cancel'
    });

    if (!modalResult?.confirmed) {
      this.connectAllFundsToggleValue = previousValue;
      return;
    }

    this.isApplyingMassToggle = true;

    try {
      await applyMassFundProductAssignment({
        onboardingId: this.recordId,
        enabled: requestedValue
      });

      this.connectAllFundsToggleValue = requestedValue;
      await this.handleRowChange();

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: requestedValue
            ? 'Products associated to all funds successfully.'
            : 'All product associations were removed successfully.',
          variant: 'success'
        })
      );
    } catch (e) {
      console.error('handleConnectAllFundsToggleChange', e);
      this.connectAllFundsToggleValue = previousValue;

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: e?.body?.message || 'Could not update mass product association.',
          variant: 'error'
        })
      );
    } finally {
      this.isApplyingMassToggle = false;
      await this.refreshMassToggleState();
    }
  }

  async handleRowChange() {
    this.fundsCacheBuster = String(Date.now());
  }

  @api
  validate() {
    let ok = true;

    this.template.querySelectorAll('c-onb_onboarding-table').forEach((cmp) => {
      if (cmp?.validate && !cmp.validate()) ok = false;
    });

    return ok;
  }
}