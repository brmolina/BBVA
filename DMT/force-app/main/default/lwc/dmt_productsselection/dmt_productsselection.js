import { LightningElement,api } from 'lwc';

export default class Dmt_productsselection extends LightningElement {

    //@api producttable;
    //@api selectedproducts = [];
    @api catalog;
    sendProducts = [];
    utilityfilter = "utility:chevrondown";
    producttablevalue;
    selectProduct = {label:"",value:""};
    family;
    subfamily;
    category;
    subcategory;
    globalproduct;
    readfamily = false;
    readsubfamily = false;
    readcategory = false;
    readsubcategory = false;
    readglobalproduct = false;
    familylabel = 'family';
    subfamilylabel = 'subfamily';
    categorylabel = 'category';
    subcategorylabel = 'subcategory';
    globalproductlabel = 'globalproduct';
    familyvalue = false;
    subfamilyvalue = false;
    categoryvalue = false;
    subcategoryvalue = false;
    globalproductvalue = false;
    searchfamily= {label:"",value:""};
    searchsubfamily= {label:"",value:""};
    searchcategory= {label:"",value:""};
    searchsubcategory= {label:"",value:""};
    searchglobalproduct= {label:"",value:""};
    

    @api
    get  producttable() {
      return this.producttablevalue;
    }
    set producttable(value) {

        this.family = value["family"];
        this.subfamily = value["subfamily"];
        this.category = value["category"];
        this.subcategory = value["subcategory"];
        this.globalproduct = value["globalproduct"];

        this.producttablevalue = value;
      }

      @api
    get  gensearch() {
      return this.gensearchvalue;
    }
    set gensearch(value) {
        console.log('en gensearch value',value);
        
        if(this.producttablevalue.family.find(x => x.g_global_product_family_id__c == value)){
            
            this.searchfamily = this.producttablevalue.family.find(x => x.g_global_product_family_id__c == value);
            this.searchglobalproduct = {label:"",value:""};
            this.searchsubcategory = {label:"",value:""};
            this.searchcategory = {label:"",value:""};
            this.searchsubfamily = {label:"",value:""};
            this.handleFilterLogic(this.searchfamily.Id, 'family');
        }
        if(this.producttablevalue.subfamily.find(x => x.g_global_product_subfamily_id__c == value)){
            
            this.searchsubfamily = this.producttablevalue.subfamily.find(x => x.g_global_product_subfamily_id__c == value);
            this.searchglobalproduct = {label:"",value:""};
            this.searchsubcategory = {label:"",value:""};
            this.searchcategory = {label:"",value:""};
            this.searchfamily = {label:"",value:""};
            this.handleFilterLogic(this.searchsubfamily.Id, 'subfamily');
        }
        if(this.producttablevalue.category.find(x => x.g_global_product_category_id__c == value)){
            
            this.searchcategory = this.producttablevalue.category.find(x => x.g_global_product_category_id__c == value);
            this.searchsubfamily = {label:"",value:""};
            this.searchglobalproduct = {label:"",value:""};
            this.searchsubcategory = {label:"",value:""};
            this.searchfamily = {label:"",value:""};
            this.handleFilterLogic(this.searchcategory.Id, 'category');
        }
        if(this.producttablevalue.subcategory.find(x => x.g_gbl_product_subcategory_id__c == value)){
            
            this.searchsubcategory = this.producttablevalue.subcategory.find(x => x.g_gbl_product_subcategory_id__c == value);
            this.searchfamily = {label:"",value:""};
            this.searchglobalproduct = {label:"",value:""};
            this.searchcategory = {label:"",value:""};
            this.searchsubfamily = {label:"",value:""};
            this.handleFilterLogic(this.searchsubcategory.Id, 'subcategory');
        }
        if(this.producttablevalue.globalproduct.find(x => x.g_global_product_id__c == value)){
            
            this.searchglobalproduct = this.producttablevalue.globalproduct.find(x => x.g_global_product_id__c == value);
            this.searchfamily = {label:"",value:""};
            this.searchsubcategory = {label:"",value:""};
            this.searchcategory = {label:"",value:""};
            this.searchsubfamily = {label:"",value:""};
            this.handleFilterLogic(this.searchglobalproduct.Id, 'globalproduct');
        }
        this.gensearchvalue = value;
      }


