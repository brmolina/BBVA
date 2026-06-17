({ // eslint-disable-line

  //wraps all the initialization functions of the component
  initComponent: function(cmp, event, helper) {
    var useStandard = cmp.get('{!v.useStandard}');
    if (useStandard) {
      var scopeCombo = cmp.find('scopeCombo');
      $A.util.addClass(scopeCombo, 'slds-hide');
    }

    helper.fetchVisions(cmp, event).then(
      $A.getCallback(function() {
        helper.fetchOptions(cmp, event);
      })
    );
  },


  //Promise Execute action against the server
  executeAction: function(cmp, action, callback) {
    return new Promise(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else if (state === 'ERROR') {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject(Error('Error message: ' + errors[0].message));
            }
          } else {
            reject(Error('Unknown error'));
          }
        }
      });
      $A.enqueueAction(action);
    });
  },

  //retrieve visions
  fetchVisions: function(cmp, event) {
    var action = cmp.get('c.getVisions');

    var visionsPromise = this.executeAction(cmp, action);

    return visionsPromise.then(
      $A.getCallback(function(result) {
        var parsedResult = JSON.parse(result);
        cmp.set('{!v.scopeOptions}', parsedResult);
        cmp.find('selectScope').set('v.value', parsedResult[0].value);
      }),
      $A.getCallback(function(error) {
        console.log('fetchVisions promise finished with errors: ' + error.message);
      })
    );
  },

  //retrieve options for the Relationship types
  fetchOptions: function(cmp, event) {
    var action = cmp.get('c.getOptions');
    var multiSelector = cmp.find('my-multi-select');

    var optionsPromise = this.executeAction(cmp, action);

    return optionsPromise.then(
      $A.getCallback(function(result) {
        var parsedResult = JSON.parse(result);

        cmp.set('{!v.nodeTypes}', parsedResult);
        multiSelector.updateOptions(parsedResult);
      }),
      $A.getCallback(function(error) {
        console.log('fetchOptions promise finished with errors: ' + error.message);
      })
    );
  },

  //Retrieves the parents from the account hierarchy
  fetchParentsData: function(cmp, event, recordId) {
    var action = cmp.get('c.fetchParentData');
    var spinner = cmp.find('treeSpinner');
    var vision = cmp.find('selectScope').get('v.value');
    var hierarchyTree = cmp.find('HierarchyTree');
    var useStandard = cmp.get('v.useStandard');
    var accountTypeField = cmp.get('v.accountTypeField');

    action.setParams({
      'useStandard': useStandard,
      'recordId': recordId,
      'vision': vision,
      'accountTypeField': accountTypeField
    });

    var parentsPromise = this.executeAction(cmp, action);

    return parentsPromise.then(
      $A.getCallback(function(result) {
        var parsedResult = JSON.parse(result);
        cmp.set('{!v.treeData}', parsedResult);
      }),
      $A.getCallback(function(error) {
        console.log('fetchParentsData promise finished with errors: ' + error.message);
      })
    );
  },

  //fetch root node using Promises
  fetchRootNode: function(cmp, event, recordId) {
    var action = cmp.get('c.fetchChildData');
    var scope = cmp.find('selectScope').get('v.value');
    var types = cmp.get('v.mySelectedRels');
    var leadLookUp = cmp.get('v.leadLookupField');
    var useStandard = cmp.get('v.useStandard');
    var accountTypeField = cmp.get('v.accountTypeField');

    action.setParams({
      'useStandard': useStandard,
      'addRoot': true,
      'recordId': recordId,
      'scope': scope,
      'types': types,
      'searchKey': '',
      'leadLookupField': leadLookUp,
      'accountTypeField': accountTypeField
    });

    var rootPromise = this.executeAction(cmp, action);

    return rootPromise.then(
      $A.getCallback(function(result) {
        var parsedResult = JSON.parse(result);
        cmp.set('{!v.treeData}', parsedResult);
      }),
      $A.getCallback(function(error) {
        console.log('fetchRootNode promise finished with errors: ' + error.message);
      })
    );
  },

  triggerEventNode: function(cmp, visibleNodeIds) {
    var myEvent = $A.get('e.c:GBL_hierarchyNodeClick');
    var nodeId = cmp.get('v.currentNodeId');
    var vision = cmp.find('selectScope').get('v.value');
    var types = cmp.get('v.mySelectedRels');

    myEvent.setParams({
        'accountId': nodeId,
        'selectedVision': vision,
        'selectedHTypes': types,
        'visibleNodeIds': visibleNodeIds 
    });

    myEvent.fire();
  },

  //initiates the load of the HierarchyTree
  processHierarchyTree: function(cmp, event) {
    var recordId = event.getParam('nodeRecordId');
    var hierarchyMode = cmp.get('{!v.hmValue}');
    var spinner = cmp.find('treeSpinner');

    //$A.util.removeClass(spinner, 'slds-hide');
    if (recordId === undefined) {
      recordId = cmp.get('v.recordId');
    }


    if (hierarchyMode === 'ModeDesc') {
      //process Children
      this.fetchRootNode(cmp, event, recordId).then(function() {
        cmp.set('v.dspOrientation', 'left-to-right');
        displayHierarchy(cmp, event); //eslint-disable-line no-use-before-define

        //$A.util.addClass(spinner, 'slds-hide');
      })
        .catch(function(error) {
          $A.reportError(error);
        });

    } else if (hierarchyMode === 'ModeAsc') {
      //process Parents
      this.fetchParentsData(cmp, event, recordId).then(function() {
        cmp.set('v.dspOrientation', 'bottom-to-top');
        displayHierarchy(cmp, event); //eslint-disable-line no-use-before-define

        //$A.util.addClass(spinner, 'slds-hide');
      })
        .catch(function(error) {
          $A.reportError(error);
        });
    }

    //Function that contains all the functionality regarding the Tree
    //It also contains the sub-functions to display related records.
    //This has to do like this as when a node is clicked (click()) the scope is restricted within this function
    function displayHierarchy(component, event, helper) {
      var dspOrientation = component.get('v.dspOrientation');
      var dspCollapsed = component.get('v.dspCollapsed');
      var treeData = component.get('v.treeData');
      var relTypes = component.get('{!v.nodeTypes}');

      // Set the dimensions and margins of the diagram
      var margin = {top: 20, right: 90, bottom: 30, left: 120};
      var width = 1440;
      var height  = 748;

      var duration = 750;
      var i = 0;
      var root;
      var maxLabelLength = 0;
      var totalNodes = 0;
      var wrapVLength = 200;
      var wrapHLength = 250;
      var wrapLength = (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') ? wrapHLength : wrapVLength;

      // declares a tree layout and assigns the size
      var treemap = d3.tree().size([height, width]); // eslint-disable-line no-undef

      // append the svg object to the body of the page when not existing
      // appends a 'group' element to 'svg'
      // moves the 'group' element to the top left margin
      d3.select(component.find('svgContainerAura').getElement()).selectAll("*").remove(); //eslint-disable-line no-undef

      var zoom = d3.zoom() // eslint-disable-line no-undef
        .scaleExtent([0.3, 2])
        .on('zoom', zoomed); //eslint-disable-line no-use-before-define

      var svg = d3.select(component.find('svgContainerAura').getElement()).append('svg') // eslint-disable-line no-undef
        .attr('width', width)
        .attr('height', height);

      var zoomer = svg.append('rect')
        .attr('width', width)
        .attr('height', height)
        .style('fill', 'none')
        .style('pointer-events', 'all')
        .call(zoom);

      var g = svg.append('g');

      //This is to pad svg by a 150px on the left hand side
      zoomer.call(zoom.transform, d3.zoomIdentity.translate(150, 0)); //eslint-disable-line no-undef

      function zoomed() {
        //The zoom and panning is affecting G element which is a child of SVG
        g.attr('transform', d3.event.transform); //eslint-disable-line no-undef
      }

      // Assigns parent, children, height, depth
      root = d3.hierarchy(treeData, function(d) { // eslint-disable-line no-undef
        return d.children;
      });
      if (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') {
        root.x0 = height / 2;
        root.y0 = 0;
      } else if (dspOrientation === 'top-to-bottom' || dspOrientation === 'bottom-to-top') {
        root.x0 = 0;
        root.y0 = 0;
      }

      // Collapse the node and all it's children
      function collapse(d) {
        if (d.children) {
          d._children = d.children;
          d._children.forEach(collapse);
          d.children = null;
        }
      }

      // Collapse after the second level
      if (!$A.util.isUndefined(root.children) && (dspCollapsed === true)) {
        root.children.forEach(collapse);
      }

      update(root, helper); //eslint-disable-line no-use-before-define

      // A recursive helper function for performing some setup by walking through all nodes
      function visit(parent, visitFn, childrenFn) {
        if (!parent) {
          return;
        }

        visitFn(parent);

        var children = childrenFn(parent);
        if (children) {
          var count = children.length;
          for (var x = 0; x < count; x++) {
            visit(children[x], visitFn, childrenFn);
          }
        }
      }

      //wraping function used to format node text appropriately when too long
      function wrap(text, maxWidth) {
        text.each(function() {

          var breakChars = ['&', '-'];
          var text = d3.select(this); //eslint-disable-line no-undef
          var textContent = text.text();
          var spanContent;

          breakChars.forEach(function(char) {
            // Add a space after each break char for the function to use to determine line breaks
            textContent = textContent.replace(char, char + ' ');
          });

          var words = textContent.split(/\s+/).reverse();
          var word;
          var line = [];
          var lineNumber = 0;
          var lineHeight = 1.1; // ems
          var x = text.attr('x');
          var y = text.attr('y');
          var dy = parseFloat(text.attr('dy') || 0);
          var tspan = text.text(null).append('tspan').attr('x', x).attr('y', y).attr('dy', dy + 'em');

          while (word = words.pop()) {
            line.push(word);
            tspan.text(line.join(' '));
            if (tspan.node().getComputedTextLength() > maxWidth) {
              line.pop();
              spanContent = line.join(' ');
              breakChars.forEach(function(char) { //eslint-disable-line no-loop-func
                // Remove spaces trailing breakChars that were added above
                spanContent = spanContent.replace(char + ' ', char);
              });
              tspan.text(spanContent);
              line = [ word ];
              tspan = text.append('tspan').attr('x', x).attr('y', y).attr('dy', ++lineNumber * lineHeight + dy + 'em').text(word);
            }
          }
        });
      }

      // color a node properly
      function colorNode(d) { //eslint-disable-line complexity
        var color20 = d3.schemeCategory20; //eslint-disable-line no-undef
        var result = color20[0];

        relTypes.forEach(function(relType) {
          if (relType.value === d.data.type) {
            result = color20[relType.colorCodeD3];
          }
        });
        return result;
      }

      //Main function in charge of refresh the structure visually every time there is a change in it
      function update(source, helper) { //eslint-disable-line complexity
        // Assigns the x and y position for the nodes
        if (dspOrientation === 'left-to-right') {
          // Compute the new height, function counts total children of root node and sets tree height accordingly.
          // This prevents the layout looking squashed when new nodes are made visible or looking sparse when nodes are removed
          // This makes the layout more consistent.

          var levelWidth = [ 1 ];
          var childCount = function(level, n) {
            if (n.children && n.children.length > 0) {
              if (levelWidth.length <= level + 1) {
                levelWidth.push(0);
              }
              levelWidth[level + 1] += n.children.length;
              n.children.forEach(function(d) {
                childCount(level + 1, d);
              });
            }
          };
          childCount(0, root);
          var newHeight = d3.max(levelWidth) * 50; //eslint-disable-line no-undef
          treemap = d3.tree().size([newHeight, width]); //eslint-disable-line no-undef
        }

        treeData = treemap(root);

        // Compute the new tree layout.
        var nodes = treeData.descendants();
        var links = treeData.descendants().slice(1);

        // Call visit function to establish maxLabelLength
        visit(treeData, function(d) {
          totalNodes++;
          maxLabelLength = Math.max(d.data.labelExtended.length, maxLabelLength);

        }, function(d) {
          return d.children && d.children.length > 0 ? d.children : null;
        });

        // Normalize for fixed-depth.
        if (dspOrientation === 'left-to-right'  || dspOrientation === 'right-to-left') {
          //ADJUST FOR HORIZONTAL NODE SPACING
          nodes.forEach(function(d) {
            d.y = (d.depth * (maxLabelLength * 7));
          });
        } else if (dspOrientation === 'bottom-to-top' || dspOrientation === 'top-to-bottom') {
          //ADJUST FOR VERTICAL NODE SPACING
          var incremental = 180; //height/(treeData.height + 1);	//height to increment per level
          //nodes.forEach(function(d){ d.y = (height+margin.top) - (incremental*(d.depth+1))});
          nodes.forEach(function(d) {
            d.y = margin.top + (incremental * d.height);
          });
        }

        // ****************** Nodes section ***************************

        // Update the nodes...
        var node = g.selectAll('g.node')
          .data(nodes, function(d) {
            return d.id || (d.id = ++i);
          });

        // Enter any new nodes at the parent's previous position.
        var nodeEnter = node.enter().append('g')
          .attr('class', 'node')
          .attr('transform', function(d) {
            if (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') {
              return 'translate(' + source.y0 + ',' + source.x0 + ')';
            } else if (dspOrientation === 'top-to-bottom' || dspOrientation === 'bottom-to-top') {
              return 'translate(' + source.x0 + ',' + source.y0 + ')';
            }
          });

        // Add Circle for the nodes
        nodeEnter.append('circle')
          .attr('class', 'node')
          .attr('r', 1e-6)
          .style('fill', colorNode)
          .on('click', click); //eslint-disable-line no-use-before-define

        // Add labels for the nodes with hyperlinks to the corresponding url
        if (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') {
          nodeEnter.append('a')
            .attr('xlink:href', function(d) {
              return d.data.hRef;
            })
            .append('text')
            .attr('x', function(d) {
              return d.children || d._children ? -15 : 15;
            })
            .attr('dy', '.35em')
            .attr('class', 'nodeText')
            .attr('text-anchor', function(d) {
              return d.children || d._children ? 'end' : 'start';
            })
            .text(function(d) {
              return d.data.labelExtended;
            })
            .call(wrap, wrapLength);

        } else if (dspOrientation === 'top-to-bottom' || dspOrientation === 'bottom-to-top') {
          nodeEnter.append('a')
            .attr('xlink:href', function(d) {
              return d.data.hRef;
            })
            .append('text')
            .attr('x', 15)
            .attr('dy', '.35em')
            .attr('class', 'nodeText')
            .attr('text-anchor', 'start')
            .text(function(d) {
              return d.data.labelExtended;
            })
            .call(wrap, wrapLength);
        }

        if (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') {
          node.select('text')
            .attr('x', function(d) {
              return d.children || d._children ? -15 : 15;
            })
            .attr('text-anchor', function(d) {
              return d.children || d._children ? 'end' : 'start';
            })
            .text(function(d) {
              return d.data.labelExtended;
            })
            .call(wrap, wrapLength);
        } else if (dspOrientation === 'top-to-bottom' || dspOrientation === 'bottom-to-top') {
          node.select('text')
            .attr('x', 15)
            .attr('text-anchor', 'start')
            .text(function(d) {
              return d.data.labelExtended;
            })
            .call(wrap, wrapLength);
        }

        // Change the circle fill depending on whether it has children and is collapsed
        node.select('circle.nodeCircle')
          .attr('r', 4.5)
          .style('fill', colorNode);

        // UPDATE
        var nodeUpdate = nodeEnter.merge(node);

        // Transition to the proper position for the node
        nodeUpdate.transition()
          .duration(duration)
          .attr('transform', function(d) {
            if (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') {
              return 'translate(' + d.y + ',' + d.x + ')';
            } else if (dspOrientation === 'top-to-bottom' || dspOrientation === 'bottom-to-top') {
              return 'translate(' + d.x + ',' + d.y + ')';
            }
          });

        // Update the node attributes and style
        nodeUpdate.select('circle.node')
          .attr('r', 10)
          .style('fill', colorNode)
          .attr('cursor', 'pointer');


        // Remove any exiting nodes
        var nodeExit = node.exit().transition()
          .duration(duration)
          .attr('transform', function(d) {
            if (dspOrientation === 'left-to-right') {
              return 'translate(' + source.y + ',' + source.x + ')';
            } else if (dspOrientation === 'right-to-left') {
              return 'translate(' + d.y + ',' + d.x + ')';
            } else if (dspOrientation === 'top-to-bottom') {
              return 'translate(' + source.x + ',' + source.y + ')';
            } else if (dspOrientation === 'bottom-to-top') {
              return 'translate(' + source.x + ',' + source.y + ')';
            }
          })
          .remove();

        // On exit reduce the node circles size to 0
        nodeExit.select('circle')
          .attr('r', 1e-6);

        // On exit reduce the opacity of text labels
        nodeExit.select('text')
          .style('fill-opacity', 1e-6);

        // ****************** links section ***************************

        // Update the links...
        var link = g.selectAll('path.link')
          .data(links, function(d) {
            return d.id;
          });

        // Enter any new links at the parent's previous position.
        var linkEnter = link.enter().insert('path', 'g')
          .attr('class', 'link')
          .attr('d', function(d) {
            var o;
            if (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') {
              o = {x: source.x0, y: source.y0};
            } else if (dspOrientation === 'top-to-bottom' || dspOrientation === 'bottom-to-top') {
              o = {y: source.y0, x: source.x0};
            }

            return diagonal(o, o); //eslint-disable-line no-use-before-define
          });

        // UPDATE
        var linkUpdate = linkEnter.merge(link);

        // Transition back to the parent element position
        linkUpdate.transition()
          .duration(duration)
          .attr('d', function(d) {
            return diagonal(d, d.parent); //eslint-disable-line no-use-before-define
          });

        // Remove any exiting links
        var linkExit = link.exit().transition()
          .duration(duration)
          .attr('d', function(d) {
            var o = {x: source.x, y: source.y};
            return diagonal(o, o); //eslint-disable-line no-use-before-define
          })
          .remove();

        // Store the old positions for transition.
        nodes.forEach(function(d) {
          d.x0 = d.x;
          d.y0 = d.y;
        });

        // Creates a curved (diagonal) path from parent to the child nodes
        function diagonal(s, d) {
          var path;

          if (dspOrientation === 'left-to-right' || dspOrientation === 'right-to-left') {
            path = `M ${s.y} ${s.x}
                    C ${(s.y + d.y) / 2} ${s.x},
                        ${(s.y + d.y) / 2} ${d.x},
                            ${d.y} ${d.x}`;
          } else if (dspOrientation === 'top-to-bottom') {
            path = `M ${s.x} ${s.y}
                    C ${(s.x + d.x) / 2} ${s.y},
                        ${(s.x + d.x) / 2} ${d.y},
                            ${d.x} ${d.y}`;
          } else if (dspOrientation === 'bottom-to-top') {
            path = `M ${s.x} ${s.y}
                    C ${s.x} ${(s.y + d.y) / 2},
                        ${d.x} ${(s.y + d.y) / 2},
                            ${d.x} ${d.y}`;
          }

          return path;
        }

        // Fire event onClick
        function click(d) {
          //VISUAL REFRESH
          //Only recover node children when recovering hierarchy children as Parents are recovered all at once
          cmp.set('v.currentNodeId', d.data.name);
          if (dspOrientation === 'left-to-right'  || dspOrientation === 'right-to-left') {
            clickNode4Childs(d); //eslint-disable-line no-use-before-define
          } else if (dspOrientation === 'top-to-bottom' || dspOrientation === 'bottom-to-top') {
            clickNode4Parents(d); //eslint-disable-line no-use-before-define
          }
        }
      }

      function clickNode4Parents(d) {
        d = toggleNode(d); //eslint-disable-line no-use-before-define
        update(d);

        //centerNode(d);
      }

      //taken out from click because otherwise requires another click for the Promise response to be executed, wired behavior
      function clickNode4Childs(d) {
        //var treeSpinner = component.find('treeSpinner');
        //$A.util.removeClass(treeSpinner, 'slds-hide');

        if ((typeof d.children === 'undefined') && (typeof d._children === 'undefined')) {
          //if the node has no children, retrieve them from server and update the node with the childs
          fetchChildsData(component, event, d).then(function(result) { //eslint-disable-line no-use-before-define
            var childArray = [];

            manageRelatedChilds(result); //eslint-disable-line no-use-before-define

            result.forEach(function(child) {
              var obj = d3.hierarchy(child); //eslint-disable-line no-undef
              obj.data.parent = d.name;
              obj.depth = d.depth + 1;
              obj.parent = d;
              obj.name = child.name;
              obj.label = child.label;
              obj.type = child.type;
              obj.objectName = child.objName;
              obj.objectId = child.objectId;
              childArray.push(obj);
            });
            d._children = childArray;

            //refresh and update here as it must be executed within the Promise
            if (d._children.length > 0) {
              d = toggleNode(d); //eslint-disable-line no-use-before-define
              update(d);
            } else {
              //This means a server has been made so don't repeat it in the future
              d._children = null;
              d.children = null;
            }
            centerNode(d); //eslint-disable-line no-use-before-define

            //$A.util.addClass(treeSpinner, 'slds-hide');
          });
        } else if (d.children !== null || d._children !== null) {
          //if the node has childrem, then allow open/close the node
          d = toggleNode(d); //eslint-disable-line no-use-before-define
          update(d);
          centerNode(d); //eslint-disable-line no-use-before-define

          //$A.util.addClass(spinner, 'slds-hide');
        } else {
          //if no children, then just remove the spinner
          //$A.util.addClass(spinner, 'slds-hide');
          centerNode(d); //eslint-disable-line no-use-before-define
        }

      }

      //function to toggle between displaying/hidding  childs
      function toggleNode(d) {
        if (d.children) {
          d._children = d.children;
          d.children = null;
        } else {
          d.children = d._children;
          d._children = null;
        }
        return d;

      }

      //function to center the svg in the node when clicked
      function centerNode(d) {
        var viewerWidth = component.find('svgContainerAura').getElement().offsetWidth;
        var viewerHeight = component.find('svgContainerAura').getElement().offsetHeight;

        var t = d3.zoomTransform(zoomer.node()); //eslint-disable-line no-undef
        var x = d.y0;
        var y = d.x0;

        x = -x * t.k + viewerWidth / 2;
        y = -y * t.k + viewerHeight / 2;

        g.transition()
          .duration(500)
          .attr('transform', 'translate(' + x + ',' + y + ')scale(' + t.k + ')')
          .on('end', function() {
            zoomer.call(zoom.transform, d3.zoomIdentity.translate(x, y).scale(t.k)); //eslint-disable-line no-undef
          });
      }

      //function to wrap the related childs
      function manageRelatedChilds(d) {
        var childs = [];

        if (d.children) {
          childs = d.children;
        } else if (d._children) {
          childs = d._children;
        } else {
          childs = d;
        }
      }

      //calls server for childs of the current node, returning a promise. when callback, child array is returned
      function fetchChildsData(component, evt, node) {
        var action = component.get('c.fetchChildData');
        var scope = component.find('selectScope').get('v.value');
        var selValues = component.get('v.mySelectedRels');
        var leadLookUp = cmp.get('v.leadLookupField');
        var useStandard = cmp.get('v.useStandard');
        var accountTypeField = cmp.get('v.accountTypeField');

        action.setParams({
          'useStandard': useStandard,
          'addRoot': false,
          'recordId': node.data.name,
          'scope': scope,
          'types': selValues,
          'searchKey': '',
          'leadLookupField': leadLookUp,
          'accountTypeField': accountTypeField
        });

        var childPromise = new Promise(function(resolve, reject) {
          action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
              var result = JSON.parse(response.getReturnValue());
              resolve(result);

            } else if (response.getState() === 'ERROR') {
              reject(result);
            }
          });
        });
        $A.enqueueAction(action);
        return childPromise;
      }

      //sample asynch function for testing
      function sampleAsyncFunction() {
        //var defer = $.Deferred();

        return new Promise(function(resolve, reject) {
          setTimeout(function() {
            var result = 3 * 2;
            console.log('individual:', result);

            // resolve the promise with our result
            resolve(result);
          }, Math.floor(Math.random() * 500) + 500);

        });
      }
    }
  },
  
  getVisibleNodeIds: function(component) {
    const treeData = component.get("v.treeData");
    if (!treeData) return [];
    const ids = [];

    function collectIds(node) {
        if (node.Id) ids.push(node.Id);
        if (node.children) node.children.forEach(collectIds);
    }
    collectIds(treeData);
    return ids;
}

});