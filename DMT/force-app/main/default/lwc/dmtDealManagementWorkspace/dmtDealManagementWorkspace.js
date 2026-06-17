import { LightningElement, api, wire } from "lwc";
import DMT_RecalcuationLine from "@salesforce/label/c.dmt_cl_recalculationLine";
import { CurrentPageReference } from "lightning/navigation";
import { NavigationMixin } from "lightning/navigation";
import launchDealManagement from "@salesforce/apex/DMT_LaunchDealManagementIPService.execute";
import extractData from '@salesforce/apex/DMT_ExtractOpportunityByClientApex.executeFromLWC';

// ─── CONSTANTS ───────────────────────────────────────────────────────────────

/** Fields forwarded to each child component — scoped to avoid full-object rerenders */
const FIELDS_LINES = ["countType", "line", "originGroup"];
const FIELDS_OPPS = ["countType", "opp"];
const FIELDS_PROFI = ["ClientId", "groupCode", "clientType"];
const FIELDS_WORKSPACE = [
    "UserInfo", "originId", "returnedDate", "groupName",
    "groupCode", "originGroup", "OppAccess", "clientType", "ClientId"
];

/** Fields that must always be arrays, never null */
const ARRAY_FIELDS = ["colLine", "line", "colOpp", "opp"];

// ─── COMPONENT ───────────────────────────────────────────────────────────────

export default class DmtDealManagementWorkspace extends NavigationMixin(LightningElement) {

    originId;
    currentTab;
    viewTab;
    oppSelected;
    productSelected = "";
    originGroup;
    hasLoaded;

    // ─── PUBLIC API ────────────────────────────────────────────────────────────

    @api
    get data() {
        return this.lineMgmtInput;
    }
    set data(value) {
        const rawData = value ?? {};
        this.hasListAccounts = true;


        this._updateBlock("Lines", rawData, FIELDS_LINES, () => {
            this.lineMgmtInput = this.mapData(rawData, FIELDS_LINES);
        });
        this._updateBlock("Opps", rawData, FIELDS_OPPS, () => {
            this.oppMgmtInput = this.mapData(rawData, FIELDS_OPPS);
        });
        this._updateBlock("Profi", rawData, FIELDS_PROFI, () => {
            this.profiMgmtInput = { ...this.profiMgmtInput, ...this.mapData(rawData, FIELDS_PROFI) };
        });
        this._updateBlock("Workspace", rawData, FIELDS_WORKSPACE, () => {
            this.workspaceInput = this.mapData(rawData, FIELDS_WORKSPACE);
        });

    }

    // ─── WIRE ──────────────────────────────────────────────────────────────────
        /**
     * Get alldata from Apex.
     */

    // @wire(launchDealManagement, {
    //     originId: "$originId"
    // })
    // wiredLaunchDealManagement({ data, error }) {
    //         if (this.hasLoaded) {
    //             return; // 🔥 evita repetir llamadas
    //         }

    //         if (!this.originId) {
    //             return; // 🔥 no llames con null
    //         }
    //         console.log('WIRE VALUE', JSON.stringify(data));
    //     if (data) {
    //         this.hasLoaded = true;
    //         const rawData = data ?? {};
    //         this.errorService = false;
    //         this.showDMT = true;
    //         this.hasListAccounts = true;
    //         this.showSpinner = false;

    //         this._updateBlock("Lines", rawData, FIELDS_LINES, () => {
    //             this.lineMgmtInput = this.mapData(rawData, FIELDS_LINES);
    //         });

    //         this._updateBlock("Opps", rawData, FIELDS_OPPS, () => {
    //             this.oppMgmtInput = this.mapData(rawData, FIELDS_OPPS);
    //         });

    //         this._updateBlock("Profi", rawData, FIELDS_PROFI, () => {
    //             this.profiMgmtInput = {
    //                 ...this.profiMgmtInput,
    //                 ...this.mapData(rawData, FIELDS_PROFI)
    //             };
    //         });

    //         this._updateBlock("Workspace", rawData, FIELDS_WORKSPACE, () => {
    //             this.workspaceInput = this.mapData(rawData, FIELDS_WORKSPACE);
    //         });
    //     } else {
    //         console.error("Error calling launchDealManagement Apex", error);
    //         this.showDMT = false;
    //         this.errorService = true;
    //         this.showSpinner = false;
    //         this.hasListAccounts = false;
    //     }
    // }

