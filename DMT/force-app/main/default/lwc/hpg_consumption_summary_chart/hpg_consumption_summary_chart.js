import {LightningElement, api, wire} from 'lwc';
//import chartjs from '@salesforce/resourceUrl/chartjs_v443';
import getCurrentLimits from '@salesforce/apex/HPG_SecondaryTablesController.getCurrentLimits';
import getCurrencies from '@salesforce/apex/HPG_SecondaryTablesController.getCurrencies';
import chartjs from '@salesforce/resourceUrl/HPG_ChartJS';
import { formatCurrency, drawTargets, chartColour, customTooltip, sortedIds } from './hpg_consumption_summary_chart_utils.js';
import { labels } from './hpg_consumption_summary_labels.js';
import { loadScript } from 'lightning/platformResourceLoader';

export default class Hpg_consumption_summary_chart extends LightningElement {

  title = 'Summary';
  initialized;
  labels = labels;
  sortedIds = sortedIds;
  chartColour = chartColour;

  @api clientId;
  @api clientType;
  @api searchDate;
  @api clientName;
  @api chartData = [];
  @api currencyId = 'EUR';
  @api exchangeRate;
  @api useSummary = false;

  chartConfig = {};
  currencies = {};
  chartLabels = [];
  targets = [];
  datasets = [];
  displayAmount;

  @wire(getCurrencies, {
    baseCurrency: '$currencyId'
  })
  chartCurrencies({error, data}) {
    if (data) {
        this.currencies = data;
    } else if (error) {
        this.error = error;
        console.error('Error loading chart currencies');
        console.error(error);
        this.isLoading = false;
    }
  }

