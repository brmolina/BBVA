import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';
import getRecordId from '@salesforce/apex/DMT_ViewController.getRecordId';
import getItemsToDisplay from '@salesforce/apex/DMT_ViewController.getItemsToDisplay';
import loadComponentsForView from '@salesforce/apex/DMT_ViewController.loadComponentsForView';
import getFeatures from '@salesforce/apex/DMT_ViewController.getFeatures';
import LINE_CURRENCYISOCODE_FIELD from '@salesforce/schema/DMT_Line__c.CurrencyIsoCode';
import OPP_CURRENCYISOCODE_FIELD from '@salesforce/schema/Opportunity.CurrencyIsoCode';
import CASE_CURRENCYISOCODE_FIELD from '@salesforce/schema/Case.CurrencyIsoCode';

export default class Dmt_view_lwc extends LightningElement {
    // ---------------- Public/Tracked API ----------------
    @track downloadInProgress = false;

    @api viewType = null;               // 'Line_Treasury', 'Line', 'Opportunity', 'Case'
    @api objectApiName = null;
    @api recordTypeApiName = null;
    @api currencyIsoCode = null;

    // Selected items (public setter)
    _selectedItems = [];
    @api
    set selectedItems(value) {
        this._selectedItems = value;
        this.updateItemsToDisplay();
    }
    get selectedItems() { return this._selectedItems; }

    // External kickoffs used by parent
    _oppId = null;
    _prodId = null;
    @api
    set oppId(value) {
        console.log('set oppId, ', value);
        if(value) {
            this._oppId = value;
            this.recordOrLineId = value;
            this.objectApiName = 'Opportunity';
            this.viewType = 'Opportunity';
            this.recordTypeApiName = 'DMT_Opportunity';
            if (this._prodId) {
                this.getItemsToDisplay();
            }
        }
    }
    get oppId() { return this._oppId; }

    @api
    set prodId(value) {
        if(value){
            this._prodId = value;
            if (this._oppId) {
                this.recordId = this._oppId;
                this.recordOrLineId = this._oppId;
                this.objectApiName = 'Opportunity';
                this.viewType = 'Opportunity';
                this.recordTypeApiName = 'DMT_Opportunity';
                this.getItemsToDisplay();
            }
        }
    }
    get prodId() { return this._prodId; }

    // ---------------- Internal State ----------------
    hasImage = false;

    // Features cache
    featuresData = [];            // last good features array
    _featuresSourceId = null;     // recordOrLineId used to fetch the cached features

    // record/line ID backing fields
    _recordId = null;
    recordOrLineId = null;
    prevRecordOrLineId = null;

    // UI / render state
    @track itemsToDisplay = [];
    isLoading = true;
    isRendered = false;
    isDownload = false;
    showDownloadPdf = true;

    jsonForPdf = '';
    vfPageUrl = '';

    // Request token to avoid stale overwrites
    _requestToken = 0;

    // Retry policy for error-only HTML
    MAX_RETRIES = 5;
    retryCount = 0;

    @track wiredFields = [];

    // Orchestrator state
    _orchTimer = null;                  // debounced schedule
    _runId = 0;                         // increment per pass
    _lastRenderedState = null;
    _lastRenderedSignature = '';        // dedupe renders

    finalErrorMessage = '';

    // ----------------------------------------------------
    // recordId accessor
    // ----------------------------------------------------
    get recordId() { return this._recordId; }

    @api
    set recordId(value) {
        if(value){
            console.log('setRecordId, ', value);
            this._recordId = value;
            this.recordOrLineId = value;
            this._onIncomingRecordOrLineIdChange();
        }
    }

