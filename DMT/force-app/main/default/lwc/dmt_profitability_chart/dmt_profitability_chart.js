import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJS from '@salesforce/resourceUrl/HPG_ChartJS';
import getProductDetailsByIds from '@salesforce/apex/DMT_Profitability_utils.getProductDetailsByIds';
import getNominalAmountsByOpportunityLineItemIds from '@salesforce/apex/DMT_Profitability_utils.getNominalAmountsByOpportunityLineItemIds';
import OPP_NAME from '@salesforce/schema/Opportunity.Name';
import { getRecord } from 'lightning/uiRecordApi';

const OPP_FIELDS = [OPP_NAME];

export default class Dmt_profitability_chart extends LightningElement {
    chart;
    chartJsInitialized = false;
    table1Data = [];
    table2Data = [];
    table3Data = [];
    summaryData = {
        raroec: '',
        raroecNoxsell: '',
        raroecProspected: '',
        rorc: '',
        rorcNoxsell: '',
        rorcProspected: ''
    };

    _cachedDetailsList = null;
    _cachedNominalMap = null;

    @api hidden = false;
    @api backgroundColor = '#ffffff';
    @api chartData;
    @api profitability;
    @api opportunityId;

    recordOpportunity;
    cachedOppNameFromApex;

    productDetailsMap = {};
    nominalAmountsMap = {};
    opportunityDates = null;

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

        const ids = this.profitability.results
            .filter(r => r.productId)
            .map(r => r.productId);

