import { LightningElement, api, wire } from "lwc";
import DMT_RecalcuationLine from "@salesforce/label/c.dmt_cl_recalculationLine";
import { CurrentPageReference } from "lightning/navigation";
import { NavigationMixin } from "lightning/navigation";
import launchDealManagement from "@salesforce/apex/DMT_LaunchDealManagementService.launchDealManagement";
import resolveGroupAccountId from "@salesforce/apex/DMT_LaunchDealManagementService.resolveGroupAccountId";
import getSalesforceAccountIdsByCustomerIds from "@salesforce/apex/DMT_HPG_MainTableCustomController.getSalesforceAccountIdsByCustomerIds";

// ─── CONSTANTS ───────────────────────────────────────────────────────────────
const FIELDS_LINES = ["countType", "line", "originGroup"];
const FIELDS_OPPS = ["countType", "opp"];
const FIELDS_PROFI = ["ClientId", "groupCode", "clientType"];
const FIELDS_WORKSPACE = [
    "UserInfo", "originId", "returnedDate", "groupName",
    "groupCode", "originGroup", "OppAccess", "hasOpportunityListAccess", "clientType", "ClientId","taxpayerId"
];

const ARRAY_FIELDS = ["colLine", "line", "colOpp", "opp"];
const SALESFORCE_ID_REGEX = /^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/;

function isValidSalesforceId(value) {
    return typeof value === "string" && SALESFORCE_ID_REGEX.test(value);
}

// ─── COMPONENT ───────────────────────────────────────────────────────────────

export default class DmtDealManagementWorkspace extends NavigationMixin(LightningElement) {

    originId;
    _urlRecordId;
    currentTab;
    viewTab;
    oppSelected;
    productSelected = "";
    originGroup;
    hasLoaded;
    sourceDataLoaded = false;
    currentSelectedCode; // Variable to track the currently loaded node code

    handleViewportResize = () => {
        this.updateManagementPanelHeight();
    };

    connectedCallback() {
        window.addEventListener("resize", this.handleViewportResize);
        window.visualViewport?.addEventListener("resize", this.handleViewportResize);
    }

    renderedCallback() {
        this.updateManagementPanelHeight();
    }

    disconnectedCallback() {
        window.removeEventListener("resize", this.handleViewportResize);
        window.visualViewport?.removeEventListener("resize", this.handleViewportResize);
    }

    updateManagementPanelHeight() {
        const activePanel = this.template.querySelector(
            ".slds-tabs_default__content.slds-show"
        );
        const workspace = this.template.querySelector(".main-wrapper");
        if (!activePanel || !workspace) {
            return;
        }

        const viewportHeight = window.visualViewport?.height ?? window.innerHeight;
        const panelTop = activePanel.getBoundingClientRect().top;
        const availableHeight = Math.max(0, Math.floor(viewportHeight - panelTop - 12));
        workspace.style.setProperty(
            "--dmt-management-panel-height",
            `${availableHeight}px`
        );
    }

