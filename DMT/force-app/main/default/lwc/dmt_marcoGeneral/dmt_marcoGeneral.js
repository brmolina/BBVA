import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import pubsub from 'omnistudio/pubsub';

/**
 * @Name        dmt_marcoGeneral
 * @Description Pure LWC replacement for the FlexCard DMT_MarcoGeneral_V2.
 *              Acts as the page-level container: fetches initial data, passes it
 *              to dmtDealManagementWorkspace, and handles pubsub events that
 *              children fire for backend operations (Lines, Opportunities, etc.).
 *
 *              DATA LAYER: Currently stubbed with empty mock data.
 *              Will be wired to DMT_MarcoGeneral_Controller @AuraEnabled methods.
 */
export default class Dmt_marcoGeneral extends LightningElement {

    @api recordId;

    // ─── STATE ─────────────────────────────────────────────────────────────────
    _data = {};
    _connected = false;
    showSpinner = true;
    errorMessage = '';
    showError = false;

    // Context kept in sync (replaces FlexCard session vars)
    _context = {
        groupCode: null,
        ClientId: null,
        clientType: null,
        nonDisclosedCode: null,
        originGroup: null,
        countryIfoId: null,
        taxpayerId: null,
        selectedClientName: null,
        clientsByGroup: null
    };

    // ─── PAGE REFERENCE (for deep-link params) ─────────────────────────────────
    @wire(CurrentPageReference)
    currentPageReference;

    // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

    connectedCallback() {
        this._connected = true;
        this._subscribePubsub();
        this._loadInitialData();
    }

    disconnectedCallback() {
        this._connected = false;
        this._unsubscribePubsub();
    }

    // ─── GETTER: data passed to dmtDealManagementWorkspace ─────────────────────

    get workspaceData() {
        return this._data;
    }

    // ─── INITIAL DATA LOAD (stubbed — no real Apex call yet) ───────────────────

    async _loadInitialData() {
        this.showSpinner = true;
        this.showError = false;

        try {
            // TODO: Replace with Apex call:
            // const result = await launchDealManagement({ originId: this.recordId });
            const result = this._getMockData();

            this._data = { ...result };
            this._context.groupCode = result.groupCode;
            this._context.originGroup = result.originGroup;
            this._context.ClientId = result.ClientId;
            this._context.clientType = result.clientType;
        } catch (error) {
            this.errorMessage = error.body ? error.body.message : error.message;
            this.showError = true;
        } finally {
            this.showSpinner = false;
        }
    }

    // ─── PUBSUB SUBSCRIPTIONS ──────────────────────────────────────────────────
    // Replaces the FlexCard's event-bridge role.

    _subscribePubsub() {
        pubsub.register('DMT_MarcoGeneral', {
            LineManagement: this._handleLineManagement.bind(this),
            OpportunityManagement: this._handleOpportunityManagement.bind(this)
        });
    }

    _unsubscribePubsub() {
        pubsub.unregister('DMT_MarcoGeneral', {
            LineManagement: this._handleLineManagement.bind(this),
            OpportunityManagement: this._handleOpportunityManagement.bind(this)
        });
    }

    // ─── LINE MANAGEMENT EVENT HANDLER ─────────────────────────────────────────
    // Actions: CREATE_LINE_IP, CREATE_NEWLINE, REFRESH_DATA, RENEW_LINE, CREATE_RENEW_LINE

    async _handleLineManagement(payload) {
        const action = payload?.action;
        let response = {};

        try {
            switch (action) {
                case 'CREATE_LINE_IP':
                    // TODO: call createLine Apex method
                    response = {};
                    break;
                case 'CREATE_NEWLINE':
                    // TODO: call dealManagementScreen Apex method
                    response = {};
                    break;
                case 'REFRESH_DATA':
                    // TODO: call refreshData/extractOpportunityByClient
                    response = {};
                    break;
                case 'RENEW_LINE':
                    // TODO: call getRenewLineData
                    response = {};
                    break;
                case 'CREATE_RENEW_LINE':
                    // TODO: call renewLine Apex method
                    response = {};
                    break;
                default:
                    break;
            }
        } catch (error) {
            response = { error: true, errorMessage: error.body?.message || error.message };
        }

        // Send response back to children
        pubsub.fire('DMT_MarcoGeneral', 'CreateLineResponse', {
            LineResponse: response,
            taxpayerId: this._context.taxpayerId,
            selectedClientName: this._context.selectedClientName
        });
    }

    // ─── OPPORTUNITY MANAGEMENT EVENT HANDLER ──────────────────────────────────
    // Actions: GET_OPPORTUNITY_INFO, REFRESH_ENTITY, CREATE_NEW_OPPORTUNITY, REFRESH_DATA

    async _handleOpportunityManagement(payload) {
        const action = payload?.action;
        let response = {};

        try {
            switch (action) {
                case 'GET_OPPORTUNITY_INFO':
                    // TODO: call createOpp Apex method
                    response = {};
                    break;
                case 'REFRESH_ENTITY':
                    // TODO: call getEntityByEntific
                    response = {};
                    break;
                case 'CREATE_NEW_OPPORTUNITY':
                    // TODO: call dealManagementScreen with isOpportunity=true
                    response = {};
                    break;
                case 'REFRESH_DATA':
                    // TODO: call extractOpportunityByClient for opps
                    response = {};
                    break;
                default:
                    break;
            }
        } catch (error) {
            response = { error: true, errorMessage: error.body?.message || error.message };
        }

        // Send response back to children
        pubsub.fire('DMT_MarcoGeneral', 'OpportunityResponse', {
            OpportunityResponse: response,
            taxpayerId: this._context.taxpayerId,
            clientsByGroup: this._context.clientsByGroup,
            selectedClientName: this._context.selectedClientName
        });
    }

    // ─── CHILD EVENT HANDLERS (DOM events from workspace) ──────────────────────

    handleSelectClient(event) {
        // This is handled by dmtDealManagementWorkspace internally
        // but if we need to update context or fetch new data, we handle it here
    }

    handleUpdateTableLines(event) {
        const detail = event.detail || {};
        if (detail.line) {
            this._data = { ...this._data, line: detail.line };
        }
        if (detail.countType) {
            this._data = { ...this._data, countType: detail.countType };
        }
    }

    handleUpdateTableOpportunities(event) {
        const detail = event.detail || {};
        if (detail.newOpps) {
            this._data = { ...this._data, opp: detail.newOpps };
        }
    }

    // ─── MOCK DATA (empty structure matching FlexCard output) ──────────────────
    // Provides the same shape so dmtDealManagementWorkspace renders correctly
    // but with no actual records. Data will be filled in later.

    _getMockData() {
        return {
            // Lines
            line: [],
            colLine: [],
            // Opportunities
            opp: [],
            colOpp: [],
            // Counters
            countType: {
                line: { Status__c: {}, Product__c: {} },
                opp: { StageName: {} }
            },
            // Context
            groupCode: null,
            groupName: '',
            originId: this.recordId,
            originGroup: null,
            ClientId: 'norecord',
            clientType: 'client',
            // Access
            OppAccess: true,
            hasWriteAccessUser: true,
            hasLineGodAccess: false,
            // User
            UserInfo: {
                hasWriteAccessUser: true,
                hasLineGodAccess: false,
                hasAccessActions: true
            },
            // Misc
            returnedDate: null,
            viewTab: 'Lines'
        };
    }
}