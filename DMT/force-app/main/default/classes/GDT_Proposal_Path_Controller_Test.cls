/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
global with sharing class GDT_Proposal_Path_Controller_Test {
    
    
    @isTest
    static void testGetRegionAmbit() {
        Test.startTest();
        List<GDT_Proposal_Path_Controller.ComboboxOption> options = GDT_Proposal_Path_Controller.getRegionAmbit();
        Test.stopTest();
        
        // Validar que la lista no es nula
        System.assertNotEquals(null, options, 'La lista de opciones no debe ser nula.');
    }

    @isTest
    static void testGetLevelAmbit() {
        Test.startTest();
        List<GDT_Proposal_Path_Controller.ComboboxOption> options = GDT_Proposal_Path_Controller.getLevelAmbit('Taxonomy_1'); 
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'La lista de opciones no debe ser nula.');
    }

    @isTest
    static void testGetDescriptionAmbit() {
        Test.startTest();
        List<GDT_Proposal_Path_Controller.ComboboxOption> options = GDT_Proposal_Path_Controller.getDescriptionAmbit('Level_1', 'Taxonomy_1');
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'La lista de opciones no debe ser nula.');
    }

    @isTest
    static void testGetTaxonomy() {
        Test.startTest();
        List<GDT_Proposal_Path_Controller.ComboboxOption> options = GDT_Proposal_Path_Controller.getTaxonomy();
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'La lista de opciones no debe ser nula.');
    }

}