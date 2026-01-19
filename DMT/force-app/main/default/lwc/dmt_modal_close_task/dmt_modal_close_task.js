import { LightningElement } from 'lwc';

export default class dmt_modal_close_task extends LightningElement {
    value = 'op1';

    get options() {
        return [
            { label: 'op1', value: 'op1' },
            { label: 'op2', value: 'op2' },
            { label: 'op3', value: 'op3' }
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
    }
}