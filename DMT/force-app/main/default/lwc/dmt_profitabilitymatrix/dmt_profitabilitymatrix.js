import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getTaxonomyValues from '@salesforce/apex/DMT_Profitability_Helper.getTaxonomyValues';
import calculateIsPercentageValue from '@salesforce/apex/DMT_Profitability_Helper.calculateIsPercentageValue';


    const NA_STRG = 'N/A';
    const NAN_STRG = 'NaN';
    const TXT_TOAST_ERROR_TITLE = 'Error when try to process the matrix data';
    const TXT_TOAST_COPY_DATA_TITLE = 'Matrix data has been copied';
    const TXT_COPY_COLUMN_TITLE_FIELDSNAMES = 'Variables';
    const TXT_COPY_COLUMN_TITLE_ORIGINALVALUES = 'Values';
    const TXT_COPY_COLUMN_TITLE_OVERRIDEVALUES = 'Override values';
export default class dmt_profitabilitymatrix extends LightningElement {
     
    formattedData;
    @track receivedDataFormated = [];
    @track matrixGeneralInfo = [];
    @track dataLoaded = false;
    ratingScale=[];
    ratingScaleIndexMaxToMin=[];
    overrideTitle=[];
    overrideOriginalTitle=[];
    labelsOverrideFields = new Map([
      ["entityNew" , "Entity "],["entificNew" , "Entific" ],["bookingNew" , "Booking" ],["feesNew" , "Acrual fees" ],["feesPeriodicNew" , "Non acrual fees" ],
      ["spreadFbNew" , "Spread undrawn" ],["spreadAmountNew" , "Spread drawn" ],["nominalAmountNew" , "Notional amount drawn" ],["nominalFbNew" , "Notional amount undrawn" ],
      ["paymentFrequencyNew" , "Payment frequency" ],["amortizationTypeNew" , "Amortization type" ],["countryRiskNew" , "Country risk" ],
      ["countryRatingNew" , "Country rating" ],["currencyNew" , "Currency" ],
      ["extClientRatingNew" , " External client rating" ],["intClientRatingNew" , "Internal client rating " ],["clientTypeNew" , "Client type " ],
      ["termNew", "Term (months)"]
    ]);
    labelsOppDataFields =  new Map([
      ["entity" , "Entity "],["entific" , "Entific" ],["booking" , "Booking" ],["feeUpfront" , "Acrual fees" ],["feePeriodic" , "Non acrual fees" ],
      ["spreadFb" , "Spread undrawn" ],["spreadAmount" , "Spread drawn" ],["nominalAmount" , "Notional amount drawn" ],["nominalFb" , "Notional amount undrawn" ],
      ["paymentFrequency" , "Payment frequency" ],["amortizationType" , "Amortization type" ],["countryRisk" , "Country risk" ],
      ["countryRating" , "Country rating" ],["currency" , "Currency" ],
      ["externalRating" , " External client rating" ],["internalRating" , "Internal client rating " ],["clientType" , "Client type " ],
      ["oppTerm", "Term (months)"]
    ]); 
    fieldOrder = [
      "entific","entity","booking","internalRating","externalRating","clientType","oppTerm","countryRisk","countryRating","currency",
      "amortizationType","paymentFrequency","nominalAmount","nominalFb","spreadAmount","spreadFb","feePeriodic","feeUpfront"
    ];
    showPercentageX = false;
    showPercentageY = false;
    showPercentageCentral = false;
    errorMatrix = false;
    messageError='Unknown error';

    @wire(getTaxonomyValues)
    wiredTaxonomyValues({ error, data }) {
        if (data) {
            this.ratingScale = data;
        } else if (error) {
            this.handleError('Error fetching taxonomy values:'+ error);
        }
    }
    
    @api
    set receivedData(value) {
      if (value && this.isValidOmniValue(value)) {
        this._processReceivedData(value);
      }
     
    }

    get receivedData() {
      return this.receivedDataFormated;
    }

