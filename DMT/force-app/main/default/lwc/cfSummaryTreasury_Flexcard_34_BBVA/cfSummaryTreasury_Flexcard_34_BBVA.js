import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfSummaryTreasury_Flexcard_34_BBVA extends FlexCardMixin(LightningElement){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              @track _sessionApiVars = {};
              @track Label={dmt_cl_NameLine:"Name",
        dmt_cl_Entific_Label:"Entific",
        dmt_cl_Start_Date:"Start Date",
        dmt_cl_End_Date:"End Date",
        dmt_cl_Line_Term:"Line Term",
        dmt_cl_Sanction_Term:"Sanction Term",
        dmt_cl_Amount:"Amount",
        dmt_cl_Type_Risk:"Type of risk",
        dmt_commitmentline:"dmt_commitmentline",
        dmt_cl_Currency:"Currency"
        };
              pubsubEvent = [];
              customEvent = [];
               
        firstRender0 = true;
        @wire(getRecord , {recordId: "$recordId" , fields:"DMT_Line__c.Id",optionalFields: $cmp.getWireOptionalFields(data.events[0])})
          wiredRecord0({ error, data }){
            if (this.objectApiName === 'DMT_Line__c'){
              if(data && this.firstRender0){
                this.firstRender0 = false;
                return;
              }else{
                this.recordChangeEventHandler(error,data,0)
              }
            }
          }
        
              connectedCallback() {
                super.connectedCallback();
                this.setThemeClass(data);
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
                          this.fetchUpdatedCustomLabels();
                      
                this.setDefinition(data);
 this.registerEvents();
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
              }

              unregisterEvents(){
                
              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }