import { api, track, wire, LightningElement } from 'lwc';
import getDerivativesData from '@salesforce/apex/HPG_SecondaryTablesController.getDerivativesData';
import chartjs from '@salesforce/resourceUrl/HPG_ChartJS';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Hpg_derivativesChart extends LightningElement {

  title = 'Derivatives';
  initialized;

  @api clientId;
  @api clientType;
  @api clientName;
  @api searchDate;
  @api countries;
  @api params;
  @api currency;
  @api exchangeRate;

  @track data = [];
  @track chartConfig = {};

  chartData = [];
  chartLabels = [];

  @wire(getDerivativesData, {
    clientId: '$clientId',
    clientType: '$clientType',
    countries: '$countries',
    searchDate : '$searchDate',
    page : 1,
    pageSize : 5000,
    grouped: true
  })
  derivativesChart({error, data}) {
    this.chartConfig = {
      type: 'bar',
      data: {
        datasets: [
        {
          label: 'Derivatives Risk Detail',
          currency: this.currency,
          barPercentage: 0.6,
          minBarLength: 2,
          backgroundColor: '#9AD0F5',
          borderWidth: 1,
          yAxisID: 'barY',
        }]
      },
      options: {
        maintainAspectRatio: false,
        responsive: true,
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: function(tooltipItem, data) {
              //var label = data.datasets[tooltipItem.datasetIndex].label || '';
              return new Intl.NumberFormat('es-AR', { style: 'currency', currency: data.datasets[0].currency || 'EUR' }).format(tooltipItem.yLabel);;
            }
          }
        },
        scales: {
          yAxes: [
            {
              id: 'barY',
              beginAtZero: false,
              display: true,
              stacked: true,
              position: 'left'
            }
          ]
        }
      }
    };

    if (data) {
      this.setChartData(data).then( result => {
        this.chartConfig.data.labels = this.chartLabels;
        this.chartConfig.data.datasets[0].data = this.chartData;
        this.showChart();
      });

    } else if (error) {
      this.error = error;
      console.error(data.message);
      this.isLoading = false;
    }
  };

  setChartData(data) {
    return new Promise((resolve, reject) => {
      if (data.success) {
        data.data.forEach( data =>  {
          data.detailDerivatives.forEach( detail => {
            this.chartData.push(parseFloat(detail.ctptyRiskExpsrAmount) * this.exchangeRate);
            this.chartLabels.push(detail.tenorDate);
          });
        });
        resolve(true);
      } else {
        reject(`No data returned`);
      }
    });
  }

  showChart() {

    if (this.initialized) {
      return;
    }

    this.initialized = true;
    var currencyId = localStorage.getItem('hpg_currency');

    var displayAmountsFunction = {
      callback: function(value, index, values) {
        if (value >= 1e12) {
          return (value/1e12).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + 'B ' + currencyId;
        } else if(value  >= 1e6) {
          return (value/1e6).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + 'M ' + currencyId;
        } else if(value == 0) {
          return (value).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",");
        } else {
          return (value).toString().replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",") + ' ' + currencyId;
        }
      }
    };

    this.chartConfig.options.scales.yAxes[0].ticks = displayAmountsFunction;
    //this.chartConfig.options.scales.yAxes[1].ticks = displayAmountsFunction;

    console.log('Chart initialized ' + this.initialized)
    Promise.all([
        loadScript(this, chartjs)

    ]).then(() => {
        const ctx = this.template.querySelector('canvas.chart').getContext('2d');
        console.log('context ' + ctx)
        var chart = new window.Chart(ctx, this.chartConfig);
        this.isLoading = false;

    }).catch(error => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error loading BAR Chart',
                message: error.message,
                variant: 'error',
            })
        );
        this.isLoading = false;
    });
  }

}