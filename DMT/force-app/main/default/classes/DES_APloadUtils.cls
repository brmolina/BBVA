/**
* @author       Global Desktop
* @date         2019/11/14
* @description  Clase estática con mét0d0s para ser invocados en en los triggers Handler cuando se produce la carga de AP
* y se deben inicializar los correspondientes BP Items
* @Revision
* 
* Version   Date            Author          Summary of changes
*
*/
public without sharing class DES_APloadUtils {

    /*T0d0s los países de esta lista se traducirán a 'USA'*/
    private final static List<String> USA_COUNTRIES = new list<String>{'Compass','NY'};
    
    /*Declaración de variable*/
    private static Map<String,String> mapMatchProductsByGD {get; set;}

    /*Declaración de variable*/
    private static Map<String,String> mapMatchProductsByEngloba {get; set;}

    /*Declaración de variable*/
    private static Map<String,String> mapFamilyProductsEngloba {get; set;}

    /*Declaración de variable*/
    private static Set<String> listCrossSellProducts {get; set;}

    /*Declaración de variable*/
    private static Map<String,String> mapCrossBorderCountryRegion {get; set;} //map:(country ENGLISH LABEL, region)

    /*Declaración de variable*/
    private static List<String> listSegmentsCountryManagement {get; set;}

    /*Declaración de variable*/
    private static Map<String,String> mapCountryBookingToLabel {get; set;} //map:(country SPANISH LABEL, country ENGLISH Label)

    /*Declaración de variable*/
    private static Map<String,String> mapCountryCodeToLabel {get; set;} //map:(country ISO-CODE-2, country ENGLISH Label)

    /*
    * @author       Global Desktop
    * @Description  Método privado con el Constructor
    */
    private DES_APloadUtils() {
    }

        

    // Codigo que se ejecuta la primera vez que se instancia la clase
    static {

        //variables needed to calculate Cross Sell
        if (mapMatchProductsByEngloba == null || mapFamilyProductsEngloba == null || mapMatchProductsByGD == null || listCrossSellProducts == null) {
            mapMatchProductsByEngloba = new Map<String,String>();
            mapFamilyProductsEngloba = new Map<String,String>();
            mapMatchProductsByGD = new Map<String,String>();
            listCrossSellProducts = new Set<String>();

            final list<AP_Product_List__mdt> listApCSP = [SELECT id, DeveloperName, Label, Engloba_Product_Name__c, Engloba_Product_Family__c, Is_Cross_Sell__c FROM AP_Product_List__mdt];
            for (AP_Product_List__mdt apcsp : listApCSP) {
                mapFamilyProductsEngloba.put(apcsp.Engloba_Product_Name__c,apcsp.Engloba_Product_Family__c);

                if (mapMatchProductsByGD.containsKey(apcsp.Label)) { // = 'N.A.'
                    mapMatchProductsByGD.put(apcsp.Label,mapMatchProductsByGD.get(apcsp.Label) + ',' + apcsp.Engloba_Product_Name__c);
                } else {
                    mapMatchProductsByGD.put(apcsp.Label,apcsp.Engloba_Product_Name__c);
                }


                if (mapMatchProductsByEngloba.containsKey(apcsp.Engloba_Product_Name__c)) {
                    mapMatchProductsByEngloba.put(apcsp.Engloba_Product_Name__c,mapMatchProductsByEngloba.get(apcsp.Engloba_Product_Name__c) + ',' + apcsp.Label);
                } else {
                    mapMatchProductsByEngloba.put(apcsp.Engloba_Product_Name__c,apcsp.Label);
                }

                if (apcsp.Is_Cross_Sell__c) {
                    listCrossSellProducts.add(apcsp.Engloba_Product_Name__c);
                }
            }
        }


        //variables needed to calculate Cross Border
        if (mapCrossBorderCountryRegion == null || listSegmentsCountryManagement == null) {
            mapCrossBorderCountryRegion = new Map<String,String>();
            final list<AP_Cross_Border_Countries__mdt> listApCBC = [SELECT id, DeveloperName, Label, DES_XB_Region_AP__c FROM AP_Cross_Border_Countries__mdt];
            for (AP_Cross_Border_Countries__mdt apCBC : listApCBC) {
                mapCrossBorderCountryRegion.put(apCBC.Label, apCBC.DES_XB_Region_AP__c);
            }

            listSegmentsCountryManagement = new List<String>();
            final list<AP_Cross_Border_segment__mdt> listApCSS = [SELECT Label FROM AP_Cross_Border_segment__mdt];
            for (AP_Cross_Border_segment__mdt apCBC : listApCSS) {
                listSegmentsCountryManagement.add(apCBC.Label);
            }
        }


        //variables needed to translate country: Booking-Account
        if (mapCountryCodeToLabel == null || mapCountryBookingToLabel == null) {
            mapCountryCodeToLabel = new Map<String,String>();
            mapCountryBookingToLabel = new Map<String,String>();
            for (PickListEntry pe : Account.DES_Country_Client__c.getDescribe().getPicklistValues()) {
                mapCountryCodeToLabel.put(pe.getValue(), pe.getLabel());
            }

            for (PickListEntry pe : DES_Booking__c.DES_Country__c.getDescribe().getPicklistValues()) {
                mapCountryBookingToLabel.put(pe.getValue(), pe.getLabel());
            }
        }
    }


    /*
    * @author       Global Desktop
    * @Description  devuelve la etiqueta (en ingles) del país de Booking que se pasa como parámetro
    */
    public static String getCountryLabelFromCountryBooking(String bookingCountry) {
        if (mapCountryBookingToLabel.containsKey(bookingCountry)) {
            return mapCountryBookingToLabel.get(bookingCountry);
        } else {
            return '';
        }
    }


    /*
    * @author       Global Desktop
    * @Description  devuelve la etiqueta (en ingles) del código de país de Account/Opportunity que se pasa como parámetro
    */
    public static String getCountryLabelFromCountryCode(String countryCode) {
        String countryLabel = '';
        if ( USA_COUNTRIES.contains(countryCode) ) {
            countryLabel = mapCountryCodeToLabel.get('US');
            //return mapCountryCodeToLabel.get('US');
        } else if (mapCountryCodeToLabel.containsKey(countryCode)) {
            countryLabel = mapCountryCodeToLabel.get(countryCode);
            //return mapCountryCodeToLabel.get(countryCode);
        } //else {
            //return '';
        //}
        return countryLabel;
    }



    /*
    * @author       Global Desktop
    * @Description  devuelve la lista de Productos Englobla
    */
    public static Set<String> getListProductsEngloba() {
        return mapMatchProductsByEngloba.keySet();
    }


    /*
    * @author       Global Desktop
    * @Description  devuelve true si el producto que se pasa por parámetro está en la lista de Productos Englobla que se ha definido
    */
    public static Boolean isInListProductsEngloba(String prodEngloba) {
        return mapMatchProductsByEngloba.containsKey(prodEngloba);
    }


    /*
    * @author       Global Desktop
    * @Description  Devuelve la familia a la que pertenece un Producto Englobla
    */
    public static String getFamilyEngloba(String prodEngloba) {
        if (mapFamilyProductsEngloba.containsKey(prodEngloba)) {
            return mapFamilyProductsEngloba.get(prodEngloba);
        } else {
            return '';
        }
    }


    /*
    * @author       Global Desktop
    * @Description  Devuelve el producto  o lista de productos Global Desktop que equivalen al Producto Englobla
    */
    public static String getGDProductName(String prodEngloba) {
        if (mapMatchProductsByEngloba.containsKey(prodEngloba)) {
            return mapMatchProductsByEngloba.get(prodEngloba);
        } else {
            return '';
        }
    }


    /*
    * @author       Global Desktop
    * @Description  Devuelve el producto Englobla que equivale al producto de Global Desktop
    */
    public static String getEnglobaProductName(String prodGD) {
        if (mapMatchProductsByGD.containsKey(prodGD)) {
            return mapMatchProductsByGD.get(prodGD);
        } else {
            return '';
        }
    }


    /*
    * @author       Global Desktop
    * @Description  Comprueba si un producto Englobla es o no Cross Sell
    */
    public static Boolean isCrossSellProduct(String productName) {
        boolean auxBl;
        if (listCrossSellProducts.contains(productName)) {
            auxBl = true;
        } else {
            auxBl = false;
        }
        return auxBl;
    }

    /*
    * @author       Global Desktop
    * @Description  Comprueba si dos países están en la misma region definida para AP
    */
    public static Boolean isSameAPCrossBorderRegion(String countryOrigin, String countryDest) {
        if (mapCrossBorderCountryRegion.containsKey(countryOrigin) && mapCrossBorderCountryRegion.containsKey(countryDest) && 
            mapCrossBorderCountryRegion.get(countryOrigin) == mapCrossBorderCountryRegion.get(countryDest)) {
            return true;
        } else {
            return false;
        }
    }


    /*
    * @author       Global Desktop
    * @Description  Comprueba si un producto Englobla es o no Cross Border, chequeando el segmento/país del Group y país de booking
    */
    public static String isCrossBorder(String groupSegment, String groupCountryManagement, String groupCountry, String bookingCountry) {
        final String countryOrigin = (listSegmentsCountryManagement.contains(groupSegment) ? groupCountryManagement : groupCountry); 
        if ( getCountryLabelFromCountryCode(countryOrigin) == bookingCountry || isSameAPCrossBorderRegion(getCountryLabelFromCountryCode(countryOrigin), bookingCountry)) {
            return 'No';
        } else {
            return 'Yes';
        }
    }




    /*
    * @author       Global Desktop
    * @Description  Método que devuelve el mapa con los pipelines de los BPitems que recibe por parámetro, dicho mapa se utilizará para rellenar en cada BPItem el valor del campo customer_open_oppy_amount__c
    */
    public static Map<String,Decimal> getMapPipelineBPI(Set<Id> listGroupId) {
        Map<String,Decimal> mapPipelineBPI = new Map<String,Decimal> ();

        List<dwp_acmh__Denorm_Account_Opportunity__c> denormOppList = [SELECT dwp_acmh__OpportunityId__c, dwp_acmh__AccountId__c, dwp_acmh__AccountId__r.DES_Revenue_Update_Engloba__c 
                                    FROM dwp_acmh__Denorm_Account_Opportunity__c 
                                    WHERE dwp_acmh__AccountId__c IN :listGroupId AND dwp_acmh__OpportunityId__r.disclosure_info_type__c != :Label.DES_OP_Inside AND 
                                    ( (dwp_acmh__OpportunityId__r.IsClosed = false AND dwp_acmh__OpportunityId__r.CloseDate = THIS_YEAR) OR 
                                      (dwp_acmh__OpportunityId__r.IsClosed = true  AND dwp_acmh__OpportunityId__r.StageName = :Label.DES_Closed_Won AND dwp_acmh__OpportunityId__r.DES_Date_Won_Lost__c = THIS_YEAR) )];

        Map<Id,dwp_acmh__Denorm_Account_Opportunity__c> mapOppById = new Map<Id,dwp_acmh__Denorm_Account_Opportunity__c>();
        for(dwp_acmh__Denorm_Account_Opportunity__c denormOpp : denormOppList) {
            mapOppById.put(denormOpp.dwp_acmh__OpportunityId__c,denormOpp);
        }

    	List<OpportunityLineItem> oppProductList = [SELECT DES_Expected_Revenue__c, pre_oppy_revenue_next_12m_amount__c, DES_Product_Family__c, DES_Product_Name__c, OpportunityId, //NOSONAR
    												Opportunity.IsClosed, Opportunity.DES_Booking_Geography__c, Opportunity.DES_Date_Won_Lost__c,
													Opportunity.Account.DES_Revenue_Update_Engloba__c, DES_Corporate_currency_revenues__c
                                                    FROM OpportunityLineItem
                                                    WHERE OpportunityId IN :mapOppById.keySet()
													AND Opportunity.Account.DES_Revenue_Update_Engloba__c != null AND Opportunity.Account.DES_Revenue_Update_Engloba__c != ''];

        for(OpportunityLineItem oppProduct : oppProductList) {
            Date lastEnglobaUpdate =  date.newinstance(
                        Integer.valueOf(oppProduct.Opportunity.Account.DES_Revenue_Update_Engloba__c.substring(0,4)),
                        Integer.valueOf(oppProduct.Opportunity.Account.DES_Revenue_Update_Engloba__c.substring(4,6)),
                        Integer.valueOf(oppProduct.Opportunity.Account.DES_Revenue_Update_Engloba__c.substring(6))
                );
            //only open opportunities and closed win opportunities after last EnglobaUpdate    
            If (!oppProduct.Opportunity.IsClosed || (oppProduct.Opportunity.IsClosed && oppProduct.Opportunity.DES_Date_Won_Lost__c >= lastEnglobaUpdate)) {
                String keyMapBPI = mapOppById.get(oppProduct.OpportunityId).dwp_acmh__AccountId__c + '++' + getCountryLabelFromCountryCode(oppProduct.Opportunity.DES_Booking_Geography__c) + '++' + getEnglobaProductName(oppProduct.DES_Product_Name__c);
                //Decimal auxRevenue = (oppProduct.Opportunity.IsClosed ? oppProduct.pre_oppy_revenue_next_12m_amount__c : oppProduct.DES_Expected_Revenue__c); //  el campo "DES_Expected_Revenue__c" ya está calculando "pre_oppy_revenue_next_12m_amount__c * oppProduct.Opportunity.DES_Expected_Probability__c"
                Decimal auxRevenue = oppProduct.DES_Corporate_currency_revenues__c;
                if (mapPipelineBPI.containsKey(keyMapBPI)) {
                    auxRevenue += mapPipelineBPI.get(keyMapBPI);
                    mapPipelineBPI.put(keyMapBPI, auxRevenue);
                } else {
                    mapPipelineBPI.put(keyMapBPI, auxRevenue);
                }
            }
        }
        return mapPipelineBPI;
    }



    /*
    * @author       Global Desktop
    * @Description  Método que devuelve la lista de bookings de los groupoId y desde el año pasados como parámetro.
    *               Para el proceso de carga automática el yearFrom será desde dos años anteriores; para el proceso batch de actualiazación sólo se recogen lo del año actual
    */
    public static List<DES_Booking__c> getListBookingsBPI(Set<Id> listGroupId,Integer fromYear) {
System.debug('********** getListBookingsBPI query params. listGroupId: ' + listGroupId + '\r\nfromYear: ' + fromYear); 
        return [Select Id, Name, CurrencyIsoCode, DES_Client__c, Current_Year_Last_Year__c, DES_Country__c, 
            DES_Current_Year_Revenues__c, DES_Current_Year__c, DES_Engloba_Date_Info__c, DES_Engloba_Load_Helper__c, DES_Previous_Year_Revenues__c, 
            DES_Provisioning_Method__c, DES_Region__c, DES_Revenues__c, DES_Segment__c, DES_Type__c, /* DES_XB__c,*/ DES_Year_Number__c, DES_Year__c, 
            SOLUTION_CATEGORY_NAME__c, Month_type__c, SOLUTION_CATEGORY_DESC__c, SOLUTION_CATEGORY_ID__c, DES_Client__r.DES_Segment__c, DES_Client__r.DES_Subsegment__c, DES_Client__r.DES_Tier__c,
            DES_Client__r.DES_Country_Client__c, DES_Client__r.DES_Country_of_Management__c/*, DES_Client__r.Industry*/ 
            From DES_Booking__c Where DES_Client__c In :listGroupId And DES_Year_Number__c >= :fromYear
            Order by DES_Client__c,DES_Year_Number__c];
    }


    /*
    * @author       Global Desktop
    * @Description  Método que devuelve el mapa con los BPItems del BP anterior, dicho mapa se utilizará para rellenar en cada BPItem el valor de "annual_expect_profit_py_amount__c"
    */
    public static Map<String,bupl__BusinessPlan_Item__c> getMapPreviousBPI(Set<Id> listGroupId, List<Id> listCurrentBPid) {
        Map<String,bupl__BusinessPlan_Item__c> mapPreviousBPItems = new Map<String,bupl__BusinessPlan_Item__c> ();
        list<bupl__BusinessPlan__c > listPreviousBP = [Select Id, Name, bupl__participant_id__c, CreatedDate 
                                From bupl__BusinessPlan__c 
                                where bupl__participant_id__c IN :listGroupId and Id NOT IN :listCurrentBPid and bupl__status_type__c = 'Validated' 
                                Order By CreatedDate Desc];

        // Para cada groupId, nos quedamos con el BP validado más reciente, por si hay de varios años
        Map<id,bupl__BusinessPlan__c>   mapPreviousBP = new Map<id,bupl__BusinessPlan__c>   ();
        Map<id,id> mapIdPreviousBP = new Map<id,id>();
        for (bupl__BusinessPlan__c bp : listPreviousBP) {
            if (!mapPreviousBP.containsKey(bp.bupl__participant_id__c) || (mapPreviousBP.containsKey(bp.bupl__participant_id__c) && mapPreviousBP.get(bp.bupl__participant_id__c).createdDate < bp.createdDate) ) {
                mapPreviousBP.put(bp.bupl__participant_id__c,bp);
                mapIdPreviousBP.put(bp.bupl__participant_id__c,bp.Id);
            }
        }

        List<bupl__BusinessPlan_Item__c> listPreviousBPItems = [Select id, bupl__gf_business_plan_version_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c, bupl__expected_revenue_amount__c, bupl__pre_expct_prft_next_12m_amount__c, bupl__solution_category_desc__c, bupl__gf_booking_operation_cntry_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c
                                    From bupl__BusinessPlan_Item__c 
                                    Where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c IN :mapIdPreviousBP.values() And 
                                                bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = 'Yes' And bupl__expected_revenue_amount__c != 0];

        for (bupl__BusinessPlan_Item__c bpi : listPreviousBPItems) {
            String keyMapBPI = bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c + '++' + bpi.bupl__gf_booking_operation_cntry_id__c + '++' + bpi.bupl__solution_category_desc__c;
            mapPreviousBPItems.put(keyMapBPI,bpi);
        }

        return mapPreviousBPItems;
    }


    /*
    * @author       Global Desktop
    * @Description  Return the initialized complete product list for a pair idClient-Country
    */
    public static map<String,bupl__BusinessPlan_Item__c> initBPItemsClientCountry (DES_Booking__c currentBooking, Id idBPV) {
        String segmentPicklistLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Segment__c').get(currentBooking.DES_Client__r.DES_Segment__c);
        final String crossBorderResult = isCrossBorder(segmentPicklistLabel, currentBooking.DES_Client__r.DES_Country_of_Management__c, 
                                                       currentBooking.DES_Client__r.DES_Country_Client__c, getCountryLabelFromCountryBooking(currentBooking.DES_Country__c));
        map<String, bupl__BusinessPlan_Item__c> initBPClientCountryMap = new map<String,bupl__BusinessPlan_Item__c>();
        String keyMapBPi;// como sólo exista un AP por cliente (group), el clientId nos sirve de indentificador unico entre Group => AP => BP
        for (String prodEngl : getListProductsEngloba()) {
            keyMapBPi = currentBooking.DES_Client__c + '++' + getCountryLabelFromCountryBooking(currentBooking.DES_Country__c) + '++' + prodEngl;
            String tierPicklistLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Tier__c').get(currentBooking.DES_Client__r.DES_Tier__c);
            String subsegmentPicklistLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Subsegment__c').get(currentBooking.DES_Client__r.DES_Subsegment__c);
            bupl__BusinessPlan_Item__c newBPI = new bupl__BusinessPlan_Item__c (
                    bupl__gf_cross_border_rev_ind_type__c = crossBorderResult,
                    bupl__gf_cross_sell_rev_ind_type__c = (isCrossSellProduct(prodEngl) ? 'Yes' : 'No'),
                    bupl__solution_category_desc__c = prodEngl,
                    industry_desc__c = subsegmentPicklistLabel,
                    tier_desc__c = tierPicklistLabel,
                    bupl__gf_business_plan_version_id__c = idBPV,
                    bupl__gf_booking_operation_cntry_id__c =  getCountryLabelFromCountryBooking(currentBooking.DES_Country__c),
                    bupl__solution_category_id__c = getFamilyEngloba(prodEngl),
                    bupl__annual_expect_profit_py_amount__c = 0,
                    bupl__customer_open_oppy_amount__c = 0,
                    bupl__gf_total_revenues_ytd_amount__c = 0,
                    bupl__total_revenues_py_amount__c = 0,
                    bupl__expected_profit_2py_amount__c = 0,
                    bupl__pre_expct_prft_next_12m_amount__c = 0,
                    bupl__expected_revenue_amount__c = 0
                );
            initBPClientCountryMap.put(keyMapBPi,newBPI);
        }

        return initBPClientCountryMap;
    }

}