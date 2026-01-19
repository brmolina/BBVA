import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfProductSanctionFieldSection extends FlexCardMixin(LightningElement){
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
              @track Label={dmt_cl_Amount:"Amount",
        dmt_cl_Currency:"Currency",
        dmt_cl_AvailableCurrencies_text:"Available Currencies for disposals",
        dmt_cl_RequiredMitigants_Text:"Required mitigants",
        dmt_cl_TypologyFinancial_Text:"Typology of financial program risks",
        dmt_cl_MultipoperationIndicator_Text:"Multioperation indicator",
        dmt_cl_RquiredNotary_Text:"Required Notary Public/Solicitor formalization indicator",
        dmt_cl_GuaranteeAdministrationIndicator_Text:"Guarantee in favor of a public administration indicator",
        dmt_cl_Globalproduct_Text:"Global Product",
        dmt_cl_Subcategory_Text:"Subcategory",
        dmt_cl_Category_Text:"Category",
        dmt_cl_Subfamily_Text:"Subfamily",
        dmt_cl_Family_Text:"Family",
        dmt_cl_minimumInternalRating_Text:"Minimum Internal Rating Limitation",
        dmt_cl_BulletIndicator_Text:"Bullet indicator Limitation",
        dmt_cl_Initialterm_Text:"Initial Term",
        dmt_cl_MaximumTerm_Text:"Maximum Term",
        dmt_cl_AssetAllocationSector_Text:"Asset Allocation Sector Limitation",
        dmt_cl_AssetAllocationSubSector_Text:"Asset Allocation Subsector Limitation",
        dmt_cl_MaxNumberMonths_Text:"Max number of months of grace period",
        dmt_cl_MinLoanValue_Text:"Min Loan to value (%)",
        dmt_cl_MinimumPercentageRAROEC_Text:"Minimum percentage RAROEC with financing",
        dmt_cl_MinimumPercentageRAROECWithout_Text:"Minimum percentage RAROEC without financing",
        dmt_cl_MinimumPercentageRORCWithout_Text:"Minimum percentage RORC without financing",
        dmt_cl_Comments:"Comments"
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
                  " card-0koKG000000L50zYAC"
                );
                this.loadCustomStylesheetAttachement("00PKG000003T0qM2AS");
                
                
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