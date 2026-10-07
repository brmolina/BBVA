import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfDMT_ProfitabilityTest extends FlexCardMixin(LightningElement){
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
              
              @track Label={DMT_ImageDescriptionText:"Image description",
        dmt_cl_Scenarios_Text:"SCENARIOS",
        dmt_cl_ButtonCurrentOpp_Text:"Current opportunities",
        DMT_BasicOpportunitiesText:"Basic Opportunities",
        dmt_cl_SelectOpportunity_Text:"Select Opportunity Type:",
        dmt_cl_NoOppsMessage:"There aren't opportunities for this client.",
        dmt_cl_ProfObsoletePassportMessage_Text:"Opportunity template values have been modified. Please recalculate passport for:",
        dmt_cl_SelectOpportunityProfitability_Text:"Select an opportunity",
        dmt_cl_SelectproductProfitability_Text:"Select a product"
        };
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                
                super.connectedCallback();
                this.setThemeClass(data);
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
                this.setDefinition(data);
 this.registerEvents();
                this.setAttribute(
                  "class", (this.getAttribute("class") ? this.getAttribute("class") : "") +
                  " card-0koKE000000L9usYAC"
                );
                this.loadCustomStylesheetAttachement("00PKE000002N0LL2A0");
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
            this.customEventName0 = interpolateWithRegex(`dataToParent`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[0] = this.handleEventAction.bind(this, data.events[0],0);

            this.template.addEventListener(this.customEventName0,this.customEvent[0]);

          
              }

              unregisterEvents(){
                
            this.template.removeEventListener(this.customEventName0,this.customEvent[0]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }