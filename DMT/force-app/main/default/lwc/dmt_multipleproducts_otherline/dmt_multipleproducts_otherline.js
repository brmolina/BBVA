import { LightningElement, api, wire, track } from 'lwc';
import getProduct2 from '@salesforce/apex/DMT_TaxonomyMultipleProducts.getProductsDMTByContext';

export default class ProductSelector extends LightningElement {
    @track products = [];
    @track filteredProducts = [];
    @track isLoading = true;
    allproducts = [];
    recordId;
    isFilteredByParent = false;

    _searchProduct = '';
    _contextCode = '';

    @api
    get lineId() {
        return this.recordId;
    }
    set lineId(value) {
        this.recordId = value;
    }

    @api
    get searchProduct() {
        return this._searchProduct;
    }
    set searchProduct(value) {
        this._searchProduct = value?.length > 2 ? value : 'emptyFilter';
        this.filterProducts();
    }

    @api
    get contextCode() {
        return this._contextCode;
    }
    set contextCode(value) {
        this._contextCode = value;
        console.log('[dmt_multipleproducts_otherline] contextCode', this._contextCode);
    }

    @wire(getProduct2, { recordId: '$recordId', contextCode: '$_contextCode' })
    wiredAllProducts({ error, data }) {
        if (data) {
            console.log('[dmt_multipleproducts_otherline] products loaded', JSON.stringify(data));
            this.allproducts = data.map(prod => ({
                id: prod.Id,
                code: prod.ProductCode,
                Name: prod.Name,
                DMT_Classification_Level__c: prod.DMT_Classification_Level__c,
                g_global_product_family_id__c: prod.DMT_Product_family__c,
                g_global_product_subfamily_id__c: prod.DMT_Product_Subfamily__c,
                g_global_product_category_id__c: prod.DMT_Product_category__c,
                g_gbl_product_subcategory_id__c: prod.DMT_Product_Subcategory__c,
                g_global_product_id__c: prod.DMT_Global_Product_Id__c,
                Parent_Product__c: prod.Parent_Product__c,
                DMT_Taxonomy_Value__c: prod.DMT_Taxonomy_Value__c,
                taxonomyContextRaw: prod.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val7_name__c,
                taxonomyChildCodes: this.parseChildCodes(prod.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val1_name_c__c),
                sortOrderRaw: prod.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val2_name__c,
                manualIndentRaw: prod.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val3_name__c,
                sortOrder: prod.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val2_name__c
                    ? parseInt(prod.DMT_Taxonomy_Value__r.gf_catalog_atrb_val2_name__c, 10)
                    : 0,
                manualIndent: prod.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val3_name__c
                    ? parseInt(prod.DMT_Taxonomy_Value__r.gf_catalog_atrb_val3_name__c, 10)
                    : 0,
                selected: false,
                children: [],
                displayName: `${prod.Name}`,
                taxValue: `${prod.ProductCode}`,
                disabled: prod.HelpText == 'OP_CONTEXT' && !prod.DMT_Product_Template__c.split(';').includes('TO') ? true : false,
                expanded: false
            }));
            this.buildHierarchyFromProducts();
        } else if (error) {
            console.error('[dmt_multipleproducts_otherline] products error', error);
        }
    }

    parseChildCodes(rawValue) {
        if (!rawValue) {
            return [];
        }

        return rawValue
            .split(',')
            .map(code => code.trim())
            .filter(Boolean);
    }

    isLeafProduct(product) {
        return String(product.sortOrderRaw || '').trim() === '99' &&
            String(product.manualIndentRaw || '').trim().toUpperCase() === 'XX';
    }

    isParentProduct(product) {
        return !this.isLeafProduct(product) && product.taxonomyChildCodes.length > 0;
    }

