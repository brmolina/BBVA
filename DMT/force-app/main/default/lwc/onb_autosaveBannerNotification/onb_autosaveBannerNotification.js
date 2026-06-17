import { LightningElement, api } from 'lwc';

const FUNDS_SCREEN = 'funds';
const MAIN_CONTAINER_SCREEN = 'mainContainer';
const WARNING_SCREEN = 'warning';

export default class Onb_autosaveBannerNotification extends LightningElement {
    @api icon;
    @api menssage;
    @api variant;
    @api title;

    get titleDefault() {
        return this.title ? this.title : '';
    }

    get bannerStyle() {
        let bg;
        let textColor;
        switch (this.variant) {
            case FUNDS_SCREEN:
                bg = 'var(--slds-g-color-brand-base-90)';
                textColor = 'var(--slds-g-color-brand-base-40)';
                break;
            case MAIN_CONTAINER_SCREEN:
                bg = 'var(--slds-g-color-surface-container-3)';
                textColor = 'var(--slds-g-color-surface-container-10)';
                break;
            case WARNING_SCREEN:
                bg = 'var(--slds-g-color-warning-base-95)';
                textColor = 'var(--slds-g-color-warning-base-20)';
                break;
            default:
                bg = 'var(--slds-g-color-surface-container-3)';
                textColor = 'var(--slds-g-color-surface-container-10)';
        }

        return `
            background-color: ${bg};
            color: ${textColor};
            --slds-c-icon-color-foreground-default: ${textColor};
        `;
    }

}