    handleFilterProduct(event){
        var selectId = event.detail.data.value;
        var context = event.detail.data.context;
        this.handleFilterLogic(selectId, context);
        // if(context == 'family'){
        //     var selectX = this.producttablevalue.family.find(x => x.Id == selectId);
        //     this.subfamily = this.producttablevalue.subfamily.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
        //     this.category = this.producttablevalue.category.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
        //     this.subcategory = this.producttablevalue.subcategory.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
        //     this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
        //     this.familyvalue = true;
        // }
        // else if(context == 'subfamily'){
        //     var selectX = this.producttablevalue.subfamily.find(x => x.Id == selectId);
        //     this.category = this.producttablevalue.category.filter(prod => prod.g_global_product_subfamily_id__c == selectX.g_global_product_subfamily_id__c);
        //     this.subcategory = this.producttablevalue.subcategory.filter(prod => prod.g_global_product_subfamily_id__c == selectX.g_global_product_subfamily_id__c);
        //     this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_global_product_subfamily_id__c == selectX.g_global_product_subfamily_id__c);
        //     this.readfamily = true;
        //     this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
        //     this.subfamilyvalue = true;
        // }
        // else if(context == 'category'){
        //     var selectX = this.producttablevalue.category.find(x => x.Id == selectId);
        //     this.subcategory = this.producttablevalue.subcategory.filter(prod => prod.g_global_product_category_id__c == selectX.g_global_product_category_id__c);
        //     this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_global_product_category_id__c == selectX.g_global_product_category_id__c);
        //     this.readfamily = true;
        //     this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
        //     this.readsubfamily = true;
        //     this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.add('noactionclass');
        //     this.categoryvalue = true;
        // }
        // else if(context == 'subcategory'){
        //     var selectX = this.producttablevalue.subcategory.find(x => x.Id == selectId);
        //     this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_gbl_product_subcategory_id__c == selectX.g_gbl_product_subcategory_id__c);
        //     this.readfamily = true;
        //     this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
        //     this.readsubfamily = true;
        //     this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.add('noactionclass');
        //     this.readcategory = true;
        //     this.template.querySelector(`[data-id="${this.categorylabel}"]`).classList.add('noactionclass');
        //     this.subcategoryvalue = true;
        // }
        // else if(context == 'globalproduct'){
        //     this.readfamily = true;
        //     this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
        //     this.readsubfamily = true;
        //     this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.add('noactionclass');
        //     this.readcategory = true;
        //     this.template.querySelector(`[data-id="${this.categorylabel}"]`).classList.add('noactionclass');
        //     this.readsubcategory = true;
        //     this.template.querySelector(`[data-id="${this.subcategorylabel}"]`).classList.add('noactionclass');
        //     this.globalproductvalue = true;
        // }
        
        // var evt = new CustomEvent('productstosend', {
        //     bubbles: true,
        //     composed: true,
        //     cancelable: true,
        //     detail: {catalog: this.catalog, data: selectX}
        // });
        // this.dispatchEvent(evt);
    }
    handleRemoveSearch(event){console.log('remove',event.detail)
        var context = event.detail;
        if(context == 'family'){
            this.subfamily = this.producttablevalue.subfamily;
            this.category = this.producttablevalue.category;
            this.subcategory = this.producttablevalue.subcategory;
            this.globalproduct = this.producttablevalue.globalproduct;
            this.familyvalue = false;
        }
        else if(context ==  'subfamily'){
            this.category = this.producttablevalue.category;
            this.subcategory = this.producttablevalue.subcategory;
            this.globalproduct = this.producttablevalue.globalproduct;
            this.readfamily = false;
            this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.remove('noactionclass');
            this.subfamilyvalue = false;
        }
        else if(context == 'category'){
            this.subcategory = this.producttablevalue.subcategory;
            this.globalproduct = this.producttablevalue.globalproduct;
            this.readsubfamily = false;
            this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.remove('noactionclass');
            if(!this.subfamilyvalue){
                this.readfamily = false;
                this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.remove('noactionclass');
            }
            this.categoryvalue = false;
        }
        else if(context == 'subcategory'){
            this.globalproduct = this.producttablevalue.globalproduct;
            this.readcategory = false;
            this.template.querySelector(`[data-id="${this.categorylabel}"]`).classList.remove('noactionclass');
            if(!this.categoryvalue){
                this.readsubfamily = false;
                this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.remove('noactionclass');
                if(!this.subfamilyvalue){
                    this.readfamily = false;
                    this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.remove('noactionclass');
                }
            }
            this.subcategoryvalue = false;
        }
        else if(context == 'globalproduct'){
            this.readsubcategory = false;
            this.template.querySelector(`[data-id="${this.subcategorylabel}"]`).classList.remove('noactionclass');
            if(!this.subcategoryvalue){
                this.readcategory = false;
                this.template.querySelector(`[data-id="${this.categorylabel}"]`).classList.remove('noactionclass');
                if(!this.categoryvalue){
                    this.readsubfamily = false;
                    this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.remove('noactionclass');
                    if(!this.subfamilyvalue){
                        this.readfamily = false;
                        this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.remove('noactionclass');
                    }
                }
            }
            this.globalproductvalue = false;
        }
    }

