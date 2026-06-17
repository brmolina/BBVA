({
    init: function(cmp) {
        var listRichText = cmp.find("listRichText");
        listRichText.set("v.value", "<ol> <li><p>Taking deposits and other repayable funds.</p></li> <li><p>Lending including, inter alia: consumer credit, credit agreements relating to immovable property, factoring, with or without recourse, financing of commercial transactions (including forfeiting).</p></li> <li><p>Financial leasing.</p></li> <li><p>Guarantees and commitments.</p></li> <li><p>Trading for own account or for account of customers in any of the following: <ul> <li><p>(a) money market instruments (cheques, bills, certificates of deposit, etc);</p></li> <li><p>(b) foreign exchange;</p></li> <li><p>(c) financial futures and options;</p></li> <li><p>(d) exchange and interest-rate instruments;</p></li> <li><p>(e) transferable securities.</p></li> </ul> </p></li> <li><p>Participation in securities issues and the provision of services relating to such issues.</p></li> <li><p>Money broking.</p></li> <li><p>Any Other services or activity involving maturity transformation, liquidity transformation, leverage or credit risk transfer.</p></li> </ol>");
    },
	handleOnCancel: function(cmp, event, helper) {
        helper.handleClose(cmp, event, helper);
    }
})