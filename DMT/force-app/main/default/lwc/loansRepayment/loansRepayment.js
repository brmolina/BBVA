import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { loadScript } from 'lightning/platformResourceLoader';
import NODATA from '@salesforce/label/c.DES_Chart_No_Data';
import CHART from '@salesforce/resourceUrl/Chart';
// import CSSFG from '@salesforce/resourceUrl/cssFichaGrupo';
// import DATA from './data';
import getDataLoans from '@salesforce/apex/LoansRepaymentCnt.getData';
import { NavigationMixin } from 'lightning/navigation';
// import { CurrentPageReference } from 'lightning/navigation';

const BBVAREPAYMENT = 'Repayment BBVA';
const TOTALREPAYMENT = 'External Repayment';
const PENDINGBALANCE = 'Pending Balance';
var userCurrency;

export default class LoansRepayment extends NavigationMixin(LightningElement) {
    @api recordId;
    @api selectedTab;
    @track url;
    // Expose the labels to use in the template.
    label = {
        NODATA
    };
    @api showViewDetails;
    showViewDetails2;
    chartjsInitialized = false;
    @track timeRefresh;
    @track noData = false;
    @track error;
    chart;
    @api operation = 'Asset Finance';
    @track columns;
    @track datas;
    @track colours;
    @track labels;



