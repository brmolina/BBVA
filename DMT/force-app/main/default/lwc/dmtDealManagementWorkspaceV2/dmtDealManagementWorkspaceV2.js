import { LightningElement, api, wire } from "lwc";
import DMT_RecalcuationLine from "@salesforce/label/c.dmt_cl_recalculationLine";
import { CurrentPageReference } from "lightning/navigation";
import { NavigationMixin } from "lightning/navigation";
import launchDealManagement from "@salesforce/apex/DMT_LaunchDealManagementService.launchDealManagement";

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

/** Valid Salesforce record Id: 15 or 18 alphanumeric characters. */
const SALESFORCE_ID_REGEX = /^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/;

function isValidSalesforceId(value) {
    return typeof value === "string" && SALESFORCE_ID_REGEX.test(value);
}

// ─── COMPONENT ───────────────────────────────────────────────────────────────

export default class DmtDealManagementWorkspaceV2 extends NavigationMixin(LightningElement) {

    connectedCallback() {
        console.debug("[DMTv2] connectedCallback", {
            originId: this.originId,
            recordId: this._recordId,
            showDMT: this.showDMT,
            errorService: this.errorService
        });
    }

    originId;
    currentTab;
    viewTab;
    oppSelected;
    productSelected = "";
    originGroup;
    hasLoaded;
    sourceDataLoaded = false;

    // ─── PUBLIC API ────────────────────────────────────────────────────────────

    /**
     * recordId injected automatically on a Record Page (lightning__RecordPage),
     * or set via the App Page property. Falls back to the URL state param.
     */
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        console.debug("[DMTv2] set recordId", { value, currentOriginId: this.originId });
        this._recordId = value;
        // Guard against malformed values (e.g. an unresolved merge field from the
        // App Page "Record Id" property config, which only resolves on Record Pages).
        // Passing that straight to Apex triggers a real 500 ("invalid for action parameter 'originId' of type 'Id'").
        if (!isValidSalesforceId(value)) {
            console.warn("[DMTv2] set recordId IGNORED invalid Id format", { value });
            return;
        }
        if (value && !this.originId) {
            this.originId = value;
            this.loadWorkspaceData();
        }
    }

    @api
    get data() {
        return this.lineMgmtInput;
    }
    set data(value) {
        console.debug("[DMTv2] set data", {
            hasValue: !!value,
            keys: value ? Object.keys(value) : null,
            originId: value ? value.originId : null,
            OppAccess: value ? value.OppAccess : null
        });
        const rawData = value ?? {};
        this.sourceDataLoaded = true;
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
     * Reads URL state params on load.
     * Used to deep-link directly into the Profitability tab with a pre-selected product/opp.
     */
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!pageRef) return;
        console.debug("[DMTv2] wire CurrentPageReference", { state: pageRef.state });
        this.currentPageReference = pageRef;
        // Only overwrite originId when the URL state actually carries it,
        // otherwise an early wire fire would wipe a valid id and trigger a failed load.
        if (isValidSalesforceId(pageRef.state?.c__recordId)) {
            this.originId = pageRef.state.c__recordId;
        }
        this.currentTab = pageRef.state?.c__currentTab || "Lines";
        this.viewTab = pageRef.state?.c__viewTab || this.currentTab;
        this.oppSelected = pageRef.state?.c__oppSelected;
        this.productSelected = pageRef.state?.c__productSelected || "";
        this.originGroup = pageRef.state?.c__originGroup;

        if (pageRef.state.c__viewTab === "Profitability") {
            this.activeTab = "ProfitabilityTest";
            this.profiMgmtInput = {
                ...this.profiMgmtInput,
                productSelected: pageRef.state.c__productSelected,
                oppSelected: pageRef.state.c__oppSelected
            };
        }

        this.loadWorkspaceData();
    }

    async loadWorkspaceData() {
        console.debug("[DMTv2] loadWorkspaceData ENTER", {
            originId: this.originId,
            sourceDataLoaded: this.sourceDataLoaded
        });
        if (!isValidSalesforceId(this.originId) || this.sourceDataLoaded) {
            console.debug("[DMTv2] loadWorkspaceData SKIP (invalid/missing originId or already loaded)");
            return;
        }

        try {
            this.showSpinner = true;
            const payload = await launchDealManagement({
                originId: this.originId,
                currentTab: this.currentTab,
                viewTab: this.viewTab,
                oppSelected: this.oppSelected,
                productSelected: this.productSelected,
                originGroup: this.originGroup
            });

            console.debug("[DMTv2] launchDealManagement OK", {
                keys: payload ? Object.keys(payload) : null,
                originId: payload ? payload.originId : null
            });
            this.data = payload;
            this.errorService = false;
            this.showDMT = true;
        } catch (error) {
            console.error("[DMTv2] launchDealManagement ERROR", error);
            this.errorService = true;
            this.showDMT = false;
            this.hasListAccounts = false;
        } finally {
            this.showSpinner = false;
            console.debug("[DMTv2] loadWorkspaceData EXIT", {
                showDMT: this.showDMT,
                errorService: this.errorService,
                showSpinner: this.showSpinner
            });
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
    showDMT = false;
    hasListAccounts = false;
    showSpinner = true;
    showScheduleSummaryModal = false;
    scheduleSummaryData = null;

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

    handleOpenScheduleSummaryModal() {
        this.showScheduleSummaryModal = true;
    }

    handleCloseScheduleSummaryModal() {
        this.showScheduleSummaryModal = false;
    }

    handleScheduleSummarySave(event) {
        this.scheduleSummaryData = event.detail;
        this.showScheduleSummaryModal = false;
    }

    serviceError(event) {
        console.warn("[DMTv2] serviceError RECEIVED lwcerror", {
            sourceDataLoaded: this.sourceDataLoaded,
            showDMT: this.showDMT,
            detail: event && event.detail,
            originId: this.originId,
            workspaceOriginId: this.workspaceInput && this.workspaceInput.originId
        });
        // Ignore transient child errors (e.g. hpg_main_table's lwcerror) fired while the
        // workspace data is still loading and children may have mounted with an empty clientId.
        // Only surface the "service unavailable" screen once the initial data has arrived.
        if (!this.sourceDataLoaded) {
            console.warn("[DMTv2] serviceError IGNORED (data not loaded yet)");
            return;
        }
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