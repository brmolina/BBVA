import { LightningElement, track, api } from 'lwc';
import getRecordsByName from '@salesforce/apex/KPI_searchController.getRecordsByName'

export default class LookupLwc extends LightningElement {
    @api
    filterName;

    @api
    recordsList;
    @api
    recordsListFiltered;

    @api
    selectedValue="";
    error;

    @api
    recordselected = false;

    @api
    disableClient =false;

    @api
    iconname;

    @track hasFocus = false;
    //Method to query data after typing search term
    onKeyChange(event) {
        this.selectedValue = event.target.value;
        if(Array.isArray(this.recordsList)){
            let tempArray = JSON.parse(JSON.stringify(this.recordsList));
            this.recordsListFiltered = tempArray.filter((elementList) => elementList.Name.toUpperCase().includes(this.selectedValue.toUpperCase())).sort();
        }

        // getRecordsByName({objectName : this.objectname, fieldName : this.fieldname, searchFor : this.selectedValue})
        //     .then(result => {
        //         this.recordsList = result;
        //     })
        //     .catch(error => {
        //         //exception handling
        //         console.error(error);
        //         this.error = error;
        //     })

    }

    //Method to clear search list and show selected value.
    @api
    clearSelection() {
        this.recordselected = false;
        this.selectedValue = "";
        this.hasFocus = false;
        const selectedEvent2 = new CustomEvent('clearSelection', {
            detail:{
                Origin: this.filterName
            }
        });
        this.dispatchEvent(selectedEvent2);
    }

    //Method to pass selected record to parent component.
    setSelectedValue(event) {
        this.selectedValue = event.target.dataset.itemname;
        this.recordselected = true;
        event.preventDefault();
        const selectedEvent = new CustomEvent('selected', {
            detail: {
                Name : this.selectedValue,
                Id : event.target.dataset.itemid,
                Origin: this.filterName
            }
        });
        this.dispatchEvent(selectedEvent);
    }
    focusIn(){
        this.hasFocus = true;
    } 
    focusOut(){
        if(!this.recordselected){
            setTimeout(() => {
                this.hasFocus = false;
              }, 180);
            
        }  
    }
}