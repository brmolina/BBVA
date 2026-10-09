public with sharing class DMT_Product_Helper {


    public void completeFields(List<Product2> newProducts)
    {
        List<Id> taxoIds = new List<Id>();
        for(Product2 pt : newProducts) {
            taxoIds.add(pt.DMT_Taxonomy_Value__c);
        }
        Map<Id,DMT_Taxonomy_Values__c> taxoVal = DMT_Passport_Selector.getTaxonomyByIds(taxoIds);
        for(Product2 p : newProducts)
        {
            if(!String.IsBlank(p.DMT_CatalogTaxonomy__c))
            {
                p.Family = 'DMT Lines';
            }
            if(p.ProductCode != null && p.ProductCode.isNumeric() && p.Family == 'DMT Lines')
            {

                Boolean isSubfamily = p.ProductCode.length() < 10 ? false : Integer.valueOf(p.ProductCode.substring(2, 10)) != 0;
                Boolean isCategory = p.ProductCode.length() < 10 ? false : Integer.valueOf(p.ProductCode.substring(4, 10)) != 0;
                Boolean isSubcategory = p.ProductCode.length() < 10 ? false : Integer.valueOf(p.ProductCode.substring(6, 10)) != 0;
                Boolean isGlobalProduct = p.ProductCode.length() < 10 ? false : Integer.valueOf(p.ProductCode.substring(8, 10)) != 0;

                p.DMT_Global_Product_Id__c = isGlobalProduct ? p.ProductCode : '';
                p.DMT_Product_family__c = p.ProductCode.substring(0,2) + '00000000';
                p.DMT_Product_Subfamily__c = isSubfamily ? p.ProductCode.substring(0,4) + '000000' : '';
                p.DMT_Product_category__c = isCategory ? p.ProductCode.substring(0,6) + '0000' : '';
                p.DMT_Product_Subcategory__c = isSubcategory ? p.ProductCode.substring(0,8) + '00' : '';

            }
            if(!taxoVal.isEmpty() && taxoVal.get(p.DMT_Taxonomy_Value__c) != null && taxoVal.get(p.DMT_Taxonomy_Value__c).gf_catalog_atrb_val3_name__c == 'XX' && taxoVal.get(p.DMT_Taxonomy_Value__c).gf_catalog_atrb_val4_name__c == 'Product') {
                for(Product2 parent : newProducts) {
                    if(taxoVal.get(parent.DMT_Taxonomy_Value__c) != null && taxoVal.get(parent.DMT_Taxonomy_Value__c).gf_catalog_atrb_val3_name__c != 'XX' && taxoVal.get(parent.DMT_Taxonomy_Value__c).gf_catalog_atrb_val4_name__c == 'Product' && parent.ProductCode.contains(p.ProductCode) && parent.DMT_CatalogTaxonomy__c == p.DMT_CatalogTaxonomy__c && parent.IsActive) {
                        p.Parent_Product__c = parent.Id;
                        break;
                    }
                }
            }
            if(!taxoVal.isEmpty() && taxoVal.get(p.DMT_Taxonomy_Value__c) != null && taxoVal.get(p.DMT_Taxonomy_Value__c).gf_catalog_atrb_val5_name__c != null) {
                String templateProd = taxoVal.get(p.DMT_Taxonomy_Value__c).gf_catalog_atrb_val5_name__c.replaceAll(', ',';');
                p.DMT_Product_Template__c = templateProd;
            }

        }

    }

public void createPriceBookEntry(List<Product2> newProducts) {
    if (newProducts == null || newProducts.isEmpty()) {
        return;
    }

    Pricebook2 pbStandard;

    if (Test.isRunningTest()) {
        pbStandard = DMT_Test_DataFactory.generatePricebook2();
    } else {
        pbStandard = DMT_Opportunity_Selector.getPriceBook2();
    }

    
    Set<String> validTemplates = new Set<String>();
    if (Test.isRunningTest()) {
        //  test,  mock estático 
        validTemplates.addAll(new List<String>{ 'TO','OL' });
    } else {
        List <Opportunity_Products__mdt> oppProductListmdt = DMT_Opportunity_Selector.getOppProductsMdt();
        for (Opportunity_Products__mdt meta : oppProductListmdt) {
            validTemplates.add(meta.Product_Template__c.trim());
        }
    }



    List<PricebookEntry> listPbeToInsert = new List<PricebookEntry>();

    for (Product2 p : newProducts) {

        Boolean hasValidTemplate = false;

        if (p.DMT_Product_Template__c != null) {
            List<String> selectedTemplates = p.DMT_Product_Template__c.split(';');
            for (String value : selectedTemplates) {
                if (validTemplates.contains(value.trim())) {
                    hasValidTemplate = true;
                    break;
                }
            }
        }

        if (hasValidTemplate) {
            listPbeToInsert.add(new PricebookEntry(
                Pricebook2Id    = pbStandard.Id,
                Product2Id      = p.Id,
                IsActive        = true,
                CurrencyIsoCode = p.CurrencyIsoCode,
                UnitPrice       = 1
            ));
        }
    }

    if (!listPbeToInsert.isEmpty()) {
        try {
            insert listPbeToInsert;
        } catch (DmlException e) {
            System.debug('Error al insertar PricebookEntries: ' + e.getMessage());
        }
    }
}

    public List<Product2> filterProductsWithoutPbe(List<Product2> products) {
        if (products== null || products.isEmpty()) {
            return new List<Product2>();
        }

        Set<Id> productIds = new Map<Id, Product2>(products).keySet();

        List<PricebookEntry> existingPbes = DMT_Opportunity_Selector.getPbeByProductIds(productIds);

        Set<Id> productsWithPbe = new Set<Id>();

        for (PricebookEntry pbe : existingPbes) {
            productsWithPbe.add(pbe.Product2Id);
        }

        List<Product2> productsWithoutPbe = new List<Product2>();
        for (Product2 product : products) {
            if (!productsWithPbe.contains(product.Id)) {
                productsWithoutPbe.add(product);
            }
        }
        return productsWithoutPbe;


    }




}