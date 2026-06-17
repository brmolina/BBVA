import { LightningElement, api } from 'lwc';

export default class Onb_dynamicPath extends LightningElement {
    @api steps = [];        // [{ key, label, order, status? }]
    @api currentStep;       // Step__c actual
    @api selectedStep;      // step seleccionado por click
    @api disableMarkComplete = false;

    get checkIconHref() {
        return '/_slds/icons/utility-sprite/svg/symbols.svg#check';
    }

    get selectedStepLabel() {
        const key = this.selectedStep || this.currentStep;
        return this.steps?.find(s => s.key === key)?.label || '';
    }

    get stepsUi() {
        const steps = this.steps || [];
        const currentKey = this.currentStep;
        const selectedKey = this.selectedStep || currentKey;

        const currentIdx = steps.findIndex(s => s.key === currentKey);

        return steps.map((s, idx) => {
            const isCurrent = s.key === currentKey;
            const isSelected = s.key === selectedKey;

            let liClass = 'slds-path__item';

            // completo si está antes del current
            if (currentIdx >= 0 && idx < currentIdx) {
                liClass += ' slds-is-complete';
            } else {
                liClass += ' slds-is-incomplete';
            }

            // current tiene prioridad visual
            if (isCurrent) {
                liClass = 'slds-path__item slds-is-current slds-is-active';
            } else if (isSelected) {
                // seleccionado (pero no current)
                liClass += ' slds-is-active';
            }

            return {
                ...s,
                liClass,
                ariaSelected: isSelected ? 'true' : 'false',
                tabIndex: s.clickable ? '0' : '-1'
            };
        });
    }

    handleStepClick(event) {
        const stepKey = event.currentTarget?.dataset?.stepKey;
        if (!stepKey) return;

        const step = (this.steps || []).find(s => s.key === stepKey);
        if(!step) return;
        this.dispatchEvent(new CustomEvent('stepselect', { detail: { stepKey } }));
    }

    handleMarkComplete() {
        this.dispatchEvent(new CustomEvent('markcomplete'));
    }
}