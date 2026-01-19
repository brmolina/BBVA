import { LightningElement, api, track } from 'lwc';
import LightningModal from 'lightning/modal';
export default class Dmt_case_comment_modal_v2 extends LightningModal {

        @api approver
        @track comment

        handleClose() {
                this.close();
        }

        handleComment(event){
                this.comment = event.target.value;
        }


        handleRequest(){
                this.close({ comment: this.comment});
        }
}