    matchesCurrentContext(rawValue) {
        if (String(this._contextCode || '').trim() === '') {
            return true;
        }

        const normalized = String(rawValue || '').toUpperCase();
        const context = String(this._contextCode || '').trim().toUpperCase();

        if (context === 'OPP') {
            return normalized.includes('OPP');
        }
        if (context === 'L') {
            return normalized.includes('L');
        }
        // Handle comma-separated tokens: 'LC', 'LNC', 'LC,LNC', etc.
        const tokens = context.split(',').map(t => t.trim()).filter(Boolean);
        if (tokens.length > 0) {
            return tokens.some(t => normalized.includes(t));
        }
        return true;
    }

    cloneTree(nodes) {
        return nodes.map(node => ({
            ...node,
            children: this.cloneTree(node.children || [])
        }));
    }

    buildHierarchyFromProducts() {
        const productsByCode = new Map();
        this.allproducts.forEach(prod => {
            const bucket = productsByCode.get(prod.code) || [];
            bucket.push({ ...prod, children: [] });
            productsByCode.set(prod.code, bucket);
        });

        const parentCandidatesByCode = new Map();
        this.allproducts
            .filter(prod => this.isParentProduct(prod) && this.matchesCurrentContext(prod.taxonomyContextRaw))
            .forEach(parent => {
                const bucket = parentCandidatesByCode.get(parent.code) || [];
                bucket.push(parent);
                parentCandidatesByCode.set(parent.code, bucket);
            });

        const selectedParents = [];
        parentCandidatesByCode.forEach((candidates) => {
            candidates.sort((firstParent, secondParent) => (
                Number(firstParent.sortOrder || 0) - Number(secondParent.sortOrder || 0)
                || String(firstParent.displayName || '').localeCompare(String(secondParent.displayName || ''))
            ));
            selectedParents.push(candidates[0]);
        });

        const parentNodes = selectedParents
            .map(parent => {
                const uniqueChildCodes = [...new Set(parent.taxonomyChildCodes)];
                const children = [];

                uniqueChildCodes.forEach(code => {
                    const candidates = productsByCode.get(code) || [];
                    const leafCandidates = candidates.filter(child => (
                        child.id !== parent.id && this.isLeafProduct(child)
                    ));

                    if (!leafCandidates.length) {
                        return;
                    }

                    leafCandidates.sort((firstChild, secondChild) => (
                        Number(firstChild.sortOrder || 0) - Number(secondChild.sortOrder || 0)
                        || String(firstChild.displayName || '').localeCompare(String(secondChild.displayName || ''))
                    ));

                    children.push({
                        ...leafCandidates[0],
                        children: []
                    });
                });

                return {
                    ...parent,
                    children
                };
            })
            .filter(parent => parent.children.length > 0);

        const sortRecursive = (nodes) => {
            nodes.sort((firstNode, secondNode) => (
                Number(firstNode.sortOrder || 0) - Number(secondNode.sortOrder || 0)
                || String(firstNode.displayName || '').localeCompare(String(secondNode.displayName || ''))
            ));

            nodes.forEach(node => {
                if (node.children?.length) {
                    sortRecursive(node.children);
                }
            });
        };

        sortRecursive(parentNodes);

        this.products = parentNodes;
        this.filteredProducts = this.cloneTree(parentNodes);
        this.isLoading = false;
    }

    filterProducts() {
        const term = this._searchProduct?.toLowerCase() || '';

        const filterRecursive = (node) => {
            const nameMatch =
                node.displayName.toLowerCase().includes(term) ||
                !term ||
                term === '' || term === 'emptyfilter';
            const filteredChildren = node.children?.map(filterRecursive).filter(Boolean) || [];

            if (nameMatch || filteredChildren.length) {
                return {
                    ...node,
                    children: filteredChildren,
                    expanded: node.expanded,
                    selected: node.selected
                };
            }

            return null;
        };

        this.filteredProducts = this.products.map(filterRecursive).filter(Boolean);
    }

    updateSelection(product) {
        const recursiveSelect = (node, selected) => {
            node.selected = selected;
            node.children?.forEach(child => recursiveSelect(child, selected));
        };

        const findAndUpdate = (nodes) => {
            for (let node of nodes) {
                if (node.id === product.id) {
                    recursiveSelect(node, product.selected);
                    return true;
                }
                if (node.children && findAndUpdate(node.children)) {
                    return true;
                }
            }
        };
        findAndUpdate(this.products);
    }

    handleExpand(event) {
        const updated = event.detail.product;
         this.updateTreeNode(this.filteredProducts, updated, 'expanded');
         this.updateTreeNode(this.filteredProducts, updated, 'selected');
         this.updateOtherProduct(this.filteredProducts, updated, 'expanded');
         this.updateOtherProduct(this.filteredProducts, updated, 'selected');

        if (updated.children && updated.children.length > 0) {
            this.isFilteredByParent = true;
        }

        this.updateTreeNode(this.products, updated, 'expanded');
        this.updateTreeNode(this.products, updated, 'selected');
        this.updateOtherProduct(this.products, updated, 'expanded');
        this.updateOtherProduct(this.products, updated, 'selected');
        this.filteredProducts = this.products.filter(node => node.selected);

        if (updated.children && updated.children.length > 0) {
            this.setSelectedRecursive(updated.children, updated.selected);
        }
        this.sendSelection();
    }

    handleCheck(event) {
        const updated = event.detail.product;
        this.updateOtherProduct(this.filteredProducts, updated, 'expanded');
        this.updateOtherProduct(this.filteredProducts, updated, 'selected');
        this.updateTreeNode(this.products, updated, 'selected');
        this.updateOtherProduct(this.products, updated, 'expanded');
        this.updateOtherProduct(this.products, updated, 'selected');
        this.filteredProducts = this.products.filter(node => node.selected);

        if (updated.children && updated.children.length > 0) {
            this.setSelectedRecursive(updated.children, updated.selected);
        }
        this.sendSelection();
    }

    updateTreeNode(nodes, updated, field) {
        for (let node of nodes) {
            if (node.id === updated.id) {
                node[field] = updated[field];
            }
            if (node.children) {
                let childselected = [];
                for (let child of node.children) {
                    if (node.id === updated.id) {
                        child[field] = updated[field];
                    }
                    if (child.id === updated.id) {
                        child[field] = updated[field];
                    }
                    if (child[field]) {
                        childselected.push(child);
                    }
                }
                if (childselected.length == 1) {
                    for (let child of node.children) {
                        if (child.id === childselected[0].id) {
                            child.disabled = true;
                        }
                    }
                } else {
                    node.children.forEach(child => {
                        child.disabled = false;
                    });
                }
            }
        }
    }

    updateOtherProduct(nodes, updated, field) {
        for (let node of nodes) {
            if (node.id !== updated.id) {
                node[field] = false;
                node['maxTerm'] = null;

                if (node.children) {
                    let isChild = false;
                    for (let child of node.children) {
                        if (child.id === updated.id) {
                            isChild = true;
                        }
                        node[field] = isChild;
                    }
                    if (!isChild) {
                        for (let child of node.children) {
                            child[field] = false;
                        }
                    }
                }
            }
        }
    }

    setSelectedRecursive(children, selected) {
        for (let child of children) {
            this.updateTreeNode(this.products, {
                ...child,
                selected
            }, 'selected');
            if (child.children?.length > 0) {
                this.setSelectedRecursive(child.children, selected);
            }
        }
    }

    handleTerm(event) {
        const updated = event.detail.product;
        this.updateTreeNode(this.products, updated, 'maxTerm');
        this.sendSelection();
    }

    sendSelection() {
        let selectedCodes = [];
        let selectedCodesId = [];

        let selectedTerms = [];
        const seenSelectedIds = new Set();

        const collectSelected = (nodes) => {
            for (let node of nodes) {
                if (node.selected && (!node.children || node.children.length === 0) && !seenSelectedIds.has(node.id)) {
                    seenSelectedIds.add(node.id);
                    selectedCodes.push(node?.code);
                    selectedTerms.push(node?.maxTerm);
                    selectedCodesId.push(node?.id);
                }
                if (node.children && node.children.length > 0) {
                    collectSelected(node.children);
                }
            }
        };

        collectSelected(this.products);

        const finalString = selectedCodes.join(';');
        const finalTerms = selectedTerms.join(';');

        const eventPayload = {
            DMT_Line__c: this.lineId,
            line: this.lineId,
            g_global_product_family_id__c: null,
            g_global_product_subfamily_id__c: null,
            g_global_product_category_id__c: null,
            g_gbl_product_subcategory_id__c: null,
            g_global_product_id__c: null,
            selectedCodes: finalString,
            selectedTerms: finalTerms
        };

        // Resolve by id (not code): the catalog has multiple Product2 records sharing the same
        // ProductCode with different Names, so matching by code can silently pick a different
        // duplicate than the one actually linked via DMT_Product__c (productIds, sourced from
        // this same selectedCodesId array). Matching by id keeps Name/parentProductName
        // consistent with whichever record ends up as the real lookup.
        const firstSelected = this.allproducts.find(p => p.id === selectedCodesId[0]);
        console.log('First Selected:', JSON.stringify(firstSelected));
        const hierarchy = [
            'g_global_product_family_id__c',
            'g_global_product_subfamily_id__c',
            'g_global_product_category_id__c',
            'g_gbl_product_subcategory_id__c',
            'g_global_product_id__c'
        ];

        if (firstSelected) {
            for (let i = hierarchy.length - 1; i >= 0; i--) {
                const field = hierarchy[i];
                if (firstSelected[field]) {
                    eventPayload[field] = finalString;
                    eventPayload['endTerm'] = finalTerms;
                    break;
                }
            }
            eventPayload['Name'] = firstSelected?.Name;

            // Surface the child product's own taxonomy value Id so it gets persisted as the
            // Commercial Product.
            eventPayload['DMT_Commercial_Product__c'] = firstSelected?.DMT_Taxonomy_Value__c || null;

            // CIBGLOBALD-3779: surface the parent node's Name too, so it can be persisted as the
            // "Commercial Product Description" alongside the selected child product's code/name.
            const parentNode = this.products.find(parent =>
                (parent.children || []).some(child => child.code === firstSelected.code)
            );
            eventPayload['parentProductName'] = parentNode?.displayName || parentNode?.Name || null;
            // Surface the parent node's taxonomy value Id so it gets persisted as the Global Product.
            eventPayload['DMT_Global_Product__c'] = parentNode?.DMT_Taxonomy_Value__c || null;
        }
        console.log('Event Payload:', JSON.stringify(eventPayload));
        console.log('selectedCodesId:', JSON.stringify(selectedCodesId));

        this.dispatchEvent(new CustomEvent('productstosend', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: { data: eventPayload, selectedCodesId: selectedCodesId }
        }));
    }

    ensureUniqueIds(products) {
        const seenIds = new Map();

        const traverse = (node) => {
            if (!node || typeof node !== 'object') return node;

            if (seenIds.has(node.id)) {
                const count = seenIds.get(node.id) + 1;
                seenIds.set(node.id, count);
                node.id = `${node.id}_${count}_${Math.random().toString(36).substring(2, 6)}`;
            } else {
                seenIds.set(node.id, 1);
            }

            if (Array.isArray(node.children) && node.children.length > 0) {
                node.children = node.children.map(child => traverse({ ...child }));
            }

            return node;
        };

        return products.map(p => traverse({ ...p }));
    }

    handleBack() {
        this.filteredProducts = JSON.parse(JSON.stringify(this.products));
        this.currentParent = null;
        this.isFilteredByParent = false;
        const resetRecursive = (nodes) => {
            nodes.forEach(node => {
                node.selected = false;
                node.expanded = false;
                if (node.children && node.children.length > 0) {
                    resetRecursive(node.children);
                }
            });
        };
        resetRecursive(this.filteredProducts);
        resetRecursive(this.products);

        this.dispatchEvent(new CustomEvent('refreshstate', {
            detail: { showSave: false },
            bubbles: true,
            composed: true
        }));


    }
}