    // ----------------------------------------------------
    // Wires
    // ----------------------------------------------------
    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    wiredRecordUi({ error, data }) {
        if (data) {
            this.recordOrLineId = this.recordId;
            const detectedApiName = data.records[this.recordId].apiName;
            console.log('detectedApiname, ', detectedApiName);
            if (this.objectApiName !== detectedApiName) {
                this.objectApiName = detectedApiName;
            }

            if (this.objectApiName === 'DMT_Line__c') {
                this.wiredFields = [LINE_CURRENCYISOCODE_FIELD];
            } else if (this.objectApiName === 'Opportunity') {
                this.viewType = 'Opportunity';
                this.recordTypeApiName = 'DMT_Opportunity'
              //  this.oppId = this.recordId;
                this.wiredFields = [OPP_CURRENCYISOCODE_FIELD];
            } else if (this.objectApiName === 'Case') {
                this.wiredFields = [CASE_CURRENCYISOCODE_FIELD];
            }
       //     this._onIncomingRecordOrLineIdChange();
            this.tryInit();
        } else if (error) {
            console.error('Error retrieving object info:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$wiredFields' })
    wiredRecord({ error, data }) {
        if (data) {
            if (this.objectApiName === 'DMT_Line__c') {
                this.currencyIsoCode = getFieldValue(data, LINE_CURRENCYISOCODE_FIELD);
            } else if (this.objectApiName === 'Opportunity') {
                this.currencyIsoCode = getFieldValue(data, OPP_CURRENCYISOCODE_FIELD);
            } else if (this.objectApiName === 'Case') {
                this.currencyIsoCode = getFieldValue(data, CASE_CURRENCYISOCODE_FIELD);
            }
         //   this._onIncomingRecordOrLineIdChange();
            this.tryInit();
        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }

    // ----------------------------------------------------
    // Token/DOM helpers (DRY)
    // ----------------------------------------------------
    _startNewRender() {
        this._requestToken += 1;
        const token = this._requestToken;
        console.log(`[ _startNewRender ] bumped token -> ${token}`);
        this._clearHtmlContainer();  // DRY: use same method
        this.isLoading = true;
        this.isRendered = false;
        this.jsonForPdf = '';
        return token;
    }

    _isStale(token) {
        const stale = token !== this._requestToken;
        if (stale) console.warn(`[ _isStale ] token ${token} is stale. current: ${this._requestToken}`);
        return stale;
    }

    _clearHtmlContainer() {
        this.vfPageUrl = '';
        const contentHtml = this.template && this.template.querySelector
            ? this.template.querySelector('.htmlContent')
            : null;
        if (contentHtml) {
            try { contentHtml.innerHTML = ''; } catch (e) { /* ignore */ }
        }
    }

    // ----------------------------------------------------
    // Readiness + init
    // ----------------------------------------------------
    isReady() {
        console.log('isReady check this.selectedItems.length:', this._selectedItems.length);
        console.log('isReady check this.recordOrLineId:', this.recordOrLineId);
            console.log('isReady check this.recordTypeApiName:', this.recordTypeApiName);
        console.log('isReady check this.objectApiName:', this.objectApiName);
        console.log('isReady check this.viewType:', this.viewType);
        const hasLimitVisual = this._selectedItems.some(i => i.component === 'Limit Visual');
        console.log('isReady check hasLimitVisual:', hasLimitVisual);
        console.log('isReady check this.currencyIsoCode:', this.currencyIsoCode);
        return (
            this._selectedItems.length > 0 &&
            this.recordOrLineId != null &&
            this.recordTypeApiName != null &&
            this.objectApiName != null &&
            this.viewType != null
        ) && (hasLimitVisual ? !!this.currencyIsoCode : true);
    }

    tryInit() {
        if (this.isReady()) {
            // No chaining here — just (re)run orchestrator debounced
            this.scheduleOrchestrate('tryInit');
        } else {
            console.log('[tryInit] Not ready yet — skipping orchestrator.');
        }
    }

    // Debounced orchestrator
    scheduleOrchestrate(reason = 'unspecified', delayMs = 400) {
        if (this._orchTimer) {
            clearTimeout(this._orchTimer);
            this._orchTimer = null;
        }
        this._orchTimer = setTimeout(() => {
            this._orchestratePass(reason).catch(e => console.error('[orchestrate] unhandled:', e));
        }, delayMs);
    }

    // ----------------------------------------------------
    // Lifecycle
    // ----------------------------------------------------
    connectedCallback() {
        // Infer object/type if provided via @api type
        if (this.viewType != null && this.viewType !== '') {
            switch (this.viewType) {
                case 'Line_Treasury':
                    this.objectApiName = 'DMT_Line__c';
                    this.recordTypeApiName = 'TreasurySettlement';
                    break;
                case 'Line':
                    this.objectApiName = 'DMT_Line__c';
                    this.recordTypeApiName = 'OtherProducts';
                    break;
                case 'Opportunity':
                    this.objectApiName = 'Opportunity';
                    this.recordTypeApiName = 'DMT_Opportunity';
                    break;
                case 'Case':
                    this.objectApiName = 'Case';
                    this.recordTypeApiName = 'Approval';
                    break;
                default:
                    console.warn('selected type not recognized:', this.viewType);
                    break;
            }
        } else {
            // Default to Case/Opportunity if not explicitly set
            this.viewType = this.objectApiName == 'Case' ? 'Case' : 'Opportunity';
        }

        if ((this.recordOrLineId == null || this.recordOrLineId === '') && this.objectApiName != null && this.recordTypeApiName != null) {
            // recordId missing, fetch it -> will call tryInit when ready
            this.getRecordId();
        } else if (this._selectedItems.length === 0 && this.recordOrLineId && this.objectApiName != null) {
            // items missing, fetch them -> will call tryInit when ready
            this.getItemsToDisplay();
        } else {
            // everything already ready, we can init directly
            this.tryInit();
        }
    }

    // ----------------------------------------------------
    // Apex helpers
    // ----------------------------------------------------
    async getRecordId() {
        await getRecordId({ objectApiName: this.objectApiName, recordTypeApiName: this.recordTypeApiName })
            .then(result => {
                const parsed = JSON.parse(result);
                this.recordId = parsed.Id;
                this.currencyIsoCode = parsed.CurrencyIsoCode;
                this.recordOrLineId = this.recordId;
                this.tryInit();
            }).catch(error => {
                console.error('Error in getRecordId:', error);
            });
    }

    async getItemsToDisplay() {
        console.log('getItemsToDisplay recordOrLineId, ', this.recordOrLineId);
        console.log('getItemsToDisplay objectApiName, ', this.objectApiName);
        try {
            const result = await getItemsToDisplay({ recordOrLineId: this.recordOrLineId, objectApiName: this.objectApiName});
            if (result) {
                const parsed = JSON.parse(result);
                this._selectedItems = JSON.parse(parsed.items);
                this.recordId = parsed.recordId;
                this.recordTypeApiName = parsed.recordTypeApiName;
                this.viewType = parsed.viewType;
                this.updateItemsToDisplay();
            }
        } catch (e) {
            console.error('[getItemsToDisplay] error:', e);
        }
    }

    // ----------------------------------------------------
    // Incoming ID changes
    // ----------------------------------------------------
    async _onIncomingRecordOrLineIdChange() {
        if (!this.recordOrLineId) return;
        if (this.prevRecordOrLineId === this.recordOrLineId) return;

        // reset charts/features whenever record changes
        this.hasImage = false;
        this.featuresData = [];
        this._featuresSourceId = null;
        this.currencyIsoCode = null;

        this._lastRenderedState = null;
        this._lastRenderedSignature = '';

        this.retryCount = 0;

        this._startNewRender(); // cancel outstanding renders

        // fetch items if empty; updateItemsToDisplay() decides if init is needed
        if (!this._selectedItems || this._selectedItems.length === 0) {
            try {
                await this.getItemsToDisplay();
            } catch (e) {
                console.error('[onIncomingRecordOrLineIdChange] getItemsToDisplay failed', e);
            }
        }
    }

    // ----------------------------------------------------
    // Items update
    // ----------------------------------------------------
    async updateItemsToDisplay() {
        console.log('updateItemsToDisplay called');
        const prev = JSON.stringify(this.itemsToDisplay);
        const next = JSON.stringify(this._selectedItems);
        console.log('updateItemsToDisplay, prev vs next:', prev, '---', next);

        if (prev !== next) {
            this.hasImage = false;
            this.featuresData = [];
            this._featuresSourceId = null;

            this._lastRenderedState = null;
            this._lastRenderedSignature = '';

            this.retryCount = 0;
            this.itemsToDisplay = [...this._selectedItems];
            this.tryInit();
        }

        if (this.recordOrLineId && this.recordOrLineId !== this.prevRecordOrLineId) {
            this.hasImage = false;
            this.prevRecordOrLineId = this.recordOrLineId;
            this.tryInit();
        }
    }

    // ----------------------------------------------------
    // Orchestrator (single-pass)
    // ----------------------------------------------------
    async _orchestratePass(reason) {
        try {
            const myRun = ++this._runId;
            console.log(`[orchestrate] START (run ${myRun}) reason: ${reason}`);

            // Pre-check: Are we ready to fetch/render?
            if (!this.isReady()) {
                console.log('[orchestrate] Not ready, skipping pass.');
                return;
            }

            // 1 Ensure selected items are present
            if (!this._selectedItems || this._selectedItems.length === 0) {
                await this.getItemsToDisplay();
                if (myRun !== this._runId) return; // state changed mid-run
            }

            const hasLimitVisual = this._selectedItems.some(i => i.component === 'Limit Visual');

            // 2 For Limit Visual we need currency
            if (hasLimitVisual && !this.currencyIsoCode) {
                // wait for currency to arrive, retry later
                this.scheduleOrchestrate('await-currency', 400);
                return;
            }

            // 3️ FEATURES fetch (only if record changed or never fetched)
            let features = this.featuresData;
            const recordStable = this._featuresSourceId === this.recordOrLineId;
            const shouldFetchFeatures = hasLimitVisual && (!recordStable || !features);

            if (shouldFetchFeatures) {
                const resp = await getFeatures({ id: this.recordOrLineId });
                console.log('getFeatures response, ', JSON.stringify(resp));
                if (myRun !== this._runId) return;

                this.featuresData = resp || [];
                this._featuresSourceId = this.recordOrLineId;

                console.log(`[orchestrate] Features fetched, count: ${this.featuresData.length}`);
            }

            // 4️ Build chart inputs
            let allLimits = null;
            let profitability = null;
            this.hasImage = false;
            if (hasLimitVisual && this.featuresData.length > 0) {
                const build = this.buildChartInputs(this.featuresData);
                if (myRun !== this._runId) return;

                allLimits = build.allLimits;
                this.hasImage = build.hasImage;
                profitability = build.profitability;
            }

            // 5 Images
            let imageData = null;
           if (this.hasImage) {
                let dataToPass = this.recordTypeApiName === 'DMT_Opportunity' ? profitability : allLimits;

                if (dataToPass) {
                    imageData = await this.getImageB64(dataToPass, this._requestToken);
                    if (myRun !== this._runId) return;
                }
            }

            // 6 Final render: always render if ready and state changed
            const stateChanged = !this._lastRenderedState ||
                this._lastRenderedState.features !== this.featuresData ||
                this._lastRenderedState.hasImage !== this.hasImage ||
                this._lastRenderedState.imageData !== imageData;

                console.log('stateChanged, ', stateChanged);
            if (stateChanged) {
                const token = this._startNewRender();
                await this._fetchAndMaybeRender(token, imageData, !!this.hasImage, myRun);

                this._lastRenderedState = {
                    features: this.featuresData,
                    hasImage: this.hasImage,
                    imageData
                };
            } else {
                console.log('[orchestrate] Skipping render (no change).');
            }

            console.log(`[orchestrate] END (run ${myRun})`);
        } catch (e) {
            console.error('[orchestrate] unhandled error:', e);
        }
    }

    // Fetch + render (single place that calls loadComponentsForView and paints)
    async _fetchAndMaybeRender(token, imageData, hasImage, myRun) {
        // Build a signature to avoid duplicate renders
        const signature = JSON.stringify({
            id: this.recordOrLineId,
            items: this._selectedItems,
            obj: this.objectApiName,
            type: this.viewType,
            hasImage: !!hasImage,
            featuresCount: this.featuresData ? this.featuresData.length : 0
        });

        if (signature === this._lastRenderedSignature) {
            console.log('[orchestrate] Skipping render (no change).');
            return;
        }

        const result = await this.loadComponentsForView(token, imageData, hasImage);
        if (myRun !== this._runId || result === null) return; // stale/aborted

        let htmlToRender = '';
        if (result.error) {
            this.finalErrorMessage = `<div class="error-message">${result.error}</div>`;
            htmlToRender = this.finalErrorMessage;
            this.isRendered = true;
        } else {
            this.jsonForPdf = result.pdf || '';
            htmlToRender = result.html || '';
            this.isRendered = true;
        }

        if (!this._isStale(token) && htmlToRender) {
            this.vfPageUrl = `<div class="htmlInterno">${htmlToRender}</div>`;
            this.loadIframe();
            this._lastRenderedSignature = signature;
        }
    }

    // ----------------------------------------------------
    // Build chart inputs (pure)
    // ----------------------------------------------------
    buildChartInputs(features) {
        // Returns { allLimits, hasImage, profitability }
        let profitability = null;
        let hasImage = false;
        const allLimitsLocal = [];

        //  Find the Profitability feature
        const profitabilityFeature = features.find(f => f.name.includes('Profitability') && f.profitability);
        if (profitabilityFeature) {
            console.log('isProfitability, ', JSON.stringify(profitabilityFeature));
            hasImage = true;
            profitability = profitabilityFeature.profitability;
        }

        // Subfeature charts (consumption limits)
        for (const key in features) {
            const f = features[key];
            if (f && f.consumptionLimits !== undefined) {
                hasImage = true;
                let conditions = [];
                let currencies = [];
                let labels = [];
                let limitLights = [];
                let targets = [];
                let dataDraw = [];
                let dataUndrawnCommitted = [];
                let dataUndrawnUncommitted = [];
                let dataPendingAuthorized = [];
                let dataNewOpportunity = [];

                (f.consumptionLimits || []).forEach((cl) => {
                    if (cl && cl.stateName !== undefined) {
                        conditions.push(cl.conditionDesc);
                        currencies.push(cl.currencyId);
                        labels.push(cl.limitDesc);
                        limitLights.push(cl.stateName?.toUpperCase());
                        targets.push(parseFloat(cl.amount?.currentApprovedAmount));
                        dataDraw.push(
                            parseFloat(cl.amount?.cmtContDisposedAmount) +
                            parseFloat(cl.amount?.uncmtContDisposedAmount)
                        );
                        dataUndrawnCommitted.push(parseFloat(cl.amount?.cmtContNonDspsAmount));
                        dataUndrawnUncommitted.push(parseFloat(cl.amount?.uncmtContNonDspsAmount));
                        dataPendingAuthorized.push(parseFloat(cl.amount?.authorizedRiskAmount));
                        dataNewOpportunity.push(parseFloat(cl.amount?.notSignedTrConsumptionAmount));
                    }
                });

                const sections = ["Drawn", "Undrawn committed", "Undrawn uncommitted", "Pending authorized", "New Opportunity"];
                const datasets = [
                    { "backgroundColor": "rgba(4, 50, 99, 1)", "data": dataDraw, "hoverBackgroundColor": "rgba(4, 50, 99, 1)", "label": "Drawn" },
                    { "backgroundColor": "rgba(20, 100, 165, 1)", "data": dataUndrawnCommitted, "hoverBackgroundColor": "rgba(20, 100, 165, 1)", "label": "Undrawn committed" },
                    { "backgroundColor": "rgba(36, 150, 234, 1)", "data": dataUndrawnUncommitted, "hoverBackgroundColor": "rgba(36, 150, 234, 1)", "label": "Undrawn uncommitted" },
                    { "backgroundColor": "rgba(45, 204, 205, 1)", "data": dataPendingAuthorized, "hoverBackgroundColor": "rgba(45, 204, 205, 1)", "label": "Pending authorized" },
                    { "backgroundColor": "rgba(189, 189, 189, 1)", "data": dataNewOpportunity, "hoverBackgroundColor": "rgba(189, 189, 189, 1)", "label": "New Opportunity" }
                ];
                const limitsObj = {
                    conditions,
                    currencies,
                    datasets,
                    labels,
                    limitLights,
                    originCurrency: this.currencyIsoCode,
                    sections,
                    targetColor: 'red',
                    targets
                };
                const allLimitObj = { format: 'JPEG', quality: 0.7, wrapperData: limitsObj };
                allLimitsLocal.push(allLimitObj);
            }
        }

        return { allLimits: allLimitsLocal.length ? allLimitsLocal : null, hasImage, profitability: profitability };
    }

    // ----------------------------------------------------
    // Image generation
    // ----------------------------------------------------
    async getImageB64(limit, token) {
        try {
            if (!token) token = this._requestToken;
            let image64AllLocal = [];

            if (this.recordTypeApiName === 'DMT_Opportunity') {
                // Profitability chart image
                const chartComponent = this.template.querySelector('c-dmt_profitability_chart');
                if (!chartComponent) {
                    console.error('[getImageB64] dmt_profitability_chart component not found in template!');
                    return '';
                }
                try {
                    // If the child needs data, pass it here:
                    chartComponent.profitability = limit;
                    const result = await chartComponent.getChartImage(300, 100);
                    if (result) {
                        image64AllLocal.push({ imgB64: result });
                        console.log('image64AllLocal.length ', image64AllLocal.length);
                    } else {
                        console.warn('[getImageB64] profitability chart image is null/undefined.');
                    }
                } catch (e) {
                    console.error('[getImageB64] error generating profitability chart image:', e.message);
                    // Paint an inline error message; orchestrator will likely retry
                    this.vfPageUrl = `<div class="error-message">Error generating profitability chart image: ${e.message}</div>`;
                    this.loadIframe();
                }
            } else {
                // Subfeature charts images
                const imageGenerator = this.template.querySelector('c-dmt_subfeature_chart');
                if (!imageGenerator) {
                    console.error('[getImageB64] dmt_subfeature_chart component not found in template!');
                    return '';
                }

                const promises = (limit || []).map(async (item, idx) => {
                    try {
                        const result = await imageGenerator.getChartImage(200, 100, JSON.parse(JSON.stringify(item)));
                        return result || null;
                    } catch (e) {
                        console.error(`[getImageB64] error generating image for index ${idx}:`, e);
                        return null;
                    }
                });

                const resolved = await Promise.all(promises);
                resolved.forEach((res) => {
                    if (res) image64AllLocal.push({ imgB64: res });
                });
            }

            return image64AllLocal.length > 0 ? image64AllLocal : '';
        } catch (e) {
            console.error('[getImageB64] exception:', e);
            return '';
        }
    }

    // ----------------------------------------------------
    // Server HTML/PDF fetcher (returns instead of rendering)
    // ----------------------------------------------------
    async loadComponentsForView(token = null, imageData = null, hasImage) {
        if (hasImage && !imageData) {
            console.warn('[loadComponentsForView] hasImage true but imageData missing -> abort');
            return { error: 'Missing image data' };
        }

        if (!token) token = this._startNewRender();
        this.isLoading = true;
        this.processing();

        const localImage = imageData ? JSON.stringify(imageData) : null;
        let parsedResult = null;
        let errorMessage = null;

        try {
            const response = await loadComponentsForView({
                recordOrLineId: this.recordOrLineId,
                viewType: this.viewType,
                selectedItems: JSON.stringify(this._selectedItems),
                productId: this._prodId,
                itemsImg: localImage
            });

            if (this._isStale(token)) {
                console.warn('Response arrived but token is stale. Ignoring.');
                return null;
            }

            try {
                parsedResult = response ? JSON.parse(response) : null;
            } catch (parseError) {
                errorMessage = 'Response could not be parsed.';
            }
        } catch (error) {
            if (this._isStale(token)) return null;
            console.error('Error in loadComponentsForView:', error && error.message ? error.message : error);
            errorMessage = 'An error occurred while loading data.';
        }

        if (!parsedResult && !errorMessage) {
            errorMessage = 'No data received from server.';
        }

        if (parsedResult?.error) {
            errorMessage = parsedResult.error;
        }

        // Validate error-only HTML
        let html = parsedResult?.HTML || '';
        if (this.validateResponseForErrors(html)) {
            // if HTML is only error placeholders, apply our retry logic at the orchestrator level
            // but this method remains a pure-return.
            html = '';
            if (this.retryCount < this.MAX_RETRIES) {
                this.retryCount++;
                errorMessage = 'Unable to load data after multiple attempts.'; // signal to orchestrator
            } else {
                errorMessage = 'Unable to load data after multiple attempts.';
            }
        } else {
            this.retryCount = 0;
        }

        return {
            html,
            pdf: parsedResult?.PDF || '',
            error: errorMessage
        };
    }

    // ----------------------------------------------------
    // Response validation helpers
    // ----------------------------------------------------
    validateResponseForErrors(htmlString) {
        if (!htmlString) return false;

        // If only one component, skip error validation
        if (this.itemsToDisplay && this.itemsToDisplay.length === 1) {
            return false;
        }

        // Extract all <div> contents
        const divs = htmlString.match(/<div>(.*?)<\/div>/g) || [];
        const contents = divs.map(d => d.replace(/<\/?div>/g, '').trim());

        // If we got at least one div, and all start with "Error:"
        const allErrors = contents.length > 0 && contents.every(c => c.startsWith('Error:'));
        return allErrors;
    }

    // ----------------------------------------------------
    // DOM render integration
    // ----------------------------------------------------
    renderedCallback() {
        // Keep itemsToDisplay synced with selectedItems if parent mutates it
        if (
            (this._selectedItems.length > 0 && this.itemsToDisplay.length > 0 && JSON.stringify(this._selectedItems) !== JSON.stringify(this.itemsToDisplay)) ||
            (this.prevRecordOrLineId !== this.recordOrLineId)
        ) {
            this.updateItemsToDisplay();
        }
    }

    loadIframe() {
        // Paint vfPageUrl into container
        const contentHtml = this.template.querySelector('.htmlContent');
        if (contentHtml) {
            contentHtml.innerHTML = this.vfPageUrl;
            // Styling
            contentHtml.style.width = '100%';
            contentHtml.style.maxHeight = '53vh';
            contentHtml.style.overflowY = 'auto';
            contentHtml.style.padding = '1rem';
            contentHtml.style.boxSizing = 'border-box';
        }
        this.isLoading = false;
        this.finishedProcessing(true, 'HTML generated successfully');
    }

    // ----------------------------------------------------
    // Processing events
    // ----------------------------------------------------
    processing() {
        const processingEvent = new CustomEvent('processing', {
            detail: { message: 'Processing started' },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(processingEvent);
    }

    finishedProcessing(success, message) {
        const finishedEvent = new CustomEvent('finishprocessing', {
            detail: { success: success, message: message },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(finishedEvent);
    }

    // ----------------------------------------------------
    // PDF download flow
    // ----------------------------------------------------
    get isDownloadInProgress() {
        return this.isLoading || this.downloadInProgress;
    }

    get downloadLabel() {
        return this.downloadInProgress ? 'Downloading PDF...' : 'Download PDF';
    }

    get hasItems() {
        return this.itemsToDisplay.length > 0;
    }

    handleDownloadPDF() {
        this.processing();
        this.showDownloadPdf = false;
        this.isDownload = true;
        this.downloadInProgress = true;
        setTimeout(() => this.downloadPdf(), 400);
    }

    async downloadPdf() {
        await this.generatePdf(JSON.parse(this.jsonForPdf || '{}'));
    }

    async generatePdf(parsedResponse) {
        try {
            const pdfGenerator = this.template.querySelector('c-pdf-generator');
            pdfGenerator.jsonData = parsedResponse;
            pdfGenerator.output = 'blob';
            const pdfBlob = await pdfGenerator.generatePDF();
            if (pdfBlob) {
                const blobUrl = URL.createObjectURL(pdfBlob);
                const a = document.createElement('a');
                a.href = blobUrl;
                a.download = 'DMT_ViewPDF.pdf';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                window.open(blobUrl, '_blank');
                URL.revokeObjectURL(blobUrl);
            }
        } catch (error) {
            console.error('Error in generatePdf:' + JSON.stringify(error));
            throw new Error('Failed to generate PDF.');
        } finally {
            this.downloadInProgress = false;
            this.showDownloadpdf = false;
            if (this.recordId) {
                window.location.reload();
            }
        }
    }
}