    /*
    * @author GlobalDesktop - APC
    * @description  rendererCallback
    */
    renderedCallback() {
        if (this.chartjsInitialized) {
            return;
        }

        this.chartjsInitialized = true;

        Promise.all([
            loadScript(this, CHART)
                .then(() => {
                    this.getData();
                })
                .catch(error => {
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error loading Chart',
                            message: error.message,
                            variant: 'error',
                        }),
                    );
                }
            ),
        ])
    }

    /*
    * @author GlobalDesktop - APC
    * @description  called in rendererCallback (not connectedCallback!) - chained methods
    */
    getData() {
        getDataLoans({ clientId: this.recordId, operationType: this.operation }).then(result => {
                this.error = null;
                this.manageResponse(JSON.parse(result));
                this.generateUrlNavigation();
            })
            .then(() => {
                if(this.noData == false){
                    let ctx = this.template
                    .querySelector('canvas.canvasChart')
                    .getContext('2d');
                    this.chart = new window.Chart(ctx, this.createConfig());
                }
            })

        //     .catch(error => {
        //         this.error = error;
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error while getting access to Loans Repayments',
        //                 message: error.message,
        //                 variant: 'error',
        //             }),
        //         );
        //     }
        // )
        ;
    }
    /*
    * @author GlobalDesktop - APC
    * @description:
            Store the PageReference in a variable
            This is a plain Javascript object that conforms to the
            PageReference type by including "type" and "attributes" properties
            The "state" property is optional
    */
    generateUrlNavigation() {
        // eslint-disable-next-line no-alert
        // alert(this.selectedTab);
        this.componentReports = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__LoansRepaymentReport'
            },
            state: {
                c__operation: this.operation,
                c__recordId: this.recordId,
                c__selectedTab: this.selectedTab
            }
        }
        this[NavigationMixin.GenerateUrl](this.componentReports)
            // eslint-disable-next-line no-return-assign
            .then(url => this.url = url);
    }
    /*
    * @author GlobalDesktop - APC
    * @description  connectedCallback chained methods
    */
    manageResponse(result) {
        if (!result || Object.values(result.mapData).length <= 0) {
            this.noData = true;
        } else {
            this.noData = false;
            userCurrency = result.userCurrency;
            this.setTimeRefresh();
            this.setColumns(Object.keys(result.mapData));
            this.setDatas(Object.values(result.mapData));
            this.setLabelAndColors(result.mapRowColors);
            //  eslint-disable-next-line no-alert
            // alert('operation:; ' + this.operation);
        }
    }
    /*
    * @author GlobalDesktop - APC
    * @description  setColumns:
    * @input: array of columns Object.keys(result.mapData)
    * @output: void -> set this.columns attribute
    */
    setColumns(array) {
        let columnas = [];
        array.forEach(function (item) {
            columnas.push(item);
        });
        this.columns = columnas;
    }
    /*
    * @author GlobalDesktop - APC
    * @description  setDatas:
    * @input: result
    * @output: void -> set this.datas attribute
    */
    setDatas(datos) {
        if (datos && datos.length > 0) {
            let arrayBBVA = [];
            let arrayTotal = [];
            let arrayPending = [];

            datos.forEach(function (item) {
                let dataBBVA = item[BBVAREPAYMENT];
                let dataTotal = item[TOTALREPAYMENT];
                let dataPending = item[PENDINGBALANCE];

                if (dataBBVA && dataTotal && dataPending) {
                    arrayBBVA.push(dataBBVA);
                    arrayTotal.push(dataTotal - dataBBVA);
                    arrayPending.push(dataPending);
                }
            })
            this.datas = [arrayBBVA, arrayTotal, arrayPending];
        }
    }
    /*
    * @author GlobalDesktop - APC
    * @description  setLabelAndColors:
    * @input:  result.mapRowColors
    * @output: void -> set this.labesl and this.colours attributes
    */
    setLabelAndColors(object) {
        let labels = Object.keys(object);

        const repBBVA = labels.find(function (element) {
            return element === BBVAREPAYMENT;
        });
        const repTotal = labels.find(function (element) {
            return element === TOTALREPAYMENT;
        });
        const pendBal = labels.find(function (element) {
            return element === PENDINGBALANCE;
        });
        let sortedLabels = [repBBVA, repTotal, pendBal];
        let sortedColors = [object[BBVAREPAYMENT], object[TOTALREPAYMENT], object[PENDINGBALANCE]];

        this.labels = sortedLabels;
        this.colours = sortedColors;
    }
    /*
    * @author GlobalDesktop - APC
    * @description  dataset constructor:
    * @input: vLabel, vBackgrCol, vData
    * @output: dataset
    */
    // dataset = function (vLabel, vBackgrCol, vData) {
    //     return {
    //         label: vLabel,
    //         backgroundColor: vBackgrCol,
    //         data: vData
    //     }
    // }
    /*
    * @author GlobalDesktop - APC
    * @description  create config object to be set in chart
    */
    createConfig() {
        let cnTooltip = 0;
        return {
            type: 'bar',
            data: {
                labels: this.columns,
                datasets: [
                    {
                        label: this.labels[2],
                        yAxisID: 'SecondAxis',
                        data: this.datas[2],
                        backgroundColor: this.colours[2],
                        borderColor: this.colours[2],
                        type: 'line',
                        fill: false,
                    },{
                        label: this.labels[0],
                        yAxisID: 'FirstAxis',
                        data: this.datas[0],
                        backgroundColor: this.colours[0],
                        fill: false,
                    }, {
                        label: this.labels[1],
                        yAxisID: 'FirstAxis',
                        data: this.datas[1],
                        backgroundColor: this.colours[1],
                        fill: false,
                        scrollbar: {
                            enabled: true
                        }
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                tooltips: {
                    mode: "index",
                    intersect: true,
                    position: 'nearest',
                    bodySpacing: 4,
                    callbacks: {
                        footer: function (tooltipItems) {
                            const BBVA = tooltipItems[1].yLabel || 0;
                            const NOBBVA = tooltipItems[2].yLabel || 0;
                            let total = BBVA + NOBBVA;

                            total = parseFloat(total).toFixed(2);
                            total += '';
                            let x = total.split('.');
                            let x1 = x[0];
                            let x2 = x.length > 1 ? ',' + x[1] : '';
                            let rgx = /(\d+)(\d{3})/;
                            while (rgx.test(x1)) {
                                x1 = x1.replace(rgx, '$1.$2');
                            }
                            total = x1 + x2;
                            return 'Total repayments: ' + total + ' ' + userCurrency;
                        },
                        label: function (tooltipItems, data) {
                            const SUMDATASETS = 3;
                            let tooltipText = [];
                            let labels = [];
                            let values = [];
                            for (let cn = 0; cn < SUMDATASETS; cn++) {
                                labels[cn] = data.datasets[cn].label || '';
                                values[cn] = data.datasets[cn].data[tooltipItems.index] || 0;
                            }
                            for (let cn = 0; cn < SUMDATASETS; cn++) {

                                values[cn] = parseFloat(values[cn]).toFixed(2);
                                values[cn] += '';
                                let x = values[cn].split('.');
                                let x1 = x[0];
                                let x2 = x.length > 1 ? ',' + x[1] : '';
                                let rgx = /(\d+)(\d{3})/;
                                while (rgx.test(x1)) {
                                    x1 = x1.replace(rgx, '$1.$2');
                                }
                                values[cn] = x1 + x2;
                            }
                            tooltipText.push(' ' + labels[cnTooltip] + ': ' + values[cnTooltip] + ' ' + userCurrency);
                            if (cnTooltip === SUMDATASETS - 1)
                                cnTooltip = 0;
                            else
                                cnTooltip++;

                            return tooltipText;
                        }
                    }
                },

                // array.forEach(function (a, i) {
                //     lineChartData.datasets[i].data = JSON.parse(a);
                // });

                legend: {
                    display: true,
                    position: "bottom",
                    labels: {
                        fontSize: 12,
                        boxWidth: 40,
                        boxHeight: 4,
                        // usePointStyle: true
                    },
                    onClick: (evt) => evt.stopPropagation()
                },
                animation: {
                    animateScale: true,
                    animateRotate: true
                },
                scales: {
                    yAxes: [{
                        id: 'FirstAxis',
                        type: 'linear',
                        position: 'left',
                        stacked: true,
                        // gridLines: {
                        //     show: true,
                        //     color: "F3F3F3",
                        // },
                        scaleLabel: {
                            display: true,
                            labelString: 'Repayments'
                        },
                        ticks: {
                            major: {
                                fontStyle: 'bold',
                                fontColor: '#FF0000'
                            }
                        },
                        yAxes: [{
                            stacked: true,
                            // ticks: {
                            //     // Include a dollar sign in the ticks
                            //     callback: function (value) {
                            //     // callback: function (value, index, values) {
                            //         return '€' + value;
                            //     }
                            // },

                        }]
                    }, {
                        id: 'SecondAxis',
                        type: 'linear',
                        position: 'right',
                        stacked: true,
                        // ticks: {
                        //     max: 4,
                        //     min: 0
                        // },
                        gridLines: {
                            display: false
                        },
                        offset: true,
                            scaleLabel: {
                                display: true,
                                labelString: 'Pending Balance'
                            },
                    }],
                    xAxes: [{
                        stacked: true
                    }],
                }
            }
        }
    }
    /*
    * @author GlobalDesktop - APC
    * @description  setTimeRefresh: utils to set properly data time
    */
    setTimeRefresh() {
        let dat = new Date();

        if (dat.getHours() >= 0 && dat.getHours() < 10) {
            if (dat.getMinutes() >= 0 && dat.getMinutes() < 10) {
                this.timeRefresh = "0" + dat.getHours() + ":0" + dat.getMinutes();
            } else {
                this.timeRefresh = "0" + dat.getHours() + ":" + dat.getMinutes();
            }
        } else {
            if (dat.getMinutes() >= 0 && dat.getMinutes() < 10) {
                this.timeRefresh = dat.getHours() + ":0" + dat.getMinutes();
            } else {
                this.timeRefresh = dat.getHours() + ":" + dat.getMinutes();
            }
        }
    }
    /*
    * @author GlobalDesktop - APC
    * @description  tooltipIndex - wip
    */
    // static getTooltipIndex(tooltip, maxIndex) {
    //     let index = tooltip ? tooltip : 0;
    //     switch (index >= maxIndex) {
    //         case true :
    //             index++;
    //             break;
    //         default:
    //             index = 0;
    //             break;
    //     }
    // }
    // static cnTooltip = 0


    /*
    * @author GlobalDesktop - APC
    * @description  navigateToMyComponent - wip
    */
    navigateToMyComponent(evt) {
        // Stop the event's default behavior.
        // Stop the event from bubbling up in the DOM.
        evt.preventDefault();
        evt.stopPropagation();
        // Navigate to the Account Home page.
        // this[NavigationMixin.Navigate](this.accountHomePageRef);
        this[NavigationMixin.Navigate](this.componentReports)
    }
/*
* @author GlobalDesktop - APC
* @description  launchEventOperation
*/
    // launchEventOperation() {
    //     const operationEVT = new CustomEvent('operation', {
    //         detail: this.operation,
    //     });
    //     this.dispatchEvent(operationEVT);
    // }
}