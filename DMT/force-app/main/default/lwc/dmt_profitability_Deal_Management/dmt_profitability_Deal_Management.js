import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecordCode from '@salesforce/apex/DMT_HPG_MainTableCustomController.getRecordCode';
import getPassportByOpp from '@salesforce/apex/DMT_Profitability_Helper.getPassportByOpp';
import toastObsoletePassportTitle from "@salesforce/label/c.DMT_ProfitabilityRedirectionObsoletePassportTitle";
import toastObsoletePassportContent from "@salesforce/label/c.DMT_ProfitabilityRedirectionObsoletePassportContent";

const ERROR_TITLE = 'Error';
const ERROR_VARIANT = 'error';
const ADVERTENCIA_STRG = 'Advertencia';
const WARNING_STRG = 'warning';
const DISMISSABLE_MODE_STRG = 'dismissable';
const MSG_ERROR_NOCLIENT = 'Cannot obtain group/client record code';
const MSG_ERROR_ONVALIDATION = 'An unexpected error occurred during validation.';

export default class Dmt_profitability_Deal_Management extends LightningModal {

    @api accountId;
    @api oppId;
    @api productSelected;

    customLabels = { toastObsoletePassportTitle, toastObsoletePassportContent };

    isLoading = true;
    withErrorPassport = false;
    navigationUrl = null;

    connectedCallback() {
        this._handleKeyDown = (e) => {
            if (e.key === 'Escape') {
                e.stopImmediatePropagation();
                e.preventDefault();
            }
        };
        window.addEventListener('keydown', this._handleKeyDown, true); // capture = true
        this.tryNavigateOrShowError();
    }

    disconnectedCallback() {
        window.removeEventListener('keydown', this._handleKeyDown, true);
    }
    
    close(result) {
      // Bloquea cualquier cierre externo mientras isLoading sea true
      if (this.isLoading) return;
      super.close(result);
    }

    _buildUrl(clientId, oppId, productSelected) {
        const params = new URLSearchParams({
            c__recordId: clientId,
            c__viewTab: 'Profitability',
            c__oppSelected: oppId,
            c__productSelected: productSelected
        });
        return `/lightning/n/DMT_Page?${params.toString()}`;
    }

    NavigateMixer() {
    const clientId = this.accountId;
    const oppId = this.oppId;
    const productSelected = this.productSelected;

    getRecordCode({ clientId })
        .then(response => {
            if (!response) {
                this.dispatchEvent(new ShowToastEvent({
                    title: ERROR_TITLE,
                    message: MSG_ERROR_NOCLIENT,
                    variant: ERROR_VARIANT,
                }));
                this.close('error');
            } else {
                setTimeout(() => {
                    const url = this._buildUrl(clientId, oppId, productSelected);
                    // Abre en nueva pestaña con <a> programático — permitido por CSP
                    const a = document.createElement('a');
                    a.href = url;
                    a.target = '_blank';
                    a.rel = 'noopener noreferrer';
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    this.isLoading = false;
                    this.close('success');
                }, 1300);
            }
        })
        .catch(error => {
            console.error('Error during validation:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: ERROR_TITLE,
                message: MSG_ERROR_ONVALIDATION,
                variant: ERROR_VARIANT,
            }));
            this.close('error');
        });
}

    tryNavigateOrShowError() {
        if (this.accountId && this.oppId && this.productSelected) {
            this.isLoading = true;
            this.withErrorPassport = false;

            getPassportByOpp({ oppId: this.oppId })
                .then(data => {
                    this.withErrorPassport = data?.DMT_Is_Obsoleted_Passport_Save__c ?? false;

                    if (this.withErrorPassport) {
                        setTimeout(() => {
                            this.showWarningToast(
                                this.customLabels.toastObsoletePassportContent,
                                this.customLabels.toastObsoletePassportTitle
                            );
                            this.isLoading = false;
                            this.close('obsolete');
                        }, 1600);
                    } else {
                        this.NavigateMixer();
                    }
                })
                .catch(error => {
                    console.error('Error fetching Passport record:', error);
                    this.isLoading = false;
                    this.withErrorPassport = true;
                    this.close('error');
                });
        }
    }

    handleNavigate() {
        // El <a> ya abre en _blank, cerramos el modal tras el click
        this.close('success');
    }

    showWarningToast(message, title = ADVERTENCIA_STRG) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant: WARNING_STRG,
            mode: DISMISSABLE_MODE_STRG
        }));
    }
}