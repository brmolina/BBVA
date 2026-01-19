import { LightningElement, track, api, wire} from 'lwc';
import getProducts from '@salesforce/apex/KPI_searchController.getKPICatalog'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class Kpi_productLookuplwc extends LightningElement {

    @track
    recordsList;

    @api
    selectedValue = "";
    error;
    @api
    recordselected = false;

    recordsRetrieved = [];
    @api
    iconname;

    @api
    hasFocus;

    @api
    productSelected = "";

    @wire(getProducts,{
            catalogId : 'PRODUCT' ,
            opSelected : "$productSelected"
        }) products ( { error, data } ) {
            try{
                if (data) {
                    data.options.forEach(option => {
                        this.recordsRetrieved.push({Name : option.name , Id: option.id});
                    });
    
                }else if(error){
                    console.error(error);
                }
            }catch(error){
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            }
        };
    
    //Method to query data after typing search term
    onKeyChange(event) {
        this.selectedValue = event.target.value;
        this.recordsList = this.recordsRetrieved.filter(record => record.Name.toLowerCase().includes(this.selectedValue.toLowerCase()));
    }

    //Method to clear search list and show selected value.
    clearSelection() {
        this.recordselected = false;
        this.selectedValue = "";
        this.recordsList = undefined;
        const selectedEvent2 = new CustomEvent('clearSelection', {
            detail:{
                Origin: 'product'
            }
        });
        this.dispatchEvent(selectedEvent2)
    }

    //Method to pass selected record to parent component.
    setSelectedValue(event) {
        this.selectedValue = event.target.dataset.itemname;
        this.recordselected = true;
        this.recordsList = undefined;
        event.preventDefault();
        const selectedEvent = new CustomEvent('selected', {
            detail: {
                Name : this.selectedValue,
                Id : event.target.dataset.itemid,
                ObjectName : 'Product'
            }
        });
        this.dispatchEvent(selectedEvent);
    }
    focusIn(){
        if(this.selectedValue){
            getRecordsByName({objectName : this.objectname, fieldName : this.fieldname, searchFor : this.selectedValue})
            .then(result => {
                this.recordsList = result;
            })
            .catch(error => {
                //exception handling
                console.error(error);
                this.error = error;
            })
        }
    }
    focusOut(){
        if(!this.recordselected){
            setTimeout(() => {
                this.recordsList = undefined;
              }, 100);
            
        }
    }
}