        Promise.all([
            getProductDetailsByIds({ productIds: ids }),
            getNominalAmountsByOpportunityLineItemIds({ productIds: ids })
        ])
        .then(([detailsList, nominalMap]) => {
            this._cachedDetailsList = detailsList;
            this._cachedNominalMap = nominalMap || {};

            this.refreshTables();
        })
        .catch(error => {
            console.error('Error loading product details or nominal amounts', error);
            this.refreshTables(true);
        });
    }

    refreshTables(isError = false) {
        if (!isError) {
            this.productDetailsMap = {};
            this.opportunityDates = null;
            this.nominalAmountsMap = this._cachedNominalMap || {};

            if (this._cachedDetailsList) {
                // NEW: Extract Opp Name from the first result (since they share the same Opp)
                if (this._cachedDetailsList.length > 0 && this._cachedDetailsList[0].OppName) {
                    this.cachedOppNameFromApex = this._cachedDetailsList[0].OppName;
                }

                this._cachedDetailsList.forEach(d => {
                    this.productDetailsMap[d.Id] = {
                        name: d.Name,
                        initialDate: d.InitialDate,
                        maturityDate: d.MaturityDate
                    };

                    if (!this.opportunityDates && d.OppInitialDate && d.OppMaturityDate) {
                        this.opportunityDates = {
                            oppInitialDate: d.OppInitialDate,
                            oppMaturityDate: d.OppMaturityDate
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
            this.summaryData = {
                raroec: this.formatPercent(opportunity.raroec),
                raroecNoxsell: this.formatPercent(opportunity.raroecNoxsell),
                raroecProspected: this.formatPercent(opportunity.raroecProspected),
                rorc: this.formatPercent(opportunity.rorc),
                rorcNoxsell: this.formatPercent(opportunity.rorcNoxsell),
                rorcProspected: this.formatPercent(opportunity.rorcProspected)
            };
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
        return `${numeric.toFixed(3)} bps`;
    }

    formatPercent(value) {
        return typeof value === 'number' ? `${(value * 100).toFixed(2)} %` : '';
    }

    formatThousands(value) {
        if (value === null || value === undefined || isNaN(value)) return '';
        return parseFloat(value).toLocaleString('es-ES', { minimumFractionDigits: 3, maximumFractionDigits: 3 });
    }

    rowStyle(index) {
        return index === 0 ? 'background-color: #e6f0fa;' : '';
    }

    processProfitabilityData(jsonData) {
        const results = jsonData.results;
        const rows = [];
        let opportunityRow;

        let totalNominalDb = 0;
        let totalNominalFb = 0;

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

            if (result.productId) {
                const product = this.productDetailsMap?.[result.productId];
                const nominals = this.nominalAmountsMap?.[result.productId];

                id = product?.name || result.productId;
                initialDate = product?.initialDate || '—';
                maturityDate = product?.maturityDate || '—';

                if (nominals) {
                    nominalDb = this.formatThousands(nominals.nominalDb) + ' EUR';
                    nominalFb = this.formatThousands(nominals.nominalFb) + ' EUR';
                    totalNominalDb += nominals.nominalDb || 0;
                    totalNominalFb += nominals.nominalFb || 0;
                }
            } else {
                if (this.opportunityDates) {
                    initialDate = this.opportunityDates.oppInitialDate || '—';
                    maturityDate = this.opportunityDates.oppMaturityDate || '—';
                }
                nominalDb = this.formatThousands(totalNominalDb) + ' EUR';
                nominalFb = this.formatThousands(totalNominalFb) + ' EUR';
            }

            const row = {
                id,
                initialDate,
                maturityDate,
                franchiseDeal: this.formatThousands(result?.franchiseDeal ? result.franchiseDeal : 0)+ ' EUR',
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
                bdi: this.formatThousands(result.bdi?.toFixed(3)),
                // Table 2
                nominalDb,
                nominalFb,
                ccfEco: this.formatPercent(result.economicCcf / 100),
                eadEco: this.formatThousands(result.economicEad),
                lgdEco: this.formatPercent(result.economicLgd / 100),
                rwaEco: this.formatPercent(result.economicApr / 100),
                ce: this.formatThousands(result.economicCapital),
                raroec: this.formatPercent(result.raroec),
                bdiCdd: this.formatThousands(result.prospectedBdi),
                ceCdd: this.formatThousands(result.prospectedEconomicCapital),
                raroecCdd: this.formatPercent(result.raroecProspected),
                // Table 3
                ccfReg: this.formatPercent(result.regulatoryCcf / 100),
                eadReg: this.formatThousands(result.regulatoryEad),
                lgdReg: this.formatPercent(result.regulatoryLgd / 100),
                rwaReg: this.formatPercent(result.regulatoryApr / 100),
                cr: this.formatThousands(result.regulatoryCapital),
                rorc: this.formatPercent(result.rorc),
                crCdd: this.formatThousands(result.prospectedRegulatoryCapital),
                rorcCdd: this.formatPercent(result.rorcProspected)
            };

            if (isOpportunity) {
                opportunityRow = row;
            } else {
                rows.push(row);
            }
        });

        const allRows = [opportunityRow, ...rows];

        const table1 = allRows.map((r, i) => ({ ...r, rowClass: i === 0 ? 'opportunity-row' : '' }));
        const table2 = allRows.map((r, i) => ({
            id: r.id,
            nominalDb: r.nominalDb,
            nominalFb: r.nominalFb,
            ccfEco: r.ccfEco,
            eadEco: r.eadEco,
            lgdEco: r.lgdEco,
            rwaEco: r.rwaEco,
            ce: r.ce,
            raroec: r.raroec,
            bdiCdd: r.bdiCdd,
            ceCdd: r.ceCdd,
            raroecCdd: r.raroecCdd,
            rowClass: i === 0 ? 'opportunity-row' : '',
            franchiseDeal: r.franchiseDeal
        }));
        const table3 = allRows.map((r, i) => ({
            id: r.id,
            nominalDb: r.nominalDb,
            nominalFb: r.nominalFb,
            ccfReg: r.ccfReg,
            eadReg: r.eadReg,
            lgdReg: r.lgdReg,
            rwaReg: r.rwaReg,
            cr: r.cr,
            rorc: r.rorc,
            bdiCdd: r.bdiCdd,
            crCdd: r.crCdd,
            rorcCdd: r.rorcCdd,
            rowClass: i === 0 ? 'opportunity-row' : ''
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
            const val = parseFloat(y.rorcYearly);
            return isNaN(val) ? null : val.toFixed(2);
        });
        let raroecData = years.map(y => {
            const val = parseFloat(y.raroecYearly);
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