import { LightningElement,api } from 'lwc';
import DMT_Styles from "@salesforce/resourceUrl/DMT_Styles";
import { loadStyle } from "lightning/platformResourceLoader";

export default class Dmt_traffic_light extends LightningElement {

    @api status;
    @api simplelight;
    @api lightsize;
    @api tooltipmessage;
    // CIBGLOBALD-4726 - 'above': the popover opens upwards from the bottom of the positioned table cell at its natural
    // width, so multi-line reasons (Asset Allocation feature in dmt_feature_with_workflow and dmt_passport_child)
    // neither squeeze into the cell nor cover the light. Without it the original position is kept (cfSummaryTreasury_Flexcard_76_BBVA).
    @api tooltipposition;
    // CIBGLOBALD-4726 - faded feature row (isFaded in dmt_feature_with_workflow): only the lights are faded, the tooltip stays opaque.
    @api faded;

    get tooltipStyle() {
        return this.tooltipposition === 'above'
            ? 'position:absolute;bottom:calc(50% + 1.25rem);left:0;width:max-content;max-width:13rem;'
            : 'position:absolute;top:-35px;left:25px';
    }

    get lightsContainerStyle() {
        return this.faded ? 'opacity: 0.4;' : '';
    }

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