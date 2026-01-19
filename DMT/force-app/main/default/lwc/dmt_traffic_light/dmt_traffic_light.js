import { LightningElement,api } from 'lwc';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import { loadStyle } from "lightning/platformResourceLoader";

export default class Dmt_traffic_light extends LightningElement {

    @api status;
    @api simplelight;
    @api lightsize;
    @api tooltipmessage;

    get greenClass() {
        return this.isGreen ? 'status-indicator green on '  : 'status-indicator grey ';
    }

    get yellowClass() {
        return this.isYellow ? 'status-indicator yellow on ' : 'status-indicator grey ';
    }

    get redClass() {
        return this.isRed ? 'status-indicator red on ' : 'status-indicator grey ';
    }

    get isGreen() {
        return this.status ? this.status.toLowerCase() === 'green' : '';
    }

    get isYellow() {
        return this.status ? this.status.toLowerCase() === 'yellow':'';
    }

    get isRed() {
        return this.status ? this.status.toLowerCase()=== 'red':'';
    }

    get isLoad() {
        return this.status? this.status.toLowerCase() === 'load':'';
    }

    get isSimplelight() {
        return this.simplelight === 'true';
    }

    get correctClass() {
        return this.isLoad ? 'load' : this.isGreen  ? this.greenClass : this.isYellow ? this.yellowClass : this.isRed ? this.redClass : 'status-indicator grey ';
    }

    get customStyle() {
        return 'height: '+ this.lightsize + ';' + 'width: '+ this.lightsize + ';';
    }

    renderedCallback() {

        Promise.all([loadStyle(this, DMT_Styles)])
        .then(() => {
            console.log("Static Resource Loaded");
        })
        .catch(error => {
            console.log("error-", error);
        });
    }
}