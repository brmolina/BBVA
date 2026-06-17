// mockData.js
export const MOCK_DATA_A = {
    components: [
        // 1. THIS SHOULD BE IGNORED COMPLETELY (In both, but with diffs)
        { name: "Limit Visual", content: [{ type: "title", text: "LIMIT VISUAL A" }, { type: "values2", body: [[{name: "A", value: "A"}]] }] },
        
        // 2. THIS SECTION IS ONLY IN A (Will show as Removed/Red)
        { name: "TEMPORARY SECTION A", content: [{ type: "title", text: "ONLY IN VERSION A" }, { type: "values2", body: [[{name: "Status", value: "Will be deleted"}]] }] },
        
        // 3. REGULAR COMPONENTS WITH DATA
        { name: "Line Info", content: [
            { type: "title", text: "LINE INFO", margin: { top: 5, bottom: 3 }, style: { nobreak: false, fontSize: 13 } },
            { type: "values2", body: [
                [ { value: "ESCD26LIN00001050ES", name: "Line Id:" }, { value: "ES", name: "Entific:" }, { value: "17-Feb-2026", name: "Start Date:" }, { value: "Line Gestor Documental", name: "Name:" } ],
                [ { value: "EUR", name: "Currency:" }, { value: "28-Feb-2027", name: "End Date:" }, { value: "", name: "Office:" } ]
            ]}
        ]},
        { name: "CLIENT", content: [
            { type: "title", text: "CLIENT" },
            { type: "values2", body: [
                [ { value: "IBERDROLA INMOBILIARIA S.A.", name: "Client:" }, { value: "Customer", name: "Client Type:" } ],
                [ { value: "A-", name: "Internal Rating (Short):" } ]
            ]}
        ]},
        { name: "PRODUCTS", content: [
            { type: "title", text: "PRODUCTS" },
            { type: "values2", body: [
                [ { value: "900.000,00 EUR", name: "Delivery vs Payment (DvP) Amount:" }, { value: "3Y", name: "First Breakclause:" }, { value: "No", name: "ISDA Waiver:" } ],
                [ { value: "800.000,00 EUR", name: "Free Delivery (FD) Amount (Units EUR):" }, { value: "1Y", name: "Breakclause Frequency:" } ]
            ]},
            { type: "values2", body: [[ { value: "", name: "Additional Products:" } ]] },
            { type: "title", text: "COUNTERPARTY RISK (DERIVATIVES RISK LINE)" },
            { type: "table", head: [["INIT TERM", "END TERM", "AMOUNT"]], body: [
                ["0D", "3Y", "900.000,00 EUR"], ["3Y", "5Y", "675.000,00 EUR"], ["5Y", "8Y", "450.000,00 EUR"]
            ]},
            { type: "title", text: "OPERATIONAL RESTRICTIONS" },
            { type: "table", head: [["PRODUCT GROUP", "DERIVATIVES LINE", "MATURITY TERM", "FD LINE: (0 EUR)", "DVP LINE: (0 EUR)"]], body: [
                ["IRS", "3", "2Y", "", ""], ["FX", "", " ", "", ""]
            ]}
        ]},
        { name: "APPROVAL PROCESS DATA", content: [
            { type: "title", text: "APPROVAL PROCESS DATA" },
            { type: "values2", body: [
                [ { value: "Risk C&IB Turkey", name: "Booking Unit Risk Approver (Local):" }, { value: "Risk C&IB Turkey", name: "Financial Program Risk Approver (Global):" } ],
                [ { value: "MARIA SELVA VERNASCA", name: "Global Banker:" }, { value: "Global Banker CIB Spain", name: "Approver Global Banker:" } ]
            ]},
            { type: "values2", body: [[ { value: "", name: "Client Use:" } ]] }
        ]},
        { name: "PASSPORT", content: [
            { type: "title", text: "PASSPORT" },
            { type: "table", head: [["FEATURE", "CAPABILITY", "WORKFLOW"]], body: [
                ["General Validations", 
                    { type: "custom", custom: [{ content: "l", styles: { textColor: "#BDBDBD" } }, { content: "l", styles: { textColor: "#F8CC52" } }, { content: "l", styles: { textColor: "#BDBDBD" } }] },
                    ""
                ],
                ["ST10 - Derivatives Limit Test (Group Level)", 
                    { type: "custom", custom: [{ content: "l", styles: { textColor: "#ffffff" } }, { content: "l", styles: { textColor: "#ffffff" } }, { content: "l", styles: { textColor: "#ffffff" } }] },
                    ""
                ]
            ]}
        ]},
        { name: "LIMIT VALIDATION", content: [
            { type: "title", text: "General Validations" },
            { type: "table", body: [
                ["Clients already included in other lines", { type: "custom", custom: [{ content: "l", styles: { textColor: "#F8CC52" } }] }, "The following clients are already included in other current lines: ES0182002102678"],
                ["Maximum consumption and maturities relationship", { type: "custom", custom: [{ content: "l", styles: { textColor: "#47AD5A" } }] }, "All the maturities in the product restrictions are shorter than the maximum consumption limit"]
            ]}
        ]},
        { name: "VALIDATION PROCESS FLOW", content: [
            { type: "title", text: "VALIDATION PROCESS" },
            { type: "title", text: "ST12 - Booking Unit Risk Analyst Consult" },
            { type: "table", head: [["APPROVER", "TASK", "STATUS", "USER", "START DATE", "END DATE", "RESULT", "COMMENTS"]], body: [
                ["GRM C&IB Spain", "Risk Analyst Advisory", "Not Started", "Jorge", "23/Feb/2026", "", "", ""]
            ]}
        ]},
        { name: "APPROVAL PROCESS FLOW", content: [
            { type: "title", text: "APPROVAL PROCESS" }
        ]}
    ]
};

