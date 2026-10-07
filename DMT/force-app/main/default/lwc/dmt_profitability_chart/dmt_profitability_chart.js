import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJS from '@salesforce/resourceUrl/DMT_ChartJS';
import getProductDetailsByIds from '@salesforce/apex/DMT_Profitability_utils.getProductDetailsByIds';
import getNominalAmountsByOpportunityLineItemIds from '@salesforce/apex/DMT_Profitability_utils.getNominalAmountsByOpportunityLineItemIds';
import convertNominalsToOppCurrency from '@salesforce/apex/DMT_Profitability_utils.convertNominalsToOppCurrency';
import getRwaRegLinkInfo from '@salesforce/apex/DMT_Profitability_utils.getRwaRegLinkInfo';
import callExternalOrchestrators from '@salesforce/apex/DMT_Profitability_utils.callExternalOrchestrators';
import getUnderlyingDetailsByIds from '@salesforce/apex/DMT_Profitability_utils.getUnderlyingDetailsByIds';

import OPP_NAME from '@salesforce/schema/Opportunity.Name';
import { getRecord } from 'lightning/uiRecordApi';

const OPP_FIELDS = [OPP_NAME];

export default class Dmt_profitability_chart extends LightningElement {
    chart;
    chartJsInitialized = false;
    table1Data = [];
    table2Data = [];
    table3Data = [];
    higherRorc = false;
    higherRoroec = false;
    summaryData = {
        raroec: '',
        rorc: '',
        clientRorc: '',
        rorcProspected: ''
    };

    _cachedDetailsList = null;
    _cachedNominalMap = null;
    _cachedNominalMapConverted = null;
    _cachedUnderlyingMap = null;

    @api hidden = false;
    @api backgroundColor = '#ffffff';
    @api chartData;
    @api profitability;
    @api opportunityId;

    recordOpportunity;
    cachedOppNameFromApex;

    productDetailsMap = {};
    nominalAmountsMap = {};
    underlyingDetailsMap = {};
    aprsCellsByProductId = {};
    showAprsCellsColumn = false;
    opportunityDates = null;
    showRwaRegLink = false;
    rwaRegBaseUrl = 'https://calculadoraholding-int.work-03.nextgen.igrupobbva/index.html';
    rwaRegBaseExplanationId = '';
    rwaRegCountry = '';

    @wire(getRecord, { recordId: '$opportunityId', fields: OPP_FIELDS })
    wiredOpportunityHandler({ data, error }) {
        if (data) {
            this.recordOpportunity = {
                id: data.id,
                name: data.fields.Name.value
            };
            this.error = undefined;
            // Refresh if data is already loaded to prefer the Wire name (optional)
            if (this.profitability && this._cachedDetailsList) {
                this.refreshTables();
            }
        }
    }

    connectedCallback() {
        if (!this.profitability || !this.profitability.results) {
            return;
        }

        const ids = [...new Set(this.profitability.results
            .filter(r => r.productId && !r.underlyingId)
            .map(r => r.productId))];

        const underlyingIds = this.profitability.results
            .filter(r => r.underlyingId)
            .map(r => r.underlyingId);

        Promise.all([
            getProductDetailsByIds({ productIds: ids, oppId: this.opportunityId }),
            getNominalAmountsByOpportunityLineItemIds({ productIds: ids, oppId: this.opportunityId }),
            getRwaRegLinkInfo({ oppId: this.opportunityId }),
            getUnderlyingDetailsByIds({ underlyingIds: underlyingIds })
        ])
        .then(([detailsList, nominalMap, rwaLinkInfo, underlyingMap]) => {
            this._cachedDetailsList = detailsList;
            this._cachedNominalMap = nominalMap;
            this._cachedUnderlyingMap = underlyingMap || {};
            this.showRwaRegLink = rwaLinkInfo?.enabled === true;
            this.rwaRegBaseUrl = rwaLinkInfo?.baseUrl || this.rwaRegBaseUrl;
            if (this.showRwaRegLink && rwaLinkInfo.explanationId) {
                this.rwaRegBaseExplanationId = rwaLinkInfo.explanationId;
                this.rwaRegCountry = rwaLinkInfo.entific || '';
            }

            convertNominalsToOppCurrency({
                productDetails: detailsList,
                nominalAmounts: nominalMap || {}
            }).then(convertedMap => {
                //this._cachedNominalMap = convertedMap || {};
                this._cachedNominalMapConverted = convertedMap || {};
                this.refreshTables();
            });
        })
        .catch(error => {
            this.refreshTables(true);
        });
    }