    // ─── PUBLIC API ────────────────────────────────────────────────────────────

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (!isValidSalesforceId(value)) {
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
            
            // Initialize currentSelectedCode based on the initial payload if it's the first load
            if (!this.currentSelectedCode) {
                 this.currentSelectedCode = this.workspaceInput?.clientType === "client" 
                    ? this.workspaceInput?.ClientId 
                    : this.workspaceInput?.groupCode;
            }
        });
    }

    // ─── WIRE ──────────────────────────────────────────────────────────────────

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!pageRef) return;
        this.currentPageReference = pageRef;
        
        if (isValidSalesforceId(pageRef.state?.c__recordId)) {
            if (!this.originId || this._urlRecordId !== pageRef.state.c__recordId) {
                this.originId = pageRef.state.c__recordId;
                this._urlRecordId = pageRef.state.c__recordId;
            }
        }

        if (pageRef.state.c__viewTab === "Profitability") {
            this.activeTab = "ProfitabilityTest";
            this.profiMgmtInput = {
                ...this.profiMgmtInput,
                productSelected: pageRef.state.c__productSelected,
                oppSelected: pageRef.state.c__oppSelected,
                ClientId: this.workspaceInput?.ClientId,
                groupCode: this.workspaceInput?.groupCode
            };
        }

        if (!this.sourceDataLoaded) {
            this.loadWorkspaceData();
        }
    }

    async loadWorkspaceData(force) {
        if (!isValidSalesforceId(this.originId) || (this.sourceDataLoaded && !force)) {
            return;
        }

        try {
            this.showSpinner = true;
            
            const requestPayload = {
                originId: this.originId,
                currentTab: this.currentTab,
                viewTab: this.viewTab,
                oppSelected: this.oppSelected,
                productSelected: this.productSelected,
                originGroup: this.originGroup,
                scopeToClient: this.scopeToClient
            };

            const payload = await launchDealManagement(requestPayload);

            this.data = payload;
            this.errorService = false;
            this.showDMT = true;
        } catch (error) {
            this.errorService = true;
            this.showDMT = false;
            this.hasListAccounts = false;
        } finally {
            this.showSpinner = false;
        }
    }

    // ─── STATE ─────────────────────────────────────────────────────────────────

    activeTab = "opps";
    scopeToClient = false;
    lineMgmtInput = {};
    oppMgmtInput = {};
    profiMgmtInput = { productSelected: "", oppSelected: "" };
    workspaceInput = {};
    isExpandedSideBar = true;
    accountName = null;
    currentPageReference;

    get resolvedClientId() {
        const res = isValidSalesforceId(this.originId) ? this.originId : undefined;
        return res;
    }

    get resolvedGroupId() {
        return this.workspaceInput?.originGroup || this.originGroup || undefined;
    }
    get resolvedTaxpayerId() {
        return this.workspaceInput?.taxpayerId || this.taxpayerId || undefined;
    }

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

    get isTabLines() { return this.activeTab === "lines" }
    get isTabOpps() { return this.activeTab === "opps" }
    get isTabProfitabilityTest() { return this.activeTab === "ProfitabilityTest"}

    get isReadOnlyRole() {
        const role = this.workspaceInput.UserInfo?.DMT_User_Role__c;
        return !role || role.split(';').some(r => r.trim() === 'DMT_Read Only');
    }

    get hasAccessNewLine() {
        return this.activeTab === "lines" && this.workspaceInput.UserInfo?.hasAccessActions;
    }

    get hasAccessRecalculateApprovals() {
        return this.activeTab === "lines" && this.workspaceInput.UserInfo?.hasAccessActions && !this.isReadOnlyRole;
    }

    get showLineActionGroup() {
        return this.hasAccessNewLine || this.hasAccessRecalculateApprovals;
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

    tabClass(tab) {
        return `slds-tabs_default__item${this.activeTab === tab ? " slds-is-active" : ""}`;
    }

    tabContentClass(tab) {
        const base = "slds-tabs_default__content slds-box tabs-custom slds-m-horizontal_medium slds-m-top_small slds-p-around_small slds-p-top_none slds-p-bottom_none";
        return `${base}${this.activeTab === tab ? " slds-show" : " slds-hide"}`;
    }

    handleTabClick(event) {
        event.preventDefault();
        this.actionExecution = false;
        this.activeTab = event.currentTarget.dataset.tab;
    }

    get notErrorService(){ return !this.errorService }

    get classShowDMT(){
        return this.hasListAccounts === true ? "slds-grid slds-has-flexi-truncate main-wrapper" : "slds-grid slds-has-flexi-truncate main-wrapper slds-hidden"
    }

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
    
    handleRefreshPage() {
        window.location.reload();
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
        if (!this.sourceDataLoaded) return;
        this.showDMT = false;
        this.errorService = true;
        this.showSpinner = false;
        this.hasListAccounts = false;
    }

    async handleChangeClient(event) {
        const { clientType, subGroupName, clientName, clientId, generalGroupCode } = event.detail;
        this.showSpinner = false;

        const cType = (clientType || "").toLowerCase();
        const isClientNode = (cType === "client" || cType === "subsidiary" || cType === "customer");

        this.accountName = cType === "subgroup" ? subGroupName : clientName;

        const newCode = isClientNode ? clientId : generalGroupCode;
        

        // Compare against our component-level state variable instead of re-evaluating workspaceInput
        if (!newCode || newCode === this.currentSelectedCode) {
            return;
        }

        // Update the state variable immediately so subsequent clicks check against this new node
        this.currentSelectedCode = newCode;

        if (isClientNode) {
            let resolvedId;
            try {
                const accountIdsByCode = await getSalesforceAccountIdsByCustomerIds({ customerIds: [clientId] });
                resolvedId = accountIdsByCode?.[clientId];
            } catch (error) {
                console.error('[DMT_WORKSPACE_DEBUG] Error fetching Salesforce ID:', error);
                return;
            }
            if (!isValidSalesforceId(resolvedId)) {
                console.warn('[DMT_WORKSPACE_DEBUG] Resolved ID is not a valid Salesforce ID, aborting.');
                return;
            }
            // IMPORTANT: If we go back from Group to Client, we MUST NOT keep the originId pointing to the Group's SF ID.
            // We update originId to the actual Client Account SF ID.
            this.originId = resolvedId; 
            this.originGroup = undefined;
            this.scopeToClient = true;
        } else {
            // Resolve the Account represented by the selected group/subgroup node.
            // `_urlRecordId` cannot be used here: when Deal Management was opened from
            // a subsidiary it still points to that subsidiary, not to the selected group.
            let resolvedGroupAccountId;
            try {
                resolvedGroupAccountId = await resolveGroupAccountId({
                    groupCode: generalGroupCode
                });
            } catch (error) {
                console.error('[DMT_WORKSPACE_DEBUG] Error resolving selected group Account ID:', error);
                return;
            }
            if (!isValidSalesforceId(resolvedGroupAccountId)) {
                console.warn('[DMT_WORKSPACE_DEBUG] No Salesforce Account found for selected group:', generalGroupCode);
                return;
            }

            this.originId = resolvedGroupAccountId;
            this.originGroup = generalGroupCode;
            this.scopeToClient = false;
        }

        this.profiMgmtInput["ClientId"] = clientId;
        this.profiMgmtInput = { ...this.profiMgmtInput, productSelected: "", oppSelected: "" };
        this.sourceDataLoaded = false;
        
        await this.loadWorkspaceData(true);
    }

    _serializeFields(data, fields) {
        const subset = {};
        fields.forEach((f) => (subset[f] = data[f] ?? null));
        return JSON.stringify(subset);
    }

    _updateBlock(blockKey, rawData, fields, updater) {
        const snapshotKey = `_last${blockKey}`;
        const current = this._serializeFields(rawData, fields);
        const changed = current !== this[snapshotKey];
        if (changed) {
            this[snapshotKey] = current;
            updater();
        }
    }

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