    @api
    set overrideFields(value) {
      if (value && this.isValidOmniValue(value)) {
        this.overrideTitle = Object.entries(value)
          .filter(([key, val]) => val !== undefined && val !== null && val !== '')
          .map(([key, val]) => ({
            field: this.labelsOverrideFields.get(key),
            value: val
          }));
      }
    }

    get overrideFields() {
      return this.overrideTitle;
    }

    @api
    set oppDataOriginal(value) {
      if (value && this.isValidOmniValue(value) && value != 'null') {
        const allowedFields = this.fieldOrder.map(key => this.labelsOppDataFields.get(key));
        this.overrideOriginalTitle = Object.entries(value)
          .filter(([key, val]) => val !== undefined && val !== null && val !== '' &&
            this.labelsOppDataFields.has(key) &&
            allowedFields.includes(this.labelsOppDataFields.get(key))
          )
          .map(([key, val]) => ({
            field: this.labelsOppDataFields.get(key),
            value: val
          }));
      }
    }

     get oppDataOriginal() {
      return this.overrideOriginalTitle;
    }
    
    //Nombre que se pinta en el eje X, recuperado del servicio
    get xAxisName() {
      return this.matrixGeneralInfo.axisX;
    }

    //Nombre que se pinta en el eje y, recuperado del servicio
    get yAxisName() {
      return this.matrixGeneralInfo.axisY;
    }

    // Ejes dinámicos basados en los datos
    get xAxis() {
        // Obtiene valores únicos para el eje X (valueAxisX) y los ordena de forma ascendente
        return  this.orderValues([...new Set(this.receivedDataFormated?.map(item => item.valueAxisX))],'asc');
    }

    get xAxisLabels() {
      let xAxiscopy = this.orderValues([...new Set(this.receivedDataFormated?.map(item => item.valueAxisX))], 'asc');
      return xAxiscopy.map(val => this.formatNumber(val, this.showPercentageX));
  }

  get yAxisLabels() {
      let yAxiscopy = this.orderValues([...new Set(this.receivedDataFormated?.map(item => item.valueAxisY))], 'desc');
      return yAxiscopy.map(val => this.formatNumber(val, this.showPercentageY));
    }

    get yAxis() {
        // Obtiene valores únicos para el eje Y (valueAxisY) y los ordena de forma descendente
        return this.orderValues([...new Set(this.receivedDataFormated?.map(item => item.valueAxisY))],'desc');
    }

    // Get max and min for axis X (valueAxisX) y Y (valueAxisY)
    get xAxisMin() {
        const { min } = this.getMinMax(this.xAxis);
        return min !== null ? this.formatNumber(min, this.showPercentageX) : NA_STRG;
    }

    get xAxisMax() {
        const { max } = this.getMinMax(this.xAxis);
        return max !== null ? this.formatNumber(max, this.showPercentageX) : NA_STRG;
    }

    get yAxisMin() {
        const { min } = this.getMinMax(this.yAxis);
        return min !== null ? this.formatNumber(min, this.showPercentageY) : NA_STRG;
    }

    get yAxisMax() {
        const { max } = this.getMinMax(this.yAxis);
        return max !== null ? this.formatNumber(max, this.showPercentageY) : NA_STRG;
    }

    get centralValueName() {
    return this.matrixGeneralInfo?.axisCentral.toUpperCase() || '';
  }

