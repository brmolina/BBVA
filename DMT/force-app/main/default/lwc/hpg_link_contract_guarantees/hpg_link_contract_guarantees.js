import { LightningElement, api } from 'lwc';

export default class Hpg_link_contract_guarantees extends LightningElement {

    @api contractId;
    @api currentDate;

    openContractGuarantees() {
      const openContractGuarantees = new CustomEvent("opencontractguarantees", {
          composed: true,
          bubbles: true,
          cancelable: true,
          detail: {
            contractId: this.contractId,
            currentDate: this.currentDate
          },
      });
      this.dispatchEvent(openContractGuarantees);
    }
}