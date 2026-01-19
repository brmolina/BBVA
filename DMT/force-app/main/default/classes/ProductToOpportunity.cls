/**
* Clase para añadir productos a oportunidades
*
* @author Jorge Levenfeld
*/
public with sharing class ProductToOpportunity {

    private Product2 product2;
    private PricebookEntry pricebookEntry;
    private OpportunityLineItem opportunityLineItem;

    private static Id stdPriceBook {
        get {
            if ( stdPriceBook == null ) {
                List<Pricebook2> pbList = [SELECT id, name FROM Pricebook2 WHERE isStandard = true LIMIT 1];
                stdPriceBook = pbList.isEmpty() ? Test.getStandardPricebookId() : pbList[0].Id;
            }
            return stdPriceBook;
        }
        set;
    }

    private static List<PricebookEntry> pricebookEntriesToInsert = new List<PricebookEntry>();
    private static List<OpportunityLineItem> opportunityLineItemsToInsert  = new List<OpportunityLineItem>();
    private static List<ProductToOpportunity> allInstances  = new List<ProductToOpportunity>();

    // Conjuntos para filtrar la query a Pricebookentries
    private static Set<String> productNames  = new Set<String>();
    private static Set<String> familyNames = new Set<String>();
    private static Set<String> currencyCodes = new Set<String>();

    /**
     * Constructor para cuando se usa el standardPriceBook
     *
     * @param productName : Nombre del producto
     * @param familyName : Nombre de la familia
     * @param opp : Oportunidad a la que se asociará.
     */
    public ProductToOpportunity( String productName, String familyName, Opportunity opp ) {
        this ( productName, familyName, opp, stdPriceBook );
    }

    /**
     * Constructor principal
     *
     * @param productName : Nombre del producto
     * @param familyName : Nombre de la familia
     * @param opp : Oportunidad a la que se asociará.
     * @param pricebook2Id : Id del priceBook al que se asociarán los productos
     */
    public ProductToOpportunity( String productName, String familyName, Opportunity opp, Id pricebook2Id ) {

        this.product2 = new Product2(
                Name = productName.trim(),
                Family = familyName.trim()
        );

        this.pricebookEntry = new PricebookEntry(
                Pricebook2Id = pricebook2Id,
                CurrencyIsoCode = opp.CurrencyIsoCode
        );

        this.opportunityLineItem = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 1,
                TotalPrice = 0.0
        );

        productNames.add(productName.trim());
        familyNames.add(familyName.trim());
        currencyCodes.add(opp.CurrencyIsoCode.trim());

        pricebookEntriesToInsert.add( this.pricebookEntry );
        opportunityLineItemsToInsert.add( this.opportunityLineItem );
        allInstances.add(this);

    }

    /**
     * Establece el id del producto
     *
     * @param product2Id
     */
    private void setProductId ( Id product2Id ) {
        product2.Id = product2Id;
        pricebookEntry.Product2Id = product2Id;
    }

    /**
     * Establece el id del priceBookEntry
     *
     * @param priceBookEntryId
     */
    private void setPriceBookEntryId( Id priceBookEntryId ) {
        pricebookEntry.Id = priceBookEntryId;
        opportunityLineItem.PricebookEntryId = priceBookEntryId;
    }

    /**
     * Trae la key relacionada con el producto a insertar, formada por el nombre y la moneda
     *
     * @return
     */
    private String getKey() {
//        return product2.Name + '||' + product2.Family + '||' + pricebookEntry.CurrencyIsoCode;
        return product2.Name + '||' + pricebookEntry.CurrencyIsoCode;
    }

    /**
     * Inserta todos los productos registrados
     */
    public static void insertAll() {

        if ( !allInstances.isEmpty() ) {

            // Obtener los registros de PricebookEntry pertinentes
            Map<String, PricebookEntry> pricebookEntriesByProductName = new Map<String, PricebookEntry> ();
            for ( PricebookEntry pbe: [SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.CurrencyIsoCode
                                        FROM PricebookEntry
                                        WHERE Product2.Name IN :productNames
//                                        AND Product2.Family IN :familyNames
                                        AND CurrencyIsoCode IN :currencyCodes]) {

//                map_data.put(pbe.Product2.Name + '||' + pbe.Product2.Family + '||' + pbe.Product2.CurrencyIsoCode, pbe);
                pricebookEntriesByProductName.put(pbe.Product2.Name + '||'  + pbe.Product2.CurrencyIsoCode, pbe);

            }

            if ( !pricebookEntriesByProductName.isEmpty() ) {

                // Rellenar los datos de los productos a asociar
                PricebookEntry pbe;
                for ( ProductToOpportunity pto: allInstances ) {
                    pbe = pricebookEntriesByProductName.get ( pto.getKey() );
                    if ( pbe != null ) {
                        pto.setProductId( pbe.Product2Id );
                        pto.setPriceBookEntryId( pbe.Id );
                    }
                }

                insert opportunityLineItemsToInsert;
                clear();

            }

        }

    }

    /**
     * Vacía las listas
     */
    private static void clear() {
        // Liberar memoria
        allInstances.clear();
        pricebookEntriesToInsert.clear();
        opportunityLineItemsToInsert.clear();
        productNames.clear();
        familyNames.clear();
        currencyCodes.clear();
    }

}