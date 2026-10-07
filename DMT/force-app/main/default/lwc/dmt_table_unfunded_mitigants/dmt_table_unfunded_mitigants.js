import { LightningElement, api, wire } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrencyValues from '@salesforce/apex/DMT_MitigantsController.getCurrencyValues';
import TITLETABLE from '@salesforce/label/c.dmt_cl_Guarantors_Text';


export default class Dmt_table_unfunded_mitigants extends LightningElement {
  @api startDate;
  @api tabletype;
  @api totalamount;
  @api conversionLabel;
  @api endDateProduct;
  currencyvalue;
  defaultLimitvalue;
  bookingGeography;
  tableData;
  labels = {
    TITLETABLE,
  };
  @api columnstablecopypaste = [];
  CurrencyIsoCode;
  validValuesLabel = ['Others > Guarantee in favour of Public Administration', 'Others > ECA Guarantor (Exporte Credit agency)', 'Others > Shared maintenance clause',
    'Personal > Parent guarantee',  'Personal > Corporate', 'Personal > Bank'];


  @api
  set oppState(value) {
    this._oppState = value;
    this.updateButtonsState();
  }
  get oppState() {
    return this._oppState;
  }

  @wire(getCurrencyValues)
  wiredCurrencies({ error, data }) {
      if (!data) {
        this.error = error;
        this.CurrencyIsoCode = [];
        return;
    }
    const uniqueCurrencies = [...new Set(data)];
    this.CurrencyIsoCode = uniqueCurrencies.map(item => ({
        label: item,
        value: item
    }));
    this.error = null;
    }
  @api
  get table() {
    return this.tableData;
  }

  set table(value) {
    console.log('oppState en set table Irene:', this.oppState);
    let normalizedData;

    try {
      if (typeof value === 'string') {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) {
          normalizedData = parsed;
        } else if (typeof parsed === 'object' && parsed !== null) {
          normalizedData = [parsed];
        } else {
          normalizedData = [];
        }
      } else if (Array.isArray(value)) {
        normalizedData = value.filter(item => typeof item === 'object' && item !== null);
      } else if (typeof value === 'object' && value !== null) {
        normalizedData = [value];
      } else {
        console.warn('Formato inesperado para table:', value);
        normalizedData = [];
      }
    } catch (e) {
      console.error('Error al procesar table:', e);
      normalizedData = [];
    }

