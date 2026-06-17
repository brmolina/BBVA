import { api, wire, track, LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJS from '@salesforce/resourceUrl/DMT_ChartJS';
import { formatCurrency, customTooltip, toggleNotice, isNull, drawTargets } from './dmt_subfeature_chart_utils.js';
import getCurrenciesD from '@salesforce/apex/DMT_Engines_Handler.getCurrenciesD';

let chartJsLoadPromise; // static variable to hold the loading promise
export default class Dmt_subfeature_chart extends LightningElement {

    chart;
    imageRenderQueue = Promise.resolve();
    currencyData;
    labels;
    sublabels
    datasets;
    targets;
    trafficlights = [];
    currenciesMap;
    paddingLeft = 50;
    isLoading = true;
    pickListC;
    initialized = false;
    format = 'PNG';
    quality = 0.5;

    @api wrapperData;
    @api featureName;
    @api featureLight;
    @api currencyId;
    @api exchangeRate = 1.0;
    @api hidden = false;
    @api backgroundColor = '#ffffff';
    @api showConditionDesc = false;

    @wire(getCurrenciesD)
    wiredCurrencies({ error, data }) {
        if (data) {
            this.currencyData = JSON.parse(JSON.stringify(data));
            if (!chartJsLoadPromise) {
                chartJsLoadPromise = loadScript(this, chartJS);
            }
            chartJsLoadPromise.then(() => {
                if (!isNull(this.wrapperData) && !isNull(this.currencyData) && !this.initialized) {
                    this.setChartData(this.wrapperData, this.currencyData).then( result => {
                        if (!this.hidden) {
                            this.renderChart();
                        }
                    });
                }
            }).catch(error => {
                console.error('Error loading Chart.js', error);
            });
        } else if (error) {
            console.error('Error retrieving currencies:', error);
        }
    }

    renderedCallback() {
        if (!isNull(this.wrapperData) && !isNull(this.currencyData) && !this.initialized) {
            if (!this.hidden) {
                this.setChartData(this.wrapperData, this.currencyData).then( result => {
                    this.renderChart();
                });
            }
        }
    }

    setChartData(wrapper, currencies) {
        return new Promise((resolve, reject) => {

            this.chartData = JSON.parse(JSON.stringify(wrapper));
            this.trafficlights = [];
            const chartLabels = this.chartData?.labels || [];
            this.currencyId = this.currencyId
            || this.chartData?.originCurrency
            || (this.pickListC && this.pickListC.length > 0 ? this.pickListC[0].value : null);
            this.exchangeRate = currencies?.currencyMap?.[this.currencyId] || 1.0;
            this.datasets = JSON.parse(JSON.stringify(this.chartData.datasets));
            this.targets =  JSON.parse(JSON.stringify(this.chartData.targets));
            this.labels = chartLabels.map(val => val?.split(' # ')[0] || '');
            this.sublabels = chartLabels.map(val => val?.split(' # ')[1] || '');
            this.pickListC = currencies?.pickList || [] ;
            this.currenciesMap = currencies?.currencyMap || {};

            (wrapper.limitLights || []).forEach( (limitLight, index) => {
                this.trafficlights[index] = {
                    colour: limitLight.toLowerCase(),
                    label: wrapper.conditions[index],
                    x: 0,
                    y: 0,
                    height: 0,
                    width: 0
                }
            });
            resolve(true)
        });
    }

    convertCurrency(value) {
        const currentCurrency =  this.chartData?.currencies[0];
        const originCurrency = this.chartData?.originCurrency;        
        const userSelectedCurrency = this.currencyId;

        if (!currentCurrency) {
            return value;
        }

        let fromCurrency = currentCurrency;
        let toCurrency = currentCurrency;

        if (userSelectedCurrency && userSelectedCurrency !== currentCurrency) {
            toCurrency = userSelectedCurrency;
        }
        else if (!userSelectedCurrency && currentCurrency !== originCurrency) {
            toCurrency = originCurrency;
        }
        if (fromCurrency === toCurrency){
            return value;
        }
        
        const fromRate = parseFloat(this.currenciesMap[fromCurrency]);
        const toRate = parseFloat(this.currenciesMap[toCurrency]);

        if (isNaN(fromRate) || isNaN(toRate) || fromRate === 0) {
            console.error(`Could not convert from ${fromCurrency} a ${toCurrency}. Rate not found.`);
            return value;
        }
        
        return (value / fromRate) * toRate;
    }

    renderChart(wrapper) {

        const chartData = wrapper || this.chartData;

        //convert datasets
        chartData.datasets.forEach((dataset, index) => {
            this.datasets[index].data = dataset.data.map(val => this.convertCurrency(val));
        });

        //convert targets
        this.targets = chartData.targets.map(target => this.convertCurrency(target));

        this.displayAmount = {
            beginAtZero: true,
            fontFamily: "sans-serif",
            fontSize:11,
            suggestedMax: (Math.max(...this.targets, 0) || 0) * 1.1,
            callback: formatCurrency
        };

        this.chartConfig = {
            type: 'horizontalBar',
            data: {
                labels: this.labels,
                sublabels: this.sublabels,
                datasets: this.datasets,
                currencies: chartData.currencies || [this.currencyId],
                targets: this.targets,
                currencyId: this.currencyId,
                exchangeRate: this.exchangeRate,
                originCurrencies: this.originCurrencies,
                conditions: chartData.conditions,
                showConditionDesc: this.showConditionDesc,
                targetColor: chartData.targetColor,
                trafficlights: this.trafficlights
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                layout: {
                    padding: {
                        left: this.paddingLeft
                    }
                },
                tooltips: {
                    enabled: false,
                    custom: customTooltip
                },
                hover: {
                    animationDuration: 0
                },
                scales: {
                    xAxes: [{
                        stacked: true,
                        id: "xBar",
                        ticks: this.displayAmount,
                        scaleLabel:{
                            display:false
                        }
                    }],
                    yAxes: [{
                        id: 'yBar',
                        ...(this.showConditionDesc && {
                            categoryPercentage: 0.5,
                            barPercentage: 0.85,
                        }),
                        ticks: {
                            beginAtZero: true,
                            fontFamily: "sans-serif",
                            fontSize: 13,
                            fontColor: "#FFFFFF"
                        },
                        stacked: true,
                        gridLines: {
                            color: "#FFFFFF",
                            zeroLineColor: "#FFFFFF",
                            zeroLineWidth: 100
                        },
                    }]
                },
                legend:{
                    display: true,
                    onClick: (e) => e.stopPropagation()
                },
                animation: false,
                pointLabelFontFamily: "sans-serif",
                scaleFontFamily: "sans-serif",
            },
            plugins: [{
                beforeDraw: chart => {
                    if (this.backgroundColor !== 'transparent') {
                        let ctx = chart.chart.ctx;
                        ctx.save();
                        ctx.globalCompositeOperation = 'destination-over';
                        ctx.fillStyle = this.backgroundColor;
                        ctx.fillRect(0, 0, chart.width, chart.height);
                        ctx.restore();
                    }
                },
                afterDraw: chart => {
                    drawTargets(chart);
                }
            }]
        };
        if (!this.hidden) {
            this.showChart();
        }
    }

    showChart() {

        if (this.initialized) {
        return;
        }

        this.initialized = true;
        const canvas = this.template.querySelector('canvas.chart');
        const conditionLengths = (this.chartData?.conditions || []).map(condition => (condition || '').length);
        const maxConditionLength = conditionLengths.length ? Math.max(...conditionLengths) : 0;
        const estimatedConditionLines = Math.max(1, Math.ceil(maxConditionLength / 70));
        const rows = this.labels?.length || 1;
        const conditionLineHeight = this.showConditionDesc ? 25 : 13;
        const messageBottomGap = this.showConditionDesc ? 24 : 26;
        const estimatedRowHeight = 36 + (estimatedConditionLines * conditionLineHeight) + messageBottomGap;
        canvas.height = Math.max(220, (rows * estimatedRowHeight) + 80);

        const ctx = canvas.getContext('2d');
        this.chart = new window.Chart(ctx, this.chartConfig);

        var chart = this.chart;
        this.refs.canvas.addEventListener('mousemove', function (e) {
            toggleNotice(chart, e);
        });

        this.isLoading = false;
    }

    handleSelectChange(event) {

        var currencyCode = event.target.value;
        var exchangeRate = parseFloat(this.currenciesMap[currencyCode]);

        if (isNaN(exchangeRate)) {
            event.preventDefault();
            console.error("Wrong currency: " + currencyCode + ' ' + exchangeRate);
        } else {
            this.currencyId = currencyCode;
            this.exchangeRate = exchangeRate;
            this.chart.clear();
            this.chart.destroy();
            this.initialized = false;
            this.renderChart();
        }
    }

    get light() {
        return this.featureLight;
    }

    @api
    getChartImage(width, height, params) {
        const runImageGeneration = () => new Promise((resolve, reject) => {
            if (!params?.wrapperData) {
                resolve(null);
                return;
            }

            if (!chartJsLoadPromise) {
                chartJsLoadPromise = loadScript(this, chartJS);
            }

            chartJsLoadPromise.then(() => {
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d');
                let chart;

                // Make the canvas itself strictly invisible so it never appears on screen.
                canvas.style.position = 'absolute';
                canvas.style.left = '-9999px';
                canvas.style.visibility = 'hidden';
                document.documentElement.appendChild(canvas);
                
                canvas.setAttribute('width', width || 60);
                canvas.setAttribute('height', height || 40);

                // Clone the wrapperData to avoid LWS '@api invalid mutation' exceptions
                let internalWrapperData = this.wrapperData;

                try {
                    if (params) {
                        Object.keys(params).forEach(param => {
                            if (param === 'wrapperData') {
                                internalWrapperData = JSON.parse(JSON.stringify(params[param]));
                            } else {
                                this[param] = typeof params[param] === 'object' && params[param] !== null
                                    ? JSON.parse(JSON.stringify(params[param]))
                                    : params[param];
                            }
                        });
                    }

                    this.setChartData(internalWrapperData, this.currencyData).then(() => {
                        this.renderChart(internalWrapperData);
                        chart = new window.Chart(ctx, this.chartConfig);

                        if (this.format.toLowerCase() === 'jpeg') {
                            resolve(chart.toBase64Image('image/jpeg', this.quality));
                        } else {
                            resolve(chart.toBase64Image());
                        }
                    }).catch(error => {
                        console.error('Error in chart data/render:', error);
                        resolve(null); // Resolve null rather than rejecting so orchestrator continues
                    }).finally(() => {
                        // 3. Guaranteed cleanup
                        if (chart) {
                            chart.destroy();
                        }
                        if (canvas && canvas.parentNode) {
                            canvas.parentNode.removeChild(canvas);
                        }
                    });

                } catch (err) {
                    console.error('Exception setting up chart parameters:', err);
                    
                    // Cleanup immediately if synchronous code fails before the promise chain
                    if (canvas && canvas.parentNode) {
                        canvas.parentNode.removeChild(canvas);
                    }
                    resolve(null); 
                }
            }).catch(error => {
                console.error('Chart.js not available', error);
                resolve(null);
            });
        });

        const queuedRun = this.imageRenderQueue.then(
            () => runImageGeneration(),
            () => runImageGeneration()
        );

        this.imageRenderQueue = queuedRun.catch(() => undefined);

        return queuedRun;
    }
}