    refreshTables(isError = false) {
        if (!isError) {
            this.productDetailsMap = {};
            this.opportunityDates = null;
            this.nominalAmountsMap = this._cachedNominalMap || {};
            this.underlyingDetailsMap = this._cachedUnderlyingMap || {};
            if (this._cachedDetailsList) {
                // NEW: Extract Opp Name from the first result (since they share the same Opp)
                if (this._cachedDetailsList.length > 0 && this._cachedDetailsList[0].OppName) {
                    this.cachedOppNameFromApex = this._cachedDetailsList[0].OppName;
                }
                this._cachedDetailsList.forEach(d => {
                    this.productDetailsMap[d.gf_group_priority_opportunity_id__c] = {
                        name: d.Name,
                        initialDate: d.InitialDate,
                        maturityDate: d.MaturityDate,
                        currency: d.Currency
                    };

                    if (!this.opportunityDates && d.OppInitialDate && d.OppMaturityDate) {
                        this.opportunityDates = {
                            oppInitialDate: d.OppInitialDate,
                            oppMaturityDate: d.OppMaturityDate,
                            oppCurrency: d.OppCurrency
                        };
                    }
                });

            }
        }

        const { table1, table2, table3 } = this.processProfitabilityData(this.profitability);
        this.table1Data = table1;
        this.table2Data = table2;
        this.table3Data = table3;

        const opportunity = this.profitability.results.find(r => !r.productId);
        if (opportunity) {

            const rorcThresholdNum = parseFloat(this.profitability.audit.rorcThreshold);
            const raroecThresholdNum = parseFloat(this.profitability.audit.raroecThreshold);

            this.summaryData = {
                raroecThreshold: this.formatPercent(raroecThresholdNum),
                rorcThreshold: this.formatPercent(rorcThresholdNum),
                raroec: this.formatPercent(opportunity.raroec),
                rorc: this.formatPercent(opportunity.rorc),
                clientRorc: this.formatPercent(opportunity.clientRorc),
                rorcProspected: this.formatPercent(opportunity.rorcProspected)
            };

            this.higherRorc = rorcThresholdNum < opportunity.rorc;
            this.higherRoroec = raroecThresholdNum < opportunity.raroec;
        }
    }

    renderedCallback() {
        if (this.chartJsInitialized) {
            return;
        }
        this.chartJsInitialized = true;
        Promise.all([loadScript(this, chartJS)]).then(() => {
            if (!this.hidden) {
                this.showChart();
            }
        }).catch(error => {
            console.error('Error loading Chart.js', error);
        });
    }

    showChart() {
        const ctx = this.template.querySelector('canvas.chart').getContext('2d');
        if (ctx) {
            this.chart = new window.Chart(ctx, this.renderChart());
        }
    }

    @api
    getChartImage(width = 200, height = 50) {
        return new Promise((resolve, reject) => {
            const canvas = document.createElement("canvas");
            const ctx = canvas.getContext('2d');

            document.documentElement.appendChild(canvas)
            canvas.width = width;
            canvas.height = height;
            canvas.setAttribute("width", width || 200);
            canvas.setAttribute("height", height || 50);

            let chart = new window.Chart(ctx, this.renderChart())
            canvas.remove();
            resolve(chart.toBase64Image());
        });
    }

    _getChartImage(width, height) {
        let canvas = document.createElement("canvas");
        document.documentElement.appendChild(canvas)

        canvas.setAttribute("width", width || 60);
        canvas.setAttribute("height", height || 40);

        let chartData = this.getChartData();
        chartData.options.animation = false;
        let chart = new window.Chart(canvas, chartData)

        const imgBase64 = chart.toBase64Image();
        canvas.remove();
        return imgBase64;
    }

    formatBps(value) {
        const numeric = parseFloat(value ?? 0);
        return `${numeric.toFixed(0)} bps`;
    }

    formatPercent(value) {
        return typeof value === 'number' ? `${(value * 100).toFixed(2)} %` : '';
    }