    normalizedData = normalizedData.filter(
          option => this.validValuesLabel.includes(option.Mitigant_Type__c)
        );
    if (normalizedData.length > 0) {
      const newArray = normalizedData.map((item, index) => {
        const newItem = { ...item };
        if (index === normalizedData.length - 1) {
          newItem.buttonDisabled = this.oppState == 'Draft' ? false : true;
          newItem.pickDisabled = this.oppState == 'Draft' ? false : true;
          newItem.deleteDisabled = this.oppState == 'Draft' ? normalizedData.length === 1 : true;
          newItem.editDisabled = this.oppState == 'Draft' ? false : true;

        }
        return newItem;
      });

      this.tableData = newArray;
    } else {
      this.tableData = [
          {
              "deleteDisabled": true,
              "pickDisabled":  this.oppState === 'Draft' ? false : true,
              "initRead": "true",
              "buttonDisabled":  this.oppState === 'Draft' ? false : true,
              "tabletype": "Derivatives"
          }
      ];
    }
  }

  @api
  get defaultLimit() {
    return this.defaultLimitvalue;
  }
  set defaultLimit(value) {
    this.defaultLimitvalue = value;
    if (value.toLowerCase() === 'true') {
      this.handledefaultLimit();
    }
  }

  @api
  get bookingGeographyLine() {
    return this.bookingGeography;
  }
  set bookingGeographyLine(value) {
    this.bookingGeography = value;
  }

  @api
  get currency() {
    return this.currencyvalue;
  }
  set currency(value) {
    this.columns = [
      {
        fieldName: "Mitigant_Type__c",
        label: "Mitigant Type",
        type: "text",
        editable: false,
        initialWidth : 270,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          placeholder: 'Select..',
          options: this.termoptions,
          fieldName: 'Mitigant_Type__c',
          value: { fieldName: 'Mitigant_Type__c' },
          context: { fieldName: 'Id' }
        }
      },
      {
        fieldName: "DMT_Guarantor_Display__c",
        label: "Guarantor (IDClient - Nombre)",
        type: "text",
        editable: false,
        initialWidth : 270,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'center' }
      },
      {
        fieldName: "Commercial_Percentage__c",
        label: "Commercial Risk (%)",
        type: 'percent-fixed',
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          step: '0.001'
        }
      },
      {
        fieldName: "Political_Percentage__c",
        label: "Political Risk (%)",
        type: 'percent-fixed',
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          step: '0.001'
        }
      },
      {
        fieldName: 'End_Date__c',
        label: 'End Date',
        type: 'date',
        editable:false,
        initialWidth :140,
        hideDefaultActions:true,
        cellAttributes:{style: 'text-align: center;'},
        typeAttributes: {
            aviableItem: {fieldName: 'aviableItem'},
            dateValue: { fieldName: 'End_Date__c' },
            fieldName: 'End_Date__c',
            value: { fieldName: 'End_Date__c' },
            context: { fieldName: 'Id' }
        }
      },
      {
        fieldName: "Internal_Rating__c",
        label: "Internal Rating",
        type: "text",
        editable: false,
        initialWidth : 100,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'center' }
      },
      {
        fieldName: "DMT_Scoring__c",
        label: "Scoring",
        type: "text",
        editable: false,
        initialWidth : 90,
        hideDefaultActions: true,
        cellAttributes: { alignment: 'center' }
      },
      {
        fieldName: "External_Rating__c",
        label: "External Rating",
        type: "text",
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          value: { fieldName: 'External_Rating__c' },
          context: { fieldName: 'Id' }
        }
      },
      {
        fieldName: "DMT_Currency__c",
        label: "Currency",
        type: "text",
        editable: false,
        hideDefaultActions: true,
        cellAttributes: {
          alignment: 'center'
        },
        typeAttributes: {
          placeholder: 'Select..',
          options: this.CurrencyIsoCode,
          fieldName: 'DMT_Currency__c',
          value: { fieldName: 'DMT_Currency__c' },
          context: { fieldName: 'Id' }
        }
      },
      /*{
        fieldName: "Counterpart__c",
        label: "CLIENT TYPE",
        type: "text",
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          placeholder: 'Select..',
          options: this.counterPartOptions,
          fieldName: 'Counterpart__c',
          value: { fieldName: 'Counterpart__c' },
          context: { fieldName: 'Id' }
        }
      },
      {
        fieldName: "SCRA__c",
        label: "SCRA",
        type: "text",
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          placeholder: 'Select..',
          options: this.scraOptions,
          fieldName: 'SCRA__c',
          value: { fieldName: 'SCRA__c' },
          context: { fieldName: 'Id' }
        }
      },
      {
        fieldName: "AVC_Check__c",
        label: "ASSET VALUE CORRELATION",
        type: "boolean",
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          value: { fieldName: 'AVC_Check__c' },
          context: { fieldName: 'Id' }
        }
      },
      {
        fieldName: "Garantor_European_ECA__c",
        label: "GUARANTOR EUROPEAN ECA",
        type: "boolean",
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          value: { fieldName: 'Garantor_European_ECA__c' },
          context: { fieldName: 'Id' }
        }
      },
      {
        fieldName: "European_Bank_Check__c",
        label: "EUROPEAN BANK",
        type: "boolean",
        editable: false,
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        typeAttributes:
        {
          value: { fieldName: 'European_Bank_Check__c' },
          context: { fieldName: 'Id' }
        }
      },*/
      {
        type: 'button',
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        initialWidth: 60,
        typeAttributes:
        {
          iconName: 'utility:delete',
          label: ' ',
          name: 'deleteRecord',
          title: '',
          disabled: { fieldName: 'deleteDisabled' },
          iconPosition: 'center',
          value: 'test'
        }
      },
      {
        type: 'button',
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        initialWidth: 60,
        typeAttributes:
        {
          iconName: 'utility:edit',
          label: ' ',
          name: 'edit',
          title: '',
          disabled: { fieldName: 'editDisabled' },
          iconPosition: 'center',
          value: 'test'
        }
      },
      {
        type: 'button',
        hideDefaultActions: true,
        cellAttributes:
        {
          alignment: 'center'
        },
        initialWidth: 60,
        typeAttributes:
        {
          iconName: 'utility:add',
          label: '    ',
          name: 'addRecord',
          title: '        ',
          disabled: { fieldName: 'buttonDisabled' },
          iconPosition: 'center',
          value: 'test'
        }
      }
    ];
  }

  termoptions = [{ label: "Others > Guarantee in favour of Public Administration", value: "O2" }, { label: "Others > Standby Letter of Credit", value: "O3" }, { label: "Others > ECA Guarantor (Exporte Credit agency)", value: "O4" }];
  liquidPeriodOptions = [{ label: "5 días", value: "5" }, { label: "10 días", value: "10" }, { label: "20 días", value: "20" }];
  counterPartOptions = [{ label: "Sovereign	", value: "SOV" }, { label: "Financial Institutions - Banks", value: "FI" }];
  scraOptions = [{ label: "A+", value: "A+" }, { label: "A", value: "A" }, { label: "B", value: "B" }];

  columns = [
    {
      fieldName: "Mitigant_Type__c",
      label: "MITIGANT TYPE",
      type: "text",
      editable: false,
      initialWidth : 270,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        placeholder: 'Select..',
        options: this.termoptions,
        fieldName: 'Mitigant_Type__c',
        value: { fieldName: 'Mitigant_Type__c' },
        context: { fieldName: 'Id' }
      }
    },
    {
      fieldName: "DMT_Guarantor_Display__c",
      label: "GUARANTOR (IDCLIENT - NOMBRE)",
      type: "text",
      editable: false,
      initialWidth : 270,
      hideDefaultActions: true,
      cellAttributes: { alignment: 'center' }
    },
    {
      fieldName: "Commercial_Percentage__c",
      label: "COMMERCIAL RISK (%)",
      type: 'percent-fixed',
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        step: '0.001'
      }
    },
    {
      fieldName: "Political_Percentage__c",
      label: "Political Risk (%)",
      type: 'percent-fixed',
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        step: '0.001'
      }
    },
    {
      fieldName: 'End_Date__c',
      label: 'END DATE',
      type:  'date',
      editable:false,
      initialWidth :140,
      hideDefaultActions:true,
      cellAttributes:{style: 'text-align: center;'},
      typeAttributes: {
          aviableItem: {fieldName: 'aviableItem'},
          dateValue: { fieldName: 'End_Date__c' },
          fieldName: 'End_Date__c',
          value: { fieldName: 'End_Date__c' },
          context: { fieldName: 'Id' }
      }
    },
    {
      fieldName: "Internal_Rating__c",
      label: "INTERNAL RATING",
      type: "text",
      editable: false,
      initialWidth : 100,
      hideDefaultActions: true,
      cellAttributes: { alignment: 'center' }
    },
    {
      fieldName: "DMT_Scoring__c",
      label: "SCORING",
      type: "text",
      editable: false,
      initialWidth : 90,
      hideDefaultActions: true,
      cellAttributes: { alignment: 'center' }
    },
    {
      fieldName: "External_Rating__c",
      label: "External Rating",
      type: "text",
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        value: { fieldName: 'External_Rating__c' },
        context: { fieldName: 'Id' }
      }
    },
    {
          fieldName:"DMT_Currency__c",
          label:"CURRENCY",
          type: "text",
          editable:false,
          hideDefaultActions:true,
          cellAttributes:
          {
            alignment: 'center'
          },
          typeAttributes:
          {
            placeholder: 'Select..',
            options: this.CurrencyIsoCode,
            fieldName: 'DMT_Currency__c',
            value: { fieldName: 'DMT_Currency__c' },
            context: { fieldName: 'Id' }
          }
        },
    /*{
      fieldName: "Counterpart__c",
      label: "CLIENT TYPE",
      type: "text",
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        placeholder: 'Select..',
        options: this.counterPartOptions,
        fieldName: 'Counterpart__c',
        value: { fieldName: 'Counterpart__c' },
        context: { fieldName: 'Id' }
      }
    },
    {
      fieldName: "SCRA__c",
      label: "SCRA",
      type: "text",
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        placeholder: 'Select..',
        options: this.scraOptions,
        fieldName: 'SCRA__c',
        value: { fieldName: 'SCRA__c' },
        context: { fieldName: 'Id' }
      }
    },
    {
      fieldName: "AVC_Check__c",
      label: "ASSET VALUE CORRELATION",
      type: "boolean",
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        value: { fieldName: 'AVC_Check__c' },
        context: { fieldName: 'Id' }
      }
    },
    {
      fieldName: "Garantor_European_ECA__c",
      label: "GUARANTOR EUROPEAN ECA",
      type: "boolean",
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        value: { fieldName: 'Garantor_European_ECA__c' },
        context: { fieldName: 'Id' }
      }
    },
    {
      fieldName: "European_Bank_Check__c",
      label: "EUROPEAN BANK",
      type: "boolean",
      editable: false,
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      typeAttributes:
      {
        value: { fieldName: 'European_Bank_Check__c' },
        context: { fieldName: 'Id' }
      }
    },*/
    {
      type: 'button',
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      initialWidth: 60,
      typeAttributes:
      {
        iconName: 'utility:delete',
        label: ' ',
        name: 'deleteRecord',
        title: '',
        disabled: { fieldName: 'deleteDisabled' },
        iconPosition: 'center',
        value: 'test'
      }
    },
    {
      type: 'button',
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      initialWidth: 60,
      typeAttributes:
      {
        iconName: 'utility:edit',
        label: ' ',
        name: 'edit',
        title: '',
        //disabled: { fieldName: 'buttonDisabled' },
        iconPosition: 'center',
        value: 'test'
      }
    },
    {
      type: 'button',
      hideDefaultActions: true,
      cellAttributes:
      {
        alignment: 'center'
      },
      initialWidth: 60,
      typeAttributes:
      {
        iconName: 'utility:add',
        label: '    ',
        name: 'addRecord',
        title: '        ',
        disabled: { fieldName: 'buttonDisabled' },
        iconPosition: 'center',
        value: 'test'
      }
    }
  ];

  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;
    switch (action.name) {
      case 'deleteRecord':{
            const removeFromTable = () => {
                let copyData = (this.tableData || []).filter(item => item.Id !== row.Id);
                if (copyData.length === 0) {
                  copyData = [{
                    deleteDisabled: true,
                    pickDisabled: this.oppState === 'Draft' || this.oppState === 'Ready to close' ? false : true,
                    initRead: 'true',
                    buttonDisabled: this.oppState === 'Draft' || this.oppState === 'Ready to close' ? false : true,
                    editDisabled: this.oppState === 'Draft' || this.oppState === 'Ready to close' ? false : true,
                    tabletype: 'Derivatives',
                    Mitigant_Type__c: '',
                    Political_Percentage__c: '0',
                    Commercial_Percentage__c: '0',
                    Id: '0',
                    updateKeyId: ''
                  }];
                }

                if (copyData.length > 0) {
                  const lastRow = copyData[copyData.length - 1];
                  lastRow.buttonDisabled = this.oppState === 'Draft' || this.oppState === 'Ready to close' ? false : true;
                  lastRow.editDisabled = this.oppState === 'Draft' || this.oppState === 'Ready to close' ? false : true;
                  lastRow.pickDisabled = this.oppState === 'Draft' || this.oppState === 'Ready to close' ? false : true;
                  lastRow.deleteDisabled = (this.oppState === 'Draft' || this.oppState === 'Ready to close') && copyData.length > 0 ? false : true;

                  copyData[0].buttonDisabled = true;
                }

                this.tableData = copyData;
                this.dispatchEvent(new CustomEvent('tableMitigantChange', {
                  bubbles: true,
                  composed: true,
                  detail: { data: copyData }
                }));
            };

            // Detectar si es un Id real de Salesforce: evita llamar deleteRecord en filas nuevas temporales
            const hasRealId = this.isSalesforceId ? this.isSalesforceId(row.Id) : (typeof row.Id === 'string' && row.Id !== '0' && row.Id.length >= 15);
            if (!hasRealId) {
                    removeFromTable();
                    break;
            }
            deleteRecord(row.Id)
            .then(() => {
              this.dispatchEvent(
              new ShowToastEvent({
                title: 'Record deleted',
                message: 'The Guarantors was successfully deleted.',
                variant: 'success'
              }));

              removeFromTable();

              this.dispatchEvent(new CustomEvent('reloadparent', { bubbles: true, composed: true }));

            })
            .catch(error => {
              this.dispatchEvent(new ShowToastEvent({
                title: 'Error deleting',
                message: (error && error.body && error.body.message) ? error.body.message : 'It was not possible to delete the record.',
                variant: 'error'
              }));
            });

          break;
        }

/*       const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);

      console.log('mitigantname irene', this.tableData[index]["Name"]);
       this.dispatchEvent(new CustomEvent('deleteModal', {
          detail: { rowId: row.Id, tabletype: row.tabletype ,mitigantId : this.tableData[index]["Id"], mitigantName : this.tableData[index]["Name"] },
          bubbles: true,
          composed: true
        }));


        break; */
      case 'addRecord':
        /*
        const index = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
        let copyDataNew = [
          ...this.tableData.slice(0, index + 1),
          {
            "Mitigant_Type__c": "2026",
            "Id": this.tableData.length,
            "Commercial_Percentage__c": 0,
            "initRead": true,
            "tabletype": this.tableData[index]["tabletype"],
            "line": this.tableData[0]["line"],
            "deleteDisabled": false,
            'buttonDisabled': true
          },
          ...this.tableData.slice(index + 1)
        ];
        let sendcopyDataNew = this.copiarLista(copyDataNew);
        sendcopyDataNew[sendcopyDataNew.length - 2]['buttonDisabled'] = true;
        sendcopyDataNew[sendcopyDataNew.length - 1]['buttonDisabled'] = true;
        sendcopyDataNew[sendcopyDataNew.length - 2]['pickDisabled'] = true;
        sendcopyDataNew[sendcopyDataNew.length - 1]['pickDisabled'] = false;
        sendcopyDataNew[sendcopyDataNew.length - 2]['deleteDisabled'] = true;
        sendcopyDataNew[sendcopyDataNew.length - 1]['deleteDisabled'] = false;
        this.dispatchEvent(new CustomEvent('tableRiskchange', { bubbles: true, composed: true, detail: { data: sendcopyDataNew, tabletype: sendcopyDataNew[0]['tabletype'] } }));
*/
          this.dispatchEvent(new CustomEvent('openModalEdit', {
          detail: { rowId: row.Id, tabletype: row.tabletype, mitigantId : '', mitigantEndData: this.endDateProduct, mitigantName : 'New Mitigant' },
          bubbles: true,
          composed: true
        }));
        break;

      case 'edit':
        const ind = this.tableData.findIndex(dataRow => dataRow.Id === row.Id);
        this.dispatchEvent(new CustomEvent('openModalEdit', {
          detail: { rowId: row.Id, tabletype: row.tabletype, mitigantId : this.tableData[ind]["Id"], mitigantName : this.tableData[ind]["Name"], DMT_Currency__c: this.tableData[ind]["DMT_Currency__c"]},
          bubbles: true,
          composed: true
        }));
        console.log('Currency enviada al modal:', this.tableData[ind]["DMT_Currency__c"]);
        break;
      
      
    }
  }

  picklistChanged(event) {
    event.stopPropagation();
    let dataRecieved = event.detail.data;
    let updatedItem;
    // Comentado por error SONAR
    /*if (dataRecieved.fieldname === 'Mitigant_Type__c') {
      updatedItem = { Id: dataRecieved.context, Mitigant_Type__c: dataRecieved.value };
    } else {
      updatedItem = { Id: dataRecieved.context, Mitigant_Type__c: dataRecieved.value };
    }*/
    updatedItem = { Id: dataRecieved.context, Mitigant_Type__c: dataRecieved.value };
    //this.updateDraftValues(updatedItem);
    this.updateDataValues(updatedItem);

  }
  textInputChanged(event) {
    event.stopPropagation();
    let dataRecieved = event.detail.data;
    let updatedItem;
    updatedItem = { Id: dataRecieved.context};
    updatedItem[dataRecieved.fieldname]= dataRecieved.value;

    this.updateDataValues(updatedItem);
  }
  updateDataValues(updateItem) {
    let copyData = this.copiarLista(this.tableData);
    copyData.forEach(item => {
      if (item.Id.toString() === updateItem.Id.toString()) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });
    copyData[copyData.length - 1]['buttonDisabled'] = false;
    //write changes back to original data
    this.dispatchEvent(new CustomEvent('tableRiskchange', { bubbles: true, composed: true, detail: { data: copyData, tabletype: copyData[0]['tabletype'] } }));
  }
  isRowPopulated(row) {
    const hasRealId = this.isSalesforceId ? this.isSalesforceId(row?.Id) : (typeof row?.Id === 'string' && row.Id !== '0' && row.Id.length >= 15);
    const hasKeyFields = !!(row && (row.Mitigant_Type__c || row.Commercial_Percentage__c || row.Political_Percentage__c));
    return hasRealId || hasKeyFields;
  }
  updateButtonsState() {
    if (!this.tableData) return;
    const canEditOrAdd = (this._oppState === 'Draft' || this._oppState === 'Ready to close');
    const lastIndex = this.tableData.length - 1;
    this.tableData = this.tableData.map((r, index) => {
      const hasData = this.isRowPopulated(r);
      return {
        ...r,
        buttonDisabled: !(canEditOrAdd && index === lastIndex), // Solo la última fila habilita el "+"
        editDisabled: !canEditOrAdd,
        deleteDisabled: !(canEditOrAdd && hasData)
      };
    });
/*     this.tableData = this.tableData.map((row, index, arr) => ({
      ...row,
      editDisabled: this._oppState !== 'Draft',
      buttonDisabled: index === arr.length - 1
        ? this._oppState !== 'Draft'
        : true
    })); */
  }

  copiarLista(listaOriginal) {
    return listaOriginal.map(elemento => {
      if (typeof elemento === 'object' && elemento !== null) {
        return JSON.parse(JSON.stringify(elemento));
      } else {
        return elemento; // Devolver una copia directa para valores primitivos
      }
    });
  }

  handleChangeCell(event) {
    let dataRecieved = event.detail.draftValues;
    let updatedItem;
    updatedItem = { Id: dataRecieved[0].Id, Commercial_Percentage__c: dataRecieved[0].Commercial_Percentage__c };
    //this.updateDraftValues(updatedItem);
    this.updateDataValues(updatedItem);
  }

  handledefaultLimit() {
    var guidanceData;
    if (this.tableData !== undefined) {
      if (this.tableData[0]['tabletype'] === 'Derivatives') {
        guidanceData = [{
          "deleteDisabled": true,
          "Mitigant_Type__c": "2026",
          "Id": "0",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "Commercial_Percentage__c": this.totalamount,
          "tabletype": "Derivatives"
        }, {
          "deleteDisabled": true,
          "Mitigant_Type__c": "2026",
          "Id": "1",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "Commercial_Percentage__c": (this.totalamount * 3) / 4,
          "tabletype": "Derivatives"
        }, {
          "deleteDisabled": true,
          "Mitigant_Type__c": "2026",
          "Id": "2",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "Commercial_Percentage__c": this.totalamount / 2,
          "tabletype": "Derivatives"
        }, {
          "deleteDisabled": true,
          "Mitigant_Type__c": "2026",
          "Id": "3",
          "pickDisabled": true,
          "initRead": "true",
          "buttonDisabled": true,
          "line": this.tableData[0]['line'],
          "Commercial_Percentage__c": (this.totalamount * 2.5) / 10,
          "tabletype": "Derivatives"
        }];
      }
      this.dispatchEvent(new CustomEvent('tableRiskchange', { bubbles: true, composed: true, detail: { data: guidanceData, tabletype: guidanceData[0]['tabletype'] } }));
    }
  }

}