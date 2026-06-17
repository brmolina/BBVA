/* eslint-disable */
/*! jQuery v3.2.1 | (c) JS Foundation and other contributors | jquery.org/license */
!(function(a, b) { // NOSONAR
  'use strict'; typeof module === 'object' && typeof module.exports === 'object' ? module.exports = a.document ? b(a, !0) : function(a) { // NOSONAR
    if (!a.document) { // NOSONAR
      throw new Error('jQuery requires a window with a document'); // NOSONAR
    } return b(a); // NOSONAR
  } : b(a); // NOSONAR
}(typeof window !== 'undefined' ? window : this, function(a, b) { // NOSONAR
  'use strict'; var c = [], d = a.document, e = Object.getPrototypeOf, f = c.slice, g = c.concat, h = c.push, i = c.indexOf, j = {}, k = j.toString, l = j.hasOwnProperty, m = l.toString, n = m.call(Object), o = {}; function p(a, b) { // NOSONAR
    b = b || d; var c = b.createElement('script'); c.text = a, b.head.appendChild(c).parentNode.removeChild(c); // NOSONAR
  } var q = '3.2.1', r = function(a, b) { // NOSONAR
      return new r.fn.init(a, b); // NOSONAR
    }, s = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, t = /^-ms-/, u = /-([a-z])/g, v = function(a, b) { // NOSONAR
      return b.toUpperCase(); // NOSONAR
    }; r.fn = r.prototype = {jquery: q, constructor: r, length: 0, toArray: function() { // NOSONAR
    return f.call(this); // NOSONAR
  }, get: function(a) { // NOSONAR
    return a == null ? f.call(this) : a < 0 ? this[a + this.length] : this[a]; // NOSONAR
  }, pushStack: function(a) { // NOSONAR
    var b = r.merge(this.constructor(), a); return b.prevObject = this, b; // NOSONAR
  }, each: function(a) { // NOSONAR
    return r.each(this, a); // NOSONAR
  }, map: function(a) { // NOSONAR
    return this.pushStack(r.map(this, function(b, c) { // NOSONAR
      return a.call(b, c, b); // NOSONAR
    })); // NOSONAR
  }, slice: function() { // NOSONAR
    return this.pushStack(f.apply(this, arguments)); // NOSONAR
  }, first: function() { // NOSONAR
    return this.eq(0); // NOSONAR
  }, last: function() { // NOSONAR
    return this.eq(-1); // NOSONAR
  }, eq: function(a) { // NOSONAR
    var b = this.length, c = +a + (a < 0 ? b : 0); return this.pushStack(c >= 0 && c < b ? [ this[c] ] : []); // NOSONAR
  }, end: function() { // NOSONAR
    return this.prevObject || this.constructor(); // NOSONAR
  }, push: h, sort: c.sort, splice: c.splice}, r.extend = r.fn.extend = function() { // NOSONAR
    var a, b, c, d, e, f, g = arguments[0] || {}, h = 1, i = arguments.length, j = !1; for (typeof g === 'boolean' && (j = g, g = arguments[h] || {}, h++), typeof g === 'object' || r.isFunction(g) || (g = {}), h === i && (g = this, h--); h < i; h++) { // NOSONAR
      if ((a = arguments[h]) != null) { // NOSONAR
        for (b in a) { // NOSONAR
          c = g[b], d = a[b], g !== d && (j && d && (r.isPlainObject(d) || (e = Array.isArray(d))) ? (e ? (e = !1, f = c && Array.isArray(c) ? c : []) : f = c && r.isPlainObject(c) ? c : {}, g[b] = r.extend(j, f, d)) : void 0 !== d && (g[b] = d)); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return g; // NOSONAR
  }, r.extend({expando: 'jQuery' + (q + Math.random()).replace(/\D/g, ''), isReady: !0, error: function(a) { // NOSONAR
    throw new Error(a); // NOSONAR
  }, noop: function() {}, isFunction: function(a) { // NOSONAR
    return r.type(a) === 'function'; // NOSONAR
  }, isWindow: function(a) { // NOSONAR
    return a != null && a === a.window; // NOSONAR
  }, isNumeric: function(a) { // NOSONAR
    var b = r.type(a); return (b === 'number' || b === 'string') && !isNaN(a - parseFloat(a)); // NOSONAR
  }, isPlainObject: function(a) { // NOSONAR
    var b, c; return !(!a || k.call(a) !== '[object Object]') && (!(b = e(a)) || (c = l.call(b, 'constructor') && b.constructor, typeof c === 'function' && m.call(c) === n)); // NOSONAR
  }, isEmptyObject: function(a) { // NOSONAR
    var b; for (b in a) { // NOSONAR
      return !1; // NOSONAR
    } return !0; // NOSONAR
  }, type: function(a) { // NOSONAR
    return a == null ? a + '' : typeof a === 'object' || typeof a === 'function' ? j[k.call(a)] || 'object' : typeof a; // NOSONAR
  }, globalEval: function(a) { // NOSONAR
    p(a); // NOSONAR
  }, camelCase: function(a) { // NOSONAR
    return a.replace(t, 'ms-').replace(u, v); // NOSONAR
  }, each: function(a, b) { // NOSONAR
    var c, d = 0; if (w(a)) { // NOSONAR
      for (c = a.length; d < c; d++) { // NOSONAR
        if (b.call(a[d], d, a[d]) === !1) { // NOSONAR
          break; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      for (d in a) { // NOSONAR
        if (b.call(a[d], d, a[d]) === !1) { // NOSONAR
          break; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return a; // NOSONAR
  }, trim: function(a) { // NOSONAR
    return a == null ? '' : (a + '').replace(s, ''); // NOSONAR
  }, makeArray: function(a, b) { // NOSONAR
    var c = b || []; return a != null && (w(Object(a)) ? r.merge(c, typeof a === 'string' ? [ a ] : a) : h.call(c, a)), c; // NOSONAR
  }, inArray: function(a, b, c) { // NOSONAR
    return b == null ? -1 : i.call(b, a, c); // NOSONAR
  }, merge: function(a, b) { // NOSONAR
    for (var c = +b.length, d = 0, e = a.length; d < c; d++) { // NOSONAR
      a[e++] = b[d]; // NOSONAR
    } return a.length = e, a; // NOSONAR
  }, grep: function(a, b, c) { // NOSONAR
    for (var d, e = [], f = 0, g = a.length, h = !c; f < g; f++) { // NOSONAR
      d = !b(a[f], f), d !== h && e.push(a[f]); // NOSONAR
    } return e; // NOSONAR
  }, map: function(a, b, c) { // NOSONAR
    var d, e, f = 0, h = []; if (w(a)) { // NOSONAR
      for (d = a.length; f < d; f++) { // NOSONAR
        e = b(a[f], f, c), e != null && h.push(e); // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      for (f in a) { // NOSONAR
        e = b(a[f], f, c), e != null && h.push(e); // NOSONAR
      } // NOSONAR
    } return g.apply([], h); // NOSONAR
  }, guid: 1, proxy: function(a, b) { // NOSONAR
    var c, d, e; if (typeof b === 'string' && (c = a[b], b = a, a = c), r.isFunction(a)) { // NOSONAR
      return d = f.call(arguments, 2), e = function() { // NOSONAR
        return a.apply(b || this, d.concat(f.call(arguments))); // NOSONAR
      }, e.guid = a.guid = a.guid || r.guid++, e; // NOSONAR
    } // NOSONAR
  }, now: Date.now, support: o}), typeof Symbol === 'function' && (r.fn[Symbol.iterator] = c[Symbol.iterator]), r.each('Boolean Number String Function Array Date RegExp Object Error Symbol'.split(' '), function(a, b) { // NOSONAR
    j['[object ' + b + ']'] = b.toLowerCase(); // NOSONAR
  }); function w(a) { // NOSONAR
    var b = !!a && 'length' in a && a.length, c = r.type(a); return c !== 'function' && !r.isWindow(a) && (c === 'array' || b === 0 || typeof b === 'number' && b > 0 && b - 1 in a); // NOSONAR
  } var x = (function(a) { // NOSONAR
    var b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u = 'sizzle' + 1 * new Date, v = a.document, w = 0, x = 0, y = ha(), z = ha(), A = ha(), B = function(a, b) { // NOSONAR
        return a === b && (l = !0), 0; // NOSONAR
      }, C = {}.hasOwnProperty, D = [], E = D.pop, F = D.push, G = D.push, H = D.slice, I = function(a, b) { // NOSONAR
        for (var c = 0, d = a.length; c < d; c++) { // NOSONAR
          if (a[c] === b) { // NOSONAR
            return c; // NOSONAR
          } // NOSONAR
        } return -1; // NOSONAR
      }, J = 'checked|selected|async|autofocus|autoplay|controls|defer|disabled|hidden|ismap|loop|multiple|open|readonly|required|scoped', K = '[\\x20\\t\\r\\n\\f]', L = '(?:\\\\.|[\\w-]|[^\0-\\xa0])+', M = '\\[' + K + '*(' + L + ')(?:' + K + '*([*^$|!~]?=)' + K + '*(?:\'((?:\\\\.|[^\\\\\'])*)\'|"((?:\\\\.|[^\\\\"])*)"|(' + L + '))|)' + K + '*\\]', N = ':(' + L + ')(?:\\(((\'((?:\\\\.|[^\\\\\'])*)\'|"((?:\\\\.|[^\\\\"])*)")|((?:\\\\.|[^\\\\()[\\]]|' + M + ')*)|.*)\\)|)', O = new RegExp(K + '+', 'g'), P = new RegExp('^' + K + '+|((?:^|[^\\\\])(?:\\\\.)*)' + K + '+$', 'g'), Q = new RegExp('^' + K + '*,' + K + '*'), R = new RegExp('^' + K + '*([>+~]|' + K + ')' + K + '*'), S = new RegExp('=' + K + '*([^\\]\'"]*?)' + K + '*\\]', 'g'), T = new RegExp(N), U = new RegExp('^' + L + '$'), V = {ID: new RegExp('^#(' + L + ')'), CLASS: new RegExp('^\\.(' + L + ')'), TAG: new RegExp('^(' + L + '|[*])'), ATTR: new RegExp('^' + M), PSEUDO: new RegExp('^' + N), CHILD: new RegExp('^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\(' + K + '*(even|odd|(([+-]|)(\\d*)n|)' + K + '*(?:([+-]|)' + K + '*(\\d+)|))' + K + '*\\)|)', 'i'), bool: new RegExp('^(?:' + J + ')$', 'i'), needsContext: new RegExp('^' + K + '*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\(' + K + '*((?:-\\d)?\\d*)' + K + '*\\)|)(?=[^-]|$)', 'i')}, W = /^(?:input|select|textarea|button)$/i, X = /^h\d$/i, Y = /^[^{]+\{\s*\[native \w/, Z = /^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/, $ = /[+~]/, _ = new RegExp('\\\\([\\da-f]{1,6}' + K + '?|(' + K + ')|.)', 'ig'), aa = function(a, b, c) { // NOSONAR
        var d = '0x' + b - 65536; return d !== d || c ? b : d < 0 ? String.fromCharCode(d + 65536) : String.fromCharCode(d >> 10 | 55296, 1023 & d | 56320); // NOSONAR
      }, ba = /([\0-\x1f\x7f]|^-?\d)|^-$|[^\0-\x1f\x7f-\uFFFF\w-]/g, ca = function(a, b) { // NOSONAR
        return b ? a === '\0' ? '\ufffd' : a.slice(0, -1) + '\\' + a.charCodeAt(a.length - 1).toString(16) + ' ' : '\\' + a; // NOSONAR
      }, da = function() { // NOSONAR
        m(); // NOSONAR
      }, ea = ta(function(a) { // NOSONAR
        return a.disabled === !0 && ('form' in a || 'label' in a); // NOSONAR
      }, {dir: 'parentNode', next: 'legend'}); try { // NOSONAR
      G.apply(D = H.call(v.childNodes), v.childNodes), D[v.childNodes.length].nodeType; // NOSONAR
    } catch (fa) { // NOSONAR
      G = {apply: D.length ? function(a, b) { // NOSONAR
        F.apply(a, H.call(b)); // NOSONAR
      } : function(a, b) { // NOSONAR
        var c = a.length, d = 0; while (a[c++] = b[d++]) { // NOSONAR
 // NOSONAR
        }a.length = c - 1; // NOSONAR
      }}; // NOSONAR
    } function ga(a, b, d, e) { // NOSONAR
      var f, h, j, k, l, o, r, s = b && b.ownerDocument, w = b ? b.nodeType : 9; if (d = d || [], typeof a !== 'string' || !a || w !== 1 && w !== 9 && w !== 11) { // NOSONAR
        return d; // NOSONAR
      } if (!e && ((b ? b.ownerDocument || b : v) !== n && m(b), b = b || n, p)) { // NOSONAR
        if (w !== 11 && (l = Z.exec(a))) { // NOSONAR
          if (f = l[1]) { // NOSONAR
            if (w === 9) { // NOSONAR
              if (!(j = b.getElementById(f))) { // NOSONAR
                return d; // NOSONAR
              } if (j.id === f) { // NOSONAR
                return d.push(j), d; // NOSONAR
              } // NOSONAR
            } else if (s && (j = s.getElementById(f)) && t(b, j) && j.id === f) { // NOSONAR
              return d.push(j), d; // NOSONAR
            } // NOSONAR
          } else { // NOSONAR
            if (l[2]) { // NOSONAR
              return G.apply(d, b.getElementsByTagName(a)), d; // NOSONAR
            } if ((f = l[3]) && c.getElementsByClassName && b.getElementsByClassName) { // NOSONAR
              return G.apply(d, b.getElementsByClassName(f)), d; // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } if (c.qsa && !A[a + ' '] && (!q || !q.test(a))) { // NOSONAR
          if (w !== 1) { // NOSONAR
            s = b, r = a; // NOSONAR
          } else if (b.nodeName.toLowerCase() !== 'object') { // NOSONAR
            (k = b.getAttribute('id')) ? k = k.replace(ba, ca) : b.setAttribute('id', k = u), o = g(a), h = o.length; while (h--) { // NOSONAR
              o[h] = '#' + k + ' ' + sa(o[h]); // NOSONAR
            }r = o.join(','), s = $.test(a) && qa(b.parentNode) || b; // NOSONAR
          } if (r) { // NOSONAR
            try { // NOSONAR
              return G.apply(d, s.querySelectorAll(r)), d; // NOSONAR
            } catch (x) {} finally { // NOSONAR
              k === u && b.removeAttribute('id'); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return i(a.replace(P, '$1'), b, d, e); // NOSONAR
    } function ha() { // NOSONAR
      var a = []; function b(c, e) { // NOSONAR
        return a.push(c + ' ') > d.cacheLength && delete b[a.shift()], b[c + ' '] = e; // NOSONAR
      } return b; // NOSONAR
    } function ia(a) { // NOSONAR
      return a[u] = !0, a; // NOSONAR
    } function ja(a) { // NOSONAR
      var b = n.createElement('fieldset'); try { // NOSONAR
        return !!a(b); // NOSONAR
      } catch (c) { // NOSONAR
        return !1; // NOSONAR
      } finally { // NOSONAR
        b.parentNode && b.parentNode.removeChild(b), b = null; // NOSONAR
      } // NOSONAR
    } function ka(a, b) { // NOSONAR
      var c = a.split('|'), e = c.length; while (e--) { // NOSONAR
        d.attrHandle[c[e]] = b; // NOSONAR
      } // NOSONAR
    } function la(a, b) { // NOSONAR
      var c = b && a, d = c && a.nodeType === 1 && b.nodeType === 1 && a.sourceIndex - b.sourceIndex; if (d) { // NOSONAR
        return d; // NOSONAR
      } if (c) { // NOSONAR
        while (c = c.nextSibling) { // NOSONAR
          if (c === b) { // NOSONAR
            return -1; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return a ? 1 : -1; // NOSONAR
    } function ma(a) { // NOSONAR
      return function(b) { // NOSONAR
        var c = b.nodeName.toLowerCase(); return c === 'input' && b.type === a; // NOSONAR
      }; // NOSONAR
    } function na(a) { // NOSONAR
      return function(b) { // NOSONAR
        var c = b.nodeName.toLowerCase(); return (c === 'input' || c === 'button') && b.type === a; // NOSONAR
      }; // NOSONAR
    } function oa(a) { // NOSONAR
      return function(b) { // NOSONAR
        return 'form' in b ? b.parentNode && b.disabled === !1 ? 'label' in b ? 'label' in b.parentNode ? b.parentNode.disabled === a : b.disabled === a : b.isDisabled === a || b.isDisabled !== !a && ea(b) === a : b.disabled === a : 'label' in b && b.disabled === a; // NOSONAR
      }; // NOSONAR
    } function pa(a) { // NOSONAR
      return ia(function(b) { // NOSONAR
        return b = +b, ia(function(c, d) { // NOSONAR
          var e, f = a([], c.length, b), g = f.length; while (g--) { // NOSONAR
            c[e = f[g]] && (c[e] = !(d[e] = c[e])); // NOSONAR
          } // NOSONAR
        }); // NOSONAR
      }); // NOSONAR
    } function qa(a) { // NOSONAR
      return a && typeof a.getElementsByTagName !== 'undefined' && a; // NOSONAR
    }c = ga.support = {}, f = ga.isXML = function(a) { // NOSONAR
      var b = a && (a.ownerDocument || a).documentElement; return !!b && b.nodeName !== 'HTML'; // NOSONAR
    }, m = ga.setDocument = function(a) { // NOSONAR
      var b, e, g = a ? a.ownerDocument || a : v; return g !== n && g.nodeType === 9 && g.documentElement ? (n = g, o = n.documentElement, p = !f(n), v !== n && (e = n.defaultView) && e.top !== e && (e.addEventListener ? e.addEventListener('unload', da, !1) : e.attachEvent && e.attachEvent('onunload', da)), c.attributes = ja(function(a) { // NOSONAR
        return a.className = 'i', !a.getAttribute('className'); // NOSONAR
      }), c.getElementsByTagName = ja(function(a) { // NOSONAR
          return a.appendChild(n.createComment('')), !a.getElementsByTagName('*').length; // NOSONAR
        }), c.getElementsByClassName = Y.test(n.getElementsByClassName), c.getById = ja(function(a) { // NOSONAR
          return o.appendChild(a).id = u, !n.getElementsByName || !n.getElementsByName(u).length; // NOSONAR
        }), c.getById ? (d.filter.ID = function(a) { // NOSONAR
          var b = a.replace(_, aa); return function(a) { // NOSONAR
            return a.getAttribute('id') === b; // NOSONAR
          }; // NOSONAR
        }, d.find.ID = function(a, b) { // NOSONAR
            if (typeof b.getElementById !== 'undefined' && p) { // NOSONAR
              var c = b.getElementById(a); return c ? [ c ] : []; // NOSONAR
            } // NOSONAR
          }) : (d.filter.ID = function(a) { // NOSONAR
          var b = a.replace(_, aa); return function(a) { // NOSONAR
            var c = typeof a.getAttributeNode !== 'undefined' && a.getAttributeNode('id'); return c && c.value === b; // NOSONAR
          }; // NOSONAR
        }, d.find.ID = function(a, b) { // NOSONAR
            if (typeof b.getElementById !== 'undefined' && p) { // NOSONAR
              var c, d, e, f = b.getElementById(a); if (f) { // NOSONAR
                if (c = f.getAttributeNode('id'), c && c.value === a) { // NOSONAR
                  return [ f ]; // NOSONAR
                } e = b.getElementsByName(a), d = 0; while (f = e[d++]) { // NOSONAR
                  if (c = f.getAttributeNode('id'), c && c.value === a) { // NOSONAR
                    return [ f ]; // NOSONAR
                  } // NOSONAR
                } // NOSONAR
              } return []; // NOSONAR
            } // NOSONAR
          }), d.find.TAG = c.getElementsByTagName ? function(a, b) { // NOSONAR
          return typeof b.getElementsByTagName !== 'undefined' ? b.getElementsByTagName(a) : c.qsa ? b.querySelectorAll(a) : void 0; // NOSONAR
        } : function(a, b) { // NOSONAR
          var c, d = [], e = 0, f = b.getElementsByTagName(a); if (a === '*') { // NOSONAR
            while (c = f[e++]) { // NOSONAR
              c.nodeType === 1 && d.push(c); // NOSONAR
            } return d; // NOSONAR
          } return f; // NOSONAR
        }, d.find.CLASS = c.getElementsByClassName && function(a, b) { // NOSONAR
          if (typeof b.getElementsByClassName !== 'undefined' && p) { // NOSONAR
            return b.getElementsByClassName(a); // NOSONAR
          } // NOSONAR
        }, r = [], q = [], (c.qsa = Y.test(n.querySelectorAll)) && (ja(function(a) { // NOSONAR
          o.appendChild(a).innerHTML = '<a id=\'' + u + '\'></a><select id=\'' + u + '-\r\\\' msallowcapture=\'\'><option selected=\'\'></option></select>', a.querySelectorAll('[msallowcapture^=\'\']').length && q.push('[*^$]=' + K + '*(?:\'\'|"")'), a.querySelectorAll('[selected]').length || q.push('\\[' + K + '*(?:value|' + J + ')'), a.querySelectorAll('[id~=' + u + '-]').length || q.push('~='), a.querySelectorAll(':checked').length || q.push(':checked'), a.querySelectorAll('a#' + u + '+*').length || q.push('.#.+[+~]'); // NOSONAR
        }), ja(function(a) { // NOSONAR
            a.innerHTML = '<a href=\'\' disabled=\'disabled\'></a><select disabled=\'disabled\'><option/></select>'; var b = n.createElement('input'); b.setAttribute('type', 'hidden'), a.appendChild(b).setAttribute('name', 'D'), a.querySelectorAll('[name=d]').length && q.push('name' + K + '*[*^$|!~]?='), a.querySelectorAll(':enabled').length !== 2 && q.push(':enabled', ':disabled'), o.appendChild(a).disabled = !0, a.querySelectorAll(':disabled').length !== 2 && q.push(':enabled', ':disabled'), a.querySelectorAll('*,:x'), q.push(',.*:'); // NOSONAR
          })), (c.matchesSelector = Y.test(s = o.matches || o.webkitMatchesSelector || o.mozMatchesSelector || o.oMatchesSelector || o.msMatchesSelector)) && ja(function(a) { // NOSONAR
          c.disconnectedMatch = s.call(a, '*'), s.call(a, '[s!=\'\']:x'), r.push('!=', N); // NOSONAR
        }), q = q.length && new RegExp(q.join('|')), r = r.length && new RegExp(r.join('|')), b = Y.test(o.compareDocumentPosition), t = b || Y.test(o.contains) ? function(a, b) { // NOSONAR
          var c = a.nodeType === 9 ? a.documentElement : a, d = b && b.parentNode; return a === d || !(!d || d.nodeType !== 1 || !(c.contains ? c.contains(d) : a.compareDocumentPosition && 16 & a.compareDocumentPosition(d))); // NOSONAR
        } : function(a, b) { // NOSONAR
          if (b) { // NOSONAR
            while (b = b.parentNode) { // NOSONAR
              if (b === a) { // NOSONAR
                return !0; // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } return !1; // NOSONAR
        }, B = b ? function(a, b) { // NOSONAR
          if (a === b) { // NOSONAR
            return l = !0, 0; // NOSONAR
          } var d = !a.compareDocumentPosition - !b.compareDocumentPosition; return d ? d : (d = (a.ownerDocument || a) === (b.ownerDocument || b) ? a.compareDocumentPosition(b) : 1, 1 & d || !c.sortDetached && b.compareDocumentPosition(a) === d ? a === n || a.ownerDocument === v && t(v, a) ? -1 : b === n || b.ownerDocument === v && t(v, b) ? 1 : k ? I(k, a) - I(k, b) : 0 : 4 & d ? -1 : 1); // NOSONAR
        } : function(a, b) { // NOSONAR
          if (a === b) { // NOSONAR
            return l = !0, 0; // NOSONAR
          } var c, d = 0, e = a.parentNode, f = b.parentNode, g = [ a ], h = [ b ]; if (!e || !f) { // NOSONAR
            return a === n ? -1 : b === n ? 1 : e ? -1 : f ? 1 : k ? I(k, a) - I(k, b) : 0; // NOSONAR
          } if (e === f) { // NOSONAR
            return la(a, b); // NOSONAR
          } c = a; while (c = c.parentNode) { // NOSONAR
            g.unshift(c); // NOSONAR
          }c = b; while (c = c.parentNode) { // NOSONAR
            h.unshift(c); // NOSONAR
          } while (g[d] === h[d]) { // NOSONAR
            d++; // NOSONAR
          } return d ? la(g[d], h[d]) : g[d] === v ? -1 : h[d] === v ? 1 : 0; // NOSONAR
        }, n) : n; // NOSONAR
    }, ga.matches = function(a, b) { // NOSONAR
      return ga(a, null, null, b); // NOSONAR
    }, ga.matchesSelector = function(a, b) { // NOSONAR
      if ((a.ownerDocument || a) !== n && m(a), b = b.replace(S, '=\'$1\']'), c.matchesSelector && p && !A[b + ' '] && (!r || !r.test(b)) && (!q || !q.test(b))) { // NOSONAR
        try { // NOSONAR
          var d = s.call(a, b); if (d || c.disconnectedMatch || a.document && a.document.nodeType !== 11) { // NOSONAR
            return d; // NOSONAR
          } // NOSONAR
        } catch (e) {} // NOSONAR
      } return ga(b, n, null, [ a ]).length > 0; // NOSONAR
    }, ga.contains = function(a, b) { // NOSONAR
      return (a.ownerDocument || a) !== n && m(a), t(a, b); // NOSONAR
    }, ga.attr = function(a, b) { // NOSONAR
      (a.ownerDocument || a) !== n && m(a); var e = d.attrHandle[b.toLowerCase()], f = e && C.call(d.attrHandle, b.toLowerCase()) ? e(a, b, !p) : void 0; return void 0 !== f ? f : c.attributes || !p ? a.getAttribute(b) : (f = a.getAttributeNode(b)) && f.specified ? f.value : null; // NOSONAR
    }, ga.escape = function(a) { // NOSONAR
      return (a + '').replace(ba, ca); // NOSONAR
    }, ga.error = function(a) { // NOSONAR
      throw new Error('Syntax error, unrecognized expression: ' + a); // NOSONAR
    }, ga.uniqueSort = function(a) { // NOSONAR
      var b, d = [], e = 0, f = 0; if (l = !c.detectDuplicates, k = !c.sortStable && a.slice(0), a.sort(B), l) { // NOSONAR
        while (b = a[f++]) { // NOSONAR
          b === a[f] && (e = d.push(f)); // NOSONAR
        } while (e--) { // NOSONAR
          a.splice(d[e], 1); // NOSONAR
        } // NOSONAR
      } return k = null, a; // NOSONAR
    }, e = ga.getText = function(a) { // NOSONAR
      var b, c = '', d = 0, f = a.nodeType; if (f) { // NOSONAR
        if (f === 1 || f === 9 || f === 11) { // NOSONAR
          if (typeof a.textContent === 'string') { // NOSONAR
            return a.textContent; // NOSONAR
          } for (a = a.firstChild; a; a = a.nextSibling) { // NOSONAR
            c += e(a); // NOSONAR
          } // NOSONAR
        } else if (f === 3 || f === 4) { // NOSONAR
          return a.nodeValue; // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        while (b = a[d++]) { // NOSONAR
          c += e(b); // NOSONAR
        } // NOSONAR
      } return c; // NOSONAR
    }, d = ga.selectors = {cacheLength: 50, createPseudo: ia, match: V, attrHandle: {}, find: {}, relative: {'>': {dir: 'parentNode', first: !0}, ' ': {dir: 'parentNode'}, '+': {dir: 'previousSibling', first: !0}, '~': {dir: 'previousSibling'}}, preFilter: {ATTR: function(a) { // NOSONAR
      return a[1] = a[1].replace(_, aa), a[3] = (a[3] || a[4] || a[5] || '').replace(_, aa), a[2] === '~=' && (a[3] = ' ' + a[3] + ' '), a.slice(0, 4); // NOSONAR
    }, CHILD: function(a) { // NOSONAR
      return a[1] = a[1].toLowerCase(), a[1].slice(0, 3) === 'nth' ? (a[3] || ga.error(a[0]), a[4] = +(a[4] ? a[5] + (a[6] || 1) : 2 * (a[3] === 'even' || a[3] === 'odd')), a[5] = +(a[7] + a[8] || a[3] === 'odd')) : a[3] && ga.error(a[0]), a; // NOSONAR
    }, PSEUDO: function(a) { // NOSONAR
      var b, c = !a[6] && a[2]; return V.CHILD.test(a[0]) ? null : (a[3] ? a[2] = a[4] || a[5] || '' : c && T.test(c) && (b = g(c, !0)) && (b = c.indexOf(')', c.length - b) - c.length) && (a[0] = a[0].slice(0, b), a[2] = c.slice(0, b)), a.slice(0, 3)); // NOSONAR
    }}, filter: {TAG: function(a) { // NOSONAR
      var b = a.replace(_, aa).toLowerCase(); return a === '*' ? function() { // NOSONAR
        return !0; // NOSONAR
      } : function(a) { // NOSONAR
        return a.nodeName && a.nodeName.toLowerCase() === b; // NOSONAR
      }; // NOSONAR
    }, CLASS: function(a) { // NOSONAR
      var b = y[a + ' ']; return b || (b = new RegExp('(^|' + K + ')' + a + '(' + K + '|$)')) && y(a, function(a) { // NOSONAR
        return b.test(typeof a.className === 'string' && a.className || typeof a.getAttribute !== 'undefined' && a.getAttribute('class') || ''); // NOSONAR
      }); // NOSONAR
    }, ATTR: function(a, b, c) { // NOSONAR
      return function(d) { // NOSONAR
        var e = ga.attr(d, a); return e == null ? b === '!=' : !b || (e += '', b === '=' ? e === c : b === '!=' ? e !== c : b === '^=' ? c && e.indexOf(c) === 0 : b === '*=' ? c && e.indexOf(c) > -1 : b === '$=' ? c && e.slice(-c.length) === c : b === '~=' ? (' ' + e.replace(O, ' ') + ' ').indexOf(c) > -1 : b === '|=' && (e === c || e.slice(0, c.length + 1) === c + '-')); // NOSONAR
      }; // NOSONAR
    }, CHILD: function(a, b, c, d, e) { // NOSONAR
      var f = a.slice(0, 3) !== 'nth', g = a.slice(-4) !== 'last', h = b === 'of-type'; return d === 1 && e === 0 ? function(a) { // NOSONAR
        return !!a.parentNode; // NOSONAR
      } : function(b, c, i) { // NOSONAR
        var j, k, l, m, n, o, p = f !== g ? 'nextSibling' : 'previousSibling', q = b.parentNode, r = h && b.nodeName.toLowerCase(), s = !i && !h, t = !1; if (q) { // NOSONAR
          if (f) { // NOSONAR
            while (p) { // NOSONAR
              m = b; while (m = m[p]) { // NOSONAR
                if (h ? m.nodeName.toLowerCase() === r : m.nodeType === 1) { // NOSONAR
                  return !1; // NOSONAR
                } // NOSONAR
              } o = p = a === 'only' && !o && 'nextSibling'; // NOSONAR
            } return !0; // NOSONAR
          } if (o = [ g ? q.firstChild : q.lastChild ], g && s) { // NOSONAR
            m = q, l = m[u] || (m[u] = {}), k = l[m.uniqueID] || (l[m.uniqueID] = {}), j = k[a] || [], n = j[0] === w && j[1], t = n && j[2], m = n && q.childNodes[n]; while (m = ++n && m && m[p] || (t = n = 0) || o.pop()) { // NOSONAR
              if (m.nodeType === 1 && ++t && m === b) { // NOSONAR
                k[a] = [w, n, t]; break; // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } else if (s && (m = b, l = m[u] || (m[u] = {}), k = l[m.uniqueID] || (l[m.uniqueID] = {}), j = k[a] || [], n = j[0] === w && j[1], t = n), t === !1) { // NOSONAR
            while (m = ++n && m && m[p] || (t = n = 0) || o.pop()) { // NOSONAR
              if ((h ? m.nodeName.toLowerCase() === r : m.nodeType === 1) && ++t && (s && (l = m[u] || (m[u] = {}), k = l[m.uniqueID] || (l[m.uniqueID] = {}), k[a] = [w, t]), m === b)) { // NOSONAR
                break; // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } return t -= e, t === d || t % d === 0 && t / d >= 0; // NOSONAR
        } // NOSONAR
      }; // NOSONAR
    }, PSEUDO: function(a, b) { // NOSONAR
      var c, e = d.pseudos[a] || d.setFilters[a.toLowerCase()] || ga.error('unsupported pseudo: ' + a); return e[u] ? e(b) : e.length > 1 ? (c = [a, a, '', b], d.setFilters.hasOwnProperty(a.toLowerCase()) ? ia(function(a, c) { // NOSONAR
        var d, f = e(a, b), g = f.length; while (g--) { // NOSONAR
          d = I(a, f[g]), a[d] = !(c[d] = f[g]); // NOSONAR
        } // NOSONAR
      }) : function(a) { // NOSONAR
        return e(a, 0, c); // NOSONAR
      }) : e; // NOSONAR
    }}, pseudos: {not: ia(function(a) { // NOSONAR
      var b = [], c = [], d = h(a.replace(P, '$1')); return d[u] ? ia(function(a, b, c, e) { // NOSONAR
        var f, g = d(a, null, e, []), h = a.length; while (h--) { // NOSONAR
          (f = g[h]) && (a[h] = !(b[h] = f)); // NOSONAR
        } // NOSONAR
      }) : function(a, e, f) { // NOSONAR
        return b[0] = a, d(b, null, f, c), b[0] = null, !c.pop(); // NOSONAR
      }; // NOSONAR
    }), has: ia(function(a) { // NOSONAR
      return function(b) { // NOSONAR
        return ga(a, b).length > 0; // NOSONAR
      }; // NOSONAR
    }), contains: ia(function(a) { // NOSONAR
      return a = a.replace(_, aa), function(b) { // NOSONAR
        return (b.textContent || b.innerText || e(b)).indexOf(a) > -1; // NOSONAR
      }; // NOSONAR
    }), lang: ia(function(a) { // NOSONAR
      return U.test(a || '') || ga.error('unsupported lang: ' + a), a = a.replace(_, aa).toLowerCase(), function(b) { // NOSONAR
        var c; do { // NOSONAR
          if (c = p ? b.lang : b.getAttribute('xml:lang') || b.getAttribute('lang')) { // NOSONAR
            return c = c.toLowerCase(), c === a || c.indexOf(a + '-') === 0; // NOSONAR
          } // NOSONAR
        } while ((b = b.parentNode) && b.nodeType === 1);return !1; // NOSONAR
      }; // NOSONAR
    }), target: function(b) { // NOSONAR
      var c = a.location && a.location.hash; return c && c.slice(1) === b.id; // NOSONAR
    }, root: function(a) { // NOSONAR
      return a === o; // NOSONAR
    }, focus: function(a) { // NOSONAR
      return a === n.activeElement && (!n.hasFocus || n.hasFocus()) && !!(a.type || a.href || ~a.tabIndex); // NOSONAR
    }, enabled: oa(!1), disabled: oa(!0), checked: function(a) { // NOSONAR
      var b = a.nodeName.toLowerCase(); return b === 'input' && !!a.checked || b === 'option' && !!a.selected; // NOSONAR
    }, selected: function(a) { // NOSONAR
      return a.parentNode && a.parentNode.selectedIndex, a.selected === !0; // NOSONAR
    }, empty: function(a) { // NOSONAR
      for (a = a.firstChild; a; a = a.nextSibling) { // NOSONAR
        if (a.nodeType < 6) { // NOSONAR
          return !1; // NOSONAR
        } // NOSONAR
      } return !0; // NOSONAR
    }, parent: function(a) { // NOSONAR
      return !d.pseudos.empty(a); // NOSONAR
    }, header: function(a) { // NOSONAR
      return X.test(a.nodeName); // NOSONAR
    }, input: function(a) { // NOSONAR
      return W.test(a.nodeName); // NOSONAR
    }, button: function(a) { // NOSONAR
      var b = a.nodeName.toLowerCase(); return b === 'input' && a.type === 'button' || b === 'button'; // NOSONAR
    }, text: function(a) { // NOSONAR
      var b; return a.nodeName.toLowerCase() === 'input' && a.type === 'text' && ((b = a.getAttribute('type')) == null || b.toLowerCase() === 'text'); // NOSONAR
    }, first: pa(function() { // NOSONAR
      return [ 0 ]; // NOSONAR
    }), last: pa(function(a, b) { // NOSONAR
      return [ b - 1 ]; // NOSONAR
    }), eq: pa(function(a, b, c) { // NOSONAR
      return [ c < 0 ? c + b : c ]; // NOSONAR
    }), even: pa(function(a, b) { // NOSONAR
      for (var c = 0; c < b; c += 2) { // NOSONAR
        a.push(c); // NOSONAR
      } return a; // NOSONAR
    }), odd: pa(function(a, b) { // NOSONAR
      for (var c = 1; c < b; c += 2) { // NOSONAR
        a.push(c); // NOSONAR
      } return a; // NOSONAR
    }), lt: pa(function(a, b, c) { // NOSONAR
      for (var d = c < 0 ? c + b : c; --d >= 0;) { // NOSONAR
        a.push(d); // NOSONAR
      } return a; // NOSONAR
    }), gt: pa(function(a, b, c) { // NOSONAR
      for (var d = c < 0 ? c + b : c; ++d < b;) { // NOSONAR
        a.push(d); // NOSONAR
      } return a; // NOSONAR
    })}}, d.pseudos.nth = d.pseudos.eq; for (b in {radio: !0, checkbox: !0, file: !0, password: !0, image: !0}) { // NOSONAR
      d.pseudos[b] = ma(b); // NOSONAR
    } for (b in {submit: !0, reset: !0}) { // NOSONAR
      d.pseudos[b] = na(b); // NOSONAR
    } function ra() {}ra.prototype = d.filters = d.pseudos, d.setFilters = new ra, g = ga.tokenize = function(a, b) { // NOSONAR
      var c, e, f, g, h, i, j, k = z[a + ' ']; if (k) { // NOSONAR
        return b ? 0 : k.slice(0); // NOSONAR
      } h = a, i = [], j = d.preFilter; while (h) { // NOSONAR
        c && !(e = Q.exec(h)) || (e && (h = h.slice(e[0].length) || h), i.push(f = [])), c = !1, (e = R.exec(h)) && (c = e.shift(), f.push({value: c, type: e[0].replace(P, ' ')}), h = h.slice(c.length)); for (g in d.filter) { // NOSONAR
          !(e = V[g].exec(h)) || j[g] && !(e = j[g](e)) || (c = e.shift(), f.push({value: c, type: g, matches: e}), h = h.slice(c.length)); // NOSONAR
        } if (!c) { // NOSONAR
          break; // NOSONAR
        } // NOSONAR
      } return b ? h.length : h ? ga.error(a) : z(a, i).slice(0); // NOSONAR
    }; function sa(a) { // NOSONAR
      for (var b = 0, c = a.length, d = ''; b < c; b++) { // NOSONAR
        d += a[b].value; // NOSONAR
      } return d; // NOSONAR
    } function ta(a, b, c) { // NOSONAR
      var d = b.dir, e = b.next, f = e || d, g = c && f === 'parentNode', h = x++; return b.first ? function(b, c, e) { // NOSONAR
        while (b = b[d]) { // NOSONAR
          if (b.nodeType === 1 || g) { // NOSONAR
            return a(b, c, e); // NOSONAR
          } // NOSONAR
        } return !1; // NOSONAR
      } : function(b, c, i) { // NOSONAR
        var j, k, l, m = [w, h]; if (i) { // NOSONAR
          while (b = b[d]) { // NOSONAR
            if ((b.nodeType === 1 || g) && a(b, c, i)) { // NOSONAR
              return !0; // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          while (b = b[d]) { // NOSONAR
            if (b.nodeType === 1 || g) { // NOSONAR
              if (l = b[u] || (b[u] = {}), k = l[b.uniqueID] || (l[b.uniqueID] = {}), e && e === b.nodeName.toLowerCase()) { // NOSONAR
                b = b[d] || b; // NOSONAR
              } else { // NOSONAR
                if ((j = k[f]) && j[0] === w && j[1] === h) { // NOSONAR
                  return m[2] = j[2]; // NOSONAR
                } if (k[f] = m, m[2] = a(b, c, i)) { // NOSONAR
                  return !0; // NOSONAR
                } // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } return !1; // NOSONAR
      }; // NOSONAR
    } function ua(a) { // NOSONAR
      return a.length > 1 ? function(b, c, d) { // NOSONAR
        var e = a.length; while (e--) { // NOSONAR
          if (!a[e](b, c, d)) { // NOSONAR
            return !1; // NOSONAR
          } // NOSONAR
        } return !0; // NOSONAR
      } : a[0]; // NOSONAR
    } function va(a, b, c) { // NOSONAR
      for (var d = 0, e = b.length; d < e; d++) { // NOSONAR
        ga(a, b[d], c); // NOSONAR
      } return c; // NOSONAR
    } function wa(a, b, c, d, e) { // NOSONAR
      for (var f, g = [], h = 0, i = a.length, j = b != null; h < i; h++) { // NOSONAR
        (f = a[h]) && (c && !c(f, d, e) || (g.push(f), j && b.push(h))); // NOSONAR
      } return g; // NOSONAR
    } function xa(a, b, c, d, e, f) { // NOSONAR
      return d && !d[u] && (d = xa(d)), e && !e[u] && (e = xa(e, f)), ia(function(f, g, h, i) { // NOSONAR
        var j, k, l, m = [], n = [], o = g.length, p = f || va(b || '*', h.nodeType ? [ h ] : h, []), q = !a || !f && b ? p : wa(p, m, a, h, i), r = c ? e || (f ? a : o || d) ? [] : g : q; if (c && c(q, r, h, i), d) { // NOSONAR
          j = wa(r, n), d(j, [], h, i), k = j.length; while (k--) { // NOSONAR
            (l = j[k]) && (r[n[k]] = !(q[n[k]] = l)); // NOSONAR
          } // NOSONAR
        } if (f) { // NOSONAR
          if (e || a) { // NOSONAR
            if (e) { // NOSONAR
              j = [], k = r.length; while (k--) { // NOSONAR
                (l = r[k]) && j.push(q[k] = l); // NOSONAR
              }e(null, r = [], j, i); // NOSONAR
            }k = r.length; while (k--) { // NOSONAR
              (l = r[k]) && (j = e ? I(f, l) : m[k]) > -1 && (f[j] = !(g[j] = l)); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          r = wa(r === g ? r.splice(o, r.length) : r), e ? e(null, g, r, i) : G.apply(g, r); // NOSONAR
        } // NOSONAR
      }); // NOSONAR
    } function ya(a) { // NOSONAR
      for (var b, c, e, f = a.length, g = d.relative[a[0].type], h = g || d.relative[' '], i = g ? 1 : 0, k = ta(function(a) { // NOSONAR
          return a === b; // NOSONAR
        }, h, !0), l = ta(function(a) { // NOSONAR
          return I(b, a) > -1; // NOSONAR
        }, h, !0), m = [ function(a, c, d) { // NOSONAR
          var e = !g && (d || c !== j) || ((b = c).nodeType ? k(a, c, d) : l(a, c, d)); return b = null, e; // NOSONAR
        } ]; i < f; i++) { // NOSONAR
        if (c = d.relative[a[i].type]) { // NOSONAR
          m = [ ta(ua(m), c) ]; // NOSONAR
        } else { // NOSONAR
          if (c = d.filter[a[i].type].apply(null, a[i].matches), c[u]) { // NOSONAR
            for (e = ++i; e < f; e++) { // NOSONAR
              if (d.relative[a[e].type]) { // NOSONAR
                break; // NOSONAR
              } // NOSONAR
            } return xa(i > 1 && ua(m), i > 1 && sa(a.slice(0, i - 1).concat({value: a[i - 2].type === ' ' ? '*' : ''})).replace(P, '$1'), c, i < e && ya(a.slice(i, e)), e < f && ya(a = a.slice(e)), e < f && sa(a)); // NOSONAR
          }m.push(c); // NOSONAR
        } // NOSONAR
      } return ua(m); // NOSONAR
    } function za(a, b) { // NOSONAR
      var c = b.length > 0, e = a.length > 0, f = function(f, g, h, i, k) { // NOSONAR
        var l, o, q, r = 0, s = '0', t = f && [], u = [], v = j, x = f || e && d.find.TAG('*', k), y = w += v == null ? 1 : Math.random() || .1, z = x.length; for (k && (j = g === n || g || k); s !== z && (l = x[s]) != null; s++) { // NOSONAR
          if (e && l) { // NOSONAR
            o = 0, g || l.ownerDocument === n || (m(l), h = !p); while (q = a[o++]) { // NOSONAR
              if (q(l, g || n, h)) { // NOSONAR
                i.push(l); break; // NOSONAR
              } // NOSONAR
            }k && (w = y); // NOSONAR
          }c && ((l = !q && l) && r--, f && t.push(l)); // NOSONAR
        } if (r += s, c && s !== r) { // NOSONAR
          o = 0; while (q = b[o++]) { // NOSONAR
            q(t, u, g, h); // NOSONAR
          } if (f) { // NOSONAR
            if (r > 0) { // NOSONAR
              while (s--) { // NOSONAR
                t[s] || u[s] || (u[s] = E.call(i)); // NOSONAR
              } // NOSONAR
            }u = wa(u); // NOSONAR
          }G.apply(i, u), k && !f && u.length > 0 && r + b.length > 1 && ga.uniqueSort(i); // NOSONAR
        } return k && (w = y, j = v), t; // NOSONAR
      }; return c ? ia(f) : f; // NOSONAR
    } return h = ga.compile = function(a, b) { // NOSONAR
      var c, d = [], e = [], f = A[a + ' ']; if (!f) { // NOSONAR
        b || (b = g(a)), c = b.length; while (c--) { // NOSONAR
          f = ya(b[c]), f[u] ? d.push(f) : e.push(f); // NOSONAR
        }f = A(a, za(e, d)), f.selector = a; // NOSONAR
      } return f; // NOSONAR
    }, i = ga.select = function(a, b, c, e) { // NOSONAR
      var f, i, j, k, l, m = typeof a === 'function' && a, n = !e && g(a = m.selector || a); if (c = c || [], n.length === 1) { // NOSONAR
        if (i = n[0] = n[0].slice(0), i.length > 2 && (j = i[0]).type === 'ID' && b.nodeType === 9 && p && d.relative[i[1].type]) { // NOSONAR
          if (b = (d.find.ID(j.matches[0].replace(_, aa), b) || [])[0], !b) { // NOSONAR
            return c; // NOSONAR
          } m && (b = b.parentNode), a = a.slice(i.shift().value.length); // NOSONAR
        }f = V.needsContext.test(a) ? 0 : i.length; while (f--) { // NOSONAR
          if (j = i[f], d.relative[k = j.type]) { // NOSONAR
            break; // NOSONAR
          } if ((l = d.find[k]) && (e = l(j.matches[0].replace(_, aa), $.test(i[0].type) && qa(b.parentNode) || b))) { // NOSONAR
            if (i.splice(f, 1), a = e.length && sa(i), !a) { // NOSONAR
              return G.apply(c, e), c; // NOSONAR
            } break; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return (m || h(a, n))(e, b, !p, c, !b || $.test(a) && qa(b.parentNode) || b), c; // NOSONAR
    }, c.sortStable = u.split('').sort(B).join('') === u, c.detectDuplicates = !!l, m(), c.sortDetached = ja(function(a) { // NOSONAR
      return 1 & a.compareDocumentPosition(n.createElement('fieldset')); // NOSONAR
    }), ja(function(a) { // NOSONAR
      return a.innerHTML = '<a href=\'#\'></a>', a.firstChild.getAttribute('href') === '#'; // NOSONAR
    }) || ka('type|href|height|width', function(a, b, c) { // NOSONAR
      if (!c) { // NOSONAR
        return a.getAttribute(b, b.toLowerCase() === 'type' ? 1 : 2); // NOSONAR
      } // NOSONAR
    }), c.attributes && ja(function(a) { // NOSONAR
      return a.innerHTML = '<input/>', a.firstChild.setAttribute('value', ''), a.firstChild.getAttribute('value') === ''; // NOSONAR
    }) || ka('value', function(a, b, c) { // NOSONAR
      if (!c && a.nodeName.toLowerCase() === 'input') { // NOSONAR
        return a.defaultValue; // NOSONAR
      } // NOSONAR
    }), ja(function(a) { // NOSONAR
      return a.getAttribute('disabled') == null; // NOSONAR
    }) || ka(J, function(a, b, c) { // NOSONAR
      var d; if (!c) { // NOSONAR
        return a[b] === !0 ? b.toLowerCase() : (d = a.getAttributeNode(b)) && d.specified ? d.value : null; // NOSONAR
      } // NOSONAR
    }), ga; // NOSONAR
  }(a)); r.find = x, r.expr = x.selectors, r.expr[':'] = r.expr.pseudos, r.uniqueSort = r.unique = x.uniqueSort, r.text = x.getText, r.isXMLDoc = x.isXML, r.contains = x.contains, r.escapeSelector = x.escape; var y = function(a, b, c) { // NOSONAR
      var d = [], e = void 0 !== c; while ((a = a[b]) && a.nodeType !== 9) { // NOSONAR
        if (a.nodeType === 1) { // NOSONAR
          if (e && r(a).is(c)) { // NOSONAR
            break; // NOSONAR
          } d.push(a); // NOSONAR
        } // NOSONAR
      } return d; // NOSONAR
    }, z = function(a, b) { // NOSONAR
      for (var c = []; a; a = a.nextSibling) { // NOSONAR
        a.nodeType === 1 && a !== b && c.push(a); // NOSONAR
      } return c; // NOSONAR
    }, A = r.expr.match.needsContext; function B(a, b) { // NOSONAR
    return a.nodeName && a.nodeName.toLowerCase() === b.toLowerCase(); // NOSONAR
  } var C = /^<([a-z][^\/\0>:\x20\t\r\n\f]*)[\x20\t\r\n\f]*\/?>(?:<\/\1>|)$/i, D = /^.[^:#\[\.,]*$/; function E(a, b, c) { // NOSONAR
    return r.isFunction(b) ? r.grep(a, function(a, d) { // NOSONAR
      return !!b.call(a, d, a) !== c; // NOSONAR
    }) : b.nodeType ? r.grep(a, function(a) { // NOSONAR
      return a === b !== c; // NOSONAR
    }) : typeof b !== 'string' ? r.grep(a, function(a) { // NOSONAR
      return i.call(b, a) > -1 !== c; // NOSONAR
    }) : D.test(b) ? r.filter(b, a, c) : (b = r.filter(b, a), r.grep(a, function(a) { // NOSONAR
      return i.call(b, a) > -1 !== c && a.nodeType === 1; // NOSONAR
    })); // NOSONAR
  }r.filter = function(a, b, c) { // NOSONAR
    var d = b[0]; return c && (a = ':not(' + a + ')'), b.length === 1 && d.nodeType === 1 ? r.find.matchesSelector(d, a) ? [ d ] : [] : r.find.matches(a, r.grep(b, function(a) { // NOSONAR
      return a.nodeType === 1; // NOSONAR
    })); // NOSONAR
  }, r.fn.extend({find: function(a) { // NOSONAR
    var b, c, d = this.length, e = this; if (typeof a !== 'string') { // NOSONAR
      return this.pushStack(r(a).filter(function() { // NOSONAR
        for (b = 0; b < d; b++) { // NOSONAR
          if (r.contains(e[b], this)) { // NOSONAR
            return !0; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      })); // NOSONAR
    } for (c = this.pushStack([]), b = 0; b < d; b++) { // NOSONAR
      r.find(a, e[b], c); // NOSONAR
    } return d > 1 ? r.uniqueSort(c) : c; // NOSONAR
  }, filter: function(a) { // NOSONAR
    return this.pushStack(E(this, a || [], !1)); // NOSONAR
  }, not: function(a) { // NOSONAR
    return this.pushStack(E(this, a || [], !0)); // NOSONAR
  }, is: function(a) { // NOSONAR
    return !!E(this, typeof a === 'string' && A.test(a) ? r(a) : a || [], !1).length; // NOSONAR
  }}); var F, G = /^(?:\s*(<[\w\W]+>)[^>]*|#([\w-]+))$/, H = r.fn.init = function(a, b, c) { // NOSONAR
    var e, f; if (!a) { // NOSONAR
      return this; // NOSONAR
    } if (c = c || F, typeof a === 'string') { // NOSONAR
      if (e = a[0] === '<' && a[a.length - 1] === '>' && a.length >= 3 ? [null, a, null] : G.exec(a), !e || !e[1] && b) { // NOSONAR
        return !b || b.jquery ? (b || c).find(a) : this.constructor(b).find(a); // NOSONAR
      } if (e[1]) { // NOSONAR
        if (b = b instanceof r ? b[0] : b, r.merge(this, r.parseHTML(e[1], b && b.nodeType ? b.ownerDocument || b : d, !0)), C.test(e[1]) && r.isPlainObject(b)) { // NOSONAR
          for (e in b) { // NOSONAR
            r.isFunction(this[e]) ? this[e](b[e]) : this.attr(e, b[e]); // NOSONAR
          } // NOSONAR
        } return this; // NOSONAR
      } return f = d.getElementById(e[2]), f && (this[0] = f, this.length = 1), this; // NOSONAR
    } return a.nodeType ? (this[0] = a, this.length = 1, this) : r.isFunction(a) ? void 0 !== c.ready ? c.ready(a) : a(r) : r.makeArray(a, this); // NOSONAR
  }; H.prototype = r.fn, F = r(d); var I = /^(?:parents|prev(?:Until|All))/, J = {children: !0, contents: !0, next: !0, prev: !0}; r.fn.extend({has: function(a) { // NOSONAR
    var b = r(a, this), c = b.length; return this.filter(function() { // NOSONAR
      for (var a = 0; a < c; a++) { // NOSONAR
        if (r.contains(this, b[a])) { // NOSONAR
          return !0; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    }); // NOSONAR
  }, closest: function(a, b) { // NOSONAR
    var c, d = 0, e = this.length, f = [], g = typeof a !== 'string' && r(a); if (!A.test(a)) { // NOSONAR
      for (;d < e; d++) { // NOSONAR
        for (c = this[d]; c && c !== b; c = c.parentNode) { // NOSONAR
          if (c.nodeType < 11 && (g ? g.index(c) > -1 : c.nodeType === 1 && r.find.matchesSelector(c, a))) { // NOSONAR
            f.push(c); break; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return this.pushStack(f.length > 1 ? r.uniqueSort(f) : f); // NOSONAR
  }, index: function(a) { // NOSONAR
    return a ? typeof a === 'string' ? i.call(r(a), this[0]) : i.call(this, a.jquery ? a[0] : a) : this[0] && this[0].parentNode ? this.first().prevAll().length : -1; // NOSONAR
  }, add: function(a, b) { // NOSONAR
    return this.pushStack(r.uniqueSort(r.merge(this.get(), r(a, b)))); // NOSONAR
  }, addBack: function(a) { // NOSONAR
    return this.add(a == null ? this.prevObject : this.prevObject.filter(a)); // NOSONAR
  }}); function K(a, b) { // NOSONAR
    while ((a = a[b]) && a.nodeType !== 1) { // NOSONAR
 // NOSONAR
    } return a; // NOSONAR
  }r.each({parent: function(a) { // NOSONAR
    var b = a.parentNode; return b && b.nodeType !== 11 ? b : null; // NOSONAR
  }, parents: function(a) { // NOSONAR
    return y(a, 'parentNode'); // NOSONAR
  }, parentsUntil: function(a, b, c) { // NOSONAR
    return y(a, 'parentNode', c); // NOSONAR
  }, next: function(a) { // NOSONAR
    return K(a, 'nextSibling'); // NOSONAR
  }, prev: function(a) { // NOSONAR
    return K(a, 'previousSibling'); // NOSONAR
  }, nextAll: function(a) { // NOSONAR
    return y(a, 'nextSibling'); // NOSONAR
  }, prevAll: function(a) { // NOSONAR
    return y(a, 'previousSibling'); // NOSONAR
  }, nextUntil: function(a, b, c) { // NOSONAR
    return y(a, 'nextSibling', c); // NOSONAR
  }, prevUntil: function(a, b, c) { // NOSONAR
    return y(a, 'previousSibling', c); // NOSONAR
  }, siblings: function(a) { // NOSONAR
    return z((a.parentNode || {}).firstChild, a); // NOSONAR
  }, children: function(a) { // NOSONAR
    return z(a.firstChild); // NOSONAR
  }, contents: function(a) { // NOSONAR
    return B(a, 'iframe') ? a.contentDocument : (B(a, 'template') && (a = a.content || a), r.merge([], a.childNodes)); // NOSONAR
  }}, function(a, b) { // NOSONAR
    r.fn[a] = function(c, d) { // NOSONAR
      var e = r.map(this, b, c); return a.slice(-5) !== 'Until' && (d = c), d && typeof d === 'string' && (e = r.filter(d, e)), this.length > 1 && (J[a] || r.uniqueSort(e), I.test(a) && e.reverse()), this.pushStack(e); // NOSONAR
    }; // NOSONAR
  }); var L = /[^\x20\t\r\n\f]+/g; function M(a) { // NOSONAR
    var b = {}; return r.each(a.match(L) || [], function(a, c) { // NOSONAR
      b[c] = !0; // NOSONAR
    }), b; // NOSONAR
  }r.Callbacks = function(a) { // NOSONAR
    a = typeof a === 'string' ? M(a) : r.extend({}, a); var b, c, d, e, f = [], g = [], h = -1, i = function() { // NOSONAR
        for (e = e || a.once, d = b = !0; g.length; h = -1) { // NOSONAR
          c = g.shift(); while (++h < f.length) { // NOSONAR
            f[h].apply(c[0], c[1]) === !1 && a.stopOnFalse && (h = f.length, c = !1); // NOSONAR
          } // NOSONAR
        }a.memory || (c = !1), b = !1, e && (f = c ? [] : ''); // NOSONAR
      }, j = {add: function() { // NOSONAR
        return f && (c && !b && (h = f.length - 1, g.push(c)), (function d(b) { // NOSONAR
          r.each(b, function(b, c) { // NOSONAR
            r.isFunction(c) ? a.unique && j.has(c) || f.push(c) : c && c.length && r.type(c) !== 'string' && d(c); // NOSONAR
          }); // NOSONAR
        }(arguments)), c && !b && i()), this; // NOSONAR
      }, remove: function() { // NOSONAR
        return r.each(arguments, function(a, b) { // NOSONAR
          var c; while ((c = r.inArray(b, f, c)) > -1) { // NOSONAR
            f.splice(c, 1), c <= h && h--; // NOSONAR
          } // NOSONAR
        }), this; // NOSONAR
      }, has: function(a) { // NOSONAR
        return a ? r.inArray(a, f) > -1 : f.length > 0; // NOSONAR
      }, empty: function() { // NOSONAR
        return f && (f = []), this; // NOSONAR
      }, disable: function() { // NOSONAR
        return e = g = [], f = c = '', this; // NOSONAR
      }, disabled: function() { // NOSONAR
        return !f; // NOSONAR
      }, lock: function() { // NOSONAR
        return e = g = [], c || b || (f = c = ''), this; // NOSONAR
      }, locked: function() { // NOSONAR
        return !!e; // NOSONAR
      }, fireWith: function(a, c) { // NOSONAR
        return e || (c = c || [], c = [a, c.slice ? c.slice() : c], g.push(c), b || i()), this; // NOSONAR
      }, fire: function() { // NOSONAR
        return j.fireWith(this, arguments), this; // NOSONAR
      }, fired: function() { // NOSONAR
        return !!d; // NOSONAR
      }}; return j; // NOSONAR
  }; function N(a) { // NOSONAR
    return a; // NOSONAR
  } function O(a) { // NOSONAR
    throw a; // NOSONAR
  } function P(a, b, c, d) { // NOSONAR
    var e; try { // NOSONAR
      a && r.isFunction(e = a.promise) ? e.call(a).done(b).fail(c) : a && r.isFunction(e = a.then) ? e.call(a, b, c) : b.apply(void 0, [ a ].slice(d)); // NOSONAR
    } catch (a) { // NOSONAR
      c.apply(void 0, [ a ]); // NOSONAR
    } // NOSONAR
  }r.extend({Deferred: function(b) { // NOSONAR
    var c = [['notify', 'progress', r.Callbacks('memory'), r.Callbacks('memory'), 2], ['resolve', 'done', r.Callbacks('once memory'), r.Callbacks('once memory'), 0, 'resolved'], ['reject', 'fail', r.Callbacks('once memory'), r.Callbacks('once memory'), 1, 'rejected']], d = 'pending', e = {state: function() { // NOSONAR
        return d; // NOSONAR
      }, always: function() { // NOSONAR
        return f.done(arguments).fail(arguments), this; // NOSONAR
      }, 'catch': function(a) { // NOSONAR
        return e.then(null, a); // NOSONAR
      }, pipe: function() { // NOSONAR
        var a = arguments; return r.Deferred(function(b) { // NOSONAR
          r.each(c, function(c, d) { // NOSONAR
            var e = r.isFunction(a[d[4]]) && a[d[4]]; f[d[1]](function() { // NOSONAR
              var a = e && e.apply(this, arguments); a && r.isFunction(a.promise) ? a.promise().progress(b.notify).done(b.resolve).fail(b.reject) : b[d[0] + 'With'](this, e ? [ a ] : arguments); // NOSONAR
            }); // NOSONAR
          }), a = null; // NOSONAR
        }).promise(); // NOSONAR
      }, then: function(b, d, e) { // NOSONAR
        var f = 0; function g(b, c, d, e) { // NOSONAR
          return function() { // NOSONAR
            var h = this, i = arguments, j = function() { // NOSONAR
                var a, j; if (!(b < f)) { // NOSONAR
                  if (a = d.apply(h, i), a === c.promise()) { // NOSONAR
                    throw new TypeError('Thenable self-resolution'); // NOSONAR
                  } j = a && (typeof a === 'object' || typeof a === 'function') && a.then, r.isFunction(j) ? e ? j.call(a, g(f, c, N, e), g(f, c, O, e)) : (f++, j.call(a, g(f, c, N, e), g(f, c, O, e), g(f, c, N, c.notifyWith))) : (d !== N && (h = void 0, i = [ a ]), (e || c.resolveWith)(h, i)); // NOSONAR
                } // NOSONAR
              }, k = e ? j : function() { // NOSONAR
                try { // NOSONAR
                  j(); // NOSONAR
                } catch (a) { // NOSONAR
                  r.Deferred.exceptionHook && r.Deferred.exceptionHook(a, k.stackTrace), b + 1 >= f && (d !== O && (h = void 0, i = [ a ]), c.rejectWith(h, i)); // NOSONAR
                } // NOSONAR
              }; b ? k() : (r.Deferred.getStackHook && (k.stackTrace = r.Deferred.getStackHook()), a.setTimeout(k)); // NOSONAR
          }; // NOSONAR
        } return r.Deferred(function(a) { // NOSONAR
          c[0][3].add(g(0, a, r.isFunction(e) ? e : N, a.notifyWith)), c[1][3].add(g(0, a, r.isFunction(b) ? b : N)), c[2][3].add(g(0, a, r.isFunction(d) ? d : O)); // NOSONAR
        }).promise(); // NOSONAR
      }, promise: function(a) { // NOSONAR
        return a != null ? r.extend(a, e) : e; // NOSONAR
      }}, f = {}; return r.each(c, function(a, b) { // NOSONAR
      var g = b[2], h = b[5]; e[b[1]] = g.add, h && g.add(function() { // NOSONAR
        d = h; // NOSONAR
      }, c[3 - a][2].disable, c[0][2].lock), g.add(b[3].fire), f[b[0]] = function() { // NOSONAR
        return f[b[0] + 'With'](this === f ? void 0 : this, arguments), this; // NOSONAR
      }, f[b[0] + 'With'] = g.fireWith; // NOSONAR
    }), e.promise(f), b && b.call(f, f), f; // NOSONAR
  }, when: function(a) { // NOSONAR
    var b = arguments.length, c = b, d = Array(c), e = f.call(arguments), g = r.Deferred(), h = function(a) { // NOSONAR
      return function(c) { // NOSONAR
        d[a] = this, e[a] = arguments.length > 1 ? f.call(arguments) : c, --b || g.resolveWith(d, e); // NOSONAR
      }; // NOSONAR
    }; if (b <= 1 && (P(a, g.done(h(c)).resolve, g.reject, !b), g.state() === 'pending' || r.isFunction(e[c] && e[c].then))) { // NOSONAR
      return g.then(); // NOSONAR
    } while (c--) { // NOSONAR
      P(e[c], h(c), g.reject); // NOSONAR
    } return g.promise(); // NOSONAR
  }}); var Q = /^(Eval|Internal|Range|Reference|Syntax|Type|URI)Error$/; r.Deferred.exceptionHook = function(b, c) { // NOSONAR
    a.console && a.console.warn && b && Q.test(b.name) && a.console.warn('jQuery.Deferred exception: ' + b.message, b.stack, c); // NOSONAR
  }, r.readyException = function(b) { // NOSONAR
    a.setTimeout(function() { // NOSONAR
      throw b; // NOSONAR
    }); // NOSONAR
  }; var R = r.Deferred(); r.fn.ready = function(a) { // NOSONAR
    return R.then(a).catch(function(a) { // NOSONAR
      r.readyException(a); // NOSONAR
    }), this; // NOSONAR
  }, r.extend({isReady: !1, readyWait: 1, ready: function(a) { // NOSONAR
    (a === !0 ? --r.readyWait : r.isReady) || (r.isReady = !0, a !== !0 && --r.readyWait > 0 || R.resolveWith(d, [ r ])); // NOSONAR
  }}), r.ready.then = R.then; function S() { // NOSONAR
    d.removeEventListener('DOMContentLoaded', S), // NOSONAR
    a.removeEventListener('load', S), r.ready(); // NOSONAR
  }d.readyState === 'complete' || d.readyState !== 'loading' && !d.documentElement.doScroll ? a.setTimeout(r.ready) : (d.addEventListener('DOMContentLoaded', S), a.addEventListener('load', S)); var T = function(a, b, c, d, e, f, g) { // NOSONAR
      var h = 0, i = a.length, j = c == null; if (r.type(c) === 'object') { // NOSONAR
        e = !0; for (h in c) { // NOSONAR
          T(a, b, h, c[h], !0, f, g); // NOSONAR
        } // NOSONAR
      } else if (void 0 !== d && (e = !0, r.isFunction(d) || (g = !0), j && (g ? (b.call(a, d), b = null) : (j = b, b = function(a, b, c) { // NOSONAR
        return j.call(r(a), c); // NOSONAR
      })), b)) { // NOSONAR
        for (;h < i; h++) { // NOSONAR
          b(a[h], c, g ? d : d.call(a[h], h, b(a[h], c))); // NOSONAR
        } // NOSONAR
      } return e ? a : j ? b.call(a) : i ? b(a[0], c) : f; // NOSONAR
    }, U = function(a) { // NOSONAR
      return a.nodeType === 1 || a.nodeType === 9 || !+a.nodeType; // NOSONAR
    }; function V() { // NOSONAR
    this.expando = r.expando + V.uid++; // NOSONAR
  }V.uid = 1, V.prototype = {cache: function(a) { // NOSONAR
    var b = a[this.expando]; return b || (b = {}, U(a) && (a.nodeType ? a[this.expando] = b : Object.defineProperty(a, this.expando, {value: b, configurable: !0}))), b; // NOSONAR
  }, set: function(a, b, c) { // NOSONAR
    var d, e = this.cache(a); if (typeof b === 'string') { // NOSONAR
      e[r.camelCase(b)] = c; // NOSONAR
    } else { // NOSONAR
      for (d in b) { // NOSONAR
        e[r.camelCase(d)] = b[d]; // NOSONAR
      } // NOSONAR
    } return e; // NOSONAR
  }, get: function(a, b) { // NOSONAR
    return void 0 === b ? this.cache(a) : a[this.expando] && a[this.expando][r.camelCase(b)]; // NOSONAR
  }, access: function(a, b, c) { // NOSONAR
    return void 0 === b || b && typeof b === 'string' && void 0 === c ? this.get(a, b) : (this.set(a, b, c), void 0 !== c ? c : b); // NOSONAR
  }, remove: function(a, b) { // NOSONAR
    var c, d = a[this.expando]; if (void 0 !== d) { // NOSONAR
      if (void 0 !== b) { // NOSONAR
        Array.isArray(b) ? b = b.map(r.camelCase) : (b = r.camelCase(b), b = b in d ? [ b ] : b.match(L) || []), c = b.length; while (c--) { // NOSONAR
          delete d[b[c]]; // NOSONAR
        } // NOSONAR
      }(void 0 === b || r.isEmptyObject(d)) && (a.nodeType ? a[this.expando] = void 0 : delete a[this.expando]); // NOSONAR
    } // NOSONAR
  }, hasData: function(a) { // NOSONAR
    var b = a[this.expando]; return void 0 !== b && !r.isEmptyObject(b); // NOSONAR
  }}; var W = new V, X = new V, Y = /^(?:\{[\w\W]*\}|\[[\w\W]*\])$/, Z = /[A-Z]/g; function $(a) { // NOSONAR
    return a === 'true' || a !== 'false' && (a === 'null' ? null : a === +a + '' ? +a : Y.test(a) ? JSON.parse(a) : a); // NOSONAR
  } function _(a, b, c) { // NOSONAR
    var d; if (void 0 === c && a.nodeType === 1) { // NOSONAR
      if (d = 'data-' + b.replace(Z, '-$&').toLowerCase(), c = a.getAttribute(d), typeof c === 'string') { // NOSONAR
        try { // NOSONAR
          c = $(c); // NOSONAR
        } catch (e) {}X.set(a, b, c); // NOSONAR
      } else { // NOSONAR
        c = void 0; // NOSONAR
      } // NOSONAR
    } return c; // NOSONAR
  }r.extend({hasData: function(a) { // NOSONAR
    return X.hasData(a) || W.hasData(a); // NOSONAR
  }, data: function(a, b, c) { // NOSONAR
    return X.access(a, b, c); // NOSONAR
  }, removeData: function(a, b) { // NOSONAR
    X.remove(a, b); // NOSONAR
  }, _data: function(a, b, c) { // NOSONAR
    return W.access(a, b, c); // NOSONAR
  }, _removeData: function(a, b) { // NOSONAR
    W.remove(a, b); // NOSONAR
  }}), r.fn.extend({data: function(a, b) { // NOSONAR
    var c, d, e, f = this[0], g = f && f.attributes; if (void 0 === a) { // NOSONAR
      if (this.length && (e = X.get(f), f.nodeType === 1 && !W.get(f, 'hasDataAttrs'))) { // NOSONAR
        c = g.length; while (c--) { // NOSONAR
          g[c] && (d = g[c].name, d.indexOf('data-') === 0 && (d = r.camelCase(d.slice(5)), _(f, d, e[d]))); // NOSONAR
        }W.set(f, 'hasDataAttrs', !0); // NOSONAR
      } return e; // NOSONAR
    } return typeof a === 'object' ? this.each(function() { // NOSONAR
      X.set(this, a); // NOSONAR
    }) : T(this, function(b) { // NOSONAR
      var c; if (f && void 0 === b) { // NOSONAR
        if (c = X.get(f, a), void 0 !== c) { // NOSONAR
          return c; // NOSONAR
        } if (c = _(f, a), void 0 !== c) { // NOSONAR
          return c; // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        this.each(function() { // NOSONAR
          X.set(this, a, b); // NOSONAR
        }); // NOSONAR
      } // NOSONAR
    }, null, b, arguments.length > 1, null, !0); // NOSONAR
  }, removeData: function(a) { // NOSONAR
    return this.each(function() { // NOSONAR
      X.remove(this, a); // NOSONAR
    }); // NOSONAR
  }}), r.extend({queue: function(a, b, c) { // NOSONAR
    var d; if (a) { // NOSONAR
      return b = (b || 'fx') + 'queue', d = W.get(a, b), c && (!d || Array.isArray(c) ? d = W.access(a, b, r.makeArray(c)) : d.push(c)), d || []; // NOSONAR
    } // NOSONAR
  }, dequeue: function(a, b) { // NOSONAR
    b = b || 'fx'; var c = r.queue(a, b), d = c.length, e = c.shift(), f = r._queueHooks(a, b), g = function() { // NOSONAR
      r.dequeue(a, b); // NOSONAR
    }; e === 'inprogress' && (e = c.shift(), d--), e && (b === 'fx' && c.unshift('inprogress'), delete f.stop, e.call(a, g, f)), !d && f && f.empty.fire(); // NOSONAR
  }, _queueHooks: function(a, b) { // NOSONAR
    var c = b + 'queueHooks'; return W.get(a, c) || W.access(a, c, {empty: r.Callbacks('once memory').add(function() { // NOSONAR
      W.remove(a, [b + 'queue', c]); // NOSONAR
    })}); // NOSONAR
  }}), r.fn.extend({queue: function(a, b) { // NOSONAR
    var c = 2; return typeof a !== 'string' && (b = a, a = 'fx', c--), arguments.length < c ? r.queue(this[0], a) : void 0 === b ? this : this.each(function() { // NOSONAR
      var c = r.queue(this, a, b); r._queueHooks(this, a), a === 'fx' && c[0] !== 'inprogress' && r.dequeue(this, a); // NOSONAR
    }); // NOSONAR
  }, dequeue: function(a) { // NOSONAR
    return this.each(function() { // NOSONAR
      r.dequeue(this, a); // NOSONAR
    }); // NOSONAR
  }, clearQueue: function(a) { // NOSONAR
    return this.queue(a || 'fx', []); // NOSONAR
  }, promise: function(a, b) { // NOSONAR
    var c, d = 1, e = r.Deferred(), f = this, g = this.length, h = function() { // NOSONAR
      --d || e.resolveWith(f, [ f ]); // NOSONAR
    }; typeof a !== 'string' && (b = a, a = void 0), a = a || 'fx'; while (g--) { // NOSONAR
      c = W.get(f[g], a + 'queueHooks'), c && c.empty && (d++, c.empty.add(h)); // NOSONAR
    } return h(), e.promise(b); // NOSONAR
  }}); var aa = /[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/.source, ba = new RegExp('^(?:([+-])=|)(' + aa + ')([a-z%]*)$', 'i'), ca = ['Top', 'Right', 'Bottom', 'Left'], da = function(a, b) { // NOSONAR
      return a = b || a, a.style.display === 'none' || a.style.display === '' && r.contains(a.ownerDocument, a) && r.css(a, 'display') === 'none'; // NOSONAR
    }, ea = function(a, b, c, d) { // NOSONAR
      var e, f, g = {}; for (f in b) { // NOSONAR
        g[f] = a.style[f], a.style[f] = b[f]; // NOSONAR
      }e = c.apply(a, d || []); for (f in b) { // NOSONAR
        a.style[f] = g[f]; // NOSONAR
      } return e; // NOSONAR
    }; function fa(a, b, c, d) { // NOSONAR
    var e, f = 1, g = 20, h = d ? function() { // NOSONAR
        return d.cur(); // NOSONAR
      } : function() { // NOSONAR
        return r.css(a, b, ''); // NOSONAR
      }, i = h(), j = c && c[3] || (r.cssNumber[b] ? '' : 'px'), k = (r.cssNumber[b] || j !== 'px' && +i) && ba.exec(r.css(a, b)); if (k && k[3] !== j) { // NOSONAR
      j = j || k[3], c = c || [], k = +i || 1; do { // NOSONAR
        f = f || '.5', k /= f, r.style(a, b, k + j); // NOSONAR
      } while (f !== (f = h() / i) && f !== 1 && --g); // NOSONAR
    } return c && (k = +k || +i || 0, e = c[1] ? k + (c[1] + 1) * c[2] : +c[2], d && (d.unit = j, d.start = k, d.end = e)), e; // NOSONAR
  } var ga = {}; function ha(a) { // NOSONAR
    var b, c = a.ownerDocument, d = a.nodeName, e = ga[d]; return e ? e : (b = c.body.appendChild(c.createElement(d)), e = r.css(b, 'display'), b.parentNode.removeChild(b), e === 'none' && (e = 'block'), ga[d] = e, e); // NOSONAR
  } function ia(a, b) { // NOSONAR
    for (var c, d, e = [], f = 0, g = a.length; f < g; f++) { // NOSONAR
      d = a[f], d.style && (c = d.style.display, b ? (c === 'none' && (e[f] = W.get(d, 'display') || null, e[f] || (d.style.display = '')), d.style.display === '' && da(d) && (e[f] = ha(d))) : c !== 'none' && (e[f] = 'none', W.set(d, 'display', c))); // NOSONAR
    } for (f = 0; f < g; f++) { // NOSONAR
      e[f] != null && (a[f].style.display = e[f]); // NOSONAR
    } return a; // NOSONAR
  }r.fn.extend({show: function() { // NOSONAR
    return ia(this, !0); // NOSONAR
  }, hide: function() { // NOSONAR
    return ia(this); // NOSONAR
  }, toggle: function(a) { // NOSONAR
    return typeof a === 'boolean' ? a ? this.show() : this.hide() : this.each(function() { // NOSONAR
      da(this) ? r(this).show() : r(this).hide(); // NOSONAR
    }); // NOSONAR
  }}); var ja = /^(?:checkbox|radio)$/i, ka = /<([a-z][^\/\0>\x20\t\r\n\f]+)/i, la = /^$|\/(?:java|ecma)script/i, ma = {option: [1, '<select multiple=\'multiple\'>', '</select>'], thead: [1, '<table>', '</table>'], col: [2, '<table><colgroup>', '</colgroup></table>'], tr: [2, '<table><tbody>', '</tbody></table>'], td: [3, '<table><tbody><tr>', '</tr></tbody></table>'], _default: [0, '', '']}; ma.optgroup = ma.option, ma.tbody = ma.tfoot = ma.colgroup = ma.caption = ma.thead, ma.th = ma.td; function na(a, b) { // NOSONAR
    var c; return c = typeof a.getElementsByTagName !== 'undefined' ? a.getElementsByTagName(b || '*') : typeof a.querySelectorAll !== 'undefined' ? a.querySelectorAll(b || '*') : [], void 0 === b || b && B(a, b) ? r.merge([ a ], c) : c; // NOSONAR
  } function oa(a, b) { // NOSONAR
    for (var c = 0, d = a.length; c < d; c++) { // NOSONAR
      W.set(a[c], 'globalEval', !b || W.get(b[c], 'globalEval')); // NOSONAR
    } // NOSONAR
  } var pa = /<|&#?\w+;/; function qa(a, b, c, d, e) { // NOSONAR
    for (var f, g, h, i, j, k, l = b.createDocumentFragment(), m = [], n = 0, o = a.length; n < o; n++) { // NOSONAR
      if (f = a[n], f || f === 0) { // NOSONAR
        if (r.type(f) === 'object') { // NOSONAR
          r.merge(m, f.nodeType ? [ f ] : f); // NOSONAR
        } else if (pa.test(f)) { // NOSONAR
          g = g || l.appendChild(b.createElement('div')), h = (ka.exec(f) || ['', ''])[1].toLowerCase(), i = ma[h] || ma._default, g.innerHTML = i[1] + r.htmlPrefilter(f) + i[2], k = i[0]; while (k--) { // NOSONAR
            g = g.lastChild; // NOSONAR
          }r.merge(m, g.childNodes), g = l.firstChild, g.textContent = ''; // NOSONAR
        } else { // NOSONAR
          m.push(b.createTextNode(f)); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } l.textContent = '', n = 0; while (f = m[n++]) { // NOSONAR
      if (d && r.inArray(f, d) > -1) { // NOSONAR
        e && e.push(f); // NOSONAR
      } else if (j = r.contains(f.ownerDocument, f), g = na(l.appendChild(f), 'script'), j && oa(g), c) { // NOSONAR
        k = 0; while (f = g[k++]) { // NOSONAR
          la.test(f.type || '') && c.push(f); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return l; // NOSONAR
  }!(function() { // NOSONAR
    var a = d.createDocumentFragment(), b = a.appendChild(d.createElement('div')), c = d.createElement('input'); c.setAttribute('type', 'radio'), c.setAttribute('checked', 'checked'), c.setAttribute('name', 't'), b.appendChild(c), o.checkClone = b.cloneNode(!0).cloneNode(!0).lastChild.checked, b.innerHTML = '<textarea>x</textarea>', o.noCloneChecked = !!b.cloneNode(!0).lastChild.defaultValue; // NOSONAR
  }()); var ra = d.documentElement, sa = /^key/, ta = /^(?:mouse|pointer|contextmenu|drag|drop)|click/, ua = /^([^.]*)(?:\.(.+)|)/; function va() { // NOSONAR
    return !0; // NOSONAR
  } function wa() { // NOSONAR
    return !1; // NOSONAR
  } function xa() { // NOSONAR
    try { // NOSONAR
      return d.activeElement; // NOSONAR
    } catch (a) {} // NOSONAR
  } function ya(a, b, c, d, e, f) { // NOSONAR
    var g, h; if (typeof b === 'object') { // NOSONAR
      typeof c !== 'string' && (d = d || c, c = void 0); for (h in b) { // NOSONAR
        ya(a, h, c, d, b[h], f); // NOSONAR
      } return a; // NOSONAR
    } if (d == null && e == null ? (e = c, d = c = void 0) : e == null && (typeof c === 'string' ? (e = d, d = void 0) : (e = d, d = c, c = void 0)), e === !1) { // NOSONAR
      e = wa; // NOSONAR
    } else if (!e) { // NOSONAR
      return a; // NOSONAR
    } return f === 1 && (g = e, e = function(a) { // NOSONAR
      return r().off(a), g.apply(this, arguments); // NOSONAR
    }, e.guid = g.guid || (g.guid = r.guid++)), a.each(function() { // NOSONAR
      r.event.add(this, b, e, d, c); // NOSONAR
    }); // NOSONAR
  }r.event = {global: {}, add: function(a, b, c, d, e) { // NOSONAR
    var f, g, h, i, j, k, l, m, n, o, p, q = W.get(a); if (q) { // NOSONAR
      c.handler && (f = c, c = f.handler, e = f.selector), e && r.find.matchesSelector(ra, e), c.guid || (c.guid = r.guid++), (i = q.events) || (i = q.events = {}), (g = q.handle) || (g = q.handle = function(b) { // NOSONAR
        return typeof r !== 'undefined' && r.event.triggered !== b.type ? r.event.dispatch.apply(a, arguments) : void 0; // NOSONAR
      }), b = (b || '').match(L) || [ '' ], j = b.length; while (j--) { // NOSONAR
        h = ua.exec(b[j]) || [], n = p = h[1], o = (h[2] || '').split('.').sort(), n && (l = r.event.special[n] || {}, n = (e ? l.delegateType : l.bindType) || n, l = r.event.special[n] || {}, k = r.extend({type: n, origType: p, data: d, handler: c, guid: c.guid, selector: e, needsContext: e && r.expr.match.needsContext.test(e), namespace: o.join('.')}, f), (m = i[n]) || (m = i[n] = [], m.delegateCount = 0, l.setup && l.setup.call(a, d, o, g) !== !1 || a.addEventListener && a.addEventListener(n, g)), l.add && (l.add.call(a, k), k.handler.guid || (k.handler.guid = c.guid)), e ? m.splice(m.delegateCount++, 0, k) : m.push(k), r.event.global[n] = !0); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  }, remove: function(a, b, c, d, e) { // NOSONAR
    var f, g, h, i, j, k, l, m, n, o, p, q = W.hasData(a) && W.get(a); if (q && (i = q.events)) { // NOSONAR
      b = (b || '').match(L) || [ '' ], j = b.length; while (j--) { // NOSONAR
        if (h = ua.exec(b[j]) || [], n = p = h[1], o = (h[2] || '').split('.').sort(), n) { // NOSONAR
          l = r.event.special[n] || {}, n = (d ? l.delegateType : l.bindType) || n, m = i[n] || [], h = h[2] && new RegExp('(^|\\.)' + o.join('\\.(?:.*\\.|)') + '(\\.|$)'), g = f = m.length; while (f--) { // NOSONAR
            k = m[f], !e && p !== k.origType || c && c.guid !== k.guid || h && !h.test(k.namespace) || d && d !== k.selector && (d !== '**' || !k.selector) || (m.splice(f, 1), k.selector && m.delegateCount--, l.remove && l.remove.call(a, k)); // NOSONAR
          }g && !m.length && (l.teardown && l.teardown.call(a, o, q.handle) !== !1 || r.removeEvent(a, n, q.handle), delete i[n]); // NOSONAR
        } else { // NOSONAR
          for (n in i) { // NOSONAR
            r.event.remove(a, n + b[j], c, d, !0); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }r.isEmptyObject(i) && W.remove(a, 'handle events'); // NOSONAR
    } // NOSONAR
  }, dispatch: function(a) { // NOSONAR
    var b = r.event.fix(a), c, d, e, f, g, h, i = new Array(arguments.length), j = (W.get(this, 'events') || {})[b.type] || [], k = r.event.special[b.type] || {}; for (i[0] = b, c = 1; c < arguments.length; c++) { // NOSONAR
      i[c] = arguments[c]; // NOSONAR
    } if (b.delegateTarget = this, !k.preDispatch || k.preDispatch.call(this, b) !== !1) { // NOSONAR
      h = r.event.handlers.call(this, b, j), c = 0; while ((f = h[c++]) && !b.isPropagationStopped()) { // NOSONAR
        b.currentTarget = f.elem, d = 0; while ((g = f.handlers[d++]) && !b.isImmediatePropagationStopped()) { // NOSONAR
          b.rnamespace && !b.rnamespace.test(g.namespace) || (b.handleObj = g, b.data = g.data, e = ((r.event.special[g.origType] || {}).handle || g.handler).apply(f.elem, i), void 0 !== e && (b.result = e) === !1 && (b.preventDefault(), b.stopPropagation())); // NOSONAR
        } // NOSONAR
      } return k.postDispatch && k.postDispatch.call(this, b), b.result; // NOSONAR
    } // NOSONAR
  }, handlers: function(a, b) { // NOSONAR
    var c, d, e, f, g, h = [], i = b.delegateCount, j = a.target; if (i && j.nodeType && !(a.type === 'click' && a.button >= 1)) { // NOSONAR
      for (;j !== this; j = j.parentNode || this) { // NOSONAR
        if (j.nodeType === 1 && (a.type !== 'click' || j.disabled !== !0)) { // NOSONAR
          for (f = [], g = {}, c = 0; c < i; c++) { // NOSONAR
            d = b[c], e = d.selector + ' ', void 0 === g[e] && (g[e] = d.needsContext ? r(e, this).index(j) > -1 : r.find(e, this, null, [ j ]).length), g[e] && f.push(d); // NOSONAR
          }f.length && h.push({elem: j, handlers: f}); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return j = this, i < b.length && h.push({elem: j, handlers: b.slice(i)}), h; // NOSONAR
  }, addProp: function(a, b) { // NOSONAR
    Object.defineProperty(r.Event.prototype, a, {enumerable: !0, configurable: !0, get: r.isFunction(b) ? function() { // NOSONAR
      if (this.originalEvent) { // NOSONAR
        return b(this.originalEvent); // NOSONAR
      } // NOSONAR
    } : function() { // NOSONAR
      if (this.originalEvent) { // NOSONAR
        return this.originalEvent[a]; // NOSONAR
      } // NOSONAR
    }, set: function(b) { // NOSONAR
      Object.defineProperty(this, a, {enumerable: !0, configurable: !0, writable: !0, value: b}); // NOSONAR
    }}); // NOSONAR
  }, fix: function(a) { // NOSONAR
    return a[r.expando] ? a : new r.Event(a); // NOSONAR
  }, special: {load: {noBubble: !0}, focus: {trigger: function() { // NOSONAR
    if (this !== xa() && this.focus) { // NOSONAR
      return this.focus(), !1; // NOSONAR
    } // NOSONAR
  }, delegateType: 'focusin'}, blur: {trigger: function() { // NOSONAR
    if (this === xa() && this.blur) { // NOSONAR
      return this.blur(), !1; // NOSONAR
    } // NOSONAR
  }, delegateType: 'focusout'}, click: {trigger: function() { // NOSONAR
    if (this.type === 'checkbox' && this.click && B(this, 'input')) { // NOSONAR
      return this.click(), !1; // NOSONAR
    } // NOSONAR
  }, _default: function(a) { // NOSONAR
    return B(a.target, 'a'); // NOSONAR
  }}, beforeunload: {postDispatch: function(a) { // NOSONAR
    void 0 !== a.result && a.originalEvent && (a.originalEvent.returnValue = a.result); // NOSONAR
  }}}}, r.removeEvent = function(a, b, c) { // NOSONAR
    a.removeEventListener && a.removeEventListener(b, c); // NOSONAR
  }, r.Event = function(a, b) { // NOSONAR
    return this instanceof r.Event ? (a && a.type ? (this.originalEvent = a, this.type = a.type, this.isDefaultPrevented = a.defaultPrevented || void 0 === a.defaultPrevented && a.returnValue === !1 ? va : wa, this.target = a.target && a.target.nodeType === 3 ? a.target.parentNode : a.target, this.currentTarget = a.currentTarget, this.relatedTarget = a.relatedTarget) : this.type = a, b && r.extend(this, b), this.timeStamp = a && a.timeStamp || r.now(), void(this[r.expando] = !0)) : new r.Event(a, b); // NOSONAR
  }, r.Event.prototype = {constructor: r.Event, isDefaultPrevented: wa, isPropagationStopped: wa, isImmediatePropagationStopped: wa, isSimulated: !1, preventDefault: function() { // NOSONAR
    var a = this.originalEvent; this.isDefaultPrevented = va, a && !this.isSimulated && a.preventDefault(); // NOSONAR
  }, stopPropagation: function() { // NOSONAR
    var a = this.originalEvent; this.isPropagationStopped = va, a && !this.isSimulated && a.stopPropagation(); // NOSONAR
  }, stopImmediatePropagation: function() { // NOSONAR
    var a = this.originalEvent; this.isImmediatePropagationStopped = va, a && !this.isSimulated && a.stopImmediatePropagation(), this.stopPropagation(); // NOSONAR
  }}, r.each({altKey: !0, bubbles: !0, cancelable: !0, changedTouches: !0, ctrlKey: !0, detail: !0, eventPhase: !0, metaKey: !0, pageX: !0, pageY: !0, shiftKey: !0, view: !0, 'char': !0, charCode: !0, key: !0, keyCode: !0, button: !0, buttons: !0, clientX: !0, clientY: !0, offsetX: !0, offsetY: !0, pointerId: !0, pointerType: !0, screenX: !0, screenY: !0, targetTouches: !0, toElement: !0, touches: !0, which: function(a) { // NOSONAR
    var b = a.button; return a.which == null && sa.test(a.type) ? a.charCode != null ? a.charCode : a.keyCode : !a.which && void 0 !== b && ta.test(a.type) ? 1 & b ? 1 : 2 & b ? 3 : 4 & b ? 2 : 0 : a.which; // NOSONAR
  }}, r.event.addProp), r.each({mouseenter: 'mouseover', mouseleave: 'mouseout', pointerenter: 'pointerover', pointerleave: 'pointerout'}, function(a, b) { // NOSONAR
    r.event.special[a] = {delegateType: b, bindType: b, handle: function(a) { // NOSONAR
      var c, d = this, e = a.relatedTarget, f = a.handleObj; return e && (e === d || r.contains(d, e)) || (a.type = f.origType, c = f.handler.apply(this, arguments), a.type = b), c; // NOSONAR
    }}; // NOSONAR
  }), r.fn.extend({on: function(a, b, c, d) { // NOSONAR
    return ya(this, a, b, c, d); // NOSONAR
  }, one: function(a, b, c, d) { // NOSONAR
    return ya(this, a, b, c, d, 1); // NOSONAR
  }, off: function(a, b, c) { // NOSONAR
    var d, e; if (a && a.preventDefault && a.handleObj) { // NOSONAR
      return d = a.handleObj, r(a.delegateTarget).off(d.namespace ? d.origType + '.' + d.namespace : d.origType, d.selector, d.handler), this; // NOSONAR
    } if (typeof a === 'object') { // NOSONAR
      for (e in a) { // NOSONAR
        this.off(e, b, a[e]); // NOSONAR
      } return this; // NOSONAR
    } return b !== !1 && typeof b !== 'function' || (c = b, b = void 0), c === !1 && (c = wa), this.each(function() { // NOSONAR
      r.event.remove(this, a, c, b); // NOSONAR
    }); // NOSONAR
  }}); var za = /<(?!area|br|col|embed|hr|img|input|link|meta|param)(([a-z][^\/\0>\x20\t\r\n\f]*)[^>]*)\/>/gi, Aa = /<script|<style|<link/i, Ba = /checked\s*(?:[^=]|=\s*.checked.)/i, Ca = /^true\/(.*)/, Da = /^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g; function Ea(a, b) { // NOSONAR
    return B(a, 'table') && B(b.nodeType !== 11 ? b : b.firstChild, 'tr') ? r('>tbody', a)[0] || a : a; // NOSONAR
  } function Fa(a) { // NOSONAR
    return a.type = (a.getAttribute('type') !== null) + '/' + a.type, a; // NOSONAR
  } function Ga(a) { // NOSONAR
    var b = Ca.exec(a.type); return b ? a.type = b[1] : a.removeAttribute('type'), a; // NOSONAR
  } function Ha(a, b) { // NOSONAR
    var c, d, e, f, g, h, i, j; if (b.nodeType === 1) { // NOSONAR
      if (W.hasData(a) && (f = W.access(a), g = W.set(b, f), j = f.events)) { // NOSONAR
        delete g.handle, g.events = {}; for (e in j) { // NOSONAR
          for (c = 0, d = j[e].length; c < d; c++) { // NOSONAR
            r.event.add(b, e, j[e][c]); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }X.hasData(a) && (h = X.access(a), i = r.extend({}, h), X.set(b, i)); // NOSONAR
    } // NOSONAR
  } function Ia(a, b) { // NOSONAR
    var c = b.nodeName.toLowerCase(); c === 'input' && ja.test(a.type) ? b.checked = a.checked : c !== 'input' && c !== 'textarea' || (b.defaultValue = a.defaultValue); // NOSONAR
  } function Ja(a, b, c, d) { // NOSONAR
    b = g.apply([], b); var e, f, h, i, j, k, l = 0, m = a.length, n = m - 1, q = b[0], s = r.isFunction(q); if (s || m > 1 && typeof q === 'string' && !o.checkClone && Ba.test(q)) { // NOSONAR
      return a.each(function(e) { // NOSONAR
        var f = a.eq(e); s && (b[0] = q.call(this, e, f.html())), Ja(f, b, c, d); // NOSONAR
      }); // NOSONAR
    } if (m && (e = qa(b, a[0].ownerDocument, !1, a, d), f = e.firstChild, e.childNodes.length === 1 && (e = f), f || d)) { // NOSONAR
      for (h = r.map(na(e, 'script'), Fa), i = h.length; l < m; l++) { // NOSONAR
        j = e, l !== n && (j = r.clone(j, !0, !0), i && r.merge(h, na(j, 'script'))), c.call(a[l], j, l); // NOSONAR
      } if (i) { // NOSONAR
        for (k = h[h.length - 1].ownerDocument, r.map(h, Ga), l = 0; l < i; l++) { // NOSONAR
          j = h[l], la.test(j.type || '') && !W.access(j, 'globalEval') && r.contains(k, j) && (j.src ? r._evalUrl && r._evalUrl(j.src) : p(j.textContent.replace(Da, ''), k)); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return a; // NOSONAR
  } function Ka(a, b, c) { // NOSONAR
    for (var d, e = b ? r.filter(b, a) : a, f = 0; (d = e[f]) != null; f++) { // NOSONAR
      c || d.nodeType !== 1 || r.cleanData(na(d)), d.parentNode && (c && r.contains(d.ownerDocument, d) && oa(na(d, 'script')), d.parentNode.removeChild(d)); // NOSONAR
    } return a; // NOSONAR
  }r.extend({htmlPrefilter: function(a) { // NOSONAR
    return a.replace(za, '<$1></$2>'); // NOSONAR
  }, clone: function(a, b, c) { // NOSONAR
    var d, e, f, g, h = a.cloneNode(!0), i = r.contains(a.ownerDocument, a); if (!(o.noCloneChecked || a.nodeType !== 1 && a.nodeType !== 11 || r.isXMLDoc(a))) { // NOSONAR
      for (g = na(h), f = na(a), d = 0, e = f.length; d < e; d++) { // NOSONAR
        Ia(f[d], g[d]); // NOSONAR
      } // NOSONAR
    } if (b) { // NOSONAR
      if (c) { // NOSONAR
        for (f = f || na(a), g = g || na(h), d = 0, e = f.length; d < e; d++) { // NOSONAR
          Ha(f[d], g[d]); // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        Ha(a, h); // NOSONAR
      } // NOSONAR
    } return g = na(h, 'script'), g.length > 0 && oa(g, !i && na(a, 'script')), h; // NOSONAR
  }, cleanData: function(a) { // NOSONAR
    for (var b, c, d, e = r.event.special, f = 0; void 0 !== (c = a[f]); f++) { // NOSONAR
      if (U(c)) { // NOSONAR
        if (b = c[W.expando]) { // NOSONAR
          if (b.events) { // NOSONAR
            for (d in b.events) { // NOSONAR
              e[d] ? r.event.remove(c, d) : r.removeEvent(c, d, b.handle); // NOSONAR
            } // NOSONAR
          }c[W.expando] = void 0; // NOSONAR
        }c[X.expando] && (c[X.expando] = void 0); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  }}), r.fn.extend({detach: function(a) { // NOSONAR
    return Ka(this, a, !0); // NOSONAR
  }, remove: function(a) { // NOSONAR
    return Ka(this, a); // NOSONAR
  }, text: function(a) { // NOSONAR
    return T(this, function(a) { // NOSONAR
      return void 0 === a ? r.text(this) : this.empty().each(function() { // NOSONAR
        this.nodeType !== 1 && this.nodeType !== 11 && this.nodeType !== 9 || (this.textContent = a); // NOSONAR
      }); // NOSONAR
    }, null, a, arguments.length); // NOSONAR
  }, append: function() { // NOSONAR
    return Ja(this, arguments, function(a) { // NOSONAR
      if (this.nodeType === 1 || this.nodeType === 11 || this.nodeType === 9) { // NOSONAR
        var b = Ea(this, a); b.appendChild(a); // NOSONAR
      } // NOSONAR
    }); // NOSONAR
  }, prepend: function() { // NOSONAR
    return Ja(this, arguments, function(a) { // NOSONAR
      if (this.nodeType === 1 || this.nodeType === 11 || this.nodeType === 9) { // NOSONAR
        var b = Ea(this, a); b.insertBefore(a, b.firstChild); // NOSONAR
      } // NOSONAR
    }); // NOSONAR
  }, before: function() { // NOSONAR
    return Ja(this, arguments, function(a) { // NOSONAR
      this.parentNode && this.parentNode.insertBefore(a, this); // NOSONAR
    }); // NOSONAR
  }, after: function() { // NOSONAR
    return Ja(this, arguments, function(a) { // NOSONAR
      this.parentNode && this.parentNode.insertBefore(a, this.nextSibling); // NOSONAR
    }); // NOSONAR
  }, empty: function() { // NOSONAR
    for (var a, b = 0; (a = this[b]) != null; b++) { // NOSONAR
      a.nodeType === 1 && (r.cleanData(na(a, !1)), a.textContent = ''); // NOSONAR
    } return this; // NOSONAR
  }, clone: function(a, b) { // NOSONAR
    return a = a != null && a, b = b == null ? a : b, this.map(function() { // NOSONAR
      return r.clone(this, a, b); // NOSONAR
    }); // NOSONAR
  }, html: function(a) { // NOSONAR
    return T(this, function(a) { // NOSONAR
      var b = this[0] || {}, c = 0, d = this.length; if (void 0 === a && b.nodeType === 1) { // NOSONAR
        return b.innerHTML; // NOSONAR
      } if (typeof a === 'string' && !Aa.test(a) && !ma[(ka.exec(a) || ['', ''])[1].toLowerCase()]) { // NOSONAR
        a = r.htmlPrefilter(a); try { // NOSONAR
          for (;c < d; c++) { // NOSONAR
            b = this[c] || {}, b.nodeType === 1 && (r.cleanData(na(b, !1)), b.innerHTML = a); // NOSONAR
          }b = 0; // NOSONAR
        } catch (e) {} // NOSONAR
      }b && this.empty().append(a); // NOSONAR
    }, null, a, arguments.length); // NOSONAR
  }, replaceWith: function() { // NOSONAR
    var a = []; return Ja(this, arguments, function(b) { // NOSONAR
      var c = this.parentNode; r.inArray(this, a) < 0 && (r.cleanData(na(this)), c && c.replaceChild(b, this)); // NOSONAR
    }, a); // NOSONAR
  }}), r.each({appendTo: 'append', prependTo: 'prepend', insertBefore: 'before', insertAfter: 'after', replaceAll: 'replaceWith'}, function(a, b) { // NOSONAR
    r.fn[a] = function(a) { // NOSONAR
      for (var c, d = [], e = r(a), f = e.length - 1, g = 0; g <= f; g++) { // NOSONAR
        c = g === f ? this : this.clone(!0), r(e[g])[b](c), h.apply(d, c.get()); // NOSONAR
      } return this.pushStack(d); // NOSONAR
    }; // NOSONAR
  }); var La = /^margin/, Ma = new RegExp('^(' + aa + ')(?!px)[a-z%]+$', 'i'), Na = function(b) { // NOSONAR
    var c = b.ownerDocument.defaultView; return c && c.opener || (c = a), c.getComputedStyle(b); // NOSONAR
  }; !(function() { // NOSONAR
    function b() { // NOSONAR
      if (i) { // NOSONAR
        i.style.cssText = 'box-sizing:border-box;position:relative;display:block;margin:auto;border:1px;padding:1px;top:1%;width:50%', i.innerHTML = '', ra.appendChild(h); var b = a.getComputedStyle(i); c = b.top !== '1%', g = b.marginLeft === '2px', e = b.width === '4px', i.style.marginRight = '50%', f = b.marginRight === '4px', ra.removeChild(h), i = null; // NOSONAR
      } // NOSONAR
    } var c, e, f, g, h = d.createElement('div'), i = d.createElement('div'); i.style && (i.style.backgroundClip = 'content-box', i.cloneNode(!0).style.backgroundClip = '', o.clearCloneStyle = i.style.backgroundClip === 'content-box', h.style.cssText = 'border:0;width:8px;height:0;top:0;left:-9999px;padding:0;margin-top:1px;position:absolute', h.appendChild(i), r.extend(o, {pixelPosition: function() { // NOSONAR
      return b(), c; // NOSONAR
    }, boxSizingReliable: function() { // NOSONAR
      return b(), e; // NOSONAR
    }, pixelMarginRight: function() { // NOSONAR
      return b(), f; // NOSONAR
    }, reliableMarginLeft: function() { // NOSONAR
      return b(), g; // NOSONAR
    }})); // NOSONAR
  }()); function Oa(a, b, c) { // NOSONAR
    var d, e, f, g, h = a.style; return c = c || Na(a), c && (g = c.getPropertyValue(b) || c[b], g !== '' || r.contains(a.ownerDocument, a) || (g = r.style(a, b)), !o.pixelMarginRight() && Ma.test(g) && La.test(b) && (d = h.width, e = h.minWidth, f = h.maxWidth, h.minWidth = h.maxWidth = h.width = g, g = c.width, h.width = d, h.minWidth = e, h.maxWidth = f)), void 0 !== g ? g + '' : g; // NOSONAR
  } function Pa(a, b) { // NOSONAR
    return {get: function() { // NOSONAR
      return a() ? void delete this.get : (this.get = b).apply(this, arguments); // NOSONAR
    }}; // NOSONAR
  } var Qa = /^(none|table(?!-c[ea]).+)/, Ra = /^--/, Sa = {position: 'absolute', visibility: 'hidden', display: 'block'}, Ta = {letterSpacing: '0', fontWeight: '400'}, Ua = ['Webkit', 'Moz', 'ms'], Va = d.createElement('div').style; function Wa(a) { // NOSONAR
    if (a in Va) { // NOSONAR
      return a; // NOSONAR
    } var b = a[0].toUpperCase() + a.slice(1), c = Ua.length; while (c--) { // NOSONAR
      if (a = Ua[c] + b, a in Va) { // NOSONAR
        return a; // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function Xa(a) { // NOSONAR
    var b = r.cssProps[a]; return b || (b = r.cssProps[a] = Wa(a) || a), b; // NOSONAR
  } function Ya(a, b, c) { // NOSONAR
    var d = ba.exec(b); return d ? Math.max(0, d[2] - (c || 0)) + (d[3] || 'px') : b; // NOSONAR
  } function Za(a, b, c, d, e) { // NOSONAR
    var f, g = 0; for (f = c === (d ? 'border' : 'content') ? 4 : b === 'width' ? 1 : 0; f < 4; f += 2) { // NOSONAR
      c === 'margin' && (g += r.css(a, c + ca[f], !0, e)), d ? (c === 'content' && (g -= r.css(a, 'padding' + ca[f], !0, e)), c !== 'margin' && (g -= r.css(a, 'border' + ca[f] + 'Width', !0, e))) : (g += r.css(a, 'padding' + ca[f], !0, e), c !== 'padding' && (g += r.css(a, 'border' + ca[f] + 'Width', !0, e))); // NOSONAR
    } return g; // NOSONAR
  } function $a(a, b, c) { // NOSONAR
    var d, e = Na(a), f = Oa(a, b, e), g = r.css(a, 'boxSizing', !1, e) === 'border-box'; return Ma.test(f) ? f : (d = g && (o.boxSizingReliable() || f === a.style[b]), f === 'auto' && (f = a['offset' + b[0].toUpperCase() + b.slice(1)]), f = parseFloat(f) || 0, f + Za(a, b, c || (g ? 'border' : 'content'), d, e) + 'px'); // NOSONAR
  }r.extend({cssHooks: {opacity: {get: function(a, b) { // NOSONAR
    if (b) { // NOSONAR
      var c = Oa(a, 'opacity'); return c === '' ? '1' : c; // NOSONAR
    } // NOSONAR
  }}}, cssNumber: {animationIterationCount: !0, columnCount: !0, fillOpacity: !0, flexGrow: !0, flexShrink: !0, fontWeight: !0, lineHeight: !0, opacity: !0, order: !0, orphans: !0, widows: !0, zIndex: !0, zoom: !0}, cssProps: {'float': 'cssFloat'}, style: function(a, b, c, d) { // NOSONAR
    if (a && a.nodeType !== 3 && a.nodeType !== 8 && a.style) { // NOSONAR
      var e, f, g, h = r.camelCase(b), i = Ra.test(b), j = a.style; return i || (b = Xa(h)), g = r.cssHooks[b] || r.cssHooks[h], void 0 === c ? g && 'get' in g && void 0 !== (e = g.get(a, !1, d)) ? e : j[b] : (f = typeof c, f === 'string' && (e = ba.exec(c)) && e[1] && (c = fa(a, b, e), f = 'number'), c != null && c === c && (f === 'number' && (c += e && e[3] || (r.cssNumber[h] ? '' : 'px')), o.clearCloneStyle || c !== '' || b.indexOf('background') !== 0 || (j[b] = 'inherit'), g && 'set' in g && void 0 === (c = g.set(a, c, d)) || (i ? j.setProperty(b, c) : j[b] = c)), void 0); // NOSONAR
    } // NOSONAR
  }, css: function(a, b, c, d) { // NOSONAR
    var e, f, g, h = r.camelCase(b), i = Ra.test(b); return i || (b = Xa(h)), g = r.cssHooks[b] || r.cssHooks[h], g && 'get' in g && (e = g.get(a, !0, c)), void 0 === e && (e = Oa(a, b, d)), e === 'normal' && b in Ta && (e = Ta[b]), c === '' || c ? (f = parseFloat(e), c === !0 || isFinite(f) ? f || 0 : e) : e; // NOSONAR
  }}), r.each(['height', 'width'], function(a, b) { // NOSONAR
    r.cssHooks[b] = {get: function(a, c, d) { // NOSONAR
      if (c) { // NOSONAR
        return !Qa.test(r.css(a, 'display')) || a.getClientRects().length && a.getBoundingClientRect().width ? $a(a, b, d) : ea(a, Sa, function() { // NOSONAR
          return $a(a, b, d); // NOSONAR
        }); // NOSONAR
      } // NOSONAR
    }, set: function(a, c, d) { // NOSONAR
      var e, f = d && Na(a), g = d && Za(a, b, d, r.css(a, 'boxSizing', !1, f) === 'border-box', f); return g && (e = ba.exec(c)) && (e[3] || 'px') !== 'px' && (a.style[b] = c, c = r.css(a, b)), Ya(a, c, g); // NOSONAR
    }}; // NOSONAR
  }), r.cssHooks.marginLeft = Pa(o.reliableMarginLeft, function(a, b) { // NOSONAR
    if (b) { // NOSONAR
      return (parseFloat(Oa(a, 'marginLeft')) || a.getBoundingClientRect().left - ea(a, {marginLeft: 0}, function() { // NOSONAR
        return a.getBoundingClientRect().left; // NOSONAR
      })) + 'px'; // NOSONAR
    } // NOSONAR
  }), r.each({margin: '', padding: '', border: 'Width'}, function(a, b) { // NOSONAR
    r.cssHooks[a + b] = {expand: function(c) { // NOSONAR
      for (var d = 0, e = {}, f = typeof c === 'string' ? c.split(' ') : [ c ]; d < 4; d++) { // NOSONAR
        e[a + ca[d] + b] = f[d] || f[d - 2] || f[0]; // NOSONAR
      } return e; // NOSONAR
    }}, La.test(a) || (r.cssHooks[a + b].set = Ya); // NOSONAR
  }), r.fn.extend({css: function(a, b) { // NOSONAR
    return T(this, function(a, b, c) { // NOSONAR
      var d, e, f = {}, g = 0; if (Array.isArray(b)) { // NOSONAR
        for (d = Na(a), e = b.length; g < e; g++) { // NOSONAR
          f[b[g]] = r.css(a, b[g], !1, d); // NOSONAR
        } return f; // NOSONAR
      } return void 0 !== c ? r.style(a, b, c) : r.css(a, b); // NOSONAR
    }, a, b, arguments.length > 1); // NOSONAR
  }}); function _a(a, b, c, d, e) { // NOSONAR
    return new _a.prototype.init(a, b, c, d, e); // NOSONAR
  }r.Tween = _a, _a.prototype = {constructor: _a, init: function(a, b, c, d, e, f) { // NOSONAR
    this.elem = a, this.prop = c, this.easing = e || r.easing._default, this.options = b, this.start = this.now = this.cur(), this.end = d, this.unit = f || (r.cssNumber[c] ? '' : 'px'); // NOSONAR
  }, cur: function() { // NOSONAR
    var a = _a.propHooks[this.prop]; return a && a.get ? a.get(this) : _a.propHooks._default.get(this); // NOSONAR
  }, run: function(a) { // NOSONAR
    var b, c = _a.propHooks[this.prop]; return this.options.duration ? this.pos = b = r.easing[this.easing](a, this.options.duration * a, 0, 1, this.options.duration) : this.pos = b = a, this.now = (this.end - this.start) * b + this.start, this.options.step && this.options.step.call(this.elem, this.now, this), c && c.set ? c.set(this) : _a.propHooks._default.set(this), this; // NOSONAR
  }}, _a.prototype.init.prototype = _a.prototype, _a.propHooks = {_default: {get: function(a) { // NOSONAR
    var b; return a.elem.nodeType !== 1 || a.elem[a.prop] != null && a.elem.style[a.prop] == null ? a.elem[a.prop] : (b = r.css(a.elem, a.prop, ''), b && b !== 'auto' ? b : 0); // NOSONAR
  }, set: function(a) { // NOSONAR
    r.fx.step[a.prop] ? r.fx.step[a.prop](a) : a.elem.nodeType !== 1 || a.elem.style[r.cssProps[a.prop]] == null && !r.cssHooks[a.prop] ? a.elem[a.prop] = a.now : r.style(a.elem, a.prop, a.now + a.unit); // NOSONAR
  }}}, _a.propHooks.scrollTop = _a.propHooks.scrollLeft = {set: function(a) { // NOSONAR
    a.elem.nodeType && a.elem.parentNode && (a.elem[a.prop] = a.now); // NOSONAR
  }}, r.easing = {linear: function(a) { // NOSONAR
    return a; // NOSONAR
  }, swing: function(a) { // NOSONAR
    return.5 - Math.cos(a * Math.PI) / 2; // NOSONAR
  }, _default: 'swing'}, r.fx = _a.prototype.init, r.fx.step = {}; var ab, bb, cb = /^(?:toggle|show|hide)$/, db = /queueHooks$/; function eb() { // NOSONAR
    bb && (d.hidden === !1 && a.requestAnimationFrame ? a.requestAnimationFrame(eb) : a.setTimeout(eb, r.fx.interval), r.fx.tick()); // NOSONAR
  } function fb() { // NOSONAR
    return a.setTimeout(function() { // NOSONAR
      ab = void 0; // NOSONAR
    }), ab = r.now(); // NOSONAR
  } function gb(a, b) { // NOSONAR
    var c, d = 0, e = {height: a}; for (b = b ? 1 : 0; d < 4; d += 2 - b) { // NOSONAR
      c = ca[d], e['margin' + c] = e['padding' + c] = a; // NOSONAR
    } return b && (e.opacity = e.width = a), e; // NOSONAR
  } function hb(a, b, c) { // NOSONAR
    for (var d, e = (kb.tweeners[b] || []).concat(kb.tweeners['*']), f = 0, g = e.length; f < g; f++) { // NOSONAR
      if (d = e[f].call(c, b, a)) { // NOSONAR
        return d; // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function ib(a, b, c) { // NOSONAR
    var d, e, f, g, h, i, j, k, l = 'width' in b || 'height' in b, m = this, n = {}, o = a.style, p = a.nodeType && da(a), q = W.get(a, 'fxshow'); c.queue || (g = r._queueHooks(a, 'fx'), g.unqueued == null && (g.unqueued = 0, h = g.empty.fire, g.empty.fire = function() { // NOSONAR
      g.unqueued || h(); // NOSONAR
    }), g.unqueued++, m.always(function() { // NOSONAR
        m.always(function() { // NOSONAR
          g.unqueued--, r.queue(a, 'fx').length || g.empty.fire(); // NOSONAR
        }); // NOSONAR
      })); for (d in b) { // NOSONAR
      if (e = b[d], cb.test(e)) { // NOSONAR
        if (delete b[d], f = f || e === 'toggle', e === (p ? 'hide' : 'show')) { // NOSONAR
          if (e !== 'show' || !q || void 0 === q[d]) { // NOSONAR
            continue; // NOSONAR
          } p = !0; // NOSONAR
        }n[d] = q && q[d] || r.style(a, d); // NOSONAR
      } // NOSONAR
    } if (i = !r.isEmptyObject(b), i || !r.isEmptyObject(n)) { // NOSONAR
      l && a.nodeType === 1 && (c.overflow = [o.overflow, o.overflowX, o.overflowY], j = q && q.display, j == null && (j = W.get(a, 'display')), k = r.css(a, 'display'), k === 'none' && (j ? k = j : (ia([ a ], !0), j = a.style.display || j, k = r.css(a, 'display'), ia([ a ]))), (k === 'inline' || k === 'inline-block' && j != null) && r.css(a, 'float') === 'none' && (i || (m.done(function() { // NOSONAR
        o.display = j; // NOSONAR
      }), j == null && (k = o.display, j = k === 'none' ? '' : k)), o.display = 'inline-block')), c.overflow && (o.overflow = 'hidden', m.always(function() { // NOSONAR
        o.overflow = c.overflow[0], o.overflowX = c.overflow[1], o.overflowY = c.overflow[2]; // NOSONAR
      })), i = !1; for (d in n) { // NOSONAR
        i || (q ? 'hidden' in q && (p = q.hidden) : q = W.access(a, 'fxshow', {display: j}), f && (q.hidden = !p), p && ia([ a ], !0), m.done(function() { // NOSONAR
          p || ia([ a ]), W.remove(a, 'fxshow'); for (d in n) { // NOSONAR
            r.style(a, d, n[d]); // NOSONAR
          } // NOSONAR
        })), i = hb(p ? q[d] : 0, d, m), d in q || (q[d] = i.start, p && (i.end = i.start, i.start = 0)); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function jb(a, b) { // NOSONAR
    var c, d, e, f, g; for (c in a) { // NOSONAR
      if (d = r.camelCase(c), e = b[d], f = a[c], Array.isArray(f) && (e = f[1], f = a[c] = f[0]), c !== d && (a[d] = f, delete a[c]), g = r.cssHooks[d], g && 'expand' in g) { // NOSONAR
        f = g.expand(f), delete a[d]; for (c in f) { // NOSONAR
          c in a || (a[c] = f[c], b[c] = e); // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        b[d] = e; // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function kb(a, b, c) { // NOSONAR
    var d, e, f = 0, g = kb.prefilters.length, h = r.Deferred().always(function() { // NOSONAR
        delete i.elem; // NOSONAR
      }), i = function() { // NOSONAR
        if (e) { // NOSONAR
          return !1; // NOSONAR
        } for (var b = ab || fb(), c = Math.max(0, j.startTime + j.duration - b), d = c / j.duration || 0, f = 1 - d, g = 0, i = j.tweens.length; g < i; g++) { // NOSONAR
          j.tweens[g].run(f); // NOSONAR
        } return h.notifyWith(a, [j, f, c]), f < 1 && i ? c : (i || h.notifyWith(a, [j, 1, 0]), h.resolveWith(a, [ j ]), !1); // NOSONAR
      }, j = h.promise({elem: a, props: r.extend({}, b), opts: r.extend(!0, {specialEasing: {}, easing: r.easing._default}, c), originalProperties: b, originalOptions: c, startTime: ab || fb(), duration: c.duration, tweens: [], createTween: function(b, c) { // NOSONAR
        var d = r.Tween(a, j.opts, b, c, j.opts.specialEasing[b] || j.opts.easing); return j.tweens.push(d), d; // NOSONAR
      }, stop: function(b) { // NOSONAR
        var c = 0, d = b ? j.tweens.length : 0; if (e) { // NOSONAR
          return this; // NOSONAR
        } for (e = !0; c < d; c++) { // NOSONAR
          j.tweens[c].run(1); // NOSONAR
        } return b ? (h.notifyWith(a, [j, 1, 0]), h.resolveWith(a, [j, b])) : h.rejectWith(a, [j, b]), this; // NOSONAR
      }}), k = j.props; for (jb(k, j.opts.specialEasing); f < g; f++) { // NOSONAR
      if (d = kb.prefilters[f].call(j, a, k, j.opts)) { // NOSONAR
        return r.isFunction(d.stop) && (r._queueHooks(j.elem, j.opts.queue).stop = r.proxy(d.stop, d)), d; // NOSONAR
      } // NOSONAR
    } return r.map(k, hb, j), r.isFunction(j.opts.start) && j.opts.start.call(a, j), j.progress(j.opts.progress).done(j.opts.done, j.opts.complete).fail(j.opts.fail).always(j.opts.always), r.fx.timer(r.extend(i, {elem: a, anim: j, queue: j.opts.queue})), j; // NOSONAR
  }r.Animation = r.extend(kb, {tweeners: {'*': [ function(a, b) { // NOSONAR
    var c = this.createTween(a, b); return fa(c.elem, a, ba.exec(b), c), c; // NOSONAR
  } ]}, tweener: function(a, b) { // NOSONAR
    r.isFunction(a) ? (b = a, a = [ '*' ]) : a = a.match(L); for (var c, d = 0, e = a.length; d < e; d++) { // NOSONAR
      c = a[d], kb.tweeners[c] = kb.tweeners[c] || [], kb.tweeners[c].unshift(b); // NOSONAR
    } // NOSONAR
  }, prefilters: [ ib ], prefilter: function(a, b) { // NOSONAR
    b ? kb.prefilters.unshift(a) : kb.prefilters.push(a); // NOSONAR
  }}), r.speed = function(a, b, c) { // NOSONAR
    var d = a && typeof a === 'object' ? r.extend({}, a) : {complete: c || !c && b || r.isFunction(a) && a, duration: a, easing: c && b || b && !r.isFunction(b) && b}; return r.fx.off ? d.duration = 0 : typeof d.duration !== 'number' && (d.duration in r.fx.speeds ? d.duration = r.fx.speeds[d.duration] : d.duration = r.fx.speeds._default), d.queue != null && d.queue !== !0 || (d.queue = 'fx'), d.old = d.complete, d.complete = function() { // NOSONAR
      r.isFunction(d.old) && d.old.call(this), d.queue && r.dequeue(this, d.queue); // NOSONAR
    }, d; // NOSONAR
  }, r.fn.extend({fadeTo: function(a, b, c, d) { // NOSONAR
    return this.filter(da).css('opacity', 0).show().end().animate({opacity: b}, a, c, d); // NOSONAR
  }, animate: function(a, b, c, d) { // NOSONAR
    var e = r.isEmptyObject(a), f = r.speed(b, c, d), g = function() { // NOSONAR
      var b = kb(this, r.extend({}, a), f); (e || W.get(this, 'finish')) && b.stop(!0); // NOSONAR
    }; return g.finish = g, e || f.queue === !1 ? this.each(g) : this.queue(f.queue, g); // NOSONAR
  }, stop: function(a, b, c) { // NOSONAR
    var d = function(a) { // NOSONAR
      var b = a.stop; delete a.stop, b(c); // NOSONAR
    }; return typeof a !== 'string' && (c = b, b = a, a = void 0), b && a !== !1 && this.queue(a || 'fx', []), this.each(function() { // NOSONAR
      var b = !0, e = a != null && a + 'queueHooks', f = r.timers, g = W.get(this); if (e) { // NOSONAR
        g[e] && g[e].stop && d(g[e]); // NOSONAR
      } else { // NOSONAR
        for (e in g) { // NOSONAR
          g[e] && g[e].stop && db.test(e) && d(g[e]); // NOSONAR
        } // NOSONAR
      } for (e = f.length; e--;) { // NOSONAR
        f[e].elem !== this || a != null && f[e].queue !== a || (f[e].anim.stop(c), b = !1, f.splice(e, 1)); // NOSONAR
      }!b && c || r.dequeue(this, a); // NOSONAR
    }); // NOSONAR
  }, finish: function(a) { // NOSONAR
    return a !== !1 && (a = a || 'fx'), this.each(function() { // NOSONAR
      var b, c = W.get(this), d = c[a + 'queue'], e = c[a + 'queueHooks'], f = r.timers, g = d ? d.length : 0; for (c.finish = !0, r.queue(this, a, []), e && e.stop && e.stop.call(this, !0), b = f.length; b--;) { // NOSONAR
        f[b].elem === this && f[b].queue === a && (f[b].anim.stop(!0), f.splice(b, 1)); // NOSONAR
      } for (b = 0; b < g; b++) { // NOSONAR
        d[b] && d[b].finish && d[b].finish.call(this); // NOSONAR
      } delete c.finish; // NOSONAR
    }); // NOSONAR
  }}), r.each(['toggle', 'show', 'hide'], function(a, b) { // NOSONAR
    var c = r.fn[b]; r.fn[b] = function(a, d, e) { // NOSONAR
      return a == null || typeof a === 'boolean' ? c.apply(this, arguments) : this.animate(gb(b, !0), a, d, e); // NOSONAR
    }; // NOSONAR
  }), r.each({slideDown: gb('show'), slideUp: gb('hide'), slideToggle: gb('toggle'), fadeIn: {opacity: 'show'}, fadeOut: {opacity: 'hide'}, fadeToggle: {opacity: 'toggle'}}, function(a, b) { // NOSONAR
    r.fn[a] = function(a, c, d) { // NOSONAR
      return this.animate(b, a, c, d); // NOSONAR
    }; // NOSONAR
  }), r.timers = [], r.fx.tick = function() { // NOSONAR
    var a, b = 0, c = r.timers; for (ab = r.now(); b < c.length; b++) { // NOSONAR
      a = c[b], a() || c[b] !== a || c.splice(b--, 1); // NOSONAR
    }c.length || r.fx.stop(), ab = void 0; // NOSONAR
  }, r.fx.timer = function(a) { // NOSONAR
    r.timers.push(a), r.fx.start(); // NOSONAR
  }, r.fx.interval = 13, r.fx.start = function() { // NOSONAR
    bb || (bb = !0, eb()); // NOSONAR
  }, r.fx.stop = function() { // NOSONAR
    bb = null; // NOSONAR
  }, r.fx.speeds = {slow: 600, fast: 200, _default: 400}, r.fn.delay = function(b, c) { // NOSONAR
    return b = r.fx ? r.fx.speeds[b] || b : b, c = c || 'fx', this.queue(c, function(c, d) { // NOSONAR
      var e = a.setTimeout(c, b); d.stop = function() { // NOSONAR
        a.clearTimeout(e); // NOSONAR
      }; // NOSONAR
    }); // NOSONAR
  }, (function() { // NOSONAR
    var a = d.createElement('input'), b = d.createElement('select'), c = b.appendChild(d.createElement('option')); a.type = 'checkbox', o.checkOn = a.value !== '', o.optSelected = c.selected, a = d.createElement('input'), a.value = 't', a.type = 'radio', o.radioValue = a.value === 't'; // NOSONAR
  }()); var lb, mb = r.expr.attrHandle; r.fn.extend({attr: function(a, b) { // NOSONAR
    return T(this, r.attr, a, b, arguments.length > 1); // NOSONAR
  }, removeAttr: function(a) { // NOSONAR
    return this.each(function() { // NOSONAR
      r.removeAttr(this, a); // NOSONAR
    }); // NOSONAR
  }}), r.extend({attr: function(a, b, c) { // NOSONAR
    var d, e, f = a.nodeType; if (f !== 3 && f !== 8 && f !== 2) { // NOSONAR
      return typeof a.getAttribute === 'undefined' ? r.prop(a, b, c) : (f === 1 && r.isXMLDoc(a) || (e = r.attrHooks[b.toLowerCase()] || (r.expr.match.bool.test(b) ? lb : void 0)), void 0 !== c ? c === null ? void r.removeAttr(a, b) : e && 'set' in e && void 0 !== (d = e.set(a, c, b)) ? d : (a.setAttribute(b, c + ''), c) : e && 'get' in e && (d = e.get(a, b)) !== null ? d : (d = r.find.attr(a, b), // NOSONAR
        d == null ? void 0 : d)); // NOSONAR
    } // NOSONAR
  }, attrHooks: {type: {set: function(a, b) { // NOSONAR
    if (!o.radioValue && b === 'radio' && B(a, 'input')) { // NOSONAR
      var c = a.value; return a.setAttribute('type', b), c && (a.value = c), b; // NOSONAR
    } // NOSONAR
  }}}, removeAttr: function(a, b) { // NOSONAR
    var c, d = 0, e = b && b.match(L); if (e && a.nodeType === 1) { // NOSONAR
      while (c = e[d++]) { // NOSONAR
        a.removeAttribute(c); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  }}), lb = {set: function(a, b, c) { // NOSONAR
    return b === !1 ? r.removeAttr(a, c) : a.setAttribute(c, c), c; // NOSONAR
  }}, r.each(r.expr.match.bool.source.match(/\w+/g), function(a, b) { // NOSONAR
    var c = mb[b] || r.find.attr; mb[b] = function(a, b, d) { // NOSONAR
      var e, f, g = b.toLowerCase(); return d || (f = mb[g], mb[g] = e, e = c(a, b, d) != null ? g : null, mb[g] = f), e; // NOSONAR
    }; // NOSONAR
  }); var nb = /^(?:input|select|textarea|button)$/i, ob = /^(?:a|area)$/i; r.fn.extend({prop: function(a, b) { // NOSONAR
    return T(this, r.prop, a, b, arguments.length > 1); // NOSONAR
  }, removeProp: function(a) { // NOSONAR
    return this.each(function() { // NOSONAR
      delete this[r.propFix[a] || a]; // NOSONAR
    }); // NOSONAR
  }}), r.extend({prop: function(a, b, c) { // NOSONAR
    var d, e, f = a.nodeType; if (f !== 3 && f !== 8 && f !== 2) { // NOSONAR
      return f === 1 && r.isXMLDoc(a) || (b = r.propFix[b] || b, e = r.propHooks[b]), void 0 !== c ? e && 'set' in e && void 0 !== (d = e.set(a, c, b)) ? d : a[b] = c : e && 'get' in e && (d = e.get(a, b)) !== null ? d : a[b]; // NOSONAR
    } // NOSONAR
  }, propHooks: {tabIndex: {get: function(a) { // NOSONAR
    var b = r.find.attr(a, 'tabindex'); return b ? parseInt(b, 10) : nb.test(a.nodeName) || ob.test(a.nodeName) && a.href ? 0 : -1; // NOSONAR
  }}}, propFix: {'for': 'htmlFor', 'class': 'className'}}), o.optSelected || (r.propHooks.selected = {get: function(a) { // NOSONAR
    var b = a.parentNode; return b && b.parentNode && b.parentNode.selectedIndex, null; // NOSONAR
  }, set: function(a) { // NOSONAR
    var b = a.parentNode; b && (b.selectedIndex, b.parentNode && b.parentNode.selectedIndex); // NOSONAR
  }}), r.each(['tabIndex', 'readOnly', 'maxLength', 'cellSpacing', 'cellPadding', 'rowSpan', 'colSpan', 'useMap', 'frameBorder', 'contentEditable'], function() { // NOSONAR
    r.propFix[this.toLowerCase()] = this; // NOSONAR
  }); function pb(a) { // NOSONAR
    var b = a.match(L) || []; return b.join(' '); // NOSONAR
  } function qb(a) { // NOSONAR
    return a.getAttribute && a.getAttribute('class') || ''; // NOSONAR
  }r.fn.extend({addClass: function(a) { // NOSONAR
    var b, c, d, e, f, g, h, i = 0; if (r.isFunction(a)) { // NOSONAR
      return this.each(function(b) { // NOSONAR
        r(this).addClass(a.call(this, b, qb(this))); // NOSONAR
      }); // NOSONAR
    } if (typeof a === 'string' && a) { // NOSONAR
      b = a.match(L) || []; while (c = this[i++]) { // NOSONAR
        if (e = qb(c), d = c.nodeType === 1 && ' ' + pb(e) + ' ') { // NOSONAR
          g = 0; while (f = b[g++]) { // NOSONAR
            d.indexOf(' ' + f + ' ') < 0 && (d += f + ' '); // NOSONAR
          }h = pb(d), e !== h && c.setAttribute('class', h); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return this; // NOSONAR
  }, removeClass: function(a) { // NOSONAR
    var b, c, d, e, f, g, h, i = 0; if (r.isFunction(a)) { // NOSONAR
      return this.each(function(b) { // NOSONAR
        r(this).removeClass(a.call(this, b, qb(this))); // NOSONAR
      }); // NOSONAR
    } if (!arguments.length) { // NOSONAR
      return this.attr('class', ''); // NOSONAR
    } if (typeof a === 'string' && a) { // NOSONAR
      b = a.match(L) || []; while (c = this[i++]) { // NOSONAR
        if (e = qb(c), d = c.nodeType === 1 && ' ' + pb(e) + ' ') { // NOSONAR
          g = 0; while (f = b[g++]) { // NOSONAR
            while (d.indexOf(' ' + f + ' ') > -1) { // NOSONAR
              d = d.replace(' ' + f + ' ', ' '); // NOSONAR
            } // NOSONAR
          }h = pb(d), e !== h && c.setAttribute('class', h); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return this; // NOSONAR
  }, toggleClass: function(a, b) { // NOSONAR
    var c = typeof a; return typeof b === 'boolean' && c === 'string' ? b ? this.addClass(a) : this.removeClass(a) : r.isFunction(a) ? this.each(function(c) { // NOSONAR
      r(this).toggleClass(a.call(this, c, qb(this), b), b); // NOSONAR
    }) : this.each(function() { // NOSONAR
      var b, d, e, f; if (c === 'string') { // NOSONAR
        d = 0, e = r(this), f = a.match(L) || []; while (b = f[d++]) { // NOSONAR
          e.hasClass(b) ? e.removeClass(b) : e.addClass(b); // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        void 0 !== a && c !== 'boolean' || (b = qb(this), b && W.set(this, '__className__', b), this.setAttribute && this.setAttribute('class', b || a === !1 ? '' : W.get(this, '__className__') || '')); // NOSONAR
      } // NOSONAR
    }); // NOSONAR
  }, hasClass: function(a) { // NOSONAR
    var b, c, d = 0; b = ' ' + a + ' '; while (c = this[d++]) { // NOSONAR
      if (c.nodeType === 1 && (' ' + pb(qb(c)) + ' ').indexOf(b) > -1) { // NOSONAR
        return !0; // NOSONAR
      } // NOSONAR
    } return !1; // NOSONAR
  }}); var rb = /\r/g; r.fn.extend({val: function(a) { // NOSONAR
    var b, c, d, e = this[0]; {if (arguments.length) { // NOSONAR
      return d = r.isFunction(a), this.each(function(c) { // NOSONAR
        var e; this.nodeType === 1 && (e = d ? a.call(this, c, r(this).val()) : a, e == null ? e = '' : typeof e === 'number' ? e += '' : Array.isArray(e) && (e = r.map(e, function(a) { // NOSONAR
          return a == null ? '' : a + ''; // NOSONAR
        })), b = r.valHooks[this.type] || r.valHooks[this.nodeName.toLowerCase()], b && 'set' in b && void 0 !== b.set(this, e, 'value') || (this.value = e)); // NOSONAR
      }); // NOSONAR
    } if (e) { // NOSONAR
      return b = r.valHooks[e.type] || r.valHooks[e.nodeName.toLowerCase()], b && 'get' in b && void 0 !== (c = b.get(e, 'value')) ? c : (c = e.value, typeof c === 'string' ? c.replace(rb, '') : c == null ? '' : c); // NOSONAR
    }} // NOSONAR
  }}), r.extend({valHooks: {option: {get: function(a) { // NOSONAR
    var b = r.find.attr(a, 'value'); return b != null ? b : pb(r.text(a)); // NOSONAR
  }}, select: {get: function(a) { // NOSONAR
    var b, c, d, e = a.options, f = a.selectedIndex, g = a.type === 'select-one', h = g ? null : [], i = g ? f + 1 : e.length; for (d = f < 0 ? i : g ? f : 0; d < i; d++) { // NOSONAR
      if (c = e[d], (c.selected || d === f) && !c.disabled && (!c.parentNode.disabled || !B(c.parentNode, 'optgroup'))) { // NOSONAR
        if (b = r(c).val(), g) { // NOSONAR
          return b; // NOSONAR
        } h.push(b); // NOSONAR
      } // NOSONAR
    } return h; // NOSONAR
  }, set: function(a, b) { // NOSONAR
    var c, d, e = a.options, f = r.makeArray(b), g = e.length; while (g--) { // NOSONAR
      d = e[g], (d.selected = r.inArray(r.valHooks.option.get(d), f) > -1) && (c = !0); // NOSONAR
    } return c || (a.selectedIndex = -1), f; // NOSONAR
  }}}}), r.each(['radio', 'checkbox'], function() { // NOSONAR
    r.valHooks[this] = {set: function(a, b) { // NOSONAR
      if (Array.isArray(b)) { // NOSONAR
        return a.checked = r.inArray(r(a).val(), b) > -1; // NOSONAR
      } // NOSONAR
    }}, o.checkOn || (r.valHooks[this].get = function(a) { // NOSONAR
      return a.getAttribute('value') === null ? 'on' : a.value; // NOSONAR
    }); // NOSONAR
  }); var sb = /^(?:focusinfocus|focusoutblur)$/; r.extend(r.event, {trigger: function(b, c, e, f) { // NOSONAR
    var g, h, i, j, k, m, n, o = [ e || d ], p = l.call(b, 'type') ? b.type : b, q = l.call(b, 'namespace') ? b.namespace.split('.') : []; if (h = i = e = e || d, e.nodeType !== 3 && e.nodeType !== 8 && !sb.test(p + r.event.triggered) && (p.indexOf('.') > -1 && (q = p.split('.'), p = q.shift(), q.sort()), k = p.indexOf(':') < 0 && 'on' + p, b = b[r.expando] ? b : new r.Event(p, typeof b === 'object' && b), b.isTrigger = f ? 2 : 3, b.namespace = q.join('.'), b.rnamespace = b.namespace ? new RegExp('(^|\\.)' + q.join('\\.(?:.*\\.|)') + '(\\.|$)') : null, b.result = void 0, b.target || (b.target = e), c = c == null ? [ b ] : r.makeArray(c, [ b ]), n = r.event.special[p] || {}, f || !n.trigger || n.trigger.apply(e, c) !== !1)) { // NOSONAR
      if (!f && !n.noBubble && !r.isWindow(e)) { // NOSONAR
        for (j = n.delegateType || p, sb.test(j + p) || (h = h.parentNode); h; h = h.parentNode) { // NOSONAR
          o.push(h), i = h; // NOSONAR
        }i === (e.ownerDocument || d) && o.push(i.defaultView || i.parentWindow || a); // NOSONAR
      }g = 0; while ((h = o[g++]) && !b.isPropagationStopped()) { // NOSONAR
        b.type = g > 1 ? j : n.bindType || p, m = (W.get(h, 'events') || {})[b.type] && W.get(h, 'handle'), m && m.apply(h, c), m = k && h[k], m && m.apply && U(h) && (b.result = m.apply(h, c), b.result === !1 && b.preventDefault()); // NOSONAR
      } return b.type = p, f || b.isDefaultPrevented() || n._default && n._default.apply(o.pop(), c) !== !1 || !U(e) || k && r.isFunction(e[p]) && !r.isWindow(e) && (i = e[k], i && (e[k] = null), r.event.triggered = p, e[p](), r.event.triggered = void 0, i && (e[k] = i)), b.result; // NOSONAR
    } // NOSONAR
  }, simulate: function(a, b, c) { // NOSONAR
    var d = r.extend(new r.Event, c, {type: a, isSimulated: !0}); r.event.trigger(d, null, b); // NOSONAR
  }}), r.fn.extend({trigger: function(a, b) { // NOSONAR
    return this.each(function() { // NOSONAR
      r.event.trigger(a, b, this); // NOSONAR
    }); // NOSONAR
  }, triggerHandler: function(a, b) { // NOSONAR
    var c = this[0]; if (c) { // NOSONAR
      return r.event.trigger(a, b, c, !0); // NOSONAR
    } // NOSONAR
  }}), r.each('blur focus focusin focusout resize scroll click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup contextmenu'.split(' '), function(a, b) { // NOSONAR
    r.fn[b] = function(a, c) { // NOSONAR
      return arguments.length > 0 ? this.on(b, null, a, c) : this.trigger(b); // NOSONAR
    }; // NOSONAR
  }), r.fn.extend({hover: function(a, b) { // NOSONAR
    return this.mouseenter(a).mouseleave(b || a); // NOSONAR
  }}), o.focusin = 'onfocusin' in a, o.focusin || r.each({focus: 'focusin', blur: 'focusout'}, function(a, b) { // NOSONAR
    var c = function(a) { // NOSONAR
      r.event.simulate(b, a.target, r.event.fix(a)); // NOSONAR
    }; r.event.special[b] = {setup: function() { // NOSONAR
      var d = this.ownerDocument || this, e = W.access(d, b); e || d.addEventListener(a, c, !0), W.access(d, b, (e || 0) + 1); // NOSONAR
    }, teardown: function() { // NOSONAR
      var d = this.ownerDocument || this, e = W.access(d, b) - 1; e ? W.access(d, b, e) : (d.removeEventListener(a, c, !0), W.remove(d, b)); // NOSONAR
    }}; // NOSONAR
  }); var tb = a.location, ub = r.now(), vb = /\?/; r.parseXML = function(b) { // NOSONAR
    var c; if (!b || typeof b !== 'string') { // NOSONAR
      return null; // NOSONAR
    } try { // NOSONAR
      c = (new a.DOMParser).parseFromString(b, 'text/xml'); // NOSONAR
    } catch (d) { // NOSONAR
      c = void 0; // NOSONAR
    } return c && !c.getElementsByTagName('parsererror').length || r.error('Invalid XML: ' + b), c; // NOSONAR
  }; var wb = /\[\]$/, xb = /\r?\n/g, yb = /^(?:submit|button|image|reset|file)$/i, zb = /^(?:input|select|textarea|keygen)/i; function Ab(a, b, c, d) { // NOSONAR
    var e; if (Array.isArray(b)) { // NOSONAR
      r.each(b, function(b, e) { // NOSONAR
        c || wb.test(a) ? d(a, e) : Ab(a + '[' + (typeof e === 'object' && e != null ? b : '') + ']', e, c, d); // NOSONAR
      }); // NOSONAR
    } else if (c || r.type(b) !== 'object') { // NOSONAR
      d(a, b); // NOSONAR
    } else { // NOSONAR
      for (e in b) { // NOSONAR
        Ab(a + '[' + e + ']', b[e], c, d); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  }r.param = function(a, b) { // NOSONAR
    var c, d = [], e = function(a, b) { // NOSONAR
      var c = r.isFunction(b) ? b() : b; d[d.length] = encodeURIComponent(a) + '=' + encodeURIComponent(c == null ? '' : c); // NOSONAR
    }; if (Array.isArray(a) || a.jquery && !r.isPlainObject(a)) { // NOSONAR
      r.each(a, function() { // NOSONAR
        e(this.name, this.value); // NOSONAR
      }); // NOSONAR
    } else { // NOSONAR
      for (c in a) { // NOSONAR
        Ab(c, a[c], b, e); // NOSONAR
      } // NOSONAR
    } return d.join('&'); // NOSONAR
  }, r.fn.extend({serialize: function() { // NOSONAR
    return r.param(this.serializeArray()); // NOSONAR
  }, serializeArray: function() { // NOSONAR
    return this.map(function() { // NOSONAR
      var a = r.prop(this, 'elements'); return a ? r.makeArray(a) : this; // NOSONAR
    }).filter(function() { // NOSONAR
      var a = this.type; return this.name && !r(this).is(':disabled') && zb.test(this.nodeName) && !yb.test(a) && (this.checked || !ja.test(a)); // NOSONAR
    }).map(function(a, b) { // NOSONAR
      var c = r(this).val(); return c == null ? null : Array.isArray(c) ? r.map(c, function(a) { // NOSONAR
        return {name: b.name, value: a.replace(xb, '\r\n')}; // NOSONAR
      }) : {name: b.name, value: c.replace(xb, '\r\n')}; // NOSONAR
    }).get(); // NOSONAR
  }}); var Bb = /%20/g, Cb = /#.*$/, Db = /([?&])_=[^&]*/, Eb = /^(.*?):[ \t]*([^\r\n]*)$/gm, Fb = /^(?:about|app|app-storage|.+-extension|file|res|widget):$/, Gb = /^(?:GET|HEAD)$/, Hb = /^\/\//, Ib = {}, Jb = {}, Kb = '*/'.concat('*'), Lb = d.createElement('a'); Lb.href = tb.href; function Mb(a) { // NOSONAR
    return function(b, c) { // NOSONAR
      typeof b !== 'string' && (c = b, b = '*'); var d, e = 0, f = b.toLowerCase().match(L) || []; if (r.isFunction(c)) { // NOSONAR
        while (d = f[e++]) { // NOSONAR
          d[0] === '+' ? (d = d.slice(1) || '*', (a[d] = a[d] || []).unshift(c)) : (a[d] = a[d] || []).push(c); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    }; // NOSONAR
  } function Nb(a, b, c, d) { // NOSONAR
    var e = {}, f = a === Jb; function g(h) { // NOSONAR
      var i; return e[h] = !0, r.each(a[h] || [], function(a, h) { // NOSONAR
        var j = h(b, c, d); return typeof j !== 'string' || f || e[j] ? f ? !(i = j) : void 0 : (b.dataTypes.unshift(j), g(j), !1); // NOSONAR
      }), i; // NOSONAR
    } return g(b.dataTypes[0]) || !e['*'] && g('*'); // NOSONAR
  } function Ob(a, b) { // NOSONAR
    var c, d, e = r.ajaxSettings.flatOptions || {}; for (c in b) { // NOSONAR
      void 0 !== b[c] && ((e[c] ? a : d || (d = {}))[c] = b[c]); // NOSONAR
    } return d && r.extend(!0, a, d), a; // NOSONAR
  } function Pb(a, b, c) { // NOSONAR
    var d, e, f, g, h = a.contents, i = a.dataTypes; while (i[0] === '*') { // NOSONAR
      i.shift(), void 0 === d && (d = a.mimeType || b.getResponseHeader('Content-Type')); // NOSONAR
    } if (d) { // NOSONAR
      for (e in h) { // NOSONAR
        if (h[e] && h[e].test(d)) { // NOSONAR
          i.unshift(e); break; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } if (i[0] in c) { // NOSONAR
      f = i[0]; // NOSONAR
    } else { // NOSONAR
      for (e in c) { // NOSONAR
        if (!i[0] || a.converters[e + ' ' + i[0]]) { // NOSONAR
          f = e; break; // NOSONAR
        }g || (g = e); // NOSONAR
      }f = f || g; // NOSONAR
    } if (f) { // NOSONAR
      return f !== i[0] && i.unshift(f), c[f]; // NOSONAR
    } // NOSONAR
  } function Qb(a, b, c, d) { // NOSONAR
    var e, f, g, h, i, j = {}, k = a.dataTypes.slice(); if (k[1]) { // NOSONAR
      for (g in a.converters) { // NOSONAR
        j[g.toLowerCase()] = a.converters[g]; // NOSONAR
      } // NOSONAR
    }f = k.shift(); while (f) { // NOSONAR
      if (a.responseFields[f] && (c[a.responseFields[f]] = b), !i && d && a.dataFilter && (b = a.dataFilter(b, a.dataType)), i = f, f = k.shift()) { // NOSONAR
        if (f === '*') { // NOSONAR
          f = i; // NOSONAR
        } else if (i !== '*' && i !== f) { // NOSONAR
          if (g = j[i + ' ' + f] || j['* ' + f], !g) { // NOSONAR
            for (e in j) { // NOSONAR
              if (h = e.split(' '), h[1] === f && (g = j[i + ' ' + h[0]] || j['* ' + h[0]])) { // NOSONAR
                g === !0 ? g = j[e] : j[e] !== !0 && (f = h[0], k.unshift(h[1])); break; // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } if (g !== !0) { // NOSONAR
            if (g && a.throws) { // NOSONAR
              b = g(b); // NOSONAR
            } else { // NOSONAR
              try { // NOSONAR
                b = g(b); // NOSONAR
              } catch (l) { // NOSONAR
                return {state: 'parsererror', error: g ? l : 'No conversion from ' + i + ' to ' + f}; // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return {state: 'success', data: b}; // NOSONAR
  }r.extend({active: 0, lastModified: {}, etag: {}, ajaxSettings: {url: tb.href, type: 'GET', isLocal: Fb.test(tb.protocol), global: !0, processData: !0, async: !0, contentType: 'application/x-www-form-urlencoded; charset=UTF-8', accepts: {'*': Kb, text: 'text/plain', html: 'text/html', xml: 'application/xml, text/xml', json: 'application/json, text/javascript'}, contents: {xml: /\bxml\b/, html: /\bhtml/, json: /\bjson\b/}, responseFields: {xml: 'responseXML', text: 'responseText', json: 'responseJSON'}, converters: {'* text': String, 'text html': !0, 'text json': JSON.parse, 'text xml': r.parseXML}, flatOptions: {url: !0, context: !0}}, ajaxSetup: function(a, b) { // NOSONAR
    return b ? Ob(Ob(a, r.ajaxSettings), b) : Ob(r.ajaxSettings, a); // NOSONAR
  }, ajaxPrefilter: Mb(Ib), ajaxTransport: Mb(Jb), ajax: function(b, c) { // NOSONAR
    typeof b === 'object' && (c = b, b = void 0), c = c || {}; var e, f, g, h, i, j, k, l, m, n, o = r.ajaxSetup({}, c), p = o.context || o, q = o.context && (p.nodeType || p.jquery) ? r(p) : r.event, s = r.Deferred(), t = r.Callbacks('once memory'), u = o.statusCode || {}, v = {}, w = {}, x = 'canceled', y = {readyState: 0, getResponseHeader: function(a) { // NOSONAR
      var b; if (k) { // NOSONAR
        if (!h) { // NOSONAR
          h = {}; while (b = Eb.exec(g)) { // NOSONAR
            h[b[1].toLowerCase()] = b[2]; // NOSONAR
          } // NOSONAR
        }b = h[a.toLowerCase()]; // NOSONAR
      } return b == null ? null : b; // NOSONAR
    }, getAllResponseHeaders: function() { // NOSONAR
      return k ? g : null; // NOSONAR
    }, setRequestHeader: function(a, b) { // NOSONAR
      return k == null && (a = w[a.toLowerCase()] = w[a.toLowerCase()] || a, v[a] = b), this; // NOSONAR
    }, overrideMimeType: function(a) { // NOSONAR
      return k == null && (o.mimeType = a), this; // NOSONAR
    }, statusCode: function(a) { // NOSONAR
      var b; if (a) { // NOSONAR
        if (k) { // NOSONAR
          y.always(a[y.status]); // NOSONAR
        } else { // NOSONAR
          for (b in a) { // NOSONAR
            u[b] = [u[b], a[b]]; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return this; // NOSONAR
    }, abort: function(a) { // NOSONAR
      var b = a || x; return e && e.abort(b), A(0, b), this; // NOSONAR
    }}; if (s.promise(y), o.url = ((b || o.url || tb.href) + '').replace(Hb, tb.protocol + '//'), o.type = c.method || c.type || o.method || o.type, o.dataTypes = (o.dataType || '*').toLowerCase().match(L) || [ '' ], o.crossDomain == null) { // NOSONAR
      j = d.createElement('a'); try { // NOSONAR
        j.href = o.url, j.href = j.href, o.crossDomain = Lb.protocol + '//' + Lb.host != j.protocol + '//' + j.host; // NOSONAR
      } catch (z) { // NOSONAR
        o.crossDomain = !0; // NOSONAR
      } // NOSONAR
    } if (o.data && o.processData && typeof o.data !== 'string' && (o.data = r.param(o.data, o.traditional)), Nb(Ib, o, c, y), k) { // NOSONAR
      return y; // NOSONAR
    } l = r.event && o.global, l && r.active++ === 0 && r.event.trigger('ajaxStart'), o.type = o.type.toUpperCase(), o.hasContent = !Gb.test(o.type), f = o.url.replace(Cb, ''), o.hasContent ? o.data && o.processData && (o.contentType || '').indexOf('application/x-www-form-urlencoded') === 0 && (o.data = o.data.replace(Bb, '+')) : (n = o.url.slice(f.length), o.data && (f += (vb.test(f) ? '&' : '?') + o.data, delete o.data), o.cache === !1 && (f = f.replace(Db, '$1'), n = (vb.test(f) ? '&' : '?') + '_=' + ub++ + n), o.url = f + n), o.ifModified && (r.lastModified[f] && y.setRequestHeader('If-Modified-Since', r.lastModified[f]), r.etag[f] && y.setRequestHeader('If-None-Match', r.etag[f])), (o.data && o.hasContent && o.contentType !== !1 || c.contentType) && y.setRequestHeader('Content-Type', o.contentType), y.setRequestHeader('Accept', o.dataTypes[0] && o.accepts[o.dataTypes[0]] ? o.accepts[o.dataTypes[0]] + (o.dataTypes[0] !== '*' ? ', ' + Kb + '; q=0.01' : '') : o.accepts['*']); for (m in o.headers) { // NOSONAR
      y.setRequestHeader(m, o.headers[m]); // NOSONAR
    } if (o.beforeSend && (o.beforeSend.call(p, y, o) === !1 || k)) { // NOSONAR
      return y.abort(); // NOSONAR
    } if (x = 'abort', t.add(o.complete), y.done(o.success), y.fail(o.error), e = Nb(Jb, o, c, y)) { // NOSONAR
      if (y.readyState = 1, l && q.trigger('ajaxSend', [y, o]), k) { // NOSONAR
        return y; // NOSONAR
      } o.async && o.timeout > 0 && (i = a.setTimeout(function() { // NOSONAR
        y.abort('timeout'); // NOSONAR
      }, o.timeout)); try { // NOSONAR
        k = !1, e.send(v, A); // NOSONAR
      } catch (z) { // NOSONAR
        if (k) { // NOSONAR
          throw z; // NOSONAR
        } A(-1, z); // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      A(-1, 'No Transport'); // NOSONAR
    } function A(b, c, d, h) { // NOSONAR
      var j, m, n, v, w, x = c; k || (k = !0, i && a.clearTimeout(i), e = void 0, g = h || '', y.readyState = b > 0 ? 4 : 0, j = b >= 200 && b < 300 || b === 304, d && (v = Pb(o, y, d)), v = Qb(o, v, y, j), j ? (o.ifModified && (w = y.getResponseHeader('Last-Modified'), w && (r.lastModified[f] = w), w = y.getResponseHeader('etag'), w && (r.etag[f] = w)), b === 204 || o.type === 'HEAD' ? x = 'nocontent' : b === 304 ? x = 'notmodified' : (x = v.state, m = v.data, n = v.error, j = !n)) : (n = x, !b && x || (x = 'error', b < 0 && (b = 0))), y.status = b, y.statusText = (c || x) + '', j ? s.resolveWith(p, [m, x, y]) : s.rejectWith(p, [y, x, n]), y.statusCode(u), u = void 0, l && q.trigger(j ? 'ajaxSuccess' : 'ajaxError', [y, o, j ? m : n]), t.fireWith(p, [y, x]), l && (q.trigger('ajaxComplete', [y, o]), --r.active || r.event.trigger('ajaxStop'))); // NOSONAR
    } return y; // NOSONAR
  }, getJSON: function(a, b, c) { // NOSONAR
    return r.get(a, b, c, 'json'); // NOSONAR
  }, getScript: function(a, b) { // NOSONAR
    return r.get(a, void 0, b, 'script'); // NOSONAR
  }}), r.each(['get', 'post'], function(a, b) { // NOSONAR
    r[b] = function(a, c, d, e) { // NOSONAR
      return r.isFunction(c) && (e = e || d, d = c, c = void 0), r.ajax(r.extend({url: a, type: b, dataType: e, data: c, success: d}, r.isPlainObject(a) && a)); // NOSONAR
    }; // NOSONAR
  }), r._evalUrl = function(a) { // NOSONAR
    return r.ajax({url: a, type: 'GET', dataType: 'script', cache: !0, async: !1, global: !1, 'throws': !0}); // NOSONAR
  }, r.fn.extend({wrapAll: function(a) { // NOSONAR
    var b; return this[0] && (r.isFunction(a) && (a = a.call(this[0])), b = r(a, this[0].ownerDocument).eq(0).clone(!0), this[0].parentNode && b.insertBefore(this[0]), b.map(function() { // NOSONAR
      var a = this; while (a.firstElementChild) { // NOSONAR
        a = a.firstElementChild; // NOSONAR
      } return a; // NOSONAR
    }).append(this)), this; // NOSONAR
  }, wrapInner: function(a) { // NOSONAR
    return r.isFunction(a) ? this.each(function(b) { // NOSONAR
      r(this).wrapInner(a.call(this, b)); // NOSONAR
    }) : this.each(function() { // NOSONAR
      var b = r(this), c = b.contents(); c.length ? c.wrapAll(a) : b.append(a); // NOSONAR
    }); // NOSONAR
  }, wrap: function(a) { // NOSONAR
    var b = r.isFunction(a); return this.each(function(c) { // NOSONAR
      r(this).wrapAll(b ? a.call(this, c) : a); // NOSONAR
    }); // NOSONAR
  }, unwrap: function(a) { // NOSONAR
    return this.parent(a).not('body').each(function() { // NOSONAR
      r(this).replaceWith(this.childNodes); // NOSONAR
    }), this; // NOSONAR
  }}), r.expr.pseudos.hidden = function(a) { // NOSONAR
    return !r.expr.pseudos.visible(a); // NOSONAR
  }, r.expr.pseudos.visible = function(a) { // NOSONAR
    return !!(a.offsetWidth || a.offsetHeight || a.getClientRects().length); // NOSONAR
  }, r.ajaxSettings.xhr = function() { // NOSONAR
    try { // NOSONAR
      return new a.XMLHttpRequest; // NOSONAR
    } catch (b) {} // NOSONAR
  }; var Rb = {0: 200, 1223: 204}, Sb = r.ajaxSettings.xhr(); o.cors = !!Sb && 'withCredentials' in Sb, o.ajax = Sb = !!Sb, r.ajaxTransport(function(b) { // NOSONAR
    var c, d; if (o.cors || Sb && !b.crossDomain) { // NOSONAR
      return {send: function(e, f) { // NOSONAR
        var g, h = b.xhr(); if (h.open(b.type, b.url, b.async, b.username, b.password), b.xhrFields) { // NOSONAR
          for (g in b.xhrFields) { // NOSONAR
            h[g] = b.xhrFields[g]; // NOSONAR
          } // NOSONAR
        }b.mimeType && h.overrideMimeType && h.overrideMimeType(b.mimeType), b.crossDomain || e['X-Requested-With'] || (e['X-Requested-With'] = 'XMLHttpRequest'); for (g in e) { // NOSONAR
          h.setRequestHeader(g, e[g]); // NOSONAR
        }c = function(a) { // NOSONAR
          return function() { // NOSONAR
            c && (c = d = h.onload = h.onerror = h.onabort = h.onreadystatechange = null, a === 'abort' ? h.abort() : a === 'error' ? typeof h.status !== 'number' ? f(0, 'error') : f(h.status, h.statusText) : f(Rb[h.status] || h.status, h.statusText, (h.responseType || 'text') !== 'text' || typeof h.responseText !== 'string' ? {binary: h.response} : {text: h.responseText}, h.getAllResponseHeaders())); // NOSONAR
          }; // NOSONAR
        }, h.onload = c(), d = h.onerror = c('error'), void 0 !== h.onabort ? h.onabort = d : h.onreadystatechange = function() { // NOSONAR
          h.readyState === 4 && a.setTimeout(function() { // NOSONAR
            c && d(); // NOSONAR
          }); // NOSONAR
        }, c = c('abort'); try { // NOSONAR
          h.send(b.hasContent && b.data || null); // NOSONAR
        } catch (i) { // NOSONAR
          if (c) { // NOSONAR
            throw i; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }, abort: function() { // NOSONAR
        c && c(); // NOSONAR
      }}; // NOSONAR
    } // NOSONAR
  }), r.ajaxPrefilter(function(a) { // NOSONAR
    a.crossDomain && (a.contents.script = !1); // NOSONAR
  }), r.ajaxSetup({accepts: {script: 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript'}, contents: {script: /\b(?:java|ecma)script\b/}, converters: {'text script': function(a) { // NOSONAR
    return r.globalEval(a), a; // NOSONAR
  }}}), r.ajaxPrefilter('script', function(a) { // NOSONAR
    void 0 === a.cache && (a.cache = !1), a.crossDomain && (a.type = 'GET'); // NOSONAR
  }), r.ajaxTransport('script', function(a) { // NOSONAR
    if (a.crossDomain) { // NOSONAR
      var b, c; return {send: function(e, f) { // NOSONAR
        b = r('<script>').prop({charset: a.scriptCharset, src: a.url}).on('load error', c = function(a) { // NOSONAR
          b.remove(), c = null, a && f(a.type === 'error' ? 404 : 200, a.type); // NOSONAR
        }), d.head.appendChild(b[0]); // NOSONAR
      }, abort: function() { // NOSONAR
        c && c(); // NOSONAR
      }}; // NOSONAR
    } // NOSONAR
  }); var Tb = [], Ub = /(=)\?(?=&|$)|\?\?/; r.ajaxSetup({jsonp: 'callback', jsonpCallback: function() { // NOSONAR
    var a = Tb.pop() || r.expando + '_' + ub++; return this[a] = !0, a; // NOSONAR
  }}), r.ajaxPrefilter('json jsonp', function(b, c, d) { // NOSONAR
    var e, f, g, h = b.jsonp !== !1 && (Ub.test(b.url) ? 'url' : typeof b.data === 'string' && (b.contentType || '').indexOf('application/x-www-form-urlencoded') === 0 && Ub.test(b.data) && 'data'); if (h || b.dataTypes[0] === 'jsonp') { // NOSONAR
      return e = b.jsonpCallback = r.isFunction(b.jsonpCallback) ? b.jsonpCallback() : b.jsonpCallback, h ? b[h] = b[h].replace(Ub, '$1' + e) : b.jsonp !== !1 && (b.url += (vb.test(b.url) ? '&' : '?') + b.jsonp + '=' + e), b.converters['script json'] = function() { // NOSONAR
        return g || r.error(e + ' was not called'), g[0]; // NOSONAR
      }, b.dataTypes[0] = 'json', f = a[e], a[e] = function() { // NOSONAR
        g = arguments; // NOSONAR
      }, d.always(function() { // NOSONAR
        void 0 === f ? r(a).removeProp(e) : a[e] = f, b[e] && (b.jsonpCallback = c.jsonpCallback, Tb.push(e)), g && r.isFunction(f) && f(g[0]), g = f = void 0; // NOSONAR
      }), 'script'; // NOSONAR
    } // NOSONAR
  }), o.createHTMLDocument = (function() { // NOSONAR
    var a = d.implementation.createHTMLDocument('').body; return a.innerHTML = '<form></form><form></form>', a.childNodes.length === 2; // NOSONAR
  }()), r.parseHTML = function(a, b, c) { // NOSONAR
    if (typeof a !== 'string') { // NOSONAR
      return []; // NOSONAR
    } typeof b === 'boolean' && (c = b, b = !1); var e, f, g; return b || (o.createHTMLDocument ? (b = d.implementation.createHTMLDocument(''), e = b.createElement('base'), e.href = d.location.href, b.head.appendChild(e)) : b = d), f = C.exec(a), g = !c && [], f ? [ b.createElement(f[1]) ] : (f = qa([ a ], b, g), g && g.length && r(g).remove(), r.merge([], f.childNodes)); // NOSONAR
  }, r.fn.load = function(a, b, c) { // NOSONAR
    var d, e, f, g = this, h = a.indexOf(' '); return h > -1 && (d = pb(a.slice(h)), a = a.slice(0, h)), r.isFunction(b) ? (c = b, b = void 0) : b && typeof b === 'object' && (e = 'POST'), g.length > 0 && r.ajax({url: a, type: e || 'GET', dataType: 'html', data: b}).done(function(a) { // NOSONAR
      f = arguments, g.html(d ? r('<div>').append(r.parseHTML(a)).find(d) : a); // NOSONAR
    }).always(c && function(a, b) { // NOSONAR
      g.each(function() { // NOSONAR
        c.apply(this, f || [a.responseText, b, a]); // NOSONAR
      }); // NOSONAR
    }), this; // NOSONAR
  }, r.each(['ajaxStart', 'ajaxStop', 'ajaxComplete', 'ajaxError', 'ajaxSuccess', 'ajaxSend'], function(a, b) { // NOSONAR
    r.fn[b] = function(a) { // NOSONAR
      return this.on(b, a); // NOSONAR
    }; // NOSONAR
  }), r.expr.pseudos.animated = function(a) { // NOSONAR
    return r.grep(r.timers, function(b) { // NOSONAR
      return a === b.elem; // NOSONAR
    }).length; // NOSONAR
  }, r.offset = {setOffset: function(a, b, c) { // NOSONAR
    var d, e, f, g, h, i, j, k = r.css(a, 'position'), l = r(a), m = {}; k === 'static' && (a.style.position = 'relative'), h = l.offset(), f = r.css(a, 'top'), i = r.css(a, 'left'), j = (k === 'absolute' || k === 'fixed') && (f + i).indexOf('auto') > -1, j ? (d = l.position(), g = d.top, e = d.left) : (g = parseFloat(f) || 0, e = parseFloat(i) || 0), r.isFunction(b) && (b = b.call(a, c, r.extend({}, h))), b.top != null && (m.top = b.top - h.top + g), b.left != null && (m.left = b.left - h.left + e), 'using' in b ? b.using.call(a, m) : l.css(m); // NOSONAR
  }}, r.fn.extend({offset: function(a) { // NOSONAR
    if (arguments.length) { // NOSONAR
      return void 0 === a ? this : this.each(function(b) { // NOSONAR
        r.offset.setOffset(this, a, b); // NOSONAR
      }); // NOSONAR
    } var b, c, d, e, f = this[0]; if (f) { // NOSONAR
      return f.getClientRects().length ? (d = f.getBoundingClientRect(), b = f.ownerDocument, c = b.documentElement, e = b.defaultView, {top: d.top + e.pageYOffset - c.clientTop, left: d.left + e.pageXOffset - c.clientLeft}) : {top: 0, left: 0}; // NOSONAR
    } // NOSONAR
  }, position: function() { // NOSONAR
    if (this[0]) { // NOSONAR
      var a, b, c = this[0], d = {top: 0, left: 0}; return r.css(c, 'position') === 'fixed' ? b = c.getBoundingClientRect() : (a = this.offsetParent(), b = this.offset(), B(a[0], 'html') || (d = a.offset()), d = {top: d.top + r.css(a[0], 'borderTopWidth', !0), left: d.left + r.css(a[0], 'borderLeftWidth', !0)}), {top: b.top - d.top - r.css(c, 'marginTop', !0), left: b.left - d.left - r.css(c, 'marginLeft', !0)}; // NOSONAR
    } // NOSONAR
  }, offsetParent: function() { // NOSONAR
    return this.map(function() { // NOSONAR
      var a = this.offsetParent; while (a && r.css(a, 'position') === 'static') { // NOSONAR
        a = a.offsetParent; // NOSONAR
      } return a || ra; // NOSONAR
    }); // NOSONAR
  }}), r.each({scrollLeft: 'pageXOffset', scrollTop: 'pageYOffset'}, function(a, b) { // NOSONAR
    var c = b === 'pageYOffset'; r.fn[a] = function(d) { // NOSONAR
      return T(this, function(a, d, e) { // NOSONAR
        var f; return r.isWindow(a) ? f = a : a.nodeType === 9 && (f = a.defaultView), void 0 === e ? f ? f[b] : a[d] : void(f ? f.scrollTo(c ? f.pageXOffset : e, c ? e : f.pageYOffset) : a[d] = e); // NOSONAR
      }, a, d, arguments.length); // NOSONAR
    }; // NOSONAR
  }), r.each(['top', 'left'], function(a, b) { // NOSONAR
    r.cssHooks[b] = Pa(o.pixelPosition, function(a, c) { // NOSONAR
      if (c) { // NOSONAR
        return c = Oa(a, b), Ma.test(c) ? r(a).position()[b] + 'px' : c; // NOSONAR
      } // NOSONAR
    }); // NOSONAR
  }), r.each({Height: 'height', Width: 'width'}, function(a, b) { // NOSONAR
    r.each({padding: 'inner' + a, content: b, '': 'outer' + a}, function(c, d) { // NOSONAR
      r.fn[d] = function(e, f) { // NOSONAR
        var g = arguments.length && (c || typeof e !== 'boolean'), h = c || (e === !0 || f === !0 ? 'margin' : 'border'); return T(this, function(b, c, e) { // NOSONAR
          var f; return r.isWindow(b) ? d.indexOf('outer') === 0 ? b['inner' + a] : b.document.documentElement['client' + a] : b.nodeType === 9 ? (f = b.documentElement, Math.max(b.body['scroll' + a], f['scroll' + a], b.body['offset' + a], f['offset' + a], f['client' + a])) : void 0 === e ? r.css(b, c, h) : r.style(b, c, e, h); // NOSONAR
        }, b, g ? e : void 0, g); // NOSONAR
      }; // NOSONAR
    }); // NOSONAR
  }), r.fn.extend({bind: function(a, b, c) { // NOSONAR
    return this.on(a, null, b, c); // NOSONAR
  }, unbind: function(a, b) { // NOSONAR
    return this.off(a, null, b); // NOSONAR
  }, delegate: function(a, b, c, d) { // NOSONAR
    return this.on(b, a, c, d); // NOSONAR
  }, undelegate: function(a, b, c) { // NOSONAR
    return arguments.length === 1 ? this.off(a, '**') : this.off(b, a || '**', c); // NOSONAR
  }}), r.holdReady = function(a) { // NOSONAR
    a ? r.readyWait++ : r.ready(!0); // NOSONAR
  }, r.isArray = Array.isArray, r.parseJSON = JSON.parse, r.nodeName = B, typeof define === 'function' && define.amd && define('jquery', [], function() { // NOSONAR
    return r; // NOSONAR
  }); var Vb = a.jQuery, Wb = a.$; return r.noConflict = function(b) { // NOSONAR
    return a.$ === r && (a.$ = Wb), b && a.jQuery === r && (a.jQuery = Vb), r; // NOSONAR
  }, b || (a.jQuery = a.$ = r), r; // NOSONAR
}));