      _processReceivedData(value) {
            const parsedValue = this.parseJson(value);
            if (!parsedValue || !parsedValue.data) {
                this.handleError('Invalid or empty data received.');
                return;
            }

            // Formatea los datos una sola vez
            this.receivedDataFormated = (parsedValue.data.assumptionResult || []).map(obj => ({
                ...obj,
                valueAxisX: obj.valueAxisX,
                valueAxisY: obj.valueAxisY,
                valueAxisCentral: obj.valueAxisCentral
            }));

            this.matrixGeneralInfo = parsedValue.data.assumption || {};

            if (this.receivedDataFormated.length === 0) {
                    this.handleError('No data to display in the matrix.');
                    return;
                }
            if (!this._validateMatrixSize()) {
                      return;
            }

            // determine percentages for X, Y and Central fields in parallel
            calculateIsPercentageValue({
              axisX: this.matrixGeneralInfo.axisX,
              axisY: this.matrixGeneralInfo.axisY,
              axisCentral: this.matrixGeneralInfo.axisCentral
            })
            .then(flags => {
                this.showPercentageX = !!flags.x;
                this.showPercentageY = !!flags.y;
                this.showPercentageCentral = !!flags.c;

                this.errorMatrix = this.receivedDataFormated.length === 0;
                this.dataLoaded = !this.errorMatrix;

                // Ordena el rating solo si hay datos
                if (this.ratingScale && this.ratingScale.length > 0) {
                    this.ratingScale = [...this.ratingScale].sort(
                        (a, b) => a.gf_catalog_atrb_val1_name_c__c - b.gf_catalog_atrb_val1_name_c__c
                    );
                    this.ratingScaleIndexMaxToMin = this.ratingScale.map(a => a.DMT_Value__c);
                }

                // Solo formatea si hay datos
                if (!this.errorMatrix) {
                    this.formatingData(this.xAxis, this.yAxis);
                }
            })
            .catch(error => {
                this.handleError(error);
                this.errorMatrix = true;
                this.dataLoaded = false;
            });
        }

    _validateMatrixSize() {
        const uniqueX = [...new Set(this.receivedDataFormated.map(item => item.valueAxisX))];
        const uniqueY = [...new Set(this.receivedDataFormated.map(item => item.valueAxisY))];
        if (uniqueX.length > 10 || uniqueY.length > 10) {
            this.handleError('Matrix size it`s bigger than 10 x 10.');
            return false;
        }
        return true;
    }

    parseJson(value) {
      try {
          return JSON.parse(value);
      } catch (error) {
        this.handleError(error);
          return null;
      }
    }

