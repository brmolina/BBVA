import { LightningElement, api, wire, track } from 'lwc';
import getProduct2 from '@salesforce/apex/DMT_TaxonomyMultipleProducts.getProductsDMT';

export default class ProductSelector extends LightningElement {
    @track products = [];
    @track filteredProducts = [];
    @track isLoading = true;
    allproducts = [];
    recordId;
    isFilteredByParent = false;

    _searchProduct = '';

    @api
    get lineId() {
        return this.recordId;
    }
    set lineId(value) {
        this.recordId = value;
        if (value) {
            this.wiredAllProducts(this.recordId);
        }
    }

    @api
    get searchProduct() {
        return this._searchProduct;
    }
    set searchProduct(value) {
        this._searchProduct = value?.length > 2 ? value : 'emptyFilter';
        this.filterProducts();
    }

    @wire(getProduct2, { recordId: '$recordId' })
    wiredAllProducts({ error, data }) {
        if (data) {
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
                expanded: false
            }));
            this.buildHierarchyFromProducts();
        } else if (error) {
            console.error(error);
        }
    }

    // 🧩 Nueva función: construye la jerarquía a partir del campo Parent_Product__c
    buildHierarchyFromProducts() {
    // 1) Crear mapa único por Id asegurando children en la instancia del mapa
    const productMap = new Map();
    this.allproducts.forEach(prod => {
        // Guardamos la misma instancia en el mapa (clon superficial para evitar mutaciones externas)
        productMap.set(prod.id, {
            ...prod,
            children: [],    // garantizamos que exista children en el nodo del mapa
            __isChild: false // flag temporal
        });
    });

    // 2) Enlazar padres con hijos usando las referencias del mapa (modificando el objeto dentro del mapa)
    this.allproducts.forEach(prod => {
        const parentId = prod.Parent_Product__c;
        if (parentId && productMap.has(parentId)) {
            const parentNode = productMap.get(parentId); // referencia al objeto en el mapa
            const childNode = productMap.get(prod.id);   // referencia al objeto en el mapa

            // Evitar duplicados por si la relación aparece repetida
            if (!parentNode.children.some(c => c.id === childNode.id)) {
                parentNode.children.push(childNode); // modificamos la instancia del mapa
            }

            // marcamos que este nodo es hijo
            childNode.__isChild = true;
        }
    });

    // 3) Seleccionar SOLO los nodos que efectivamente tienen hijos (son padres)
    const parents = Array.from(productMap.values()).filter(node => Array.isArray(node.children) && node.children.length > 0);

    // 4) Ordenar recursivamente por sortOrder (protegemos contra null/undefined)
    const sortRecursive = (nodes) => {
        nodes.sort((a, b) => (Number(a.sortOrder || 0) - Number(b.sortOrder || 0)));
        nodes.forEach(n => {
            if (n.children && n.children.length > 0) {
                sortRecursive(n.children);
            }
        });
    };
    sortRecursive(parents);

    // 5) Limpiar flags internos __isChild
    const cleanRecursive = (nodes) => {
        nodes.forEach(n => {
            delete n.__isChild;
            if (n.children && n.children.length > 0) {
                cleanRecursive(n.children);
            }
        });
    };
    cleanRecursive(parents);

    // 6) Asignar resultado: SOLO padres (cada uno con sus hijos anidados)
    // Hacemos copias superficiales para filteredProducts para evitar compartir referencias directas con this.products
    this.products = parents;
    this.filteredProducts = parents.map(p => ({ ...p, children: p.children.slice() }));
    this.isLoading = false;
}

    filterProducts() {
        const term = this._searchProduct?.toLowerCase() || '';

        const filterRecursive = (node) => {
            const nameMatch =
                node.displayName.toLowerCase().includes(term) ||
                !term ||
                term === ''  || term === 'emptyfilter';
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
            //this.filteredProducts = [updated];
            //this.products = [updated];
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
        // this.updateTreeNode(this.filteredProducts, updated, 'selected');
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
            this.updateTreeNode(this.products, children, 'selected');
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

        const collectSelected = (nodes) => {
            for (let node of nodes) {
                if (node.selected && (!node.children || node.children.length === 0)) {
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

        const firstSelected = this.allproducts.find(p =>
            selectedCodes.includes(p.code)
        );
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
        this.filteredProducts = JSON.parse(JSON.stringify(this.products)); // clonado limpio
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