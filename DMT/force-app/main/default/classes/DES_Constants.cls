/**
 * @description Central constants class for the Desktop (DES) domain.
 *              Constants are grouped by naming prefix:
 *                  ROLE_        → team member / management team roles
 *                  ACCOUNT_RT_  → Account Record Type developer names
 *
 *              Usage:
 *                  String role = DES_Constants.ROLE_GLOBAL_BANKER;
 *                  String rt   = DES_Constants.ACCOUNT_RT_PROSPECT_GROUP;
 *
 * @author      Borja Lorenzo Adajas
 * @date        2026-05-14
 */
public with sharing class DES_Constants {

    // ──────────────────────────────────────────────────────────────────────────
    // Roles  (ROLE_)
    // ──────────────────────────────────────────────────────────────────────────

    /** Global Banker role. Matches DES_Member_Role__c on DES_BBVA_Management_team__c. */
    public static final String ROLE_GLOBAL_BANKER = Label.DES_ROLE_GLOBAL_BANKER;

    /** DES_Local_Banker_Country__c value used when creating Global Banker management team records. */
    public static final String MANAGEMENT_TEAM_GLOBAL_COUNTRY = 'Global';

    // ──────────────────────────────────────────────────────────────────────────
    // Account — Record Type developer names  (ACCOUNT_RT_)
    // ──────────────────────────────────────────────────────────────────────────

    /** Prospect Group Account Record Type developer name. */
    public static final String ACCOUNT_RT_PROSPECT_GROUP = 'Prospect_Group';

    /** Prospect Subsidiary Account Record Type developer name. */
    public static final String ACCOUNT_RT_PROSPECT_SUBSIDIARY = 'Prospect_Subsidiary';

    // ──────────────────────────────────────────────────────────────────────────
    // Account — Prospect Status Funnel values  (PROSPECT_STATUS_FUNNEL_)
    // ──────────────────────────────────────────────────────────────────────────

    /** Prospect Status Funnel - Identify. */
    public static final String PROSPECT_STATUS_FUNNEL_IDENTIFY = 'Identify';
    
}