    handleFilterLogic(selectId, context){console.log('enfamilycontext',context)
        if(context == 'family'){console.log('enfamily',selectId)
            var selectX = this.producttablevalue.family.find(x => x.Id == selectId);
            this.subfamily = this.producttablevalue.subfamily.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
            this.category = this.producttablevalue.category.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
            this.subcategory = this.producttablevalue.subcategory.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
            this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_global_product_family_id__c == selectX.g_global_product_family_id__c);
            this.familyvalue = true;
        }
        else if(context == 'subfamily'){
            var selectX = this.producttablevalue.subfamily.find(x => x.Id == selectId);
            this.category = this.producttablevalue.category.filter(prod => prod.g_global_product_subfamily_id__c == selectX.g_global_product_subfamily_id__c);
            this.subcategory = this.producttablevalue.subcategory.filter(prod => prod.g_global_product_subfamily_id__c == selectX.g_global_product_subfamily_id__c);
            this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_global_product_subfamily_id__c == selectX.g_global_product_subfamily_id__c);
            this.readfamily = true;
            this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
            this.subfamilyvalue = true;
        }
        else if(context == 'category'){
            var selectX = this.producttablevalue.category.find(x => x.Id == selectId);
            this.subcategory = this.producttablevalue.subcategory.filter(prod => prod.g_global_product_category_id__c == selectX.g_global_product_category_id__c);
            this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_global_product_category_id__c == selectX.g_global_product_category_id__c);
            this.readfamily = true;
            this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
            this.readsubfamily = true;
            this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.add('noactionclass');
            this.categoryvalue = true;
        }
        else if(context == 'subcategory'){
            var selectX = this.producttablevalue.subcategory.find(x => x.Id == selectId);
            this.globalproduct = this.producttablevalue.globalproduct.filter(prod => prod.g_gbl_product_subcategory_id__c == selectX.g_gbl_product_subcategory_id__c);
            this.readfamily = true;
            this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
            this.readsubfamily = true;
            this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.add('noactionclass');
            this.readcategory = true;
            this.template.querySelector(`[data-id="${this.categorylabel}"]`).classList.add('noactionclass');
            this.subcategoryvalue = true;
        }
        else if(context == 'globalproduct'){
            var selectX = this.producttablevalue.globalproduct.find(x => x.Id == selectId);
            this.readfamily = true;
            this.template.querySelector(`[data-id="${this.familylabel}"]`).classList.add('noactionclass');
            this.readsubfamily = true;
            this.template.querySelector(`[data-id="${this.subfamilylabel}"]`).classList.add('noactionclass');
            this.readcategory = true;
            this.template.querySelector(`[data-id="${this.categorylabel}"]`).classList.add('noactionclass');
            this.readsubcategory = true;
            this.template.querySelector(`[data-id="${this.subcategorylabel}"]`).classList.add('noactionclass');
            this.globalproductvalue = true;
        }
        
        var evt = new CustomEvent('productstosend', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {catalog: this.catalog, data: selectX}
        });
        this.dispatchEvent(evt);
    }
}