/**
 * @description Batch job that recalculates and updates g_customer_id__c on all
 *              Prospect_Subsidiary accounts using the country-to-entific mapping
 *              defined in DES_Country_Entific_Mapping__mdt.
 *
 *              Formula: g_customer_id__c = <entific_alpha_prefix> + 'P' + DES_Sequence__c
 *
 *              Only accounts with a non-blank DES_Country_of_Management_OLD__c and
 *              DES_Sequence__c are processed. Accounts whose computed value is already
 *              correct are skipped to avoid unnecessary DML.
 *
 *              Execution example (default batch size 200):
 *                  Database.executeBatch(new DES_UpdateCustomerIdBatch(), 200);
 *
 * @author      Generated
 * @date        2026-05-28
 */
public with sharing class DES_UpdateCustomerIdBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer totalProcessed = 0;
    private Integer totalUpdated   = 0;
    private Integer totalErrors    = 0;

    // Loaded once in start() and reused across execute() chunks.
    private Map<String, String> countryToEntificMap;

    /**
     * ISO 3166-1 alpha-3 → alpha-2 mapping.
     * Used to convert the owner's DES_Country__c (ISO 3) to the ISO 2 code
     * required by DES_Country_Entific_Mapping__mdt.
     */
    private static final Map<String, String> ISO3_TO_ISO2 = new Map<String, String>{
        'ALA' => 'AX', // Åland Islands
        'ALB' => 'AL', // Albania
        'DZA' => 'DZ', // Algeria
        'ASM' => 'AS', // American Samoa
        'AND' => 'AD', // Andorra
        'AGO' => 'AO', // Angola
        'AIA' => 'AI', // Anguilla
        'ATA' => 'AQ', // Antarctica
        'ATG' => 'AG', // Antigua and Barbuda
        'ARE' => 'AE', // Arab Emirates
        'ARG' => 'AR', // Argentina
        'ARM' => 'AM', // Armenia
        'ABW' => 'AW', // Aruba
        'SHN' => 'SH', // Ascensión y Tristán de Acuña
        'AUS' => 'AU', // Australia
        'AUT' => 'AT', // Austria
        'AZE' => 'AZ', // Azerbaijan
        'BHS' => 'BS', // Bahamas
        'BHR' => 'BH', // Bahrain
        'BGD' => 'BD', // Bangladesh
        'BRB' => 'BB', // Barbados
        'BLR' => 'BY', // Belarus
        'BEL' => 'BE', // Belgium
        'BLZ' => 'BZ', // Belize
        'BEN' => 'BJ', // Benin
        'BMU' => 'BM', // Bermuda Islands
        'BTN' => 'BT', // Bhutan
        'BOL' => 'BO', // Bolivia
        'BIH' => 'BA', // Bosnia and Herzegovina
        'BWA' => 'BW', // Botswana
        'BVT' => 'BV', // Bouvet Island
        'BRA' => 'BR', // Brazil
        'IOT' => 'IO', // British Indian Ocean Territory
        'BRN' => 'BN', // Brunei
        'BGR' => 'BG', // Bulgaria
        'BFA' => 'BF', // Burkina Faso
        'BDI' => 'BI', // Burundi
        'KHM' => 'KH', // Cambodia
        'CMR' => 'CM', // Cameroon
        'CAN' => 'CA', // Canada
        'CPV' => 'CV', // Cape Verde
        'CYM' => 'KY', // Cayman Islands
        'CAF' => 'CF', // Central African Republic
        'TCD' => 'TD', // Chad
        'CHL' => 'CL', // Chile
        'CHN' => 'CN', // China
        'CXR' => 'CX', // Christmas Island
        'CCK' => 'CC', // Cocos (Keeling) Islands
        'COL' => 'CO', // Colombia
        'COM' => 'KM', // Comoros
        'COG' => 'CG', // Congo
        'COK' => 'CK', // Cook Islands
        'CRI' => 'CR', // Costa Rica
        'HRV' => 'HR', // Croatia
        'CUB' => 'CU', // Cuba
        'CYP' => 'CY', // Cyprus
        'CZE' => 'CZ', // Czech Republic
        'DNK' => 'DK', // Denmark
        'DJI' => 'DJ', // Djibouti
        'DMA' => 'DM', // Dominica
        'DOM' => 'DO', // Dominican Republic
        'TLS' => 'TL', // East Timor
        'ECU' => 'EC', // Ecuador
        'EGY' => 'EG', // Egypt
        'SLV' => 'SV', // El Salvador
        'GNQ' => 'GQ', // Equatorial Guinea
        'ERI' => 'ER', // Eritrea
        'EST' => 'EE', // Estonia
        'ETH' => 'ET', // Ethiopia
        'FLK' => 'FK', // Falkland Islands (Malvinas)
        'FRO' => 'FO', // Faroe Islands
        'FJI' => 'FJ', // Fiji
        'FIN' => 'FI', // Finland
        'FRA' => 'FR', // France
        'GUF' => 'GF', // French Guiana
        'PYF' => 'PF', // French Polynesia
        'ATF' => 'TF', // French Southern and Antarctic Lands
        'GAB' => 'GA', // Gabon
        'GMB' => 'GM', // Gambia
        'GEO' => 'GE', // Georgia
        'DEU' => 'DE', // Germany
        'GHA' => 'GH', // Ghana
        'GIB' => 'GI', // Gibraltar
        'GRC' => 'GR', // Greece
        'GRL' => 'GL', // Greenland
        'GRD' => 'GD', // Grenada
        'GLP' => 'GP', // Guadeloupe
        'GUM' => 'GU', // Guam
        'GTM' => 'GT', // Guatemala
        'GGY' => 'GG', // Guernsey
        'GIN' => 'GN', // Guinea
        'GNB' => 'GW', // Guinea-Bissau
        'GUY' => 'GY', // Guyana
        'HTI' => 'HT', // Haiti
        'HMD' => 'HM', // Heard Island and McDonald Islands
        'HND' => 'HN', // Honduras
        'HKG' => 'HK', // Hong Kong
        'HUN' => 'HU', // Hungary
        'ISL' => 'IS', // Iceland
        'IND' => 'IN', // India
        'IDN' => 'ID', // Indonesia
        'IRN' => 'IR', // Iran
        'IRQ' => 'IQ', // Iraq
        'IRL' => 'IE', // Ireland
        'IMN' => 'IM', // Isle of Man
        'ISR' => 'IL', // Israel
        'ITA' => 'IT', // Italy
        'CIV' => 'CI', // Ivory Coast
        'JAM' => 'JM', // Jamaica
        'JPN' => 'JP', // Japan
        'JEY' => 'JE', // Jersey
        'JOR' => 'JO', // Jordan
        'KAZ' => 'KZ', // Kazakhstan
        'KEN' => 'KE', // Kenya
        'KIR' => 'KI', // Kiribati
        'KWT' => 'KW', // Kuwait
        'KGZ' => 'KG', // Kyrgyzstan
        'LAO' => 'LA', // Laos
        'LVA' => 'LV', // Latvia
        'LBN' => 'LB', // Lebanon
        'LSO' => 'LS', // Lesotho
        'LBR' => 'LR', // Liberia
        'LBY' => 'LY', // Libya
        'LIE' => 'LI', // Liechtenstein
        'LTU' => 'LT', // Lithuania
        'LUX' => 'LU', // Luxembourg
        'MAC' => 'MO', // Macao
        'MKD' => 'MK', // Macedonia
        'MDG' => 'MG', // Madagascar
        'MWI' => 'MW', // Malawi
        'MYS' => 'MY', // Malaysia
        'MDV' => 'MV', // Maldives
        'MLI' => 'ML', // Mali
        'MLT' => 'MT', // Malta
        'MHL' => 'MH', // Marshall Islands
        'MTQ' => 'MQ', // Martinique
        'MRT' => 'MR', // Mauritania
        'MUS' => 'MU', // Mauritius
        'MYT' => 'YT', // Mayotte
        'MEX' => 'MX', // Mexico
        'MDA' => 'MD', // Moldova
        'MCO' => 'MC', // Monaco
        'MNG' => 'MN', // Mongolia
        'MNE' => 'ME', // Montenegro
        'MSR' => 'MS', // Montserrat
        'MAR' => 'MA', // Morocco
        'MOZ' => 'MZ', // Mozambique
        'MMR' => 'MM', // Myanmar
        'NAM' => 'NA', // Namibia
        'NRU' => 'NR', // Nauru
        'NPL' => 'NP', // Nepal
        'ANT' => 'AN', // Netherlands Antilles
        'NLD' => 'NL', // Netherlands
        'NCL' => 'NC', // New Caledonia
        'NZL' => 'NZ', // New Zealand
        'NIC' => 'NI', // Nicaragua
        'NER' => 'NE', // Niger
        'NGA' => 'NG', // Nigeria
        'NIU' => 'NU', // Niue
        'NFK' => 'NF', // Norfolk Island
        'PRK' => 'KP', // North Korea
        'MNP' => 'MP', // Northern Mariana Islands
        'NOR' => 'NO', // Norway
        'OMN' => 'OM', // Oman
        'PAK' => 'PK', // Pakistan
        'PLW' => 'PW', // Palau
        'PSE' => 'PS', // Palestine
        'PAN' => 'PA', // Panama
        'PRY' => 'PY', // Paraguay
        'PER' => 'PE', // Peru
        'PHL' => 'PH', // Philippines
        'PCN' => 'PN', // Pitcairn Islands
        'POL' => 'PL', // Poland
        'PRT' => 'PT', // Portugal
        'PRI' => 'PR', // Puerto Rico
        'QAT' => 'QA', // Qatar
        'REU' => 'RE', // Réunion
        'ROU' => 'RO', // Romania
        'RUS' => 'RU', // Russia
        'RWA' => 'RW', // Rwanda
        'BLM' => 'BL', // Saint Barthélemy
        'KNA' => 'KN', // Saint Kitts and Nevis
        'LCA' => 'LC', // Saint Lucia
        'MAF' => 'MF', // Saint Martin (French part)
        'SPM' => 'PM', // Saint Pierre and Miquelon
        'VCT' => 'VC', // Saint Vincent and the Grenadines
        'WSM' => 'WS', // Samoa
        'SMR' => 'SM', // San Marino
        'STP' => 'ST', // Sao Tome and Principe
        'SAU' => 'SA', // Saudi Arabia
        'SEN' => 'SN', // Senegal
        'SRB' => 'RS', // Serbia
        'SYC' => 'SC', // Seychelles
        'SLE' => 'SL', // Sierra Leone
        'SGP' => 'SG', // Singapore
        'SVK' => 'SK', // Slovakia
        'SVN' => 'SI', // Slovenia
        'SLB' => 'SB', // Solomon Islands
        'SOM' => 'SO', // Somalia
        'ZAF' => 'ZA', // South Africa
        'SGS' => 'GS', // South Georgia and the South Sandwich Islands
        'KOR' => 'KR', // South Korea
        'ESP' => 'ES', // Spain
        'LKA' => 'LK', // Sri Lanka
        'SDN' => 'SD', // Sudan
        'SUR' => 'SR', // Suriname
        'SJM' => 'SJ', // Svalbard and Jan Mayen
        'SWZ' => 'SZ', // Swaziland
        'SWE' => 'SE', // Sweden
        'CHE' => 'CH', // Switzerland
        'SYR' => 'SY', // Syria
        'TWN' => 'TW', // Taiwan
        'TJK' => 'TJ', // Tajikistan
        'TZA' => 'TZ', // Tanzania
        'THA' => 'TH', // Thailand
        'TGO' => 'TG', // Togo
        'TKL' => 'TK', // Tokelau
        'TON' => 'TO', // Tonga
        'TTO' => 'TT', // Trinidad and Tobago
        'TUN' => 'TN', // Tunisia
        'TUR' => 'TR', // Turkey
        'TKM' => 'TM', // Turkmenistan
        'TCA' => 'TC', // Turks and Caicos Islands
        'TUV' => 'TV', // Tuvalu
        'UGA' => 'UG', // Uganda
        'UKR' => 'UA', // Ukraine
        'GBR' => 'GB', // United Kingdom
        'UMI' => 'UM', // United States Minor Outlying Islands
        'VIR' => 'VI', // United States Virgin Islands
        'URY' => 'UY', // Uruguay
        'USA' => 'US', // USA
        'UZB' => 'UZ', // Uzbekistan
        'VUT' => 'VU', // Vanuatu
        'VAT' => 'VA', // Vatican City State
        'VEN' => 'VE', // Venezuela
        'VNM' => 'VN', // Vietnam
        'VGB' => 'VG', // Virgin Islands
        'WLF' => 'WF', // Wallis and Futuna
        'ESH' => 'EH', // Western Sahara
        'YEM' => 'YE', // Yemen
        'ZMB' => 'ZM'  // Zambia
    };

    // ──────────────────────────────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext bc) {
        countryToEntificMap = buildCountryToEntificMap();

        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Prospect_Subsidiary')
            .getRecordTypeId();

        return Database.getQueryLocator([
            SELECT Id, RecordTypeId, DES_Country_of_Management_OLD__c, DES_Sequence__c, g_customer_id__c,
                   participant_id__c, Owner.DES_Country__c
            FROM   Account
            WHERE  RecordTypeId   = :subsidiaryRtId
              AND  DES_Sequence__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Resolve country from parent group for subsidiaries with blank country.
        Set<Id> parentIds = new Set<Id>();
        for (Account acc : scope) {
            if (String.isBlank(acc.DES_Country_of_Management_OLD__c) && acc.participant_id__c != null) {
                parentIds.add(acc.participant_id__c);
            }
        }

        Map<Id, Account> parentById = new Map<Id, Account>();
        if (!parentIds.isEmpty()) {
            for (Account parent : [
                SELECT Id, DES_Country_of_Management_OLD__c
                FROM   Account
                WHERE  Id IN :parentIds
            ]) {
                parentById.put(parent.Id, parent);
            }
        }

        List<Account> toUpdate = new List<Account>();

        for (Account acc : scope) {
            totalProcessed++;

            String country = acc.DES_Country_of_Management_OLD__c;
            if (String.isBlank(country) && acc.participant_id__c != null) {
                Account parent = parentById.get(acc.participant_id__c);
                if (parent != null) {
                    country = parent.DES_Country_of_Management_OLD__c;
                }
            }

            // Fallback: owner's DES_Country__c (ISO 3 → ISO 2).
            if (String.isBlank(country)) {
                String iso3 = acc.Owner?.DES_Country__c;
                if (String.isNotBlank(iso3)) {
                    country = ISO3_TO_ISO2.get(iso3.trim().toUpperCase());
                }
            }

            if (String.isBlank(country)) {
                continue;
            }

            String countryCode = country.trim().toUpperCase();
            String prefix      = extractAlphabeticPrefix(countryToEntificMap.get(countryCode));

            if (String.isBlank(prefix)) {
                continue;
            }

            String newCustomerId = prefix + 'P' + acc.DES_Sequence__c;

            if (newCustomerId != acc.g_customer_id__c) {
                toUpdate.add(new Account(Id = acc.Id, g_customer_id__c = newCustomerId));
            }
        }

        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    totalUpdated++;
                } else {
                    totalErrors++;
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'DES_UpdateCustomerIdBatch – error updating Account ' + sr.getId()
                            + ': ' + err.getStatusCode() + ' – ' + err.getMessage());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'DES_UpdateCustomerIdBatch finished. '
            + 'Processed: ' + totalProcessed
            + ', Updated: '  + totalUpdated
            + ', Errors: '   + totalErrors);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private helpers (same logic as DES_ProspectService)
    // ──────────────────────────────────────────────────────────────────────────

    private static Map<String, String> buildCountryToEntificMap() {
        Map<String, String> result = new Map<String, String>();

        for (DES_Country_Entific_Mapping__mdt row : [
            SELECT Country_Code__c, Entific__c
            FROM   DES_Country_Entific_Mapping__mdt
        ]) {
            if (String.isNotBlank(row.Country_Code__c) && String.isNotBlank(row.Entific__c)) {
                result.put(row.Country_Code__c.trim().toUpperCase(), row.Entific__c.trim());
            }
        }

        return result;
    }

    private static String extractAlphabeticPrefix(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        String trimmed = value.trim();
        String prefix  = '';
        for (Integer i = 0; i < trimmed.length(); i++) {
            String ch = trimmed.substring(i, i + 1);
            if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')) {
                prefix += ch.toUpperCase();
            } else {
                break;
            }
        }

        return prefix;
    }
}