/****************************************************************************************
*   @author: GlobalDesktop
*   @Class: DES_ContactVisitHelper
*   @Description:  Copia el valor de un campo que viene filtrado en otro o viceversa


*   @Versions:
        v1 - 2019/02/XX - Initial version
******************************************************************************************/
public with sharing class DES_ContactVisitHelper {

	/*Declarando variable*/
    private static DES_ContactVisitHelper instance;

	/**
	* @author Global Desktop
	* @description Constructor
	*/
	private DES_ContactVisitHelper() {
		System.debug('Constructor');
	}
	   /*
  *  validar contactos repetidos al crear un contacto
  */
  public static void validarContactosDuplicados(List <dwp_kitv__Visit_Contact__c> triggerNew) {
    if(triggerNew.size()>0) {
        final Set <Id> idsVisitas = new Set <Id>();
        for(dwp_kitv__Visit_Contact__c visitContact : triggerNew) {
          if(!idsVisitas.contains(visitContact.dwp_kitv__visit_id__c)) {
            idsVisitas.add(visitContact.dwp_kitv__visit_id__c);
          }
        }
        for(Id visitid : idsVisitas) {

            final Set <Id> idsContact = new Set <Id>();
            for(dwp_kitv__Visit_Contact__c visitContact : triggerNew) {
              if(visitContact.dwp_kitv__visit_id__c==visitid) {
                  if(!idsContact.contains(visitContact.dwp_kitv__contact_id__c)) {
                      idsContact.add(visitContact.dwp_kitv__contact_id__c);
                  }else {
                     visitContact.addError(System.Label.lbl_DuplicateContact);
                  }
              }
            }
        }
    }


  }
	/**
	* @author Global Desktop
	* @description Singleton Pattern
	*/
    public static DES_ContactVisitHelper getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_ContactVisitHelper();
        }
        return instance;
    }

	/*
	* @author Global Desktop
	* @description Función para que los dos Lookups a contacto del objeto visit contact valgan lo mismo.
	*/
	public static void relatedContactUpdate(final list<dwp_kitv__Visit_Contact__c> triggerNew, final Map<Id,dwp_kitv__Visit_Contact__c> oldMap) {
		for(dwp_kitv__Visit_Contact__c vContact : triggerNew) {
			if(vContact.dwp_kitv__contact_id__c == null/* || oldMap.get(vContact.Id).Contact_filtered__c != vContact.Contact_filtered__c*/) {
				vContact.dwp_kitv__contact_id__c = vContact.Contact_filtered__c;
			} else {
				vContact.Contact_filtered__c = vContact.dwp_kitv__contact_id__c;
			}
		}
	}

	/*
	* Method para replicar la funcionalidad del proccess Main contact Visit
	*/
	public static void mainContactNew(List <dwp_kitv__Visit_Contact__c> triggerNew) {
		final Map <Id, Boolean> mapVisitMain = new Map <Id, Boolean>();
		final Map<Id, String> mapVisitContact = new Map <Id, String>();

		final Map <Id, Contact> mapContacName = fillMapContactName(triggerNew);

		for(dwp_kitv__Visit_Contact__c visitContact : triggerNew) {
			if((mapVisitMain.get(visitContact.dwp_kitv__visit_id__c) == null ||
			(mapVisitMain.get(visitContact.dwp_kitv__visit_id__c) != null && !mapVisitMain.get(visitContact.dwp_kitv__visit_id__c)))
			 && visitContact.dwp_kitv__Main_contact__c) {
				visitContact.dwp_kitv__Send_minutes__c = 'To';
				mapVisitMain.put(visitContact.dwp_kitv__visit_id__c, true);
				mapVisitContact.put(visitContact.dwp_kitv__visit_id__c, mapContacName.get(visitContact.dwp_kitv__contact_id__c).LastName);
			} else {
				visitContact.dwp_kitv__Main_contact__c = false;
				visitContact.dwp_kitv__Send_minutes__c = 'CC';
			}
		}
		updateVisitContact(mapVisitMain);
		updateVisit(mapVisitContact);

	}

	/*
	* Fill mapContactName method for mainContactNew
	*/
	private static Map <Id, Contact> fillMapContactName(List <dwp_kitv__Visit_Contact__c> triggerNew) {
		final Set <Id> idsContact = new Set <Id>();

		for(dwp_kitv__Visit_Contact__c visitContact : triggerNew) {
			if(!idsContact.contains(visitContact.dwp_kitv__contact_id__c)) {
				idsContact.add(visitContact.dwp_kitv__contact_id__c);
			}
		}

		return new Map <Id,Contact>([
			SELECT Id, LastName
			FROM Contact
			WHERE Id IN :idsContact
		]);

		}

	/*
	* Update visit contact for mainContactNew
	*/
	private static void updateVisitContact(Map <Id, Boolean> mapVisitMain) {
		final List<dwp_kitv__Visit_Contact__c> visitContacts = new List <dwp_kitv__Visit_Contact__c>([
			SELECT Id, dwp_kitv__Main_contact__c, dwp_kitv__visit_id__c
			FROM dwp_kitv__Visit_Contact__c
			WHERE dwp_kitv__visit_id__c in :mapVisitMain.keySet()
		]);
		if(!visitContacts.isEmpty()) {
			for(dwp_kitv__Visit_Contact__c visContact : visitContacts) {
				visContact.dwp_kitv__Main_contact__c = false;
				visContact.dwp_kitv__Send_minutes__c = 'CC';
			}
			update visitContacts;
		}
	}

	/*
	* Update visit for mainContactNew
	*/
	private static void updateVisit(Map<Id, String> mapVisitContact) {
		final List <dwp_kitv__Visit__c> visitToupdate = new List<dwp_kitv__Visit__c>();
		for(Id idVisit : mapVisitContact.keySet()) {
			final dwp_kitv__Visit__c visitAux = new dwp_kitv__Visit__c(Id = idVisit, dwp_kitv__Main_Contact__c = mapVisitContact.get(idVisit));
			visitToupdate.add(visitAux);
		}
		if(!visitToupdate.isEmpty()) {
			update visitToupdate;
		}
	}
}