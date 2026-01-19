/*----------------------------------------------------------------------------------------------
    Description:    Creacion de datos dummy para los Tests de Commercial Offer.

    History:
    <Date>          <Author>                <Description>
    18/05/2020
-----------------------------------------------------------------------------------------------*/
public with sharing class UtilTest_CommercialOffer {

    /*
    *   Met0d0 que crea ofertas comerciales
    */
    public coff__Commercial_Offer__c createCommOff(Account acc) {//NOSONAR
        final coff__Commercial_Offer__c cOffer = new coff__Commercial_Offer__c();
        cOffer.Name = 'Commercial Offer Test';
        cOffer.coff__participant_id__c = acc.Id;
        cOffer.coff__gf_commercial_offer_desc__c = 'Test';
        return cOffer;
    }
}