    /**
     * Reads URL state params on load.
     * Used to deep-link directly into the Profitability tab with a pre-selected product/opp.
     */
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!pageRef) return;
        this.currentPageReference = pageRef;
        this.originId = pageRef.state?.c__recordId;console.log('originId',this.originId);

        if (pageRef.state.c__viewTab === "Profitability") {
            this.activeTab = "ProfitabilityTest";
            this.profiMgmtInput = {
                ...this.profiMgmtInput,
                productSelected: pageRef.state.c__productSelected,
                oppSelected: pageRef.state.c__oppSelected
            };
        }
    }

    // ─── STATE ─────────────────────────────────────────────────────────────────

    activeTab = "lines";

    lineMgmtInput = {};
    oppMgmtInput = {};
    profiMgmtInput = { productSelected: "", oppSelected: "" };
    workspaceInput = {};

    isExpandedSideBar = true;
    accountName = null;
    currentPageReference;

    /** JSON snapshots per block — used by _updateBlock to detect changes */
    _lastLines = null;
    _lastOpps = null;
    _lastProfi = null;
    _lastWorkspace = null;
    actionExecution = false;
    errorService = false;
    showDMT = true;
    hasListAccounts = false;
    showSpinner = true;

    labels = { DMT_RecalcuationLine };

    // ─── TAB GETTERS ───────────────────────────────────────────────────────────

    get isTabLines() { return this.activeTab === "lines" }// && this.showDMT; }
    get isTabOpps() { return this.activeTab === "opps" }//&& this.showDMT; }
    get isTabProfitabilityTest() { return this.activeTab === "ProfitabilityTest"}// && this.showDMT; }

    /** Show header action buttons only when the user has access and the relevant tab is active */
    get hasAccessActionLines() {
        return this.activeTab === "lines" && this.workspaceInput.UserInfo?.hasAccessActions;
    }
    get hasAccessActionOpp() {
        return this.activeTab === "opps" && this.workspaceInput.UserInfo?.hasAccessActions;
    }

    get tabClassLines() { return this.tabClass("lines"); }
    get tabClassOpps() { return this.tabClass("opps"); }
    get tabClassProfitabilityTest() { return this.tabClass("ProfitabilityTest"); }

    get tabContentClassLines() { return this.tabContentClass("lines"); }
    get tabContentClassOpps() { return this.tabContentClass("opps"); }
    get tabContentClassProfitabilityTest() { return this.tabContentClass("ProfitabilityTest"); }

    // ─── TAB HELPERS ───────────────────────────────────────────────────────────

    tabClass(tab) {
        return `slds-tabs_default__item${this.activeTab === tab ? " slds-is-active" : ""}`;
    }

    tabContentClass(tab) {
        const base = "slds-tabs_default__content slds-box tabs-custom slds-m-horizontal_medium " +
            "slds-m-top_small slds-p-around_small slds-p-top_none slds-p-bottom_none";
        return `${base}${this.activeTab === tab ? " slds-show" : " slds-hide"}`;
    }

    handleTabClick(event) {
        event.preventDefault();
        this.actionExecution = false;
        this.activeTab = event.currentTarget.dataset.tab;
    }

    // ─── UX GETTERS ───────────────────────────────────────────────────────
    get notErrorService(){
        return !this.errorService
    }

    get classShowDMT(){
        return this.hasListAccounts === true ? "slds-grid slds-has-flexi-truncate main-wrapper" : "slds-grid slds-has-flexi-truncate main-wrapper slds-hidden"
    }

    // ─── SIDEBAR GETTERS ───────────────────────────────────────────────────────

    get isExpandedSideBarClass() {
        return this.isExpandedSideBar
            ? "slds-col slds-size_4-of-12 slds-has-flexi-truncate sidebar-col"
            : "sidebar slds-col slds-size_1-of-12 slds-has-flexi-truncate sidebar-col";
    }

    get isExpandedContentClass() {
        return this.isExpandedSideBar
            ? "slds-col slds-size_8-of-12 slds-has-flexi-truncate content-col"
            : "content slds-col slds-size_11-of-12 slds-has-flexi-truncate content-col";
    }

    // ─── HEADER ACTIONS ────────────────────────────────────────────────────────

    /**
     * Routes header button clicks to the correct child component.
     * "help" opens the external NoteBookLM link; the rest are delegated to the active tab's child.
     */
    async handleHeaderAction(event) {
        const action = event.currentTarget.dataset.action;

        const selectorMap = {
            opps: "c-dmt-opportunities-managment-content",
            lines: "c-dmt-lines-management-content"
        };

        const selector = selectorMap[this.activeTab];
        if (selector) {
            this.actionExecution = true;
            this.actionExecution = !(await this.template.querySelector(selector)?.handleHeaderAction(action));

        }
    }
    
    handleSidebarToggle(event) {
        this.isExpandedSideBar = event.detail.isExpanded;
    }

    serviceError(event) {
        this.showDMT = false;
        this.errorService = true;
        this.showSpinner = false;
        this.hasListAccounts = false;
    }

    /**
     * Fires when the user selects a different client in the sidebar.
     * Resets Profitability tab selections if the active account has changed.
     */

        handleChangeClient(event) {
       
        const { clientType, subGroupName, clientName, clientId, generalGroupCode } = event.detail;
        this.showSpinner = false;


        this.accountName = clientType === "subgroup" ? subGroupName : clientName;

        const oldCode = this.workspaceInput.clientType === "client"
            ? this.workspaceInput.ClientId
            : this.workspaceInput.groupCode;

        const newCode = clientType === "client" ? clientId : generalGroupCode;

        if (oldCode !== "norecord" && newCode !== oldCode && this.activeTab === "ProfitabilityTest") {
            this.profiMgmtInput = { ...this.profiMgmtInput, productSelected: "", oppSelected: "" };
        }
    }

    // handleChangeClient(event) {
    //     console.log('select client', JSON.stringify(event.detail));

    //     const { clientType, subGroupName, clientName, clientId, generalGroupCode } = event.detail;

    //     this.accountName = clientType === "subgroup" ? subGroupName : clientName;
    //     //this.originId = clientId;

    //     let clientIdParam = null;
    //     let groupCodeParam = null;

    //     if (clientType === "client") {
    //         clientIdParam = clientId;
    //     } else {
    //         groupCodeParam = generalGroupCode;
    //     }

    //     let nonDisclosedCode = null;
    //     if (this.originGroup === 'GXXXXXXXXXXXXXX') {
    //         nonDisclosedCode = 'GXXXXXXXXXXXXXX';
    //     }

    //     this.showSpinner = true;

    //     extractData({
    //         groupCode: groupCodeParam,
    //         clientId: clientIdParam,
    //         currentTab: this.activeTab,
    //         viewTab: this.activeTab,
    //     })
    //     .then(data => {
    //         console.log('APEX RESULT', JSON.stringify(data));

    //         const rawData = data ?? {};

    //         this._updateBlock("Lines", rawData, FIELDS_LINES, () => {
    //             this.lineMgmtInput = this.mapData(rawData, FIELDS_LINES);
    //         });

    //         this._updateBlock("Opps", rawData, FIELDS_OPPS, () => {
    //             this.oppMgmtInput = this.mapData(rawData, FIELDS_OPPS);
    //         });

    //         this._updateBlock("Profi", rawData, FIELDS_PROFI, () => {
    //             this.profiMgmtInput = {
    //                 ...this.profiMgmtInput,
    //                 ...this.mapData(rawData, FIELDS_PROFI)
    //             };
    //         });

    //         // this._updateBlock("Workspace", rawData, FIELDS_WORKSPACE, () => {
    //         //     this.workspaceInput = this.mapData(rawData, FIELDS_WORKSPACE);
    //         // });

    //         this.errorService = false;
    //         this.showDMT = true;
    //         this.hasListAccounts = true;
    //     })
    //     .catch(error => {
    //         console.error("Error calling Apex", error);
    //         this.showDMT = false;
    //         this.errorService = true;
    //         this.hasListAccounts = false;
    //     })
    //     .finally(() => {
    //         this.showSpinner = false;
    //     });
    // }

    // ─── DATA HELPERS ──────────────────────────────────────────────────────────

    /**
     * Serializes only the subset of fields relevant to a block.
     * Comparing this string avoids re-rendering children when unrelated fields change.
     */
    _serializeFields(data, fields) {
        const subset = {};
        fields.forEach((f) => (subset[f] = data[f] ?? null));
        return JSON.stringify(subset);
    }

    /**
     * Generic diff-and-update for a data block.
     * Runs the update callback only when the serialized snapshot has changed.
     */
    _updateBlock(blockKey, rawData, fields, updater) {
        const snapshotKey = `_last${blockKey}`;
        const current = this._serializeFields(rawData, fields);
        if (current !== this[snapshotKey]) {
            this[snapshotKey] = current;
            updater();
        }
    }

    /**
     * Extracts and normalizes the given fields from raw data.
     * Fields listed in ARRAY_FIELDS are guaranteed to be arrays.
     */
    mapData(d, fields) {
        const mapped = {};
        fields.forEach((f) => {
            mapped[f] = ARRAY_FIELDS.includes(f)
                ? (Array.isArray(d[f]) ? d[f] : [])
                : (d[f] ?? null);
        });
        return mapped;
    }
}