    handleError(error,showToast = false){
      let message = "Unknown error";

      if (Array.isArray(error?.body)) {
        message = error.body.map((e) => e.message).join(", ");
      } else if (typeof error?.body?.message === "string") {
        message = error.body.message;
      } else if (typeof error === "string") {
        message = error;
      }

      this.messageError = message;
      this.errorMatrix = true; 
      this.dataLoaded = false;
      if (showToast) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: TXT_TOAST_ERROR_TITLE,
            message,
            variant: "error",
          }),
        );
      }
    }

  getMinMax(values) {
    let nums;
    if (this.checkIsNumber(values?.[0])) {
      nums = values.map(str => Number(str));
    }
    if (nums && nums.length > 0) {
      return { min: Math.min(...nums), max: Math.max(...nums) };
    } else if (values && values.length > 0) {
      const idxLast = this.ratingScaleIndexMaxToMin.indexOf(values[values.length - 1]);
      const idxFirst = this.ratingScaleIndexMaxToMin.indexOf(values[0]);
      return {
        min: this.ratingScaleIndexMaxToMin[Math.max(idxLast, idxFirst)],
        max: this.ratingScaleIndexMaxToMin[Math.min(idxLast, idxFirst)]
      };
    }
    return { min: null, max: null };
  }

    //Order values from list with mode asc or desc. For ratings ( not numbers) order based on other list ratingScaleIndexMaxToMin
    orderValues(lista,order){
      return [...lista].sort((a,b) => {
        const numA = parseFloat(a);
        const numB = parseFloat(b);
        const isNumA = !isNaN(numA);
        const isNumB = !isNaN(numB);
        switch (order) {
          case 'asc':
            if(isNumA && isNumB){
              return numA - numB;
            } else if(!isNumA && !isNumB){
                return this.ratingScaleIndexMaxToMin.indexOf(b) - this.ratingScaleIndexMaxToMin.indexOf(a);
            }
            return isNumA ? -1 : 1;
          case 'desc':
            if(isNumA && isNumB){
              return numB - numA;
            } else if(!isNumA && !isNumB){
                return this.ratingScaleIndexMaxToMin.indexOf(a) - this.ratingScaleIndexMaxToMin.indexOf(b);
            } 
            return isNumA ? -1 : 1;
          default:
            return isNumA ? -1 : 1;
        }
      })
    }

  checkIsNumber(number){
    const isNumb = !isNaN(parseFloat(number));
    return isNumb;
  }

  // Get the cell data based on x and y values
  getCellData(x, y) {
      const cellData = this.receivedData.find(item =>
      this.compareValuesForFind(item.valueAxisX, x) &&
      this.compareValuesForFind(item.valueAxisY, y)
    );
    if (!cellData) return '-';
    const central = cellData.valueAxisCentral;
    if (central === NAN_STRG || central === null || central === undefined) return '-';
    return this.formatNumber(central, this.showPercentageCentral);
  }


  formatingData(xData,yData){
    const yLabels = this.yAxisLabels;
    this.formattedData = yData.map((yValue, index) => ({
      yValue, // raw value used for lookup
      yLabel: yLabels[index], // display label (percent or raw)
      rowData: xData.map(xValue => ({
        xValue, // raw x value used for lookup
        cellData: this.getCellData(xValue, yValue)
      }))
    }));
  }
  handleExportToExcel(event) {
    event.preventDefault();
    this.copyToClipboard(event);
  }

  copyToClipboard(event) {
    let textContent = this.buildTextTable();
    let textArea = document.createElement('textarea');
    textArea.value = textContent;
    document.body.appendChild(textArea);

    textArea.select();
    document.execCommand('copy');

    document.body.removeChild(textArea);

    this.dispatchEvent(
      new ShowToastEvent({
        title: TXT_TOAST_COPY_DATA_TITLE,
        message:"",
        variant: "success",
      }),
    );
}


  buildTextTable() {
    if (!this.formattedData || this.formattedData.length === 0) return '';
    let result = '';
    result += `\t${this.xAxisName} (Min: ${this.xAxisMin}, Max: ${this.xAxisMax})\n`;
    
    result += '\t';
    this.xAxisLabels.forEach(label => {
        result += `${label}\t`;
    });
    result += '\n';
    
    this.formattedData.forEach(row => {
        result += `${row.yLabel}\t`; 
        row.rowData.forEach(cell => {
            result += `${cell.cellData === '-' ? '' : cell.cellData}\t`;
        });
        result += '\n';
    });

    
    result += `${this.yAxisName} (Min: ${this.yAxisMin}, Max: ${this.yAxisMax})\n`;

    result += '\n'; 
    result += `${TXT_COPY_COLUMN_TITLE_FIELDSNAMES}\t${TXT_COPY_COLUMN_TITLE_ORIGINALVALUES}\t${TXT_COPY_COLUMN_TITLE_OVERRIDEVALUES}\n`;

    this.fieldOrder.forEach(key => {
      const original = this.overrideOriginalTitle.find(item => item.field === this.labelsOppDataFields.get(key));
      const modified = this.overrideTitle.find(item => item.field === this.labelsOppDataFields.get(key));
      result += `${original ? original.field : ''}\t${original ? original.value : ''}`;
      result += `\t${modified ? modified.value : ''}\n`;
    });

    return result;
  }

  isValidOmniValue(value) {
    if (value === null || value === undefined) return false;

    if (typeof value === 'string') {
      const v = value.trim();
      if (v === '' || v.toLowerCase() === 'null') return false;

      // placeholder simple como {overridefields} o {oppData} -> devolver false
      const placeholderRegex = /^\{\s*[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)*\s*\}$/;
      if (placeholderRegex.test(v)) return false;

      return true;
    }else if(typeof value === 'object'){
      return true;
    }
    return false;
  }

  formatNumber(value, isPercent) {
      if (value === null || value === undefined) return '-';
      if (typeof value === 'string' && value.trim() === '') return '-';
      if (value === NAN_STRG) return '-';

      const num = Number(value);
      if (!isFinite(num)) return String(value);
      let v = num;
      if (isPercent) v = v * 100;
      const formatted = v.toFixed(2);
      return isPercent ? `${formatted}%` : formatted;
    }

  compareValuesForFind(a, b) {
      const aIsNum = this.checkIsNumber(a);
      const bIsNum = this.checkIsNumber(b);
      if (aIsNum && bIsNum) {
        return Number(a) === Number(b);
      }
      return String(a) === String(b);
    }    
}