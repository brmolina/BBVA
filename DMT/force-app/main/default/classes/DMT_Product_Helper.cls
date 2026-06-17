public with sharing class DMT_Product_Helper {

    private static final String PRODUCT_TAXONOMY_TYPE = 'Product';
    private static final String CHILD_TAXONOMY_FLAG = 'XX';


    public void completeFields(List<Product2> newProducts)
    {
        List<Id> taxoIds = new List<Id>();
        for(Product2 pt : newProducts) {
            taxoIds.add(pt.DMT_Taxonomy_Value__c);
        }
        Map<Id,DMT_Taxonomy_Values__c> taxoVal = DMT_Passport_Selector.getTaxonomyByIds(taxoIds);
        List<Product2> existingParentCandidates = getExistingParentCandidates(newProducts);
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
            if(p.ProductCode != null && p.ProductCode.isNumeric()) {
                Product2 parentInBatch = findParentInBatch(p, newProducts, taxoVal);
                if (parentInBatch != null) {
                    p.Parent_Product__c = parentInBatch.Id;
                } else {
                    Product2 parentInExisting = findParentInExisting(p, existingParentCandidates, taxoVal);
                    if (parentInExisting != null) {
                        p.Parent_Product__c = parentInExisting.Id;
                    }
                }
            }
            if(!taxoVal.isEmpty() && taxoVal.get(p.DMT_Taxonomy_Value__c) != null && taxoVal.get(p.DMT_Taxonomy_Value__c).gf_catalog_atrb_val5_name__c != null) {
                String templateProd = taxoVal.get(p.DMT_Taxonomy_Value__c).gf_catalog_atrb_val5_name__c.replaceAll(', ',';');
                p.DMT_Product_Template__c = templateProd;
            }

        }
    }

    private static Boolean isChildProductTaxonomy(Product2 product, Map<Id,DMT_Taxonomy_Values__c> taxoVal) {
        return !taxoVal.isEmpty()
            && taxoVal.get(product.DMT_Taxonomy_Value__c) != null
            && taxoVal.get(product.DMT_Taxonomy_Value__c).gf_catalog_atrb_val3_name__c == CHILD_TAXONOMY_FLAG
            && taxoVal.get(product.DMT_Taxonomy_Value__c).gf_catalog_atrb_val4_name__c == PRODUCT_TAXONOMY_TYPE;
    }

    private static Boolean isParentProductTaxonomy(DMT_Taxonomy_Values__c taxonomyValue) {
        return taxonomyValue != null
            && taxonomyValue.gf_catalog_atrb_val3_name__c != CHILD_TAXONOMY_FLAG
            && taxonomyValue.gf_catalog_atrb_val4_name__c == PRODUCT_TAXONOMY_TYPE;
    }

    private static Boolean parentMatchesChild(Product2 child, Product2 parent) {
        return parent != null
            && !String.isBlank(parent.ProductCode)
            && !String.isBlank(child.ProductCode)
            && parent.ProductCode.startsWith(child.ProductCode)
            && parent.ProductCode.length() > child.ProductCode.length()
            && (child.Id == null || parent.Id != child.Id);
    }

    private static Product2 findParentInBatch(Product2 child, List<Product2> newProducts, Map<Id,DMT_Taxonomy_Values__c> taxoVal) {
        for(Product2 parent : newProducts) {
            if(isParentProductTaxonomy(taxoVal.get(parent.DMT_Taxonomy_Value__c)) && parentMatchesChild(child, parent)) {
                return parent;
            }
        }
        return null;
    }

    private static Product2 findParentInExisting(Product2 child, List<Product2> existingParents) {
        return findParentInExisting(child, existingParents, new Map<Id,DMT_Taxonomy_Values__c>());
    }

    private static Product2 findParentInExisting(Product2 child, List<Product2> existingParents, Map<Id,DMT_Taxonomy_Values__c> taxoVal) {
        for(Product2 parent : existingParents) {
            DMT_Taxonomy_Values__c parentTaxonomy = taxoVal != null ? taxoVal.get(parent.DMT_Taxonomy_Value__c) : null;
            if(isParentProductTaxonomy(parentTaxonomy) && parentMatchesChild(child, parent)) {
                return parent;
            }
        }
        return null;
    }

    private static List<Product2> getExistingParentCandidates(List<Product2> newProducts) {
        return [
            SELECT Id, ProductCode, DMT_Taxonomy_Value__c, DMT_CatalogTaxonomy__c
            FROM Product2
            WHERE ProductCode != null
            AND DMT_Taxonomy_Value__c != null
            ORDER BY CreatedDate ASC
        ];
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