import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

import searchClient
    from '@salesforce/apex/DMT_Client_Selector.searchClient';

import getAccountById
    from '@salesforce/apex/DMT_Client_Selector.getAccountById';

export default class LocalClientPicker extends LightningElement {

    @api clientId;

    // Se mantienen para no romper la configuración actual del Flow.
    @api entityId;
    @api mitangt;

    disabled = false;

    prospectSearchTerm = '';
    prospectResults = [];
    prospectLoading = false;
    prospectOpen = false;

    prospectSearchTimeout;
    prospectSearchSequence = 0;

    connectedCallback() {
        if (this.hasValue && this.clientId.startsWith('001')) {
            this.loadSelectedAccount();
        }
    }

    disconnectedCallback() {
        clearTimeout(this.prospectSearchTimeout);
    }

    get hasValue() {
        return (
            this.clientId &&
            this.clientId !== '' &&
            this.clientId !== 'null' &&
            this.clientId !== 'undefined'
        );
    }

    get prospectComboboxClass() {
        return this.prospectOpen
            ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'
            : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    get showProspectResults() {
        return (
            this.prospectOpen &&
            this.prospectResults.length > 0
        );
    }

    handleProspectSearch(event) {
        const searchTerm = event.target.value || '';

        this.prospectSearchTerm = searchTerm;

        clearTimeout(this.prospectSearchTimeout);

        // Invalida cualquier búsqueda anterior.
        this.prospectSearchSequence += 1;

        // Si se modifica el texto, se elimina la selección anterior.
        if (this.clientId) {
            this.clientId = null;
            this.notifyRecordSelected(null);
        }

        if (searchTerm.trim().length < 2) {
            this.prospectResults = [];
            this.prospectOpen = false;
            this.prospectLoading = false;
            return;
        }

        const currentSequence = this.prospectSearchSequence;

        this.prospectSearchTimeout = setTimeout(() => {
            this.findAccounts(
                searchTerm.trim(),
                currentSequence
            );
        }, 300);
    }

    async findAccounts(searchTerm, searchSequence) {
        this.prospectLoading = true;

        try {
            const accounts = await searchClient({
                searchTerm
            }) || [];

            // Ignora respuestas de búsquedas anteriores.
            if (
                searchSequence !== this.prospectSearchSequence ||
                this.prospectSearchTerm.trim() !== searchTerm
            ) {
                return;
            }

            this.prospectResults = accounts.map(account => ({
                id: account.Id,
                label: account.Name || 'Account',
                subtitle:
                    account.DES_Group_Code__c ||
                    account.g_customer_id__c  ||
                    ''
            }));

            this.prospectOpen =
                this.prospectResults.length > 0;

        } catch (error) {
            if (searchSequence === this.prospectSearchSequence) {
                this.prospectResults = [];
                this.prospectOpen = false;
            }

            console.error(
                'Error searching accounts:',
                error
            );
        } finally {
            if (searchSequence === this.prospectSearchSequence) {
                this.prospectLoading = false;
            }
        }
    }

    handleProspectSelect(event) {
        const recordId =
            event.currentTarget.dataset.id;

        const label =
            event.currentTarget.dataset.label;

        clearTimeout(this.prospectSearchTimeout);

        // Invalida una petición que todavía estuviese ejecutándose.
        this.prospectSearchSequence += 1;

        this.clientId = recordId;
        this.prospectSearchTerm = label;
        this.prospectResults = [];
        this.prospectOpen = false;
        this.prospectLoading = false;

        this.notifyRecordSelected(recordId);
    }

    handleProspectFocus() {
        this.prospectOpen =
            this.prospectResults.length > 0;
    }

    handleProspectBlur() {
        // Da tiempo a ejecutar el clic sobre el resultado.
        setTimeout(() => {
            this.prospectOpen = false;
        }, 200);
    }

    async loadSelectedAccount() {
        try {
            const account = await getAccountById({
                accountId: this.clientId
            });

            this.prospectSearchTerm =
                account?.Name || '';

        } catch (error) {
            console.error(
                'Error loading selected account:',
                error
            );
        }
    }

    notifyRecordSelected(recordId) {
        this.dispatchEvent(
            new CustomEvent('recordselected', {
                bubbles: true,
                composed: true,
                detail: {
                    recordId
                }
            })
        );

        this.dispatchEvent(
            new FlowAttributeChangeEvent(
                'clientId',
                recordId
            )
        );
    }
}