  @wire(getCurrentLimits, {
    clientId: '$clientId',
    clientType: '$clientType',
    searchDate : '$searchDate'
  })
  currentLimits({error, data}) {
    if (data) {
        console.log(data);
        this.setChartData(this.chartData, data).then( result => {

            this.displayAmount = {
                beginAtZero: true,
                fontFamily: "sans-serif",
                fontSize:11,
                suggestedMax: Math.max(...this.targets),
                callback: formatCurrency
            };

            this.chartConfig = {
                type: 'horizontalBar',
                data: {
                    labels: this.chartLabels,
                    datasets: this.datasets,
                    targets: this.targets,
                    currency: this.currencyId,
                    exchangeRate: this.exchangeRate
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Consumption summary'
                        },
                    },
                    tooltips: {
                        enabled: false,
                        custom: customTooltip
                    },
                    hover: {
                        animationDuration:0
                    },
                    scales: {
                        xAxes: [{
                            id: "xBar",
                            ticks: this.displayAmount,
                            scaleLabel:{display: false},
                            gridLines: {},
                            stacked: true
                        }],
                        yAxes: [{
                            id: 'yBar',
                            stacked: true,
                            gridLines: {
                                color: "#fff",
                                zeroLineColor: "#fff",
                                zeroLineWidth: 100
                            },
                            ticks: {
                                beginAtZero: true,
                                fontFamily: "sans-serif",
                                fontSize: 13
                            }
                        }]
                    },
                    legend:{
                        display: true,
                        onClick: (e) => e.stopPropagation()
                    },
                    animation: {
                        onComplete: drawTargets
                    }
                }
            };
            this.showChart();
        });

    } else if (error) {
      this.error = error;
      console.error('Error loading chart data');
      console.error(error);
      this.isLoading = false;
    }
  };

  setChartData(data, limits) {

    return new Promise((resolve, reject) => {

        if (this.useSummary) {
            // use amounts from hpg_consumption_summary service instead
            var chartData = {};
            data.data.data.forEach( data => {
                chartData[data.consumptionLastLevelId] = {data:{}, currentApprovedAmount: 0, label: this.labels[data.consumptionLastLevelId]};
                ['authorizedRiskAmount',
                'cNotSignedTrConsumptionAmount',
                'committedContractsDisposedAmount',
                'committedContractsNonDisposedAmount',
                'uncommittedContractsDisposedAmount',
                'uncommittedContractsNonDisposedAmount'].forEach( lastLevelId => {
                    chartData[data.consumptionLastLevelId].data[lastLevelId] = this.sum(data.catalogs, lastLevelId);
                });
                if (limits.data.find( key => key.consumptionLastLevelId === data.consumptionLastLevelId)) {
                    chartData[data.consumptionLastLevelId].currentApprovedAmount = limits.data.find( key => key.consumptionLastLevelId === data.consumptionLastLevelId).currentApprovedAmount * this.exchangeRate;
                }
            });

            ['authorizedRiskAmount',
            'cNotSignedTrConsumptionAmount',
            'committedContractsDisposedAmount',
            'committedContractsNonDisposedAmount',
            'uncommittedContractsDisposedAmount',
            'uncommittedContractsNonDisposedAmount'].forEach( amount => {
                var data = [];
                Object.keys(chartData).forEach( lastLevelId => {
                    data.push(chartData[lastLevelId].data[amount] * this.exchangeRate);
                });
                this.datasets.push({
                    id: amount,
                    label: this.labels[amount],
                    data: data,
                    backgroundColor: chartColour[amount],
                    hoverBackgroundColor: chartColour[amount + '_hover']
                });
            });

            Object.keys(chartData).forEach( lastLevelId => {
                this.targets.push(chartData[lastLevelId].currentApprovedAmount * this.exchangeRate);
                this.chartLabels.push(chartData[lastLevelId].label + ' (' + lastLevelId + ')');
            });

            resolve(true);

        } else {

            if (limits.success) {

                //var sorted = limits.data.slice().sort((a, b) => a.consumptionLastLevelId - b.consumptionLastLevelId);

                var sorted = limits.data.slice().sort((a, b) => sortedIds.indexOf(a.consumptionLastLevelId) - sortedIds.indexOf(b.consumptionLastLevelId));

                ['sumDisposedAmount',
                'committedContractsNonDisposedAmount',
                'uncommittedContractsNonDisposedAmount',
                'authorizedRiskAmount',
                'cNotSignedTrConsumptionAmount',].forEach( amount => {
                    var data = [];
                    sorted.forEach( limit => {
                        data.push(limit[amount] * this.convert(1, limit.currencyId));
                    });
                    this.datasets.push({
                        id: amount,
                        label: this.labels[amount],
                        data: data,
                        backgroundColor: chartColour[amount],
                        hoverBackgroundColor: chartColour[amount + '_hover']
                    });
                });

                // remove bars where limit = 0
                for (let index = sorted.length - 1; index >= 0; index--) {
                    var limit = sorted[index];
                    if (!limit.currentApprovedAmount || limit.currentApprovedAmount <= 0) {
                        this.datasets.forEach( dataset => {
                            dataset.data.splice(index, 1);
                        });
                    }
                };

                sorted.forEach( limit => {
                    if (limit.currentApprovedAmount && limit.currentApprovedAmount > 0) {
                        this.targets.push(limit.currentApprovedAmount * this.convert(1, limit.currencyId));
                        this.chartLabels.push(this.labels[limit.consumptionLastLevelId]); //+ ' (' + limit.consumptionLastLevelId + ')'
                    }
                });

                resolve(true);
            } else {
                console.error(limits.errorMessage);
                reject(`No chart data returned`);
            }
        }
    });
  }

  showChart() {

    if (this.initialized) {
      return;
    }

    this.initialized = true;
    console.log('Chart initialized ' + this.initialized);

    Promise.all([loadScript(this, chartjs)]).then(() => {
        const ctx = this.template.querySelector('canvas.summarychart').getContext('2d');
        console.log('context ' + ctx)
        var chart = new window.Chart(ctx, this.chartConfig);
        this.isLoading = false;
    }).catch(error => {
        console.error('ERROR loading chart:', error.message);
        this.isLoading = false;
    });
  }

  sum(catalogs, item) {
    return catalogs.reduce(function (sum, catalog) {
        return sum + catalog[item] * this.exchangeRate;
    }, 0);
  }

  convert(amount, target) {
    if (!target || target == this.baseCurrency ) {
        return amount;
    }
    var exchangeRate = this.currencies.exchangeRates.find(currency => currency.currencyId == target).exchangeRate;
    return amount * exchangeRate;
  }

}