export const MOCK_DATA_B = {
    components: [
        // 1. LIMIT VISUAL (Should be ignored despite changes)
        { name: "Limit Visual", content: [{ type: "title", text: "LIMIT VISUAL B" }, { type: "values2", body: [[{name: "B", value: "B"}]] }] },
        
        // 2. THIS SECTION IS ONLY IN B (Will show as Added/Green)
        { name: "TEMPORARY SECTION B", content: [{ type: "title", text: "ONLY IN VERSION B" }, { type: "values2", body: [[{name: "Status", value: "Freshly added"}]] }] },
        
        // 3. REGULAR COMPONENTS WITH DATA
        { name: "Line Info", content: [
            { type: "title", text: "LINE INFO" },
            { type: "values2", body: [
                // CHANGED: Start Date
                [ { value: "ESCD26LIN00001050ES", name: "Line Id:" }, { value: "ES", name: "Entific:" }, { value: "20-Feb-2026", name: "Start Date:" }, { value: "Line Gestor Documental", name: "Name:" } ],
                // CHANGED: Currency
                [ { value: "USD", name: "Currency:" }, { value: "28-Feb-2027", name: "End Date:" }, { value: "", name: "Office:" } ]
            ]}
        ]},
        { name: "CLIENT", content: [
            { type: "title", text: "CLIENT" },
            { type: "values2", body: [
                [ { value: "IBERDROLA INMOBILIARIA S.A.", name: "Client:" }, { value: "Customer", name: "Client Type:" } ],
                // CHANGED: Rating
                [ { value: "A+", name: "Internal Rating (Short):" } ]
            ]}
        ]},
        { name: "PRODUCTS", content: [
            { type: "title", text: "PRODUCTS" },
            { type: "values2", body: [
                // CHANGED: DvP Amount
                [ { value: "950.000,00 EUR", name: "Delivery vs Payment (DvP) Amount:" }, { value: "3Y", name: "First Breakclause:" }, { value: "No", name: "ISDA Waiver:" } ],
                [ { value: "800.000,00 EUR", name: "Free Delivery (FD) Amount (Units EUR):" }, { value: "1Y", name: "Breakclause Frequency:" } ]
            ]},
            // CHANGED: Empty to Filled text
            { type: "values2", body: [[ { value: "Extra product info added", name: "Additional Products:" } ]] },
            { type: "title", text: "COUNTERPARTY RISK (DERIVATIVES RISK LINE)" },
            { type: "table", head: [["INIT TERM", "END TERM", "AMOUNT"]], body: [
                ["0D", "3Y", "900.000,00 EUR"], 
                // CHANGED: Value
                ["3Y", "5Y", "999.000,00 EUR"], 
                ["5Y", "8Y", "450.000,00 EUR"],
                // ADDED: New Row
                ["8Y", "10Y", "100.000,00 EUR"]
            ]},
            { type: "title", text: "OPERATIONAL RESTRICTIONS" },
            { type: "table", head: [["PRODUCT GROUP", "DERIVATIVES LINE", "MATURITY TERM", "FD LINE: (0 EUR)", "DVP LINE: (0 EUR)"]], body: [
                ["IRS", "3", "2Y", "", ""], 
                // CHANGED: Added restrictions to FX
                ["FX", "3", "2D", "3", "3"]
            ]}
        ]},
        { name: "APPROVAL PROCESS DATA", content: [
            { type: "title", text: "APPROVAL PROCESS DATA" },
            { type: "values2", body: [
                [ { value: "Risk C&IB Turkey", name: "Booking Unit Risk Approver (Local):" }, { value: "Risk C&IB Turkey", name: "Financial Program Risk Approver (Global):" } ],
                [ { value: "MARIA SELVA VERNASCA", name: "Global Banker:" }, { value: "Global Banker CIB Spain", name: "Approver Global Banker:" } ]
            ]},
            // CHANGED: Filled an empty field
            { type: "values2", body: [[ { value: "Corporate purpose", name: "Client Use:" } ]] }
        ]},
        { name: "PASSPORT", content: [
            { type: "title", text: "PASSPORT" },
            { type: "table", head: [["FEATURE", "CAPABILITY", "WORKFLOW"]], body: [
                ["General Validations", 
                    { type: "custom", custom: [{ content: "l", styles: { textColor: "#BDBDBD" } }, { content: "l", styles: { textColor: "#F8CC52" } }, { content: "l", styles: { textColor: "#BDBDBD" } }] },
                    ""
                ],
                ["ST10 - Derivatives Limit Test (Group Level)", 
                    { type: "custom", custom: [{ content: "l", styles: { textColor: "#ffffff" } }, { content: "l", styles: { textColor: "#ffffff" } }, { content: "l", styles: { textColor: "#ffffff" } }] },
                    // CHANGED: Workflow traffic light from nothing/white to Gray-Yellow-Gray
                    { type: "custom", custom: [{ content: "l", styles: { textColor: "#BDBDBD" } }, { content: "l", styles: { textColor: "#F8CC52" } }, { content: "l", styles: { textColor: "#BDBDBD" } }] }
                ]
            ]}
        ]},
        { name: "LIMIT VALIDATION", content: [
            { type: "title", text: "General Validations" },
            { type: "table", body: [
                // CHANGED: Text value
                ["Clients already included in other lines", { type: "custom", custom: [{ content: "l", styles: { textColor: "#F8CC52" } }] }, "No clients are included in other lines."],
                ["Maximum consumption and maturities relationship", { type: "custom", custom: [{ content: "l", styles: { textColor: "#47AD5A" } }] }, "All the maturities in the product restrictions are shorter than the maximum consumption limit"]
            ]}
        ]},
        { name: "VALIDATION PROCESS FLOW", content: [
            { type: "title", text: "VALIDATION PROCESS" },
            { type: "title", text: "ST12 - Booking Unit Risk Analyst Consult" },
            { type: "table", head: [["APPROVER", "TASK", "STATUS", "USER", "START DATE", "END DATE", "RESULT", "COMMENTS"]], body: [
                // CHANGED: Status
                ["GRM C&IB Spain", "Risk Analyst Advisory", "In Progress", "Jorge", "23/Feb/2026", "", "", ""]
            ]}
        ]},
        { name: "APPROVAL PROCESS FLOW", content: [
            // CHANGED: Title text
            { type: "title", text: "APPROVAL PROCESS (UPDATED)" }
        ]}
    ]
};