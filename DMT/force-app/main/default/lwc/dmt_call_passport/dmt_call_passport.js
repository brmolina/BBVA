import { LightningElement, api } from 'lwc';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';

export default class Dmt_call_passport extends LightningElement {

    groupedData = [];
    message = '';
    showSpinnerPassport = false;

    @api
    fetchData(params) {
        this.showSpinnerPassport = true;
        this.message = 'Consulting customer groups.';
        this.groupedData = params.page === 1 ? [] : this.groupedData;
        fetchData(params).then( data => {
            if (data.success) {
                this.groupedData = this.groupedData.concat(data.data);
                if (data.pagination.totalPages > data.pagination.page) {
                    this.handleFetchMore(params);
                } else {
                    this.showSpinnerPassport = false;

                    let message = {'body': JSON.stringify(this.groupedData), 'result': true};
                    const fetchMoreEvent = new CustomEvent('callservice', {detail: JSON.stringify(message)});
                    this.dispatchEvent(fetchMoreEvent);

                }
            } else {
                console.error('ERROR loading more data: ' + data.errorMessage);
                this.showSpinnerPassport = false;

                let message = {'result': false};
                const fetchMoreEvent = new CustomEvent('callservice', {detail: JSON.stringify(message)});
                this.dispatchEvent(fetchMoreEvent);
            }
        }).catch((error) => {
            console.error('ERROR FETCHING DATA: ' + error);
            this.showSpinnerPassport = false;

            let message = {'result': false};
            const fetchMoreEvent = new CustomEvent('callservice', {detail: JSON.stringify(message)});
            this.dispatchEvent(fetchMoreEvent);
        });

    }

    handleFetchMore(data) {
        const params = {
            selectedTab: data.selectedTab,
            clientId: data.clientId,
            lCountries: data.countries,
            searchDate: data.searchDate,
            clientPositionsType: data.clientPositionsType,
            page: data.page + 1,
            pageSize: data.pageSize,
            customerId: data.customerId
        }
        this.fetchData(params);
    }
}