    formatThousands(value) {
        if (value === null || value === undefined || isNaN(value)) return '';
        return parseFloat(value).toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    formatAmountWithCurrency(value, currency) {
        const formatted = this.formatThousands(value);
        return formatted ? `${formatted} ${currency || ''}`.trim() : '';
    }

    formatAmountWithCurrencyMax2(value, currency) {
        if (value === null || value === undefined || isNaN(value)) return '';
        const numericValue = parseFloat(value);
        const formatted = Math.abs(numericValue) > 0 && Math.abs(numericValue) < 0.01
            ? numericValue.toExponential(2)
            : numericValue.toLocaleString('es-ES', { maximumFractionDigits: 2 });
        return `${formatted} ${currency || ''}`.trim();
    }

    rowStyle(index) {
        return index === 0 ? 'background-color: #e6f0fa;' : '';
    }

    get externalRwaEnabled() {
        return this.showRwaRegLink;
    }

    get externalRwaDisabled() {
        return !this.externalRwaEnabled;
    }

    getRwaRegUrl(productId) {
        if (!this.rwaRegBaseExplanationId || !productId) {
            return '';
        }

        const explanationId = `${this.rwaRegBaseExplanationId}_${productId}`;
        const country = this.rwaRegCountry || '';
        return `${this.rwaRegBaseUrl}?explanationId=${encodeURIComponent(explanationId)}&applicationId=2&country=${encodeURIComponent(country)}`;
    }

    handleExternalRwaClick() {
        if (!this.externalRwaEnabled) {
            return;
        }

        callExternalOrchestrators({ oppId: this.opportunityId })
            .then(result => {
                if (result?.success !== true || !result?.responseBody) {
                    this.showAprsCellsColumn = false;
                    return;
                }

                const responseBody = typeof result.responseBody === 'string'
                    ? JSON.parse(result.responseBody)
                    : result.responseBody;

                const aprsCalculatorList = responseBody?.data?.aprsCalculator || [];
                this.aprsCellsByProductId = aprsCalculatorList.reduce((accumulator, item) => {
                    const aprCalculator = item?.aprCalculator;
                    const productId = aprCalculator?.productId;
                    if (productId) {
                        accumulator[productId] = aprCalculator?.aprCalculation ?? '';
                    }
                    return accumulator;
                }, {});
                this.showAprsCellsColumn = Object.keys(this.aprsCellsByProductId).length > 0;

                this.refreshTables();
            })
            .catch(() => {});
    }

    buildOrderedRows(opportunityRow, productRows, underlyingRows) {
        const orderedRows = [];
        const sortedProductRows = [...productRows].sort((a, b) => a.sourceIndex - b.sourceIndex);
        const sortedUnderlyingRows = [...underlyingRows].sort((a, b) => a.sourceIndex - b.sourceIndex);
        const underlyingRowsByParentId = sortedUnderlyingRows.reduce((accumulator, row) => {
            const parentId = row.productId;
            if (!accumulator[parentId]) {
                accumulator[parentId] = [];
            }
            accumulator[parentId].push(row);
            return accumulator;
        }, {});

        if (opportunityRow) {
            orderedRows.push(opportunityRow);
        }

        sortedProductRows.forEach(row => {
            orderedRows.push(row);
            const childRows = underlyingRowsByParentId[row.productId] || [];
            orderedRows.push(...childRows);
            delete underlyingRowsByParentId[row.productId];
        });

        Object.values(underlyingRowsByParentId).forEach(orphanRows => {
            orderedRows.push(...orphanRows);
        });

        return orderedRows;
    }

    normalizeProfitabilityResults(results = []) {
        const selectedIndexes = new Set();
        let opportunityIndex = null;
        const productIndexById = new Map();
        const underlyingIndexById = new Map();

        results.forEach((result, index) => {
            if (!result.productId) {
                if (opportunityIndex === null) {
                    opportunityIndex = index;
                }
                return;
            }

            if (result.underlyingId) {
                if (!underlyingIndexById.has(result.underlyingId)) {
                    underlyingIndexById.set(result.underlyingId, index);
                }
                return;
            }

            const currentIndex = productIndexById.get(result.productId);
            if (currentIndex === undefined) {
                productIndexById.set(result.productId, index);
                return;
            }

            const currentResult = results[currentIndex] || {};
            const currentIsPreferred = currentResult.isLine === true;
            const incomingIsPreferred = result.isLine === true;

            if (!currentIsPreferred && incomingIsPreferred) {
                productIndexById.set(result.productId, index);
            }
        });

        if (opportunityIndex !== null) {
            selectedIndexes.add(opportunityIndex);
        }

        productIndexById.forEach(index => selectedIndexes.add(index));
        underlyingIndexById.forEach(index => selectedIndexes.add(index));

        return results.filter((_, index) => selectedIndexes.has(index));
    }

    processProfitabilityData(jsonData) {
        const results = this.normalizeProfitabilityResults(jsonData.results || []);
        const productRows = [];
        const underlyingRows = [];
        let opportunityRow;
        let totalNominalDb = 0;
        let totalNominalFb = 0;
        const toNumberOrNull = value => {
            const numeric = Number(value);
            return Number.isFinite(numeric) ? numeric : null;
        };

        results.forEach((result, index) => {
            const isOpportunity = !result.productId;

            // LOGIC CHANGE:
            // 1. Try Wire record name
            // 2. Try Cached Apex name (fallback)
            // 3. Default to empty
            let id = this.recordOpportunity?.name || this.cachedOppNameFromApex || '';

            let initialDate = '—';
            let maturityDate = '—';
            let nominalDb = '—';
            let nominalFb = '—';
            let nominalDbValue = null;
            let nominalFbValue = null;
            let product;
            let nominals;
            let nominalsConverted;
            let rowCurrency = this.opportunityDates?.oppCurrency || '';
            if (result.productId) {
                product = this.productDetailsMap?.[result.productId];
                nominals = this.nominalAmountsMap?.[result.productId];
                nominalsConverted = this._cachedNominalMapConverted?.[result.productId];
                id = product?.name || result.productId;
                initialDate = product?.initialDate || '—';
                maturityDate = product?.maturityDate || '—';
                rowCurrency = product?.currency || rowCurrency;

                if (nominals && !result.underlyingId) {
                    nominalDb = this.formatThousands(nominals.nominalDb) + ' ' + product?.currency;
                    nominalFb = this.formatThousands(nominals.nominalFb) + ' ' + product?.currency;
                    nominalDbValue = toNumberOrNull(nominals.nominalDb);
                    nominalFbValue = toNumberOrNull(nominals.nominalFb);
                    totalNominalDb += nominalsConverted?.nominalDb || 0;
                    totalNominalFb += nominalsConverted?.nominalFb || 0;
                }
            } else {
                if (this.opportunityDates) {
                    initialDate = this.opportunityDates.oppInitialDate || '—';
                    maturityDate = this.opportunityDates.oppMaturityDate || '—';
                }
                nominalDb = this.formatThousands(totalNominalDb) + ' ' + rowCurrency;
                nominalFb = this.formatThousands(totalNominalFb) + ' ' + rowCurrency;
            }
            if (result.underlyingId) {
                const underlying = this.underlyingDetailsMap?.[result.underlyingId];
                id = underlying?.Name || result.underlyingId;
                if (underlying) {
                    nominalDb = this.formatThousands(underlying.nominalDb) + ' ' + (product?.currency || rowCurrency);
                    nominalFb = this.formatThousands(underlying.nominalFb) + ' ' + (product?.currency || rowCurrency);
                    nominalDbValue = toNumberOrNull(underlying.nominalDb);
                    nominalFbValue = toNumberOrNull(underlying.nominalFb);
                }
            }

            const aprsCellsValue = result.productId ? this.aprsCellsByProductId?.[result.productId] : null;
            const aprsCellsFormatted = result.productId
                ? this.formatAmountWithCurrency(aprsCellsValue, rowCurrency)
                : '';
            const aprsCellsUrl = result.productId ? this.getRwaRegUrl(result.productId) : '';

            const row = {
                key: `${result.underlyingId || result.productId || 'opportunity'}-${index}`,
                id,
                productId: result.productId || null,
                underlyingId: result.underlyingId || null,
                sourceIndex: index,
                rowCurrency,
                nominalDbValue,
                nominalFbValue,
                initialDate,
                maturityDate,
                franchiseDeal: this.formatThousands(result?.franchiseDeal ? result.franchiseDeal : 0)+ ' ' +(result.productId ? product?.currency : rowCurrency ),
                // Table 1
                taxRate: this.formatPercent(result.taxRate / 100),
                spreadDb: this.formatBps(result.spreadDbPbs),
                spreadFb: this.formatBps(result.spreadFbPbs),
                fundingDb: this.formatBps(result.fundingDbPbs),
                fundingFb: this.formatBps(result.fundingFbPbs),
                countryRiskDb: this.formatBps(result.countryRiskProvisionDbPbs),
                countryRiskFb: this.formatBps(result.countryRiskProvisionFbPbs),
                pe: this.formatBps(result.expectedLossPbs),
                feesNonAccrual: this.formatBps(result.feesUpFrontPbs),
                feesAccrual: this.formatBps(result.periodicFeesPbs),
                incomes12Months: this.formatAmountWithCurrencyMax2(result.incomes12Months, (result.productId ? product?.currency : rowCurrency)),
                averageLife: result.averageLife !== null && result.averageLife !== undefined ? `${parseFloat(result.averageLife).toFixed(2)}y` : '',
                tenor: result.term !== null && result.term !== undefined ? `${parseFloat(result.term).toFixed(2)}y` : '',
                allInDb: this.formatBps(result.allInDb),
                allInFb: this.formatBps(result.allInFb),
                feesDrawn: this.formatBps(result.feesDbPbs),
                feesUndrawn: this.formatBps(result.feesFbPbs),
    
                // Tabla 2
                nominalDb,
                nominalFb,
                ccfEco: this.formatPercent(result.economicCcf / 100),
                eadEco: this.formatThousands(result.economicEad) + ' ' + (result.productId ? product?.currency : rowCurrency),
                lgdEco: this.formatPercent(result.economicLgd / 100),
                netIncomeEco: this.formatAmountWithCurrencyMax2(
                    result.BDIEco ?? result.bdiEco,
                    (result.productId ? product?.currency : rowCurrency)
                ),
                rwaEco: this.formatAmountWithCurrency(result.economicApr, (result.productId ? product?.currency : rowCurrency)),
                ce: this.formatAmountWithCurrency(result.economicCapital, (result.productId ? product?.currency : rowCurrency)),
                raroec: this.formatPercent(result.raroec),
                bdiCdd: this.formatThousands(result.prospectedBdi),
                ceCdd: this.formatThousands(result.prospectedEconomicCapital),
                // Table 3
                ccfReg: this.formatPercent(result.regulatoryCcf / 100),
                eadReg: this.formatThousands(result.regulatoryEad) + ' ' + (result.productId ? product?.currency : rowCurrency),
                lgdReg: this.formatPercent(result.regulatoryLgd / 100),
                netIncomeReg: this.formatAmountWithCurrencyMax2(
                    result.BDIReg ?? result.bdiReg,
                    (result.productId ? product?.currency : rowCurrency)
                ),
                rwaReg: this.formatAmountWithCurrency(result.regulatoryApr, (result.productId ? product?.currency : rowCurrency)),
                aprsCells: aprsCellsFormatted,
                aprsCellsIsLink: Boolean(aprsCellsFormatted && result.productId && this.showRwaRegLink && aprsCellsUrl),
                aprsCellsUrl: aprsCellsUrl,
                rwaRegIsLink: false,
                rwaRegUrl: '',
                cr: this.formatAmountWithCurrency(result.regulatoryCapital, (result.productId ? product?.currency : rowCurrency)),
                rorc: this.formatPercent(result.rorc),
                crCdd: this.formatThousands(result.prospectedRegulatoryCapital),
                rorcCdd: this.formatPercent(result.rorcProspected)
            };

            if (isOpportunity) {
                opportunityRow = row;
            } else if (result.underlyingId) {
                underlyingRows.push(row);
            } else {
                productRows.push(row);
            }
        });

        const underlyingNominalsByProductId = underlyingRows.reduce((accumulator, row) => {
            if (!row.productId) {
                return accumulator;
            }

            if (!accumulator[row.productId]) {
                accumulator[row.productId] = {
                    nominalDb: 0,
                    nominalFb: 0,
                    hasNominalDb: false,
                    hasNominalFb: false
                };
            }

            if (typeof row.nominalDbValue === 'number') {
                accumulator[row.productId].nominalDb += row.nominalDbValue;
                accumulator[row.productId].hasNominalDb = true;
            }

            if (typeof row.nominalFbValue === 'number') {
                accumulator[row.productId].nominalFb += row.nominalFbValue;
                accumulator[row.productId].hasNominalFb = true;
            }

            return accumulator;
        }, {});

        productRows.forEach(row => {
            const underlyingNominals = underlyingNominalsByProductId[row.productId];
            if (!underlyingNominals) {
                return;
            }

            row.nominalDb = underlyingNominals.hasNominalDb
                ? this.formatAmountWithCurrency(underlyingNominals.nominalDb, row.rowCurrency)
                : '—';
            row.nominalFb = underlyingNominals.hasNominalFb
                ? this.formatAmountWithCurrency(underlyingNominals.nominalFb, row.rowCurrency)
                : '—';
            row.nominalDbValue = underlyingNominals.hasNominalDb ? underlyingNominals.nominalDb : null;
            row.nominalFbValue = underlyingNominals.hasNominalFb ? underlyingNominals.nominalFb : null;
        });

        const totalNominalDbVisible = productRows.reduce(
            (sum, row) => sum + (typeof row.nominalDbValue === 'number' ? row.nominalDbValue : 0),
            0
        );
        const totalNominalFbVisible = productRows.reduce(
            (sum, row) => sum + (typeof row.nominalFbValue === 'number' ? row.nominalFbValue : 0),
            0
        );

        if (opportunityRow) {
            const oppCurrency = this.opportunityDates?.oppCurrency || '';
            opportunityRow.nominalDb = this.formatThousands(totalNominalDbVisible) + ' ' + oppCurrency;
            opportunityRow.nominalFb = this.formatThousands(totalNominalFbVisible) + ' ' + oppCurrency;
            opportunityRow.nominalDbValue = totalNominalDbVisible;
            opportunityRow.nominalFbValue = totalNominalFbVisible;
        }

        const allRows = this.buildOrderedRows(opportunityRow, productRows, underlyingRows);

        const table1 = allRows.map((r, i) => ({
            ...r,
            rowClass: i === 0 ? 'opportunity-row' : (r.underlyingId ? 'underlying-row' : ''),
            idClass: r.underlyingId ? 'id-label id-label-underlying' : 'id-label'
        }));
        const table2 = allRows.map((r, i) => ({
            key: r.key,
            id: r.id,
            nominalDb: r.nominalDb,
            nominalFb: r.nominalFb,
            ccfEco: r.ccfEco,
            eadEco: r.eadEco,
            lgdEco: r.lgdEco,
            netIncomeEco: r.netIncomeEco,
            rwaEco: r.rwaEco,
            ce: r.ce,
            raroec: r.raroec,
            bdiCdd: r.bdiCdd,
            ceCdd: r.ceCdd,
            rowClass: i === 0 ? 'opportunity-row' : (r.underlyingId ? 'underlying-row' : ''),
            idClass: r.underlyingId ? 'id-label id-label-underlying' : 'id-label',
            franchiseDeal: r.franchiseDeal
        }));
        const table3 = allRows.map((r, i) => ({
            key: r.key,
            id: r.id,
            nominalDb: r.nominalDb,
            nominalFb: r.nominalFb,
            ccfReg: r.ccfReg,
            eadReg: r.eadReg,
            lgdReg: r.lgdReg,
            netIncomeReg: r.netIncomeReg,
            rwaReg: r.rwaReg,
            aprsCells: r.aprsCells,
            aprsCellsIsLink: r.aprsCellsIsLink,
            aprsCellsUrl: r.aprsCellsUrl,
            rwaRegIsLink: r.rwaRegIsLink,
            rwaRegUrl: r.rwaRegUrl,
            cr: r.cr,
            rorc: r.rorc,
            bdiCdd: r.bdiCdd,
            crCdd: r.crCdd,
            rorcCdd: r.rorcCdd,
            rowClass: i === 0 ? 'opportunity-row' : (r.underlyingId ? 'underlying-row' : ''),
            idClass: r.underlyingId ? 'id-label id-label-underlying' : 'id-label'
        }));
        return { table1, table2, table3 };
    }

    extractChartData(jsonData) {
        const results = jsonData.results;
        const labels = [];
        const raroecData = [];
        const rorcData = [];

        results.forEach((result, index) => {
            const id = result.productId ? `P${index}` : 'Opp';
            labels.push(id);
            raroecData.push(result.raroec ?? 0);
            rorcData.push(result.rorc ?? 0);
        });
        return { labels, raroecData, rorcData };
    }

    extractYearlyChartData() {
        const results = this.profitability?.results || [];
        const opportunity = results.find(r => !r.productId);
        const years = opportunity?.totalYears || [];

        let labels = years.map(y => y.year.toString());
        let eadEcoData = years.map(y => (parseFloat(y.eadEcoYearly) / 1000000).toFixed(2));
        let eadRegData = years.map(y => (parseFloat(y.eadRegYearly) / 1000000).toFixed(2));
        let rorcData = years.map(y => {
            const val = parseFloat(y.rorcYearly * 100);
            return isNaN(val) ? null : val.toFixed(2);
        });
        let raroecData = years.map(y => {
            const val = parseFloat(y.raroecYearly * 100);
            return isNaN(val) ? null : val.toFixed(2);
        });

        if (labels.length < 3 && labels.length > 0) {
            const currentYear = parseInt(labels[labels.length - 1]);
            const needed = 3 - labels.length;

            for (let i = 1; i <= needed; i++) {
                labels.push((currentYear + i).toString());
                eadEcoData.push(0);
                eadRegData.push(0);
                rorcData.push(null);
                raroecData.push(null);
            }
        }
        return { labels, eadEcoData, eadRegData, rorcData, raroecData };
    }

    renderChart() {
        const { labels, eadEcoData, eadRegData, rorcData, raroecData } = this.extractYearlyChartData();

        return {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'EAD ECO (Mill €)',
                        data: eadEcoData,
                        backgroundColor: 'rgba(20, 100, 165, 0.5)',
                        borderColor: 'rgba(20, 100, 165, 1)',
                        borderWidth: 1,
                        yAxisID: 'y-axis-euros',
                        type: 'bar',
                        maxBarThickness: 40,
                        categoryPercentage: 0.5,
                        barPercentage: 0.6
                    },
                    {
                        label: 'EAD REG (Mill €)',
                        data: eadRegData,
                        backgroundColor: 'rgba(91, 190, 255, 0.5)',
                        borderColor: 'rgba(91, 190, 255, 1)',
                        borderWidth: 1,
                        yAxisID: 'y-axis-euros',
                        type: 'bar',
                        maxBarThickness: 40,
                        categoryPercentage: 0.5,
                        barPercentage: 0.6
                    },
                    {
                        label: 'RORC (%)',
                        data: rorcData,
                        borderColor: 'rgba(255, 181, 107, 1)',
                        backgroundColor: 'rgba(255, 181, 107, 0.2)',
                        borderWidth: 2,
                        fill: false,
                        yAxisID: 'y-axis-percent',
                        type: 'line',
                        pointRadius: 4,
                        pointHoverRadius: 6
                    },
                    {
                        label: 'RAROEC (%)',
                        data: raroecData,
                        borderColor: 'rgba(136, 231, 131, 1)',
                        backgroundColor: 'rgba(136, 231, 131, 0.2)',
                        borderWidth: 2,
                        fill: false,
                        yAxisID: 'y-axis-percent',
                        type: 'line',
                        pointRadius: 4,
                        pointHoverRadius: 6
                    }
                ]
            },
            options: {
                scales: {
                    yAxes: [
                        {
                            id: 'y-axis-euros',
                            type: 'linear',
                            position: 'left',
                            ticks: {
                                beginAtZero: true
                            },
                            scaleLabel: {
                                display: true,
                                labelString: 'EAD (Mill €)'
                            }
                        },
                        {
                            id: 'y-axis-percent',
                            type: 'linear',
                            position: 'right',
                            ticks: {
                                beginAtZero: true,
                                callback: value => `${value} %`
                            },
                            scaleLabel: {
                                display: true,
                                labelString: 'Percentage (%)'
                            },
                            gridLines: {
                                drawOnChartArea: false
                            }
                        }
                    ]
                },
                legend: {
                    position: 'top'
                },
                animation: false,
                tooltips: {
                    mode: 'index',
                    intersect: false,
                    callbacks: {
                        label: function(tooltipItem, data) {
                            const dataset = data.datasets[tooltipItem.datasetIndex];
                            const value = tooltipItem.yLabel;
                            const label = dataset.label || '';
                            if (dataset.yAxisID === 'y-axis-percent') {
                                return `${label}: ${value} %`;
                            } else {
                                return `${label}: ${value} M €`;
                            }
                        }
                    }
                }
            }
        };
    }
}