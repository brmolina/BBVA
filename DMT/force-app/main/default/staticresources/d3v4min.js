/* eslint-disable */
// https://d3js.org Version 4.11.0. Copyright 2017 Mike Bostock.
(function(t, n) { // NOSONAR
  typeof exports === 'object' && typeof module !== 'undefined' ? n(exports) : typeof define === 'function' && define.amd ? define([ 'exports' ], n) : n(t.d3 = t.d3 || {}); // NOSONAR
}(this, function(t) { // NOSONAR
  'use strict'; function n(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      return ls(t(n), e); // NOSONAR
    }; // NOSONAR
  } function e(t, n) { // NOSONAR
    return [t, n]; // NOSONAR
  } function r(t, n, e) { // NOSONAR
    var r = (n - t) / Math.max(0, e), i = Math.floor(Math.log(r) / Math.LN10), o = r / Math.pow(10, i); return i >= 0 ? (o >= ks ? 10 : o >= Ss ? 5 : o >= Es ? 2 : 1) * Math.pow(10, i) : -Math.pow(10, -i) / (o >= ks ? 10 : o >= Ss ? 5 : o >= Es ? 2 : 1); // NOSONAR
  } function i(t, n, e) { // NOSONAR
    var r = Math.abs(n - t) / Math.max(0, e), i = Math.pow(10, Math.floor(Math.log(r) / Math.LN10)), o = r / i; return o >= ks ? i *= 10 : o >= Ss ? i *= 5 : o >= Es && (i *= 2), n < t ? -i : i; // NOSONAR
  } function o(t) { // NOSONAR
    return t.length; // NOSONAR
  } function u(t) { // NOSONAR
    return 'translate(' + (t + .5) + ',0)'; // NOSONAR
  } function a(t) { // NOSONAR
    return 'translate(0,' + (t + .5) + ')'; // NOSONAR
  } function c(t) { // NOSONAR
    return function(n) { // NOSONAR
      return +t(n); // NOSONAR
    }; // NOSONAR
  } function s(t) { // NOSONAR
    var n = Math.max(0, t.bandwidth() - 1) / 2; return t.round() && (n = Math.round(n)), function(e) { // NOSONAR
      return +t(e) + n; // NOSONAR
    }; // NOSONAR
  } function f() { // NOSONAR
    return !this.__axis; // NOSONAR
  } function l(t, n) { // NOSONAR
    function e(e) { // NOSONAR
      var u = i == null ? n.ticks ? n.ticks.apply(n, r) : n.domain() : i, a = o == null ? n.tickFormat ? n.tickFormat.apply(n, r) : Us : o, g = Math.max(l, 0) + p, y = n.range(), m = +y[0] + .5, x = +y[y.length - 1] + .5, b = (n.bandwidth ? s : c)(n.copy()), w = e.selection ? e.selection() : e, M = w.selectAll('.domain').data([ null ]), T = w.selectAll('.tick').data(u, n).order(), N = T.exit(), k = T.enter().append('g').attr('class', 'tick'), S = T.select('line'), E = T.select('text'); M = M.merge(M.enter().insert('path', '.tick').attr('class', 'domain').attr('stroke', '#000')), T = T.merge(k), S = S.merge(k.append('line').attr('stroke', '#000').attr(v + '2', d * l)), E = E.merge(k.append('text').attr('fill', '#000').attr(v, d * g).attr('dy', t === Ds ? '0em' : t === Fs ? '0.71em' : '0.32em')), e !== w && (M = M.transition(e), T = T.transition(e), S = S.transition(e), E = E.transition(e), N = N.transition(e).attr('opacity', Ys).attr('transform', function(t) { // NOSONAR
        return isFinite(t = b(t)) ? _(t) : this.getAttribute('transform'); // NOSONAR
      }), k.attr('opacity', Ys).attr('transform', function(t) { // NOSONAR
          var n = this.parentNode.__axis; return _(n && isFinite(n = n(t)) ? n : b(t)); // NOSONAR
        })), N.remove(), M.attr('d', t === Is || t == Os ? 'M' + d * h + ',' + m + 'H0.5V' + x + 'H' + d * h : 'M' + m + ',' + d * h + 'V0.5H' + x + 'V' + d * h), T.attr('opacity', 1).attr('transform', function(t) { // NOSONAR
        return _(b(t)); // NOSONAR
      }), S.attr(v + '2', d * l), E.attr(v, d * g).text(a), w.filter(f).attr('fill', 'none').attr('font-size', 10).attr('font-family', 'sans-serif').attr('text-anchor', t === Os ? 'start' : t === Is ? 'end' : 'middle'), w.each(function() { // NOSONAR
        this.__axis = b; // NOSONAR
      }); // NOSONAR
    } var r = [], i = null, o = null, l = 6, h = 6, p = 3, d = t === Ds || t === Is ? -1 : 1, v = t === Is || t === Os ? 'x' : 'y', _ = t === Ds || t === Fs ? u : a; return e.scale = function(t) { // NOSONAR
      return arguments.length ? (n = t, e) : n; // NOSONAR
    }, e.ticks = function() { // NOSONAR
      return r = qs.call(arguments), e; // NOSONAR
    }, e.tickArguments = function(t) { // NOSONAR
      return arguments.length ? (r = t == null ? [] : qs.call(t), e) : r.slice(); // NOSONAR
    }, e.tickValues = function(t) { // NOSONAR
      return arguments.length ? (i = t == null ? null : qs.call(t), e) : i && i.slice(); // NOSONAR
    }, e.tickFormat = function(t) { // NOSONAR
      return arguments.length ? (o = t, e) : o; // NOSONAR
    }, e.tickSize = function(t) { // NOSONAR
      return arguments.length ? (l = h = +t, e) : l; // NOSONAR
    }, e.tickSizeInner = function(t) { // NOSONAR
      return arguments.length ? (l = +t, e) : l; // NOSONAR
    }, e.tickSizeOuter = function(t) { // NOSONAR
      return arguments.length ? (h = +t, e) : h; // NOSONAR
    }, e.tickPadding = function(t) { // NOSONAR
      return arguments.length ? (p = +t, e) : p; // NOSONAR
    }, e; // NOSONAR
  } function h() { // NOSONAR
    for (var t, n = 0, e = arguments.length, r = {}; n < e; ++n) { // NOSONAR
      if (!(t = arguments[n] + '') || t in r) { // NOSONAR
        throw new Error('illegal type: ' + t); // NOSONAR
      } r[t] = []; // NOSONAR
    } return new p(r); // NOSONAR
  } function p(t) { // NOSONAR
    this._ = t; // NOSONAR
  } function d(t, n) { // NOSONAR
    return t.trim().split(/^|\s+/).map(function(t) { // NOSONAR
      var e = '', r = t.indexOf('.'); if (r >= 0 && (e = t.slice(r + 1), t = t.slice(0, r)), t && !n.hasOwnProperty(t)) { // NOSONAR
        throw new Error('unknown type: ' + t); // NOSONAR
      } return {type: t, name: e}; // NOSONAR
    }); // NOSONAR
  } function v(t, n) { // NOSONAR
    for (var e, r = 0, i = t.length; r < i; ++r) { // NOSONAR
      if ((e = t[r]).name === n) { // NOSONAR
        return e.value; // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function _(t, n, e) { // NOSONAR
    for (var r = 0, i = t.length; r < i; ++r) { // NOSONAR
      if (t[r].name === n) { // NOSONAR
        t[r] = Bs, t = t.slice(0, r).concat(t.slice(r + 1)); break; // NOSONAR
      } // NOSONAR
    } return e != null && t.push({name: n, value: e}), t; // NOSONAR
  } function g(t) { // NOSONAR
    return function() { // NOSONAR
      var n = this.ownerDocument, e = this.namespaceURI; return e === js && n.documentElement.namespaceURI === js ? n.createElement(t) : n.createElementNS(e, t); // NOSONAR
    }; // NOSONAR
  } function y(t) { // NOSONAR
    return function() { // NOSONAR
      return this.ownerDocument.createElementNS(t.space, t.local); // NOSONAR
    }; // NOSONAR
  } function m() { // NOSONAR
    return new x; // NOSONAR
  } function x() { // NOSONAR
    this._ = '@' + (++Vs).toString(36); // NOSONAR
  } function b(t, n, e) { // NOSONAR
    return t = w(t, n, e), function(n) { // NOSONAR
      var e = n.relatedTarget; e && (e === this || 8 & e.compareDocumentPosition(this)) || t.call(this, n); // NOSONAR
    }; // NOSONAR
  } function w(n, e, r) { // NOSONAR
    return function(i) { // NOSONAR
      var o = t.event; t.event = i; try { // NOSONAR
        n.call(this, this.__data__, e, r); // NOSONAR
      } finally { // NOSONAR
        t.event = o; // NOSONAR
      } // NOSONAR
    }; // NOSONAR
  } function M(t) { // NOSONAR
    return t.trim().split(/^|\s+/).map(function(t) { // NOSONAR
      var n = '', e = t.indexOf('.'); return e >= 0 && (n = t.slice(e + 1), t = t.slice(0, e)), {type: t, name: n}; // NOSONAR
    }); // NOSONAR
  } function T(t) { // NOSONAR
    return function() { // NOSONAR
      var n = this.__on; if (n) { // NOSONAR
        for (var e, r = 0, i = -1, o = n.length; r < o; ++r) { // NOSONAR
          e = n[r], t.type && e.type !== t.type || e.name !== t.name ? n[++i] = e : this.removeEventListener(e.type, e.listener, e.capture); // NOSONAR
        }++i ? n.length = i : delete this.__on; // NOSONAR
      } // NOSONAR
    }; // NOSONAR
  } function N(t, n, e) { // NOSONAR
    var r = Qs.hasOwnProperty(t.type) ? b : w; return function(i, o, u) { // NOSONAR
      var a, c = this.__on, s = r(n, o, u); if (c) { // NOSONAR
        for (var f = 0, l = c.length; f < l; ++f) { // NOSONAR
          if ((a = c[f]).type === t.type && a.name === t.name) { // NOSONAR
            return this.removeEventListener(a.type, a.listener, a.capture), this.addEventListener(a.type, a.listener = s, a.capture = e), void(a.value = n); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } this.addEventListener(t.type, s, e), a = {type: t.type, name: t.name, value: n, listener: s, capture: e}, c ? c.push(a) : this.__on = [ a ]; // NOSONAR
    }; // NOSONAR
  } function k(n, e, r, i) { // NOSONAR
    var o = t.event; n.sourceEvent = t.event, t.event = n; try { // NOSONAR
      return e.apply(r, i); // NOSONAR
    } finally { // NOSONAR
      t.event = o; // NOSONAR
    } // NOSONAR
  } function S() {} function E() { // NOSONAR
    return []; // NOSONAR
  } function A(t, n) { // NOSONAR
    this.ownerDocument = t.ownerDocument, this.namespaceURI = t.namespaceURI, this._next = null, this._parent = t, this.__data__ = n; // NOSONAR
  } function C(t, n, e, r, i, o) { // NOSONAR
    for (var u, a = 0, c = n.length, s = o.length; a < s; ++a) { // NOSONAR
      (u = n[a]) ? (u.__data__ = o[a], r[a] = u) : e[a] = new A(t, o[a]); // NOSONAR
    } for (;a < c; ++a) { // NOSONAR
      (u = n[a]) && (i[a] = u); // NOSONAR
    } // NOSONAR
  } function z(t, n, e, r, i, o, u) { // NOSONAR
    var a, c, s, f = {}, l = n.length, h = o.length, p = new Array(l); for (a = 0; a < l; ++a) { // NOSONAR
      (c = n[a]) && (p[a] = s = af + u.call(c, c.__data__, a, n), s in f ? i[a] = c : f[s] = c); // NOSONAR
    } for (a = 0; a < h; ++a) { // NOSONAR
      (c = f[s = af + u.call(t, o[a], a, o)]) ? (r[a] = c, c.__data__ = o[a], f[s] = null) : e[a] = new A(t, o[a]); // NOSONAR
    } for (a = 0; a < l; ++a) { // NOSONAR
      (c = n[a]) && f[p[a]] === c && (i[a] = c); // NOSONAR
    } // NOSONAR
  } function P(t, n) { // NOSONAR
    return t < n ? -1 : t > n ? 1 : t >= n ? 0 : NaN; // NOSONAR
  } function R(t) { // NOSONAR
    return function() { // NOSONAR
      this.removeAttribute(t); // NOSONAR
    }; // NOSONAR
  } function L(t) { // NOSONAR
    return function() { // NOSONAR
      this.removeAttributeNS(t.space, t.local); // NOSONAR
    }; // NOSONAR
  } function q(t, n) { // NOSONAR
    return function() { // NOSONAR
      this.setAttribute(t, n); // NOSONAR
    }; // NOSONAR
  } function U(t, n) { // NOSONAR
    return function() { // NOSONAR
      this.setAttributeNS(t.space, t.local, n); // NOSONAR
    }; // NOSONAR
  } function D(t, n) { // NOSONAR
    return function() { // NOSONAR
      var e = n.apply(this, arguments); e == null ? this.removeAttribute(t) : this.setAttribute(t, e); // NOSONAR
    }; // NOSONAR
  } function O(t, n) { // NOSONAR
    return function() { // NOSONAR
      var e = n.apply(this, arguments); e == null ? this.removeAttributeNS(t.space, t.local) : this.setAttributeNS(t.space, t.local, e); // NOSONAR
    }; // NOSONAR
  } function F(t) { // NOSONAR
    return function() { // NOSONAR
      this.style.removeProperty(t); // NOSONAR
    }; // NOSONAR
  } function I(t, n, e) { // NOSONAR
    return function() { // NOSONAR
      this.style.setProperty(t, n, e); // NOSONAR
    }; // NOSONAR
  } function Y(t, n, e) { // NOSONAR
    return function() { // NOSONAR
      var r = n.apply(this, arguments); r == null ? this.style.removeProperty(t) : this.style.setProperty(t, r, e); // NOSONAR
    }; // NOSONAR
  } function B(t, n) { // NOSONAR
    return t.style.getPropertyValue(n) || cf(t).getComputedStyle(t, null).getPropertyValue(n); // NOSONAR
  } function j(t) { // NOSONAR
    return function() { // NOSONAR
      delete this[t]; // NOSONAR
    }; // NOSONAR
  } function H(t, n) { // NOSONAR
    return function() { // NOSONAR
      this[t] = n; // NOSONAR
    }; // NOSONAR
  } function X(t, n) { // NOSONAR
    return function() { // NOSONAR
      var e = n.apply(this, arguments); e == null ? delete this[t] : this[t] = e; // NOSONAR
    }; // NOSONAR
  } function $(t) { // NOSONAR
    return t.trim().split(/^|\s+/); // NOSONAR
  } function V(t) { // NOSONAR
    return t.classList || new W(t); // NOSONAR
  } function W(t) { // NOSONAR
    this._node = t, this._names = $(t.getAttribute('class') || ''); // NOSONAR
  } function Z(t, n) { // NOSONAR
    for (var e = V(t), r = -1, i = n.length; ++r < i;) { // NOSONAR
      e.add(n[r]); // NOSONAR
    } // NOSONAR
  } function G(t, n) { // NOSONAR
    for (var e = V(t), r = -1, i = n.length; ++r < i;) { // NOSONAR
      e.remove(n[r]); // NOSONAR
    } // NOSONAR
  } function J(t) { // NOSONAR
    return function() { // NOSONAR
      Z(this, t); // NOSONAR
    }; // NOSONAR
  } function Q(t) { // NOSONAR
    return function() { // NOSONAR
      G(this, t); // NOSONAR
    }; // NOSONAR
  } function K(t, n) { // NOSONAR
    return function() { // NOSONAR
      (n.apply(this, arguments) ? Z : G)(this, t); // NOSONAR
    }; // NOSONAR
  } function tt() { // NOSONAR
    this.textContent = ''; // NOSONAR
  } function nt(t) { // NOSONAR
    return function() { // NOSONAR
      this.textContent = t; // NOSONAR
    }; // NOSONAR
  } function et(t) { // NOSONAR
    return function() { // NOSONAR
      var n = t.apply(this, arguments); this.textContent = n == null ? '' : n; // NOSONAR
    }; // NOSONAR
  } function rt() { // NOSONAR
    this.innerHTML = ''; // NOSONAR
  } function it(t) { // NOSONAR
    return function() { // NOSONAR
      this.innerHTML = t; // NOSONAR
    }; // NOSONAR
  } function ot(t) { // NOSONAR
    return function() { // NOSONAR
      var n = t.apply(this, arguments); this.innerHTML = n == null ? '' : n; // NOSONAR
    }; // NOSONAR
  } function ut() { // NOSONAR
    this.nextSibling && this.parentNode.appendChild(this); // NOSONAR
  } function at() { // NOSONAR
    this.previousSibling && this.parentNode.insertBefore(this, this.parentNode.firstChild); // NOSONAR
  } function ct() { // NOSONAR
    return null; // NOSONAR
  } function st() { // NOSONAR
    var t = this.parentNode; t && t.removeChild(this); // NOSONAR
  } function ft(t, n, e) { // NOSONAR
    var r = cf(t), i = r.CustomEvent; typeof i === 'function' ? i = new i(n, e) : (i = r.document.createEvent('Event'), e ? (i.initEvent(n, e.bubbles, e.cancelable), i.detail = e.detail) : i.initEvent(n, !1, !1)), t.dispatchEvent(i); // NOSONAR
  } function lt(t, n) { // NOSONAR
    return function() { // NOSONAR
      return ft(this, t, n); // NOSONAR
    }; // NOSONAR
  } function ht(t, n) { // NOSONAR
    return function() { // NOSONAR
      return ft(this, t, n.apply(this, arguments)); // NOSONAR
    }; // NOSONAR
  } function pt(t, n) { // NOSONAR
    this._groups = t, this._parents = n; // NOSONAR
  } function dt() { // NOSONAR
    return new pt([ [ document.documentElement ] ], sf); // NOSONAR
  } function vt() { // NOSONAR
    t.event.stopImmediatePropagation(); // NOSONAR
  } function _t(t, n) { // NOSONAR
    var e = t.document.documentElement, r = ff(t).on('dragstart.drag', null); n && (r.on('click.drag', hf, !0), setTimeout(function() { // NOSONAR
      r.on('click.drag', null); // NOSONAR
    }, 0)), 'onselectstart' in e ? r.on('selectstart.drag', null) : (e.style.MozUserSelect = e.__noselect, delete e.__noselect); // NOSONAR
  } function gt(t, n, e, r, i, o, u, a, c, s) { // NOSONAR
    this.target = t, this.type = n, this.subject = e, this.identifier = r, this.active = i, this.x = o, this.y = u, this.dx = a, this.dy = c, this._ = s; // NOSONAR
  } function yt() { // NOSONAR
    return !t.event.button; // NOSONAR
  } function mt() { // NOSONAR
    return this.parentNode; // NOSONAR
  } function xt(n) { // NOSONAR
    return n == null ? {x: t.event.x, y: t.event.y} : n; // NOSONAR
  } function bt() { // NOSONAR
    return 'ontouchstart' in this; // NOSONAR
  } function wt(t, n) { // NOSONAR
    var e = Object.create(t.prototype); for (var r in n) { // NOSONAR
      e[r] = n[r]; // NOSONAR
    } return e; // NOSONAR
  } function Mt() {} function Tt(t) { // NOSONAR
    var n; return t = (t + '').trim().toLowerCase(), (n = mf.exec(t)) ? (n = parseInt(n[1], 16), new At(n >> 8 & 15 | n >> 4 & 240, n >> 4 & 15 | 240 & n, (15 & n) << 4 | 15 & n, 1)) : (n = xf.exec(t)) ? Nt(parseInt(n[1], 16)) : (n = bf.exec(t)) ? new At(n[1], n[2], n[3], 1) : (n = wf.exec(t)) ? new At(255 * n[1] / 100, 255 * n[2] / 100, 255 * n[3] / 100, 1) : (n = Mf.exec(t)) ? kt(n[1], n[2], n[3], n[4]) : (n = Tf.exec(t)) ? kt(255 * n[1] / 100, 255 * n[2] / 100, 255 * n[3] / 100, n[4]) : (n = Nf.exec(t)) ? Ct(n[1], n[2] / 100, n[3] / 100, 1) : (n = kf.exec(t)) ? Ct(n[1], n[2] / 100, n[3] / 100, n[4]) : Sf.hasOwnProperty(t) ? Nt(Sf[t]) : t === 'transparent' ? new At(NaN, NaN, NaN, 0) : null; // NOSONAR
  } function Nt(t) { // NOSONAR
    return new At(t >> 16 & 255, t >> 8 & 255, 255 & t, 1); // NOSONAR
  } function kt(t, n, e, r) { // NOSONAR
    return r <= 0 && (t = n = e = NaN), new At(t, n, e, r); // NOSONAR
  } function St(t) { // NOSONAR
    return t instanceof Mt || (t = Tt(t)), t ? (t = t.rgb(), new At(t.r, t.g, t.b, t.opacity)) : new At; // NOSONAR
  } function Et(t, n, e, r) { // NOSONAR
    return arguments.length === 1 ? St(t) : new At(t, n, e, r == null ? 1 : r); // NOSONAR
  } function At(t, n, e, r) { // NOSONAR
    this.r = +t, this.g = +n, this.b = +e, this.opacity = +r; // NOSONAR
  } function Ct(t, n, e, r) { // NOSONAR
    return r <= 0 ? t = n = e = NaN : e <= 0 || e >= 1 ? t = n = NaN : n <= 0 && (t = NaN), new Rt(t, n, e, r); // NOSONAR
  } function zt(t) { // NOSONAR
    if (t instanceof Rt) { // NOSONAR
      return new Rt(t.h, t.s, t.l, t.opacity); // NOSONAR
    } if (t instanceof Mt || (t = Tt(t)), !t) { // NOSONAR
      return new Rt; // NOSONAR
    } if (t instanceof Rt) { // NOSONAR
      return t; // NOSONAR
    } var n = (t = t.rgb()).r / 255, e = t.g / 255, r = t.b / 255, i = Math.min(n, e, r), o = Math.max(n, e, r), u = NaN, a = o - i, c = (o + i) / 2; return a ? (u = n === o ? (e - r) / a + 6 * (e < r) : e === o ? (r - n) / a + 2 : (n - e) / a + 4, a /= c < .5 ? o + i : 2 - o - i, u *= 60) : a = c > 0 && c < 1 ? 0 : u, new Rt(u, a, c, t.opacity); // NOSONAR
  } function Pt(t, n, e, r) { // NOSONAR
    return arguments.length === 1 ? zt(t) : new Rt(t, n, e, r == null ? 1 : r); // NOSONAR
  } function Rt(t, n, e, r) { // NOSONAR
    this.h = +t, this.s = +n, this.l = +e, this.opacity = +r; // NOSONAR
  } function Lt(t, n, e) { // NOSONAR
    return 255 * (t < 60 ? n + (e - n) * t / 60 : t < 180 ? e : t < 240 ? n + (e - n) * (240 - t) / 60 : n); // NOSONAR
  } function qt(t) { // NOSONAR
    if (t instanceof Dt) { // NOSONAR
      return new Dt(t.l, t.a, t.b, t.opacity); // NOSONAR
    } if (t instanceof Ht) { // NOSONAR
      var n = t.h * Ef; return new Dt(t.l, Math.cos(n) * t.c, Math.sin(n) * t.c, t.opacity); // NOSONAR
    }t instanceof At || (t = St(t)); var e = Yt(t.r), r = Yt(t.g), i = Yt(t.b), o = Ot((.4124564 * e + .3575761 * r + .1804375 * i) / Cf), u = Ot((.2126729 * e + .7151522 * r + .072175 * i) / zf); return new Dt(116 * u - 16, 500 * (o - u), 200 * (u - Ot((.0193339 * e + .119192 * r + .9503041 * i) / Pf)), t.opacity); // NOSONAR
  } function Ut(t, n, e, r) { // NOSONAR
    return arguments.length === 1 ? qt(t) : new Dt(t, n, e, r == null ? 1 : r); // NOSONAR
  } function Dt(t, n, e, r) { // NOSONAR
    this.l = +t, this.a = +n, this.b = +e, this.opacity = +r; // NOSONAR
  } function Ot(t) { // NOSONAR
    return t > Uf ? Math.pow(t, 1 / 3) : t / qf + Rf; // NOSONAR
  } function Ft(t) { // NOSONAR
    return t > Lf ? t * t * t : qf * (t - Rf); // NOSONAR
  } function It(t) { // NOSONAR
    return 255 * (t <= .0031308 ? 12.92 * t : 1.055 * Math.pow(t, 1 / 2.4) - .055); // NOSONAR
  } function Yt(t) { // NOSONAR
    return (t /= 255) <= .04045 ? t / 12.92 : Math.pow((t + .055) / 1.055, 2.4); // NOSONAR
  } function Bt(t) { // NOSONAR
    if (t instanceof Ht) { // NOSONAR
      return new Ht(t.h, t.c, t.l, t.opacity); // NOSONAR
    } t instanceof Dt || (t = qt(t)); var n = Math.atan2(t.b, t.a) * Af; return new Ht(n < 0 ? n + 360 : n, Math.sqrt(t.a * t.a + t.b * t.b), t.l, t.opacity); // NOSONAR
  } function jt(t, n, e, r) { // NOSONAR
    return arguments.length === 1 ? Bt(t) : new Ht(t, n, e, r == null ? 1 : r); // NOSONAR
  } function Ht(t, n, e, r) { // NOSONAR
    this.h = +t, this.c = +n, this.l = +e, this.opacity = +r; // NOSONAR
  } function Xt(t) { // NOSONAR
    if (t instanceof Vt) { // NOSONAR
      return new Vt(t.h, t.s, t.l, t.opacity); // NOSONAR
    } t instanceof At || (t = St(t)); var n = t.r / 255, e = t.g / 255, r = t.b / 255, i = (Hf * r + Bf * n - jf * e) / (Hf + Bf - jf), o = r - i, u = (Yf * (e - i) - Ff * o) / If, a = Math.sqrt(u * u + o * o) / (Yf * i * (1 - i)), c = a ? Math.atan2(u, o) * Af - 120 : NaN; return new Vt(c < 0 ? c + 360 : c, a, i, t.opacity); // NOSONAR
  } function $t(t, n, e, r) { // NOSONAR
    return arguments.length === 1 ? Xt(t) : new Vt(t, n, e, r == null ? 1 : r); // NOSONAR
  } function Vt(t, n, e, r) { // NOSONAR
    this.h = +t, this.s = +n, this.l = +e, this.opacity = +r; // NOSONAR
  } function Wt(t, n, e, r, i) { // NOSONAR
    var o = t * t, u = o * t; return ((1 - 3 * t + 3 * o - u) * n + (4 - 6 * o + 3 * u) * e + (1 + 3 * t + 3 * o - 3 * u) * r + u * i) / 6; // NOSONAR
  } function Zt(t, n) { // NOSONAR
    return function(e) { // NOSONAR
      return t + e * n; // NOSONAR
    }; // NOSONAR
  } function Gt(t, n, e) { // NOSONAR
    return t = Math.pow(t, e), n = Math.pow(n, e) - t, e = 1 / e, function(r) { // NOSONAR
      return Math.pow(t + r * n, e); // NOSONAR
    }; // NOSONAR
  } function Jt(t, n) { // NOSONAR
    var e = n - t; return e ? Zt(t, e > 180 || e < -180 ? e - 360 * Math.round(e / 360) : e) : Kf(isNaN(t) ? n : t); // NOSONAR
  } function Qt(t) { // NOSONAR
    return (t = +t) == 1 ? Kt : function(n, e) { // NOSONAR
      return e - n ? Gt(n, e, t) : Kf(isNaN(n) ? e : n); // NOSONAR
    }; // NOSONAR
  } function Kt(t, n) { // NOSONAR
    var e = n - t; return e ? Zt(t, e) : Kf(isNaN(t) ? n : t); // NOSONAR
  } function tn(t) { // NOSONAR
    return function(n) { // NOSONAR
      var e, r, i = n.length, o = new Array(i), u = new Array(i), a = new Array(i); for (e = 0; e < i; ++e) { // NOSONAR
        r = Et(n[e]), o[e] = r.r || 0, u[e] = r.g || 0, a[e] = r.b || 0; // NOSONAR
      } return o = t(o), u = t(u), a = t(a), r.opacity = 1, function(t) { // NOSONAR
        return r.r = o(t), r.g = u(t), r.b = a(t), r + ''; // NOSONAR
      }; // NOSONAR
    }; // NOSONAR
  } function nn(t) { // NOSONAR
    return function() { // NOSONAR
      return t; // NOSONAR
    }; // NOSONAR
  } function en(t) { // NOSONAR
    return function(n) { // NOSONAR
      return t(n) + ''; // NOSONAR
    }; // NOSONAR
  } function rn(t, n, e, r) { // NOSONAR
    function i(t) { // NOSONAR
      return t.length ? t.pop() + ' ' : ''; // NOSONAR
    } function o(t, r, i, o, u, a) { // NOSONAR
      if (t !== i || r !== o) { // NOSONAR
        var c = u.push('translate(', null, n, null, e); a.push({i: c - 4, x: ol(t, i)}, {i: c - 2, x: ol(r, o)}); // NOSONAR
      } else { // NOSONAR
        (i || o) && u.push('translate(' + i + n + o + e); // NOSONAR
      } // NOSONAR
    } function u(t, n, e, o) { // NOSONAR
      t !== n ? (t - n > 180 ? n += 360 : n - t > 180 && (t += 360), o.push({i: e.push(i(e) + 'rotate(', null, r) - 2, x: ol(t, n)})) : n && e.push(i(e) + 'rotate(' + n + r); // NOSONAR
    } function a(t, n, e, o) { // NOSONAR
      t !== n ? o.push({i: e.push(i(e) + 'skewX(', null, r) - 2, x: ol(t, n)}) : n && e.push(i(e) + 'skewX(' + n + r); // NOSONAR
    } function c(t, n, e, r, o, u) { // NOSONAR
      if (t !== e || n !== r) { // NOSONAR
        var a = o.push(i(o) + 'scale(', null, ',', null, ')'); u.push({i: a - 4, x: ol(t, e)}, {i: a - 2, x: ol(n, r)}); // NOSONAR
      } else { // NOSONAR
        e === 1 && r === 1 || o.push(i(o) + 'scale(' + e + ',' + r + ')'); // NOSONAR
      } // NOSONAR
    } return function(n, e) { // NOSONAR
      var r = [], i = []; return n = t(n), e = t(e), o(n.translateX, n.translateY, e.translateX, e.translateY, r, i), u(n.rotate, e.rotate, r, i), a(n.skewX, e.skewX, r, i), c(n.scaleX, n.scaleY, e.scaleX, e.scaleY, r, i), n = e = null, function(t) { // NOSONAR
        for (var n, e = -1, o = i.length; ++e < o;) { // NOSONAR
          r[(n = i[e]).i] = n.x(t); // NOSONAR
        } return r.join(''); // NOSONAR
      }; // NOSONAR
    }; // NOSONAR
  } function on(t) { // NOSONAR
    return ((t = Math.exp(t)) + 1 / t) / 2; // NOSONAR
  } function un(t) { // NOSONAR
    return ((t = Math.exp(t)) - 1 / t) / 2; // NOSONAR
  } function an(t) { // NOSONAR
    return ((t = Math.exp(2 * t)) - 1) / (t + 1); // NOSONAR
  } function cn(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      var r = t((n = Pt(n)).h, (e = Pt(e)).h), i = Kt(n.s, e.s), o = Kt(n.l, e.l), u = Kt(n.opacity, e.opacity); return function(t) { // NOSONAR
        return n.h = r(t), n.s = i(t), n.l = o(t), n.opacity = u(t), n + ''; // NOSONAR
      }; // NOSONAR
    }; // NOSONAR
  } function sn(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      var r = t((n = jt(n)).h, (e = jt(e)).h), i = Kt(n.c, e.c), o = Kt(n.l, e.l), u = Kt(n.opacity, e.opacity); return function(t) { // NOSONAR
        return n.h = r(t), n.c = i(t), n.l = o(t), n.opacity = u(t), n + ''; // NOSONAR
      }; // NOSONAR
    }; // NOSONAR
  } function fn(t) { // NOSONAR
    return (function n(e) { // NOSONAR
      function r(n, r) { // NOSONAR
        var i = t((n = $t(n)).h, (r = $t(r)).h), o = Kt(n.s, r.s), u = Kt(n.l, r.l), a = Kt(n.opacity, r.opacity); return function(t) { // NOSONAR
          return n.h = i(t), n.s = o(t), n.l = u(Math.pow(t, e)), n.opacity = a(t), n + ''; // NOSONAR
        }; // NOSONAR
      } return e = +e, r.gamma = n, r; // NOSONAR
    }(1)); // NOSONAR
  } function ln() { // NOSONAR
    return Cl || (Rl(hn), Cl = Pl.now() + zl); // NOSONAR
  } function hn() { // NOSONAR
    Cl = 0; // NOSONAR
  } function pn() { // NOSONAR
    this._call = this._time = this._next = null; // NOSONAR
  } function dn(t, n, e) { // NOSONAR
    var r = new pn; return r.restart(t, n, e), r; // NOSONAR
  } function vn() { // NOSONAR
    ln(), ++Nl; for (var t, n = Zf; n;) { // NOSONAR
      (t = Cl - n._time) >= 0 && n._call.call(null, t), n = n._next; // NOSONAR
    }--Nl; // NOSONAR
  } function _n() { // NOSONAR
    Cl = (Al = Pl.now()) + zl, Nl = kl = 0; try { // NOSONAR
      vn(); // NOSONAR
    } finally { // NOSONAR
      Nl = 0, yn(), Cl = 0; // NOSONAR
    } // NOSONAR
  } function gn() { // NOSONAR
    var t = Pl.now(), n = t - Al; n > El && (zl -= n, Al = t); // NOSONAR
  } function yn() { // NOSONAR
    for (var t, n, e = Zf, r = 1 / 0; e;) { // NOSONAR
      e._call ? (r > e._time && (r = e._time), t = e, e = e._next) : (n = e._next, e._next = null, e = t ? t._next = n : Zf = n); // NOSONAR
    }Gf = t, mn(r); // NOSONAR
  } function mn(t) { // NOSONAR
    Nl || (kl && (kl = clearTimeout(kl)), t - Cl > 24 ? (t < 1 / 0 && (kl = setTimeout(_n, t - Pl.now() - zl)), Sl && (Sl = clearInterval(Sl))) : (Sl || (Al = Pl.now(), Sl = setInterval(gn, El)), Nl = 1, Rl(_n))); // NOSONAR
  } function xn(t, n) { // NOSONAR
    var e = t.__transition; if (!e || !(e = e[n]) || e.state > Dl) { // NOSONAR
      throw new Error('too late'); // NOSONAR
    } return e; // NOSONAR
  } function bn(t, n) { // NOSONAR
    var e = t.__transition; if (!e || !(e = e[n]) || e.state > Fl) { // NOSONAR
      throw new Error('too late'); // NOSONAR
    } return e; // NOSONAR
  } function wn(t, n) { // NOSONAR
    var e = t.__transition; if (!e || !(e = e[n])) { // NOSONAR
      throw new Error('too late'); // NOSONAR
    } return e; // NOSONAR
  } function Mn(t, n, e) { // NOSONAR
    function r(c) { // NOSONAR
      var s, f, l, h; if (e.state !== Ol) { // NOSONAR
        return o(); // NOSONAR
      } for (s in a) { // NOSONAR
        if ((h = a[s]).name === e.name) { // NOSONAR
          if (h.state === Il) { // NOSONAR
            return Ll(r); // NOSONAR
          } h.state === Yl ? (h.state = jl, h.timer.stop(), h.on.call('interrupt', t, t.__data__, h.index, h.group), delete a[s]) : +s < n && (h.state = jl, h.timer.stop(), delete a[s]); // NOSONAR
        } // NOSONAR
      } if (Ll(function() { // NOSONAR
        e.state === Il && (e.state = Yl, e.timer.restart(i, e.delay, e.time), i(c)); // NOSONAR
      }), e.state = Fl, e.on.call('start', t, t.__data__, e.index, e.group), e.state === Fl) { // NOSONAR
        for (e.state = Il, u = new Array(l = e.tween.length), s = 0, f = -1; s < l; ++s) { // NOSONAR
          (h = e.tween[s].value.call(t, t.__data__, e.index, e.group)) && (u[++f] = h); // NOSONAR
        }u.length = f + 1; // NOSONAR
      } // NOSONAR
    } function i(n) { // NOSONAR
      for (var r = n < e.duration ? e.ease.call(null, n / e.duration) : (e.timer.restart(o), e.state = Bl, 1), i = -1, a = u.length; ++i < a;) { // NOSONAR
        u[i].call(null, r); // NOSONAR
      }e.state === Bl && (e.on.call('end', t, t.__data__, e.index, e.group), o()); // NOSONAR
    } function o() { // NOSONAR
      e.state = jl, e.timer.stop(), delete a[n]; for (var r in a) { // NOSONAR
        return; // NOSONAR
      } delete t.__transition; // NOSONAR
    } var u, a = t.__transition; a[n] = e, e.timer = dn(function(t) { // NOSONAR
      e.state = Ol, e.timer.restart(r, e.delay, e.time), e.delay <= t && r(t - e.delay); // NOSONAR
    }, 0, e.time); // NOSONAR
  } function Tn(t, n) { // NOSONAR
    var e, r; return function() { // NOSONAR
      var i = bn(this, t), o = i.tween; if (o !== e) { // NOSONAR
        for (var u = 0, a = (r = e = o).length; u < a; ++u) { // NOSONAR
          if (r[u].name === n) { // NOSONAR
            (r = r.slice()).splice(u, 1); break; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }i.tween = r; // NOSONAR
    }; // NOSONAR
  } function Nn(t, n, e) { // NOSONAR
    var r, i; if (typeof e !== 'function') { // NOSONAR
      throw new Error; // NOSONAR
    } return function() { // NOSONAR
      var o = bn(this, t), u = o.tween; if (u !== r) { // NOSONAR
        i = (r = u).slice(); for (var a = {name: n, value: e}, c = 0, s = i.length; c < s; ++c) { // NOSONAR
          if (i[c].name === n) { // NOSONAR
            i[c] = a; break; // NOSONAR
          } // NOSONAR
        }c === s && i.push(a); // NOSONAR
      }o.tween = i; // NOSONAR
    }; // NOSONAR
  } function kn(t, n, e) { // NOSONAR
    var r = t._id; return t.each(function() { // NOSONAR
      var t = bn(this, r); (t.value || (t.value = {}))[n] = e.apply(this, arguments); // NOSONAR
    }), function(t) { // NOSONAR
      return wn(t, r).value[n]; // NOSONAR
    }; // NOSONAR
  } function Sn(t) { // NOSONAR
    return function() { // NOSONAR
      this.removeAttribute(t); // NOSONAR
    }; // NOSONAR
  } function En(t) { // NOSONAR
    return function() { // NOSONAR
      this.removeAttributeNS(t.space, t.local); // NOSONAR
    }; // NOSONAR
  } function An(t, n, e) { // NOSONAR
    var r, i; return function() { // NOSONAR
      var o = this.getAttribute(t); return o === e ? null : o === r ? i : i = n(r = o, e); // NOSONAR
    }; // NOSONAR
  } function Cn(t, n, e) { // NOSONAR
    var r, i; return function() { // NOSONAR
      var o = this.getAttributeNS(t.space, t.local); return o === e ? null : o === r ? i : i = n(r = o, e); // NOSONAR
    }; // NOSONAR
  } function zn(t, n, e) { // NOSONAR
    var r, i, o; return function() { // NOSONAR
      var u, a = e(this); {if (a != null) { // NOSONAR
        return (u = this.getAttribute(t)) === a ? null : u === r && a === i ? o : o = n(r = u, i = a); // NOSONAR
      } this.removeAttribute(t);} // NOSONAR
    }; // NOSONAR
  } function Pn(t, n, e) { // NOSONAR
    var r, i, o; return function() { // NOSONAR
      var u, a = e(this); {if (a != null) { // NOSONAR
        return (u = this.getAttributeNS(t.space, t.local)) === a ? null : u === r && a === i ? o : o = n(r = u, i = a); // NOSONAR
      } this.removeAttributeNS(t.space, t.local);} // NOSONAR
    }; // NOSONAR
  } function Rn(t, n) { // NOSONAR
    function e() { // NOSONAR
      var e = this, r = n.apply(e, arguments); return r && function(n) { // NOSONAR
        e.setAttributeNS(t.space, t.local, r(n)); // NOSONAR
      }; // NOSONAR
    } return e._value = n, e; // NOSONAR
  } function Ln(t, n) { // NOSONAR
    function e() { // NOSONAR
      var e = this, r = n.apply(e, arguments); return r && function(n) { // NOSONAR
        e.setAttribute(t, r(n)); // NOSONAR
      }; // NOSONAR
    } return e._value = n, e; // NOSONAR
  } function qn(t, n) { // NOSONAR
    return function() { // NOSONAR
      xn(this, t).delay = +n.apply(this, arguments); // NOSONAR
    }; // NOSONAR
  } function Un(t, n) { // NOSONAR
    return n = +n, function() { // NOSONAR
      xn(this, t).delay = n; // NOSONAR
    }; // NOSONAR
  } function Dn(t, n) { // NOSONAR
    return function() { // NOSONAR
      bn(this, t).duration = +n.apply(this, arguments); // NOSONAR
    }; // NOSONAR
  } function On(t, n) { // NOSONAR
    return n = +n, function() { // NOSONAR
      bn(this, t).duration = n; // NOSONAR
    }; // NOSONAR
  } function Fn(t, n) { // NOSONAR
    if (typeof n !== 'function') { // NOSONAR
      throw new Error; // NOSONAR
    } return function() { // NOSONAR
      bn(this, t).ease = n; // NOSONAR
    }; // NOSONAR
  } function In(t) { // NOSONAR
    return (t + '').trim().split(/^|\s+/).every(function(t) { // NOSONAR
      var n = t.indexOf('.'); return n >= 0 && (t = t.slice(0, n)), !t || t === 'start'; // NOSONAR
    }); // NOSONAR
  } function Yn(t, n, e) { // NOSONAR
    var r, i, o = In(n) ? xn : bn; return function() { // NOSONAR
      var u = o(this, t), a = u.on; a !== r && (i = (r = a).copy()).on(n, e), u.on = i; // NOSONAR
    }; // NOSONAR
  } function Bn(t) { // NOSONAR
    return function() { // NOSONAR
      var n = this.parentNode; for (var e in this.__transition) { // NOSONAR
        if (+e !== t) { // NOSONAR
          return; // NOSONAR
        } // NOSONAR
      } n && n.removeChild(this); // NOSONAR
    }; // NOSONAR
  } function jn(t, n) { // NOSONAR
    var e, r, i; return function() { // NOSONAR
      var o = B(this, t), u = (this.style.removeProperty(t), B(this, t)); return o === u ? null : o === e && u === r ? i : i = n(e = o, r = u); // NOSONAR
    }; // NOSONAR
  } function Hn(t) { // NOSONAR
    return function() { // NOSONAR
      this.style.removeProperty(t); // NOSONAR
    }; // NOSONAR
  } function Xn(t, n, e) { // NOSONAR
    var r, i; return function() { // NOSONAR
      var o = B(this, t); return o === e ? null : o === r ? i : i = n(r = o, e); // NOSONAR
    }; // NOSONAR
  } function $n(t, n, e) { // NOSONAR
    var r, i, o; return function() { // NOSONAR
      var u = B(this, t), a = e(this); return a == null && (this.style.removeProperty(t), a = B(this, t)), u === a ? null : u === r && a === i ? o : o = n(r = u, i = a); // NOSONAR
    }; // NOSONAR
  } function Vn(t, n, e) { // NOSONAR
    function r() { // NOSONAR
      var r = this, i = n.apply(r, arguments); return i && function(n) { // NOSONAR
        r.style.setProperty(t, i(n), e); // NOSONAR
      }; // NOSONAR
    } return r._value = n, r; // NOSONAR
  } function Wn(t) { // NOSONAR
    return function() { // NOSONAR
      this.textContent = t; // NOSONAR
    }; // NOSONAR
  } function Zn(t) { // NOSONAR
    return function() { // NOSONAR
      var n = t(this); this.textContent = n == null ? '' : n; // NOSONAR
    }; // NOSONAR
  } function Gn(t, n, e, r) { // NOSONAR
    this._groups = t, this._parents = n, this._name = e, this._id = r; // NOSONAR
  } function Jn(t) { // NOSONAR
    return dt().transition(t); // NOSONAR
  } function Qn() { // NOSONAR
    return ++Wl; // NOSONAR
  } function Kn(t) { // NOSONAR
    return ((t *= 2) <= 1 ? t * t : --t * (2 - t) + 1) / 2; // NOSONAR
  } function te(t) { // NOSONAR
    return ((t *= 2) <= 1 ? t * t * t : (t -= 2) * t * t + 2) / 2; // NOSONAR
  } function ne(t) { // NOSONAR
    return (1 - Math.cos(Kl * t)) / 2; // NOSONAR
  } function ee(t) { // NOSONAR
    return ((t *= 2) <= 1 ? Math.pow(2, 10 * t - 10) : 2 - Math.pow(2, 10 - 10 * t)) / 2; // NOSONAR
  } function re(t) { // NOSONAR
    return ((t *= 2) <= 1 ? 1 - Math.sqrt(1 - t * t) : Math.sqrt(1 - (t -= 2) * t) + 1) / 2; // NOSONAR
  } function ie(t) { // NOSONAR
    return (t = +t) < nh ? fh * t * t : t < rh ? fh * (t -= eh) * t + ih : t < uh ? fh * (t -= oh) * t + ah : fh * (t -= ch) * t + sh; // NOSONAR
  } function oe(t, n) { // NOSONAR
    for (var e; !(e = t.__transition) || !(e = e[n]);) { // NOSONAR
      if (!(t = t.parentNode)) { // NOSONAR
        return yh.time = ln(), yh; // NOSONAR
      } // NOSONAR
    } return e; // NOSONAR
  } function ue() { // NOSONAR
    t.event.stopImmediatePropagation(); // NOSONAR
  } function ae(t) { // NOSONAR
    return {type: t}; // NOSONAR
  } function ce() { // NOSONAR
    return !t.event.button; // NOSONAR
  } function se() { // NOSONAR
    var t = this.ownerSVGElement || this; return [[0, 0], [t.width.baseVal.value, t.height.baseVal.value]]; // NOSONAR
  } function fe(t) { // NOSONAR
    for (;!t.__brush;) { // NOSONAR
      if (!(t = t.parentNode)) { // NOSONAR
        return; // NOSONAR
      } // NOSONAR
    } return t.__brush; // NOSONAR
  } function le(t) { // NOSONAR
    return t[0][0] === t[1][0] || t[0][1] === t[1][1]; // NOSONAR
  } function he(n) { // NOSONAR
    function e(t) { // NOSONAR
      var e = t.property('__brush', a).selectAll('.overlay').data([ ae('overlay') ]); e.enter().append('rect').attr('class', 'overlay').attr('pointer-events', 'all').attr('cursor', Ch.overlay).merge(e).each(function() { // NOSONAR
        var t = fe(this).extent; ff(this).attr('x', t[0][0]).attr('y', t[0][1]).attr('width', t[1][0] - t[0][0]).attr('height', t[1][1] - t[0][1]); // NOSONAR
      }), t.selectAll('.selection').data([ ae('selection') ]).enter().append('rect').attr('class', 'selection').attr('cursor', Ch.selection).attr('fill', '#777').attr('fill-opacity', .3).attr('stroke', '#fff').attr('shape-rendering', 'crispEdges'); var i = t.selectAll('.handle').data(n.handles, function(t) { // NOSONAR
        return t.type; // NOSONAR
      }); i.exit().remove(), i.enter().append('rect').attr('class', function(t) { // NOSONAR
        return 'handle handle--' + t.type; // NOSONAR
      }).attr('cursor', function(t) { // NOSONAR
        return Ch[t.type]; // NOSONAR
      }), t.each(r).attr('fill', 'none').attr('pointer-events', 'all').style('-webkit-tap-highlight-color', 'rgba(0,0,0,0)').on('mousedown.brush touchstart.brush', u); // NOSONAR
    } function r() { // NOSONAR
      var t = ff(this), n = fe(this).selection; n ? (t.selectAll('.selection').style('display', null).attr('x', n[0][0]).attr('y', n[0][1]).attr('width', n[1][0] - n[0][0]).attr('height', n[1][1] - n[0][1]), t.selectAll('.handle').style('display', null).attr('x', function(t) { // NOSONAR
        return t.type[t.type.length - 1] === 'e' ? n[1][0] - p / 2 : n[0][0] - p / 2; // NOSONAR
      }).attr('y', function(t) { // NOSONAR
        return t.type[0] === 's' ? n[1][1] - p / 2 : n[0][1] - p / 2; // NOSONAR
      }).attr('width', function(t) { // NOSONAR
        return t.type === 'n' || t.type === 's' ? n[1][0] - n[0][0] + p : p; // NOSONAR
      }).attr('height', function(t) { // NOSONAR
        return t.type === 'e' || t.type === 'w' ? n[1][1] - n[0][1] + p : p; // NOSONAR
      })) : t.selectAll('.selection,.handle').style('display', 'none').attr('x', null).attr('y', null).attr('width', null).attr('height', null); // NOSONAR
    } function i(t, n) { // NOSONAR
      return t.__brush.emitter || new o(t, n); // NOSONAR
    } function o(t, n) { // NOSONAR
      this.that = t, this.args = n, this.state = t.__brush, this.active = 0; // NOSONAR
    } function u() { // NOSONAR
      function e() { // NOSONAR
        var t = nf(w); !L || x || b || (Math.abs(t[0] - U[0]) > Math.abs(t[1] - U[1]) ? b = !0 : x = !0), U = t, m = !0, wh(), o(); // NOSONAR
      } function o() { // NOSONAR
        var t; switch (g = U[0] - q[0], y = U[1] - q[1], T) { // NOSONAR
          case Th:case Mh:N && (g = Math.max(C - a, Math.min(P - p, g)), s = a + g, d = p + g), k && (y = Math.max(z - l, Math.min(R - v, y)), h = l + y, _ = v + y); break; case Nh:N < 0 ? (g = Math.max(C - a, Math.min(P - a, g)), s = a + g, d = p) : N > 0 && (g = Math.max(C - p, Math.min(P - p, g)), s = a, d = p + g), k < 0 ? (y = Math.max(z - l, Math.min(R - l, y)), h = l + y, _ = v) : k > 0 && (y = Math.max(z - v, Math.min(R - v, y)), h = l, _ = v + y); break; case kh:N && (s = Math.max(C, Math.min(P, a - g * N)), d = Math.max(C, Math.min(P, p + g * N))), k && (h = Math.max(z, Math.min(R, l - y * k)), _ = Math.max(z, Math.min(R, v + y * k))); // NOSONAR
        }d < s && (N *= -1, t = a, a = p, p = t, t = s, s = d, d = t, M in zh && F.attr('cursor', Ch[M = zh[M]])), _ < h && (k *= -1, t = l, l = v, v = t, t = h, h = _, _ = t, M in Ph && F.attr('cursor', Ch[M = Ph[M]])), S.selection && (A = S.selection), x && (s = A[0][0], d = A[1][0]), b && (h = A[0][1], _ = A[1][1]), A[0][0] === s && A[0][1] === h && A[1][0] === d && A[1][1] === _ || (S.selection = [[s, h], [d, _]], r.call(w), D.brush()); // NOSONAR
      } function u() { // NOSONAR
        if (ue(), t.event.touches) { // NOSONAR
          if (t.event.touches.length) { // NOSONAR
            return; // NOSONAR
          } c && clearTimeout(c), c = setTimeout(function() { // NOSONAR
            c = null; // NOSONAR
          }, 500), O.on('touchmove.brush touchend.brush touchcancel.brush', null); // NOSONAR
        } else { // NOSONAR
          _t(t.event.view, m), I.on('keydown.brush keyup.brush mousemove.brush mouseup.brush', null); // NOSONAR
        }O.attr('pointer-events', 'all'), F.attr('cursor', Ch.overlay), S.selection && (A = S.selection), le(A) && (S.selection = null, r.call(w)), D.end(); // NOSONAR
      } if (t.event.touches) { // NOSONAR
        if (t.event.changedTouches.length < t.event.touches.length) { // NOSONAR
          return wh(); // NOSONAR
        } // NOSONAR
      } else if (c) { // NOSONAR
        return; // NOSONAR
      } if (f.apply(this, arguments)) { // NOSONAR
        var a, s, l, h, p, d, v, _, g, y, m, x, b, w = this, M = t.event.target.__data__.type, T = (t.event.metaKey ? M = 'overlay' : M) === 'selection' ? Mh : t.event.altKey ? kh : Nh, N = n === Eh ? null : Rh[M], k = n === Sh ? null : Lh[M], S = fe(w), E = S.extent, A = S.selection, C = E[0][0], z = E[0][1], P = E[1][0], R = E[1][1], L = N && k && t.event.shiftKey, q = nf(w), U = q, D = i(w, arguments).beforestart(); M === 'overlay' ? S.selection = A = [[a = n === Eh ? C : q[0], l = n === Sh ? z : q[1]], [p = n === Eh ? P : a, v = n === Sh ? R : l]] : (a = A[0][0], l = A[0][1], p = A[1][0], v = A[1][1]), s = a, h = l, d = p, _ = v; var O = ff(w).attr('pointer-events', 'none'), F = O.selectAll('.overlay').attr('cursor', Ch[M]); if (t.event.touches) { // NOSONAR
          O.on('touchmove.brush', e, !0).on('touchend.brush touchcancel.brush', u, !0); // NOSONAR
        } else { // NOSONAR
          var I = ff(t.event.view).on('keydown.brush', function() { // NOSONAR
            switch (t.event.keyCode) { // NOSONAR
              case 16:L = N && k; break; case 18:T === Nh && (N && (p = d - g * N, a = s + g * N), k && (v = _ - y * k, l = h + y * k), T = kh, o()); break; case 32:T !== Nh && T !== kh || (N < 0 ? p = d - g : N > 0 && (a = s - g), k < 0 ? v = _ - y : k > 0 && (l = h - y), T = Th, F.attr('cursor', Ch.selection), o()); break; default:return; // NOSONAR
            }wh(); // NOSONAR
          }, !0).on('keyup.brush', function() { // NOSONAR
            switch (t.event.keyCode) { // NOSONAR
              case 16:L && (x = b = L = !1, o()); break; case 18:T === kh && (N < 0 ? p = d : N > 0 && (a = s), k < 0 ? v = _ : k > 0 && (l = h), T = Nh, o()); break; case 32:T === Th && (t.event.altKey ? (N && (p = d - g * N, a = s + g * N), k && (v = _ - y * k, l = h + y * k), T = kh) : (N < 0 ? p = d : N > 0 && (a = s), k < 0 ? v = _ : k > 0 && (l = h), T = Nh), F.attr('cursor', Ch[M]), o()); break; default:return; // NOSONAR
            }wh(); // NOSONAR
          }, !0).on('mousemove.brush', e, !0).on('mouseup.brush', u, !0); pf(t.event.view); // NOSONAR
        }ue(), Xl(w), r.call(w), D.start(); // NOSONAR
      } // NOSONAR
    } function a() { // NOSONAR
      var t = this.__brush || {selection: null}; return t.extent = s.apply(this, arguments), t.dim = n, t; // NOSONAR
    } var c, s = se, f = ce, l = h(e, 'start', 'brush', 'end'), p = 6; return e.move = function(t, e) { // NOSONAR
      t.selection ? t.on('start.brush', function() { // NOSONAR
        i(this, arguments).beforestart().start(); // NOSONAR
      }).on('interrupt.brush end.brush', function() { // NOSONAR
        i(this, arguments).end(); // NOSONAR
      }).tween('brush', function() { // NOSONAR
        function t(t) { // NOSONAR
          u.selection = t === 1 && le(s) ? null : f(t), r.call(o), a.brush(); // NOSONAR
        } var o = this, u = o.__brush, a = i(o, arguments), c = u.selection, s = n.input(typeof e === 'function' ? e.apply(this, arguments) : e, u.extent), f = fl(c, s); return c && s ? t : t(1); // NOSONAR
      }) : t.each(function() { // NOSONAR
        var t = this, o = arguments, u = t.__brush, a = n.input(typeof e === 'function' ? e.apply(t, o) : e, u.extent), c = i(t, o).beforestart(); Xl(t), u.selection = a == null || le(a) ? null : a, r.call(t), c.start().brush().end(); // NOSONAR
      }); // NOSONAR
    }, o.prototype = {beforestart: function() { // NOSONAR
      return ++this.active == 1 && (this.state.emitter = this, this.starting = !0), this; // NOSONAR
    }, start: function() { // NOSONAR
      return this.starting && (this.starting = !1, this.emit('start')), this; // NOSONAR
    }, brush: function() { // NOSONAR
      return this.emit('brush'), this; // NOSONAR
    }, end: function() { // NOSONAR
      return --this.active == 0 && (delete this.state.emitter, this.emit('end')), this; // NOSONAR
    }, emit: function(t) { // NOSONAR
      k(new bh(e, t, n.output(this.state.selection)), l.apply, l, [t, this.that, this.args]); // NOSONAR
    }}, e.extent = function(t) { // NOSONAR
      return arguments.length ? (s = typeof t === 'function' ? t : xh([[+t[0][0], +t[0][1]], [+t[1][0], +t[1][1]]]), e) : s; // NOSONAR
    }, e.filter = function(t) { // NOSONAR
      return arguments.length ? (f = typeof t === 'function' ? t : xh(!!t), e) : f; // NOSONAR
    }, e.handleSize = function(t) { // NOSONAR
      return arguments.length ? (p = +t, e) : p; // NOSONAR
    }, e.on = function() { // NOSONAR
      var t = l.on.apply(l, arguments); return t === l ? e : t; // NOSONAR
    }, e; // NOSONAR
  } function pe(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      return t(n.source.value + n.target.value, e.source.value + e.target.value); // NOSONAR
    }; // NOSONAR
  } function de() { // NOSONAR
    this._x0 = this._y0 = this._x1 = this._y1 = null, this._ = ''; // NOSONAR
  } function ve() { // NOSONAR
    return new de; // NOSONAR
  } function _e(t) { // NOSONAR
    return t.source; // NOSONAR
  } function ge(t) { // NOSONAR
    return t.target; // NOSONAR
  } function ye(t) { // NOSONAR
    return t.radius; // NOSONAR
  } function me(t) { // NOSONAR
    return t.startAngle; // NOSONAR
  } function xe(t) { // NOSONAR
    return t.endAngle; // NOSONAR
  } function be() {} function we(t, n) { // NOSONAR
    var e = new be; if (t instanceof be) { // NOSONAR
      t.each(function(t, n) { // NOSONAR
        e.set(n, t); // NOSONAR
      }); // NOSONAR
    } else if (Array.isArray(t)) { // NOSONAR
      var r, i = -1, o = t.length; if (n == null) { // NOSONAR
        for (;++i < o;) { // NOSONAR
          e.set(i, t[i]); // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        for (;++i < o;) { // NOSONAR
          e.set(n(r = t[i], i, t), r); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } else if (t) { // NOSONAR
      for (var u in t) { // NOSONAR
        e.set(u, t[u]); // NOSONAR
      } // NOSONAR
    } return e; // NOSONAR
  } function Me() { // NOSONAR
    return {}; // NOSONAR
  } function Te(t, n, e) { // NOSONAR
    t[n] = e; // NOSONAR
  } function Ne() { // NOSONAR
    return we(); // NOSONAR
  } function ke(t, n, e) { // NOSONAR
    t.set(n, e); // NOSONAR
  } function Se() {} function Ee(t, n) { // NOSONAR
    var e = new Se; if (t instanceof Se) { // NOSONAR
      t.each(function(t) { // NOSONAR
        e.add(t); // NOSONAR
      }); // NOSONAR
    } else if (t) { // NOSONAR
      var r = -1, i = t.length; if (n == null) { // NOSONAR
        for (;++r < i;) { // NOSONAR
          e.add(t[r]); // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        for (;++r < i;) { // NOSONAR
          e.add(n(t[r], r, t)); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return e; // NOSONAR
  } function Ae(t) { // NOSONAR
    return new Function('d', 'return {' + t.map(function(t, n) { // NOSONAR
      return JSON.stringify(t) + ': d[' + n + ']'; // NOSONAR
    }).join(',') + '}'); // NOSONAR
  } function Ce(t, n) { // NOSONAR
    var e = Ae(t); return function(r, i) { // NOSONAR
      return n(e(r), i, t); // NOSONAR
    }; // NOSONAR
  } function ze(t) { // NOSONAR
    var n = Object.create(null), e = []; return t.forEach(function(t) { // NOSONAR
      for (var r in t) { // NOSONAR
        r in n || e.push(n[r] = r); // NOSONAR
      } // NOSONAR
    }), e; // NOSONAR
  } function Pe(t, n, e, r) { // NOSONAR
    if (isNaN(n) || isNaN(e)) { // NOSONAR
      return t; // NOSONAR
    } var i, o, u, a, c, s, f, l, h, p = t._root, d = {data: r}, v = t._x0, _ = t._y0, g = t._x1, y = t._y1; if (!p) { // NOSONAR
      return t._root = d, t; // NOSONAR
    } for (;p.length;) { // NOSONAR
      if ((s = n >= (o = (v + g) / 2)) ? v = o : g = o, (f = e >= (u = (_ + y) / 2)) ? _ = u : y = u, i = p, !(p = p[l = f << 1 | s])) { // NOSONAR
        return i[l] = d, t; // NOSONAR
      } // NOSONAR
    } if (a = +t._x.call(null, p.data), c = +t._y.call(null, p.data), n === a && e === c) { // NOSONAR
      return d.next = p, i ? i[l] = d : t._root = d, t; // NOSONAR
    } do { // NOSONAR
      i = i ? i[l] = new Array(4) : t._root = new Array(4), (s = n >= (o = (v + g) / 2)) ? v = o : g = o, (f = e >= (u = (_ + y) / 2)) ? _ = u : y = u; // NOSONAR
    } while ((l = f << 1 | s) == (h = (c >= u) << 1 | a >= o));return i[h] = p, i[l] = d, t; // NOSONAR
  } function Re(t) { // NOSONAR
    return t[0]; // NOSONAR
  } function Le(t) { // NOSONAR
    return t[1]; // NOSONAR
  } function qe(t, n, e) { // NOSONAR
    var r = new Ue(n == null ? Re : n, e == null ? Le : e, NaN, NaN, NaN, NaN); return t == null ? r : r.addAll(t); // NOSONAR
  } function Ue(t, n, e, r, i, o) { // NOSONAR
    this._x = t, this._y = n, this._x0 = e, this._y0 = r, this._x1 = i, this._y1 = o, this._root = void 0; // NOSONAR
  } function De(t) { // NOSONAR
    for (var n = {data: t.data}, e = n; t = t.next;) { // NOSONAR
      e = e.next = {data: t.data}; // NOSONAR
    } return n; // NOSONAR
  } function Oe(t) { // NOSONAR
    return t.x + t.vx; // NOSONAR
  } function Fe(t) { // NOSONAR
    return t.y + t.vy; // NOSONAR
  } function Ie(t) { // NOSONAR
    return t.index; // NOSONAR
  } function Ye(t, n) { // NOSONAR
    var e = t.get(n); if (!e) { // NOSONAR
      throw new Error('missing: ' + n); // NOSONAR
    } return e; // NOSONAR
  } function Be(t) { // NOSONAR
    return t.x; // NOSONAR
  } function je(t) { // NOSONAR
    return t.y; // NOSONAR
  } function He(t) { // NOSONAR
    return new Xe(t); // NOSONAR
  } function Xe(t) { // NOSONAR
    if (!(n = wp.exec(t))) { // NOSONAR
      throw new Error('invalid format: ' + t); // NOSONAR
    } var n, e = n[1] || ' ', r = n[2] || '>', i = n[3] || '-', o = n[4] || '', u = !!n[5], a = n[6] && +n[6], c = !!n[7], s = n[8] && +n[8].slice(1), f = n[9] || ''; f === 'n' ? (c = !0, f = 'g') : bp[f] || (f = ''), (u || e === '0' && r === '=') && (u = !0, e = '0', r = '='), this.fill = e, this.align = r, this.sign = i, this.symbol = o, this.zero = u, this.width = a, this.comma = c, this.precision = s, this.type = f; // NOSONAR
  } function $e(n) { // NOSONAR
    return Mp = kp(n), t.format = Mp.format, t.formatPrefix = Mp.formatPrefix, Mp; // NOSONAR
  } function Ve() { // NOSONAR
    this.reset(); // NOSONAR
  } function We(t, n, e) { // NOSONAR
    var r = t.s = n + e, i = r - n, o = r - i; t.t = n - o + (e - i); // NOSONAR
  } function Ze(t) { // NOSONAR
    return t > 1 ? 0 : t < -1 ? fd : Math.acos(t); // NOSONAR
  } function Ge(t) { // NOSONAR
    return t > 1 ? ld : t < -1 ? -ld : Math.asin(t); // NOSONAR
  } function Je(t) { // NOSONAR
    return (t = Td(t / 2)) * t; // NOSONAR
  } function Qe() {} function Ke(t, n) { // NOSONAR
    t && Ad.hasOwnProperty(t.type) && Ad[t.type](t, n); // NOSONAR
  } function tr(t, n, e) { // NOSONAR
    var r, i = -1, o = t.length - e; for (n.lineStart(); ++i < o;) { // NOSONAR
      r = t[i], n.point(r[0], r[1], r[2]); // NOSONAR
    }n.lineEnd(); // NOSONAR
  } function nr(t, n) { // NOSONAR
    var e = -1, r = t.length; for (n.polygonStart(); ++e < r;) { // NOSONAR
      tr(t[e], n, 1); // NOSONAR
    }n.polygonEnd(); // NOSONAR
  } function er() { // NOSONAR
    Rd.point = ir; // NOSONAR
  } function rr() { // NOSONAR
    or(zp, Pp); // NOSONAR
  } function ir(t, n) { // NOSONAR
    Rd.point = or, zp = t, Pp = n, Rp = t *= vd, Lp = md(n = (n *= vd) / 2 + hd), qp = Td(n); // NOSONAR
  } function or(t, n) { // NOSONAR
    n = (n *= vd) / 2 + hd; var e = (t *= vd) - Rp, r = e >= 0 ? 1 : -1, i = r * e, o = md(n), u = Td(n), a = qp * u, c = Lp * o + a * md(i), s = a * r * Td(i); zd.add(yd(s, c)), Rp = t, Lp = o, qp = u; // NOSONAR
  } function ur(t) { // NOSONAR
    return [yd(t[1], t[0]), Ge(t[2])]; // NOSONAR
  } function ar(t) { // NOSONAR
    var n = t[0], e = t[1], r = md(e); return [r * md(n), r * Td(n), Td(e)]; // NOSONAR
  } function cr(t, n) { // NOSONAR
    return t[0] * n[0] + t[1] * n[1] + t[2] * n[2]; // NOSONAR
  } function sr(t, n) { // NOSONAR
    return [t[1] * n[2] - t[2] * n[1], t[2] * n[0] - t[0] * n[2], t[0] * n[1] - t[1] * n[0]]; // NOSONAR
  } function fr(t, n) { // NOSONAR
    t[0] += n[0], t[1] += n[1], t[2] += n[2]; // NOSONAR
  } function lr(t, n) { // NOSONAR
    return [t[0] * n, t[1] * n, t[2] * n]; // NOSONAR
  } function hr(t) { // NOSONAR
    var n = kd(t[0] * t[0] + t[1] * t[1] + t[2] * t[2]); t[0] /= n, t[1] /= n, t[2] /= n; // NOSONAR
  } function pr(t, n) { // NOSONAR
    Hp.push(Xp = [Up = t, Op = t]), n < Dp && (Dp = n), n > Fp && (Fp = n); // NOSONAR
  } function dr(t, n) { // NOSONAR
    var e = ar([t * vd, n * vd]); if (jp) { // NOSONAR
      var r = sr(jp, e), i = sr([r[1], -r[0], 0], r); hr(i), i = ur(i); var o, u = t - Ip, a = u > 0 ? 1 : -1, c = i[0] * dd * a, s = _d(u) > 180; s ^ (a * Ip < c && c < a * t) ? (o = i[1] * dd) > Fp && (Fp = o) : (c = (c + 360) % 360 - 180, s ^ (a * Ip < c && c < a * t) ? (o = -i[1] * dd) < Dp && (Dp = o) : (n < Dp && (Dp = n), n > Fp && (Fp = n))), s ? t < Ip ? xr(Up, t) > xr(Up, Op) && (Op = t) : xr(t, Op) > xr(Up, Op) && (Up = t) : Op >= Up ? (t < Up && (Up = t), t > Op && (Op = t)) : t > Ip ? xr(Up, t) > xr(Up, Op) && (Op = t) : xr(t, Op) > xr(Up, Op) && (Up = t); // NOSONAR
    } else { // NOSONAR
      Hp.push(Xp = [Up = t, Op = t]); // NOSONAR
    }n < Dp && (Dp = n), n > Fp && (Fp = n), jp = e, Ip = t; // NOSONAR
  } function vr() { // NOSONAR
    qd.point = dr; // NOSONAR
  } function _r() { // NOSONAR
    Xp[0] = Up, Xp[1] = Op, qd.point = pr, jp = null; // NOSONAR
  } function gr(t, n) { // NOSONAR
    if (jp) { // NOSONAR
      var e = t - Ip; Ld.add(_d(e) > 180 ? e + (e > 0 ? 360 : -360) : e); // NOSONAR
    } else { // NOSONAR
      Yp = t, Bp = n; // NOSONAR
    }Rd.point(t, n), dr(t, n); // NOSONAR
  } function yr() { // NOSONAR
    Rd.lineStart(); // NOSONAR
  } function mr() { // NOSONAR
    gr(Yp, Bp), Rd.lineEnd(), _d(Ld) > sd && (Up = -(Op = 180)), Xp[0] = Up, Xp[1] = Op, jp = null; // NOSONAR
  } function xr(t, n) { // NOSONAR
    return (n -= t) < 0 ? n + 360 : n; // NOSONAR
  } function br(t, n) { // NOSONAR
    return t[0] - n[0]; // NOSONAR
  } function wr(t, n) { // NOSONAR
    return t[0] <= t[1] ? t[0] <= n && n <= t[1] : n < t[0] || t[1] < n; // NOSONAR
  } function Mr(t, n) { // NOSONAR
    t *= vd; var e = md(n *= vd); Tr(e * md(t), e * Td(t), Td(n)); // NOSONAR
  } function Tr(t, n, e) { // NOSONAR
    Wp += (t - Wp) / ++$p, Zp += (n - Zp) / $p, Gp += (e - Gp) / $p; // NOSONAR
  } function Nr() { // NOSONAR
    Ud.point = kr; // NOSONAR
  } function kr(t, n) { // NOSONAR
    t *= vd; var e = md(n *= vd); od = e * md(t), ud = e * Td(t), ad = Td(n), Ud.point = Sr, Tr(od, ud, ad); // NOSONAR
  } function Sr(t, n) { // NOSONAR
    t *= vd; var e = md(n *= vd), r = e * md(t), i = e * Td(t), o = Td(n), u = yd(kd((u = ud * o - ad * i) * u + (u = ad * r - od * o) * u + (u = od * i - ud * r) * u), od * r + ud * i + ad * o); Vp += u, Jp += u * (od + (od = r)), Qp += u * (ud + (ud = i)), Kp += u * (ad + (ad = o)), Tr(od, ud, ad); // NOSONAR
  } function Er() { // NOSONAR
    Ud.point = Mr; // NOSONAR
  } function Ar() { // NOSONAR
    Ud.point = zr; // NOSONAR
  } function Cr() { // NOSONAR
    Pr(rd, id), Ud.point = Mr; // NOSONAR
  } function zr(t, n) { // NOSONAR
    rd = t, id = n, t *= vd, n *= vd, Ud.point = Pr; var e = md(n); od = e * md(t), ud = e * Td(t), ad = Td(n), Tr(od, ud, ad); // NOSONAR
  } function Pr(t, n) { // NOSONAR
    t *= vd; var e = md(n *= vd), r = e * md(t), i = e * Td(t), o = Td(n), u = ud * o - ad * i, a = ad * r - od * o, c = od * i - ud * r, s = kd(u * u + a * a + c * c), f = Ge(s), l = s && -f / s; td += l * u, nd += l * a, ed += l * c, Vp += f, Jp += f * (od + (od = r)), Qp += f * (ud + (ud = i)), Kp += f * (ad + (ad = o)), Tr(od, ud, ad); // NOSONAR
  } function Rr(t, n) { // NOSONAR
    return [t > fd ? t - pd : t < -fd ? t + pd : t, n]; // NOSONAR
  } function Lr(t, n, e) { // NOSONAR
    return (t %= pd) ? n || e ? Od(Ur(t), Dr(n, e)) : Ur(t) : n || e ? Dr(n, e) : Rr; // NOSONAR
  } function qr(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      return n += t, [n > fd ? n - pd : n < -fd ? n + pd : n, e]; // NOSONAR
    }; // NOSONAR
  } function Ur(t) { // NOSONAR
    var n = qr(t); return n.invert = qr(-t), n; // NOSONAR
  } function Dr(t, n) { // NOSONAR
    function e(t, n) { // NOSONAR
      var e = md(n), a = md(t) * e, c = Td(t) * e, s = Td(n), f = s * r + a * i; return [yd(c * o - f * u, a * r - s * i), Ge(f * o + c * u)]; // NOSONAR
    } var r = md(t), i = Td(t), o = md(n), u = Td(n); return e.invert = function(t, n) { // NOSONAR
      var e = md(n), a = md(t) * e, c = Td(t) * e, s = Td(n), f = s * o - c * u; return [yd(c * o + s * u, a * r + f * i), Ge(f * r - a * i)]; // NOSONAR
    }, e; // NOSONAR
  } function Or(t, n, e, r, i, o) { // NOSONAR
    if (e) { // NOSONAR
      var u = md(n), a = Td(n), c = r * e; i == null ? (i = n + r * pd, o = n - c / 2) : (i = Fr(u, i), o = Fr(u, o), (r > 0 ? i < o : i > o) && (i += r * pd)); for (var s, f = i; r > 0 ? f > o : f < o; f -= c) { // NOSONAR
        s = ur([u, -a * md(f), -a * Td(f)]), t.point(s[0], s[1]); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function Fr(t, n) { // NOSONAR
    (n = ar(n))[0] -= t, hr(n); var e = Ze(-n[1]); return ((-n[2] < 0 ? -e : e) + pd - sd) % pd; // NOSONAR
  } function Ir(t, n, e, r) { // NOSONAR
    this.x = t, this.z = n, this.o = e, this.e = r, this.v = !1, this.n = this.p = null; // NOSONAR
  } function Yr(t) { // NOSONAR
    if (n = t.length) { // NOSONAR
      for (var n, e, r = 0, i = t[0]; ++r < n;) { // NOSONAR
        i.n = e = t[r], e.p = i, i = e; // NOSONAR
      }i.n = e = t[0], e.p = i; // NOSONAR
    } // NOSONAR
  } function Br(t) { // NOSONAR
    return t.length > 1; // NOSONAR
  } function jr(t, n) { // NOSONAR
    return ((t = t.x)[0] < 0 ? t[1] - ld - sd : ld - t[1]) - ((n = n.x)[0] < 0 ? n[1] - ld - sd : ld - n[1]); // NOSONAR
  } function Hr(t, n, e, r) { // NOSONAR
    var i, o, u = Td(t - e); return _d(u) > sd ? gd((Td(n) * (o = md(r)) * Td(e) - Td(r) * (i = md(n)) * Td(t)) / (i * o * u)) : (n + r) / 2; // NOSONAR
  } function Xr(t, n, e, r) { // NOSONAR
    function i(i, o) { // NOSONAR
      return t <= i && i <= e && n <= o && o <= r; // NOSONAR
    } function o(i, o, a, s) { // NOSONAR
      var f = 0, l = 0; if (i == null || (f = u(i, a)) !== (l = u(o, a)) || c(i, o) < 0 ^ a > 0) { // NOSONAR
        do { // NOSONAR
          s.point(f === 0 || f === 3 ? t : e, f > 1 ? r : n); // NOSONAR
        } while ((f = (f + a + 4) % 4) !== l); // NOSONAR
      } else { // NOSONAR
        s.point(o[0], o[1]); // NOSONAR
      } // NOSONAR
    } function u(r, i) { // NOSONAR
      return _d(r[0] - t) < sd ? i > 0 ? 0 : 3 : _d(r[0] - e) < sd ? i > 0 ? 2 : 1 : _d(r[1] - n) < sd ? i > 0 ? 1 : 0 : i > 0 ? 3 : 2; // NOSONAR
    } function a(t, n) { // NOSONAR
      return c(t.x, n.x); // NOSONAR
    } function c(t, n) { // NOSONAR
      var e = u(t, 1), r = u(n, 1); return e !== r ? e - r : e === 0 ? n[1] - t[1] : e === 1 ? t[0] - n[0] : e === 2 ? t[1] - n[1] : n[0] - t[0]; // NOSONAR
    } return function(u) { // NOSONAR
      function c(t, n) { // NOSONAR
        i(t, n) && w.point(t, n); // NOSONAR
      } function s() { // NOSONAR
        for (var n = 0, e = 0, i = h.length; e < i; ++e) { // NOSONAR
          for (var o, u, a = h[e], c = 1, s = a.length, f = a[0], l = f[0], p = f[1]; c < s; ++c) { // NOSONAR
            o = l, u = p, l = (f = a[c])[0], p = f[1], u <= r ? p > r && (l - o) * (r - u) > (p - u) * (t - o) && ++n : p <= r && (l - o) * (r - u) < (p - u) * (t - o) && --n; // NOSONAR
          } // NOSONAR
        } return n; // NOSONAR
      } function f(o, u) { // NOSONAR
        var a = i(o, u); if (h && p.push([o, u]), x) { // NOSONAR
          d = o, v = u, _ = a, x = !1, a && (w.lineStart(), w.point(o, u)); // NOSONAR
        } else if (a && m) { // NOSONAR
          w.point(o, u); // NOSONAR
        } else { // NOSONAR
          var c = [g = Math.max(av, Math.min(uv, g)), y = Math.max(av, Math.min(uv, y))], s = [o = Math.max(av, Math.min(uv, o)), u = Math.max(av, Math.min(uv, u))]; ov(c, s, t, n, e, r) ? (m || (w.lineStart(), w.point(c[0], c[1])), w.point(s[0], s[1]), a || w.lineEnd(), b = !1) : a && (w.lineStart(), w.point(o, u), b = !1); // NOSONAR
        }g = o, y = u, m = a; // NOSONAR
      } var l, h, p, d, v, _, g, y, m, x, b, w = u, M = Jd(), T = {point: c, lineStart: function() { // NOSONAR
        T.point = f, h && h.push(p = []), x = !0, m = !1, g = y = NaN; // NOSONAR
      }, lineEnd: function() { // NOSONAR
        l && (f(d, v), _ && m && M.rejoin(), l.push(M.result())), T.point = c, m && w.lineEnd(); // NOSONAR
      }, polygonStart: function() { // NOSONAR
        w = M, l = [], h = [], b = !0; // NOSONAR
      }, polygonEnd: function() { // NOSONAR
        var t = s(), n = b && t, e = (l = Ps(l)).length; (n || e) && (u.polygonStart(), n && (u.lineStart(), o(null, null, 1, u), u.lineEnd()), e && Kd(l, a, t, o, u), u.polygonEnd()), w = u, l = h = p = null; // NOSONAR
      }}; return T; // NOSONAR
    }; // NOSONAR
  } function $r() { // NOSONAR
    sv.point = sv.lineEnd = Qe; // NOSONAR
  } function Vr(t, n) { // NOSONAR
    Fd = t *= vd, Id = Td(n *= vd), Yd = md(n), sv.point = Wr; // NOSONAR
  } function Wr(t, n) { // NOSONAR
    t *= vd; var e = Td(n *= vd), r = md(n), i = _d(t - Fd), o = md(i), u = r * Td(i), a = Yd * e - Id * r * o, c = Id * e + Yd * r * o; cv.add(yd(kd(u * u + a * a), c)), Fd = t, Id = e, Yd = r; // NOSONAR
  } function Zr(t, n) { // NOSONAR
    return !(!t || !vv.hasOwnProperty(t.type)) && vv[t.type](t, n); // NOSONAR
  } function Gr(t, n) { // NOSONAR
    return pv(t, n) === 0; // NOSONAR
  } function Jr(t, n) { // NOSONAR
    var e = pv(t[0], t[1]); return pv(t[0], n) + pv(n, t[1]) <= e + sd; // NOSONAR
  } function Qr(t, n) { // NOSONAR
    return !!nv(t.map(Kr), ti(n)); // NOSONAR
  } function Kr(t) { // NOSONAR
    return (t = t.map(ti)).pop(), t; // NOSONAR
  } function ti(t) { // NOSONAR
    return [t[0] * vd, t[1] * vd]; // NOSONAR
  } function ni(t, n, e) { // NOSONAR
    var r = Ns(t, n - sd, e).concat(n); return function(t) { // NOSONAR
      return r.map(function(n) { // NOSONAR
        return [t, n]; // NOSONAR
      }); // NOSONAR
    }; // NOSONAR
  } function ei(t, n, e) { // NOSONAR
    var r = Ns(t, n - sd, e).concat(n); return function(t) { // NOSONAR
      return r.map(function(n) { // NOSONAR
        return [n, t]; // NOSONAR
      }); // NOSONAR
    }; // NOSONAR
  } function ri() { // NOSONAR
    function t() { // NOSONAR
      return {type: 'MultiLineString', coordinates: n()}; // NOSONAR
    } function n() { // NOSONAR
      return Ns(xd(o / _) * _, i, _).map(h).concat(Ns(xd(s / g) * g, c, g).map(p)).concat(Ns(xd(r / d) * d, e, d).filter(function(t) { // NOSONAR
        return _d(t % _) > sd; // NOSONAR
      }).map(f)).concat(Ns(xd(a / v) * v, u, v).filter(function(t) { // NOSONAR
        return _d(t % g) > sd; // NOSONAR
      }).map(l)); // NOSONAR
    } var e, r, i, o, u, a, c, s, f, l, h, p, d = 10, v = d, _ = 90, g = 360, y = 2.5; return t.lines = function() { // NOSONAR
      return n().map(function(t) { // NOSONAR
        return {type: 'LineString', coordinates: t}; // NOSONAR
      }); // NOSONAR
    }, t.outline = function() { // NOSONAR
      return {type: 'Polygon', coordinates: [ h(o).concat(p(c).slice(1), h(i).reverse().slice(1), p(s).reverse().slice(1)) ]}; // NOSONAR
    }, t.extent = function(n) { // NOSONAR
      return arguments.length ? t.extentMajor(n).extentMinor(n) : t.extentMinor(); // NOSONAR
    }, t.extentMajor = function(n) { // NOSONAR
      return arguments.length ? (o = +n[0][0], i = +n[1][0], s = +n[0][1], c = +n[1][1], o > i && (n = o, o = i, i = n), s > c && (n = s, s = c, c = n), t.precision(y)) : [[o, s], [i, c]]; // NOSONAR
    }, t.extentMinor = function(n) { // NOSONAR
      return arguments.length ? (r = +n[0][0], e = +n[1][0], a = +n[0][1], u = +n[1][1], r > e && (n = r, r = e, e = n), a > u && (n = a, a = u, u = n), t.precision(y)) : [[r, a], [e, u]]; // NOSONAR
    }, t.step = function(n) { // NOSONAR
      return arguments.length ? t.stepMajor(n).stepMinor(n) : t.stepMinor(); // NOSONAR
    }, t.stepMajor = function(n) { // NOSONAR
      return arguments.length ? (_ = +n[0], g = +n[1], t) : [_, g]; // NOSONAR
    }, t.stepMinor = function(n) { // NOSONAR
      return arguments.length ? (d = +n[0], v = +n[1], t) : [d, v]; // NOSONAR
    }, t.precision = function(n) { // NOSONAR
      return arguments.length ? (y = +n, f = ni(a, u, 90), l = ei(r, e, y), h = ni(s, c, 90), p = ei(o, i, y), t) : y; // NOSONAR
    }, t.extentMajor([[-180, -90 + sd], [180, 90 - sd]]).extentMinor([[-180, -80 - sd], [180, 80 + sd]]); // NOSONAR
  } function ii() { // NOSONAR
    mv.point = oi; // NOSONAR
  } function oi(t, n) { // NOSONAR
    mv.point = ui, Bd = Hd = t, jd = Xd = n; // NOSONAR
  } function ui(t, n) { // NOSONAR
    yv.add(Xd * t - Hd * n), Hd = t, Xd = n; // NOSONAR
  } function ai() { // NOSONAR
    ui(Bd, jd); // NOSONAR
  } function ci(t, n) { // NOSONAR
    Nv += t, kv += n, ++Sv; // NOSONAR
  } function si() { // NOSONAR
    Lv.point = fi; // NOSONAR
  } function fi(t, n) { // NOSONAR
    Lv.point = li, ci(Wd = t, Zd = n); // NOSONAR
  } function li(t, n) { // NOSONAR
    var e = t - Wd, r = n - Zd, i = kd(e * e + r * r); Ev += i * (Wd + t) / 2, Av += i * (Zd + n) / 2, Cv += i, ci(Wd = t, Zd = n); // NOSONAR
  } function hi() { // NOSONAR
    Lv.point = ci; // NOSONAR
  } function pi() { // NOSONAR
    Lv.point = vi; // NOSONAR
  } function di() { // NOSONAR
    _i($d, Vd); // NOSONAR
  } function vi(t, n) { // NOSONAR
    Lv.point = _i, ci($d = Wd = t, Vd = Zd = n); // NOSONAR
  } function _i(t, n) { // NOSONAR
    var e = t - Wd, r = n - Zd, i = kd(e * e + r * r); Ev += i * (Wd + t) / 2, Av += i * (Zd + n) / 2, Cv += i, zv += (i = Zd * t - Wd * n) * (Wd + t), Pv += i * (Zd + n), Rv += 3 * i, ci(Wd = t, Zd = n); // NOSONAR
  } function gi(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function yi(t, n) { // NOSONAR
    Yv.point = mi, Uv = Ov = t, Dv = Fv = n; // NOSONAR
  } function mi(t, n) { // NOSONAR
    Ov -= t, Fv -= n, Iv.add(kd(Ov * Ov + Fv * Fv)), Ov = t, Fv = n; // NOSONAR
  } function xi() { // NOSONAR
    this._string = []; // NOSONAR
  } function bi(t) { // NOSONAR
    return 'm0,' + t + 'a' + t + ',' + t + ' 0 1,1 0,' + -2 * t + 'a' + t + ',' + t + ' 0 1,1 0,' + 2 * t + 'z'; // NOSONAR
  } function wi(t) { // NOSONAR
    return function(n) { // NOSONAR
      var e = new Mi; for (var r in t) { // NOSONAR
        e[r] = t[r]; // NOSONAR
      } return e.stream = n, e; // NOSONAR
    }; // NOSONAR
  } function Mi() {} function Ti(t, n, e) { // NOSONAR
    var r = n[1][0] - n[0][0], i = n[1][1] - n[0][1], o = t.clipExtent && t.clipExtent(); t.scale(150).translate([0, 0]), o != null && t.clipExtent(null), Cd(e, t.stream(Tv)); var u = Tv.result(), a = Math.min(r / (u[1][0] - u[0][0]), i / (u[1][1] - u[0][1])), c = +n[0][0] + (r - a * (u[1][0] + u[0][0])) / 2, s = +n[0][1] + (i - a * (u[1][1] + u[0][1])) / 2; return o != null && t.clipExtent(o), t.scale(150 * a).translate([c, s]); // NOSONAR
  } function Ni(t, n, e) { // NOSONAR
    return Ti(t, [[0, 0], n], e); // NOSONAR
  } function ki(t) { // NOSONAR
    return wi({point: function(n, e) { // NOSONAR
      n = t(n, e), this.stream.point(n[0], n[1]); // NOSONAR
    }}); // NOSONAR
  } function Si(t, n) { // NOSONAR
    function e(r, i, o, u, a, c, s, f, l, h, p, d, v, _) { // NOSONAR
      var g = s - r, y = f - i, m = g * g + y * y; if (m > 4 * n && v--) { // NOSONAR
        var x = u + h, b = a + p, w = c + d, M = kd(x * x + b * b + w * w), T = Ge(w /= M), N = _d(_d(w) - 1) < sd || _d(o - l) < sd ? (o + l) / 2 : yd(b, x), k = t(N, T), S = k[0], E = k[1], A = S - r, C = E - i, z = y * A - g * C; (z * z / m > n || _d((g * A + y * C) / m - .5) > .3 || u * h + a * p + c * d < jv) && (e(r, i, o, u, a, c, S, E, N, x /= M, b /= M, w, v, _), _.point(S, E), e(S, E, N, x, b, w, s, f, l, h, p, d, v, _)); // NOSONAR
      } // NOSONAR
    } return function(n) { // NOSONAR
      function r(e, r) { // NOSONAR
        e = t(e, r), n.point(e[0], e[1]); // NOSONAR
      } function i() { // NOSONAR
        g = NaN, w.point = o, n.lineStart(); // NOSONAR
      } function o(r, i) { // NOSONAR
        var o = ar([r, i]), u = t(r, i); e(g, y, _, m, x, b, g = u[0], y = u[1], _ = r, m = o[0], x = o[1], b = o[2], Bv, n), n.point(g, y); // NOSONAR
      } function u() { // NOSONAR
        w.point = r, n.lineEnd(); // NOSONAR
      } function a() { // NOSONAR
        i(), w.point = c, w.lineEnd = s; // NOSONAR
      } function c(t, n) { // NOSONAR
        o(f = t, n), l = g, h = y, p = m, d = x, v = b, w.point = o; // NOSONAR
      } function s() { // NOSONAR
        e(g, y, _, m, x, b, l, h, f, p, d, v, Bv, n), w.lineEnd = u, u(); // NOSONAR
      } var f, l, h, p, d, v, _, g, y, m, x, b, w = {point: r, lineStart: i, lineEnd: u, polygonStart: function() { // NOSONAR
        n.polygonStart(), w.lineStart = a; // NOSONAR
      }, polygonEnd: function() { // NOSONAR
        n.polygonEnd(), w.lineStart = i; // NOSONAR
      }}; return w; // NOSONAR
    }; // NOSONAR
  } function Ei(t) { // NOSONAR
    return wi({point: function(n, e) { // NOSONAR
      var r = t(n, e); return this.stream.point(r[0], r[1]); // NOSONAR
    }}); // NOSONAR
  } function Ai(t) { // NOSONAR
    return Ci(function() { // NOSONAR
      return t; // NOSONAR
    })(); // NOSONAR
  } function Ci(t) { // NOSONAR
    function n(t) { // NOSONAR
      return t = f(t[0] * vd, t[1] * vd), [t[0] * _ + a, c - t[1] * _]; // NOSONAR
    } function e(t) { // NOSONAR
      return (t = f.invert((t[0] - a) / _, (c - t[1]) / _)) && [t[0] * dd, t[1] * dd]; // NOSONAR
    } function r(t, n) { // NOSONAR
      return t = u(t, n), [t[0] * _ + a, c - t[1] * _]; // NOSONAR
    } function i() { // NOSONAR
      f = Od(s = Lr(b, w, M), u); var t = u(m, x); return a = g - t[0] * _, c = y + t[1] * _, o(); // NOSONAR
    } function o() { // NOSONAR
      return d = v = null, n; // NOSONAR
    } var u, a, c, s, f, l, h, p, d, v, _ = 150, g = 480, y = 250, m = 0, x = 0, b = 0, w = 0, M = 0, T = null, N = rv, k = null, S = _v, E = .5, A = Hv(r, E); return n.stream = function(t) { // NOSONAR
      return d && v === t ? d : d = Xv(Ei(s)(N(A(S(v = t))))); // NOSONAR
    }, n.preclip = function(t) { // NOSONAR
      return arguments.length ? (N = t, T = void 0, o()) : N; // NOSONAR
    }, n.postclip = function(t) { // NOSONAR
      return arguments.length ? (S = t, k = l = h = p = null, o()) : S; // NOSONAR
    }, n.clipAngle = function(t) { // NOSONAR
      return arguments.length ? (N = +t ? iv(T = t * vd) : (T = null, rv), o()) : T * dd; // NOSONAR
    }, n.clipExtent = function(t) { // NOSONAR
      return arguments.length ? (S = t == null ? (k = l = h = p = null, _v) : Xr(k = +t[0][0], l = +t[0][1], h = +t[1][0], p = +t[1][1]), o()) : k == null ? null : [[k, l], [h, p]]; // NOSONAR
    }, n.scale = function(t) { // NOSONAR
      return arguments.length ? (_ = +t, i()) : _; // NOSONAR
    }, n.translate = function(t) { // NOSONAR
      return arguments.length ? (g = +t[0], y = +t[1], i()) : [g, y]; // NOSONAR
    }, n.center = function(t) { // NOSONAR
      return arguments.length ? (m = t[0] % 360 * vd, x = t[1] % 360 * vd, i()) : [m * dd, x * dd]; // NOSONAR
    }, n.rotate = function(t) { // NOSONAR
      return arguments.length ? (b = t[0] % 360 * vd, w = t[1] % 360 * vd, M = t.length > 2 ? t[2] % 360 * vd : 0, i()) : [b * dd, w * dd, M * dd]; // NOSONAR
    }, n.precision = function(t) { // NOSONAR
      return arguments.length ? (A = Hv(r, E = t * t), o()) : kd(E); // NOSONAR
    }, n.fitExtent = function(t, e) { // NOSONAR
      return Ti(n, t, e); // NOSONAR
    }, n.fitSize = function(t, e) { // NOSONAR
      return Ni(n, t, e); // NOSONAR
    }, function() { // NOSONAR
      return u = t.apply(this, arguments), n.invert = u.invert && e, i(); // NOSONAR
    }; // NOSONAR
  } function zi(t) { // NOSONAR
    var n = 0, e = fd / 3, r = Ci(t), i = r(n, e); return i.parallels = function(t) { // NOSONAR
      return arguments.length ? r(n = t[0] * vd, e = t[1] * vd) : [n * dd, e * dd]; // NOSONAR
    }, i; // NOSONAR
  } function Pi(t) { // NOSONAR
    function n(t, n) { // NOSONAR
      return [t * e, Td(n) / e]; // NOSONAR
    } var e = md(t); return n.invert = function(t, n) { // NOSONAR
      return [t / e, Ge(n * e)]; // NOSONAR
    }, n; // NOSONAR
  } function Ri(t, n) { // NOSONAR
    function e(t, n) { // NOSONAR
      var e = kd(o - 2 * i * Td(n)) / i; return [e * Td(t *= i), u - e * md(t)]; // NOSONAR
    } var r = Td(t), i = (r + Td(n)) / 2; if (_d(i) < sd) { // NOSONAR
      return Pi(t); // NOSONAR
    } var o = 1 + r * (2 * i - r), u = kd(o) / i; return e.invert = function(t, n) { // NOSONAR
      var e = u - n; return [yd(t, _d(e)) / i * Nd(e), Ge((o - (t * t + e * e) * i * i) / (2 * i))]; // NOSONAR
    }, e; // NOSONAR
  } function Li(t) { // NOSONAR
    var n = t.length; return {point: function(e, r) { // NOSONAR
      for (var i = -1; ++i < n;) { // NOSONAR
        t[i].point(e, r); // NOSONAR
      } // NOSONAR
    }, sphere: function() { // NOSONAR
      for (var e = -1; ++e < n;) { // NOSONAR
        t[e].sphere(); // NOSONAR
      } // NOSONAR
    }, lineStart: function() { // NOSONAR
      for (var e = -1; ++e < n;) { // NOSONAR
        t[e].lineStart(); // NOSONAR
      } // NOSONAR
    }, lineEnd: function() { // NOSONAR
      for (var e = -1; ++e < n;) { // NOSONAR
        t[e].lineEnd(); // NOSONAR
      } // NOSONAR
    }, polygonStart: function() { // NOSONAR
      for (var e = -1; ++e < n;) { // NOSONAR
        t[e].polygonStart(); // NOSONAR
      } // NOSONAR
    }, polygonEnd: function() { // NOSONAR
      for (var e = -1; ++e < n;) { // NOSONAR
        t[e].polygonEnd(); // NOSONAR
      } // NOSONAR
    }}; // NOSONAR
  } function qi(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      var r = md(n), i = md(e), o = t(r * i); return [o * i * Td(n), o * Td(e)]; // NOSONAR
    }; // NOSONAR
  } function Ui(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      var r = kd(n * n + e * e), i = t(r), o = Td(i), u = md(i); return [yd(n * o, r * u), Ge(r && e * o / r)]; // NOSONAR
    }; // NOSONAR
  } function Di(t, n) { // NOSONAR
    return [t, wd(Sd((ld + n) / 2))]; // NOSONAR
  } function Oi(t) { // NOSONAR
    function n() { // NOSONAR
      var n = fd * a(), u = o(Gd(o.rotate()).invert([0, 0])); return s(f == null ? [[u[0] - n, u[1] - n], [u[0] + n, u[1] + n]] : t === Di ? [[Math.max(u[0] - n, f), e], [Math.min(u[0] + n, r), i]] : [[f, Math.max(u[1] - n, e)], [r, Math.min(u[1] + n, i)]]); // NOSONAR
    } var e, r, i, o = Ai(t), u = o.center, a = o.scale, c = o.translate, s = o.clipExtent, f = null; return o.scale = function(t) { // NOSONAR
      return arguments.length ? (a(t), n()) : a(); // NOSONAR
    }, o.translate = function(t) { // NOSONAR
      return arguments.length ? (c(t), n()) : c(); // NOSONAR
    }, o.center = function(t) { // NOSONAR
      return arguments.length ? (u(t), n()) : u(); // NOSONAR
    }, o.clipExtent = function(t) { // NOSONAR
      return arguments.length ? (t == null ? f = e = r = i = null : (f = +t[0][0], e = +t[0][1], r = +t[1][0], i = +t[1][1]), n()) : f == null ? null : [[f, e], [r, i]]; // NOSONAR
    }, n(); // NOSONAR
  } function Fi(t) { // NOSONAR
    return Sd((ld + t) / 2); // NOSONAR
  } function Ii(t, n) { // NOSONAR
    function e(t, n) { // NOSONAR
      o > 0 ? n < -ld + sd && (n = -ld + sd) : n > ld - sd && (n = ld - sd); var e = o / Md(Fi(n), i); return [e * Td(i * t), o - e * md(i * t)]; // NOSONAR
    } var r = md(t), i = t === n ? Td(t) : wd(r / md(n)) / wd(Fi(n) / Fi(t)), o = r * Md(Fi(t), i) / i; return i ? (e.invert = function(t, n) { // NOSONAR
      var e = o - n, r = Nd(i) * kd(t * t + e * e); return [yd(t, _d(e)) / i * Nd(e), 2 * gd(Md(o / r, 1 / i)) - ld]; // NOSONAR
    }, e) : Di; // NOSONAR
  } function Yi(t, n) { // NOSONAR
    return [t, n]; // NOSONAR
  } function Bi(t, n) { // NOSONAR
    function e(t, n) { // NOSONAR
      var e = o - n, r = i * t; return [e * Td(r), o - e * md(r)]; // NOSONAR
    } var r = md(t), i = t === n ? Td(t) : (r - md(n)) / (n - t), o = r / i + t; return _d(i) < sd ? Yi : (e.invert = function(t, n) { // NOSONAR
      var e = o - n; return [yd(t, _d(e)) / i * Nd(e), o - Nd(i) * kd(t * t + e * e)]; // NOSONAR
    }, e); // NOSONAR
  } function ji(t, n) { // NOSONAR
    var e = md(n), r = md(t) * e; return [e * Td(t) / r, Td(n) / r]; // NOSONAR
  } function Hi(t, n, e, r) { // NOSONAR
    return t === 1 && n === 1 && e === 0 && r === 0 ? _v : wi({point: function(i, o) { // NOSONAR
      this.stream.point(i * t + e, o * n + r); // NOSONAR
    }}); // NOSONAR
  } function Xi(t, n) { // NOSONAR
    var e = n * n, r = e * e; return [t * (.8707 - .131979 * e + r * (r * (.003971 * e - .001529 * r) - .013791)), n * (1.007226 + e * (.015085 + r * (.028874 * e - .044475 - .005916 * r)))]; // NOSONAR
  } function $i(t, n) { // NOSONAR
    return [md(n) * Td(t), Td(n)]; // NOSONAR
  } function Vi(t, n) { // NOSONAR
    var e = md(n), r = 1 + md(t) * e; return [e * Td(t) / r, Td(n) / r]; // NOSONAR
  } function Wi(t, n) { // NOSONAR
    return [wd(Sd((ld + n) / 2)), -t]; // NOSONAR
  } function Zi(t, n) { // NOSONAR
    return t.parent === n.parent ? 1 : 2; // NOSONAR
  } function Gi(t) { // NOSONAR
    return t.reduce(Ji, 0) / t.length; // NOSONAR
  } function Ji(t, n) { // NOSONAR
    return t + n.x; // NOSONAR
  } function Qi(t) { // NOSONAR
    return 1 + t.reduce(Ki, 0); // NOSONAR
  } function Ki(t, n) { // NOSONAR
    return Math.max(t, n.y); // NOSONAR
  } function to(t) { // NOSONAR
    for (var n; n = t.children;) { // NOSONAR
      t = n[0]; // NOSONAR
    } return t; // NOSONAR
  } function no(t) { // NOSONAR
    for (var n; n = t.children;) { // NOSONAR
      t = n[n.length - 1]; // NOSONAR
    } return t; // NOSONAR
  } function eo(t) { // NOSONAR
    var n = 0, e = t.children, r = e && e.length; if (r) { // NOSONAR
      for (;--r >= 0;) { // NOSONAR
        n += e[r].value; // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      n = 1; // NOSONAR
    }t.value = n; // NOSONAR
  } function ro(t, n) { // NOSONAR
    if (t === n) { // NOSONAR
      return t; // NOSONAR
    } var e = t.ancestors(), r = n.ancestors(), i = null; for (t = e.pop(), n = r.pop(); t === n;) { // NOSONAR
      i = t, t = e.pop(), n = r.pop(); // NOSONAR
    } return i; // NOSONAR
  } function io(t, n) { // NOSONAR
    var e, r, i, o, u, a = new co(t), c = +t.value && (a.value = t.value), s = [ a ]; for (n == null && (n = oo); e = s.pop();) { // NOSONAR
      if (c && (e.value = +e.data.value), (i = n(e.data)) && (u = i.length)) { // NOSONAR
        for (e.children = new Array(u), o = u - 1; o >= 0; --o) { // NOSONAR
          s.push(r = e.children[o] = new co(i[o])), r.parent = e, r.depth = e.depth + 1; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return a.eachBefore(ao); // NOSONAR
  } function oo(t) { // NOSONAR
    return t.children; // NOSONAR
  } function uo(t) { // NOSONAR
    t.data = t.data.data; // NOSONAR
  } function ao(t) { // NOSONAR
    var n = 0; do { // NOSONAR
      t.height = n; // NOSONAR
    } while ((t = t.parent) && t.height < ++n); // NOSONAR
  } function co(t) { // NOSONAR
    this.data = t, this.depth = this.height = 0, this.parent = null; // NOSONAR
  } function so(t) { // NOSONAR
    for (var n, e, r = t.length; r;) { // NOSONAR
      e = Math.random() * r-- | 0, n = t[r], t[r] = t[e], t[e] = n; // NOSONAR
    } return t; // NOSONAR
  } function fo(t, n) { // NOSONAR
    var e, r; if (po(n, t)) { // NOSONAR
      return [ n ]; // NOSONAR
    } for (e = 0; e < t.length; ++e) { // NOSONAR
      if (lo(n, t[e]) && po(go(t[e], n), t)) { // NOSONAR
        return [t[e], n]; // NOSONAR
      } // NOSONAR
    } for (e = 0; e < t.length - 1; ++e) { // NOSONAR
      for (r = e + 1; r < t.length; ++r) { // NOSONAR
        if (lo(go(t[e], t[r]), n) && lo(go(t[e], n), t[r]) && lo(go(t[r], n), t[e]) && po(yo(t[e], t[r], n), t)) { // NOSONAR
          return [t[e], t[r], n]; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } throw new Error; // NOSONAR
  } function lo(t, n) { // NOSONAR
    var e = t.r - n.r, r = n.x - t.x, i = n.y - t.y; return e < 0 || e * e < r * r + i * i; // NOSONAR
  } function ho(t, n) { // NOSONAR
    var e = t.r - n.r + 1e-6, r = n.x - t.x, i = n.y - t.y; return e > 0 && e * e > r * r + i * i; // NOSONAR
  } function po(t, n) { // NOSONAR
    for (var e = 0; e < n.length; ++e) { // NOSONAR
      if (!ho(t, n[e])) { // NOSONAR
        return !1; // NOSONAR
      } // NOSONAR
    } return !0; // NOSONAR
  } function vo(t) { // NOSONAR
    switch (t.length) { // NOSONAR
      case 1:return _o(t[0]); case 2:return go(t[0], t[1]); case 3:return yo(t[0], t[1], t[2]); // NOSONAR
    } // NOSONAR
  } function _o(t) { // NOSONAR
    return {x: t.x, y: t.y, r: t.r}; // NOSONAR
  } function go(t, n) { // NOSONAR
    var e = t.x, r = t.y, i = t.r, o = n.x, u = n.y, a = n.r, c = o - e, s = u - r, f = a - i, l = Math.sqrt(c * c + s * s); return {x: (e + o + c / l * f) / 2, y: (r + u + s / l * f) / 2, r: (l + i + a) / 2}; // NOSONAR
  } function yo(t, n, e) { // NOSONAR
    var r = t.x, i = t.y, o = t.r, u = n.x, a = n.y, c = n.r, s = e.x, f = e.y, l = e.r, h = r - u, p = r - s, d = i - a, v = i - f, _ = c - o, g = l - o, y = r * r + i * i - o * o, m = y - u * u - a * a + c * c, x = y - s * s - f * f + l * l, b = p * d - h * v, w = (d * x - v * m) / (2 * b) - r, M = (v * _ - d * g) / b, T = (p * m - h * x) / (2 * b) - i, N = (h * g - p * _) / b, k = M * M + N * N - 1, S = 2 * (o + w * M + T * N), E = w * w + T * T - o * o, A = -(k ? (S + Math.sqrt(S * S - 4 * k * E)) / (2 * k) : E / S); return {x: r + w + M * A, y: i + T + N * A, r: A}; // NOSONAR
  } function mo(t, n, e) { // NOSONAR
    var r = t.x, i = t.y, o = n.r + e.r, u = t.r + e.r, a = n.x - r, c = n.y - i, s = a * a + c * c; if (s) { // NOSONAR
      var f = .5 + ((u *= u) - (o *= o)) / (2 * s), l = Math.sqrt(Math.max(0, 2 * o * (u + s) - (u -= s) * u - o * o)) / (2 * s); e.x = r + f * a + l * c, e.y = i + f * c - l * a; // NOSONAR
    } else { // NOSONAR
      e.x = r + u, e.y = i; // NOSONAR
    } // NOSONAR
  } function xo(t, n) { // NOSONAR
    var e = n.x - t.x, r = n.y - t.y, i = t.r + n.r; return i * i - 1e-6 > e * e + r * r; // NOSONAR
  } function bo(t) { // NOSONAR
    var n = t._, e = t.next._, r = n.r + e.r, i = (n.x * e.r + e.x * n.r) / r, o = (n.y * e.r + e.y * n.r) / r; return i * i + o * o; // NOSONAR
  } function wo(t) { // NOSONAR
    this._ = t, this.next = null, this.previous = null; // NOSONAR
  } function Mo(t) { // NOSONAR
    if (!(i = t.length)) { // NOSONAR
      return 0; // NOSONAR
    } var n, e, r, i, o, u, a, c, s, f, l; if (n = t[0], n.x = 0, n.y = 0, !(i > 1)) { // NOSONAR
      return n.r; // NOSONAR
    } if (e = t[1], n.x = -e.r, e.x = n.r, e.y = 0, !(i > 2)) { // NOSONAR
      return n.r + e.r; // NOSONAR
    } mo(e, n, r = t[2]), n = new wo(n), e = new wo(e), r = new wo(r), n.next = r.previous = e, e.next = n.previous = r, r.next = e.previous = n; t:for (a = 3; a < i; ++a) { // NOSONAR
      mo(n._, e._, r = t[a]), r = new wo(r), c = e.next, s = n.previous, f = e._.r, l = n._.r; do { // NOSONAR
        if (f <= l) { // NOSONAR
          if (xo(c._, r._)) { // NOSONAR
            e = c, n.next = e, e.previous = n, --a; continue t; // NOSONAR
          }f += c._.r, c = c.next; // NOSONAR
        } else { // NOSONAR
          if (xo(s._, r._)) { // NOSONAR
            (n = s).next = e, e.previous = n, --a; continue t; // NOSONAR
          }l += s._.r, s = s.previous; // NOSONAR
        } // NOSONAR
      } while (c !== s.next);for (r.previous = n, r.next = e, n.next = e.previous = e = r, o = bo(n); (r = r.next) !== e;) { // NOSONAR
        (u = bo(r)) < o && (n = r, o = u); // NOSONAR
      }e = n.next; // NOSONAR
    } for (n = [ e._ ], r = e; (r = r.next) !== e;) { // NOSONAR
      n.push(r._); // NOSONAR
    } for (r = Jv(n), a = 0; a < i; ++a) { // NOSONAR
      n = t[a], n.x -= r.x, n.y -= r.y; // NOSONAR
    } return r.r; // NOSONAR
  } function To(t) { // NOSONAR
    return t == null ? null : No(t); // NOSONAR
  } function No(t) { // NOSONAR
    if (typeof t !== 'function') { // NOSONAR
      throw new Error; // NOSONAR
    } return t; // NOSONAR
  } function ko() { // NOSONAR
    return 0; // NOSONAR
  } function So(t) { // NOSONAR
    return Math.sqrt(t.value); // NOSONAR
  } function Eo(t) { // NOSONAR
    return function(n) { // NOSONAR
      n.children || (n.r = Math.max(0, +t(n) || 0)); // NOSONAR
    }; // NOSONAR
  } function Ao(t, n) { // NOSONAR
    return function(e) { // NOSONAR
      if (r = e.children) { // NOSONAR
        var r, i, o, u = r.length, a = t(e) * n || 0; if (a) { // NOSONAR
          for (i = 0; i < u; ++i) { // NOSONAR
            r[i].r += a; // NOSONAR
          } // NOSONAR
        } if (o = Mo(r), a) { // NOSONAR
          for (i = 0; i < u; ++i) { // NOSONAR
            r[i].r -= a; // NOSONAR
          } // NOSONAR
        }e.r = o + a; // NOSONAR
      } // NOSONAR
    }; // NOSONAR
  } function Co(t) { // NOSONAR
    return function(n) { // NOSONAR
      var e = n.parent; n.r *= t, e && (n.x = e.x + t * n.x, n.y = e.y + t * n.y); // NOSONAR
    }; // NOSONAR
  } function zo(t) { // NOSONAR
    return t.id; // NOSONAR
  } function Po(t) { // NOSONAR
    return t.parentId; // NOSONAR
  } function Ro(t, n) { // NOSONAR
    return t.parent === n.parent ? 1 : 2; // NOSONAR
  } function Lo(t) { // NOSONAR
    var n = t.children; return n ? n[0] : t.t; // NOSONAR
  } function qo(t) { // NOSONAR
    var n = t.children; return n ? n[n.length - 1] : t.t; // NOSONAR
  } function Uo(t, n, e) { // NOSONAR
    var r = e / (n.i - t.i); n.c -= r, n.s += e, t.c += r, n.z += e, n.m += e; // NOSONAR
  } function Do(t) { // NOSONAR
    for (var n, e = 0, r = 0, i = t.children, o = i.length; --o >= 0;) { // NOSONAR
      (n = i[o]).z += e, n.m += e, e += n.s + (r += n.c); // NOSONAR
    } // NOSONAR
  } function Oo(t, n, e) { // NOSONAR
    return t.a.parent === n.parent ? t.a : e; // NOSONAR
  } function Fo(t, n) { // NOSONAR
    this._ = t, this.parent = null, this.children = null, this.A = null, this.a = this, this.z = 0, this.m = 0, this.c = 0, this.s = 0, this.t = null, this.i = n; // NOSONAR
  } function Io(t) { // NOSONAR
    for (var n, e, r, i, o, u = new Fo(t, 0), a = [ u ]; n = a.pop();) { // NOSONAR
      if (r = n._.children) { // NOSONAR
        for (n.children = new Array(o = r.length), i = o - 1; i >= 0; --i) { // NOSONAR
          a.push(e = n.children[i] = new Fo(r[i], i)), e.parent = n; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return (u.parent = new Fo(null, 0)).children = [ u ], u; // NOSONAR
  } function Yo(t, n, e, r, i, o) { // NOSONAR
    for (var u, a, c, s, f, l, h, p, d, v, _, g = [], y = n.children, m = 0, x = 0, b = y.length, w = n.value; m < b;) { // NOSONAR
      c = i - e, s = o - r; do { // NOSONAR
        f = y[x++].value; // NOSONAR
      } while (!f && x < b);for (l = h = f, _ = f * f * (v = Math.max(s / c, c / s) / (w * t)), d = Math.max(h / _, _ / l); x < b; ++x) { // NOSONAR
        if (f += a = y[x].value, a < l && (l = a), a > h && (h = a), _ = f * f * v, (p = Math.max(h / _, _ / l)) > d) { // NOSONAR
          f -= a; break; // NOSONAR
        }d = p; // NOSONAR
      }g.push(u = {value: f, dice: c < s, children: y.slice(m, x)}), u.dice ? t_(u, e, r, i, w ? r += s * f / w : o) : i_(u, e, r, w ? e += c * f / w : i, o), w -= f, m = x; // NOSONAR
    } return g; // NOSONAR
  } function Bo(t, n) { // NOSONAR
    return t[0] - n[0] || t[1] - n[1]; // NOSONAR
  } function jo(t) { // NOSONAR
    for (var n = t.length, e = [0, 1], r = 2, i = 2; i < n; ++i) { // NOSONAR
      for (;r > 1 && c_(t[e[r - 2]], t[e[r - 1]], t[i]) <= 0;) { // NOSONAR
        --r; // NOSONAR
      }e[r++] = i; // NOSONAR
    } return e.slice(0, r); // NOSONAR
  } function Ho(t) { // NOSONAR
    this._size = t, this._call = this._error = null, this._tasks = [], this._data = [], this._waiting = this._active = this._ended = this._start = 0; // NOSONAR
  } function Xo(t) { // NOSONAR
    if (!t._start) { // NOSONAR
      try { // NOSONAR
        $o(t); // NOSONAR
      } catch (n) { // NOSONAR
        if (t._tasks[t._ended + t._active - 1]) { // NOSONAR
          Wo(t, n); // NOSONAR
        } else if (!t._data) { // NOSONAR
          throw n; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function $o(t) { // NOSONAR
    for (;t._start = t._waiting && t._active < t._size;) { // NOSONAR
      var n = t._ended + t._active, e = t._tasks[n], r = e.length - 1, i = e[r]; e[r] = Vo(t, n), --t._waiting, ++t._active, e = i.apply(null, e), t._tasks[n] && (t._tasks[n] = e || f_); // NOSONAR
    } // NOSONAR
  } function Vo(t, n) { // NOSONAR
    return function(e, r) { // NOSONAR
      t._tasks[n] && (--t._active, ++t._ended, t._tasks[n] = null, t._error == null && (e != null ? Wo(t, e) : (t._data[n] = r, t._waiting ? Xo(t) : Zo(t)))); // NOSONAR
    }; // NOSONAR
  } function Wo(t, n) { // NOSONAR
    var e, r = t._tasks.length; for (t._error = n, t._data = void 0, t._waiting = NaN; --r >= 0;) { // NOSONAR
      if ((e = t._tasks[r]) && (t._tasks[r] = null, e.abort)) { // NOSONAR
        try { // NOSONAR
          e.abort(); // NOSONAR
        } catch (n) {} // NOSONAR
      } // NOSONAR
    }t._active = NaN, Zo(t); // NOSONAR
  } function Zo(t) { // NOSONAR
    if (!t._active && t._call) { // NOSONAR
      var n = t._data; t._data = void 0, t._call(t._error, n); // NOSONAR
    } // NOSONAR
  } function Go(t) { // NOSONAR
    if (t == null) { // NOSONAR
      t = 1 / 0; // NOSONAR
    } else if (!((t = +t) >= 1)) { // NOSONAR
      throw new Error('invalid concurrency'); // NOSONAR
    } return new Ho(t); // NOSONAR
  } function Jo(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      t(n == null ? e : null); // NOSONAR
    }; // NOSONAR
  } function Qo(t) { // NOSONAR
    var n = t.responseType; return n && n !== 'text' ? t.response : t.responseText; // NOSONAR
  } function Ko(t, n) { // NOSONAR
    return function(e) { // NOSONAR
      return t(e.responseText, n); // NOSONAR
    }; // NOSONAR
  } function tu(t) { // NOSONAR
    function n(n) { // NOSONAR
      var o = n + '', u = e.get(o); if (!u) { // NOSONAR
        if (i !== C_) { // NOSONAR
          return i; // NOSONAR
        } e.set(o, u = r.push(n)); // NOSONAR
      } return t[(u - 1) % t.length]; // NOSONAR
    } var e = we(), r = [], i = C_; return t = t == null ? [] : A_.call(t), n.domain = function(t) { // NOSONAR
      if (!arguments.length) { // NOSONAR
        return r.slice(); // NOSONAR
      } r = [], e = we(); for (var i, o, u = -1, a = t.length; ++u < a;) { // NOSONAR
        e.has(o = (i = t[u]) + '') || e.set(o, r.push(i)); // NOSONAR
      } return n; // NOSONAR
    }, n.range = function(e) { // NOSONAR
      return arguments.length ? (t = A_.call(e), n) : t.slice(); // NOSONAR
    }, n.unknown = function(t) { // NOSONAR
      return arguments.length ? (i = t, n) : i; // NOSONAR
    }, n.copy = function() { // NOSONAR
      return tu().domain(r).range(t).unknown(i); // NOSONAR
    }, n; // NOSONAR
  } function nu() { // NOSONAR
    function t() { // NOSONAR
      var t = i().length, r = u[1] < u[0], l = u[r - 0], h = u[1 - r]; n = (h - l) / Math.max(1, t - c + 2 * s), a && (n = Math.floor(n)), l += (h - l - n * (t - c)) * f, e = n * (1 - c), a && (l = Math.round(l), e = Math.round(e)); var p = Ns(t).map(function(t) { // NOSONAR
        return l + n * t; // NOSONAR
      }); return o(r ? p.reverse() : p); // NOSONAR
    } var n, e, r = tu().unknown(void 0), i = r.domain, o = r.range, u = [0, 1], a = !1, c = 0, s = 0, f = .5; return delete r.unknown, r.domain = function(n) { // NOSONAR
      return arguments.length ? (i(n), t()) : i(); // NOSONAR
    }, r.range = function(n) { // NOSONAR
      return arguments.length ? (u = [+n[0], +n[1]], t()) : u.slice(); // NOSONAR
    }, r.rangeRound = function(n) { // NOSONAR
      return u = [+n[0], +n[1]], a = !0, t(); // NOSONAR
    }, r.bandwidth = function() { // NOSONAR
      return e; // NOSONAR
    }, r.step = function() { // NOSONAR
      return n; // NOSONAR
    }, r.round = function(n) { // NOSONAR
      return arguments.length ? (a = !!n, t()) : a; // NOSONAR
    }, r.padding = function(n) { // NOSONAR
      return arguments.length ? (c = s = Math.max(0, Math.min(1, n)), t()) : c; // NOSONAR
    }, r.paddingInner = function(n) { // NOSONAR
      return arguments.length ? (c = Math.max(0, Math.min(1, n)), t()) : c; // NOSONAR
    }, r.paddingOuter = function(n) { // NOSONAR
      return arguments.length ? (s = Math.max(0, Math.min(1, n)), t()) : s; // NOSONAR
    }, r.align = function(n) { // NOSONAR
      return arguments.length ? (f = Math.max(0, Math.min(1, n)), t()) : f; // NOSONAR
    }, r.copy = function() { // NOSONAR
      return nu().domain(i()).range(u).round(a).paddingInner(c).paddingOuter(s).align(f); // NOSONAR
    }, t(); // NOSONAR
  } function eu(t) { // NOSONAR
    var n = t.copy; return t.padding = t.paddingOuter, delete t.paddingInner, delete t.paddingOuter, t.copy = function() { // NOSONAR
      return eu(n()); // NOSONAR
    }, t; // NOSONAR
  } function ru(t, n) { // NOSONAR
    return (n -= t = +t) ? function(e) { // NOSONAR
      return (e - t) / n; // NOSONAR
    } : z_(n); // NOSONAR
  } function iu(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      var r = t(n = +n, e = +e); return function(t) { // NOSONAR
        return t <= n ? 0 : t >= e ? 1 : r(t); // NOSONAR
      }; // NOSONAR
    }; // NOSONAR
  } function ou(t) { // NOSONAR
    return function(n, e) { // NOSONAR
      var r = t(n = +n, e = +e); return function(t) { // NOSONAR
        return t <= 0 ? n : t >= 1 ? e : r(t); // NOSONAR
      }; // NOSONAR
    }; // NOSONAR
  } function uu(t, n, e, r) { // NOSONAR
    var i = t[0], o = t[1], u = n[0], a = n[1]; return o < i ? (i = e(o, i), u = r(a, u)) : (i = e(i, o), u = r(u, a)), function(t) { // NOSONAR
      return u(i(t)); // NOSONAR
    }; // NOSONAR
  } function au(t, n, e, r) { // NOSONAR
    var i = Math.min(t.length, n.length) - 1, o = new Array(i), u = new Array(i), a = -1; for (t[i] < t[0] && (t = t.slice().reverse(), n = n.slice().reverse()); ++a < i;) { // NOSONAR
      o[a] = e(t[a], t[a + 1]), u[a] = r(n[a], n[a + 1]); // NOSONAR
    } return function(n) { // NOSONAR
      var e = ds(t, n, 1, i) - 1; return u[e](o[e](n)); // NOSONAR
    }; // NOSONAR
  } function cu(t, n) { // NOSONAR
    return n.domain(t.domain()).range(t.range()).interpolate(t.interpolate()).clamp(t.clamp()); // NOSONAR
  } function su(t, n) { // NOSONAR
    function e() { // NOSONAR
      return i = Math.min(a.length, c.length) > 2 ? au : uu, o = u = null, r; // NOSONAR
    } function r(n) { // NOSONAR
      return (o || (o = i(a, c, f ? iu(t) : t, s)))(+n); // NOSONAR
    } var i, o, u, a = R_, c = R_, s = fl, f = !1; return r.invert = function(t) { // NOSONAR
      return (u || (u = i(c, a, ru, f ? ou(n) : n)))(+t); // NOSONAR
    }, r.domain = function(t) { // NOSONAR
      return arguments.length ? (a = E_.call(t, P_), e()) : a.slice(); // NOSONAR
    }, r.range = function(t) { // NOSONAR
      return arguments.length ? (c = A_.call(t), e()) : c.slice(); // NOSONAR
    }, r.rangeRound = function(t) { // NOSONAR
      return c = A_.call(t), s = ll, e(); // NOSONAR
    }, r.clamp = function(t) { // NOSONAR
      return arguments.length ? (f = !!t, e()) : f; // NOSONAR
    }, r.interpolate = function(t) { // NOSONAR
      return arguments.length ? (s = t, e()) : s; // NOSONAR
    }, e(); // NOSONAR
  } function fu(t) { // NOSONAR
    var n = t.domain; return t.ticks = function(t) { // NOSONAR
      var e = n(); return As(e[0], e[e.length - 1], t == null ? 10 : t); // NOSONAR
    }, t.tickFormat = function(t, e) { // NOSONAR
      return L_(n(), t, e); // NOSONAR
    }, t.nice = function(e) { // NOSONAR
      e == null && (e = 10); var i, o = n(), u = 0, a = o.length - 1, c = o[u], s = o[a]; return s < c && (i = c, c = s, s = i, i = u, u = a, a = i), (i = r(c, s, e)) > 0 ? i = r(c = Math.floor(c / i) * i, s = Math.ceil(s / i) * i, e) : i < 0 && (i = r(c = Math.ceil(c * i) / i, s = Math.floor(s * i) / i, e)), i > 0 ? (o[u] = Math.floor(c / i) * i, o[a] = Math.ceil(s / i) * i, n(o)) : i < 0 && (o[u] = Math.ceil(c * i) / i, o[a] = Math.floor(s * i) / i, n(o)), t; // NOSONAR
    }, t; // NOSONAR
  } function lu() { // NOSONAR
    var t = su(ru, ol); return t.copy = function() { // NOSONAR
      return cu(t, lu()); // NOSONAR
    }, fu(t); // NOSONAR
  } function hu() { // NOSONAR
    function t(t) { // NOSONAR
      return +t; // NOSONAR
    } var n = [0, 1]; return t.invert = t, t.domain = t.range = function(e) { // NOSONAR
      return arguments.length ? (n = E_.call(e, P_), t) : n.slice(); // NOSONAR
    }, t.copy = function() { // NOSONAR
      return hu().domain(n); // NOSONAR
    }, fu(t); // NOSONAR
  } function pu(t, n) { // NOSONAR
    return (n = Math.log(n / t)) ? function(e) { // NOSONAR
      return Math.log(e / t) / n; // NOSONAR
    } : z_(n); // NOSONAR
  } function du(t, n) { // NOSONAR
    return t < 0 ? function(e) { // NOSONAR
      return -Math.pow(-n, e) * Math.pow(-t, 1 - e); // NOSONAR
    } : function(e) { // NOSONAR
      return Math.pow(n, e) * Math.pow(t, 1 - e); // NOSONAR
    }; // NOSONAR
  } function vu(t) { // NOSONAR
    return isFinite(t) ? +('1e' + t) : t < 0 ? 0 : t; // NOSONAR
  } function _u(t) { // NOSONAR
    return t === 10 ? vu : t === Math.E ? Math.exp : function(n) { // NOSONAR
      return Math.pow(t, n); // NOSONAR
    }; // NOSONAR
  } function gu(t) { // NOSONAR
    return t === Math.E ? Math.log : t === 10 && Math.log10 || t === 2 && Math.log2 || (t = Math.log(t), function(n) { // NOSONAR
      return Math.log(n) / t; // NOSONAR
    }); // NOSONAR
  } function yu(t) { // NOSONAR
    return function(n) { // NOSONAR
      return -t(-n); // NOSONAR
    }; // NOSONAR
  } function mu() { // NOSONAR
    function n() { // NOSONAR
      return o = gu(i), u = _u(i), r()[0] < 0 && (o = yu(o), u = yu(u)), e; // NOSONAR
    } var e = su(pu, du).domain([1, 10]), r = e.domain, i = 10, o = gu(10), u = _u(10); return e.base = function(t) { // NOSONAR
      return arguments.length ? (i = +t, n()) : i; // NOSONAR
    }, e.domain = function(t) { // NOSONAR
      return arguments.length ? (r(t), n()) : r(); // NOSONAR
    }, e.ticks = function(t) { // NOSONAR
      var n, e = r(), a = e[0], c = e[e.length - 1]; (n = c < a) && (h = a, a = c, c = h); var s, f, l, h = o(a), p = o(c), d = t == null ? 10 : +t, v = []; if (!(i % 1) && p - h < d) { // NOSONAR
        if (h = Math.round(h) - 1, p = Math.round(p) + 1, a > 0) { // NOSONAR
          for (;h < p; ++h) { // NOSONAR
            for (f = 1, s = u(h); f < i; ++f) { // NOSONAR
              if (!((l = s * f) < a)) { // NOSONAR
                if (l > c) { // NOSONAR
                  break; // NOSONAR
                } v.push(l); // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          for (;h < p; ++h) { // NOSONAR
            for (f = i - 1, s = u(h); f >= 1; --f) { // NOSONAR
              if (!((l = s * f) < a)) { // NOSONAR
                if (l > c) { // NOSONAR
                  break; // NOSONAR
                } v.push(l); // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        v = As(h, p, Math.min(p - h, d)).map(u); // NOSONAR
      } return n ? v.reverse() : v; // NOSONAR
    }, e.tickFormat = function(n, r) { // NOSONAR
      if (r == null && (r = i === 10 ? '.0e' : ','), typeof r !== 'function' && (r = t.format(r)), n === 1 / 0) { // NOSONAR
        return r; // NOSONAR
      } n == null && (n = 10); var a = Math.max(1, i * n / e.ticks().length); return function(t) { // NOSONAR
        var n = t / u(Math.round(o(t))); return n * i < i - .5 && (n *= i), n <= a ? r(t) : ''; // NOSONAR
      }; // NOSONAR
    }, e.nice = function() { // NOSONAR
      return r(q_(r(), {floor: function(t) { // NOSONAR
        return u(Math.floor(o(t))); // NOSONAR
      }, ceil: function(t) { // NOSONAR
        return u(Math.ceil(o(t))); // NOSONAR
      }})); // NOSONAR
    }, e.copy = function() { // NOSONAR
      return cu(e, mu().base(i)); // NOSONAR
    }, e; // NOSONAR
  } function xu(t, n) { // NOSONAR
    return t < 0 ? -Math.pow(-t, n) : Math.pow(t, n); // NOSONAR
  } function bu() { // NOSONAR
    var t = 1, n = su(function(n, e) { // NOSONAR
        return (e = xu(e, t) - (n = xu(n, t))) ? function(r) { // NOSONAR
          return (xu(r, t) - n) / e; // NOSONAR
        } : z_(e); // NOSONAR
      }, function(n, e) { // NOSONAR
        return e = xu(e, t) - (n = xu(n, t)), function(r) { // NOSONAR
          return xu(n + e * r, 1 / t); // NOSONAR
        }; // NOSONAR
      }), e = n.domain; return n.exponent = function(n) { // NOSONAR
      return arguments.length ? (t = +n, e(e())) : t; // NOSONAR
    }, n.copy = function() { // NOSONAR
      return cu(n, bu().exponent(t)); // NOSONAR
    }, fu(n); // NOSONAR
  } function wu() { // NOSONAR
    function t() { // NOSONAR
      var t = 0, o = Math.max(1, r.length); for (i = new Array(o - 1); ++t < o;) { // NOSONAR
        i[t - 1] = zs(e, t / o); // NOSONAR
      } return n; // NOSONAR
    } function n(t) { // NOSONAR
      if (!isNaN(t = +t)) { // NOSONAR
        return r[ds(i, t)]; // NOSONAR
      } // NOSONAR
    } var e = [], r = [], i = []; return n.invertExtent = function(t) { // NOSONAR
      var n = r.indexOf(t); return n < 0 ? [NaN, NaN] : [n > 0 ? i[n - 1] : e[0], n < i.length ? i[n] : e[e.length - 1]]; // NOSONAR
    }, n.domain = function(n) { // NOSONAR
      if (!arguments.length) { // NOSONAR
        return e.slice(); // NOSONAR
      } e = []; for (var r, i = 0, o = n.length; i < o; ++i) { // NOSONAR
        (r = n[i]) == null || isNaN(r = +r) || e.push(r); // NOSONAR
      } return e.sort(ls), t(); // NOSONAR
    }, n.range = function(n) { // NOSONAR
      return arguments.length ? (r = A_.call(n), t()) : r.slice(); // NOSONAR
    }, n.quantiles = function() { // NOSONAR
      return i.slice(); // NOSONAR
    }, n.copy = function() { // NOSONAR
      return wu().domain(e).range(r); // NOSONAR
    }, n; // NOSONAR
  } function Mu() { // NOSONAR
    function t(t) { // NOSONAR
      if (t <= t) { // NOSONAR
        return u[ds(o, t, 0, i)]; // NOSONAR
      } // NOSONAR
    } function n() { // NOSONAR
      var n = -1; for (o = new Array(i); ++n < i;) { // NOSONAR
        o[n] = ((n + 1) * r - (n - i) * e) / (i + 1); // NOSONAR
      } return t; // NOSONAR
    } var e = 0, r = 1, i = 1, o = [ .5 ], u = [0, 1]; return t.domain = function(t) { // NOSONAR
      return arguments.length ? (e = +t[0], r = +t[1], n()) : [e, r]; // NOSONAR
    }, t.range = function(t) { // NOSONAR
      return arguments.length ? (i = (u = A_.call(t)).length - 1, n()) : u.slice(); // NOSONAR
    }, t.invertExtent = function(t) { // NOSONAR
      var n = u.indexOf(t); return n < 0 ? [NaN, NaN] : n < 1 ? [e, o[0]] : n >= i ? [o[i - 1], r] : [o[n - 1], o[n]]; // NOSONAR
    }, t.copy = function() { // NOSONAR
      return Mu().domain([e, r]).range(u); // NOSONAR
    }, fu(t); // NOSONAR
  } function Tu() { // NOSONAR
    function t(t) { // NOSONAR
      if (t <= t) { // NOSONAR
        return e[ds(n, t, 0, r)]; // NOSONAR
      } // NOSONAR
    } var n = [ .5 ], e = [0, 1], r = 1; return t.domain = function(i) { // NOSONAR
      return arguments.length ? (n = A_.call(i), r = Math.min(n.length, e.length - 1), t) : n.slice(); // NOSONAR
    }, t.range = function(i) { // NOSONAR
      return arguments.length ? (e = A_.call(i), r = Math.min(n.length, e.length - 1), t) : e.slice(); // NOSONAR
    }, t.invertExtent = function(t) { // NOSONAR
      var r = e.indexOf(t); return [n[r - 1], n[r]]; // NOSONAR
    }, t.copy = function() { // NOSONAR
      return Tu().domain(n).range(e); // NOSONAR
    }, t; // NOSONAR
  } function Nu(t, n, e, r) { // NOSONAR
    function i(n) { // NOSONAR
      return t(n = new Date(+n)), n; // NOSONAR
    } return i.floor = i, i.ceil = function(e) { // NOSONAR
      return t(e = new Date(e - 1)), n(e, 1), t(e), e; // NOSONAR
    }, i.round = function(t) { // NOSONAR
      var n = i(t), e = i.ceil(t); return t - n < e - t ? n : e; // NOSONAR
    }, i.offset = function(t, e) { // NOSONAR
      return n(t = new Date(+t), e == null ? 1 : Math.floor(e)), t; // NOSONAR
    }, i.range = function(e, r, o) { // NOSONAR
      var u = []; if (e = i.ceil(e), o = o == null ? 1 : Math.floor(o), !(e < r && o > 0)) { // NOSONAR
        return u; // NOSONAR
      } do { // NOSONAR
        u.push(new Date(+e)); // NOSONAR
      } while (n(e, o), t(e), e < r);return u; // NOSONAR
    }, i.filter = function(e) { // NOSONAR
      return Nu(function(n) { // NOSONAR
        if (n >= n) { // NOSONAR
          for (;t(n), !e(n);) { // NOSONAR
            n.setTime(n - 1); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }, function(t, r) { // NOSONAR
        if (t >= t) { // NOSONAR
          if (r < 0) { // NOSONAR
            for (;++r <= 0;) { // NOSONAR
              for (;n(t, -1), !e(t);) { // NOSONAR
 // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } else { // NOSONAR
            for (;--r >= 0;) { // NOSONAR
              for (;n(t, 1), !e(t);) { // NOSONAR
 // NOSONAR
              } // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }); // NOSONAR
    }, e && (i.count = function(n, r) { // NOSONAR
      return U_.setTime(+n), D_.setTime(+r), t(U_), t(D_), Math.floor(e(U_, D_)); // NOSONAR
    }, i.every = function(t) { // NOSONAR
        return t = Math.floor(t), isFinite(t) && t > 0 ? t > 1 ? i.filter(r ? function(n) { // NOSONAR
          return r(n) % t == 0; // NOSONAR
        } : function(n) { // NOSONAR
          return i.count(0, n) % t == 0; // NOSONAR
        }) : i : null; // NOSONAR
      }), i; // NOSONAR
  } function ku(t) { // NOSONAR
    return Nu(function(n) { // NOSONAR
      n.setDate(n.getDate() - (n.getDay() + 7 - t) % 7), n.setHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setDate(t.getDate() + 7 * n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t - (n.getTimezoneOffset() - t.getTimezoneOffset()) * I_) / Y_; // NOSONAR
    }); // NOSONAR
  } function Su(t) { // NOSONAR
    return Nu(function(n) { // NOSONAR
      n.setUTCDate(n.getUTCDate() - (n.getUTCDay() + 7 - t) % 7), n.setUTCHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setUTCDate(t.getUTCDate() + 7 * n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t) / Y_; // NOSONAR
    }); // NOSONAR
  } function Eu(t) { // NOSONAR
    if (t.y >= 0 && t.y < 100) { // NOSONAR
      var n = new Date(-1, t.m, t.d, t.H, t.M, t.S, t.L); return n.setFullYear(t.y), n; // NOSONAR
    } return new Date(t.y, t.m, t.d, t.H, t.M, t.S, t.L); // NOSONAR
  } function Au(t) { // NOSONAR
    if (t.y >= 0 && t.y < 100) { // NOSONAR
      var n = new Date(Date.UTC(-1, t.m, t.d, t.H, t.M, t.S, t.L)); return n.setUTCFullYear(t.y), n; // NOSONAR
    } return new Date(Date.UTC(t.y, t.m, t.d, t.H, t.M, t.S, t.L)); // NOSONAR
  } function Cu(t) { // NOSONAR
    return {y: t, m: 0, d: 1, H: 0, M: 0, S: 0, L: 0}; // NOSONAR
  } function zu(t) { // NOSONAR
    function n(t, n) { // NOSONAR
      return function(e) { // NOSONAR
        var r, i, o, u = [], a = -1, c = 0, s = t.length; for (e instanceof Date || (e = new Date(+e)); ++a < s;) { // NOSONAR
          t.charCodeAt(a) === 37 && (u.push(t.slice(c, a)), (i = Fg[r = t.charAt(++a)]) != null ? r = t.charAt(++a) : i = r === 'e' ? ' ' : '0', (o = n[r]) && (r = o(e, i)), u.push(r), c = a + 1); // NOSONAR
        } return u.push(t.slice(c, a)), u.join(''); // NOSONAR
      }; // NOSONAR
    } function e(t, n) { // NOSONAR
      return function(e) { // NOSONAR
        var i = Cu(1900); if (r(i, t, e += '', 0) != e.length) { // NOSONAR
          return null; // NOSONAR
        } if ('p' in i && (i.H = i.H % 12 + 12 * i.p), 'W' in i || 'U' in i) { // NOSONAR
          'w' in i || (i.w = 'W' in i ? 1 : 0); var o = 'Z' in i ? Au(Cu(i.y)).getUTCDay() : n(Cu(i.y)).getDay(); i.m = 0, i.d = 'W' in i ? (i.w + 6) % 7 + 7 * i.W - (o + 5) % 7 : i.w + 7 * i.U - (o + 6) % 7; // NOSONAR
        } return 'Z' in i ? (i.H += i.Z / 100 | 0, i.M += i.Z % 100, Au(i)) : n(i); // NOSONAR
      }; // NOSONAR
    } function r(t, n, e, r) { // NOSONAR
      for (var i, o, u = 0, a = n.length, c = e.length; u < a;) { // NOSONAR
        if (r >= c) { // NOSONAR
          return -1; // NOSONAR
        } if ((i = n.charCodeAt(u++)) === 37) { // NOSONAR
          if (i = n.charAt(u++), !(o = T[i in Fg ? n.charAt(u++) : i]) || (r = o(t, e, r)) < 0) { // NOSONAR
            return -1; // NOSONAR
          } // NOSONAR
        } else if (i != e.charCodeAt(r++)) { // NOSONAR
          return -1; // NOSONAR
        } // NOSONAR
      } return r; // NOSONAR
    } var i = t.dateTime, o = t.date, u = t.time, a = t.periods, c = t.days, s = t.shortDays, f = t.months, l = t.shortMonths, h = Lu(a), p = qu(a), d = Lu(c), v = qu(c), _ = Lu(s), g = qu(s), y = Lu(f), m = qu(f), x = Lu(l), b = qu(l), w = {a: function(t) { // NOSONAR
        return s[t.getDay()]; // NOSONAR
      }, A: function(t) { // NOSONAR
        return c[t.getDay()]; // NOSONAR
      }, b: function(t) { // NOSONAR
        return l[t.getMonth()]; // NOSONAR
      }, B: function(t) { // NOSONAR
        return f[t.getMonth()]; // NOSONAR
      }, c: null, d: Gu, e: Gu, H: Ju, I: Qu, j: Ku, L: ta, m: na, M: ea, p: function(t) { // NOSONAR
        return a[+(t.getHours() >= 12)]; // NOSONAR
      }, S: ra, U: ia, w: oa, W: ua, x: null, X: null, y: aa, Y: ca, Z: sa, '%': Ta}, M = {a: function(t) { // NOSONAR
        return s[t.getUTCDay()]; // NOSONAR
      }, A: function(t) { // NOSONAR
        return c[t.getUTCDay()]; // NOSONAR
      }, b: function(t) { // NOSONAR
        return l[t.getUTCMonth()]; // NOSONAR
      }, B: function(t) { // NOSONAR
        return f[t.getUTCMonth()]; // NOSONAR
      }, c: null, d: fa, e: fa, H: la, I: ha, j: pa, L: da, m: va, M: _a, p: function(t) { // NOSONAR
        return a[+(t.getUTCHours() >= 12)]; // NOSONAR
      }, S: ga, U: ya, w: ma, W: xa, x: null, X: null, y: ba, Y: wa, Z: Ma, '%': Ta}, T = {a: function(t, n, e) { // NOSONAR
        var r = _.exec(n.slice(e)); return r ? (t.w = g[r[0].toLowerCase()], e + r[0].length) : -1; // NOSONAR
      }, A: function(t, n, e) { // NOSONAR
        var r = d.exec(n.slice(e)); return r ? (t.w = v[r[0].toLowerCase()], e + r[0].length) : -1; // NOSONAR
      }, b: function(t, n, e) { // NOSONAR
        var r = x.exec(n.slice(e)); return r ? (t.m = b[r[0].toLowerCase()], e + r[0].length) : -1; // NOSONAR
      }, B: function(t, n, e) { // NOSONAR
        var r = y.exec(n.slice(e)); return r ? (t.m = m[r[0].toLowerCase()], e + r[0].length) : -1; // NOSONAR
      }, c: function(t, n, e) { // NOSONAR
        return r(t, i, n, e); // NOSONAR
      }, d: ju, e: ju, H: Xu, I: Xu, j: Hu, L: Wu, m: Bu, M: $u, p: function(t, n, e) { // NOSONAR
        var r = h.exec(n.slice(e)); return r ? (t.p = p[r[0].toLowerCase()], e + r[0].length) : -1; // NOSONAR
      }, S: Vu, U: Du, w: Uu, W: Ou, x: function(t, n, e) { // NOSONAR
        return r(t, o, n, e); // NOSONAR
      }, X: function(t, n, e) { // NOSONAR
        return r(t, u, n, e); // NOSONAR
      }, y: Iu, Y: Fu, Z: Yu, '%': Zu}; return w.x = n(o, w), w.X = n(u, w), w.c = n(i, w), M.x = n(o, M), M.X = n(u, M), M.c = n(i, M), {format: function(t) { // NOSONAR
      var e = n(t += '', w); return e.toString = function() { // NOSONAR
        return t; // NOSONAR
      }, e; // NOSONAR
    }, parse: function(t) { // NOSONAR
      var n = e(t += '', Eu); return n.toString = function() { // NOSONAR
        return t; // NOSONAR
      }, n; // NOSONAR
    }, utcFormat: function(t) { // NOSONAR
      var e = n(t += '', M); return e.toString = function() { // NOSONAR
        return t; // NOSONAR
      }, e; // NOSONAR
    }, utcParse: function(t) { // NOSONAR
      var n = e(t, Au); return n.toString = function() { // NOSONAR
        return t; // NOSONAR
      }, n; // NOSONAR
    }}; // NOSONAR
  } function Pu(t, n, e) { // NOSONAR
    var r = t < 0 ? '-' : '', i = (r ? -t : t) + '', o = i.length; return r + (o < e ? new Array(e - o + 1).join(n) + i : i); // NOSONAR
  } function Ru(t) { // NOSONAR
    return t.replace(Bg, '\\$&'); // NOSONAR
  } function Lu(t) { // NOSONAR
    return new RegExp('^(?:' + t.map(Ru).join('|') + ')', 'i'); // NOSONAR
  } function qu(t) { // NOSONAR
    for (var n = {}, e = -1, r = t.length; ++e < r;) { // NOSONAR
      n[t[e].toLowerCase()] = e; // NOSONAR
    } return n; // NOSONAR
  } function Uu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 1)); return r ? (t.w = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Du(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e)); return r ? (t.U = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Ou(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e)); return r ? (t.W = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Fu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 4)); return r ? (t.y = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Iu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 2)); return r ? (t.y = +r[0] + (+r[0] > 68 ? 1900 : 2e3), e + r[0].length) : -1; // NOSONAR
  } function Yu(t, n, e) { // NOSONAR
    var r = /^(Z)|([+-]\d\d)(?:\:?(\d\d))?/.exec(n.slice(e, e + 6)); return r ? (t.Z = r[1] ? 0 : -(r[2] + (r[3] || '00')), e + r[0].length) : -1; // NOSONAR
  } function Bu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 2)); return r ? (t.m = r[0] - 1, e + r[0].length) : -1; // NOSONAR
  } function ju(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 2)); return r ? (t.d = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Hu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 3)); return r ? (t.m = 0, t.d = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Xu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 2)); return r ? (t.H = +r[0], e + r[0].length) : -1; // NOSONAR
  } function $u(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 2)); return r ? (t.M = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Vu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 2)); return r ? (t.S = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Wu(t, n, e) { // NOSONAR
    var r = Ig.exec(n.slice(e, e + 3)); return r ? (t.L = +r[0], e + r[0].length) : -1; // NOSONAR
  } function Zu(t, n, e) { // NOSONAR
    var r = Yg.exec(n.slice(e, e + 1)); return r ? e + r[0].length : -1; // NOSONAR
  } function Gu(t, n) { // NOSONAR
    return Pu(t.getDate(), n, 2); // NOSONAR
  } function Ju(t, n) { // NOSONAR
    return Pu(t.getHours(), n, 2); // NOSONAR
  } function Qu(t, n) { // NOSONAR
    return Pu(t.getHours() % 12 || 12, n, 2); // NOSONAR
  } function Ku(t, n) { // NOSONAR
    return Pu(1 + W_.count(hg(t), t), n, 3); // NOSONAR
  } function ta(t, n) { // NOSONAR
    return Pu(t.getMilliseconds(), n, 3); // NOSONAR
  } function na(t, n) { // NOSONAR
    return Pu(t.getMonth() + 1, n, 2); // NOSONAR
  } function ea(t, n) { // NOSONAR
    return Pu(t.getMinutes(), n, 2); // NOSONAR
  } function ra(t, n) { // NOSONAR
    return Pu(t.getSeconds(), n, 2); // NOSONAR
  } function ia(t, n) { // NOSONAR
    return Pu(G_.count(hg(t), t), n, 2); // NOSONAR
  } function oa(t) { // NOSONAR
    return t.getDay(); // NOSONAR
  } function ua(t, n) { // NOSONAR
    return Pu(J_.count(hg(t), t), n, 2); // NOSONAR
  } function aa(t, n) { // NOSONAR
    return Pu(t.getFullYear() % 100, n, 2); // NOSONAR
  } function ca(t, n) { // NOSONAR
    return Pu(t.getFullYear() % 1e4, n, 4); // NOSONAR
  } function sa(t) { // NOSONAR
    var n = t.getTimezoneOffset(); return (n > 0 ? '-' : (n *= -1, '+')) + Pu(n / 60 | 0, '0', 2) + Pu(n % 60, '0', 2); // NOSONAR
  } function fa(t, n) { // NOSONAR
    return Pu(t.getUTCDate(), n, 2); // NOSONAR
  } function la(t, n) { // NOSONAR
    return Pu(t.getUTCHours(), n, 2); // NOSONAR
  } function ha(t, n) { // NOSONAR
    return Pu(t.getUTCHours() % 12 || 12, n, 2); // NOSONAR
  } function pa(t, n) { // NOSONAR
    return Pu(1 + yg.count(Ug(t), t), n, 3); // NOSONAR
  } function da(t, n) { // NOSONAR
    return Pu(t.getUTCMilliseconds(), n, 3); // NOSONAR
  } function va(t, n) { // NOSONAR
    return Pu(t.getUTCMonth() + 1, n, 2); // NOSONAR
  } function _a(t, n) { // NOSONAR
    return Pu(t.getUTCMinutes(), n, 2); // NOSONAR
  } function ga(t, n) { // NOSONAR
    return Pu(t.getUTCSeconds(), n, 2); // NOSONAR
  } function ya(t, n) { // NOSONAR
    return Pu(xg.count(Ug(t), t), n, 2); // NOSONAR
  } function ma(t) { // NOSONAR
    return t.getUTCDay(); // NOSONAR
  } function xa(t, n) { // NOSONAR
    return Pu(bg.count(Ug(t), t), n, 2); // NOSONAR
  } function ba(t, n) { // NOSONAR
    return Pu(t.getUTCFullYear() % 100, n, 2); // NOSONAR
  } function wa(t, n) { // NOSONAR
    return Pu(t.getUTCFullYear() % 1e4, n, 4); // NOSONAR
  } function Ma() { // NOSONAR
    return '+0000'; // NOSONAR
  } function Ta() { // NOSONAR
    return '%'; // NOSONAR
  } function Na(n) { // NOSONAR
    return Dg = zu(n), t.timeFormat = Dg.format, t.timeParse = Dg.parse, t.utcFormat = Dg.utcFormat, t.utcParse = Dg.utcParse, Dg; // NOSONAR
  } function ka(t) { // NOSONAR
    return new Date(t); // NOSONAR
  } function Sa(t) { // NOSONAR
    return t instanceof Date ? +t : +new Date(+t); // NOSONAR
  } function Ea(t, n, e, r, o, u, a, c, s) { // NOSONAR
    function f(i) { // NOSONAR
      return (a(i) < i ? v : u(i) < i ? _ : o(i) < i ? g : r(i) < i ? y : n(i) < i ? e(i) < i ? m : x : t(i) < i ? b : w)(i); // NOSONAR
    } function l(n, e, r, o) { // NOSONAR
      if (n == null && (n = 10), typeof n === 'number') { // NOSONAR
        var u = Math.abs(r - e) / n, a = hs(function(t) { // NOSONAR
          return t[2]; // NOSONAR
        }).right(M, u); a === M.length ? (o = i(e / Jg, r / Jg, n), n = t) : a ? (o = (a = M[u / M[a - 1][2] < M[a][2] / u ? a - 1 : a])[1], n = a[0]) : (o = i(e, r, n), n = c); // NOSONAR
      } return o == null ? n : n.every(o); // NOSONAR
    } var h = su(ru, ol), p = h.invert, d = h.domain, v = s('.%L'), _ = s(':%S'), g = s('%I:%M'), y = s('%I %p'), m = s('%a %d'), x = s('%b %d'), b = s('%B'), w = s('%Y'), M = [[a, 1, Xg], [a, 5, 5 * Xg], [a, 15, 15 * Xg], [a, 30, 30 * Xg], [u, 1, $g], [u, 5, 5 * $g], [u, 15, 15 * $g], [u, 30, 30 * $g], [o, 1, Vg], [o, 3, 3 * Vg], [o, 6, 6 * Vg], [o, 12, 12 * Vg], [r, 1, Wg], [r, 2, 2 * Wg], [e, 1, Zg], [n, 1, Gg], [n, 3, 3 * Gg], [t, 1, Jg]]; return h.invert = function(t) { // NOSONAR
      return new Date(p(t)); // NOSONAR
    }, h.domain = function(t) { // NOSONAR
      return arguments.length ? d(E_.call(t, Sa)) : d().map(ka); // NOSONAR
    }, h.ticks = function(t, n) { // NOSONAR
      var e, r = d(), i = r[0], o = r[r.length - 1], u = o < i; return u && (e = i, i = o, o = e), e = l(t, i, o, n), e = e ? e.range(i, o + 1) : [], u ? e.reverse() : e; // NOSONAR
    }, h.tickFormat = function(t, n) { // NOSONAR
      return n == null ? f : s(n); // NOSONAR
    }, h.nice = function(t, n) { // NOSONAR
      var e = d(); return (t = l(t, e[0], e[e.length - 1], n)) ? d(q_(e, t)) : h; // NOSONAR
    }, h.copy = function() { // NOSONAR
      return cu(h, Ea(t, n, e, r, o, u, a, c, s)); // NOSONAR
    }, h; // NOSONAR
  } function Aa(t) { // NOSONAR
    var n = t.length; return function(e) { // NOSONAR
      return t[Math.max(0, Math.min(n - 1, Math.floor(e * n)))]; // NOSONAR
    }; // NOSONAR
  } function Ca(t) { // NOSONAR
    function n(n) { // NOSONAR
      var o = (n - e) / (r - e); return t(i ? Math.max(0, Math.min(1, o)) : o); // NOSONAR
    } var e = 0, r = 1, i = !1; return n.domain = function(t) { // NOSONAR
      return arguments.length ? (e = +t[0], r = +t[1], n) : [e, r]; // NOSONAR
    }, n.clamp = function(t) { // NOSONAR
      return arguments.length ? (i = !!t, n) : i; // NOSONAR
    }, n.interpolator = function(e) { // NOSONAR
      return arguments.length ? (t = e, n) : t; // NOSONAR
    }, n.copy = function() { // NOSONAR
      return Ca(t).domain([e, r]).clamp(i); // NOSONAR
    }, fu(n); // NOSONAR
  } function za(t) { // NOSONAR
    return t > 1 ? 0 : t < -1 ? xy : Math.acos(t); // NOSONAR
  } function Pa(t) { // NOSONAR
    return t >= 1 ? by : t <= -1 ? -by : Math.asin(t); // NOSONAR
  } function Ra(t) { // NOSONAR
    return t.innerRadius; // NOSONAR
  } function La(t) { // NOSONAR
    return t.outerRadius; // NOSONAR
  } function qa(t) { // NOSONAR
    return t.startAngle; // NOSONAR
  } function Ua(t) { // NOSONAR
    return t.endAngle; // NOSONAR
  } function Da(t) { // NOSONAR
    return t && t.padAngle; // NOSONAR
  } function Oa(t, n, e, r, i, o, u, a) { // NOSONAR
    var c = e - t, s = r - n, f = u - i, l = a - o, h = (f * (n - o) - l * (t - i)) / (l * c - f * s); return [t + h * c, n + h * s]; // NOSONAR
  } function Fa(t, n, e, r, i, o, u) { // NOSONAR
    var a = t - e, c = n - r, s = (u ? o : -o) / yy(a * a + c * c), f = s * c, l = -s * a, h = t + f, p = n + l, d = e + f, v = r + l, _ = (h + d) / 2, g = (p + v) / 2, y = d - h, m = v - p, x = y * y + m * m, b = i - o, w = h * v - d * p, M = (m < 0 ? -1 : 1) * yy(vy(0, b * b * x - w * w)), T = (w * m - y * M) / x, N = (-w * y - m * M) / x, k = (w * m + y * M) / x, S = (-w * y + m * M) / x, E = T - _, A = N - g, C = k - _, z = S - g; return E * E + A * A > C * C + z * z && (T = k, N = S), {cx: T, cy: N, x01: -f, y01: -l, x11: T * (i / b - 1), y11: N * (i / b - 1)}; // NOSONAR
  } function Ia(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function Ya(t) { // NOSONAR
    return t[0]; // NOSONAR
  } function Ba(t) { // NOSONAR
    return t[1]; // NOSONAR
  } function ja(t) { // NOSONAR
    this._curve = t; // NOSONAR
  } function Ha(t) { // NOSONAR
    function n(n) { // NOSONAR
      return new ja(t(n)); // NOSONAR
    } return n._curve = t, n; // NOSONAR
  } function Xa(t) { // NOSONAR
    var n = t.curve; return t.angle = t.x, delete t.x, t.radius = t.y, delete t.y, t.curve = function(t) { // NOSONAR
      return arguments.length ? n(Ha(t)) : n()._curve; // NOSONAR
    }, t; // NOSONAR
  } function $a(t) { // NOSONAR
    return t.source; // NOSONAR
  } function Va(t) { // NOSONAR
    return t.target; // NOSONAR
  } function Wa(t) { // NOSONAR
    function n() { // NOSONAR
      var n, a = Py.call(arguments), c = e.apply(this, a), s = r.apply(this, a); if (u || (u = n = ve()), t(u, +i.apply(this, (a[0] = c, a)), +o.apply(this, a), +i.apply(this, (a[0] = s, a)), +o.apply(this, a)), n) { // NOSONAR
        return u = null, n + '' || null; // NOSONAR
      } // NOSONAR
    } var e = $a, r = Va, i = Ya, o = Ba, u = null; return n.source = function(t) { // NOSONAR
      return arguments.length ? (e = t, n) : e; // NOSONAR
    }, n.target = function(t) { // NOSONAR
      return arguments.length ? (r = t, n) : r; // NOSONAR
    }, n.x = function(t) { // NOSONAR
      return arguments.length ? (i = typeof t === 'function' ? t : ly(+t), n) : i; // NOSONAR
    }, n.y = function(t) { // NOSONAR
      return arguments.length ? (o = typeof t === 'function' ? t : ly(+t), n) : o; // NOSONAR
    }, n.context = function(t) { // NOSONAR
      return arguments.length ? (u = t == null ? null : t, n) : u; // NOSONAR
    }, n; // NOSONAR
  } function Za(t, n, e, r, i) { // NOSONAR
    t.moveTo(n, e), t.bezierCurveTo(n = (n + r) / 2, e, n, i, r, i); // NOSONAR
  } function Ga(t, n, e, r, i) { // NOSONAR
    t.moveTo(n, e), t.bezierCurveTo(n, e = (e + i) / 2, r, e, r, i); // NOSONAR
  } function Ja(t, n, e, r, i) { // NOSONAR
    var o = zy(n, e), u = zy(n, e = (e + i) / 2), a = zy(r, e), c = zy(r, i); t.moveTo(o[0], o[1]), t.bezierCurveTo(u[0], u[1], a[0], a[1], c[0], c[1]); // NOSONAR
  } function Qa(t, n, e) { // NOSONAR
    t._context.bezierCurveTo((2 * t._x0 + t._x1) / 3, (2 * t._y0 + t._y1) / 3, (t._x0 + 2 * t._x1) / 3, (t._y0 + 2 * t._y1) / 3, (t._x0 + 4 * t._x1 + n) / 6, (t._y0 + 4 * t._y1 + e) / 6); // NOSONAR
  } function Ka(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function tc(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function nc(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function ec(t, n) { // NOSONAR
    this._basis = new Ka(t), this._beta = n; // NOSONAR
  } function rc(t, n, e) { // NOSONAR
    t._context.bezierCurveTo(t._x1 + t._k * (t._x2 - t._x0), t._y1 + t._k * (t._y2 - t._y0), t._x2 + t._k * (t._x1 - n), t._y2 + t._k * (t._y1 - e), t._x2, t._y2); // NOSONAR
  } function ic(t, n) { // NOSONAR
    this._context = t, this._k = (1 - n) / 6; // NOSONAR
  } function oc(t, n) { // NOSONAR
    this._context = t, this._k = (1 - n) / 6; // NOSONAR
  } function uc(t, n) { // NOSONAR
    this._context = t, this._k = (1 - n) / 6; // NOSONAR
  } function ac(t, n, e) { // NOSONAR
    var r = t._x1, i = t._y1, o = t._x2, u = t._y2; if (t._l01_a > my) { // NOSONAR
      var a = 2 * t._l01_2a + 3 * t._l01_a * t._l12_a + t._l12_2a, c = 3 * t._l01_a * (t._l01_a + t._l12_a); r = (r * a - t._x0 * t._l12_2a + t._x2 * t._l01_2a) / c, i = (i * a - t._y0 * t._l12_2a + t._y2 * t._l01_2a) / c; // NOSONAR
    } if (t._l23_a > my) { // NOSONAR
      var s = 2 * t._l23_2a + 3 * t._l23_a * t._l12_a + t._l12_2a, f = 3 * t._l23_a * (t._l23_a + t._l12_a); o = (o * s + t._x1 * t._l23_2a - n * t._l12_2a) / f, u = (u * s + t._y1 * t._l23_2a - e * t._l12_2a) / f; // NOSONAR
    }t._context.bezierCurveTo(r, i, o, u, t._x2, t._y2); // NOSONAR
  } function cc(t, n) { // NOSONAR
    this._context = t, this._alpha = n; // NOSONAR
  } function sc(t, n) { // NOSONAR
    this._context = t, this._alpha = n; // NOSONAR
  } function fc(t, n) { // NOSONAR
    this._context = t, this._alpha = n; // NOSONAR
  } function lc(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function hc(t) { // NOSONAR
    return t < 0 ? -1 : 1; // NOSONAR
  } function pc(t, n, e) { // NOSONAR
    var r = t._x1 - t._x0, i = n - t._x1, o = (t._y1 - t._y0) / (r || i < 0 && -0), u = (e - t._y1) / (i || r < 0 && -0), a = (o * i + u * r) / (r + i); return (hc(o) + hc(u)) * Math.min(Math.abs(o), Math.abs(u), .5 * Math.abs(a)) || 0; // NOSONAR
  } function dc(t, n) { // NOSONAR
    var e = t._x1 - t._x0; return e ? (3 * (t._y1 - t._y0) / e - n) / 2 : n; // NOSONAR
  } function vc(t, n, e) { // NOSONAR
    var r = t._x0, i = t._y0, o = t._x1, u = t._y1, a = (o - r) / 3; t._context.bezierCurveTo(r + a, i + a * n, o - a, u - a * e, o, u); // NOSONAR
  } function _c(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function gc(t) { // NOSONAR
    this._context = new yc(t); // NOSONAR
  } function yc(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function mc(t) { // NOSONAR
    this._context = t; // NOSONAR
  } function xc(t) { // NOSONAR
    var n, e, r = t.length - 1, i = new Array(r), o = new Array(r), u = new Array(r); for (i[0] = 0, o[0] = 2, u[0] = t[0] + 2 * t[1], n = 1; n < r - 1; ++n) { // NOSONAR
      i[n] = 1, o[n] = 4, u[n] = 4 * t[n] + 2 * t[n + 1]; // NOSONAR
    } for (i[r - 1] = 2, o[r - 1] = 7, u[r - 1] = 8 * t[r - 1] + t[r], n = 1; n < r; ++n) { // NOSONAR
      e = i[n] / o[n - 1], o[n] -= e, u[n] -= e * u[n - 1]; // NOSONAR
    } for (i[r - 1] = u[r - 1] / o[r - 1], n = r - 2; n >= 0; --n) { // NOSONAR
      i[n] = (u[n] - i[n + 1]) / o[n]; // NOSONAR
    } for (o[r - 1] = (t[r] + i[r - 1]) / 2, n = 0; n < r - 1; ++n) { // NOSONAR
      o[n] = 2 * t[n + 1] - i[n + 1]; // NOSONAR
    } return [i, o]; // NOSONAR
  } function bc(t, n) { // NOSONAR
    this._context = t, this._t = n; // NOSONAR
  } function wc(t, n) { // NOSONAR
    return t[n]; // NOSONAR
  } function Mc(t) { // NOSONAR
    for (var n, e = 0, r = -1, i = t.length; ++r < i;) { // NOSONAR
      (n = +t[r][1]) && (e += n); // NOSONAR
    } return e; // NOSONAR
  } function Tc(t) { // NOSONAR
    return t[0]; // NOSONAR
  } function Nc(t) { // NOSONAR
    return t[1]; // NOSONAR
  } function kc() { // NOSONAR
    this._ = null; // NOSONAR
  } function Sc(t) { // NOSONAR
    t.U = t.C = t.L = t.R = t.P = t.N = null; // NOSONAR
  } function Ec(t, n) { // NOSONAR
    var e = n, r = n.R, i = e.U; i ? i.L === e ? i.L = r : i.R = r : t._ = r, r.U = i, e.U = r, e.R = r.L, e.R && (e.R.U = e), r.L = e; // NOSONAR
  } function Ac(t, n) { // NOSONAR
    var e = n, r = n.L, i = e.U; i ? i.L === e ? i.L = r : i.R = r : t._ = r, r.U = i, e.U = r, e.L = r.R, e.L && (e.L.U = e), r.R = e; // NOSONAR
  } function Cc(t) { // NOSONAR
    for (;t.L;) { // NOSONAR
      t = t.L; // NOSONAR
    } return t; // NOSONAR
  } function zc(t, n, e, r) { // NOSONAR
    var i = [null, null], o = pm.push(i) - 1; return i.left = t, i.right = n, e && Rc(i, t, n, e), r && Rc(i, n, t, r), lm[t.index].halfedges.push(o), lm[n.index].halfedges.push(o), i; // NOSONAR
  } function Pc(t, n, e) { // NOSONAR
    var r = [n, e]; return r.left = t, r; // NOSONAR
  } function Rc(t, n, e, r) { // NOSONAR
    t[0] || t[1] ? t.left === e ? t[1] = r : t[0] = r : (t[0] = r, t.left = n, t.right = e); // NOSONAR
  } function Lc(t, n, e, r, i) { // NOSONAR
    var o, u = t[0], a = t[1], c = u[0], s = u[1], f = 0, l = 1, h = a[0] - c, p = a[1] - s; if (o = n - c, h || !(o > 0)) { // NOSONAR
      if (o /= h, h < 0) { // NOSONAR
        if (o < f) { // NOSONAR
          return; // NOSONAR
        } o < l && (l = o); // NOSONAR
      } else if (h > 0) { // NOSONAR
        if (o > l) { // NOSONAR
          return; // NOSONAR
        } o > f && (f = o); // NOSONAR
      } if (o = r - c, h || !(o < 0)) { // NOSONAR
        if (o /= h, h < 0) { // NOSONAR
          if (o > l) { // NOSONAR
            return; // NOSONAR
          } o > f && (f = o); // NOSONAR
        } else if (h > 0) { // NOSONAR
          if (o < f) { // NOSONAR
            return; // NOSONAR
          } o < l && (l = o); // NOSONAR
        } if (o = e - s, p || !(o > 0)) { // NOSONAR
          if (o /= p, p < 0) { // NOSONAR
            if (o < f) { // NOSONAR
              return; // NOSONAR
            } o < l && (l = o); // NOSONAR
          } else if (p > 0) { // NOSONAR
            if (o > l) { // NOSONAR
              return; // NOSONAR
            } o > f && (f = o); // NOSONAR
          } if (o = i - s, p || !(o < 0)) { // NOSONAR
            if (o /= p, p < 0) { // NOSONAR
              if (o > l) { // NOSONAR
                return; // NOSONAR
              } o > f && (f = o); // NOSONAR
            } else if (p > 0) { // NOSONAR
              if (o < f) { // NOSONAR
                return; // NOSONAR
              } o < l && (l = o); // NOSONAR
            } return !(f > 0 || l < 1) || (f > 0 && (t[0] = [c + f * h, s + f * p]), l < 1 && (t[1] = [c + l * h, s + l * p]), !0); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function qc(t, n, e, r, i) { // NOSONAR
    var o = t[1]; if (o) { // NOSONAR
      return !0; // NOSONAR
    } var u, a, c = t[0], s = t.left, f = t.right, l = s[0], h = s[1], p = f[0], d = f[1], v = (l + p) / 2, _ = (h + d) / 2; if (d === h) { // NOSONAR
      if (v < n || v >= r) { // NOSONAR
        return; // NOSONAR
      } if (l > p) { // NOSONAR
        if (c) { // NOSONAR
          if (c[1] >= i) { // NOSONAR
            return; // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          c = [v, e]; // NOSONAR
        }o = [v, i]; // NOSONAR
      } else { // NOSONAR
        if (c) { // NOSONAR
          if (c[1] < e) { // NOSONAR
            return; // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          c = [v, i]; // NOSONAR
        }o = [v, e]; // NOSONAR
      } // NOSONAR
    } else if (u = (l - p) / (d - h), a = _ - u * v, u < -1 || u > 1) { // NOSONAR
      if (l > p) { // NOSONAR
        if (c) { // NOSONAR
          if (c[1] >= i) { // NOSONAR
            return; // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          c = [(e - a) / u, e]; // NOSONAR
        }o = [(i - a) / u, i]; // NOSONAR
      } else { // NOSONAR
        if (c) { // NOSONAR
          if (c[1] < e) { // NOSONAR
            return; // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          c = [(i - a) / u, i]; // NOSONAR
        }o = [(e - a) / u, e]; // NOSONAR
      } // NOSONAR
    } else if (h < d) { // NOSONAR
      if (c) { // NOSONAR
        if (c[0] >= r) { // NOSONAR
          return; // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        c = [n, u * n + a]; // NOSONAR
      }o = [r, u * r + a]; // NOSONAR
    } else { // NOSONAR
      if (c) { // NOSONAR
        if (c[0] < n) { // NOSONAR
          return; // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        c = [r, u * r + a]; // NOSONAR
      }o = [n, u * n + a]; // NOSONAR
    } return t[0] = c, t[1] = o, !0; // NOSONAR
  } function Uc(t, n, e, r) { // NOSONAR
    for (var i, o = pm.length; o--;) { // NOSONAR
      qc(i = pm[o], t, n, e, r) && Lc(i, t, n, e, r) && (Math.abs(i[0][0] - i[1][0]) > _m || Math.abs(i[0][1] - i[1][1]) > _m) || delete pm[o]; // NOSONAR
    } // NOSONAR
  } function Dc(t) { // NOSONAR
    return lm[t.index] = {site: t, halfedges: []}; // NOSONAR
  } function Oc(t, n) { // NOSONAR
    var e = t.site, r = n.left, i = n.right; return e === i && (i = r, r = e), i ? Math.atan2(i[1] - r[1], i[0] - r[0]) : (e === r ? (r = n[1], i = n[0]) : (r = n[0], i = n[1]), Math.atan2(r[0] - i[0], i[1] - r[1])); // NOSONAR
  } function Fc(t, n) { // NOSONAR
    return n[+(n.left !== t.site)]; // NOSONAR
  } function Ic(t, n) { // NOSONAR
    return n[+(n.left === t.site)]; // NOSONAR
  } function Yc() { // NOSONAR
    for (var t, n, e, r, i = 0, o = lm.length; i < o; ++i) { // NOSONAR
      if ((t = lm[i]) && (r = (n = t.halfedges).length)) { // NOSONAR
        var u = new Array(r), a = new Array(r); for (e = 0; e < r; ++e) { // NOSONAR
          u[e] = e, a[e] = Oc(t, pm[n[e]]); // NOSONAR
        } for (u.sort(function(t, n) { // NOSONAR
          return a[n] - a[t]; // NOSONAR
        }), e = 0; e < r; ++e) { // NOSONAR
          a[e] = n[u[e]]; // NOSONAR
        } for (e = 0; e < r; ++e) { // NOSONAR
          n[e] = a[e]; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function Bc(t, n, e, r) { // NOSONAR
    var i, o, u, a, c, s, f, l, h, p, d, v, _ = lm.length, g = !0; for (i = 0; i < _; ++i) { // NOSONAR
      if (o = lm[i]) { // NOSONAR
        for (u = o.site, a = (c = o.halfedges).length; a--;) { // NOSONAR
          pm[c[a]] || c.splice(a, 1); // NOSONAR
        } for (a = 0, s = c.length; a < s;) { // NOSONAR
          d = (p = Ic(o, pm[c[a]]))[0], v = p[1], l = (f = Fc(o, pm[c[++a % s]]))[0], h = f[1], (Math.abs(d - l) > _m || Math.abs(v - h) > _m) && (c.splice(a, 0, pm.push(Pc(u, p, Math.abs(d - t) < _m && r - v > _m ? [t, Math.abs(l - t) < _m ? h : r] : Math.abs(v - r) < _m && e - d > _m ? [Math.abs(h - r) < _m ? l : e, r] : Math.abs(d - e) < _m && v - n > _m ? [e, Math.abs(l - e) < _m ? h : n] : Math.abs(v - n) < _m && d - t > _m ? [Math.abs(h - n) < _m ? l : t, n] : null)) - 1), ++s); // NOSONAR
        }s && (g = !1); // NOSONAR
      } // NOSONAR
    } if (g) { // NOSONAR
      var y, m, x, b = 1 / 0; for (i = 0, g = null; i < _; ++i) { // NOSONAR
        (o = lm[i]) && (x = (y = (u = o.site)[0] - t) * y + (m = u[1] - n) * m) < b && (b = x, g = o); // NOSONAR
      } if (g) { // NOSONAR
        var w = [t, n], M = [t, r], T = [e, r], N = [e, n]; g.halfedges.push(pm.push(Pc(u = g.site, w, M)) - 1, pm.push(Pc(u, M, T)) - 1, pm.push(Pc(u, T, N)) - 1, pm.push(Pc(u, N, w)) - 1); // NOSONAR
      } // NOSONAR
    } for (i = 0; i < _; ++i) { // NOSONAR
      (o = lm[i]) && (o.halfedges.length || delete lm[i]); // NOSONAR
    } // NOSONAR
  } function jc() { // NOSONAR
    Sc(this), this.x = this.y = this.arc = this.site = this.cy = null; // NOSONAR
  } function Hc(t) { // NOSONAR
    var n = t.P, e = t.N; if (n && e) { // NOSONAR
      var r = n.site, i = t.site, o = e.site; if (r !== o) { // NOSONAR
        var u = i[0], a = i[1], c = r[0] - u, s = r[1] - a, f = o[0] - u, l = o[1] - a, h = 2 * (c * l - s * f); if (!(h >= -gm)) { // NOSONAR
          var p = c * c + s * s, d = f * f + l * l, v = (l * p - s * d) / h, _ = (c * d - f * p) / h, g = dm.pop() || new jc; g.arc = t, g.site = i, g.x = v + u, g.y = (g.cy = _ + a) + Math.sqrt(v * v + _ * _), t.circle = g; for (var y = null, m = hm._; m;) { // NOSONAR
            if (g.y < m.y || g.y === m.y && g.x <= m.x) { // NOSONAR
              if (!m.L) { // NOSONAR
                y = m.P; break; // NOSONAR
              }m = m.L; // NOSONAR
            } else { // NOSONAR
              if (!m.R) { // NOSONAR
                y = m; break; // NOSONAR
              }m = m.R; // NOSONAR
            } // NOSONAR
          }hm.insert(y, g), y || (sm = g); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function Xc(t) { // NOSONAR
    var n = t.circle; n && (n.P || (sm = n.N), hm.remove(n), dm.push(n), Sc(n), t.circle = null); // NOSONAR
  } function $c() { // NOSONAR
    Sc(this), this.edge = this.site = this.circle = null; // NOSONAR
  } function Vc(t) { // NOSONAR
    var n = vm.pop() || new $c; return n.site = t, n; // NOSONAR
  } function Wc(t) { // NOSONAR
    Xc(t), fm.remove(t), vm.push(t), Sc(t); // NOSONAR
  } function Zc(t) { // NOSONAR
    var n = t.circle, e = n.x, r = n.cy, i = [e, r], o = t.P, u = t.N, a = [ t ]; Wc(t); for (var c = o; c.circle && Math.abs(e - c.circle.x) < _m && Math.abs(r - c.circle.cy) < _m;) { // NOSONAR
      o = c.P, a.unshift(c), Wc(c), c = o; // NOSONAR
    }a.unshift(c), Xc(c); for (var s = u; s.circle && Math.abs(e - s.circle.x) < _m && Math.abs(r - s.circle.cy) < _m;) { // NOSONAR
      u = s.N, a.push(s), Wc(s), s = u; // NOSONAR
    }a.push(s), Xc(s); var f, l = a.length; for (f = 1; f < l; ++f) { // NOSONAR
      s = a[f], c = a[f - 1], Rc(s.edge, c.site, s.site, i); // NOSONAR
    }c = a[0], (s = a[l - 1]).edge = zc(c.site, s.site, null, i), Hc(c), Hc(s); // NOSONAR
  } function Gc(t) { // NOSONAR
    for (var n, e, r, i, o = t[0], u = t[1], a = fm._; a;) { // NOSONAR
      if ((r = Jc(a, u) - o) > _m) { // NOSONAR
        a = a.L; // NOSONAR
      } else { // NOSONAR
        if (!((i = o - Qc(a, u)) > _m)) { // NOSONAR
          r > -_m ? (n = a.P, e = a) : i > -_m ? (n = a, e = a.N) : n = e = a; break; // NOSONAR
        } if (!a.R) { // NOSONAR
          n = a; break; // NOSONAR
        }a = a.R; // NOSONAR
      } // NOSONAR
    }Dc(t); var c = Vc(t); if (fm.insert(n, c), n || e) { // NOSONAR
      if (n === e) { // NOSONAR
        return Xc(n), e = Vc(n.site), fm.insert(c, e), c.edge = e.edge = zc(n.site, c.site), Hc(n), void Hc(e); // NOSONAR
      } if (e) { // NOSONAR
        Xc(n), Xc(e); var s = n.site, f = s[0], l = s[1], h = t[0] - f, p = t[1] - l, d = e.site, v = d[0] - f, _ = d[1] - l, g = 2 * (h * _ - p * v), y = h * h + p * p, m = v * v + _ * _, x = [(_ * y - p * m) / g + f, (h * m - v * y) / g + l]; Rc(e.edge, s, d, x), c.edge = zc(s, t, null, x), e.edge = zc(t, d, null, x), Hc(n), Hc(e); // NOSONAR
      } else { // NOSONAR
        c.edge = zc(n.site, c.site); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  } function Jc(t, n) { // NOSONAR
    var e = t.site, r = e[0], i = e[1], o = i - n; if (!o) { // NOSONAR
      return r; // NOSONAR
    } var u = t.P; if (!u) { // NOSONAR
      return -1 / 0; // NOSONAR
    } var a = (e = u.site)[0], c = e[1], s = c - n; if (!s) { // NOSONAR
      return a; // NOSONAR
    } var f = a - r, l = 1 / o - 1 / s, h = f / s; return l ? (-h + Math.sqrt(h * h - 2 * l * (f * f / (-2 * s) - c + s / 2 + i - o / 2))) / l + r : (r + a) / 2; // NOSONAR
  } function Qc(t, n) { // NOSONAR
    var e = t.N; if (e) { // NOSONAR
      return Jc(e, n); // NOSONAR
    } var r = t.site; return r[1] === n ? r[0] : 1 / 0; // NOSONAR
  } function Kc(t, n, e) { // NOSONAR
    return (t[0] - e[0]) * (n[1] - t[1]) - (t[0] - n[0]) * (e[1] - t[1]); // NOSONAR
  } function ts(t, n) { // NOSONAR
    return n[1] - t[1] || n[0] - t[0]; // NOSONAR
  } function ns(t, n) { // NOSONAR
    var e, r, i, o = t.sort(ts).pop(); for (pm = [], lm = new Array(t.length), fm = new kc, hm = new kc; ;) { // NOSONAR
      if (i = sm, o && (!i || o[1] < i.y || o[1] === i.y && o[0] < i.x)) { // NOSONAR
        o[0] === e && o[1] === r || (Gc(o), e = o[0], r = o[1]), o = t.pop(); // NOSONAR
      } else { // NOSONAR
        if (!i) { // NOSONAR
          break; // NOSONAR
        } Zc(i.arc); // NOSONAR
      } // NOSONAR
    } if (Yc(), n) { // NOSONAR
      var u = +n[0][0], a = +n[0][1], c = +n[1][0], s = +n[1][1]; Uc(u, a, c, s), Bc(u, a, c, s); // NOSONAR
    } this.edges = pm, this.cells = lm, fm = hm = pm = lm = null; // NOSONAR
  } function es(t, n, e) { // NOSONAR
    this.target = t, this.type = n, this.transform = e; // NOSONAR
  } function rs(t, n, e) { // NOSONAR
    this.k = t, this.x = n, this.y = e; // NOSONAR
  } function is(t) { // NOSONAR
    return t.__zoom || mm; // NOSONAR
  } function os() { // NOSONAR
    t.event.stopImmediatePropagation(); // NOSONAR
  } function us() { // NOSONAR
    return !t.event.button; // NOSONAR
  } function as() { // NOSONAR
    var t, n, e = this; return e instanceof SVGElement ? (t = (e = e.ownerSVGElement || e).width.baseVal.value, n = e.height.baseVal.value) : (t = e.clientWidth, n = e.clientHeight), [[0, 0], [t, n]]; // NOSONAR
  } function cs() { // NOSONAR
    return this.__zoom || mm; // NOSONAR
  } function ss() { // NOSONAR
    return -t.event.deltaY * (t.event.deltaMode ? 120 : 1) / 500; // NOSONAR
  } function fs() { // NOSONAR
    return 'ontouchstart' in this; // NOSONAR
  } var ls = function(t, n) { // NOSONAR
      return t < n ? -1 : t > n ? 1 : t >= n ? 0 : NaN; // NOSONAR
    }, hs = function(t) { // NOSONAR
      return t.length === 1 && (t = n(t)), {left: function(n, e, r, i) { // NOSONAR
        for (r == null && (r = 0), i == null && (i = n.length); r < i;) { // NOSONAR
          var o = r + i >>> 1; t(n[o], e) < 0 ? r = o + 1 : i = o; // NOSONAR
        } return r; // NOSONAR
      }, right: function(n, e, r, i) { // NOSONAR
        for (r == null && (r = 0), i == null && (i = n.length); r < i;) { // NOSONAR
          var o = r + i >>> 1; t(n[o], e) > 0 ? i = o : r = o + 1; // NOSONAR
        } return r; // NOSONAR
      }}; // NOSONAR
    }, ps = hs(ls), ds = ps.right, vs = ps.left, _s = function(t) { // NOSONAR
      return t === null ? NaN : +t; // NOSONAR
    }, gs = function(t, n) { // NOSONAR
      var e, r, i = t.length, o = 0, u = -1, a = 0, c = 0; if (n == null) { // NOSONAR
        for (;++u < i;) { // NOSONAR
          isNaN(e = _s(t[u])) || (c += (r = e - a) * (e - (a += r / ++o))); // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        for (;++u < i;) { // NOSONAR
          isNaN(e = _s(n(t[u], u, t))) || (c += (r = e - a) * (e - (a += r / ++o))); // NOSONAR
        } // NOSONAR
      } if (o > 1) { // NOSONAR
        return c / (o - 1); // NOSONAR
      } // NOSONAR
    }, ys = function(t, n) { // NOSONAR
      var e = gs(t, n); return e ? Math.sqrt(e) : e; // NOSONAR
    }, ms = function(t, n) { // NOSONAR
      var e, r, i, o = t.length, u = -1; if (n == null) { // NOSONAR
        for (;++u < o;) { // NOSONAR
          if ((e = t[u]) != null && e >= e) { // NOSONAR
            for (r = i = e; ++u < o;) { // NOSONAR
              (e = t[u]) != null && (r > e && (r = e), i < e && (i = e)); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        for (;++u < o;) { // NOSONAR
          if ((e = n(t[u], u, t)) != null && e >= e) { // NOSONAR
            for (r = i = e; ++u < o;) { // NOSONAR
              (e = n(t[u], u, t)) != null && (r > e && (r = e), i < e && (i = e)); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return [r, i]; // NOSONAR
    }, xs = Array.prototype, bs = xs.slice, ws = xs.map, Ms = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, Ts = function(t) { // NOSONAR
      return t; // NOSONAR
    }, Ns = function(t, n, e) { // NOSONAR
      t = +t, n = +n, e = (i = arguments.length) < 2 ? (n = t, t = 0, 1) : i < 3 ? 1 : +e; for (var r = -1, i = 0 | Math.max(0, Math.ceil((n - t) / e)), o = new Array(i); ++r < i;) { // NOSONAR
        o[r] = t + r * e; // NOSONAR
      } return o; // NOSONAR
    }, ks = Math.sqrt(50), Ss = Math.sqrt(10), Es = Math.sqrt(2), As = function(t, n, e) { // NOSONAR
      var i, o, u, a, c = -1; if (n = +n, t = +t, e = +e, t === n && e > 0) { // NOSONAR
        return [ t ]; // NOSONAR
      } if ((i = n < t) && (o = t, t = n, n = o), (a = r(t, n, e)) === 0 || !isFinite(a)) { // NOSONAR
        return []; // NOSONAR
      } if (a > 0) { // NOSONAR
        for (t = Math.ceil(t / a), n = Math.floor(n / a), u = new Array(o = Math.ceil(n - t + 1)); ++c < o;) { // NOSONAR
          u[c] = (t + c) * a; // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        for (t = Math.floor(t * a), n = Math.ceil(n * a), u = new Array(o = Math.ceil(t - n + 1)); ++c < o;) { // NOSONAR
          u[c] = (t - c) / a; // NOSONAR
        } // NOSONAR
      } return i && u.reverse(), u; // NOSONAR
    }, Cs = function(t) { // NOSONAR
      return Math.ceil(Math.log(t.length) / Math.LN2) + 1; // NOSONAR
    }, zs = function(t, n, e) { // NOSONAR
      if (e == null && (e = _s), r = t.length) { // NOSONAR
        if ((n = +n) <= 0 || r < 2) { // NOSONAR
          return +e(t[0], 0, t); // NOSONAR
        } if (n >= 1) { // NOSONAR
          return +e(t[r - 1], r - 1, t); // NOSONAR
        } var r, i = (r - 1) * n, o = Math.floor(i), u = +e(t[o], o, t); return u + (+e(t[o + 1], o + 1, t) - u) * (i - o); // NOSONAR
      } // NOSONAR
    }, Ps = function(t) { // NOSONAR
      for (var n, e, r, i = t.length, o = -1, u = 0; ++o < i;) { // NOSONAR
        u += t[o].length; // NOSONAR
      } for (e = new Array(u); --i >= 0;) { // NOSONAR
        for (n = (r = t[i]).length; --n >= 0;) { // NOSONAR
          e[--u] = r[n]; // NOSONAR
        } // NOSONAR
      } return e; // NOSONAR
    }, Rs = function(t, n) { // NOSONAR
      var e, r, i = t.length, o = -1; if (n == null) { // NOSONAR
        for (;++o < i;) { // NOSONAR
          if ((e = t[o]) != null && e >= e) { // NOSONAR
            for (r = e; ++o < i;) { // NOSONAR
              (e = t[o]) != null && r > e && (r = e); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        for (;++o < i;) { // NOSONAR
          if ((e = n(t[o], o, t)) != null && e >= e) { // NOSONAR
            for (r = e; ++o < i;) { // NOSONAR
              (e = n(t[o], o, t)) != null && r > e && (r = e); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return r; // NOSONAR
    }, Ls = function(t) { // NOSONAR
      if (!(i = t.length)) { // NOSONAR
        return []; // NOSONAR
      } for (var n = -1, e = Rs(t, o), r = new Array(e); ++n < e;) { // NOSONAR
        for (var i, u = -1, a = r[n] = new Array(i); ++u < i;) { // NOSONAR
          a[u] = t[u][n]; // NOSONAR
        } // NOSONAR
      } return r; // NOSONAR
    }, qs = Array.prototype.slice, Us = function(t) { // NOSONAR
      return t; // NOSONAR
    }, Ds = 1, Os = 2, Fs = 3, Is = 4, Ys = 1e-6, Bs = {value: function() {}}; p.prototype = h.prototype = {constructor: p, on: function(t, n) { // NOSONAR
    var e, r = this._, i = d(t + '', r), o = -1, u = i.length; {if (!(arguments.length < 2)) { // NOSONAR
      if (n != null && typeof n !== 'function') { // NOSONAR
        throw new Error('invalid callback: ' + n); // NOSONAR
      } for (;++o < u;) { // NOSONAR
        if (e = (t = i[o]).type) { // NOSONAR
          r[e] = _(r[e], t.name, n); // NOSONAR
        } else if (n == null) { // NOSONAR
          for (e in r) { // NOSONAR
            r[e] = _(r[e], t.name, null); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return this; // NOSONAR
    } for (;++o < u;) { // NOSONAR
      if ((e = (t = i[o]).type) && (e = v(r[e], t.name))) { // NOSONAR
        return e; // NOSONAR
      } // NOSONAR
    }} // NOSONAR
  }, copy: function() { // NOSONAR
    var t = {}, n = this._; for (var e in n) { // NOSONAR
      t[e] = n[e].slice(); // NOSONAR
    } return new p(t); // NOSONAR
  }, call: function(t, n) { // NOSONAR
    if ((e = arguments.length - 2) > 0) { // NOSONAR
      for (var e, r, i = new Array(e), o = 0; o < e; ++o) { // NOSONAR
        i[o] = arguments[o + 2]; // NOSONAR
      } // NOSONAR
    } if (!this._.hasOwnProperty(t)) { // NOSONAR
      throw new Error('unknown type: ' + t); // NOSONAR
    } for (o = 0, e = (r = this._[t]).length; o < e; ++o) { // NOSONAR
      r[o].value.apply(n, i); // NOSONAR
    } // NOSONAR
  }, apply: function(t, n, e) { // NOSONAR
    if (!this._.hasOwnProperty(t)) { // NOSONAR
      throw new Error('unknown type: ' + t); // NOSONAR
    } for (var r = this._[t], i = 0, o = r.length; i < o; ++i) { // NOSONAR
      r[i].value.apply(n, e); // NOSONAR
    } // NOSONAR
  }}; var js = 'http://www.w3.org/1999/xhtml', Hs = {svg: 'http://www.w3.org/2000/svg', xhtml: js, xlink: 'http://www.w3.org/1999/xlink', xml: 'http://www.w3.org/XML/1998/namespace', xmlns: 'http://www.w3.org/2000/xmlns/'}, Xs = function(t) { // NOSONAR
      var n = t += '', e = n.indexOf(':'); return e >= 0 && (n = t.slice(0, e)) !== 'xmlns' && (t = t.slice(e + 1)), Hs.hasOwnProperty(n) ? {space: Hs[n], local: t} : t; // NOSONAR
    }, $s = function(t) { // NOSONAR
      var n = Xs(t); return (n.local ? y : g)(n); // NOSONAR
    }, Vs = 0; x.prototype = m.prototype = {constructor: x, get: function(t) { // NOSONAR
    for (var n = this._; !(n in t);) { // NOSONAR
      if (!(t = t.parentNode)) { // NOSONAR
        return; // NOSONAR
      } // NOSONAR
    } return t[n]; // NOSONAR
  }, set: function(t, n) { // NOSONAR
    return t[this._] = n; // NOSONAR
  }, remove: function(t) { // NOSONAR
    return this._ in t && delete t[this._]; // NOSONAR
  }, toString: function() { // NOSONAR
    return this._; // NOSONAR
  }}; var Ws = function(t) { // NOSONAR
    return function() { // NOSONAR
      return this.matches(t); // NOSONAR
    }; // NOSONAR
  }; if (typeof document !== 'undefined') { // NOSONAR
    var Zs = document.documentElement; if (!Zs.matches) { // NOSONAR
      var Gs = Zs.webkitMatchesSelector || Zs.msMatchesSelector || Zs.mozMatchesSelector || Zs.oMatchesSelector; Ws = function(t) { // NOSONAR
        return function() { // NOSONAR
          return Gs.call(this, t); // NOSONAR
        }; // NOSONAR
      }; // NOSONAR
    } // NOSONAR
  } var Js = Ws, Qs = {}; t.event = null, typeof document !== 'undefined' && ('onmouseenter' in document.documentElement || (Qs = {mouseenter: 'mouseover', mouseleave: 'mouseout'})); var Ks = function() { // NOSONAR
      for (var n, e = t.event; n = e.sourceEvent;) { // NOSONAR
        e = n; // NOSONAR
      } return e; // NOSONAR
    }, tf = function(t, n) { // NOSONAR
      var e = t.ownerSVGElement || t; if (e.createSVGPoint) { // NOSONAR
        var r = e.createSVGPoint(); return r.x = n.clientX, r.y = n.clientY, r = r.matrixTransform(t.getScreenCTM().inverse()), [r.x, r.y]; // NOSONAR
      } var i = t.getBoundingClientRect(); return [n.clientX - i.left - t.clientLeft, n.clientY - i.top - t.clientTop]; // NOSONAR
    }, nf = function(t) { // NOSONAR
      var n = Ks(); return n.changedTouches && (n = n.changedTouches[0]), tf(t, n); // NOSONAR
    }, ef = function(t) { // NOSONAR
      return t == null ? S : function() { // NOSONAR
        return this.querySelector(t); // NOSONAR
      }; // NOSONAR
    }, rf = function(t) { // NOSONAR
      return t == null ? E : function() { // NOSONAR
        return this.querySelectorAll(t); // NOSONAR
      }; // NOSONAR
    }, of = function(t) { // NOSONAR
      return new Array(t.length); // NOSONAR
    }; A.prototype = {constructor: A, appendChild: function(t) { // NOSONAR
    return this._parent.insertBefore(t, this._next); // NOSONAR
  }, insertBefore: function(t, n) { // NOSONAR
    return this._parent.insertBefore(t, n); // NOSONAR
  }, querySelector: function(t) { // NOSONAR
    return this._parent.querySelector(t); // NOSONAR
  }, querySelectorAll: function(t) { // NOSONAR
    return this._parent.querySelectorAll(t); // NOSONAR
  }}; var uf = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, af = '$', cf = function(t) { // NOSONAR
      return t.ownerDocument && t.ownerDocument.defaultView || t.document && t || t.defaultView; // NOSONAR
    }; W.prototype = {add: function(t) { // NOSONAR
    this._names.indexOf(t) < 0 && (this._names.push(t), this._node.setAttribute('class', this._names.join(' '))); // NOSONAR
  }, remove: function(t) { // NOSONAR
    var n = this._names.indexOf(t); n >= 0 && (this._names.splice(n, 1), this._node.setAttribute('class', this._names.join(' '))); // NOSONAR
  }, contains: function(t) { // NOSONAR
    return this._names.indexOf(t) >= 0; // NOSONAR
  }}; var sf = [ null ]; pt.prototype = dt.prototype = {constructor: pt, select: function(t) { // NOSONAR
    typeof t !== 'function' && (t = ef(t)); for (var n = this._groups, e = n.length, r = new Array(e), i = 0; i < e; ++i) { // NOSONAR
      for (var o, u, a = n[i], c = a.length, s = r[i] = new Array(c), f = 0; f < c; ++f) { // NOSONAR
        (o = a[f]) && (u = t.call(o, o.__data__, f, a)) && ('__data__' in o && (u.__data__ = o.__data__), s[f] = u); // NOSONAR
      } // NOSONAR
    } return new pt(r, this._parents); // NOSONAR
  }, selectAll: function(t) { // NOSONAR
    typeof t !== 'function' && (t = rf(t)); for (var n = this._groups, e = n.length, r = [], i = [], o = 0; o < e; ++o) { // NOSONAR
      for (var u, a = n[o], c = a.length, s = 0; s < c; ++s) { // NOSONAR
        (u = a[s]) && (r.push(t.call(u, u.__data__, s, a)), i.push(u)); // NOSONAR
      } // NOSONAR
    } return new pt(r, i); // NOSONAR
  }, filter: function(t) { // NOSONAR
    typeof t !== 'function' && (t = Js(t)); for (var n = this._groups, e = n.length, r = new Array(e), i = 0; i < e; ++i) { // NOSONAR
      for (var o, u = n[i], a = u.length, c = r[i] = [], s = 0; s < a; ++s) { // NOSONAR
        (o = u[s]) && t.call(o, o.__data__, s, u) && c.push(o); // NOSONAR
      } // NOSONAR
    } return new pt(r, this._parents); // NOSONAR
  }, data: function(t, n) { // NOSONAR
    if (!t) { // NOSONAR
      return p = new Array(this.size()), s = -1, this.each(function(t) { // NOSONAR
        p[++s] = t; // NOSONAR
      }), p; // NOSONAR
    } var e = n ? z : C, r = this._parents, i = this._groups; typeof t !== 'function' && (t = uf(t)); for (var o = i.length, u = new Array(o), a = new Array(o), c = new Array(o), s = 0; s < o; ++s) { // NOSONAR
      var f = r[s], l = i[s], h = l.length, p = t.call(f, f && f.__data__, s, r), d = p.length, v = a[s] = new Array(d), _ = u[s] = new Array(d); e(f, l, v, _, c[s] = new Array(h), p, n); for (var g, y, m = 0, x = 0; m < d; ++m) { // NOSONAR
        if (g = v[m]) { // NOSONAR
          for (m >= x && (x = m + 1); !(y = _[x]) && ++x < d;) { // NOSONAR
 // NOSONAR
          }g._next = y || null; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return u = new pt(u, r), u._enter = a, u._exit = c, u; // NOSONAR
  }, enter: function() { // NOSONAR
    return new pt(this._enter || this._groups.map(of), this._parents); // NOSONAR
  }, exit: function() { // NOSONAR
    return new pt(this._exit || this._groups.map(of), this._parents); // NOSONAR
  }, merge: function(t) { // NOSONAR
    for (var n = this._groups, e = t._groups, r = n.length, i = e.length, o = Math.min(r, i), u = new Array(r), a = 0; a < o; ++a) { // NOSONAR
      for (var c, s = n[a], f = e[a], l = s.length, h = u[a] = new Array(l), p = 0; p < l; ++p) { // NOSONAR
        (c = s[p] || f[p]) && (h[p] = c); // NOSONAR
      } // NOSONAR
    } for (;a < r; ++a) { // NOSONAR
      u[a] = n[a]; // NOSONAR
    } return new pt(u, this._parents); // NOSONAR
  }, order: function() { // NOSONAR
    for (var t = this._groups, n = -1, e = t.length; ++n < e;) { // NOSONAR
      for (var r, i = t[n], o = i.length - 1, u = i[o]; --o >= 0;) { // NOSONAR
        (r = i[o]) && (u && u !== r.nextSibling && u.parentNode.insertBefore(r, u), u = r); // NOSONAR
      } // NOSONAR
    } return this; // NOSONAR
  }, sort: function(t) { // NOSONAR
    t || (t = P); for (var n = this._groups, e = n.length, r = new Array(e), i = 0; i < e; ++i) { // NOSONAR
      for (var o, u = n[i], a = u.length, c = r[i] = new Array(a), s = 0; s < a; ++s) { // NOSONAR
        (o = u[s]) && (c[s] = o); // NOSONAR
      }c.sort(function(n, e) { // NOSONAR
        return n && e ? t(n.__data__, e.__data__) : !n - !e; // NOSONAR
      }); // NOSONAR
    } return new pt(r, this._parents).order(); // NOSONAR
  }, call: function() { // NOSONAR
    var t = arguments[0]; return arguments[0] = this, t.apply(null, arguments), this; // NOSONAR
  }, nodes: function() { // NOSONAR
    var t = new Array(this.size()), n = -1; return this.each(function() { // NOSONAR
      t[++n] = this; // NOSONAR
    }), t; // NOSONAR
  }, node: function() { // NOSONAR
    for (var t = this._groups, n = 0, e = t.length; n < e; ++n) { // NOSONAR
      for (var r = t[n], i = 0, o = r.length; i < o; ++i) { // NOSONAR
        var u = r[i]; if (u) { // NOSONAR
          return u; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return null; // NOSONAR
  }, size: function() { // NOSONAR
    var t = 0; return this.each(function() { // NOSONAR
      ++t; // NOSONAR
    }), t; // NOSONAR
  }, empty: function() { // NOSONAR
    return !this.node(); // NOSONAR
  }, each: function(t) { // NOSONAR
    for (var n = this._groups, e = 0, r = n.length; e < r; ++e) { // NOSONAR
      for (var i, o = n[e], u = 0, a = o.length; u < a; ++u) { // NOSONAR
        (i = o[u]) && t.call(i, i.__data__, u, o); // NOSONAR
      } // NOSONAR
    } return this; // NOSONAR
  }, attr: function(t, n) { // NOSONAR
    var e = Xs(t); if (arguments.length < 2) { // NOSONAR
      var r = this.node(); return e.local ? r.getAttributeNS(e.space, e.local) : r.getAttribute(e); // NOSONAR
    } return this.each((n == null ? e.local ? L : R : typeof n === 'function' ? e.local ? O : D : e.local ? U : q)(e, n)); // NOSONAR
  }, style: function(t, n, e) { // NOSONAR
    return arguments.length > 1 ? this.each((n == null ? F : typeof n === 'function' ? Y : I)(t, n, e == null ? '' : e)) : B(this.node(), t); // NOSONAR
  }, property: function(t, n) { // NOSONAR
    return arguments.length > 1 ? this.each((n == null ? j : typeof n === 'function' ? X : H)(t, n)) : this.node()[t]; // NOSONAR
  }, classed: function(t, n) { // NOSONAR
    var e = $(t + ''); if (arguments.length < 2) { // NOSONAR
      for (var r = V(this.node()), i = -1, o = e.length; ++i < o;) { // NOSONAR
        if (!r.contains(e[i])) { // NOSONAR
          return !1; // NOSONAR
        } // NOSONAR
      } return !0; // NOSONAR
    } return this.each((typeof n === 'function' ? K : n ? J : Q)(e, n)); // NOSONAR
  }, text: function(t) { // NOSONAR
    return arguments.length ? this.each(t == null ? tt : (typeof t === 'function' ? et : nt)(t)) : this.node().textContent; // NOSONAR
  }, html: function(t) { // NOSONAR
    return arguments.length ? this.each(t == null ? rt : (typeof t === 'function' ? ot : it)(t)) : this.node().innerHTML; // NOSONAR
  }, raise: function() { // NOSONAR
    return this.each(ut); // NOSONAR
  }, lower: function() { // NOSONAR
    return this.each(at); // NOSONAR
  }, append: function(t) { // NOSONAR
    var n = typeof t === 'function' ? t : $s(t); return this.select(function() { // NOSONAR
      return this.appendChild(n.apply(this, arguments)); // NOSONAR
    }); // NOSONAR
  }, insert: function(t, n) { // NOSONAR
    var e = typeof t === 'function' ? t : $s(t), r = n == null ? ct : typeof n === 'function' ? n : ef(n); return this.select(function() { // NOSONAR
      return this.insertBefore(e.apply(this, arguments), r.apply(this, arguments) || null); // NOSONAR
    }); // NOSONAR
  }, remove: function() { // NOSONAR
    return this.each(st); // NOSONAR
  }, datum: function(t) { // NOSONAR
    return arguments.length ? this.property('__data__', t) : this.node().__data__; // NOSONAR
  }, on: function(t, n, e) { // NOSONAR
    var r, i, o = M(t + ''), u = o.length; {if (!(arguments.length < 2)) { // NOSONAR
      for (a = n ? N : T, e == null && (e = !1), r = 0; r < u; ++r) { // NOSONAR
        this.each(a(o[r], n, e)); // NOSONAR
      } return this; // NOSONAR
    } var a = this.node().__on; if (a) { // NOSONAR
      for (var c, s = 0, f = a.length; s < f; ++s) { // NOSONAR
        for (r = 0, c = a[s]; r < u; ++r) { // NOSONAR
          if ((i = o[r]).type === c.type && i.name === c.name) { // NOSONAR
            return c.value; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    }} // NOSONAR
  }, dispatch: function(t, n) { // NOSONAR
    return this.each((typeof n === 'function' ? ht : lt)(t, n)); // NOSONAR
  }}; var ff = function(t) { // NOSONAR
      return typeof t === 'string' ? new pt([ [ document.querySelector(t) ] ], [ document.documentElement ]) : new pt([ [ t ] ], sf); // NOSONAR
    }, lf = function(t, n, e) { // NOSONAR
      arguments.length < 3 && (e = n, n = Ks().changedTouches); for (var r, i = 0, o = n ? n.length : 0; i < o; ++i) { // NOSONAR
        if ((r = n[i]).identifier === e) { // NOSONAR
          return tf(t, r); // NOSONAR
        } // NOSONAR
      } return null; // NOSONAR
    }, hf = function() { // NOSONAR
      t.event.preventDefault(), t.event.stopImmediatePropagation(); // NOSONAR
    }, pf = function(t) { // NOSONAR
      var n = t.document.documentElement, e = ff(t).on('dragstart.drag', hf, !0); 'onselectstart' in n ? e.on('selectstart.drag', hf, !0) : (n.__noselect = n.style.MozUserSelect, n.style.MozUserSelect = 'none'); // NOSONAR
    }, df = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }; gt.prototype.on = function() { // NOSONAR
    var t = this._.on.apply(this._, arguments); return t === this._ ? this : t; // NOSONAR
  }; var vf = function(t, n, e) { // NOSONAR
      t.prototype = n.prototype = e, e.constructor = t; // NOSONAR
    }, _f = '\\s*([+-]?\\d+)\\s*', gf = '\\s*([+-]?\\d*\\.?\\d+(?:[eE][+-]?\\d+)?)\\s*', yf = '\\s*([+-]?\\d*\\.?\\d+(?:[eE][+-]?\\d+)?)%\\s*', mf = /^#([0-9a-f]{3})$/, xf = /^#([0-9a-f]{6})$/, bf = new RegExp('^rgb\\(' + [_f, _f, _f] + '\\)$'), wf = new RegExp('^rgb\\(' + [yf, yf, yf] + '\\)$'), Mf = new RegExp('^rgba\\(' + [_f, _f, _f, gf] + '\\)$'), Tf = new RegExp('^rgba\\(' + [yf, yf, yf, gf] + '\\)$'), Nf = new RegExp('^hsl\\(' + [gf, yf, yf] + '\\)$'), kf = new RegExp('^hsla\\(' + [gf, yf, yf, gf] + '\\)$'), Sf = {aliceblue: 15792383, antiquewhite: 16444375, aqua: 65535, aquamarine: 8388564, azure: 15794175, beige: 16119260, bisque: 16770244, black: 0, blanchedalmond: 16772045, blue: 255, blueviolet: 9055202, brown: 10824234, burlywood: 14596231, cadetblue: 6266528, chartreuse: 8388352, chocolate: 13789470, coral: 16744272, cornflowerblue: 6591981, cornsilk: 16775388, crimson: 14423100, cyan: 65535, darkblue: 139, darkcyan: 35723, darkgoldenrod: 12092939, darkgray: 11119017, darkgreen: 25600, darkgrey: 11119017, darkkhaki: 12433259, darkmagenta: 9109643, darkolivegreen: 5597999, darkorange: 16747520, darkorchid: 10040012, darkred: 9109504, darksalmon: 15308410, darkseagreen: 9419919, darkslateblue: 4734347, darkslategray: 3100495, darkslategrey: 3100495, darkturquoise: 52945, darkviolet: 9699539, deeppink: 16716947, deepskyblue: 49151, dimgray: 6908265, dimgrey: 6908265, dodgerblue: 2003199, firebrick: 11674146, floralwhite: 16775920, forestgreen: 2263842, fuchsia: 16711935, gainsboro: 14474460, ghostwhite: 16316671, gold: 16766720, goldenrod: 14329120, gray: 8421504, green: 32768, greenyellow: 11403055, grey: 8421504, honeydew: 15794160, hotpink: 16738740, indianred: 13458524, indigo: 4915330, ivory: 16777200, khaki: 15787660, lavender: 15132410, lavenderblush: 16773365, lawngreen: 8190976, lemonchiffon: 16775885, lightblue: 11393254, lightcoral: 15761536, lightcyan: 14745599, lightgoldenrodyellow: 16448210, lightgray: 13882323, lightgreen: 9498256, lightgrey: 13882323, lightpink: 16758465, lightsalmon: 16752762, lightseagreen: 2142890, lightskyblue: 8900346, lightslategray: 7833753, lightslategrey: 7833753, lightsteelblue: 11584734, lightyellow: 16777184, lime: 65280, limegreen: 3329330, linen: 16445670, magenta: 16711935, maroon: 8388608, mediumaquamarine: 6737322, mediumblue: 205, mediumorchid: 12211667, mediumpurple: 9662683, mediumseagreen: 3978097, mediumslateblue: 8087790, mediumspringgreen: 64154, mediumturquoise: 4772300, mediumvioletred: 13047173, midnightblue: 1644912, mintcream: 16121850, mistyrose: 16770273, moccasin: 16770229, navajowhite: 16768685, navy: 128, oldlace: 16643558, olive: 8421376, olivedrab: 7048739, orange: 16753920, orangered: 16729344, orchid: 14315734, palegoldenrod: 15657130, palegreen: 10025880, paleturquoise: 11529966, palevioletred: 14381203, papayawhip: 16773077, peachpuff: 16767673, peru: 13468991, pink: 16761035, plum: 14524637, powderblue: 11591910, purple: 8388736, rebeccapurple: 6697881, red: 16711680, rosybrown: 12357519, royalblue: 4286945, saddlebrown: 9127187, salmon: 16416882, sandybrown: 16032864, seagreen: 3050327, seashell: 16774638, sienna: 10506797, silver: 12632256, skyblue: 8900331, slateblue: 6970061, slategray: 7372944, slategrey: 7372944, snow: 16775930, springgreen: 65407, steelblue: 4620980, tan: 13808780, teal: 32896, thistle: 14204888, tomato: 16737095, turquoise: 4251856, violet: 15631086, wheat: 16113331, white: 16777215, whitesmoke: 16119285, yellow: 16776960, yellowgreen: 10145074}; vf(Mt, Tt, {displayable: function() { // NOSONAR
    return this.rgb().displayable(); // NOSONAR
  }, toString: function() { // NOSONAR
    return this.rgb() + ''; // NOSONAR
  }}), vf(At, Et, wt(Mt, {brighter: function(t) { // NOSONAR
    return t = t == null ? 1 / .7 : Math.pow(1 / .7, t), new At(this.r * t, this.g * t, this.b * t, this.opacity); // NOSONAR
  }, darker: function(t) { // NOSONAR
    return t = t == null ? .7 : Math.pow(.7, t), new At(this.r * t, this.g * t, this.b * t, this.opacity); // NOSONAR
  }, rgb: function() { // NOSONAR
    return this; // NOSONAR
  }, displayable: function() { // NOSONAR
    return this.r >= 0 && this.r <= 255 && this.g >= 0 && this.g <= 255 && this.b >= 0 && this.b <= 255 && this.opacity >= 0 && this.opacity <= 1; // NOSONAR
  }, toString: function() { // NOSONAR
    var t = this.opacity; return ((t = isNaN(t) ? 1 : Math.max(0, Math.min(1, t))) === 1 ? 'rgb(' : 'rgba(') + Math.max(0, Math.min(255, Math.round(this.r) || 0)) + ', ' + Math.max(0, Math.min(255, Math.round(this.g) || 0)) + ', ' + Math.max(0, Math.min(255, Math.round(this.b) || 0)) + (t === 1 ? ')' : ', ' + t + ')'); // NOSONAR
  }})), vf(Rt, Pt, wt(Mt, {brighter: function(t) { // NOSONAR
    return t = t == null ? 1 / .7 : Math.pow(1 / .7, t), new Rt(this.h, this.s, this.l * t, this.opacity); // NOSONAR
  }, darker: function(t) { // NOSONAR
    return t = t == null ? .7 : Math.pow(.7, t), new Rt(this.h, this.s, this.l * t, this.opacity); // NOSONAR
  }, rgb: function() { // NOSONAR
    var t = this.h % 360 + 360 * (this.h < 0), n = isNaN(t) || isNaN(this.s) ? 0 : this.s, e = this.l, r = e + (e < .5 ? e : 1 - e) * n, i = 2 * e - r; return new At(Lt(t >= 240 ? t - 240 : t + 120, i, r), Lt(t, i, r), Lt(t < 120 ? t + 240 : t - 120, i, r), this.opacity); // NOSONAR
  }, displayable: function() { // NOSONAR
    return (this.s >= 0 && this.s <= 1 || isNaN(this.s)) && this.l >= 0 && this.l <= 1 && this.opacity >= 0 && this.opacity <= 1; // NOSONAR
  }})); var Ef = Math.PI / 180, Af = 180 / Math.PI, Cf = .95047, zf = 1, Pf = 1.08883, Rf = 4 / 29, Lf = 6 / 29, qf = 3 * Lf * Lf, Uf = Lf * Lf * Lf; vf(Dt, Ut, wt(Mt, {brighter: function(t) { // NOSONAR
    return new Dt(this.l + 18 * (t == null ? 1 : t), this.a, this.b, this.opacity); // NOSONAR
  }, darker: function(t) { // NOSONAR
    return new Dt(this.l - 18 * (t == null ? 1 : t), this.a, this.b, this.opacity); // NOSONAR
  }, rgb: function() { // NOSONAR
    var t = (this.l + 16) / 116, n = isNaN(this.a) ? t : t + this.a / 500, e = isNaN(this.b) ? t : t - this.b / 200; return t = zf * Ft(t), n = Cf * Ft(n), e = Pf * Ft(e), new At(It(3.2404542 * n - 1.5371385 * t - .4985314 * e), It(-.969266 * n + 1.8760108 * t + .041556 * e), It(.0556434 * n - .2040259 * t + 1.0572252 * e), this.opacity); // NOSONAR
  }})), vf(Ht, jt, wt(Mt, {brighter: function(t) { // NOSONAR
    return new Ht(this.h, this.c, this.l + 18 * (t == null ? 1 : t), this.opacity); // NOSONAR
  }, darker: function(t) { // NOSONAR
    return new Ht(this.h, this.c, this.l - 18 * (t == null ? 1 : t), this.opacity); // NOSONAR
  }, rgb: function() { // NOSONAR
    return qt(this).rgb(); // NOSONAR
  }})); var Df = -.14861, Of = 1.78277, Ff = -.29227, If = -.90649, Yf = 1.97294, Bf = Yf * If, jf = Yf * Of, Hf = Of * Ff - If * Df; vf(Vt, $t, wt(Mt, {brighter: function(t) { // NOSONAR
    return t = t == null ? 1 / .7 : Math.pow(1 / .7, t), new Vt(this.h, this.s, this.l * t, this.opacity); // NOSONAR
  }, darker: function(t) { // NOSONAR
    return t = t == null ? .7 : Math.pow(.7, t), new Vt(this.h, this.s, this.l * t, this.opacity); // NOSONAR
  }, rgb: function() { // NOSONAR
    var t = isNaN(this.h) ? 0 : (this.h + 120) * Ef, n = +this.l, e = isNaN(this.s) ? 0 : this.s * n * (1 - n), r = Math.cos(t), i = Math.sin(t); return new At(255 * (n + e * (Df * r + Of * i)), 255 * (n + e * (Ff * r + If * i)), 255 * (n + e * (Yf * r)), this.opacity); // NOSONAR
  }})); var Xf, $f, Vf, Wf, Zf, Gf, Jf = function(t) { // NOSONAR
      var n = t.length - 1; return function(e) { // NOSONAR
        var r = e <= 0 ? e = 0 : e >= 1 ? (e = 1, n - 1) : Math.floor(e * n), i = t[r], o = t[r + 1], u = r > 0 ? t[r - 1] : 2 * i - o, a = r < n - 1 ? t[r + 2] : 2 * o - i; return Wt((e - r / n) * n, u, i, o, a); // NOSONAR
      }; // NOSONAR
    }, Qf = function(t) { // NOSONAR
      var n = t.length; return function(e) { // NOSONAR
        var r = Math.floor(((e %= 1) < 0 ? ++e : e) * n), i = t[(r + n - 1) % n], o = t[r % n], u = t[(r + 1) % n], a = t[(r + 2) % n]; return Wt((e - r / n) * n, i, o, u, a); // NOSONAR
      }; // NOSONAR
    }, Kf = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, tl = (function t(n) { // NOSONAR
      function e(t, n) { // NOSONAR
        var e = r((t = Et(t)).r, (n = Et(n)).r), i = r(t.g, n.g), o = r(t.b, n.b), u = Kt(t.opacity, n.opacity); return function(n) { // NOSONAR
          return t.r = e(n), t.g = i(n), t.b = o(n), t.opacity = u(n), t + ''; // NOSONAR
        }; // NOSONAR
      } var r = Qt(n); return e.gamma = t, e; // NOSONAR
    }(1)), nl = tn(Jf), el = tn(Qf), rl = function(t, n) { // NOSONAR
      var e, r = n ? n.length : 0, i = t ? Math.min(r, t.length) : 0, o = new Array(r), u = new Array(r); for (e = 0; e < i; ++e) { // NOSONAR
        o[e] = fl(t[e], n[e]); // NOSONAR
      } for (;e < r; ++e) { // NOSONAR
        u[e] = n[e]; // NOSONAR
      } return function(t) { // NOSONAR
        for (e = 0; e < i; ++e) { // NOSONAR
          u[e] = o[e](t); // NOSONAR
        } return u; // NOSONAR
      }; // NOSONAR
    }, il = function(t, n) { // NOSONAR
      var e = new Date; return t = +t, n -= t, function(r) { // NOSONAR
        return e.setTime(t + n * r), e; // NOSONAR
      }; // NOSONAR
    }, ol = function(t, n) { // NOSONAR
      return t = +t, n -= t, function(e) { // NOSONAR
        return t + n * e; // NOSONAR
      }; // NOSONAR
    }, ul = function(t, n) { // NOSONAR
      var e, r = {}, i = {}; t !== null && typeof t === 'object' || (t = {}), n !== null && typeof n === 'object' || (n = {}); for (e in n) { // NOSONAR
        e in t ? r[e] = fl(t[e], n[e]) : i[e] = n[e]; // NOSONAR
      } return function(t) { // NOSONAR
        for (e in r) { // NOSONAR
          i[e] = r[e](t); // NOSONAR
        } return i; // NOSONAR
      }; // NOSONAR
    }, al = /[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?/g, cl = new RegExp(al.source, 'g'), sl = function(t, n) { // NOSONAR
      var e, r, i, o = al.lastIndex = cl.lastIndex = 0, u = -1, a = [], c = []; for (t += '', n += ''; (e = al.exec(t)) && (r = cl.exec(n));) { // NOSONAR
        (i = r.index) > o && (i = n.slice(o, i), a[u] ? a[u] += i : a[++u] = i), (e = e[0]) === (r = r[0]) ? a[u] ? a[u] += r : a[++u] = r : (a[++u] = null, c.push({i: u, x: ol(e, r)})), o = cl.lastIndex; // NOSONAR
      } return o < n.length && (i = n.slice(o), a[u] ? a[u] += i : a[++u] = i), a.length < 2 ? c[0] ? en(c[0].x) : nn(n) : (n = c.length, function(t) { // NOSONAR
        for (var e, r = 0; r < n; ++r) { // NOSONAR
          a[(e = c[r]).i] = e.x(t); // NOSONAR
        } return a.join(''); // NOSONAR
      }); // NOSONAR
    }, fl = function(t, n) { // NOSONAR
      var e, r = typeof n; return n == null || r === 'boolean' ? Kf(n) : (r === 'number' ? ol : r === 'string' ? (e = Tt(n)) ? (n = e, tl) : sl : n instanceof Tt ? tl : n instanceof Date ? il : Array.isArray(n) ? rl : typeof n.valueOf !== 'function' && typeof n.toString !== 'function' || isNaN(n) ? ul : ol)(t, n); // NOSONAR
    }, ll = function(t, n) { // NOSONAR
      return t = +t, n -= t, function(e) { // NOSONAR
        return Math.round(t + n * e); // NOSONAR
      }; // NOSONAR
    }, hl = 180 / Math.PI, pl = {translateX: 0, translateY: 0, rotate: 0, skewX: 0, scaleX: 1, scaleY: 1}, dl = function(t, n, e, r, i, o) { // NOSONAR
      var u, a, c; return (u = Math.sqrt(t * t + n * n)) && (t /= u, n /= u), (c = t * e + n * r) && (e -= t * c, r -= n * c), (a = Math.sqrt(e * e + r * r)) && (e /= a, r /= a, c /= a), t * r < n * e && (t = -t, n = -n, c = -c, u = -u), {translateX: i, translateY: o, rotate: Math.atan2(n, t) * hl, skewX: Math.atan(c) * hl, scaleX: u, scaleY: a}; // NOSONAR
    }, vl = rn(function(t) { // NOSONAR
      return t === 'none' ? pl : (Xf || (Xf = document.createElement('DIV'), $f = document.documentElement, Vf = document.defaultView), Xf.style.transform = t, t = Vf.getComputedStyle($f.appendChild(Xf), null).getPropertyValue('transform'), $f.removeChild(Xf), t = t.slice(7, -1).split(','), dl(+t[0], +t[1], +t[2], +t[3], +t[4], +t[5])); // NOSONAR
    }, 'px, ', 'px)', 'deg)'), _l = rn(function(t) { // NOSONAR
      return t == null ? pl : (Wf || (Wf = document.createElementNS('http://www.w3.org/2000/svg', 'g')), Wf.setAttribute('transform', t), (t = Wf.transform.baseVal.consolidate()) ? (t = t.matrix, dl(t.a, t.b, t.c, t.d, t.e, t.f)) : pl); // NOSONAR
    }, ', ', ')', ')'), gl = Math.SQRT2, yl = function(t, n) { // NOSONAR
      var e, r, i = t[0], o = t[1], u = t[2], a = n[0], c = n[1], s = n[2], f = a - i, l = c - o, h = f * f + l * l; if (h < 1e-12) { // NOSONAR
        r = Math.log(s / u) / gl, e = function(t) { // NOSONAR
          return [i + t * f, o + t * l, u * Math.exp(gl * t * r)]; // NOSONAR
        }; // NOSONAR
      } else { // NOSONAR
        var p = Math.sqrt(h), d = (s * s - u * u + 4 * h) / (2 * u * 2 * p), v = (s * s - u * u - 4 * h) / (2 * s * 2 * p), _ = Math.log(Math.sqrt(d * d + 1) - d), g = Math.log(Math.sqrt(v * v + 1) - v); r = (g - _) / gl, e = function(t) { // NOSONAR
          var n = t * r, e = on(_), a = u / (2 * p) * (e * an(gl * n + _) - un(_)); return [i + a * f, o + a * l, u * e / on(gl * n + _)]; // NOSONAR
        }; // NOSONAR
      } return e.duration = 1e3 * r, e; // NOSONAR
    }, ml = cn(Jt), xl = cn(Kt), bl = sn(Jt), wl = sn(Kt), Ml = fn(Jt), Tl = fn(Kt), Nl = 0, kl = 0, Sl = 0, El = 1e3, Al = 0, Cl = 0, zl = 0, Pl = typeof performance === 'object' && performance.now ? performance : Date, Rl = typeof window === 'object' && window.requestAnimationFrame ? window.requestAnimationFrame.bind(window) : function(t) { // NOSONAR
      setTimeout(t, 17); // NOSONAR
    }; pn.prototype = dn.prototype = {constructor: pn, restart: function(t, n, e) { // NOSONAR
    if (typeof t !== 'function') { // NOSONAR
      throw new TypeError('callback is not a function'); // NOSONAR
    } e = (e == null ? ln() : +e) + (n == null ? 0 : +n), this._next || Gf === this || (Gf ? Gf._next = this : Zf = this, Gf = this), this._call = t, this._time = e, mn(); // NOSONAR
  }, stop: function() { // NOSONAR
    this._call && (this._call = null, this._time = 1 / 0, mn()); // NOSONAR
  }}; var Ll = function(t, n, e) { // NOSONAR
      var r = new pn; return n = n == null ? 0 : +n, r.restart(function(e) { // NOSONAR
        r.stop(), t(e + n); // NOSONAR
      }, n, e), r; // NOSONAR
    }, ql = h('start', 'end', 'interrupt'), Ul = [], Dl = 0, Ol = 1, Fl = 2, Il = 3, Yl = 4, Bl = 5, jl = 6, Hl = function(t, n, e, r, i, o) { // NOSONAR
      var u = t.__transition; if (u) { // NOSONAR
        if (e in u) { // NOSONAR
          return; // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        t.__transition = {}; // NOSONAR
      }Mn(t, e, {name: n, index: r, group: i, on: ql, tween: Ul, time: o.time, delay: o.delay, duration: o.duration, ease: o.ease, timer: null, state: Dl}); // NOSONAR
    }, Xl = function(t, n) { // NOSONAR
      var e, r, i, o = t.__transition, u = !0; if (o) { // NOSONAR
        n = n == null ? null : n + ''; for (i in o) { // NOSONAR
          (e = o[i]).name === n ? (r = e.state > Fl && e.state < Bl, e.state = jl, e.timer.stop(), r && e.on.call('interrupt', t, t.__data__, e.index, e.group), delete o[i]) : u = !1; // NOSONAR
        }u && delete t.__transition; // NOSONAR
      } // NOSONAR
    }, $l = function(t, n) { // NOSONAR
      var e; return (typeof n === 'number' ? ol : n instanceof Tt ? tl : (e = Tt(n)) ? (n = e, tl) : sl)(t, n); // NOSONAR
    }, Vl = dt.prototype.constructor, Wl = 0, Zl = dt.prototype; Gn.prototype = Jn.prototype = {constructor: Gn, select: function(t) { // NOSONAR
    var n = this._name, e = this._id; typeof t !== 'function' && (t = ef(t)); for (var r = this._groups, i = r.length, o = new Array(i), u = 0; u < i; ++u) { // NOSONAR
      for (var a, c, s = r[u], f = s.length, l = o[u] = new Array(f), h = 0; h < f; ++h) { // NOSONAR
        (a = s[h]) && (c = t.call(a, a.__data__, h, s)) && ('__data__' in a && (c.__data__ = a.__data__), l[h] = c, Hl(l[h], n, e, h, l, wn(a, e))); // NOSONAR
      } // NOSONAR
    } return new Gn(o, this._parents, n, e); // NOSONAR
  }, selectAll: function(t) { // NOSONAR
    var n = this._name, e = this._id; typeof t !== 'function' && (t = rf(t)); for (var r = this._groups, i = r.length, o = [], u = [], a = 0; a < i; ++a) { // NOSONAR
      for (var c, s = r[a], f = s.length, l = 0; l < f; ++l) { // NOSONAR
        if (c = s[l]) { // NOSONAR
          for (var h, p = t.call(c, c.__data__, l, s), d = wn(c, e), v = 0, _ = p.length; v < _; ++v) { // NOSONAR
            (h = p[v]) && Hl(h, n, e, v, p, d); // NOSONAR
          }o.push(p), u.push(c); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return new Gn(o, u, n, e); // NOSONAR
  }, filter: function(t) { // NOSONAR
    typeof t !== 'function' && (t = Js(t)); for (var n = this._groups, e = n.length, r = new Array(e), i = 0; i < e; ++i) { // NOSONAR
      for (var o, u = n[i], a = u.length, c = r[i] = [], s = 0; s < a; ++s) { // NOSONAR
        (o = u[s]) && t.call(o, o.__data__, s, u) && c.push(o); // NOSONAR
      } // NOSONAR
    } return new Gn(r, this._parents, this._name, this._id); // NOSONAR
  }, merge: function(t) { // NOSONAR
    if (t._id !== this._id) { // NOSONAR
      throw new Error; // NOSONAR
    } for (var n = this._groups, e = t._groups, r = n.length, i = e.length, o = Math.min(r, i), u = new Array(r), a = 0; a < o; ++a) { // NOSONAR
      for (var c, s = n[a], f = e[a], l = s.length, h = u[a] = new Array(l), p = 0; p < l; ++p) { // NOSONAR
        (c = s[p] || f[p]) && (h[p] = c); // NOSONAR
      } // NOSONAR
    } for (;a < r; ++a) { // NOSONAR
      u[a] = n[a]; // NOSONAR
    } return new Gn(u, this._parents, this._name, this._id); // NOSONAR
  }, selection: function() { // NOSONAR
    return new Vl(this._groups, this._parents); // NOSONAR
  }, transition: function() { // NOSONAR
    for (var t = this._name, n = this._id, e = Qn(), r = this._groups, i = r.length, o = 0; o < i; ++o) { // NOSONAR
      for (var u, a = r[o], c = a.length, s = 0; s < c; ++s) { // NOSONAR
        if (u = a[s]) { // NOSONAR
          var f = wn(u, n); Hl(u, t, e, s, a, {time: f.time + f.delay + f.duration, delay: 0, duration: f.duration, ease: f.ease}); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return new Gn(r, this._parents, t, e); // NOSONAR
  }, call: Zl.call, nodes: Zl.nodes, node: Zl.node, size: Zl.size, empty: Zl.empty, each: Zl.each, on: function(t, n) { // NOSONAR
    var e = this._id; return arguments.length < 2 ? wn(this.node(), e).on.on(t) : this.each(Yn(e, t, n)); // NOSONAR
  }, attr: function(t, n) { // NOSONAR
    var e = Xs(t), r = e === 'transform' ? _l : $l; return this.attrTween(t, typeof n === 'function' ? (e.local ? Pn : zn)(e, r, kn(this, 'attr.' + t, n)) : n == null ? (e.local ? En : Sn)(e) : (e.local ? Cn : An)(e, r, n + '')); // NOSONAR
  }, attrTween: function(t, n) { // NOSONAR
    var e = 'attr.' + t; if (arguments.length < 2) { // NOSONAR
      return (e = this.tween(e)) && e._value; // NOSONAR
    } if (n == null) { // NOSONAR
      return this.tween(e, null); // NOSONAR
    } if (typeof n !== 'function') { // NOSONAR
      throw new Error; // NOSONAR
    } var r = Xs(t); return this.tween(e, (r.local ? Rn : Ln)(r, n)); // NOSONAR
  }, style: function(t, n, e) { // NOSONAR
    var r = (t += '') == 'transform' ? vl : $l; return n == null ? this.styleTween(t, jn(t, r)).on('end.style.' + t, Hn(t)) : this.styleTween(t, typeof n === 'function' ? $n(t, r, kn(this, 'style.' + t, n)) : Xn(t, r, n + ''), e); // NOSONAR
  }, styleTween: function(t, n, e) { // NOSONAR
    var r = 'style.' + (t += ''); if (arguments.length < 2) { // NOSONAR
      return (r = this.tween(r)) && r._value; // NOSONAR
    } if (n == null) { // NOSONAR
      return this.tween(r, null); // NOSONAR
    } if (typeof n !== 'function') { // NOSONAR
      throw new Error; // NOSONAR
    } return this.tween(r, Vn(t, n, e == null ? '' : e)); // NOSONAR
  }, text: function(t) { // NOSONAR
    return this.tween('text', typeof t === 'function' ? Zn(kn(this, 'text', t)) : Wn(t == null ? '' : t + '')); // NOSONAR
  }, remove: function() { // NOSONAR
    return this.on('end.remove', Bn(this._id)); // NOSONAR
  }, tween: function(t, n) { // NOSONAR
    var e = this._id; if (t += '', arguments.length < 2) { // NOSONAR
      for (var r, i = wn(this.node(), e).tween, o = 0, u = i.length; o < u; ++o) { // NOSONAR
        if ((r = i[o]).name === t) { // NOSONAR
          return r.value; // NOSONAR
        } // NOSONAR
      } return null; // NOSONAR
    } return this.each((n == null ? Tn : Nn)(e, t, n)); // NOSONAR
  }, delay: function(t) { // NOSONAR
    var n = this._id; return arguments.length ? this.each((typeof t === 'function' ? qn : Un)(n, t)) : wn(this.node(), n).delay; // NOSONAR
  }, duration: function(t) { // NOSONAR
    var n = this._id; return arguments.length ? this.each((typeof t === 'function' ? Dn : On)(n, t)) : wn(this.node(), n).duration; // NOSONAR
  }, ease: function(t) { // NOSONAR
    var n = this._id; return arguments.length ? this.each(Fn(n, t)) : wn(this.node(), n).ease; // NOSONAR
  }}; var Gl = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return Math.pow(t, n); // NOSONAR
      } return n = +n, e.exponent = t, e; // NOSONAR
    }(3)), Jl = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return 1 - Math.pow(1 - t, n); // NOSONAR
      } return n = +n, e.exponent = t, e; // NOSONAR
    }(3)), Ql = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return ((t *= 2) <= 1 ? Math.pow(t, n) : 2 - Math.pow(2 - t, n)) / 2; // NOSONAR
      } return n = +n, e.exponent = t, e; // NOSONAR
    }(3)), Kl = Math.PI, th = Kl / 2, nh = 4 / 11, eh = 6 / 11, rh = 8 / 11, ih = .75, oh = 9 / 11, uh = 10 / 11, ah = .9375, ch = 21 / 22, sh = 63 / 64, fh = 1 / nh / nh, lh = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return t * t * ((n + 1) * t - n); // NOSONAR
      } return n = +n, e.overshoot = t, e; // NOSONAR
    }(1.70158)), hh = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return --t * t * ((n + 1) * t + n) + 1; // NOSONAR
      } return n = +n, e.overshoot = t, e; // NOSONAR
    }(1.70158)), ph = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return ((t *= 2) < 1 ? t * t * ((n + 1) * t - n) : (t -= 2) * t * ((n + 1) * t + n) + 2) / 2; // NOSONAR
      } return n = +n, e.overshoot = t, e; // NOSONAR
    }(1.70158)), dh = 2 * Math.PI, vh = (function t(n, e) { // NOSONAR
      function r(t) { // NOSONAR
        return n * Math.pow(2, 10 * --t) * Math.sin((i - t) / e); // NOSONAR
      } var i = Math.asin(1 / (n = Math.max(1, n))) * (e /= dh); return r.amplitude = function(n) { // NOSONAR
        return t(n, e * dh); // NOSONAR
      }, r.period = function(e) { // NOSONAR
        return t(n, e); // NOSONAR
      }, r; // NOSONAR
    }(1, .3)), _h = (function t(n, e) { // NOSONAR
      function r(t) { // NOSONAR
        return 1 - n * Math.pow(2, -10 * (t = +t)) * Math.sin((t + i) / e); // NOSONAR
      } var i = Math.asin(1 / (n = Math.max(1, n))) * (e /= dh); return r.amplitude = function(n) { // NOSONAR
        return t(n, e * dh); // NOSONAR
      }, r.period = function(e) { // NOSONAR
        return t(n, e); // NOSONAR
      }, r; // NOSONAR
    }(1, .3)), gh = (function t(n, e) { // NOSONAR
      function r(t) { // NOSONAR
        return ((t = 2 * t - 1) < 0 ? n * Math.pow(2, 10 * t) * Math.sin((i - t) / e) : 2 - n * Math.pow(2, -10 * t) * Math.sin((i + t) / e)) / 2; // NOSONAR
      } var i = Math.asin(1 / (n = Math.max(1, n))) * (e /= dh); return r.amplitude = function(n) { // NOSONAR
        return t(n, e * dh); // NOSONAR
      }, r.period = function(e) { // NOSONAR
        return t(n, e); // NOSONAR
      }, r; // NOSONAR
    }(1, .3)), yh = {time: null, delay: 0, duration: 250, ease: te}; dt.prototype.interrupt = function(t) { // NOSONAR
    return this.each(function() { // NOSONAR
      Xl(this, t); // NOSONAR
    }); // NOSONAR
  }, dt.prototype.transition = function(t) { // NOSONAR
    var n, e; t instanceof Gn ? (n = t._id, t = t._name) : (n = Qn(), (e = yh).time = ln(), t = t == null ? null : t + ''); for (var r = this._groups, i = r.length, o = 0; o < i; ++o) { // NOSONAR
      for (var u, a = r[o], c = a.length, s = 0; s < c; ++s) { // NOSONAR
        (u = a[s]) && Hl(u, t, n, s, a, e || oe(u, n)); // NOSONAR
      } // NOSONAR
    } return new Gn(r, this._parents, t, n); // NOSONAR
  }; var mh = [ null ], xh = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, bh = function(t, n, e) { // NOSONAR
      this.target = t, this.type = n, this.selection = e; // NOSONAR
    }, wh = function() { // NOSONAR
      t.event.preventDefault(), t.event.stopImmediatePropagation(); // NOSONAR
    }, Mh = {name: 'drag'}, Th = {name: 'space'}, Nh = {name: 'handle'}, kh = {name: 'center'}, Sh = {name: 'x', handles: ['e', 'w'].map(ae), input: function(t, n) { // NOSONAR
      return t && [[t[0], n[0][1]], [t[1], n[1][1]]]; // NOSONAR
    }, output: function(t) { // NOSONAR
      return t && [t[0][0], t[1][0]]; // NOSONAR
    }}, Eh = {name: 'y', handles: ['n', 's'].map(ae), input: function(t, n) { // NOSONAR
      return t && [[n[0][0], t[0]], [n[1][0], t[1]]]; // NOSONAR
    }, output: function(t) { // NOSONAR
      return t && [t[0][1], t[1][1]]; // NOSONAR
    }}, Ah = {name: 'xy', handles: ['n', 'e', 's', 'w', 'nw', 'ne', 'se', 'sw'].map(ae), input: function(t) { // NOSONAR
      return t; // NOSONAR
    }, output: function(t) { // NOSONAR
      return t; // NOSONAR
    }}, Ch = {overlay: 'crosshair', selection: 'move', n: 'ns-resize', e: 'ew-resize', s: 'ns-resize', w: 'ew-resize', nw: 'nwse-resize', ne: 'nesw-resize', se: 'nwse-resize', sw: 'nesw-resize'}, zh = {e: 'w', w: 'e', nw: 'ne', ne: 'nw', se: 'sw', sw: 'se'}, Ph = {n: 's', s: 'n', nw: 'sw', ne: 'se', se: 'ne', sw: 'nw'}, Rh = {overlay: 1, selection: 1, n: null, e: 1, s: null, w: -1, nw: -1, ne: 1, se: 1, sw: -1}, Lh = {overlay: 1, selection: 1, n: -1, e: null, s: 1, w: null, nw: -1, ne: -1, se: 1, sw: 1}, qh = Math.cos, Uh = Math.sin, Dh = Math.PI, Oh = Dh / 2, Fh = 2 * Dh, Ih = Math.max, Yh = Array.prototype.slice, Bh = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, jh = Math.PI, Hh = 2 * jh, Xh = Hh - 1e-6; de.prototype = ve.prototype = {constructor: de, moveTo: function(t, n) { // NOSONAR
    this._ += 'M' + (this._x0 = this._x1 = +t) + ',' + (this._y0 = this._y1 = +n); // NOSONAR
  }, closePath: function() { // NOSONAR
    this._x1 !== null && (this._x1 = this._x0, this._y1 = this._y0, this._ += 'Z'); // NOSONAR
  }, lineTo: function(t, n) { // NOSONAR
    this._ += 'L' + (this._x1 = +t) + ',' + (this._y1 = +n); // NOSONAR
  }, quadraticCurveTo: function(t, n, e, r) { // NOSONAR
    this._ += 'Q' + +t + ',' + +n + ',' + (this._x1 = +e) + ',' + (this._y1 = +r); // NOSONAR
  }, bezierCurveTo: function(t, n, e, r, i, o) { // NOSONAR
    this._ += 'C' + +t + ',' + +n + ',' + +e + ',' + +r + ',' + (this._x1 = +i) + ',' + (this._y1 = +o); // NOSONAR
  }, arcTo: function(t, n, e, r, i) { // NOSONAR
    t = +t, n = +n, e = +e, r = +r, i = +i; var o = this._x1, u = this._y1, a = e - t, c = r - n, s = o - t, f = u - n, l = s * s + f * f; if (i < 0) { // NOSONAR
      throw new Error('negative radius: ' + i); // NOSONAR
    } if (this._x1 === null) { // NOSONAR
      this._ += 'M' + (this._x1 = t) + ',' + (this._y1 = n); // NOSONAR
    } else if (l > 1e-6) { // NOSONAR
      if (Math.abs(f * a - c * s) > 1e-6 && i) { // NOSONAR
        var h = e - o, p = r - u, d = a * a + c * c, v = h * h + p * p, _ = Math.sqrt(d), g = Math.sqrt(l), y = i * Math.tan((jh - Math.acos((d + l - v) / (2 * _ * g))) / 2), m = y / g, x = y / _; Math.abs(m - 1) > 1e-6 && (this._ += 'L' + (t + m * s) + ',' + (n + m * f)), this._ += 'A' + i + ',' + i + ',0,0,' + +(f * h > s * p) + ',' + (this._x1 = t + x * a) + ',' + (this._y1 = n + x * c); // NOSONAR
      } else { // NOSONAR
        this._ += 'L' + (this._x1 = t) + ',' + (this._y1 = n); // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
 // NOSONAR
    } // NOSONAR
  }, arc: function(t, n, e, r, i, o) { // NOSONAR
    t = +t, n = +n; var u = (e = +e) * Math.cos(r), a = e * Math.sin(r), c = t + u, s = n + a, f = 1 ^ o, l = o ? r - i : i - r; if (e < 0) { // NOSONAR
      throw new Error('negative radius: ' + e); // NOSONAR
    } this._x1 === null ? this._ += 'M' + c + ',' + s : (Math.abs(this._x1 - c) > 1e-6 || Math.abs(this._y1 - s) > 1e-6) && (this._ += 'L' + c + ',' + s), e && (l < 0 && (l = l % Hh + Hh), l > Xh ? this._ += 'A' + e + ',' + e + ',0,1,' + f + ',' + (t - u) + ',' + (n - a) + 'A' + e + ',' + e + ',0,1,' + f + ',' + (this._x1 = c) + ',' + (this._y1 = s) : l > 1e-6 && (this._ += 'A' + e + ',' + e + ',0,' + +(l >= jh) + ',' + f + ',' + (this._x1 = t + e * Math.cos(i)) + ',' + (this._y1 = n + e * Math.sin(i)))); // NOSONAR
  }, rect: function(t, n, e, r) { // NOSONAR
    this._ += 'M' + (this._x0 = this._x1 = +t) + ',' + (this._y0 = this._y1 = +n) + 'h' + +e + 'v' + +r + 'h' + -e + 'Z'; // NOSONAR
  }, toString: function() { // NOSONAR
    return this._; // NOSONAR
  }}; be.prototype = we.prototype = {constructor: be, has: function(t) { // NOSONAR
    return '$' + t in this; // NOSONAR
  }, get: function(t) { // NOSONAR
    return this['$' + t]; // NOSONAR
  }, set: function(t, n) { // NOSONAR
    return this['$' + t] = n, this; // NOSONAR
  }, remove: function(t) { // NOSONAR
    var n = '$' + t; return n in this && delete this[n]; // NOSONAR
  }, clear: function() { // NOSONAR
    for (var t in this) { // NOSONAR
      t[0] === '$' && delete this[t]; // NOSONAR
    } // NOSONAR
  }, keys: function() { // NOSONAR
    var t = []; for (var n in this) { // NOSONAR
      n[0] === '$' && t.push(n.slice(1)); // NOSONAR
    } return t; // NOSONAR
  }, values: function() { // NOSONAR
    var t = []; for (var n in this) { // NOSONAR
      n[0] === '$' && t.push(this[n]); // NOSONAR
    } return t; // NOSONAR
  }, entries: function() { // NOSONAR
    var t = []; for (var n in this) { // NOSONAR
      n[0] === '$' && t.push({key: n.slice(1), value: this[n]}); // NOSONAR
    } return t; // NOSONAR
  }, size: function() { // NOSONAR
    var t = 0; for (var n in this) { // NOSONAR
      n[0] === '$' && ++t; // NOSONAR
    } return t; // NOSONAR
  }, empty: function() { // NOSONAR
    for (var t in this) { // NOSONAR
      if (t[0] === '$') { // NOSONAR
        return !1; // NOSONAR
      } // NOSONAR
    } return !0; // NOSONAR
  }, each: function(t) { // NOSONAR
    for (var n in this) { // NOSONAR
      n[0] === '$' && t(this[n], n.slice(1), this); // NOSONAR
    } // NOSONAR
  }}; var $h = we.prototype; Se.prototype = Ee.prototype = {constructor: Se, has: $h.has, add: function(t) { // NOSONAR
    return t += '', this['$' + t] = t, this; // NOSONAR
  }, remove: $h.remove, clear: $h.clear, values: $h.keys, size: $h.size, empty: $h.empty, each: $h.each}; var Vh = {}, Wh = {}, Zh = 34, Gh = 10, Jh = 13, Qh = function(t) { // NOSONAR
      function n(t, n) { // NOSONAR
        function e() { // NOSONAR
          if (s) { // NOSONAR
            return Wh; // NOSONAR
          } if (f) { // NOSONAR
            return f = !1, Vh; // NOSONAR
          } var n, e, r = a; if (t.charCodeAt(r) === Zh) { // NOSONAR
            for (;a++ < u && t.charCodeAt(a) !== Zh || t.charCodeAt(++a) === Zh;) { // NOSONAR
 // NOSONAR
            } return (n = a) >= u ? s = !0 : (e = t.charCodeAt(a++)) === Gh ? f = !0 : e === Jh && (f = !0, t.charCodeAt(a) === Gh && ++a), t.slice(r + 1, n - 1).replace(/""/g, '"'); // NOSONAR
          } for (;a < u;) { // NOSONAR
            if ((e = t.charCodeAt(n = a++)) === Gh) { // NOSONAR
              f = !0; // NOSONAR
            } else if (e === Jh) { // NOSONAR
              f = !0, t.charCodeAt(a) === Gh && ++a; // NOSONAR
            } else if (e !== o) { // NOSONAR
              continue; // NOSONAR
            } return t.slice(r, n); // NOSONAR
          } return s = !0, t.slice(r, u); // NOSONAR
        } var r, i = [], u = t.length, a = 0, c = 0, s = u <= 0, f = !1; for (t.charCodeAt(u - 1) === Gh && --u, t.charCodeAt(u - 1) === Jh && --u; (r = e()) !== Wh;) { // NOSONAR
          for (var l = []; r !== Vh && r !== Wh;) { // NOSONAR
            l.push(r), r = e(); // NOSONAR
          }n && (l = n(l, c++)) == null || i.push(l); // NOSONAR
        } return i; // NOSONAR
      } function e(n) { // NOSONAR
        return n.map(r).join(t); // NOSONAR
      } function r(t) { // NOSONAR
        return t == null ? '' : i.test(t += '') ? '"' + t.replace(/"/g, '""') + '"' : t; // NOSONAR
      } var i = new RegExp('["' + t + '\n\r]'), o = t.charCodeAt(0); return {parse: function(t, e) { // NOSONAR
        var r, i, o = n(t, function(t, n) { // NOSONAR
          if (r) { // NOSONAR
            return r(t, n - 1); // NOSONAR
          } i = t, r = e ? Ce(t, e) : Ae(t); // NOSONAR
        }); return o.columns = i, o; // NOSONAR
      }, parseRows: n, format: function(n, e) { // NOSONAR
        return e == null && (e = ze(n)), [ e.map(r).join(t) ].concat(n.map(function(n) { // NOSONAR
          return e.map(function(t) { // NOSONAR
            return r(n[t]); // NOSONAR
          }).join(t); // NOSONAR
        })).join('\n'); // NOSONAR
      }, formatRows: function(t) { // NOSONAR
        return t.map(e).join('\n'); // NOSONAR
      }}; // NOSONAR
    }, Kh = Qh(','), tp = Kh.parse, np = Kh.parseRows, ep = Kh.format, rp = Kh.formatRows, ip = Qh('\t'), op = ip.parse, up = ip.parseRows, ap = ip.format, cp = ip.formatRows, sp = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, fp = function() { // NOSONAR
      return 1e-6 * (Math.random() - .5); // NOSONAR
    }, lp = function(t, n, e, r, i) { // NOSONAR
      this.node = t, this.x0 = n, this.y0 = e, this.x1 = r, this.y1 = i; // NOSONAR
    }, hp = qe.prototype = Ue.prototype; hp.copy = function() { // NOSONAR
    var t, n, e = new Ue(this._x, this._y, this._x0, this._y0, this._x1, this._y1), r = this._root; if (!r) { // NOSONAR
      return e; // NOSONAR
    } if (!r.length) { // NOSONAR
      return e._root = De(r), e; // NOSONAR
    } for (t = [ {source: r, target: e._root = new Array(4)} ]; r = t.pop();) { // NOSONAR
      for (var i = 0; i < 4; ++i) { // NOSONAR
        (n = r.source[i]) && (n.length ? t.push({source: n, target: r.target[i] = new Array(4)}) : r.target[i] = De(n)); // NOSONAR
      } // NOSONAR
    } return e; // NOSONAR
  }, hp.add = function(t) { // NOSONAR
    var n = +this._x.call(null, t), e = +this._y.call(null, t); return Pe(this.cover(n, e), n, e, t); // NOSONAR
  }, hp.addAll = function(t) { // NOSONAR
    var n, e, r, i, o = t.length, u = new Array(o), a = new Array(o), c = 1 / 0, s = 1 / 0, f = -1 / 0, l = -1 / 0; for (e = 0; e < o; ++e) { // NOSONAR
      isNaN(r = +this._x.call(null, n = t[e])) || isNaN(i = +this._y.call(null, n)) || (u[e] = r, a[e] = i, r < c && (c = r), r > f && (f = r), i < s && (s = i), i > l && (l = i)); // NOSONAR
    } for (f < c && (c = this._x0, f = this._x1), l < s && (s = this._y0, l = this._y1), this.cover(c, s).cover(f, l), e = 0; e < o; ++e) { // NOSONAR
      Pe(this, u[e], a[e], t[e]); // NOSONAR
    } return this; // NOSONAR
  }, hp.cover = function(t, n) { // NOSONAR
    if (isNaN(t = +t) || isNaN(n = +n)) { // NOSONAR
      return this; // NOSONAR
    } var e = this._x0, r = this._y0, i = this._x1, o = this._y1; if (isNaN(e)) { // NOSONAR
      i = (e = Math.floor(t)) + 1, o = (r = Math.floor(n)) + 1; // NOSONAR
    } else { // NOSONAR
      if (!(e > t || t > i || r > n || n > o)) { // NOSONAR
        return this; // NOSONAR
      } var u, a, c = i - e, s = this._root; switch (a = (n < (r + o) / 2) << 1 | t < (e + i) / 2) { // NOSONAR
        case 0:do { // NOSONAR
          u = new Array(4), u[a] = s, s = u; // NOSONAR
        } while (c *= 2, i = e + c, o = r + c, t > i || n > o);break; case 1:do { // NOSONAR
          u = new Array(4), u[a] = s, s = u; // NOSONAR
        } while (c *= 2, e = i - c, o = r + c, e > t || n > o);break; case 2:do { // NOSONAR
          u = new Array(4), u[a] = s, s = u; // NOSONAR
        } while (c *= 2, i = e + c, r = o - c, t > i || r > n);break; case 3:do { // NOSONAR
          u = new Array(4), u[a] = s, s = u; // NOSONAR
        } while (c *= 2, e = i - c, r = o - c, e > t || r > n); // NOSONAR
      } this._root && this._root.length && (this._root = s); // NOSONAR
    } return this._x0 = e, this._y0 = r, this._x1 = i, this._y1 = o, this; // NOSONAR
  }, hp.data = function() { // NOSONAR
    var t = []; return this.visit(function(n) { // NOSONAR
      if (!n.length) { // NOSONAR
        do { // NOSONAR
          t.push(n.data); // NOSONAR
        } while (n = n.next); // NOSONAR
      } // NOSONAR
    }), t; // NOSONAR
  }, hp.extent = function(t) { // NOSONAR
    return arguments.length ? this.cover(+t[0][0], +t[0][1]).cover(+t[1][0], +t[1][1]) : isNaN(this._x0) ? void 0 : [[this._x0, this._y0], [this._x1, this._y1]]; // NOSONAR
  }, hp.find = function(t, n, e) { // NOSONAR
    var r, i, o, u, a, c, s, f = this._x0, l = this._y0, h = this._x1, p = this._y1, d = [], v = this._root; for (v && d.push(new lp(v, f, l, h, p)), e == null ? e = 1 / 0 : (f = t - e, l = n - e, h = t + e, p = n + e, e *= e); c = d.pop();) { // NOSONAR
      if (!(!(v = c.node) || (i = c.x0) > h || (o = c.y0) > p || (u = c.x1) < f || (a = c.y1) < l)) { // NOSONAR
        if (v.length) { // NOSONAR
          var _ = (i + u) / 2, g = (o + a) / 2; d.push(new lp(v[3], _, g, u, a), new lp(v[2], i, g, _, a), new lp(v[1], _, o, u, g), new lp(v[0], i, o, _, g)), (s = (n >= g) << 1 | t >= _) && (c = d[d.length - 1], d[d.length - 1] = d[d.length - 1 - s], d[d.length - 1 - s] = c); // NOSONAR
        } else { // NOSONAR
          var y = t - +this._x.call(null, v.data), m = n - +this._y.call(null, v.data), x = y * y + m * m; if (x < e) { // NOSONAR
            var b = Math.sqrt(e = x); f = t - b, l = n - b, h = t + b, p = n + b, r = v.data; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return r; // NOSONAR
  }, hp.remove = function(t) { // NOSONAR
    if (isNaN(o = +this._x.call(null, t)) || isNaN(u = +this._y.call(null, t))) { // NOSONAR
      return this; // NOSONAR
    } var n, e, r, i, o, u, a, c, s, f, l, h, p = this._root, d = this._x0, v = this._y0, _ = this._x1, g = this._y1; if (!p) { // NOSONAR
      return this; // NOSONAR
    } if (p.length) { // NOSONAR
      for (;;) { // NOSONAR
        if ((s = o >= (a = (d + _) / 2)) ? d = a : _ = a, (f = u >= (c = (v + g) / 2)) ? v = c : g = c, n = p, !(p = p[l = f << 1 | s])) { // NOSONAR
          return this; // NOSONAR
        } if (!p.length) { // NOSONAR
          break; // NOSONAR
        } (n[l + 1 & 3] || n[l + 2 & 3] || n[l + 3 & 3]) && (e = n, h = l); // NOSONAR
      } // NOSONAR
    } for (;p.data !== t;) { // NOSONAR
      if (r = p, !(p = p.next)) { // NOSONAR
        return this; // NOSONAR
      } // NOSONAR
    } return (i = p.next) && delete p.next, r ? (i ? r.next = i : delete r.next, this) : n ? (i ? n[l] = i : delete n[l], (p = n[0] || n[1] || n[2] || n[3]) && p === (n[3] || n[2] || n[1] || n[0]) && !p.length && (e ? e[h] = p : this._root = p), this) : (this._root = i, this); // NOSONAR
  }, hp.removeAll = function(t) { // NOSONAR
    for (var n = 0, e = t.length; n < e; ++n) { // NOSONAR
      this.remove(t[n]); // NOSONAR
    } return this; // NOSONAR
  }, hp.root = function() { // NOSONAR
    return this._root; // NOSONAR
  }, hp.size = function() { // NOSONAR
    var t = 0; return this.visit(function(n) { // NOSONAR
      if (!n.length) { // NOSONAR
        do { // NOSONAR
          ++t; // NOSONAR
        } while (n = n.next); // NOSONAR
      } // NOSONAR
    }), t; // NOSONAR
  }, hp.visit = function(t) { // NOSONAR
    var n, e, r, i, o, u, a = [], c = this._root; for (c && a.push(new lp(c, this._x0, this._y0, this._x1, this._y1)); n = a.pop();) { // NOSONAR
      if (!t(c = n.node, r = n.x0, i = n.y0, o = n.x1, u = n.y1) && c.length) { // NOSONAR
        var s = (r + o) / 2, f = (i + u) / 2; (e = c[3]) && a.push(new lp(e, s, f, o, u)), (e = c[2]) && a.push(new lp(e, r, f, s, u)), (e = c[1]) && a.push(new lp(e, s, i, o, f)), (e = c[0]) && a.push(new lp(e, r, i, s, f)); // NOSONAR
      } // NOSONAR
    } return this; // NOSONAR
  }, hp.visitAfter = function(t) { // NOSONAR
    var n, e = [], r = []; for (this._root && e.push(new lp(this._root, this._x0, this._y0, this._x1, this._y1)); n = e.pop();) { // NOSONAR
      var i = n.node; if (i.length) { // NOSONAR
        var o, u = n.x0, a = n.y0, c = n.x1, s = n.y1, f = (u + c) / 2, l = (a + s) / 2; (o = i[0]) && e.push(new lp(o, u, a, f, l)), (o = i[1]) && e.push(new lp(o, f, a, c, l)), (o = i[2]) && e.push(new lp(o, u, l, f, s)), (o = i[3]) && e.push(new lp(o, f, l, c, s)); // NOSONAR
      }r.push(n); // NOSONAR
    } for (;n = r.pop();) { // NOSONAR
      t(n.node, n.x0, n.y0, n.x1, n.y1); // NOSONAR
    } return this; // NOSONAR
  }, hp.x = function(t) { // NOSONAR
    return arguments.length ? (this._x = t, this) : this._x; // NOSONAR
  }, hp.y = function(t) { // NOSONAR
    return arguments.length ? (this._y = t, this) : this._y; // NOSONAR
  }; var pp, dp = 10, vp = Math.PI * (3 - Math.sqrt(5)), _p = function(t, n) { // NOSONAR
      if ((e = (t = n ? t.toExponential(n - 1) : t.toExponential()).indexOf('e')) < 0) { // NOSONAR
        return null; // NOSONAR
      } var e, r = t.slice(0, e); return [r.length > 1 ? r[0] + r.slice(2) : r, +t.slice(e + 1)]; // NOSONAR
    }, gp = function(t) { // NOSONAR
      return (t = _p(Math.abs(t))) ? t[1] : NaN; // NOSONAR
    }, yp = function(t, n) { // NOSONAR
      return function(e, r) { // NOSONAR
        for (var i = e.length, o = [], u = 0, a = t[0], c = 0; i > 0 && a > 0 && (c + a + 1 > r && (a = Math.max(1, r - c)), o.push(e.substring(i -= a, i + a)), !((c += a + 1) > r));) { // NOSONAR
          a = t[u = (u + 1) % t.length]; // NOSONAR
        } return o.reverse().join(n); // NOSONAR
      }; // NOSONAR
    }, mp = function(t) { // NOSONAR
      return function(n) { // NOSONAR
        return n.replace(/[0-9]/g, function(n) { // NOSONAR
          return t[+n]; // NOSONAR
        }); // NOSONAR
      }; // NOSONAR
    }, xp = function(t, n) { // NOSONAR
      var e = _p(t, n); if (!e) { // NOSONAR
        return t + ''; // NOSONAR
      } var r = e[0], i = e[1]; return i < 0 ? '0.' + new Array(-i).join('0') + r : r.length > i + 1 ? r.slice(0, i + 1) + '.' + r.slice(i + 1) : r + new Array(i - r.length + 2).join('0'); // NOSONAR
    }, bp = {'': function(t, n) { // NOSONAR
      t:for (var e, r = (t = t.toPrecision(n)).length, i = 1, o = -1; i < r; ++i) { // NOSONAR
        switch (t[i]) { // NOSONAR
          case '.':o = e = i; break; case '0':o === 0 && (o = i), e = i; break; case 'e':break t; default:o > 0 && (o = 0); // NOSONAR
        } // NOSONAR
      } return o > 0 ? t.slice(0, o) + t.slice(e + 1) : t; // NOSONAR
    }, '%': function(t, n) { // NOSONAR
      return (100 * t).toFixed(n); // NOSONAR
    }, b: function(t) { // NOSONAR
      return Math.round(t).toString(2); // NOSONAR
    }, c: function(t) { // NOSONAR
      return t + ''; // NOSONAR
    }, d: function(t) { // NOSONAR
      return Math.round(t).toString(10); // NOSONAR
    }, e: function(t, n) { // NOSONAR
      return t.toExponential(n); // NOSONAR
    }, f: function(t, n) { // NOSONAR
      return t.toFixed(n); // NOSONAR
    }, g: function(t, n) { // NOSONAR
      return t.toPrecision(n); // NOSONAR
    }, o: function(t) { // NOSONAR
      return Math.round(t).toString(8); // NOSONAR
    }, p: function(t, n) { // NOSONAR
      return xp(100 * t, n); // NOSONAR
    }, r: xp, s: function(t, n) { // NOSONAR
      var e = _p(t, n); if (!e) { // NOSONAR
        return t + ''; // NOSONAR
      } var r = e[0], i = e[1], o = i - (pp = 3 * Math.max(-8, Math.min(8, Math.floor(i / 3)))) + 1, u = r.length; return o === u ? r : o > u ? r + new Array(o - u + 1).join('0') : o > 0 ? r.slice(0, o) + '.' + r.slice(o) : '0.' + new Array(1 - o).join('0') + _p(t, Math.max(0, n + o - 1))[0]; // NOSONAR
    }, X: function(t) { // NOSONAR
      return Math.round(t).toString(16).toUpperCase(); // NOSONAR
    }, x: function(t) { // NOSONAR
      return Math.round(t).toString(16); // NOSONAR
    }}, wp = /^(?:(.)?([<>=^]))?([+\-\( ])?([$#])?(0)?(\d+)?(,)?(\.\d+)?([a-z%])?$/i; He.prototype = Xe.prototype, Xe.prototype.toString = function() { // NOSONAR
    return this.fill + this.align + this.sign + this.symbol + (this.zero ? '0' : '') + (this.width == null ? '' : Math.max(1, 0 | this.width)) + (this.comma ? ',' : '') + (this.precision == null ? '' : '.' + Math.max(0, 0 | this.precision)) + this.type; // NOSONAR
  }; var Mp, Tp = function(t) { // NOSONAR
      return t; // NOSONAR
    }, Np = ['y', 'z', 'a', 'f', 'p', 'n', 'µ', 'm', '', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'], kp = function(t) { // NOSONAR
      function n(t) { // NOSONAR
        function n(t) { // NOSONAR
          var n, r, u, f = _, x = g; if (v === 'c') { // NOSONAR
            x = y(t) + x, t = ''; // NOSONAR
          } else { // NOSONAR
            var b = (t = +t) < 0; if (t = y(Math.abs(t), d), b && +t == 0 && (b = !1), f = (b ? s === '(' ? s : '-' : s === '-' || s === '(' ? '' : s) + f, x = x + (v === 's' ? Np[8 + pp / 3] : '') + (b && s === '(' ? ')' : ''), m) { // NOSONAR
              for (n = -1, r = t.length; ++n < r;) { // NOSONAR
                if ((u = t.charCodeAt(n)) < 48 || u > 57) { // NOSONAR
                  x = (u === 46 ? i + t.slice(n + 1) : t.slice(n)) + x, t = t.slice(0, n); break; // NOSONAR
                } // NOSONAR
              } // NOSONAR
            } // NOSONAR
          }p && !l && (t = e(t, 1 / 0)); var w = f.length + t.length + x.length, M = w < h ? new Array(h - w + 1).join(a) : ''; switch (p && l && (t = e(M + t, M.length ? h - x.length : 1 / 0), M = ''), c) { // NOSONAR
            case '<':t = f + t + x + M; break; case '=':t = f + M + t + x; break; case '^':t = M.slice(0, w = M.length >> 1) + f + t + x + M.slice(w); break; default:t = M + f + t + x; // NOSONAR
          } return o(t); // NOSONAR
        } var a = (t = He(t)).fill, c = t.align, s = t.sign, f = t.symbol, l = t.zero, h = t.width, p = t.comma, d = t.precision, v = t.type, _ = f === '$' ? r[0] : f === '#' && /[boxX]/.test(v) ? '0' + v.toLowerCase() : '', g = f === '$' ? r[1] : /[%p]/.test(v) ? u : '', y = bp[v], m = !v || /[defgprs%]/.test(v); return d = d == null ? v ? 6 : 12 : /[gprs]/.test(v) ? Math.max(1, Math.min(21, d)) : Math.max(0, Math.min(20, d)), n.toString = function() { // NOSONAR
          return t + ''; // NOSONAR
        }, n; // NOSONAR
      } var e = t.grouping && t.thousands ? yp(t.grouping, t.thousands) : Tp, r = t.currency, i = t.decimal, o = t.numerals ? mp(t.numerals) : Tp, u = t.percent || '%'; return {format: n, formatPrefix: function(t, e) { // NOSONAR
        var r = n((t = He(t), t.type = 'f', t)), i = 3 * Math.max(-8, Math.min(8, Math.floor(gp(e) / 3))), o = Math.pow(10, -i), u = Np[8 + i / 3]; return function(t) { // NOSONAR
          return r(o * t) + u; // NOSONAR
        }; // NOSONAR
      }}; // NOSONAR
    }; $e({decimal: '.', thousands: ',', grouping: [ 3 ], currency: ['$', '']}); var Sp = function(t) { // NOSONAR
      return Math.max(0, -gp(Math.abs(t))); // NOSONAR
    }, Ep = function(t, n) { // NOSONAR
      return Math.max(0, 3 * Math.max(-8, Math.min(8, Math.floor(gp(n) / 3))) - gp(Math.abs(t))); // NOSONAR
    }, Ap = function(t, n) { // NOSONAR
      return t = Math.abs(t), n = Math.abs(n) - t, Math.max(0, gp(n) - gp(t)) + 1; // NOSONAR
    }, Cp = function() { // NOSONAR
      return new Ve; // NOSONAR
    }; Ve.prototype = {constructor: Ve, reset: function() { // NOSONAR
    this.s = this.t = 0; // NOSONAR
  }, add: function(t) { // NOSONAR
    We(cd, t, this.t), We(this, cd.s, this.s), this.s ? this.t += cd.t : this.s = cd.t; // NOSONAR
  }, valueOf: function() { // NOSONAR
    return this.s; // NOSONAR
  }}; var zp, Pp, Rp, Lp, qp, Up, Dp, Op, Fp, Ip, Yp, Bp, jp, Hp, Xp, $p, Vp, Wp, Zp, Gp, Jp, Qp, Kp, td, nd, ed, rd, id, od, ud, ad, cd = new Ve, sd = 1e-6, fd = Math.PI, ld = fd / 2, hd = fd / 4, pd = 2 * fd, dd = 180 / fd, vd = fd / 180, _d = Math.abs, gd = Math.atan, yd = Math.atan2, md = Math.cos, xd = Math.ceil, bd = Math.exp, wd = Math.log, Md = Math.pow, Td = Math.sin, Nd = Math.sign || function(t) { // NOSONAR
      return t > 0 ? 1 : t < 0 ? -1 : 0; // NOSONAR
    }, kd = Math.sqrt, Sd = Math.tan, Ed = {Feature: function(t, n) { // NOSONAR
      Ke(t.geometry, n); // NOSONAR
    }, FeatureCollection: function(t, n) { // NOSONAR
      for (var e = t.features, r = -1, i = e.length; ++r < i;) { // NOSONAR
        Ke(e[r].geometry, n); // NOSONAR
      } // NOSONAR
    }}, Ad = {Sphere: function(t, n) { // NOSONAR
      n.sphere(); // NOSONAR
    }, Point: function(t, n) { // NOSONAR
      t = t.coordinates, n.point(t[0], t[1], t[2]); // NOSONAR
    }, MultiPoint: function(t, n) { // NOSONAR
      for (var e = t.coordinates, r = -1, i = e.length; ++r < i;) { // NOSONAR
        t = e[r], n.point(t[0], t[1], t[2]); // NOSONAR
      } // NOSONAR
    }, LineString: function(t, n) { // NOSONAR
      tr(t.coordinates, n, 0); // NOSONAR
    }, MultiLineString: function(t, n) { // NOSONAR
      for (var e = t.coordinates, r = -1, i = e.length; ++r < i;) { // NOSONAR
        tr(e[r], n, 0); // NOSONAR
      } // NOSONAR
    }, Polygon: function(t, n) { // NOSONAR
      nr(t.coordinates, n); // NOSONAR
    }, MultiPolygon: function(t, n) { // NOSONAR
      for (var e = t.coordinates, r = -1, i = e.length; ++r < i;) { // NOSONAR
        nr(e[r], n); // NOSONAR
      } // NOSONAR
    }, GeometryCollection: function(t, n) { // NOSONAR
      for (var e = t.geometries, r = -1, i = e.length; ++r < i;) { // NOSONAR
        Ke(e[r], n); // NOSONAR
      } // NOSONAR
    }}, Cd = function(t, n) { // NOSONAR
      t && Ed.hasOwnProperty(t.type) ? Ed[t.type](t, n) : Ke(t, n); // NOSONAR
    }, zd = Cp(), Pd = Cp(), Rd = {point: Qe, lineStart: Qe, lineEnd: Qe, polygonStart: function() { // NOSONAR
      zd.reset(), Rd.lineStart = er, Rd.lineEnd = rr; // NOSONAR
    }, polygonEnd: function() { // NOSONAR
      var t = +zd; Pd.add(t < 0 ? pd + t : t), this.lineStart = this.lineEnd = this.point = Qe; // NOSONAR
    }, sphere: function() { // NOSONAR
      Pd.add(pd); // NOSONAR
    }}, Ld = Cp(), qd = {point: pr, lineStart: vr, lineEnd: _r, polygonStart: function() { // NOSONAR
      qd.point = gr, qd.lineStart = yr, qd.lineEnd = mr, Ld.reset(), Rd.polygonStart(); // NOSONAR
    }, polygonEnd: function() { // NOSONAR
      Rd.polygonEnd(), qd.point = pr, qd.lineStart = vr, qd.lineEnd = _r, zd < 0 ? (Up = -(Op = 180), Dp = -(Fp = 90)) : Ld > sd ? Fp = 90 : Ld < -sd && (Dp = -90), Xp[0] = Up, Xp[1] = Op; // NOSONAR
    }}, Ud = {sphere: Qe, point: Mr, lineStart: Nr, lineEnd: Er, polygonStart: function() { // NOSONAR
      Ud.lineStart = Ar, Ud.lineEnd = Cr; // NOSONAR
    }, polygonEnd: function() { // NOSONAR
      Ud.lineStart = Nr, Ud.lineEnd = Er; // NOSONAR
    }}, Dd = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, Od = function(t, n) { // NOSONAR
      function e(e, r) { // NOSONAR
        return e = t(e, r), n(e[0], e[1]); // NOSONAR
      } return t.invert && n.invert && (e.invert = function(e, r) { // NOSONAR
        return (e = n.invert(e, r)) && t.invert(e[0], e[1]); // NOSONAR
      }), e; // NOSONAR
    }; Rr.invert = Rr; var Fd, Id, Yd, Bd, jd, Hd, Xd, $d, Vd, Wd, Zd, Gd = function(t) { // NOSONAR
      function n(n) { // NOSONAR
        return n = t(n[0] * vd, n[1] * vd), n[0] *= dd, n[1] *= dd, n; // NOSONAR
      } return t = Lr(t[0] * vd, t[1] * vd, t.length > 2 ? t[2] * vd : 0), n.invert = function(n) { // NOSONAR
        return n = t.invert(n[0] * vd, n[1] * vd), n[0] *= dd, n[1] *= dd, n; // NOSONAR
      }, n; // NOSONAR
    }, Jd = function() { // NOSONAR
      var t, n = []; return {point: function(n, e) { // NOSONAR
        t.push([n, e]); // NOSONAR
      }, lineStart: function() { // NOSONAR
        n.push(t = []); // NOSONAR
      }, lineEnd: Qe, rejoin: function() { // NOSONAR
        n.length > 1 && n.push(n.pop().concat(n.shift())); // NOSONAR
      }, result: function() { // NOSONAR
        var e = n; return n = [], t = null, e; // NOSONAR
      }}; // NOSONAR
    }, Qd = function(t, n) { // NOSONAR
      return _d(t[0] - n[0]) < sd && _d(t[1] - n[1]) < sd; // NOSONAR
    }, Kd = function(t, n, e, r, i) { // NOSONAR
      var o, u, a = [], c = []; if (t.forEach(function(t) { // NOSONAR
        if (!((n = t.length - 1) <= 0)) { // NOSONAR
          var n, e, r = t[0], u = t[n]; if (Qd(r, u)) { // NOSONAR
            for (i.lineStart(), o = 0; o < n; ++o) { // NOSONAR
              i.point((r = t[o])[0], r[1]); // NOSONAR
            }i.lineEnd(); // NOSONAR
          } else { // NOSONAR
            a.push(e = new Ir(r, t, null, !0)), c.push(e.o = new Ir(r, null, e, !1)), a.push(e = new Ir(u, t, null, !1)), c.push(e.o = new Ir(u, null, e, !0)); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }), a.length) { // NOSONAR
        for (c.sort(n), Yr(a), Yr(c), o = 0, u = c.length; o < u; ++o) { // NOSONAR
          c[o].e = e = !e; // NOSONAR
        } for (var s, f, l = a[0]; ;) { // NOSONAR
          for (var h = l, p = !0; h.v;) { // NOSONAR
            if ((h = h.n) === l) { // NOSONAR
              return; // NOSONAR
            } // NOSONAR
          } s = h.z, i.lineStart(); do { // NOSONAR
            if (h.v = h.o.v = !0, h.e) { // NOSONAR
              if (p) { // NOSONAR
                for (o = 0, u = s.length; o < u; ++o) { // NOSONAR
                  i.point((f = s[o])[0], f[1]); // NOSONAR
                } // NOSONAR
              } else { // NOSONAR
                r(h.x, h.n.x, 1, i); // NOSONAR
              }h = h.n; // NOSONAR
            } else { // NOSONAR
              if (p) { // NOSONAR
                for (s = h.p.z, o = s.length - 1; o >= 0; --o) { // NOSONAR
                  i.point((f = s[o])[0], f[1]); // NOSONAR
                } // NOSONAR
              } else { // NOSONAR
                r(h.x, h.p.x, -1, i); // NOSONAR
              }h = h.p; // NOSONAR
            }s = (h = h.o).z, p = !p; // NOSONAR
          } while (!h.v);i.lineEnd(); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    }, tv = Cp(), nv = function(t, n) { // NOSONAR
      var e = n[0], r = n[1], i = [Td(e), -md(e), 0], o = 0, u = 0; tv.reset(); for (var a = 0, c = t.length; a < c; ++a) { // NOSONAR
        if (f = (s = t[a]).length) { // NOSONAR
          for (var s, f, l = s[f - 1], h = l[0], p = l[1] / 2 + hd, d = Td(p), v = md(p), _ = 0; _ < f; ++_, h = y, d = x, v = b, l = g) { // NOSONAR
            var g = s[_], y = g[0], m = g[1] / 2 + hd, x = Td(m), b = md(m), w = y - h, M = w >= 0 ? 1 : -1, T = M * w, N = T > fd, k = d * x; if (tv.add(yd(k * M * Td(T), v * b + k * md(T))), o += N ? w + M * pd : w, N ^ h >= e ^ y >= e) { // NOSONAR
              var S = sr(ar(l), ar(g)); hr(S); var E = sr(i, S); hr(E); var A = (N ^ w >= 0 ? -1 : 1) * Ge(E[2]); (r > A || r === A && (S[0] || S[1])) && (u += N ^ w >= 0 ? 1 : -1); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } return (o < -sd || o < sd && tv < -sd) ^ 1 & u; // NOSONAR
    }, ev = function(t, n, e, r) { // NOSONAR
      return function(i) { // NOSONAR
        function o(n, e) { // NOSONAR
          t(n, e) && i.point(n, e); // NOSONAR
        } function u(t, n) { // NOSONAR
          v.point(t, n); // NOSONAR
        } function a() { // NOSONAR
          m.point = u, v.lineStart(); // NOSONAR
        } function c() { // NOSONAR
          m.point = o, v.lineEnd(); // NOSONAR
        } function s(t, n) { // NOSONAR
          d.push([t, n]), g.point(t, n); // NOSONAR
        } function f() { // NOSONAR
          g.lineStart(), d = []; // NOSONAR
        } function l() { // NOSONAR
          s(d[0][0], d[0][1]), g.lineEnd(); var t, n, e, r, o = g.clean(), u = _.result(), a = u.length; if (d.pop(), h.push(d), d = null, a) { // NOSONAR
            if (1 & o) { // NOSONAR
              if (e = u[0], (n = e.length - 1) > 0) { // NOSONAR
                for (y || (i.polygonStart(), y = !0), i.lineStart(), t = 0; t < n; ++t) { // NOSONAR
                  i.point((r = e[t])[0], r[1]); // NOSONAR
                }i.lineEnd(); // NOSONAR
              } // NOSONAR
            } else { // NOSONAR
              a > 1 && 2 & o && u.push(u.pop().concat(u.shift())), p.push(u.filter(Br)); // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } var h, p, d, v = n(i), _ = Jd(), g = n(_), y = !1, m = {point: o, lineStart: a, lineEnd: c, polygonStart: function() { // NOSONAR
          m.point = s, m.lineStart = f, m.lineEnd = l, p = [], h = []; // NOSONAR
        }, polygonEnd: function() { // NOSONAR
          m.point = o, m.lineStart = a, m.lineEnd = c, p = Ps(p); var t = nv(h, r); p.length ? (y || (i.polygonStart(), y = !0), Kd(p, jr, t, e, i)) : t && (y || (i.polygonStart(), y = !0), i.lineStart(), e(null, null, 1, i), i.lineEnd()), y && (i.polygonEnd(), y = !1), p = h = null; // NOSONAR
        }, sphere: function() { // NOSONAR
          i.polygonStart(), i.lineStart(), e(null, null, 1, i), i.lineEnd(), i.polygonEnd(); // NOSONAR
        }}; return m; // NOSONAR
      }; // NOSONAR
    }, rv = ev(function() { // NOSONAR
      return !0; // NOSONAR
    }, function(t) { // NOSONAR
      var n, e = NaN, r = NaN, i = NaN; return {lineStart: function() { // NOSONAR
        t.lineStart(), n = 1; // NOSONAR
      }, point: function(o, u) { // NOSONAR
        var a = o > 0 ? fd : -fd, c = _d(o - e); _d(c - fd) < sd ? (t.point(e, r = (r + u) / 2 > 0 ? ld : -ld), t.point(i, r), t.lineEnd(), t.lineStart(), t.point(a, r), t.point(o, r), n = 0) : i !== a && c >= fd && (_d(e - i) < sd && (e -= i * sd), _d(o - a) < sd && (o -= a * sd), r = Hr(e, r, o, u), t.point(i, r), t.lineEnd(), t.lineStart(), t.point(a, r), n = 0), t.point(e = o, r = u), i = a; // NOSONAR
      }, lineEnd: function() { // NOSONAR
        t.lineEnd(), e = r = NaN; // NOSONAR
      }, clean: function() { // NOSONAR
        return 2 - n; // NOSONAR
      }}; // NOSONAR
    }, function(t, n, e, r) { // NOSONAR
      var i; if (t == null) { // NOSONAR
        i = e * ld, r.point(-fd, i), r.point(0, i), r.point(fd, i), r.point(fd, 0), r.point(fd, -i), r.point(0, -i), r.point(-fd, -i), r.point(-fd, 0), r.point(-fd, i); // NOSONAR
      } else if (_d(t[0] - n[0]) > sd) { // NOSONAR
        var o = t[0] < n[0] ? fd : -fd; i = e * o / 2, r.point(-o, i), r.point(0, i), r.point(o, i); // NOSONAR
      } else { // NOSONAR
        r.point(n[0], n[1]); // NOSONAR
      } // NOSONAR
    }, [-fd, -ld]), iv = function(t) { // NOSONAR
      function n(t, n) { // NOSONAR
        return md(t) * md(n) > i; // NOSONAR
      } function e(t, n, e) { // NOSONAR
        var r = [1, 0, 0], o = sr(ar(t), ar(n)), u = cr(o, o), a = o[0], c = u - a * a; if (!c) { // NOSONAR
          return !e && t; // NOSONAR
        } var s = i * u / c, f = -i * a / c, l = sr(r, o), h = lr(r, s); fr(h, lr(o, f)); var p = l, d = cr(h, p), v = cr(p, p), _ = d * d - v * (cr(h, h) - 1); if (!(_ < 0)) { // NOSONAR
          var g = kd(_), y = lr(p, (-d - g) / v); if (fr(y, h), y = ur(y), !e) { // NOSONAR
            return y; // NOSONAR
          } var m, x = t[0], b = n[0], w = t[1], M = n[1]; b < x && (m = x, x = b, b = m); var T = b - x, N = _d(T - fd) < sd, k = N || T < sd; if (!N && M < w && (m = w, w = M, M = m), k ? N ? w + M > 0 ^ y[1] < (_d(y[0] - x) < sd ? w : M) : w <= y[1] && y[1] <= M : T > fd ^ (x <= y[0] && y[0] <= b)) { // NOSONAR
            var S = lr(p, (-d + g) / v); return fr(S, h), [y, ur(S)]; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } function r(n, e) { // NOSONAR
        var r = u ? t : fd - t, i = 0; return n < -r ? i |= 1 : n > r && (i |= 2), e < -r ? i |= 4 : e > r && (i |= 8), i; // NOSONAR
      } var i = md(t), o = 6 * vd, u = i > 0, a = _d(i) > sd; return ev(n, function(t) { // NOSONAR
        var i, o, c, s, f; return {lineStart: function() { // NOSONAR
          s = c = !1, f = 1; // NOSONAR
        }, point: function(l, h) { // NOSONAR
          var p, d = [l, h], v = n(l, h), _ = u ? v ? 0 : r(l, h) : v ? r(l + (l < 0 ? fd : -fd), h) : 0; if (!i && (s = c = v) && t.lineStart(), v !== c && (!(p = e(i, d)) || Qd(i, p) || Qd(d, p)) && (d[0] += sd, d[1] += sd, v = n(d[0], d[1])), v !== c) { // NOSONAR
            f = 0, v ? (t.lineStart(), p = e(d, i), t.point(p[0], p[1])) : (p = e(i, d), t.point(p[0], p[1]), t.lineEnd()), i = p; // NOSONAR
          } else if (a && i && u ^ v) { // NOSONAR
            var g; _ & o || !(g = e(d, i, !0)) || (f = 0, u ? (t.lineStart(), t.point(g[0][0], g[0][1]), t.point(g[1][0], g[1][1]), t.lineEnd()) : (t.point(g[1][0], g[1][1]), t.lineEnd(), t.lineStart(), t.point(g[0][0], g[0][1]))); // NOSONAR
          }!v || i && Qd(i, d) || t.point(d[0], d[1]), i = d, c = v, o = _; // NOSONAR
        }, lineEnd: function() { // NOSONAR
          c && t.lineEnd(), i = null; // NOSONAR
        }, clean: function() { // NOSONAR
          return f | (s && c) << 1; // NOSONAR
        }}; // NOSONAR
      }, function(n, e, r, i) { // NOSONAR
        Or(i, t, o, r, n, e); // NOSONAR
      }, u ? [0, -t] : [-fd, t - fd]); // NOSONAR
    }, ov = function(t, n, e, r, i, o) { // NOSONAR
      var u, a = t[0], c = t[1], s = 0, f = 1, l = n[0] - a, h = n[1] - c; if (u = e - a, l || !(u > 0)) { // NOSONAR
        if (u /= l, l < 0) { // NOSONAR
          if (u < s) { // NOSONAR
            return; // NOSONAR
          } u < f && (f = u); // NOSONAR
        } else if (l > 0) { // NOSONAR
          if (u > f) { // NOSONAR
            return; // NOSONAR
          } u > s && (s = u); // NOSONAR
        } if (u = i - a, l || !(u < 0)) { // NOSONAR
          if (u /= l, l < 0) { // NOSONAR
            if (u > f) { // NOSONAR
              return; // NOSONAR
            } u > s && (s = u); // NOSONAR
          } else if (l > 0) { // NOSONAR
            if (u < s) { // NOSONAR
              return; // NOSONAR
            } u < f && (f = u); // NOSONAR
          } if (u = r - c, h || !(u > 0)) { // NOSONAR
            if (u /= h, h < 0) { // NOSONAR
              if (u < s) { // NOSONAR
                return; // NOSONAR
              } u < f && (f = u); // NOSONAR
            } else if (h > 0) { // NOSONAR
              if (u > f) { // NOSONAR
                return; // NOSONAR
              } u > s && (s = u); // NOSONAR
            } if (u = o - c, h || !(u < 0)) { // NOSONAR
              if (u /= h, h < 0) { // NOSONAR
                if (u > f) { // NOSONAR
                  return; // NOSONAR
                } u > s && (s = u); // NOSONAR
              } else if (h > 0) { // NOSONAR
                if (u < s) { // NOSONAR
                  return; // NOSONAR
                } u < f && (f = u); // NOSONAR
              } return s > 0 && (t[0] = a + s * l, t[1] = c + s * h), f < 1 && (n[0] = a + f * l, n[1] = c + f * h), !0; // NOSONAR
            } // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    }, uv = 1e9, av = -uv, cv = Cp(), sv = {sphere: Qe, point: Qe, lineStart: function() { // NOSONAR
      sv.point = Vr, sv.lineEnd = $r; // NOSONAR
    }, lineEnd: Qe, polygonStart: Qe, polygonEnd: Qe}, fv = function(t) { // NOSONAR
      return cv.reset(), Cd(t, sv), +cv; // NOSONAR
    }, lv = [null, null], hv = {type: 'LineString', coordinates: lv}, pv = function(t, n) { // NOSONAR
      return lv[0] = t, lv[1] = n, fv(hv); // NOSONAR
    }, dv = {Feature: function(t, n) { // NOSONAR
      return Zr(t.geometry, n); // NOSONAR
    }, FeatureCollection: function(t, n) { // NOSONAR
      for (var e = t.features, r = -1, i = e.length; ++r < i;) { // NOSONAR
        if (Zr(e[r].geometry, n)) { // NOSONAR
          return !0; // NOSONAR
        } // NOSONAR
      } return !1; // NOSONAR
    }}, vv = {Sphere: function() { // NOSONAR
      return !0; // NOSONAR
    }, Point: function(t, n) { // NOSONAR
      return Gr(t.coordinates, n); // NOSONAR
    }, MultiPoint: function(t, n) { // NOSONAR
      for (var e = t.coordinates, r = -1, i = e.length; ++r < i;) { // NOSONAR
        if (Gr(e[r], n)) { // NOSONAR
          return !0; // NOSONAR
        } // NOSONAR
      } return !1; // NOSONAR
    }, LineString: function(t, n) { // NOSONAR
      return Jr(t.coordinates, n); // NOSONAR
    }, MultiLineString: function(t, n) { // NOSONAR
      for (var e = t.coordinates, r = -1, i = e.length; ++r < i;) { // NOSONAR
        if (Jr(e[r], n)) { // NOSONAR
          return !0; // NOSONAR
        } // NOSONAR
      } return !1; // NOSONAR
    }, Polygon: function(t, n) { // NOSONAR
      return Qr(t.coordinates, n); // NOSONAR
    }, MultiPolygon: function(t, n) { // NOSONAR
      for (var e = t.coordinates, r = -1, i = e.length; ++r < i;) { // NOSONAR
        if (Qr(e[r], n)) { // NOSONAR
          return !0; // NOSONAR
        } // NOSONAR
      } return !1; // NOSONAR
    }, GeometryCollection: function(t, n) { // NOSONAR
      for (var e = t.geometries, r = -1, i = e.length; ++r < i;) { // NOSONAR
        if (Zr(e[r], n)) { // NOSONAR
          return !0; // NOSONAR
        } // NOSONAR
      } return !1; // NOSONAR
    }}, _v = function(t) { // NOSONAR
      return t; // NOSONAR
    }, gv = Cp(), yv = Cp(), mv = {point: Qe, lineStart: Qe, lineEnd: Qe, polygonStart: function() { // NOSONAR
      mv.lineStart = ii, mv.lineEnd = ai; // NOSONAR
    }, polygonEnd: function() { // NOSONAR
      mv.lineStart = mv.lineEnd = mv.point = Qe, gv.add(_d(yv)), yv.reset(); // NOSONAR
    }, result: function() { // NOSONAR
      var t = gv / 2; return gv.reset(), t; // NOSONAR
    }}, xv = 1 / 0, bv = xv, wv = -xv, Mv = wv, Tv = {point: function(t, n) { // NOSONAR
      t < xv && (xv = t), t > wv && (wv = t), n < bv && (bv = n), n > Mv && (Mv = n); // NOSONAR
    }, lineStart: Qe, lineEnd: Qe, polygonStart: Qe, polygonEnd: Qe, result: function() { // NOSONAR
      var t = [[xv, bv], [wv, Mv]]; return wv = Mv = -(bv = xv = 1 / 0), t; // NOSONAR
    }}, Nv = 0, kv = 0, Sv = 0, Ev = 0, Av = 0, Cv = 0, zv = 0, Pv = 0, Rv = 0, Lv = {point: ci, lineStart: si, lineEnd: hi, polygonStart: function() { // NOSONAR
      Lv.lineStart = pi, Lv.lineEnd = di; // NOSONAR
    }, polygonEnd: function() { // NOSONAR
      Lv.point = ci, Lv.lineStart = si, Lv.lineEnd = hi; // NOSONAR
    }, result: function() { // NOSONAR
      var t = Rv ? [zv / Rv, Pv / Rv] : Cv ? [Ev / Cv, Av / Cv] : Sv ? [Nv / Sv, kv / Sv] : [NaN, NaN]; return Nv = kv = Sv = Ev = Av = Cv = zv = Pv = Rv = 0, t; // NOSONAR
    }}; gi.prototype = {_radius: 4.5, pointRadius: function(t) { // NOSONAR
    return this._radius = t, this; // NOSONAR
  }, polygonStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, polygonEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    this._line === 0 && this._context.closePath(), this._point = NaN; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (this._point) { // NOSONAR
      case 0:this._context.moveTo(t, n), this._point = 1; break; case 1:this._context.lineTo(t, n); break; default:this._context.moveTo(t + this._radius, n), this._context.arc(t, n, this._radius, 0, pd); // NOSONAR
    } // NOSONAR
  }, result: Qe}; var qv, Uv, Dv, Ov, Fv, Iv = Cp(), Yv = {point: Qe, lineStart: function() { // NOSONAR
    Yv.point = yi; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    qv && mi(Uv, Dv), Yv.point = Qe; // NOSONAR
  }, polygonStart: function() { // NOSONAR
    qv = !0; // NOSONAR
  }, polygonEnd: function() { // NOSONAR
    qv = null; // NOSONAR
  }, result: function() { // NOSONAR
    var t = +Iv; return Iv.reset(), t; // NOSONAR
  }}; xi.prototype = {_radius: 4.5, _circle: bi(4.5), pointRadius: function(t) { // NOSONAR
    return (t = +t) !== this._radius && (this._radius = t, this._circle = null), this; // NOSONAR
  }, polygonStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, polygonEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    this._line === 0 && this._string.push('Z'), this._point = NaN; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (this._point) { // NOSONAR
      case 0:this._string.push('M', t, ',', n), this._point = 1; break; case 1:this._string.push('L', t, ',', n); break; default:this._circle == null && (this._circle = bi(this._radius)), this._string.push('M', t, ',', n, this._circle); // NOSONAR
    } // NOSONAR
  }, result: function() { // NOSONAR
    if (this._string.length) { // NOSONAR
      var t = this._string.join(''); return this._string = [], t; // NOSONAR
    } return null; // NOSONAR
  }}; Mi.prototype = {constructor: Mi, point: function(t, n) { // NOSONAR
    this.stream.point(t, n); // NOSONAR
  }, sphere: function() { // NOSONAR
    this.stream.sphere(); // NOSONAR
  }, lineStart: function() { // NOSONAR
    this.stream.lineStart(); // NOSONAR
  }, lineEnd: function() { // NOSONAR
    this.stream.lineEnd(); // NOSONAR
  }, polygonStart: function() { // NOSONAR
    this.stream.polygonStart(); // NOSONAR
  }, polygonEnd: function() { // NOSONAR
    this.stream.polygonEnd(); // NOSONAR
  }}; var Bv = 16, jv = md(30 * vd), Hv = function(t, n) { // NOSONAR
      return +n ? Si(t, n) : ki(t); // NOSONAR
    }, Xv = wi({point: function(t, n) { // NOSONAR
      this.stream.point(t * vd, n * vd); // NOSONAR
    }}), $v = function() { // NOSONAR
      return zi(Ri).scale(155.424).center([0, 33.6442]); // NOSONAR
    }, Vv = function() { // NOSONAR
      return $v().parallels([29.5, 45.5]).scale(1070).translate([480, 250]).rotate([96, 0]).center([-.6, 38.7]); // NOSONAR
    }, Wv = qi(function(t) { // NOSONAR
      return kd(2 / (1 + t)); // NOSONAR
    }); Wv.invert = Ui(function(t) { // NOSONAR
    return 2 * Ge(t / 2); // NOSONAR
  }); var Zv = qi(function(t) { // NOSONAR
    return (t = Ze(t)) && t / Td(t); // NOSONAR
  }); Zv.invert = Ui(function(t) { // NOSONAR
    return t; // NOSONAR
  }); Di.invert = function(t, n) { // NOSONAR
    return [t, 2 * gd(bd(n)) - ld]; // NOSONAR
  }; Yi.invert = Yi; ji.invert = Ui(gd); Xi.invert = function(t, n) { // NOSONAR
    var e, r = n, i = 25; do { // NOSONAR
      var o = r * r, u = o * o; r -= e = (r * (1.007226 + o * (.015085 + u * (.028874 * o - .044475 - .005916 * u))) - n) / (1.007226 + o * (.045255 + u * (.259866 * o - .311325 - .005916 * 11 * u))); // NOSONAR
    } while (_d(e) > sd && --i > 0);return [t / (.8707 + (o = r * r) * (o * (o * o * o * (.003971 - .001529 * o) - .013791) - .131979)), r]; // NOSONAR
  }; $i.invert = Ui(Ge); Vi.invert = Ui(function(t) { // NOSONAR
    return 2 * gd(t); // NOSONAR
  }); Wi.invert = function(t, n) { // NOSONAR
    return [-n, 2 * gd(bd(t)) - ld]; // NOSONAR
  }; co.prototype = io.prototype = {constructor: co, count: function() { // NOSONAR
    return this.eachAfter(eo); // NOSONAR
  }, each: function(t) { // NOSONAR
    var n, e, r, i, o = this, u = [ o ]; do { // NOSONAR
      for (n = u.reverse(), u = []; o = n.pop();) { // NOSONAR
        if (t(o), e = o.children) { // NOSONAR
          for (r = 0, i = e.length; r < i; ++r) { // NOSONAR
            u.push(e[r]); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } while (u.length);return this; // NOSONAR
  }, eachAfter: function(t) { // NOSONAR
    for (var n, e, r, i = this, o = [ i ], u = []; i = o.pop();) { // NOSONAR
      if (u.push(i), n = i.children) { // NOSONAR
        for (e = 0, r = n.length; e < r; ++e) { // NOSONAR
          o.push(n[e]); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } for (;i = u.pop();) { // NOSONAR
      t(i); // NOSONAR
    } return this; // NOSONAR
  }, eachBefore: function(t) { // NOSONAR
    for (var n, e, r = this, i = [ r ]; r = i.pop();) { // NOSONAR
      if (t(r), n = r.children) { // NOSONAR
        for (e = n.length - 1; e >= 0; --e) { // NOSONAR
          i.push(n[e]); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return this; // NOSONAR
  }, sum: function(t) { // NOSONAR
    return this.eachAfter(function(n) { // NOSONAR
      for (var e = +t(n.data) || 0, r = n.children, i = r && r.length; --i >= 0;) { // NOSONAR
        e += r[i].value; // NOSONAR
      }n.value = e; // NOSONAR
    }); // NOSONAR
  }, sort: function(t) { // NOSONAR
    return this.eachBefore(function(n) { // NOSONAR
      n.children && n.children.sort(t); // NOSONAR
    }); // NOSONAR
  }, path: function(t) { // NOSONAR
    for (var n = this, e = ro(n, t), r = [ n ]; n !== e;) { // NOSONAR
      n = n.parent, r.push(n); // NOSONAR
    } for (var i = r.length; t !== e;) { // NOSONAR
      r.splice(i, 0, t), t = t.parent; // NOSONAR
    } return r; // NOSONAR
  }, ancestors: function() { // NOSONAR
    for (var t = this, n = [ t ]; t = t.parent;) { // NOSONAR
      n.push(t); // NOSONAR
    } return n; // NOSONAR
  }, descendants: function() { // NOSONAR
    var t = []; return this.each(function(n) { // NOSONAR
      t.push(n); // NOSONAR
    }), t; // NOSONAR
  }, leaves: function() { // NOSONAR
    var t = []; return this.eachBefore(function(n) { // NOSONAR
      n.children || t.push(n); // NOSONAR
    }), t; // NOSONAR
  }, links: function() { // NOSONAR
    var t = this, n = []; return t.each(function(e) { // NOSONAR
      e !== t && n.push({source: e.parent, target: e}); // NOSONAR
    }), n; // NOSONAR
  }, copy: function() { // NOSONAR
    return io(this).eachBefore(uo); // NOSONAR
  }}; var Gv = Array.prototype.slice, Jv = function(t) { // NOSONAR
      for (var n, e, r = 0, i = (t = so(Gv.call(t))).length, o = []; r < i;) { // NOSONAR
        n = t[r], e && ho(e, n) ? ++r : (e = vo(o = fo(o, n)), r = 0); // NOSONAR
      } return e; // NOSONAR
    }, Qv = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, Kv = function(t) { // NOSONAR
      t.x0 = Math.round(t.x0), t.y0 = Math.round(t.y0), t.x1 = Math.round(t.x1), t.y1 = Math.round(t.y1); // NOSONAR
    }, t_ = function(t, n, e, r, i) { // NOSONAR
      for (var o, u = t.children, a = -1, c = u.length, s = t.value && (r - n) / t.value; ++a < c;) { // NOSONAR
        (o = u[a]).y0 = e, o.y1 = i, o.x0 = n, o.x1 = n += o.value * s; // NOSONAR
      } // NOSONAR
    }, n_ = '$', e_ = {depth: -1}, r_ = {}; Fo.prototype = Object.create(co.prototype); var i_ = function(t, n, e, r, i) { // NOSONAR
      for (var o, u = t.children, a = -1, c = u.length, s = t.value && (i - e) / t.value; ++a < c;) { // NOSONAR
        (o = u[a]).x0 = n, o.x1 = r, o.y0 = e, o.y1 = e += o.value * s; // NOSONAR
      } // NOSONAR
    }, o_ = (1 + Math.sqrt(5)) / 2, u_ = (function t(n) { // NOSONAR
      function e(t, e, r, i, o) { // NOSONAR
        Yo(n, t, e, r, i, o); // NOSONAR
      } return e.ratio = function(n) { // NOSONAR
        return t((n = +n) > 1 ? n : 1); // NOSONAR
      }, e; // NOSONAR
    }(o_)), a_ = (function t(n) { // NOSONAR
      function e(t, e, r, i, o) { // NOSONAR
        if ((u = t._squarify) && u.ratio === n) { // NOSONAR
          for (var u, a, c, s, f, l = -1, h = u.length, p = t.value; ++l < h;) { // NOSONAR
            for (c = (a = u[l]).children, s = a.value = 0, f = c.length; s < f; ++s) { // NOSONAR
              a.value += c[s].value; // NOSONAR
            }a.dice ? t_(a, e, r, i, r += (o - r) * a.value / p) : i_(a, e, r, e += (i - e) * a.value / p, o), p -= a.value; // NOSONAR
          } // NOSONAR
        } else { // NOSONAR
          t._squarify = u = Yo(n, t, e, r, i, o), u.ratio = n; // NOSONAR
        } // NOSONAR
      } return e.ratio = function(n) { // NOSONAR
        return t((n = +n) > 1 ? n : 1); // NOSONAR
      }, e; // NOSONAR
    }(o_)), c_ = function(t, n, e) { // NOSONAR
      return (n[0] - t[0]) * (e[1] - t[1]) - (n[1] - t[1]) * (e[0] - t[0]); // NOSONAR
    }, s_ = [].slice, f_ = {}; Ho.prototype = Go.prototype = {constructor: Ho, defer: function(t) { // NOSONAR
    if (typeof t !== 'function') { // NOSONAR
      throw new Error('invalid callback'); // NOSONAR
    } if (this._call) { // NOSONAR
      throw new Error('defer after await'); // NOSONAR
    } if (this._error != null) { // NOSONAR
      return this; // NOSONAR
    } var n = s_.call(arguments, 1); return n.push(t), ++this._waiting, this._tasks.push(n), Xo(this), this; // NOSONAR
  }, abort: function() { // NOSONAR
    return this._error == null && Wo(this, new Error('abort')), this; // NOSONAR
  }, await: function(t) { // NOSONAR
    if (typeof t !== 'function') { // NOSONAR
      throw new Error('invalid callback'); // NOSONAR
    } if (this._call) { // NOSONAR
      throw new Error('multiple await'); // NOSONAR
    } return this._call = function(n, e) { // NOSONAR
      t.apply(null, [ n ].concat(e)); // NOSONAR
    }, Zo(this), this; // NOSONAR
  }, awaitAll: function(t) { // NOSONAR
    if (typeof t !== 'function') { // NOSONAR
      throw new Error('invalid callback'); // NOSONAR
    } if (this._call) { // NOSONAR
      throw new Error('multiple await'); // NOSONAR
    } return this._call = t, Zo(this), this; // NOSONAR
  }}; var l_ = function() { // NOSONAR
      return Math.random(); // NOSONAR
    }, h_ = (function t(n) { // NOSONAR
      function e(t, e) { // NOSONAR
        return t = t == null ? 0 : +t, e = e == null ? 1 : +e, arguments.length === 1 ? (e = t, t = 0) : e -= t, function() { // NOSONAR
          return n() * e + t; // NOSONAR
        }; // NOSONAR
      } return e.source = t, e; // NOSONAR
    }(l_)), p_ = (function t(n) { // NOSONAR
      function e(t, e) { // NOSONAR
        var r, i; return t = t == null ? 0 : +t, e = e == null ? 1 : +e, function() { // NOSONAR
          var o; if (r != null) { // NOSONAR
            o = r, r = null; // NOSONAR
          } else { // NOSONAR
            do { // NOSONAR
              r = 2 * n() - 1, o = 2 * n() - 1, i = r * r + o * o; // NOSONAR
            } while (!i || i > 1); // NOSONAR
          } return t + e * o * Math.sqrt(-2 * Math.log(i) / i); // NOSONAR
        }; // NOSONAR
      } return e.source = t, e; // NOSONAR
    }(l_)), d_ = (function t(n) { // NOSONAR
      function e() { // NOSONAR
        var t = p_.source(n).apply(this, arguments); return function() { // NOSONAR
          return Math.exp(t()); // NOSONAR
        }; // NOSONAR
      } return e.source = t, e; // NOSONAR
    }(l_)), v_ = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return function() { // NOSONAR
          for (var e = 0, r = 0; r < t; ++r) { // NOSONAR
            e += n(); // NOSONAR
          } return e; // NOSONAR
        }; // NOSONAR
      } return e.source = t, e; // NOSONAR
    }(l_)), __ = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        var e = v_.source(n)(t); return function() { // NOSONAR
          return e() / t; // NOSONAR
        }; // NOSONAR
      } return e.source = t, e; // NOSONAR
    }(l_)), g_ = (function t(n) { // NOSONAR
      function e(t) { // NOSONAR
        return function() { // NOSONAR
          return -Math.log(1 - n()) / t; // NOSONAR
        }; // NOSONAR
      } return e.source = t, e; // NOSONAR
    }(l_)), y_ = function(t, n) { // NOSONAR
      function e(t) { // NOSONAR
        var n, e = s.status; if (!e && Qo(s) || e >= 200 && e < 300 || e === 304) { // NOSONAR
          if (o) { // NOSONAR
            try { // NOSONAR
              n = o.call(r, s); // NOSONAR
            } catch (t) { // NOSONAR
              return void a.call('error', r, t); // NOSONAR
            } // NOSONAR
          } else { // NOSONAR
            n = s; // NOSONAR
          }a.call('load', r, n); // NOSONAR
        } else { // NOSONAR
          a.call('error', r, t); // NOSONAR
        } // NOSONAR
      } var r, i, o, u, a = h('beforesend', 'progress', 'load', 'error'), c = we(), s = new XMLHttpRequest, f = null, l = null, p = 0; if (typeof XDomainRequest === 'undefined' || 'withCredentials' in s || !/^(http(s)?:)?\/\//.test(t) || (s = new XDomainRequest), 'onload' in s ? s.onload = s.onerror = s.ontimeout = e : s.onreadystatechange = function(t) { // NOSONAR
        s.readyState > 3 && e(t); // NOSONAR
      }, s.onprogress = function(t) { // NOSONAR
          a.call('progress', r, t); // NOSONAR
        }, r = {header: function(t, n) { // NOSONAR
          return t = (t + '').toLowerCase(), arguments.length < 2 ? c.get(t) : (n == null ? c.remove(t) : c.set(t, n + ''), r); // NOSONAR
        }, mimeType: function(t) { // NOSONAR
          return arguments.length ? (i = t == null ? null : t + '', r) : i; // NOSONAR
        }, responseType: function(t) { // NOSONAR
          return arguments.length ? (u = t, r) : u; // NOSONAR
        }, timeout: function(t) { // NOSONAR
          return arguments.length ? (p = +t, r) : p; // NOSONAR
        }, user: function(t) { // NOSONAR
          return arguments.length < 1 ? f : (f = t == null ? null : t + '', r); // NOSONAR
        }, password: function(t) { // NOSONAR
          return arguments.length < 1 ? l : (l = t == null ? null : t + '', r); // NOSONAR
        }, response: function(t) { // NOSONAR
          return o = t, r; // NOSONAR
        }, get: function(t, n) { // NOSONAR
          return r.send('GET', t, n); // NOSONAR
        }, post: function(t, n) { // NOSONAR
          return r.send('POST', t, n); // NOSONAR
        }, send: function(n, e, o) { // NOSONAR
          return s.open(n, t, !0, f, l), i == null || c.has('accept') || c.set('accept', i + ',*/*'), s.setRequestHeader && c.each(function(t, n) { // NOSONAR
            s.setRequestHeader(n, t); // NOSONAR
          }), i != null && s.overrideMimeType && s.overrideMimeType(i), u != null && (s.responseType = u), p > 0 && (s.timeout = p), o == null && typeof e === 'function' && (o = e, e = null), o != null && o.length === 1 && (o = Jo(o)), o != null && r.on('error', o).on('load', function(t) { // NOSONAR
            o(null, t); // NOSONAR
          }), a.call('beforesend', r, s), s.send(e == null ? null : e), r; // NOSONAR
        }, abort: function() { // NOSONAR
          return s.abort(), r; // NOSONAR
        }, on: function() { // NOSONAR
          var t = a.on.apply(a, arguments); return t === a ? r : t; // NOSONAR
        }}, n != null) { // NOSONAR
        if (typeof n !== 'function') { // NOSONAR
          throw new Error('invalid callback: ' + n); // NOSONAR
        } return r.get(n); // NOSONAR
      } return r; // NOSONAR
    }, m_ = function(t, n) { // NOSONAR
      return function(e, r) { // NOSONAR
        var i = y_(e).mimeType(t).response(n); if (r != null) { // NOSONAR
          if (typeof r !== 'function') { // NOSONAR
            throw new Error('invalid callback: ' + r); // NOSONAR
          } return i.get(r); // NOSONAR
        } return i; // NOSONAR
      }; // NOSONAR
    }, x_ = m_('text/html', function(t) { // NOSONAR
      return document.createRange().createContextualFragment(t.responseText); // NOSONAR
    }), b_ = m_('application/json', function(t) { // NOSONAR
      return JSON.parse(t.responseText); // NOSONAR
    }), w_ = m_('text/plain', function(t) { // NOSONAR
      return t.responseText; // NOSONAR
    }), M_ = m_('application/xml', function(t) { // NOSONAR
      var n = t.responseXML; if (!n) { // NOSONAR
        throw new Error('parse error'); // NOSONAR
      } return n; // NOSONAR
    }), T_ = function(t, n) { // NOSONAR
      return function(e, r, i) { // NOSONAR
        arguments.length < 3 && (i = r, r = null); var o = y_(e).mimeType(t); return o.row = function(t) { // NOSONAR
          return arguments.length ? o.response(Ko(n, r = t)) : r; // NOSONAR
        }, o.row(r), i ? o.get(i) : o; // NOSONAR
      }; // NOSONAR
    }, N_ = T_('text/csv', tp), k_ = T_('text/tab-separated-values', op), S_ = Array.prototype, E_ = S_.map, A_ = S_.slice, C_ = {name: 'implicit'}, z_ = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, P_ = function(t) { // NOSONAR
      return +t; // NOSONAR
    }, R_ = [0, 1], L_ = function(n, e, r) { // NOSONAR
      var o, u = n[0], a = n[n.length - 1], c = i(u, a, e == null ? 10 : e); switch ((r = He(r == null ? ',f' : r)).type) { // NOSONAR
        case 's':var s = Math.max(Math.abs(u), Math.abs(a)); return r.precision != null || isNaN(o = Ep(c, s)) || (r.precision = o), t.formatPrefix(r, s); case '':case 'e':case 'g':case 'p':case 'r':r.precision != null || isNaN(o = Ap(c, Math.max(Math.abs(u), Math.abs(a)))) || (r.precision = o - (r.type === 'e')); break; case 'f':case '%':r.precision != null || isNaN(o = Sp(c)) || (r.precision = o - 2 * (r.type === '%')); // NOSONAR
      } return t.format(r); // NOSONAR
    }, q_ = function(t, n) { // NOSONAR
      var e, r = 0, i = (t = t.slice()).length - 1, o = t[r], u = t[i]; return u < o && (e = r, r = i, i = e, e = o, o = u, u = e), t[r] = n.floor(o), t[i] = n.ceil(u), t; // NOSONAR
    }, U_ = new Date, D_ = new Date, O_ = Nu(function() {}, function(t, n) { // NOSONAR
      t.setTime(+t + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return n - t; // NOSONAR
    }); O_.every = function(t) { // NOSONAR
    return t = Math.floor(t), isFinite(t) && t > 0 ? t > 1 ? Nu(function(n) { // NOSONAR
      n.setTime(Math.floor(n / t) * t); // NOSONAR
    }, function(n, e) { // NOSONAR
      n.setTime(+n + e * t); // NOSONAR
    }, function(n, e) { // NOSONAR
      return (e - n) / t; // NOSONAR
    }) : O_ : null; // NOSONAR
  }; var F_ = O_.range, I_ = 6e4, Y_ = 6048e5, B_ = Nu(function(t) { // NOSONAR
      t.setTime(1e3 * Math.floor(t / 1e3)); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setTime(+t + 1e3 * n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t) / 1e3; // NOSONAR
    }, function(t) { // NOSONAR
      return t.getUTCSeconds(); // NOSONAR
    }), j_ = B_.range, H_ = Nu(function(t) { // NOSONAR
      t.setTime(Math.floor(t / I_) * I_); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setTime(+t + n * I_); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t) / I_; // NOSONAR
    }, function(t) { // NOSONAR
      return t.getMinutes(); // NOSONAR
    }), X_ = H_.range, $_ = Nu(function(t) { // NOSONAR
      var n = t.getTimezoneOffset() * I_ % 36e5; n < 0 && (n += 36e5), t.setTime(36e5 * Math.floor((+t - n) / 36e5) + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setTime(+t + 36e5 * n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t) / 36e5; // NOSONAR
    }, function(t) { // NOSONAR
      return t.getHours(); // NOSONAR
    }), V_ = $_.range, W_ = Nu(function(t) { // NOSONAR
      t.setHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setDate(t.getDate() + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t - (n.getTimezoneOffset() - t.getTimezoneOffset()) * I_) / 864e5; // NOSONAR
    }, function(t) { // NOSONAR
      return t.getDate() - 1; // NOSONAR
    }), Z_ = W_.range, G_ = ku(0), J_ = ku(1), Q_ = ku(2), K_ = ku(3), tg = ku(4), ng = ku(5), eg = ku(6), rg = G_.range, ig = J_.range, og = Q_.range, ug = K_.range, ag = tg.range, cg = ng.range, sg = eg.range, fg = Nu(function(t) { // NOSONAR
      t.setDate(1), t.setHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setMonth(t.getMonth() + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return n.getMonth() - t.getMonth() + 12 * (n.getFullYear() - t.getFullYear()); // NOSONAR
    }, function(t) { // NOSONAR
      return t.getMonth(); // NOSONAR
    }), lg = fg.range, hg = Nu(function(t) { // NOSONAR
      t.setMonth(0, 1), t.setHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setFullYear(t.getFullYear() + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return n.getFullYear() - t.getFullYear(); // NOSONAR
    }, function(t) { // NOSONAR
      return t.getFullYear(); // NOSONAR
    }); hg.every = function(t) { // NOSONAR
    return isFinite(t = Math.floor(t)) && t > 0 ? Nu(function(n) { // NOSONAR
      n.setFullYear(Math.floor(n.getFullYear() / t) * t), n.setMonth(0, 1), n.setHours(0, 0, 0, 0); // NOSONAR
    }, function(n, e) { // NOSONAR
      n.setFullYear(n.getFullYear() + e * t); // NOSONAR
    }) : null; // NOSONAR
  }; var pg = hg.range, dg = Nu(function(t) { // NOSONAR
      t.setUTCSeconds(0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setTime(+t + n * I_); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t) / I_; // NOSONAR
    }, function(t) { // NOSONAR
      return t.getUTCMinutes(); // NOSONAR
    }), vg = dg.range, _g = Nu(function(t) { // NOSONAR
      t.setUTCMinutes(0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setTime(+t + 36e5 * n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t) / 36e5; // NOSONAR
    }, function(t) { // NOSONAR
      return t.getUTCHours(); // NOSONAR
    }), gg = _g.range, yg = Nu(function(t) { // NOSONAR
      t.setUTCHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setUTCDate(t.getUTCDate() + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return (n - t) / 864e5; // NOSONAR
    }, function(t) { // NOSONAR
      return t.getUTCDate() - 1; // NOSONAR
    }), mg = yg.range, xg = Su(0), bg = Su(1), wg = Su(2), Mg = Su(3), Tg = Su(4), Ng = Su(5), kg = Su(6), Sg = xg.range, Eg = bg.range, Ag = wg.range, Cg = Mg.range, zg = Tg.range, Pg = Ng.range, Rg = kg.range, Lg = Nu(function(t) { // NOSONAR
      t.setUTCDate(1), t.setUTCHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setUTCMonth(t.getUTCMonth() + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return n.getUTCMonth() - t.getUTCMonth() + 12 * (n.getUTCFullYear() - t.getUTCFullYear()); // NOSONAR
    }, function(t) { // NOSONAR
      return t.getUTCMonth(); // NOSONAR
    }), qg = Lg.range, Ug = Nu(function(t) { // NOSONAR
      t.setUTCMonth(0, 1), t.setUTCHours(0, 0, 0, 0); // NOSONAR
    }, function(t, n) { // NOSONAR
      t.setUTCFullYear(t.getUTCFullYear() + n); // NOSONAR
    }, function(t, n) { // NOSONAR
      return n.getUTCFullYear() - t.getUTCFullYear(); // NOSONAR
    }, function(t) { // NOSONAR
      return t.getUTCFullYear(); // NOSONAR
    }); Ug.every = function(t) { // NOSONAR
    return isFinite(t = Math.floor(t)) && t > 0 ? Nu(function(n) { // NOSONAR
      n.setUTCFullYear(Math.floor(n.getUTCFullYear() / t) * t), n.setUTCMonth(0, 1), n.setUTCHours(0, 0, 0, 0); // NOSONAR
    }, function(n, e) { // NOSONAR
      n.setUTCFullYear(n.getUTCFullYear() + e * t); // NOSONAR
    }) : null; // NOSONAR
  }; var Dg, Og = Ug.range, Fg = {'-': '', _: ' ', 0: '0'}, Ig = /^\s*\d+/, Yg = /^%/, Bg = /[\\\^\$\*\+\?\|\[\]\(\)\.\{\}]/g; Na({dateTime: '%x, %X', date: '%-m/%-d/%Y', time: '%-I:%M:%S %p', periods: ['AM', 'PM'], days: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'], shortDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'], months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'], shortMonths: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']}); var jg = Date.prototype.toISOString ? function(t) { // NOSONAR
      return t.toISOString(); // NOSONAR
    } : t.utcFormat('%Y-%m-%dT%H:%M:%S.%LZ'), Hg = +new Date('2000-01-01T00:00:00.000Z') ? function(t) { // NOSONAR
      var n = new Date(t); return isNaN(n) ? null : n; // NOSONAR
    } : t.utcParse('%Y-%m-%dT%H:%M:%S.%LZ'), Xg = 1e3, $g = 60 * Xg, Vg = 60 * $g, Wg = 24 * Vg, Zg = 7 * Wg, Gg = 30 * Wg, Jg = 365 * Wg, Qg = function(t) { // NOSONAR
      return t.match(/.{6}/g).map(function(t) { // NOSONAR
        return '#' + t; // NOSONAR
      }); // NOSONAR
    }, Kg = Qg('1f77b4ff7f0e2ca02cd627289467bd8c564be377c27f7f7fbcbd2217becf'), ty = Qg('393b795254a36b6ecf9c9ede6379398ca252b5cf6bcedb9c8c6d31bd9e39e7ba52e7cb94843c39ad494ad6616be7969c7b4173a55194ce6dbdde9ed6'), ny = Qg('3182bd6baed69ecae1c6dbefe6550dfd8d3cfdae6bfdd0a231a35474c476a1d99bc7e9c0756bb19e9ac8bcbddcdadaeb636363969696bdbdbdd9d9d9'), ey = Qg('1f77b4aec7e8ff7f0effbb782ca02c98df8ad62728ff98969467bdc5b0d58c564bc49c94e377c2f7b6d27f7f7fc7c7c7bcbd22dbdb8d17becf9edae5'), ry = Tl($t(300, .5, 0), $t(-240, .5, 1)), iy = Tl($t(-100, .75, .35), $t(80, 1.5, .8)), oy = Tl($t(260, .75, .35), $t(80, 1.5, .8)), uy = $t(), ay = Aa(Qg('44015444025645045745055946075a46085c460a5d460b5e470d60470e6147106347116447136548146748166848176948186a481a6c481b6d481c6e481d6f481f70482071482173482374482475482576482677482878482979472a7a472c7a472d7b472e7c472f7d46307e46327e46337f463480453581453781453882443983443a83443b84433d84433e85423f854240864241864142874144874045884046883f47883f48893e49893e4a893e4c8a3d4d8a3d4e8a3c4f8a3c508b3b518b3b528b3a538b3a548c39558c39568c38588c38598c375a8c375b8d365c8d365d8d355e8d355f8d34608d34618d33628d33638d32648e32658e31668e31678e31688e30698e306a8e2f6b8e2f6c8e2e6d8e2e6e8e2e6f8e2d708e2d718e2c718e2c728e2c738e2b748e2b758e2a768e2a778e2a788e29798e297a8e297b8e287c8e287d8e277e8e277f8e27808e26818e26828e26828e25838e25848e25858e24868e24878e23888e23898e238a8d228b8d228c8d228d8d218e8d218f8d21908d21918c20928c20928c20938c1f948c1f958b1f968b1f978b1f988b1f998a1f9a8a1e9b8a1e9c891e9d891f9e891f9f881fa0881fa1881fa1871fa28720a38620a48621a58521a68522a78522a88423a98324aa8325ab8225ac8226ad8127ad8128ae8029af7f2ab07f2cb17e2db27d2eb37c2fb47c31b57b32b67a34b67935b77937b87838b9773aba763bbb753dbc743fbc7340bd7242be7144bf7046c06f48c16e4ac16d4cc26c4ec36b50c46a52c56954c56856c66758c7655ac8645cc8635ec96260ca6063cb5f65cb5e67cc5c69cd5b6ccd5a6ece5870cf5773d05675d05477d1537ad1517cd2507fd34e81d34d84d44b86d54989d5488bd6468ed64590d74393d74195d84098d83e9bd93c9dd93ba0da39a2da37a5db36a8db34aadc32addc30b0dd2fb2dd2db5de2bb8de29bade28bddf26c0df25c2df23c5e021c8e020cae11fcde11dd0e11cd2e21bd5e21ad8e219dae319dde318dfe318e2e418e5e419e7e419eae51aece51befe51cf1e51df4e61ef6e620f8e621fbe723fde725')), cy = Aa(Qg('00000401000501010601010802010902020b02020d03030f03031204041405041606051806051a07061c08071e0907200a08220b09240c09260d0a290e0b2b100b2d110c2f120d31130d34140e36150e38160f3b180f3d19103f1a10421c10441d11471e114920114b21114e22115024125325125527125829115a2a115c2c115f2d11612f116331116533106734106936106b38106c390f6e3b0f703d0f713f0f72400f74420f75440f764510774710784910784a10794c117a4e117b4f127b51127c52137c54137d56147d57157e59157e5a167e5c167f5d177f5f187f601880621980641a80651a80671b80681c816a1c816b1d816d1d816e1e81701f81721f817320817521817621817822817922827b23827c23827e24828025828125818326818426818627818827818928818b29818c29818e2a81902a81912b81932b80942c80962c80982d80992d809b2e7f9c2e7f9e2f7fa02f7fa1307ea3307ea5317ea6317da8327daa337dab337cad347cae347bb0357bb2357bb3367ab5367ab73779b83779ba3878bc3978bd3977bf3a77c03a76c23b75c43c75c53c74c73d73c83e73ca3e72cc3f71cd4071cf4070d0416fd2426fd3436ed5446dd6456cd8456cd9466bdb476adc4869de4968df4a68e04c67e24d66e34e65e44f64e55064e75263e85362e95462ea5661eb5760ec5860ed5a5fee5b5eef5d5ef05f5ef1605df2625df2645cf3655cf4675cf4695cf56b5cf66c5cf66e5cf7705cf7725cf8745cf8765cf9785df9795df97b5dfa7d5efa7f5efa815ffb835ffb8560fb8761fc8961fc8a62fc8c63fc8e64fc9065fd9266fd9467fd9668fd9869fd9a6afd9b6bfe9d6cfe9f6dfea16efea36ffea571fea772fea973feaa74feac76feae77feb078feb27afeb47bfeb67cfeb77efeb97ffebb81febd82febf84fec185fec287fec488fec68afec88cfeca8dfecc8ffecd90fecf92fed194fed395fed597fed799fed89afdda9cfddc9efddea0fde0a1fde2a3fde3a5fde5a7fde7a9fde9aafdebacfcecaefceeb0fcf0b2fcf2b4fcf4b6fcf6b8fcf7b9fcf9bbfcfbbdfcfdbf')), sy = Aa(Qg('00000401000501010601010802010a02020c02020e03021004031204031405041706041907051b08051d09061f0a07220b07240c08260d08290e092b10092d110a30120a32140b34150b37160b39180c3c190c3e1b0c411c0c431e0c451f0c48210c4a230c4c240c4f260c51280b53290b552b0b572d0b592f0a5b310a5c320a5e340a5f3609613809623909633b09643d09653e0966400a67420a68440a68450a69470b6a490b6a4a0c6b4c0c6b4d0d6c4f0d6c510e6c520e6d540f6d550f6d57106e59106e5a116e5c126e5d126e5f136e61136e62146e64156e65156e67166e69166e6a176e6c186e6d186e6f196e71196e721a6e741a6e751b6e771c6d781c6d7a1d6d7c1d6d7d1e6d7f1e6c801f6c82206c84206b85216b87216b88226a8a226a8c23698d23698f24699025689225689326679526679727669827669a28659b29649d29649f2a63a02a63a22b62a32c61a52c60a62d60a82e5fa92e5eab2f5ead305dae305cb0315bb1325ab3325ab43359b63458b73557b93556ba3655bc3754bd3853bf3952c03a51c13a50c33b4fc43c4ec63d4dc73e4cc83f4bca404acb4149cc4248ce4347cf4446d04545d24644d34743d44842d54a41d74b3fd84c3ed94d3dda4e3cdb503bdd513ade5238df5337e05536e15635e25734e35933e45a31e55c30e65d2fe75e2ee8602de9612bea632aeb6429eb6628ec6726ed6925ee6a24ef6c23ef6e21f06f20f1711ff1731df2741cf3761bf37819f47918f57b17f57d15f67e14f68013f78212f78410f8850ff8870ef8890cf98b0bf98c0af98e09fa9008fa9207fa9407fb9606fb9706fb9906fb9b06fb9d07fc9f07fca108fca309fca50afca60cfca80dfcaa0ffcac11fcae12fcb014fcb216fcb418fbb61afbb81dfbba1ffbbc21fbbe23fac026fac228fac42afac62df9c72ff9c932f9cb35f8cd37f8cf3af7d13df7d340f6d543f6d746f5d949f5db4cf4dd4ff4df53f4e156f3e35af3e55df2e661f2e865f2ea69f1ec6df1ed71f1ef75f1f179f2f27df2f482f3f586f3f68af4f88ef5f992f6fa96f8fb9af9fc9dfafda1fcffa4')), fy = Aa(Qg('0d088710078813078916078a19068c1b068d1d068e20068f2206902406912605912805922a05932c05942e05952f059631059733059735049837049938049a3a049a3c049b3e049c3f049c41049d43039e44039e46039f48039f4903a04b03a14c02a14e02a25002a25102a35302a35502a45601a45801a45901a55b01a55c01a65e01a66001a66100a76300a76400a76600a76700a86900a86a00a86c00a86e00a86f00a87100a87201a87401a87501a87701a87801a87a02a87b02a87d03a87e03a88004a88104a78305a78405a78606a68707a68808a68a09a58b0aa58d0ba58e0ca48f0da4910ea3920fa39410a29511a19613a19814a099159f9a169f9c179e9d189d9e199da01a9ca11b9ba21d9aa31e9aa51f99a62098a72197a82296aa2395ab2494ac2694ad2793ae2892b02991b12a90b22b8fb32c8eb42e8db52f8cb6308bb7318ab83289ba3388bb3488bc3587bd3786be3885bf3984c03a83c13b82c23c81c33d80c43e7fc5407ec6417dc7427cc8437bc9447aca457acb4679cc4778cc4977cd4a76ce4b75cf4c74d04d73d14e72d24f71d35171d45270d5536fd5546ed6556dd7566cd8576bd9586ada5a6ada5b69db5c68dc5d67dd5e66de5f65de6164df6263e06363e16462e26561e26660e3685fe4695ee56a5de56b5de66c5ce76e5be76f5ae87059e97158e97257ea7457eb7556eb7655ec7754ed7953ed7a52ee7b51ef7c51ef7e50f07f4ff0804ef1814df1834cf2844bf3854bf3874af48849f48948f58b47f58c46f68d45f68f44f79044f79143f79342f89441f89540f9973ff9983ef99a3efa9b3dfa9c3cfa9e3bfb9f3afba139fba238fca338fca537fca636fca835fca934fdab33fdac33fdae32fdaf31fdb130fdb22ffdb42ffdb52efeb72dfeb82cfeba2cfebb2bfebd2afebe2afec029fdc229fdc328fdc527fdc627fdc827fdca26fdcb26fccd25fcce25fcd025fcd225fbd324fbd524fbd724fad824fada24f9dc24f9dd25f8df25f8e125f7e225f7e425f6e626f6e826f5e926f5eb27f4ed27f3ee27f3f027f2f227f1f426f1f525f0f724f0f921')), ly = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }, hy = Math.abs, py = Math.atan2, dy = Math.cos, vy = Math.max, _y = Math.min, gy = Math.sin, yy = Math.sqrt, my = 1e-12, xy = Math.PI, by = xy / 2, wy = 2 * xy; Ia.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1, this._line ? this._context.lineTo(t, n) : this._context.moveTo(t, n); break; case 1:this._point = 2; default:this._context.lineTo(t, n); // NOSONAR
    } // NOSONAR
  }}; var My = function(t) { // NOSONAR
      return new Ia(t); // NOSONAR
    }, Ty = function() { // NOSONAR
      function t(t) { // NOSONAR
        var a, c, s, f = t.length, l = !1; for (i == null && (u = o(s = ve())), a = 0; a <= f; ++a) { // NOSONAR
          !(a < f && r(c = t[a], a, t)) === l && ((l = !l) ? u.lineStart() : u.lineEnd()), l && u.point(+n(c, a, t), +e(c, a, t)); // NOSONAR
        } if (s) { // NOSONAR
          return u = null, s + '' || null; // NOSONAR
        } // NOSONAR
      } var n = Ya, e = Ba, r = ly(!0), i = null, o = My, u = null; return t.x = function(e) { // NOSONAR
        return arguments.length ? (n = typeof e === 'function' ? e : ly(+e), t) : n; // NOSONAR
      }, t.y = function(n) { // NOSONAR
        return arguments.length ? (e = typeof n === 'function' ? n : ly(+n), t) : e; // NOSONAR
      }, t.defined = function(n) { // NOSONAR
        return arguments.length ? (r = typeof n === 'function' ? n : ly(!!n), t) : r; // NOSONAR
      }, t.curve = function(n) { // NOSONAR
        return arguments.length ? (o = n, i != null && (u = o(i)), t) : o; // NOSONAR
      }, t.context = function(n) { // NOSONAR
        return arguments.length ? (n == null ? i = u = null : u = o(i = n), t) : i; // NOSONAR
      }, t; // NOSONAR
    }, Ny = function() { // NOSONAR
      function t(t) { // NOSONAR
        var n, f, l, h, p, d = t.length, v = !1, _ = new Array(d), g = new Array(d); for (a == null && (s = c(p = ve())), n = 0; n <= d; ++n) { // NOSONAR
          if (!(n < d && u(h = t[n], n, t)) === v) { // NOSONAR
            if (v = !v) { // NOSONAR
              f = n, s.areaStart(), s.lineStart(); // NOSONAR
            } else { // NOSONAR
              for (s.lineEnd(), s.lineStart(), l = n - 1; l >= f; --l) { // NOSONAR
                s.point(_[l], g[l]); // NOSONAR
              }s.lineEnd(), s.areaEnd(); // NOSONAR
            } // NOSONAR
          }v && (_[n] = +e(h, n, t), g[n] = +i(h, n, t), s.point(r ? +r(h, n, t) : _[n], o ? +o(h, n, t) : g[n])); // NOSONAR
        } if (p) { // NOSONAR
          return s = null, p + '' || null; // NOSONAR
        } // NOSONAR
      } function n() { // NOSONAR
        return Ty().defined(u).curve(c).context(a); // NOSONAR
      } var e = Ya, r = null, i = ly(0), o = Ba, u = ly(!0), a = null, c = My, s = null; return t.x = function(n) { // NOSONAR
        return arguments.length ? (e = typeof n === 'function' ? n : ly(+n), r = null, t) : e; // NOSONAR
      }, t.x0 = function(n) { // NOSONAR
        return arguments.length ? (e = typeof n === 'function' ? n : ly(+n), t) : e; // NOSONAR
      }, t.x1 = function(n) { // NOSONAR
        return arguments.length ? (r = n == null ? null : typeof n === 'function' ? n : ly(+n), t) : r; // NOSONAR
      }, t.y = function(n) { // NOSONAR
        return arguments.length ? (i = typeof n === 'function' ? n : ly(+n), o = null, t) : i; // NOSONAR
      }, t.y0 = function(n) { // NOSONAR
        return arguments.length ? (i = typeof n === 'function' ? n : ly(+n), t) : i; // NOSONAR
      }, t.y1 = function(n) { // NOSONAR
        return arguments.length ? (o = n == null ? null : typeof n === 'function' ? n : ly(+n), t) : o; // NOSONAR
      }, t.lineX0 = t.lineY0 = function() { // NOSONAR
        return n().x(e).y(i); // NOSONAR
      }, t.lineY1 = function() { // NOSONAR
        return n().x(e).y(o); // NOSONAR
      }, t.lineX1 = function() { // NOSONAR
        return n().x(r).y(i); // NOSONAR
      }, t.defined = function(n) { // NOSONAR
        return arguments.length ? (u = typeof n === 'function' ? n : ly(!!n), t) : u; // NOSONAR
      }, t.curve = function(n) { // NOSONAR
        return arguments.length ? (c = n, a != null && (s = c(a)), t) : c; // NOSONAR
      }, t.context = function(n) { // NOSONAR
        return arguments.length ? (n == null ? a = s = null : s = c(a = n), t) : a; // NOSONAR
      }, t; // NOSONAR
    }, ky = function(t, n) { // NOSONAR
      return n < t ? -1 : n > t ? 1 : n >= t ? 0 : NaN; // NOSONAR
    }, Sy = function(t) { // NOSONAR
      return t; // NOSONAR
    }, Ey = Ha(My); ja.prototype = {areaStart: function() { // NOSONAR
    this._curve.areaStart(); // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._curve.areaEnd(); // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._curve.lineStart(); // NOSONAR
  }, lineEnd: function() { // NOSONAR
    this._curve.lineEnd(); // NOSONAR
  }, point: function(t, n) { // NOSONAR
    this._curve.point(n * Math.sin(t), n * -Math.cos(t)); // NOSONAR
  }}; var Ay = function() { // NOSONAR
      return Xa(Ty().curve(Ey)); // NOSONAR
    }, Cy = function() { // NOSONAR
      var t = Ny().curve(Ey), n = t.curve, e = t.lineX0, r = t.lineX1, i = t.lineY0, o = t.lineY1; return t.angle = t.x, delete t.x, t.startAngle = t.x0, delete t.x0, t.endAngle = t.x1, delete t.x1, t.radius = t.y, delete t.y, t.innerRadius = t.y0, delete t.y0, t.outerRadius = t.y1, delete t.y1, t.lineStartAngle = function() { // NOSONAR
        return Xa(e()); // NOSONAR
      }, delete t.lineX0, t.lineEndAngle = function() { // NOSONAR
        return Xa(r()); // NOSONAR
      }, delete t.lineX1, t.lineInnerRadius = function() { // NOSONAR
        return Xa(i()); // NOSONAR
      }, delete t.lineY0, t.lineOuterRadius = function() { // NOSONAR
        return Xa(o()); // NOSONAR
      }, delete t.lineY1, t.curve = function(t) { // NOSONAR
        return arguments.length ? n(Ha(t)) : n()._curve; // NOSONAR
      }, t; // NOSONAR
    }, zy = function(t, n) { // NOSONAR
      return [(n = +n) * Math.cos(t -= Math.PI / 2), n * Math.sin(t)]; // NOSONAR
    }, Py = Array.prototype.slice, Ry = {draw: function(t, n) { // NOSONAR
      var e = Math.sqrt(n / xy); t.moveTo(e, 0), t.arc(0, 0, e, 0, wy); // NOSONAR
    }}, Ly = {draw: function(t, n) { // NOSONAR
      var e = Math.sqrt(n / 5) / 2; t.moveTo(-3 * e, -e), t.lineTo(-e, -e), t.lineTo(-e, -3 * e), t.lineTo(e, -3 * e), t.lineTo(e, -e), t.lineTo(3 * e, -e), t.lineTo(3 * e, e), t.lineTo(e, e), t.lineTo(e, 3 * e), t.lineTo(-e, 3 * e), t.lineTo(-e, e), t.lineTo(-3 * e, e), t.closePath(); // NOSONAR
    }}, qy = Math.sqrt(1 / 3), Uy = 2 * qy, Dy = {draw: function(t, n) { // NOSONAR
      var e = Math.sqrt(n / Uy), r = e * qy; t.moveTo(0, -e), t.lineTo(r, 0), t.lineTo(0, e), t.lineTo(-r, 0), t.closePath(); // NOSONAR
    }}, Oy = Math.sin(xy / 10) / Math.sin(7 * xy / 10), Fy = Math.sin(wy / 10) * Oy, Iy = -Math.cos(wy / 10) * Oy, Yy = {draw: function(t, n) { // NOSONAR
      var e = Math.sqrt(.8908130915292852 * n), r = Fy * e, i = Iy * e; t.moveTo(0, -e), t.lineTo(r, i); for (var o = 1; o < 5; ++o) { // NOSONAR
        var u = wy * o / 5, a = Math.cos(u), c = Math.sin(u); t.lineTo(c * e, -a * e), t.lineTo(a * r - c * i, c * r + a * i); // NOSONAR
      }t.closePath(); // NOSONAR
    }}, By = {draw: function(t, n) { // NOSONAR
      var e = Math.sqrt(n), r = -e / 2; t.rect(r, r, e, e); // NOSONAR
    }}, jy = Math.sqrt(3), Hy = {draw: function(t, n) { // NOSONAR
      var e = -Math.sqrt(n / (3 * jy)); t.moveTo(0, 2 * e), t.lineTo(-jy * e, -e), t.lineTo(jy * e, -e), t.closePath(); // NOSONAR
    }}, Xy = -.5, $y = Math.sqrt(3) / 2, Vy = 1 / Math.sqrt(12), Wy = 3 * (Vy / 2 + 1), Zy = {draw: function(t, n) { // NOSONAR
      var e = Math.sqrt(n / Wy), r = e / 2, i = e * Vy, o = r, u = e * Vy + e, a = -o, c = u; t.moveTo(r, i), t.lineTo(o, u), t.lineTo(a, c), t.lineTo(Xy * r - $y * i, $y * r + Xy * i), t.lineTo(Xy * o - $y * u, $y * o + Xy * u), t.lineTo(Xy * a - $y * c, $y * a + Xy * c), t.lineTo(Xy * r + $y * i, Xy * i - $y * r), t.lineTo(Xy * o + $y * u, Xy * u - $y * o), t.lineTo(Xy * a + $y * c, Xy * c - $y * a), t.closePath(); // NOSONAR
    }}, Gy = [Ry, Ly, Dy, By, Yy, Hy, Zy], Jy = function() {}; Ka.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._y0 = this._y1 = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    switch (this._point) { // NOSONAR
      case 3:Qa(this, this._x1, this._y1); case 2:this._context.lineTo(this._x1, this._y1); // NOSONAR
    }(this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1, this._line ? this._context.lineTo(t, n) : this._context.moveTo(t, n); break; case 1:this._point = 2; break; case 2:this._point = 3, this._context.lineTo((5 * this._x0 + this._x1) / 6, (5 * this._y0 + this._y1) / 6); default:Qa(this, t, n); // NOSONAR
    } this._x0 = this._x1, this._x1 = t, this._y0 = this._y1, this._y1 = n; // NOSONAR
  }}; tc.prototype = {areaStart: Jy, areaEnd: Jy, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._x2 = this._x3 = this._x4 = this._y0 = this._y1 = this._y2 = this._y3 = this._y4 = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    switch (this._point) { // NOSONAR
      case 1:this._context.moveTo(this._x2, this._y2), this._context.closePath(); break; case 2:this._context.moveTo((this._x2 + 2 * this._x3) / 3, (this._y2 + 2 * this._y3) / 3), this._context.lineTo((this._x3 + 2 * this._x2) / 3, (this._y3 + 2 * this._y2) / 3), this._context.closePath(); break; case 3:this.point(this._x2, this._y2), this.point(this._x3, this._y3), this.point(this._x4, this._y4); // NOSONAR
    } // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1, this._x2 = t, this._y2 = n; break; case 1:this._point = 2, this._x3 = t, this._y3 = n; break; case 2:this._point = 3, this._x4 = t, this._y4 = n, this._context.moveTo((this._x0 + 4 * this._x1 + t) / 6, (this._y0 + 4 * this._y1 + n) / 6); break; default:Qa(this, t, n); // NOSONAR
    } this._x0 = this._x1, this._x1 = t, this._y0 = this._y1, this._y1 = n; // NOSONAR
  }}; nc.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._y0 = this._y1 = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    (this._line || this._line !== 0 && this._point === 3) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1; break; case 1:this._point = 2; break; case 2:this._point = 3; var e = (this._x0 + 4 * this._x1 + t) / 6, r = (this._y0 + 4 * this._y1 + n) / 6; this._line ? this._context.lineTo(e, r) : this._context.moveTo(e, r); break; case 3:this._point = 4; default:Qa(this, t, n); // NOSONAR
    } this._x0 = this._x1, this._x1 = t, this._y0 = this._y1, this._y1 = n; // NOSONAR
  }}; ec.prototype = {lineStart: function() { // NOSONAR
    this._x = [], this._y = [], this._basis.lineStart(); // NOSONAR
  }, lineEnd: function() { // NOSONAR
    var t = this._x, n = this._y, e = t.length - 1; if (e > 0) { // NOSONAR
      for (var r, i = t[0], o = n[0], u = t[e] - i, a = n[e] - o, c = -1; ++c <= e;) { // NOSONAR
        r = c / e, this._basis.point(this._beta * t[c] + (1 - this._beta) * (i + r * u), this._beta * n[c] + (1 - this._beta) * (o + r * a)); // NOSONAR
      } // NOSONAR
    } this._x = this._y = null, this._basis.lineEnd(); // NOSONAR
  }, point: function(t, n) { // NOSONAR
    this._x.push(+t), this._y.push(+n); // NOSONAR
  }}; var Qy = (function t(n) { // NOSONAR
    function e(t) { // NOSONAR
      return n === 1 ? new Ka(t) : new ec(t, n); // NOSONAR
    } return e.beta = function(n) { // NOSONAR
      return t(+n); // NOSONAR
    }, e; // NOSONAR
  }(.85)); ic.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    switch (this._point) { // NOSONAR
      case 2:this._context.lineTo(this._x2, this._y2); break; case 3:rc(this, this._x1, this._y1); // NOSONAR
    }(this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1, this._line ? this._context.lineTo(t, n) : this._context.moveTo(t, n); break; case 1:this._point = 2, this._x1 = t, this._y1 = n; break; case 2:this._point = 3; default:rc(this, t, n); // NOSONAR
    } this._x0 = this._x1, this._x1 = this._x2, this._x2 = t, this._y0 = this._y1, this._y1 = this._y2, this._y2 = n; // NOSONAR
  }}; var Ky = (function t(n) { // NOSONAR
    function e(t) { // NOSONAR
      return new ic(t, n); // NOSONAR
    } return e.tension = function(n) { // NOSONAR
      return t(+n); // NOSONAR
    }, e; // NOSONAR
  }(0)); oc.prototype = {areaStart: Jy, areaEnd: Jy, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._x2 = this._x3 = this._x4 = this._x5 = this._y0 = this._y1 = this._y2 = this._y3 = this._y4 = this._y5 = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    switch (this._point) { // NOSONAR
      case 1:this._context.moveTo(this._x3, this._y3), this._context.closePath(); break; case 2:this._context.lineTo(this._x3, this._y3), this._context.closePath(); break; case 3:this.point(this._x3, this._y3), this.point(this._x4, this._y4), this.point(this._x5, this._y5); // NOSONAR
    } // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1, this._x3 = t, this._y3 = n; break; case 1:this._point = 2, this._context.moveTo(this._x4 = t, this._y4 = n); break; case 2:this._point = 3, this._x5 = t, this._y5 = n; break; default:rc(this, t, n); // NOSONAR
    } this._x0 = this._x1, this._x1 = this._x2, this._x2 = t, this._y0 = this._y1, this._y1 = this._y2, this._y2 = n; // NOSONAR
  }}; var tm = (function t(n) { // NOSONAR
    function e(t) { // NOSONAR
      return new oc(t, n); // NOSONAR
    } return e.tension = function(n) { // NOSONAR
      return t(+n); // NOSONAR
    }, e; // NOSONAR
  }(0)); uc.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    (this._line || this._line !== 0 && this._point === 3) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1; break; case 1:this._point = 2; break; case 2:this._point = 3, this._line ? this._context.lineTo(this._x2, this._y2) : this._context.moveTo(this._x2, this._y2); break; case 3:this._point = 4; default:rc(this, t, n); // NOSONAR
    } this._x0 = this._x1, this._x1 = this._x2, this._x2 = t, this._y0 = this._y1, this._y1 = this._y2, this._y2 = n; // NOSONAR
  }}; var nm = (function t(n) { // NOSONAR
    function e(t) { // NOSONAR
      return new uc(t, n); // NOSONAR
    } return e.tension = function(n) { // NOSONAR
      return t(+n); // NOSONAR
    }, e; // NOSONAR
  }(0)); cc.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._l01_a = this._l12_a = this._l23_a = this._l01_2a = this._l12_2a = this._l23_2a = this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    switch (this._point) { // NOSONAR
      case 2:this._context.lineTo(this._x2, this._y2); break; case 3:this.point(this._x2, this._y2); // NOSONAR
    }(this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    if (t = +t, n = +n, this._point) { // NOSONAR
      var e = this._x2 - t, r = this._y2 - n; this._l23_a = Math.sqrt(this._l23_2a = Math.pow(e * e + r * r, this._alpha)); // NOSONAR
    } switch (this._point) { // NOSONAR
      case 0:this._point = 1, this._line ? this._context.lineTo(t, n) : this._context.moveTo(t, n); break; case 1:this._point = 2; break; case 2:this._point = 3; default:ac(this, t, n); // NOSONAR
    } this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = t, this._y0 = this._y1, this._y1 = this._y2, this._y2 = n; // NOSONAR
  }}; var em = (function t(n) { // NOSONAR
    function e(t) { // NOSONAR
      return n ? new cc(t, n) : new ic(t, 0); // NOSONAR
    } return e.alpha = function(n) { // NOSONAR
      return t(+n); // NOSONAR
    }, e; // NOSONAR
  }(.5)); sc.prototype = {areaStart: Jy, areaEnd: Jy, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._x2 = this._x3 = this._x4 = this._x5 = this._y0 = this._y1 = this._y2 = this._y3 = this._y4 = this._y5 = NaN, this._l01_a = this._l12_a = this._l23_a = this._l01_2a = this._l12_2a = this._l23_2a = this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    switch (this._point) { // NOSONAR
      case 1:this._context.moveTo(this._x3, this._y3), this._context.closePath(); break; case 2:this._context.lineTo(this._x3, this._y3), this._context.closePath(); break; case 3:this.point(this._x3, this._y3), this.point(this._x4, this._y4), this.point(this._x5, this._y5); // NOSONAR
    } // NOSONAR
  }, point: function(t, n) { // NOSONAR
    if (t = +t, n = +n, this._point) { // NOSONAR
      var e = this._x2 - t, r = this._y2 - n; this._l23_a = Math.sqrt(this._l23_2a = Math.pow(e * e + r * r, this._alpha)); // NOSONAR
    } switch (this._point) { // NOSONAR
      case 0:this._point = 1, this._x3 = t, this._y3 = n; break; case 1:this._point = 2, this._context.moveTo(this._x4 = t, this._y4 = n); break; case 2:this._point = 3, this._x5 = t, this._y5 = n; break; default:ac(this, t, n); // NOSONAR
    } this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = t, this._y0 = this._y1, this._y1 = this._y2, this._y2 = n; // NOSONAR
  }}; var rm = (function t(n) { // NOSONAR
    function e(t) { // NOSONAR
      return n ? new sc(t, n) : new oc(t, 0); // NOSONAR
    } return e.alpha = function(n) { // NOSONAR
      return t(+n); // NOSONAR
    }, e; // NOSONAR
  }(.5)); fc.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN, this._l01_a = this._l12_a = this._l23_a = this._l01_2a = this._l12_2a = this._l23_2a = this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    (this._line || this._line !== 0 && this._point === 3) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    if (t = +t, n = +n, this._point) { // NOSONAR
      var e = this._x2 - t, r = this._y2 - n; this._l23_a = Math.sqrt(this._l23_2a = Math.pow(e * e + r * r, this._alpha)); // NOSONAR
    } switch (this._point) { // NOSONAR
      case 0:this._point = 1; break; case 1:this._point = 2; break; case 2:this._point = 3, this._line ? this._context.lineTo(this._x2, this._y2) : this._context.moveTo(this._x2, this._y2); break; case 3:this._point = 4; default:ac(this, t, n); // NOSONAR
    } this._l01_a = this._l12_a, this._l12_a = this._l23_a, this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a, this._x0 = this._x1, this._x1 = this._x2, this._x2 = t, this._y0 = this._y1, this._y1 = this._y2, this._y2 = n; // NOSONAR
  }}; var im = (function t(n) { // NOSONAR
    function e(t) { // NOSONAR
      return n ? new fc(t, n) : new uc(t, 0); // NOSONAR
    } return e.alpha = function(n) { // NOSONAR
      return t(+n); // NOSONAR
    }, e; // NOSONAR
  }(.5)); lc.prototype = {areaStart: Jy, areaEnd: Jy, lineStart: function() { // NOSONAR
    this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    this._point && this._context.closePath(); // NOSONAR
  }, point: function(t, n) { // NOSONAR
    t = +t, n = +n, this._point ? this._context.lineTo(t, n) : (this._point = 1, this._context.moveTo(t, n)); // NOSONAR
  }}; _c.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x0 = this._x1 = this._y0 = this._y1 = this._t0 = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    switch (this._point) { // NOSONAR
      case 2:this._context.lineTo(this._x1, this._y1); break; case 3:vc(this, this._t0, dc(this, this._t0)); // NOSONAR
    }(this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line = 1 - this._line; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    var e = NaN; if (t = +t, n = +n, t !== this._x1 || n !== this._y1) { // NOSONAR
      switch (this._point) { // NOSONAR
        case 0:this._point = 1, this._line ? this._context.lineTo(t, n) : this._context.moveTo(t, n); break; case 1:this._point = 2; break; case 2:this._point = 3, vc(this, dc(this, e = pc(this, t, n)), e); break; default:vc(this, this._t0, e = pc(this, t, n)); // NOSONAR
      } this._x0 = this._x1, this._x1 = t, this._y0 = this._y1, this._y1 = n, this._t0 = e; // NOSONAR
    } // NOSONAR
  }}, (gc.prototype = Object.create(_c.prototype)).point = function(t, n) { // NOSONAR
    _c.prototype.point.call(this, n, t); // NOSONAR
  }, yc.prototype = {moveTo: function(t, n) { // NOSONAR
    this._context.moveTo(n, t); // NOSONAR
  }, closePath: function() { // NOSONAR
    this._context.closePath(); // NOSONAR
  }, lineTo: function(t, n) { // NOSONAR
    this._context.lineTo(n, t); // NOSONAR
  }, bezierCurveTo: function(t, n, e, r, i, o) { // NOSONAR
    this._context.bezierCurveTo(n, t, r, e, o, i); // NOSONAR
  }}, mc.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x = [], this._y = []; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    var t = this._x, n = this._y, e = t.length; if (e) { // NOSONAR
      if (this._line ? this._context.lineTo(t[0], n[0]) : this._context.moveTo(t[0], n[0]), e === 2) { // NOSONAR
        this._context.lineTo(t[1], n[1]); // NOSONAR
      } else { // NOSONAR
        for (var r = xc(t), i = xc(n), o = 0, u = 1; u < e; ++o, ++u) { // NOSONAR
          this._context.bezierCurveTo(r[0][o], i[0][o], r[1][o], i[1][o], t[u], n[u]); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } (this._line || this._line !== 0 && e === 1) && this._context.closePath(), this._line = 1 - this._line, this._x = this._y = null; // NOSONAR
  }, point: function(t, n) { // NOSONAR
    this._x.push(+t), this._y.push(+n); // NOSONAR
  }}; bc.prototype = {areaStart: function() { // NOSONAR
    this._line = 0; // NOSONAR
  }, areaEnd: function() { // NOSONAR
    this._line = NaN; // NOSONAR
  }, lineStart: function() { // NOSONAR
    this._x = this._y = NaN, this._point = 0; // NOSONAR
  }, lineEnd: function() { // NOSONAR
    this._t > 0 && this._t < 1 && this._point === 2 && this._context.lineTo(this._x, this._y), (this._line || this._line !== 0 && this._point === 1) && this._context.closePath(), this._line >= 0 && (this._t = 1 - this._t, this._line = 1 - this._line); // NOSONAR
  }, point: function(t, n) { // NOSONAR
    switch (t = +t, n = +n, this._point) { // NOSONAR
      case 0:this._point = 1, this._line ? this._context.lineTo(t, n) : this._context.moveTo(t, n); break; case 1:this._point = 2; default:if (this._t <= 0) { // NOSONAR
        this._context.lineTo(this._x, n), this._context.lineTo(t, n); // NOSONAR
      } else { // NOSONAR
        var e = this._x * (1 - this._t) + t * this._t; this._context.lineTo(e, this._y), this._context.lineTo(e, n); // NOSONAR
      } // NOSONAR
    } this._x = t, this._y = n; // NOSONAR
  }}; var om = function(t, n) { // NOSONAR
      if ((i = t.length) > 1) { // NOSONAR
        for (var e, r, i, o = 1, u = t[n[0]], a = u.length; o < i; ++o) { // NOSONAR
          for (r = u, u = t[n[o]], e = 0; e < a; ++e) { // NOSONAR
            u[e][1] += u[e][0] = isNaN(r[e][1]) ? r[e][0] : r[e][1]; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    }, um = function(t) { // NOSONAR
      for (var n = t.length, e = new Array(n); --n >= 0;) { // NOSONAR
        e[n] = n; // NOSONAR
      } return e; // NOSONAR
    }, am = function(t) { // NOSONAR
      var n = t.map(Mc); return um(t).sort(function(t, e) { // NOSONAR
        return n[t] - n[e]; // NOSONAR
      }); // NOSONAR
    }, cm = function(t) { // NOSONAR
      return function() { // NOSONAR
        return t; // NOSONAR
      }; // NOSONAR
    }; kc.prototype = {constructor: kc, insert: function(t, n) { // NOSONAR
    var e, r, i; if (t) { // NOSONAR
      if (n.P = t, n.N = t.N, t.N && (t.N.P = n), t.N = n, t.R) { // NOSONAR
        for (t = t.R; t.L;) { // NOSONAR
          t = t.L; // NOSONAR
        }t.L = n; // NOSONAR
      } else { // NOSONAR
        t.R = n; // NOSONAR
      }e = t; // NOSONAR
    } else { // NOSONAR
      this._ ? (t = Cc(this._), n.P = null, n.N = t, t.P = t.L = n, e = t) : (n.P = n.N = null, this._ = n, e = null); // NOSONAR
    } for (n.L = n.R = null, n.U = e, n.C = !0, t = n; e && e.C;) { // NOSONAR
      e === (r = e.U).L ? (i = r.R) && i.C ? (e.C = i.C = !1, r.C = !0, t = r) : (t === e.R && (Ec(this, e), e = (t = e).U), e.C = !1, r.C = !0, Ac(this, r)) : (i = r.L) && i.C ? (e.C = i.C = !1, r.C = !0, t = r) : (t === e.L && (Ac(this, e), e = (t = e).U), e.C = !1, r.C = !0, Ec(this, r)), e = t.U; // NOSONAR
    } this._.C = !1; // NOSONAR
  }, remove: function(t) { // NOSONAR
    t.N && (t.N.P = t.P), t.P && (t.P.N = t.N), t.N = t.P = null; var n, e, r, i = t.U, o = t.L, u = t.R; if (e = o ? u ? Cc(u) : o : u, i ? i.L === t ? i.L = e : i.R = e : this._ = e, o && u ? (r = e.C, e.C = t.C, e.L = o, o.U = e, e !== u ? (i = e.U, e.U = t.U, t = e.R, i.L = t, e.R = u, u.U = e) : (e.U = i, i = e, t = e.R)) : (r = t.C, t = e), t && (t.U = i), !r) { // NOSONAR
      if (t && t.C) { // NOSONAR
        t.C = !1; // NOSONAR
      } else { // NOSONAR
        do { // NOSONAR
          if (t === this._) { // NOSONAR
            break; // NOSONAR
          } if (t === i.L) { // NOSONAR
            if ((n = i.R).C && (n.C = !1, i.C = !0, Ec(this, i), n = i.R), n.L && n.L.C || n.R && n.R.C) { // NOSONAR
              n.R && n.R.C || (n.L.C = !1, n.C = !0, Ac(this, n), n = i.R), n.C = i.C, i.C = n.R.C = !1, Ec(this, i), t = this._; break; // NOSONAR
            } // NOSONAR
          } else if ((n = i.L).C && (n.C = !1, i.C = !0, Ac(this, i), n = i.L), n.L && n.L.C || n.R && n.R.C) { // NOSONAR
            n.L && n.L.C || (n.R.C = !1, n.C = !0, Ec(this, n), n = i.L), n.C = i.C, i.C = n.L.C = !1, Ac(this, i), t = this._; break; // NOSONAR
          }n.C = !0, t = i, i = i.U; // NOSONAR
        } while (!t.C);t && (t.C = !1); // NOSONAR
      } // NOSONAR
    } // NOSONAR
  }}; var sm, fm, lm, hm, pm, dm = [], vm = [], _m = 1e-6, gm = 1e-12; ns.prototype = {constructor: ns, polygons: function() { // NOSONAR
    var t = this.edges; return this.cells.map(function(n) { // NOSONAR
      var e = n.halfedges.map(function(e) { // NOSONAR
        return Fc(n, t[e]); // NOSONAR
      }); return e.data = n.site.data, e; // NOSONAR
    }); // NOSONAR
  }, triangles: function() { // NOSONAR
    var t = [], n = this.edges; return this.cells.forEach(function(e, r) { // NOSONAR
      if (o = (i = e.halfedges).length) { // NOSONAR
        for (var i, o, u, a = e.site, c = -1, s = n[i[o - 1]], f = s.left === a ? s.right : s.left; ++c < o;) { // NOSONAR
          u = f, f = (s = n[i[c]]).left === a ? s.right : s.left, u && f && r < u.index && r < f.index && Kc(a, u, f) < 0 && t.push([a.data, u.data, f.data]); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    }), t; // NOSONAR
  }, links: function() { // NOSONAR
    return this.edges.filter(function(t) { // NOSONAR
      return t.right; // NOSONAR
    }).map(function(t) { // NOSONAR
      return {source: t.left.data, target: t.right.data}; // NOSONAR
    }); // NOSONAR
  }, find: function(t, n, e) { // NOSONAR
    for (var r, i, o = this, u = o._found || 0, a = o.cells.length; !(i = o.cells[u]);) { // NOSONAR
      if (++u >= a) { // NOSONAR
        return null; // NOSONAR
      } // NOSONAR
    } var c = t - i.site[0], s = n - i.site[1], f = c * c + s * s; do { // NOSONAR
      i = o.cells[r = u], u = null, i.halfedges.forEach(function(e) { // NOSONAR
        var r = o.edges[e], a = r.left; if (a !== i.site && a || (a = r.right)) { // NOSONAR
          var c = t - a[0], s = n - a[1], l = c * c + s * s; l < f && (f = l, u = a.index); // NOSONAR
        } // NOSONAR
      }); // NOSONAR
    } while (u !== null);return o._found = r, e == null || f <= e * e ? i.site : null; // NOSONAR
  }}; var ym = function(t) { // NOSONAR
    return function() { // NOSONAR
      return t; // NOSONAR
    }; // NOSONAR
  }; rs.prototype = {constructor: rs, scale: function(t) { // NOSONAR
    return t === 1 ? this : new rs(this.k * t, this.x, this.y); // NOSONAR
  }, translate: function(t, n) { // NOSONAR
    return t === 0 & n === 0 ? this : new rs(this.k, this.x + this.k * t, this.y + this.k * n); // NOSONAR
  }, apply: function(t) { // NOSONAR
    return [t[0] * this.k + this.x, t[1] * this.k + this.y]; // NOSONAR
  }, applyX: function(t) { // NOSONAR
    return t * this.k + this.x; // NOSONAR
  }, applyY: function(t) { // NOSONAR
    return t * this.k + this.y; // NOSONAR
  }, invert: function(t) { // NOSONAR
    return [(t[0] - this.x) / this.k, (t[1] - this.y) / this.k]; // NOSONAR
  }, invertX: function(t) { // NOSONAR
    return (t - this.x) / this.k; // NOSONAR
  }, invertY: function(t) { // NOSONAR
    return (t - this.y) / this.k; // NOSONAR
  }, rescaleX: function(t) { // NOSONAR
    return t.copy().domain(t.range().map(this.invertX, this).map(t.invert, t)); // NOSONAR
  }, rescaleY: function(t) { // NOSONAR
    return t.copy().domain(t.range().map(this.invertY, this).map(t.invert, t)); // NOSONAR
  }, toString: function() { // NOSONAR
    return 'translate(' + this.x + ',' + this.y + ') scale(' + this.k + ')'; // NOSONAR
  }}; var mm = new rs(1, 0, 0); is.prototype = rs.prototype; var xm = function() { // NOSONAR
    t.event.preventDefault(), t.event.stopImmediatePropagation(); // NOSONAR
  }; t.version = '4.11.0', t.bisect = ds, t.bisectRight = ds, t.bisectLeft = vs, t.ascending = ls, t.bisector = hs, t.cross = function(t, n, r) { // NOSONAR
    var i, o, u, a, c = t.length, s = n.length, f = new Array(c * s); for (r == null && (r = e), i = u = 0; i < c; ++i) { // NOSONAR
      for (a = t[i], o = 0; o < s; ++o, ++u) { // NOSONAR
        f[u] = r(a, n[o]); // NOSONAR
      } // NOSONAR
    } return f; // NOSONAR
  }, t.descending = function(t, n) { // NOSONAR
    return n < t ? -1 : n > t ? 1 : n >= t ? 0 : NaN; // NOSONAR
  }, t.deviation = ys, t.extent = ms, t.histogram = function() { // NOSONAR
    function t(t) { // NOSONAR
      var o, u, a = t.length, c = new Array(a); for (o = 0; o < a; ++o) { // NOSONAR
        c[o] = n(t[o], o, t); // NOSONAR
      } var s = e(c), f = s[0], l = s[1], h = r(c, f, l); Array.isArray(h) || (h = i(f, l, h), h = Ns(Math.ceil(f / h) * h, Math.floor(l / h) * h, h)); for (var p = h.length; h[0] <= f;) { // NOSONAR
        h.shift(), --p; // NOSONAR
      } for (;h[p - 1] > l;) { // NOSONAR
        h.pop(), --p; // NOSONAR
      } var d, v = new Array(p + 1); for (o = 0; o <= p; ++o) { // NOSONAR
        (d = v[o] = []).x0 = o > 0 ? h[o - 1] : f, d.x1 = o < p ? h[o] : l; // NOSONAR
      } for (o = 0; o < a; ++o) { // NOSONAR
        f <= (u = c[o]) && u <= l && v[ds(h, u, 0, p)].push(t[o]); // NOSONAR
      } return v; // NOSONAR
    } var n = Ts, e = ms, r = Cs; return t.value = function(e) { // NOSONAR
      return arguments.length ? (n = typeof e === 'function' ? e : Ms(e), t) : n; // NOSONAR
    }, t.domain = function(n) { // NOSONAR
      return arguments.length ? (e = typeof n === 'function' ? n : Ms([n[0], n[1]]), t) : e; // NOSONAR
    }, t.thresholds = function(n) { // NOSONAR
      return arguments.length ? (r = typeof n === 'function' ? n : Ms(Array.isArray(n) ? bs.call(n) : n), t) : r; // NOSONAR
    }, t; // NOSONAR
  }, t.thresholdFreedmanDiaconis = function(t, n, e) { // NOSONAR
    return t = ws.call(t, _s).sort(ls), Math.ceil((e - n) / (2 * (zs(t, .75) - zs(t, .25)) * Math.pow(t.length, -1 / 3))); // NOSONAR
  }, t.thresholdScott = function(t, n, e) { // NOSONAR
    return Math.ceil((e - n) / (3.5 * ys(t) * Math.pow(t.length, -1 / 3))); // NOSONAR
  }, t.thresholdSturges = Cs, t.max = function(t, n) { // NOSONAR
    var e, r, i = t.length, o = -1; if (n == null) { // NOSONAR
      for (;++o < i;) { // NOSONAR
        if ((e = t[o]) != null && e >= e) { // NOSONAR
          for (r = e; ++o < i;) { // NOSONAR
            (e = t[o]) != null && e > r && (r = e); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      for (;++o < i;) { // NOSONAR
        if ((e = n(t[o], o, t)) != null && e >= e) { // NOSONAR
          for (r = e; ++o < i;) { // NOSONAR
            (e = n(t[o], o, t)) != null && e > r && (r = e); // NOSONAR
          } // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return r; // NOSONAR
  }, t.mean = function(t, n) { // NOSONAR
    var e, r = t.length, i = r, o = -1, u = 0; if (n == null) { // NOSONAR
      for (;++o < r;) { // NOSONAR
        isNaN(e = _s(t[o])) ? --i : u += e; // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      for (;++o < r;) { // NOSONAR
        isNaN(e = _s(n(t[o], o, t))) ? --i : u += e; // NOSONAR
      } // NOSONAR
    } if (i) { // NOSONAR
      return u / i; // NOSONAR
    } // NOSONAR
  }, t.median = function(t, n) { // NOSONAR
    var e, r = t.length, i = -1, o = []; if (n == null) { // NOSONAR
      for (;++i < r;) { // NOSONAR
        isNaN(e = _s(t[i])) || o.push(e); // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      for (;++i < r;) { // NOSONAR
        isNaN(e = _s(n(t[i], i, t))) || o.push(e); // NOSONAR
      } // NOSONAR
    } return zs(o.sort(ls), .5); // NOSONAR
  }, t.merge = Ps, t.min = Rs, t.pairs = function(t, n) { // NOSONAR
    n == null && (n = e); for (var r = 0, i = t.length - 1, o = t[0], u = new Array(i < 0 ? 0 : i); r < i;) { // NOSONAR
      u[r] = n(o, o = t[++r]); // NOSONAR
    } return u; // NOSONAR
  }, t.permute = function(t, n) { // NOSONAR
    for (var e = n.length, r = new Array(e); e--;) { // NOSONAR
      r[e] = t[n[e]]; // NOSONAR
    } return r; // NOSONAR
  }, t.quantile = zs, t.range = Ns, t.scan = function(t, n) { // NOSONAR
    if (e = t.length) { // NOSONAR
      var e, r, i = 0, o = 0, u = t[o]; for (n == null && (n = ls); ++i < e;) { // NOSONAR
        (n(r = t[i], u) < 0 || n(u, u) !== 0) && (u = r, o = i); // NOSONAR
      } return n(u, u) === 0 ? o : void 0; // NOSONAR
    } // NOSONAR
  }, t.shuffle = function(t, n, e) { // NOSONAR
    for (var r, i, o = (e == null ? t.length : e) - (n = n == null ? 0 : +n); o;) { // NOSONAR
      i = Math.random() * o-- | 0, r = t[o + n], t[o + n] = t[i + n], t[i + n] = r; // NOSONAR
    } return t; // NOSONAR
  }, t.sum = function(t, n) { // NOSONAR
    var e, r = t.length, i = -1, o = 0; if (n == null) { // NOSONAR
      for (;++i < r;) { // NOSONAR
        (e = +t[i]) && (o += e); // NOSONAR
      } // NOSONAR
    } else { // NOSONAR
      for (;++i < r;) { // NOSONAR
        (e = +n(t[i], i, t)) && (o += e); // NOSONAR
      } // NOSONAR
    } return o; // NOSONAR
  }, t.ticks = As, t.tickIncrement = r, t.tickStep = i, t.transpose = Ls, t.variance = gs, t.zip = function() { // NOSONAR
    return Ls(arguments); // NOSONAR
  }, t.axisTop = function(t) { // NOSONAR
    return l(Ds, t); // NOSONAR
  }, t.axisRight = function(t) { // NOSONAR
    return l(Os, t); // NOSONAR
  }, t.axisBottom = function(t) { // NOSONAR
    return l(Fs, t); // NOSONAR
  }, t.axisLeft = function(t) { // NOSONAR
    return l(Is, t); // NOSONAR
  }, t.brush = function() { // NOSONAR
    return he(Ah); // NOSONAR
  }, t.brushX = function() { // NOSONAR
    return he(Sh); // NOSONAR
  }, t.brushY = function() { // NOSONAR
    return he(Eh); // NOSONAR
  }, t.brushSelection = function(t) { // NOSONAR
    var n = t.__brush; return n ? n.dim.output(n.selection) : null; // NOSONAR
  }, t.chord = function() { // NOSONAR
    function t(t) { // NOSONAR
      var o, u, a, c, s, f, l = t.length, h = [], p = Ns(l), d = [], v = [], _ = v.groups = new Array(l), g = new Array(l * l); for (o = 0, s = -1; ++s < l;) { // NOSONAR
        for (u = 0, f = -1; ++f < l;) { // NOSONAR
          u += t[s][f]; // NOSONAR
        }h.push(u), d.push(Ns(l)), o += u; // NOSONAR
      } for (e && p.sort(function(t, n) { // NOSONAR
        return e(h[t], h[n]); // NOSONAR
      }), r && d.forEach(function(n, e) { // NOSONAR
          n.sort(function(n, i) { // NOSONAR
            return r(t[e][n], t[e][i]); // NOSONAR
          }); // NOSONAR
        }), c = (o = Ih(0, Fh - n * l) / o) ? n : Fh / l, u = 0, s = -1; ++s < l;) { // NOSONAR
        for (a = u, f = -1; ++f < l;) { // NOSONAR
          var y = p[s], m = d[y][f], x = t[y][m], b = u, w = u += x * o; g[m * l + y] = {index: y, subindex: m, startAngle: b, endAngle: w, value: x}; // NOSONAR
        }_[y] = {index: y, startAngle: a, endAngle: u, value: h[y]}, u += c; // NOSONAR
      } for (s = -1; ++s < l;) { // NOSONAR
        for (f = s - 1; ++f < l;) { // NOSONAR
          var M = g[f * l + s], T = g[s * l + f]; (M.value || T.value) && v.push(M.value < T.value ? {source: T, target: M} : {source: M, target: T}); // NOSONAR
        } // NOSONAR
      } return i ? v.sort(i) : v; // NOSONAR
    } var n = 0, e = null, r = null, i = null; return t.padAngle = function(e) { // NOSONAR
      return arguments.length ? (n = Ih(0, e), t) : n; // NOSONAR
    }, t.sortGroups = function(n) { // NOSONAR
      return arguments.length ? (e = n, t) : e; // NOSONAR
    }, t.sortSubgroups = function(n) { // NOSONAR
      return arguments.length ? (r = n, t) : r; // NOSONAR
    }, t.sortChords = function(n) { // NOSONAR
      return arguments.length ? (n == null ? i = null : (i = pe(n))._ = n, t) : i && i._; // NOSONAR
    }, t; // NOSONAR
  }, t.ribbon = function() { // NOSONAR
    function t() { // NOSONAR
      var t, a = Yh.call(arguments), c = n.apply(this, a), s = e.apply(this, a), f = +r.apply(this, (a[0] = c, a)), l = i.apply(this, a) - Oh, h = o.apply(this, a) - Oh, p = f * qh(l), d = f * Uh(l), v = +r.apply(this, (a[0] = s, a)), _ = i.apply(this, a) - Oh, g = o.apply(this, a) - Oh; if (u || (u = t = ve()), u.moveTo(p, d), u.arc(0, 0, f, l, h), l === _ && h === g || (u.quadraticCurveTo(0, 0, v * qh(_), v * Uh(_)), u.arc(0, 0, v, _, g)), u.quadraticCurveTo(0, 0, p, d), u.closePath(), t) { // NOSONAR
        return u = null, t + '' || null; // NOSONAR
      } // NOSONAR
    } var n = _e, e = ge, r = ye, i = me, o = xe, u = null; return t.radius = function(n) { // NOSONAR
      return arguments.length ? (r = typeof n === 'function' ? n : Bh(+n), t) : r; // NOSONAR
    }, t.startAngle = function(n) { // NOSONAR
      return arguments.length ? (i = typeof n === 'function' ? n : Bh(+n), t) : i; // NOSONAR
    }, t.endAngle = function(n) { // NOSONAR
      return arguments.length ? (o = typeof n === 'function' ? n : Bh(+n), t) : o; // NOSONAR
    }, t.source = function(e) { // NOSONAR
      return arguments.length ? (n = e, t) : n; // NOSONAR
    }, t.target = function(n) { // NOSONAR
      return arguments.length ? (e = n, t) : e; // NOSONAR
    }, t.context = function(n) { // NOSONAR
      return arguments.length ? (u = n == null ? null : n, t) : u; // NOSONAR
    }, t; // NOSONAR
  }, t.nest = function() { // NOSONAR
    function t(n, i, u, a) { // NOSONAR
      if (i >= o.length) { // NOSONAR
        return e != null && n.sort(e), r != null ? r(n) : n; // NOSONAR
      } for (var c, s, f, l = -1, h = n.length, p = o[i++], d = we(), v = u(); ++l < h;) { // NOSONAR
        (f = d.get(c = p(s = n[l]) + '')) ? f.push(s) : d.set(c, [ s ]); // NOSONAR
      } return d.each(function(n, e) { // NOSONAR
        a(v, e, t(n, i, u, a)); // NOSONAR
      }), v; // NOSONAR
    } function n(t, e) { // NOSONAR
      if (++e > o.length) { // NOSONAR
        return t; // NOSONAR
      } var i, a = u[e - 1]; return r != null && e >= o.length ? i = t.entries() : (i = [], t.each(function(t, r) { // NOSONAR
        i.push({key: r, values: n(t, e)}); // NOSONAR
      })), a != null ? i.sort(function(t, n) { // NOSONAR
        return a(t.key, n.key); // NOSONAR
      }) : i; // NOSONAR
    } var e, r, i, o = [], u = []; return i = {object: function(n) { // NOSONAR
      return t(n, 0, Me, Te); // NOSONAR
    }, map: function(n) { // NOSONAR
      return t(n, 0, Ne, ke); // NOSONAR
    }, entries: function(e) { // NOSONAR
      return n(t(e, 0, Ne, ke), 0); // NOSONAR
    }, key: function(t) { // NOSONAR
      return o.push(t), i; // NOSONAR
    }, sortKeys: function(t) { // NOSONAR
      return u[o.length - 1] = t, i; // NOSONAR
    }, sortValues: function(t) { // NOSONAR
      return e = t, i; // NOSONAR
    }, rollup: function(t) { // NOSONAR
      return r = t, i; // NOSONAR
    }}; // NOSONAR
  }, t.set = Ee, t.map = we, t.keys = function(t) { // NOSONAR
    var n = []; for (var e in t) { // NOSONAR
      n.push(e); // NOSONAR
    } return n; // NOSONAR
  }, t.values = function(t) { // NOSONAR
    var n = []; for (var e in t) { // NOSONAR
      n.push(t[e]); // NOSONAR
    } return n; // NOSONAR
  }, t.entries = function(t) { // NOSONAR
    var n = []; for (var e in t) { // NOSONAR
      n.push({key: e, value: t[e]}); // NOSONAR
    } return n; // NOSONAR
  }, t.color = Tt, t.rgb = Et, t.hsl = Pt, t.lab = Ut, t.hcl = jt, t.cubehelix = $t, t.dispatch = h, t.drag = function() { // NOSONAR
    function n(t) { // NOSONAR
      t.on('mousedown.drag', e).filter(g).on('touchstart.drag', o).on('touchmove.drag', u).on('touchend.drag touchcancel.drag', a).style('touch-action', 'none').style('-webkit-tap-highlight-color', 'rgba(0,0,0,0)'); // NOSONAR
    } function e() { // NOSONAR
      if (!p && d.apply(this, arguments)) { // NOSONAR
        var n = c('mouse', v.apply(this, arguments), nf, this, arguments); n && (ff(t.event.view).on('mousemove.drag', r, !0).on('mouseup.drag', i, !0), pf(t.event.view), vt(), l = !1, s = t.event.clientX, f = t.event.clientY, n('start')); // NOSONAR
      } // NOSONAR
    } function r() { // NOSONAR
      if (hf(), !l) { // NOSONAR
        var n = t.event.clientX - s, e = t.event.clientY - f; l = n * n + e * e > b; // NOSONAR
      }y.mouse('drag'); // NOSONAR
    } function i() { // NOSONAR
      ff(t.event.view).on('mousemove.drag mouseup.drag', null), _t(t.event.view, l), hf(), y.mouse('end'); // NOSONAR
    } function o() { // NOSONAR
      if (d.apply(this, arguments)) { // NOSONAR
        var n, e, r = t.event.changedTouches, i = v.apply(this, arguments), o = r.length; for (n = 0; n < o; ++n) { // NOSONAR
          (e = c(r[n].identifier, i, lf, this, arguments)) && (vt(), e('start')); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } function u() { // NOSONAR
      var n, e, r = t.event.changedTouches, i = r.length; for (n = 0; n < i; ++n) { // NOSONAR
        (e = y[r[n].identifier]) && (hf(), e('drag')); // NOSONAR
      } // NOSONAR
    } function a() { // NOSONAR
      var n, e, r = t.event.changedTouches, i = r.length; for (p && clearTimeout(p), p = setTimeout(function() { // NOSONAR
        p = null; // NOSONAR
      }, 500), n = 0; n < i; ++n) { // NOSONAR
        (e = y[r[n].identifier]) && (vt(), e('end')); // NOSONAR
      } // NOSONAR
    } function c(e, r, i, o, u) { // NOSONAR
      var a, c, s, f = i(r, e), l = m.copy(); if (k(new gt(n, 'beforestart', a, e, x, f[0], f[1], 0, 0, l), function() { // NOSONAR
        return (t.event.subject = a = _.apply(o, u)) != null && (c = a.x - f[0] || 0, s = a.y - f[1] || 0, !0); // NOSONAR
      })) { // NOSONAR
        return function t(h) { // NOSONAR
          var p, d = f; switch (h) { // NOSONAR
            case 'start':y[e] = t, p = x++; break; case 'end':delete y[e], --x; case 'drag':f = i(r, e), p = x; // NOSONAR
          }k(new gt(n, h, a, e, p, f[0] + c, f[1] + s, f[0] - d[0], f[1] - d[1], l), l.apply, l, [h, o, u]); // NOSONAR
        }; // NOSONAR
      } // NOSONAR
    } var s, f, l, p, d = yt, v = mt, _ = xt, g = bt, y = {}, m = h('start', 'drag', 'end'), x = 0, b = 0; return n.filter = function(t) { // NOSONAR
      return arguments.length ? (d = typeof t === 'function' ? t : df(!!t), n) : d; // NOSONAR
    }, n.container = function(t) { // NOSONAR
      return arguments.length ? (v = typeof t === 'function' ? t : df(t), n) : v; // NOSONAR
    }, n.subject = function(t) { // NOSONAR
      return arguments.length ? (_ = typeof t === 'function' ? t : df(t), n) : _; // NOSONAR
    }, n.touchable = function(t) { // NOSONAR
      return arguments.length ? (g = typeof t === 'function' ? t : df(!!t), n) : g; // NOSONAR
    }, n.on = function() { // NOSONAR
      var t = m.on.apply(m, arguments); return t === m ? n : t; // NOSONAR
    }, n.clickDistance = function(t) { // NOSONAR
      return arguments.length ? (b = (t = +t) * t, n) : Math.sqrt(b); // NOSONAR
    }, n; // NOSONAR
  }, t.dragDisable = pf, t.dragEnable = _t, t.dsvFormat = Qh, t.csvParse = tp, t.csvParseRows = np, t.csvFormat = ep, t.csvFormatRows = rp, t.tsvParse = op, t.tsvParseRows = up, t.tsvFormat = ap, t.tsvFormatRows = cp, t.easeLinear = function(t) { // NOSONAR
    return +t; // NOSONAR
  }, t.easeQuad = Kn, t.easeQuadIn = function(t) { // NOSONAR
    return t * t; // NOSONAR
  }, t.easeQuadOut = function(t) { // NOSONAR
    return t * (2 - t); // NOSONAR
  }, t.easeQuadInOut = Kn, t.easeCubic = te, t.easeCubicIn = function(t) { // NOSONAR
    return t * t * t; // NOSONAR
  }, t.easeCubicOut = function(t) { // NOSONAR
    return --t * t * t + 1; // NOSONAR
  }, t.easeCubicInOut = te, t.easePoly = Ql, t.easePolyIn = Gl, t.easePolyOut = Jl, t.easePolyInOut = Ql, t.easeSin = ne, t.easeSinIn = function(t) { // NOSONAR
    return 1 - Math.cos(t * th); // NOSONAR
  }, t.easeSinOut = function(t) { // NOSONAR
    return Math.sin(t * th); // NOSONAR
  }, t.easeSinInOut = ne, t.easeExp = ee, t.easeExpIn = function(t) { // NOSONAR
    return Math.pow(2, 10 * t - 10); // NOSONAR
  }, t.easeExpOut = function(t) { // NOSONAR
    return 1 - Math.pow(2, -10 * t); // NOSONAR
  }, t.easeExpInOut = ee, t.easeCircle = re, t.easeCircleIn = function(t) { // NOSONAR
    return 1 - Math.sqrt(1 - t * t); // NOSONAR
  }, t.easeCircleOut = function(t) { // NOSONAR
    return Math.sqrt(1 - --t * t); // NOSONAR
  }, t.easeCircleInOut = re, t.easeBounce = ie, t.easeBounceIn = function(t) { // NOSONAR
    return 1 - ie(1 - t); // NOSONAR
  }, t.easeBounceOut = ie, t.easeBounceInOut = function(t) { // NOSONAR
    return ((t *= 2) <= 1 ? 1 - ie(1 - t) : ie(t - 1) + 1) / 2; // NOSONAR
  }, t.easeBack = ph, t.easeBackIn = lh, t.easeBackOut = hh, t.easeBackInOut = ph, t.easeElastic = _h, t.easeElasticIn = vh, t.easeElasticOut = _h, t.easeElasticInOut = gh, t.forceCenter = function(t, n) { // NOSONAR
    function e() { // NOSONAR
      var e, i, o = r.length, u = 0, a = 0; for (e = 0; e < o; ++e) { // NOSONAR
        u += (i = r[e]).x, a += i.y; // NOSONAR
      } for (u = u / o - t, a = a / o - n, e = 0; e < o; ++e) { // NOSONAR
        (i = r[e]).x -= u, i.y -= a; // NOSONAR
      } // NOSONAR
    } var r; return t == null && (t = 0), n == null && (n = 0), e.initialize = function(t) { // NOSONAR
      r = t; // NOSONAR
    }, e.x = function(n) { // NOSONAR
      return arguments.length ? (t = +n, e) : t; // NOSONAR
    }, e.y = function(t) { // NOSONAR
      return arguments.length ? (n = +t, e) : n; // NOSONAR
    }, e; // NOSONAR
  }, t.forceCollide = function(t) { // NOSONAR
    function n() { // NOSONAR
      for (var t, n, r, c, s, f, l, h = i.length, p = 0; p < a; ++p) { // NOSONAR
        for (n = qe(i, Oe, Fe).visitAfter(e), t = 0; t < h; ++t) { // NOSONAR
          r = i[t], f = o[r.index], l = f * f, c = r.x + r.vx, s = r.y + r.vy, n.visit(function(t, n, e, i, o) { // NOSONAR
            var a = t.data, h = t.r, p = f + h; if (!a) { // NOSONAR
              return n > c + p || i < c - p || e > s + p || o < s - p; // NOSONAR
            } if (a.index > r.index) { // NOSONAR
              var d = c - a.x - a.vx, v = s - a.y - a.vy, _ = d * d + v * v; _ < p * p && (d === 0 && (d = fp(), _ += d * d), v === 0 && (v = fp(), _ += v * v), _ = (p - (_ = Math.sqrt(_))) / _ * u, r.vx += (d *= _) * (p = (h *= h) / (l + h)), r.vy += (v *= _) * p, a.vx -= d * (p = 1 - p), a.vy -= v * p); // NOSONAR
            } // NOSONAR
          }); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } function e(t) { // NOSONAR
      if (t.data) { // NOSONAR
        return t.r = o[t.data.index]; // NOSONAR
      } for (var n = t.r = 0; n < 4; ++n) { // NOSONAR
        t[n] && t[n].r > t.r && (t.r = t[n].r); // NOSONAR
      } // NOSONAR
    } function r() { // NOSONAR
      if (i) { // NOSONAR
        var n, e, r = i.length; for (o = new Array(r), n = 0; n < r; ++n) { // NOSONAR
          e = i[n], o[e.index] = +t(e, n, i); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } var i, o, u = 1, a = 1; return typeof t !== 'function' && (t = sp(t == null ? 1 : +t)), n.initialize = function(t) { // NOSONAR
      i = t, r(); // NOSONAR
    }, n.iterations = function(t) { // NOSONAR
      return arguments.length ? (a = +t, n) : a; // NOSONAR
    }, n.strength = function(t) { // NOSONAR
      return arguments.length ? (u = +t, n) : u; // NOSONAR
    }, n.radius = function(e) { // NOSONAR
      return arguments.length ? (t = typeof e === 'function' ? e : sp(+e), r(), n) : t; // NOSONAR
    }, n; // NOSONAR
  }, t.forceLink = function(t) { // NOSONAR
    function n(n) { // NOSONAR
      for (var e = 0, r = t.length; e < p; ++e) { // NOSONAR
        for (var i, a, c, f, l, h, d, v = 0; v < r; ++v) { // NOSONAR
          a = (i = t[v]).source, f = (c = i.target).x + c.vx - a.x - a.vx || fp(), l = c.y + c.vy - a.y - a.vy || fp(), f *= h = ((h = Math.sqrt(f * f + l * l)) - u[v]) / h * n * o[v], l *= h, c.vx -= f * (d = s[v]), c.vy -= l * d, a.vx += f * (d = 1 - d), a.vy += l * d; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } function e() { // NOSONAR
      if (a) { // NOSONAR
        var n, e, l = a.length, h = t.length, p = we(a, f); for (n = 0, c = new Array(l); n < h; ++n) { // NOSONAR
          (e = t[n]).index = n, typeof e.source !== 'object' && (e.source = Ye(p, e.source)), typeof e.target !== 'object' && (e.target = Ye(p, e.target)), c[e.source.index] = (c[e.source.index] || 0) + 1, c[e.target.index] = (c[e.target.index] || 0) + 1; // NOSONAR
        } for (n = 0, s = new Array(h); n < h; ++n) { // NOSONAR
          e = t[n], s[n] = c[e.source.index] / (c[e.source.index] + c[e.target.index]); // NOSONAR
        }o = new Array(h), r(), u = new Array(h), i(); // NOSONAR
      } // NOSONAR
    } function r() { // NOSONAR
      if (a) { // NOSONAR
        for (var n = 0, e = t.length; n < e; ++n) { // NOSONAR
          o[n] = +l(t[n], n, t); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } function i() { // NOSONAR
      if (a) { // NOSONAR
        for (var n = 0, e = t.length; n < e; ++n) { // NOSONAR
          u[n] = +h(t[n], n, t); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } var o, u, a, c, s, f = Ie, l = function(t) { // NOSONAR
        return 1 / Math.min(c[t.source.index], c[t.target.index]); // NOSONAR
      }, h = sp(30), p = 1; return t == null && (t = []), n.initialize = function(t) { // NOSONAR
      a = t, e(); // NOSONAR
    }, n.links = function(r) { // NOSONAR
      return arguments.length ? (t = r, e(), n) : t; // NOSONAR
    }, n.id = function(t) { // NOSONAR
      return arguments.length ? (f = t, n) : f; // NOSONAR
    }, n.iterations = function(t) { // NOSONAR
      return arguments.length ? (p = +t, n) : p; // NOSONAR
    }, n.strength = function(t) { // NOSONAR
      return arguments.length ? (l = typeof t === 'function' ? t : sp(+t), r(), n) : l; // NOSONAR
    }, n.distance = function(t) { // NOSONAR
      return arguments.length ? (h = typeof t === 'function' ? t : sp(+t), i(), n) : h; // NOSONAR
    }, n; // NOSONAR
  }, t.forceManyBody = function() { // NOSONAR
    function t(t) { // NOSONAR
      var n, a = i.length, c = qe(i, Be, je).visitAfter(e); for (u = t, n = 0; n < a; ++n) { // NOSONAR
        o = i[n], c.visit(r); // NOSONAR
      } // NOSONAR
    } function n() { // NOSONAR
      if (i) { // NOSONAR
        var t, n, e = i.length; for (a = new Array(e), t = 0; t < e; ++t) { // NOSONAR
          n = i[t], a[n.index] = +c(n, t, i); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } function e(t) { // NOSONAR
      var n, e, r, i, o, u = 0, c = 0; if (t.length) { // NOSONAR
        for (r = i = o = 0; o < 4; ++o) { // NOSONAR
          (n = t[o]) && (e = Math.abs(n.value)) && (u += n.value, c += e, r += e * n.x, i += e * n.y); // NOSONAR
        }t.x = r / c, t.y = i / c; // NOSONAR
      } else { // NOSONAR
        (n = t).x = n.data.x, n.y = n.data.y; do { // NOSONAR
          u += a[n.data.index]; // NOSONAR
        } while (n = n.next); // NOSONAR
      }t.value = u; // NOSONAR
    } function r(t, n, e, r) { // NOSONAR
      if (!t.value) { // NOSONAR
        return !0; // NOSONAR
      } var i = t.x - o.x, c = t.y - o.y, h = r - n, p = i * i + c * c; if (h * h / l < p) { // NOSONAR
        return p < f && (i === 0 && (i = fp(), p += i * i), c === 0 && (c = fp(), p += c * c), p < s && (p = Math.sqrt(s * p)), o.vx += i * t.value * u / p, o.vy += c * t.value * u / p), !0; // NOSONAR
      } if (!(t.length || p >= f)) { // NOSONAR
        (t.data !== o || t.next) && (i === 0 && (i = fp(), p += i * i), c === 0 && (c = fp(), p += c * c), p < s && (p = Math.sqrt(s * p))); do { // NOSONAR
          t.data !== o && (h = a[t.data.index] * u / p, o.vx += i * h, o.vy += c * h); // NOSONAR
        } while (t = t.next); // NOSONAR
      } // NOSONAR
    } var i, o, u, a, c = sp(-30), s = 1, f = 1 / 0, l = .81; return t.initialize = function(t) { // NOSONAR
      i = t, n(); // NOSONAR
    }, t.strength = function(e) { // NOSONAR
      return arguments.length ? (c = typeof e === 'function' ? e : sp(+e), n(), t) : c; // NOSONAR
    }, t.distanceMin = function(n) { // NOSONAR
      return arguments.length ? (s = n * n, t) : Math.sqrt(s); // NOSONAR
    }, t.distanceMax = function(n) { // NOSONAR
      return arguments.length ? (f = n * n, t) : Math.sqrt(f); // NOSONAR
    }, t.theta = function(n) { // NOSONAR
      return arguments.length ? (l = n * n, t) : Math.sqrt(l); // NOSONAR
    }, t; // NOSONAR
  }, t.forceRadial = function(t, n, e) { // NOSONAR
    function r(t) { // NOSONAR
      for (var r = 0, i = o.length; r < i; ++r) { // NOSONAR
        var c = o[r], s = c.x - n || 1e-6, f = c.y - e || 1e-6, l = Math.sqrt(s * s + f * f), h = (a[r] - l) * u[r] * t / l; c.vx += s * h, c.vy += f * h; // NOSONAR
      } // NOSONAR
    } function i() { // NOSONAR
      if (o) { // NOSONAR
        var n, e = o.length; for (u = new Array(e), a = new Array(e), n = 0; n < e; ++n) { // NOSONAR
          a[n] = +t(o[n], n, o), u[n] = isNaN(a[n]) ? 0 : +c(o[n], n, o); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } var o, u, a, c = sp(.1); return typeof t !== 'function' && (t = sp(+t)), n == null && (n = 0), e == null && (e = 0), r.initialize = function(t) { // NOSONAR
      o = t, i(); // NOSONAR
    }, r.strength = function(t) { // NOSONAR
      return arguments.length ? (c = typeof t === 'function' ? t : sp(+t), i(), r) : c; // NOSONAR
    }, r.radius = function(n) { // NOSONAR
      return arguments.length ? (t = typeof n === 'function' ? n : sp(+n), i(), r) : t; // NOSONAR
    }, r.x = function(t) { // NOSONAR
      return arguments.length ? (n = +t, r) : n; // NOSONAR
    }, r.y = function(t) { // NOSONAR
      return arguments.length ? (e = +t, r) : e; // NOSONAR
    }, r; // NOSONAR
  }, t.forceSimulation = function(t) { // NOSONAR
    function n() { // NOSONAR
      e(), d.call('tick', o), u < a && (p.stop(), d.call('end', o)); // NOSONAR
    } function e() { // NOSONAR
      var n, e, r = t.length; for (u += (s - u) * c, l.each(function(t) { // NOSONAR
        t(u); // NOSONAR
      }), n = 0; n < r; ++n) { // NOSONAR
        (e = t[n]).fx == null ? e.x += e.vx *= f : (e.x = e.fx, e.vx = 0), e.fy == null ? e.y += e.vy *= f : (e.y = e.fy, e.vy = 0); // NOSONAR
      } // NOSONAR
    } function r() { // NOSONAR
      for (var n, e = 0, r = t.length; e < r; ++e) { // NOSONAR
        if (n = t[e], n.index = e, isNaN(n.x) || isNaN(n.y)) { // NOSONAR
          var i = dp * Math.sqrt(e), o = e * vp; n.x = i * Math.cos(o), n.y = i * Math.sin(o); // NOSONAR
        }(isNaN(n.vx) || isNaN(n.vy)) && (n.vx = n.vy = 0); // NOSONAR
      } // NOSONAR
    } function i(n) { // NOSONAR
      return n.initialize && n.initialize(t), n; // NOSONAR
    } var o, u = 1, a = .001, c = 1 - Math.pow(a, 1 / 300), s = 0, f = .6, l = we(), p = dn(n), d = h('tick', 'end'); return t == null && (t = []), r(), o = {tick: e, restart: function() { // NOSONAR
      return p.restart(n), o; // NOSONAR
    }, stop: function() { // NOSONAR
      return p.stop(), o; // NOSONAR
    }, nodes: function(n) { // NOSONAR
      return arguments.length ? (t = n, r(), l.each(i), o) : t; // NOSONAR
    }, alpha: function(t) { // NOSONAR
      return arguments.length ? (u = +t, o) : u; // NOSONAR
    }, alphaMin: function(t) { // NOSONAR
      return arguments.length ? (a = +t, o) : a; // NOSONAR
    }, alphaDecay: function(t) { // NOSONAR
      return arguments.length ? (c = +t, o) : +c; // NOSONAR
    }, alphaTarget: function(t) { // NOSONAR
      return arguments.length ? (s = +t, o) : s; // NOSONAR
    }, velocityDecay: function(t) { // NOSONAR
      return arguments.length ? (f = 1 - t, o) : 1 - f; // NOSONAR
    }, force: function(t, n) { // NOSONAR
      return arguments.length > 1 ? (n == null ? l.remove(t) : l.set(t, i(n)), o) : l.get(t); // NOSONAR
    }, find: function(n, e, r) { // NOSONAR
      var i, o, u, a, c, s = 0, f = t.length; for (r == null ? r = 1 / 0 : r *= r, s = 0; s < f; ++s) { // NOSONAR
        (u = (i = n - (a = t[s]).x) * i + (o = e - a.y) * o) < r && (c = a, r = u); // NOSONAR
      } return c; // NOSONAR
    }, on: function(t, n) { // NOSONAR
      return arguments.length > 1 ? (d.on(t, n), o) : d.on(t); // NOSONAR
    }}; // NOSONAR
  }, t.forceX = function(t) { // NOSONAR
    function n(t) { // NOSONAR
      for (var n, e = 0, u = r.length; e < u; ++e) { // NOSONAR
        (n = r[e]).vx += (o[e] - n.x) * i[e] * t; // NOSONAR
      } // NOSONAR
    } function e() { // NOSONAR
      if (r) { // NOSONAR
        var n, e = r.length; for (i = new Array(e), o = new Array(e), n = 0; n < e; ++n) { // NOSONAR
          i[n] = isNaN(o[n] = +t(r[n], n, r)) ? 0 : +u(r[n], n, r); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } var r, i, o, u = sp(.1); return typeof t !== 'function' && (t = sp(t == null ? 0 : +t)), n.initialize = function(t) { // NOSONAR
      r = t, e(); // NOSONAR
    }, n.strength = function(t) { // NOSONAR
      return arguments.length ? (u = typeof t === 'function' ? t : sp(+t), e(), n) : u; // NOSONAR
    }, n.x = function(r) { // NOSONAR
      return arguments.length ? (t = typeof r === 'function' ? r : sp(+r), e(), n) : t; // NOSONAR
    }, n; // NOSONAR
  }, t.forceY = function(t) { // NOSONAR
    function n(t) { // NOSONAR
      for (var n, e = 0, u = r.length; e < u; ++e) { // NOSONAR
        (n = r[e]).vy += (o[e] - n.y) * i[e] * t; // NOSONAR
      } // NOSONAR
    } function e() { // NOSONAR
      if (r) { // NOSONAR
        var n, e = r.length; for (i = new Array(e), o = new Array(e), n = 0; n < e; ++n) { // NOSONAR
          i[n] = isNaN(o[n] = +t(r[n], n, r)) ? 0 : +u(r[n], n, r); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } var r, i, o, u = sp(.1); return typeof t !== 'function' && (t = sp(t == null ? 0 : +t)), n.initialize = function(t) { // NOSONAR
      r = t, e(); // NOSONAR
    }, n.strength = function(t) { // NOSONAR
      return arguments.length ? (u = typeof t === 'function' ? t : sp(+t), e(), n) : u; // NOSONAR
    }, n.y = function(r) { // NOSONAR
      return arguments.length ? (t = typeof r === 'function' ? r : sp(+r), e(), n) : t; // NOSONAR
    }, n; // NOSONAR
  }, t.formatDefaultLocale = $e, t.formatLocale = kp, t.formatSpecifier = He, t.precisionFixed = Sp, t.precisionPrefix = Ep, t.precisionRound = Ap, t.geoArea = function(t) { // NOSONAR
    return Pd.reset(), Cd(t, Rd), 2 * Pd; // NOSONAR
  }, t.geoBounds = function(t) { // NOSONAR
    var n, e, r, i, o, u, a; if (Fp = Op = -(Up = Dp = 1 / 0), Hp = [], Cd(t, qd), e = Hp.length) { // NOSONAR
      for (Hp.sort(br), n = 1, o = [ r = Hp[0] ]; n < e; ++n) { // NOSONAR
        wr(r, (i = Hp[n])[0]) || wr(r, i[1]) ? (xr(r[0], i[1]) > xr(r[0], r[1]) && (r[1] = i[1]), xr(i[0], r[1]) > xr(r[0], r[1]) && (r[0] = i[0])) : o.push(r = i); // NOSONAR
      } for (u = -1 / 0, n = 0, r = o[e = o.length - 1]; n <= e; r = i, ++n) { // NOSONAR
        i = o[n], (a = xr(r[1], i[0])) > u && (u = a, Up = i[0], Op = r[1]); // NOSONAR
      } // NOSONAR
    } return Hp = Xp = null, Up === 1 / 0 || Dp === 1 / 0 ? [[NaN, NaN], [NaN, NaN]] : [[Up, Dp], [Op, Fp]]; // NOSONAR
  }, t.geoCentroid = function(t) { // NOSONAR
    $p = Vp = Wp = Zp = Gp = Jp = Qp = Kp = td = nd = ed = 0, Cd(t, Ud); var n = td, e = nd, r = ed, i = n * n + e * e + r * r; return i < 1e-12 && (n = Jp, e = Qp, r = Kp, Vp < sd && (n = Wp, e = Zp, r = Gp), (i = n * n + e * e + r * r) < 1e-12) ? [NaN, NaN] : [yd(e, n) * dd, Ge(r / kd(i)) * dd]; // NOSONAR
  }, t.geoCircle = function() { // NOSONAR
    function t() { // NOSONAR
      var t = r.apply(this, arguments), a = i.apply(this, arguments) * vd, c = o.apply(this, arguments) * vd; return n = [], e = Lr(-t[0] * vd, -t[1] * vd, 0).invert, Or(u, a, c, 1), t = {type: 'Polygon', coordinates: [ n ]}, n = e = null, t; // NOSONAR
    } var n, e, r = Dd([0, 0]), i = Dd(90), o = Dd(6), u = {point: function(t, r) { // NOSONAR
      n.push(t = e(t, r)), t[0] *= dd, t[1] *= dd; // NOSONAR
    }}; return t.center = function(n) { // NOSONAR
      return arguments.length ? (r = typeof n === 'function' ? n : Dd([+n[0], +n[1]]), t) : r; // NOSONAR
    }, t.radius = function(n) { // NOSONAR
      return arguments.length ? (i = typeof n === 'function' ? n : Dd(+n), t) : i; // NOSONAR
    }, t.precision = function(n) { // NOSONAR
      return arguments.length ? (o = typeof n === 'function' ? n : Dd(+n), t) : o; // NOSONAR
    }, t; // NOSONAR
  }, t.geoClipAntimeridian = rv, t.geoClipCircle = iv, t.geoClipExtent = function() { // NOSONAR
    var t, n, e, r = 0, i = 0, o = 960, u = 500; return e = {stream: function(e) { // NOSONAR
      return t && n === e ? t : t = Xr(r, i, o, u)(n = e); // NOSONAR
    }, extent: function(a) { // NOSONAR
      return arguments.length ? (r = +a[0][0], i = +a[0][1], o = +a[1][0], u = +a[1][1], t = n = null, e) : [[r, i], [o, u]]; // NOSONAR
    }}; // NOSONAR
  }, t.geoClipRectangle = Xr, t.geoContains = function(t, n) { // NOSONAR
    return (t && dv.hasOwnProperty(t.type) ? dv[t.type] : Zr)(t, n); // NOSONAR
  }, t.geoDistance = pv, t.geoGraticule = ri, t.geoGraticule10 = function() { // NOSONAR
    return ri()(); // NOSONAR
  }, t.geoInterpolate = function(t, n) { // NOSONAR
    var e = t[0] * vd, r = t[1] * vd, i = n[0] * vd, o = n[1] * vd, u = md(r), a = Td(r), c = md(o), s = Td(o), f = u * md(e), l = u * Td(e), h = c * md(i), p = c * Td(i), d = 2 * Ge(kd(Je(o - r) + u * c * Je(i - e))), v = Td(d), _ = d ? function(t) { // NOSONAR
      var n = Td(t *= d) / v, e = Td(d - t) / v, r = e * f + n * h, i = e * l + n * p, o = e * a + n * s; return [yd(i, r) * dd, yd(o, kd(r * r + i * i)) * dd]; // NOSONAR
    } : function() { // NOSONAR
      return [e * dd, r * dd]; // NOSONAR
    }; return _.distance = d, _; // NOSONAR
  }, t.geoLength = fv, t.geoPath = function(t, n) { // NOSONAR
    function e(t) { // NOSONAR
      return t && (typeof o === 'function' && i.pointRadius(+o.apply(this, arguments)), Cd(t, r(i))), i.result(); // NOSONAR
    } var r, i, o = 4.5; return e.area = function(t) { // NOSONAR
      return Cd(t, r(mv)), mv.result(); // NOSONAR
    }, e.measure = function(t) { // NOSONAR
      return Cd(t, r(Yv)), Yv.result(); // NOSONAR
    }, e.bounds = function(t) { // NOSONAR
      return Cd(t, r(Tv)), Tv.result(); // NOSONAR
    }, e.centroid = function(t) { // NOSONAR
      return Cd(t, r(Lv)), Lv.result(); // NOSONAR
    }, e.projection = function(n) { // NOSONAR
      return arguments.length ? (r = n == null ? (t = null, _v) : (t = n).stream, e) : t; // NOSONAR
    }, e.context = function(t) { // NOSONAR
      return arguments.length ? (i = t == null ? (n = null, new xi) : new gi(n = t), typeof o !== 'function' && i.pointRadius(o), e) : n; // NOSONAR
    }, e.pointRadius = function(t) { // NOSONAR
      return arguments.length ? (o = typeof t === 'function' ? t : (i.pointRadius(+t), +t), e) : o; // NOSONAR
    }, e.projection(t).context(n); // NOSONAR
  }, t.geoAlbers = Vv, t.geoAlbersUsa = function() { // NOSONAR
    function t(t) { // NOSONAR
      var n = t[0], e = t[1]; return a = null, i.point(n, e), a || (o.point(n, e), a) || (u.point(n, e), a); // NOSONAR
    } function n() { // NOSONAR
      return e = r = null, t; // NOSONAR
    } var e, r, i, o, u, a, c = Vv(), s = $v().rotate([154, 0]).center([-2, 58.5]).parallels([55, 65]), f = $v().rotate([157, 0]).center([-3, 19.9]).parallels([8, 18]), l = {point: function(t, n) { // NOSONAR
      a = [t, n]; // NOSONAR
    }}; return t.invert = function(t) { // NOSONAR
      var n = c.scale(), e = c.translate(), r = (t[0] - e[0]) / n, i = (t[1] - e[1]) / n; return (i >= .12 && i < .234 && r >= -.425 && r < -.214 ? s : i >= .166 && i < .234 && r >= -.214 && r < -.115 ? f : c).invert(t); // NOSONAR
    }, t.stream = function(t) { // NOSONAR
      return e && r === t ? e : e = Li([c.stream(r = t), s.stream(t), f.stream(t)]); // NOSONAR
    }, t.precision = function(t) { // NOSONAR
      return arguments.length ? (c.precision(t), s.precision(t), f.precision(t), n()) : c.precision(); // NOSONAR
    }, t.scale = function(n) { // NOSONAR
      return arguments.length ? (c.scale(n), s.scale(.35 * n), f.scale(n), t.translate(c.translate())) : c.scale(); // NOSONAR
    }, t.translate = function(t) { // NOSONAR
      if (!arguments.length) { // NOSONAR
        return c.translate(); // NOSONAR
      } var e = c.scale(), r = +t[0], a = +t[1]; return i = c.translate(t).clipExtent([[r - .455 * e, a - .238 * e], [r + .455 * e, a + .238 * e]]).stream(l), o = s.translate([r - .307 * e, a + .201 * e]).clipExtent([[r - .425 * e + sd, a + .12 * e + sd], [r - .214 * e - sd, a + .234 * e - sd]]).stream(l), u = f.translate([r - .205 * e, a + .212 * e]).clipExtent([[r - .214 * e + sd, a + .166 * e + sd], [r - .115 * e - sd, a + .234 * e - sd]]).stream(l), n(); // NOSONAR
    }, t.fitExtent = function(n, e) { // NOSONAR
      return Ti(t, n, e); // NOSONAR
    }, t.fitSize = function(n, e) { // NOSONAR
      return Ni(t, n, e); // NOSONAR
    }, t.scale(1070); // NOSONAR
  }, t.geoAzimuthalEqualArea = function() { // NOSONAR
    return Ai(Wv).scale(124.75).clipAngle(179.999); // NOSONAR
  }, t.geoAzimuthalEqualAreaRaw = Wv, t.geoAzimuthalEquidistant = function() { // NOSONAR
    return Ai(Zv).scale(79.4188).clipAngle(179.999); // NOSONAR
  }, t.geoAzimuthalEquidistantRaw = Zv, t.geoConicConformal = function() { // NOSONAR
    return zi(Ii).scale(109.5).parallels([30, 30]); // NOSONAR
  }, t.geoConicConformalRaw = Ii, t.geoConicEqualArea = $v, t.geoConicEqualAreaRaw = Ri, t.geoConicEquidistant = function() { // NOSONAR
    return zi(Bi).scale(131.154).center([0, 13.9389]); // NOSONAR
  }, t.geoConicEquidistantRaw = Bi, t.geoEquirectangular = function() { // NOSONAR
    return Ai(Yi).scale(152.63); // NOSONAR
  }, t.geoEquirectangularRaw = Yi, t.geoGnomonic = function() { // NOSONAR
    return Ai(ji).scale(144.049).clipAngle(60); // NOSONAR
  }, t.geoGnomonicRaw = ji, t.geoIdentity = function() { // NOSONAR
    function t() { // NOSONAR
      return i = o = null, u; // NOSONAR
    } var n, e, r, i, o, u, a = 1, c = 0, s = 0, f = 1, l = 1, h = _v, p = null, d = _v; return u = {stream: function(t) { // NOSONAR
      return i && o === t ? i : i = h(d(o = t)); // NOSONAR
    }, postclip: function(i) { // NOSONAR
      return arguments.length ? (d = i, p = n = e = r = null, t()) : d; // NOSONAR
    }, clipExtent: function(i) { // NOSONAR
      return arguments.length ? (d = i == null ? (p = n = e = r = null, _v) : Xr(p = +i[0][0], n = +i[0][1], e = +i[1][0], r = +i[1][1]), t()) : p == null ? null : [[p, n], [e, r]]; // NOSONAR
    }, scale: function(n) { // NOSONAR
      return arguments.length ? (h = Hi((a = +n) * f, a * l, c, s), t()) : a; // NOSONAR
    }, translate: function(n) { // NOSONAR
      return arguments.length ? (h = Hi(a * f, a * l, c = +n[0], s = +n[1]), t()) : [c, s]; // NOSONAR
    }, reflectX: function(n) { // NOSONAR
      return arguments.length ? (h = Hi(a * (f = n ? -1 : 1), a * l, c, s), t()) : f < 0; // NOSONAR
    }, reflectY: function(n) { // NOSONAR
      return arguments.length ? (h = Hi(a * f, a * (l = n ? -1 : 1), c, s), t()) : l < 0; // NOSONAR
    }, fitExtent: function(t, n) { // NOSONAR
      return Ti(u, t, n); // NOSONAR
    }, fitSize: function(t, n) { // NOSONAR
      return Ni(u, t, n); // NOSONAR
    }}; // NOSONAR
  }, t.geoProjection = Ai, t.geoProjectionMutator = Ci, t.geoMercator = function() { // NOSONAR
    return Oi(Di).scale(961 / pd); // NOSONAR
  }, t.geoMercatorRaw = Di, t.geoNaturalEarth1 = function() { // NOSONAR
    return Ai(Xi).scale(175.295); // NOSONAR
  }, t.geoNaturalEarth1Raw = Xi, t.geoOrthographic = function() { // NOSONAR
    return Ai($i).scale(249.5).clipAngle(90 + sd); // NOSONAR
  }, t.geoOrthographicRaw = $i, t.geoStereographic = function() { // NOSONAR
    return Ai(Vi).scale(250).clipAngle(142); // NOSONAR
  }, t.geoStereographicRaw = Vi, t.geoTransverseMercator = function() { // NOSONAR
    var t = Oi(Wi), n = t.center, e = t.rotate; return t.center = function(t) { // NOSONAR
      return arguments.length ? n([-t[1], t[0]]) : (t = n(), [t[1], -t[0]]); // NOSONAR
    }, t.rotate = function(t) { // NOSONAR
      return arguments.length ? e([t[0], t[1], t.length > 2 ? t[2] + 90 : 90]) : (t = e(), [t[0], t[1], t[2] - 90]); // NOSONAR
    }, e([0, 0, 90]).scale(159.155); // NOSONAR
  }, t.geoTransverseMercatorRaw = Wi, t.geoRotation = Gd, t.geoStream = Cd, t.geoTransform = function(t) { // NOSONAR
    return {stream: wi(t)}; // NOSONAR
  }, t.cluster = function() { // NOSONAR
    function t(t) { // NOSONAR
      var o, u = 0; t.eachAfter(function(t) { // NOSONAR
        var e = t.children; e ? (t.x = Gi(e), t.y = Qi(e)) : (t.x = o ? u += n(t, o) : 0, t.y = 0, o = t); // NOSONAR
      }); var a = to(t), c = no(t), s = a.x - n(a, c) / 2, f = c.x + n(c, a) / 2; return t.eachAfter(i ? function(n) { // NOSONAR
        n.x = (n.x - t.x) * e, n.y = (t.y - n.y) * r; // NOSONAR
      } : function(n) { // NOSONAR
        n.x = (n.x - s) / (f - s) * e, n.y = (1 - (t.y ? n.y / t.y : 1)) * r; // NOSONAR
      }); // NOSONAR
    } var n = Zi, e = 1, r = 1, i = !1; return t.separation = function(e) { // NOSONAR
      return arguments.length ? (n = e, t) : n; // NOSONAR
    }, t.size = function(n) { // NOSONAR
      return arguments.length ? (i = !1, e = +n[0], r = +n[1], t) : i ? null : [e, r]; // NOSONAR
    }, t.nodeSize = function(n) { // NOSONAR
      return arguments.length ? (i = !0, e = +n[0], r = +n[1], t) : i ? [e, r] : null; // NOSONAR
    }, t; // NOSONAR
  }, t.hierarchy = io, t.pack = function() { // NOSONAR
    function t(t) { // NOSONAR
      return t.x = e / 2, t.y = r / 2, n ? t.eachBefore(Eo(n)).eachAfter(Ao(i, .5)).eachBefore(Co(1)) : t.eachBefore(Eo(So)).eachAfter(Ao(ko, 1)).eachAfter(Ao(i, t.r / Math.min(e, r))).eachBefore(Co(Math.min(e, r) / (2 * t.r))), t; // NOSONAR
    } var n = null, e = 1, r = 1, i = ko; return t.radius = function(e) { // NOSONAR
      return arguments.length ? (n = To(e), t) : n; // NOSONAR
    }, t.size = function(n) { // NOSONAR
      return arguments.length ? (e = +n[0], r = +n[1], t) : [e, r]; // NOSONAR
    }, t.padding = function(n) { // NOSONAR
      return arguments.length ? (i = typeof n === 'function' ? n : Qv(+n), t) : i; // NOSONAR
    }, t; // NOSONAR
  }, t.packSiblings = function(t) { // NOSONAR
    return Mo(t), t; // NOSONAR
  }, t.packEnclose = Jv, t.partition = function() { // NOSONAR
    function t(t) { // NOSONAR
      var u = t.height + 1; return t.x0 = t.y0 = i, t.x1 = e, t.y1 = r / u, t.eachBefore(n(r, u)), o && t.eachBefore(Kv), t; // NOSONAR
    } function n(t, n) { // NOSONAR
      return function(e) { // NOSONAR
        e.children && t_(e, e.x0, t * (e.depth + 1) / n, e.x1, t * (e.depth + 2) / n); var r = e.x0, o = e.y0, u = e.x1 - i, a = e.y1 - i; u < r && (r = u = (r + u) / 2), a < o && (o = a = (o + a) / 2), e.x0 = r, e.y0 = o, e.x1 = u, e.y1 = a; // NOSONAR
      }; // NOSONAR
    } var e = 1, r = 1, i = 0, o = !1; return t.round = function(n) { // NOSONAR
      return arguments.length ? (o = !!n, t) : o; // NOSONAR
    }, t.size = function(n) { // NOSONAR
      return arguments.length ? (e = +n[0], r = +n[1], t) : [e, r]; // NOSONAR
    }, t.padding = function(n) { // NOSONAR
      return arguments.length ? (i = +n, t) : i; // NOSONAR
    }, t; // NOSONAR
  }, t.stratify = function() { // NOSONAR
    function t(t) { // NOSONAR
      var r, i, o, u, a, c, s, f = t.length, l = new Array(f), h = {}; for (i = 0; i < f; ++i) { // NOSONAR
        r = t[i], a = l[i] = new co(r), (c = n(r, i, t)) != null && (c += '') && (h[s = n_ + (a.id = c)] = s in h ? r_ : a); // NOSONAR
      } for (i = 0; i < f; ++i) { // NOSONAR
        if (a = l[i], (c = e(t[i], i, t)) != null && (c += '')) { // NOSONAR
          if (!(u = h[n_ + c])) { // NOSONAR
            throw new Error('missing: ' + c); // NOSONAR
          } if (u === r_) { // NOSONAR
            throw new Error('ambiguous: ' + c); // NOSONAR
          } u.children ? u.children.push(a) : u.children = [ a ], a.parent = u; // NOSONAR
        } else { // NOSONAR
          if (o) { // NOSONAR
            throw new Error('multiple roots'); // NOSONAR
          } o = a; // NOSONAR
        } // NOSONAR
      } if (!o) { // NOSONAR
        throw new Error('no root'); // NOSONAR
      } if (o.parent = e_, o.eachBefore(function(t) { // NOSONAR
        t.depth = t.parent.depth + 1, --f; // NOSONAR
      }).eachBefore(ao), o.parent = null, f > 0) { // NOSONAR
        throw new Error('cycle'); // NOSONAR
      } return o; // NOSONAR
    } var n = zo, e = Po; return t.id = function(e) { // NOSONAR
      return arguments.length ? (n = No(e), t) : n; // NOSONAR
    }, t.parentId = function(n) { // NOSONAR
      return arguments.length ? (e = No(n), t) : e; // NOSONAR
    }, t; // NOSONAR
  }, t.tree = function() { // NOSONAR
    function t(t) { // NOSONAR
      var r = Io(t); if (r.eachAfter(n), r.parent.m = -r.z, r.eachBefore(e), c) { // NOSONAR
        t.eachBefore(i); // NOSONAR
      } else { // NOSONAR
        var s = t, f = t, l = t; t.eachBefore(function(t) { // NOSONAR
          t.x < s.x && (s = t), t.x > f.x && (f = t), t.depth > l.depth && (l = t); // NOSONAR
        }); var h = s === f ? 1 : o(s, f) / 2, p = h - s.x, d = u / (f.x + h + p), v = a / (l.depth || 1); t.eachBefore(function(t) { // NOSONAR
          t.x = (t.x + p) * d, t.y = t.depth * v; // NOSONAR
        }); // NOSONAR
      } return t; // NOSONAR
    } function n(t) { // NOSONAR
      var n = t.children, e = t.parent.children, i = t.i ? e[t.i - 1] : null; if (n) { // NOSONAR
        Do(t); var u = (n[0].z + n[n.length - 1].z) / 2; i ? (t.z = i.z + o(t._, i._), t.m = t.z - u) : t.z = u; // NOSONAR
      } else { // NOSONAR
        i && (t.z = i.z + o(t._, i._)); // NOSONAR
      }t.parent.A = r(t, i, t.parent.A || e[0]); // NOSONAR
    } function e(t) { // NOSONAR
      t._.x = t.z + t.parent.m, t.m += t.parent.m; // NOSONAR
    } function r(t, n, e) { // NOSONAR
      if (n) { // NOSONAR
        for (var r, i = t, u = t, a = n, c = i.parent.children[0], s = i.m, f = u.m, l = a.m, h = c.m; a = qo(a), i = Lo(i), a && i;) { // NOSONAR
          c = Lo(c), (u = qo(u)).a = t, (r = a.z + l - i.z - s + o(a._, i._)) > 0 && (Uo(Oo(a, t, e), t, r), s += r, f += r), l += a.m, s += i.m, h += c.m, f += u.m; // NOSONAR
        }a && !qo(u) && (u.t = a, u.m += l - f), i && !Lo(c) && (c.t = i, c.m += s - h, e = t); // NOSONAR
      } return e; // NOSONAR
    } function i(t) { // NOSONAR
      t.x *= u, t.y = t.depth * a; // NOSONAR
    } var o = Ro, u = 1, a = 1, c = null; return t.separation = function(n) { // NOSONAR
      return arguments.length ? (o = n, t) : o; // NOSONAR
    }, t.size = function(n) { // NOSONAR
      return arguments.length ? (c = !1, u = +n[0], a = +n[1], t) : c ? null : [u, a]; // NOSONAR
    }, t.nodeSize = function(n) { // NOSONAR
      return arguments.length ? (c = !0, u = +n[0], a = +n[1], t) : c ? [u, a] : null; // NOSONAR
    }, t; // NOSONAR
  }, t.treemap = function() { // NOSONAR
    function t(t) { // NOSONAR
      return t.x0 = t.y0 = 0, t.x1 = i, t.y1 = o, t.eachBefore(n), u = [ 0 ], r && t.eachBefore(Kv), t; // NOSONAR
    } function n(t) { // NOSONAR
      var n = u[t.depth], r = t.x0 + n, i = t.y0 + n, o = t.x1 - n, h = t.y1 - n; o < r && (r = o = (r + o) / 2), h < i && (i = h = (i + h) / 2), t.x0 = r, t.y0 = i, t.x1 = o, t.y1 = h, t.children && (n = u[t.depth + 1] = a(t) / 2, r += l(t) - n, i += c(t) - n, o -= s(t) - n, h -= f(t) - n, o < r && (r = o = (r + o) / 2), h < i && (i = h = (i + h) / 2), e(t, r, i, o, h)); // NOSONAR
    } var e = u_, r = !1, i = 1, o = 1, u = [ 0 ], a = ko, c = ko, s = ko, f = ko, l = ko; return t.round = function(n) { // NOSONAR
      return arguments.length ? (r = !!n, t) : r; // NOSONAR
    }, t.size = function(n) { // NOSONAR
      return arguments.length ? (i = +n[0], o = +n[1], t) : [i, o]; // NOSONAR
    }, t.tile = function(n) { // NOSONAR
      return arguments.length ? (e = No(n), t) : e; // NOSONAR
    }, t.padding = function(n) { // NOSONAR
      return arguments.length ? t.paddingInner(n).paddingOuter(n) : t.paddingInner(); // NOSONAR
    }, t.paddingInner = function(n) { // NOSONAR
      return arguments.length ? (a = typeof n === 'function' ? n : Qv(+n), t) : a; // NOSONAR
    }, t.paddingOuter = function(n) { // NOSONAR
      return arguments.length ? t.paddingTop(n).paddingRight(n).paddingBottom(n).paddingLeft(n) : t.paddingTop(); // NOSONAR
    }, t.paddingTop = function(n) { // NOSONAR
      return arguments.length ? (c = typeof n === 'function' ? n : Qv(+n), t) : c; // NOSONAR
    }, t.paddingRight = function(n) { // NOSONAR
      return arguments.length ? (s = typeof n === 'function' ? n : Qv(+n), t) : s; // NOSONAR
    }, t.paddingBottom = function(n) { // NOSONAR
      return arguments.length ? (f = typeof n === 'function' ? n : Qv(+n), t) : f; // NOSONAR
    }, t.paddingLeft = function(n) { // NOSONAR
      return arguments.length ? (l = typeof n === 'function' ? n : Qv(+n), t) : l; // NOSONAR
    }, t; // NOSONAR
  }, t.treemapBinary = function(t, n, e, r, i) { // NOSONAR
    function o(t, n, e, r, i, u, a) { // NOSONAR
      if (t >= n - 1) { // NOSONAR
        var s = c[t]; return s.x0 = r, s.y0 = i, s.x1 = u, void(s.y1 = a); // NOSONAR
      } for (var l = f[t], h = e / 2 + l, p = t + 1, d = n - 1; p < d;) { // NOSONAR
        var v = p + d >>> 1; f[v] < h ? p = v + 1 : d = v; // NOSONAR
      }h - f[p - 1] < f[p] - h && t + 1 < p && --p; var _ = f[p] - l, g = e - _; if (u - r > a - i) { // NOSONAR
        var y = (r * g + u * _) / e; o(t, p, _, r, i, y, a), o(p, n, g, y, i, u, a); // NOSONAR
      } else { // NOSONAR
        var m = (i * g + a * _) / e; o(t, p, _, r, i, u, m), o(p, n, g, r, m, u, a); // NOSONAR
      } // NOSONAR
    } var u, a, c = t.children, s = c.length, f = new Array(s + 1); for (f[0] = a = u = 0; u < s; ++u) { // NOSONAR
      f[u + 1] = a += c[u].value; // NOSONAR
    }o(0, s, t.value, n, e, r, i); // NOSONAR
  }, t.treemapDice = t_, t.treemapSlice = i_, t.treemapSliceDice = function(t, n, e, r, i) { // NOSONAR
    (1 & t.depth ? i_ : t_)(t, n, e, r, i); // NOSONAR
  }, t.treemapSquarify = u_, t.treemapResquarify = a_, t.interpolate = fl, t.interpolateArray = rl, t.interpolateBasis = Jf, t.interpolateBasisClosed = Qf, t.interpolateDate = il, t.interpolateNumber = ol, t.interpolateObject = ul, t.interpolateRound = ll, t.interpolateString = sl, t.interpolateTransformCss = vl, t.interpolateTransformSvg = _l, t.interpolateZoom = yl, t.interpolateRgb = tl, t.interpolateRgbBasis = nl, t.interpolateRgbBasisClosed = el, t.interpolateHsl = ml, t.interpolateHslLong = xl, t.interpolateLab = function(t, n) { // NOSONAR
    var e = Kt((t = Ut(t)).l, (n = Ut(n)).l), r = Kt(t.a, n.a), i = Kt(t.b, n.b), o = Kt(t.opacity, n.opacity); return function(n) { // NOSONAR
      return t.l = e(n), t.a = r(n), t.b = i(n), t.opacity = o(n), t + ''; // NOSONAR
    }; // NOSONAR
  }, t.interpolateHcl = bl, t.interpolateHclLong = wl, t.interpolateCubehelix = Ml, t.interpolateCubehelixLong = Tl, t.quantize = function(t, n) { // NOSONAR
    for (var e = new Array(n), r = 0; r < n; ++r) { // NOSONAR
      e[r] = t(r / (n - 1)); // NOSONAR
    } return e; // NOSONAR
  }, t.path = ve, t.polygonArea = function(t) { // NOSONAR
    for (var n, e = -1, r = t.length, i = t[r - 1], o = 0; ++e < r;) { // NOSONAR
      n = i, i = t[e], o += n[1] * i[0] - n[0] * i[1]; // NOSONAR
    } return o / 2; // NOSONAR
  }, t.polygonCentroid = function(t) { // NOSONAR
    for (var n, e, r = -1, i = t.length, o = 0, u = 0, a = t[i - 1], c = 0; ++r < i;) { // NOSONAR
      n = a, a = t[r], c += e = n[0] * a[1] - a[0] * n[1], o += (n[0] + a[0]) * e, u += (n[1] + a[1]) * e; // NOSONAR
    } return c *= 3, [o / c, u / c]; // NOSONAR
  }, t.polygonHull = function(t) { // NOSONAR
    if ((e = t.length) < 3) { // NOSONAR
      return null; // NOSONAR
    } var n, e, r = new Array(e), i = new Array(e); for (n = 0; n < e; ++n) { // NOSONAR
      r[n] = [+t[n][0], +t[n][1], n]; // NOSONAR
    } for (r.sort(Bo), n = 0; n < e; ++n) { // NOSONAR
      i[n] = [r[n][0], -r[n][1]]; // NOSONAR
    } var o = jo(r), u = jo(i), a = u[0] === o[0], c = u[u.length - 1] === o[o.length - 1], s = []; for (n = o.length - 1; n >= 0; --n) { // NOSONAR
      s.push(t[r[o[n]][2]]); // NOSONAR
    } for (n = +a; n < u.length - c; ++n) { // NOSONAR
      s.push(t[r[u[n]][2]]); // NOSONAR
    } return s; // NOSONAR
  }, t.polygonContains = function(t, n) { // NOSONAR
    for (var e, r, i = t.length, o = t[i - 1], u = n[0], a = n[1], c = o[0], s = o[1], f = !1, l = 0; l < i; ++l) { // NOSONAR
      e = (o = t[l])[0], (r = o[1]) > a != s > a && u < (c - e) * (a - r) / (s - r) + e && (f = !f), c = e, s = r; // NOSONAR
    } return f; // NOSONAR
  }, t.polygonLength = function(t) { // NOSONAR
    for (var n, e, r = -1, i = t.length, o = t[i - 1], u = o[0], a = o[1], c = 0; ++r < i;) { // NOSONAR
      n = u, e = a, n -= u = (o = t[r])[0], e -= a = o[1], c += Math.sqrt(n * n + e * e); // NOSONAR
    } return c; // NOSONAR
  }, t.quadtree = qe, t.queue = Go, t.randomUniform = h_, t.randomNormal = p_, t.randomLogNormal = d_, t.randomBates = __, t.randomIrwinHall = v_, t.randomExponential = g_, t.request = y_, t.html = x_, t.json = b_, t.text = w_, t.xml = M_, t.csv = N_, t.tsv = k_, t.scaleBand = nu, t.scalePoint = function() { // NOSONAR
    return eu(nu().paddingInner(1)); // NOSONAR
  }, t.scaleIdentity = hu, t.scaleLinear = lu, t.scaleLog = mu, t.scaleOrdinal = tu, t.scaleImplicit = C_, t.scalePow = bu, t.scaleSqrt = function() { // NOSONAR
    return bu().exponent(.5); // NOSONAR
  }, t.scaleQuantile = wu, t.scaleQuantize = Mu, t.scaleThreshold = Tu, t.scaleTime = function() { // NOSONAR
    return Ea(hg, fg, G_, W_, $_, H_, B_, O_, t.timeFormat).domain([new Date(2e3, 0, 1), new Date(2e3, 0, 2)]); // NOSONAR
  }, t.scaleUtc = function() { // NOSONAR
    return Ea(Ug, Lg, xg, yg, _g, dg, B_, O_, t.utcFormat).domain([Date.UTC(2e3, 0, 1), Date.UTC(2e3, 0, 2)]); // NOSONAR
  }, t.schemeCategory10 = Kg, t.schemeCategory20b = ty, t.schemeCategory20c = ny, t.schemeCategory20 = ey, t.interpolateCubehelixDefault = ry, t.interpolateRainbow = function(t) { // NOSONAR
    (t < 0 || t > 1) && (t -= Math.floor(t)); var n = Math.abs(t - .5); return uy.h = 360 * t - 100, uy.s = 1.5 - 1.5 * n, uy.l = .8 - .9 * n, uy + ''; // NOSONAR
  }, t.interpolateWarm = iy, t.interpolateCool = oy, t.interpolateViridis = ay, t.interpolateMagma = cy, t.interpolateInferno = sy, t.interpolatePlasma = fy, t.scaleSequential = Ca, t.creator = $s, t.local = m, t.matcher = Js, t.mouse = nf, t.namespace = Xs, t.namespaces = Hs, t.select = ff, t.selectAll = function(t) { // NOSONAR
    return typeof t === 'string' ? new pt([ document.querySelectorAll(t) ], [ document.documentElement ]) : new pt([ t == null ? [] : t ], sf); // NOSONAR
  }, t.selection = dt, t.selector = ef, t.selectorAll = rf, t.style = B, t.touch = lf, t.touches = function(t, n) { // NOSONAR
    n == null && (n = Ks().touches); for (var e = 0, r = n ? n.length : 0, i = new Array(r); e < r; ++e) { // NOSONAR
      i[e] = tf(t, n[e]); // NOSONAR
    } return i; // NOSONAR
  }, t.window = cf, t.customEvent = k, t.arc = function() { // NOSONAR
    function t() { // NOSONAR
      var t, s, f = +n.apply(this, arguments), l = +e.apply(this, arguments), h = o.apply(this, arguments) - by, p = u.apply(this, arguments) - by, d = hy(p - h), v = p > h; if (c || (c = t = ve()), l < f && (s = l, l = f, f = s), l > my) { // NOSONAR
        if (d > wy - my) { // NOSONAR
          c.moveTo(l * dy(h), l * gy(h)), c.arc(0, 0, l, h, p, !v), f > my && (c.moveTo(f * dy(p), f * gy(p)), c.arc(0, 0, f, p, h, v)); // NOSONAR
        } else { // NOSONAR
          var _, g, y = h, m = p, x = h, b = p, w = d, M = d, T = a.apply(this, arguments) / 2, N = T > my && (i ? +i.apply(this, arguments) : yy(f * f + l * l)), k = _y(hy(l - f) / 2, +r.apply(this, arguments)), S = k, E = k; if (N > my) { // NOSONAR
            var A = Pa(N / f * gy(T)), C = Pa(N / l * gy(T)); (w -= 2 * A) > my ? (A *= v ? 1 : -1, x += A, b -= A) : (w = 0, x = b = (h + p) / 2), (M -= 2 * C) > my ? (C *= v ? 1 : -1, y += C, m -= C) : (M = 0, y = m = (h + p) / 2); // NOSONAR
          } var z = l * dy(y), P = l * gy(y), R = f * dy(b), L = f * gy(b); if (k > my) { // NOSONAR
            var q = l * dy(m), U = l * gy(m), D = f * dy(x), O = f * gy(x); if (d < xy) { // NOSONAR
              var F = w > my ? Oa(z, P, D, O, q, U, R, L) : [R, L], I = z - F[0], Y = P - F[1], B = q - F[0], j = U - F[1], H = 1 / gy(za((I * B + Y * j) / (yy(I * I + Y * Y) * yy(B * B + j * j))) / 2), X = yy(F[0] * F[0] + F[1] * F[1]); S = _y(k, (f - X) / (H - 1)), E = _y(k, (l - X) / (H + 1)); // NOSONAR
            } // NOSONAR
          }M > my ? E > my ? (_ = Fa(D, O, z, P, l, E, v), g = Fa(q, U, R, L, l, E, v), c.moveTo(_.cx + _.x01, _.cy + _.y01), E < k ? c.arc(_.cx, _.cy, E, py(_.y01, _.x01), py(g.y01, g.x01), !v) : (c.arc(_.cx, _.cy, E, py(_.y01, _.x01), py(_.y11, _.x11), !v), c.arc(0, 0, l, py(_.cy + _.y11, _.cx + _.x11), py(g.cy + g.y11, g.cx + g.x11), !v), c.arc(g.cx, g.cy, E, py(g.y11, g.x11), py(g.y01, g.x01), !v))) : (c.moveTo(z, P), c.arc(0, 0, l, y, m, !v)) : c.moveTo(z, P), f > my && w > my ? S > my ? (_ = Fa(R, L, q, U, f, -S, v), g = Fa(z, P, D, O, f, -S, v), c.lineTo(_.cx + _.x01, _.cy + _.y01), S < k ? c.arc(_.cx, _.cy, S, py(_.y01, _.x01), py(g.y01, g.x01), !v) : (c.arc(_.cx, _.cy, S, py(_.y01, _.x01), py(_.y11, _.x11), !v), c.arc(0, 0, f, py(_.cy + _.y11, _.cx + _.x11), py(g.cy + g.y11, g.cx + g.x11), v), c.arc(g.cx, g.cy, S, py(g.y11, g.x11), py(g.y01, g.x01), !v))) : c.arc(0, 0, f, b, x, v) : c.lineTo(R, L); // NOSONAR
        } // NOSONAR
      } else { // NOSONAR
        c.moveTo(0, 0); // NOSONAR
      } if (c.closePath(), t) { // NOSONAR
        return c = null, t + '' || null; // NOSONAR
      } // NOSONAR
    } var n = Ra, e = La, r = ly(0), i = null, o = qa, u = Ua, a = Da, c = null; return t.centroid = function() { // NOSONAR
      var t = (+n.apply(this, arguments) + +e.apply(this, arguments)) / 2, r = (+o.apply(this, arguments) + +u.apply(this, arguments)) / 2 - xy / 2; return [dy(r) * t, gy(r) * t]; // NOSONAR
    }, t.innerRadius = function(e) { // NOSONAR
      return arguments.length ? (n = typeof e === 'function' ? e : ly(+e), t) : n; // NOSONAR
    }, t.outerRadius = function(n) { // NOSONAR
      return arguments.length ? (e = typeof n === 'function' ? n : ly(+n), t) : e; // NOSONAR
    }, t.cornerRadius = function(n) { // NOSONAR
      return arguments.length ? (r = typeof n === 'function' ? n : ly(+n), t) : r; // NOSONAR
    }, t.padRadius = function(n) { // NOSONAR
      return arguments.length ? (i = n == null ? null : typeof n === 'function' ? n : ly(+n), t) : i; // NOSONAR
    }, t.startAngle = function(n) { // NOSONAR
      return arguments.length ? (o = typeof n === 'function' ? n : ly(+n), t) : o; // NOSONAR
    }, t.endAngle = function(n) { // NOSONAR
      return arguments.length ? (u = typeof n === 'function' ? n : ly(+n), t) : u; // NOSONAR
    }, t.padAngle = function(n) { // NOSONAR
      return arguments.length ? (a = typeof n === 'function' ? n : ly(+n), t) : a; // NOSONAR
    }, t.context = function(n) { // NOSONAR
      return arguments.length ? (c = n == null ? null : n, t) : c; // NOSONAR
    }, t; // NOSONAR
  }, t.area = Ny, t.line = Ty, t.pie = function() { // NOSONAR
    function t(t) { // NOSONAR
      var a, c, s, f, l, h = t.length, p = 0, d = new Array(h), v = new Array(h), _ = +i.apply(this, arguments), g = Math.min(wy, Math.max(-wy, o.apply(this, arguments) - _)), y = Math.min(Math.abs(g) / h, u.apply(this, arguments)), m = y * (g < 0 ? -1 : 1); for (a = 0; a < h; ++a) { // NOSONAR
        (l = v[d[a] = a] = +n(t[a], a, t)) > 0 && (p += l); // NOSONAR
      } for (e != null ? d.sort(function(t, n) { // NOSONAR
        return e(v[t], v[n]); // NOSONAR
      }) : r != null && d.sort(function(n, e) { // NOSONAR
        return r(t[n], t[e]); // NOSONAR
      }), a = 0, s = p ? (g - h * m) / p : 0; a < h; ++a, _ = f) { // NOSONAR
        c = d[a], f = _ + ((l = v[c]) > 0 ? l * s : 0) + m, v[c] = {data: t[c], index: a, value: l, startAngle: _, endAngle: f, padAngle: y}; // NOSONAR
      } return v; // NOSONAR
    } var n = Sy, e = ky, r = null, i = ly(0), o = ly(wy), u = ly(0); return t.value = function(e) { // NOSONAR
      return arguments.length ? (n = typeof e === 'function' ? e : ly(+e), t) : n; // NOSONAR
    }, t.sortValues = function(n) { // NOSONAR
      return arguments.length ? (e = n, r = null, t) : e; // NOSONAR
    }, t.sort = function(n) { // NOSONAR
      return arguments.length ? (r = n, e = null, t) : r; // NOSONAR
    }, t.startAngle = function(n) { // NOSONAR
      return arguments.length ? (i = typeof n === 'function' ? n : ly(+n), t) : i; // NOSONAR
    }, t.endAngle = function(n) { // NOSONAR
      return arguments.length ? (o = typeof n === 'function' ? n : ly(+n), t) : o; // NOSONAR
    }, t.padAngle = function(n) { // NOSONAR
      return arguments.length ? (u = typeof n === 'function' ? n : ly(+n), t) : u; // NOSONAR
    }, t; // NOSONAR
  }, t.areaRadial = Cy, t.radialArea = Cy, t.lineRadial = Ay, t.radialLine = Ay, t.pointRadial = zy, t.linkHorizontal = function() { // NOSONAR
    return Wa(Za); // NOSONAR
  }, t.linkVertical = function() { // NOSONAR
    return Wa(Ga); // NOSONAR
  }, t.linkRadial = function() { // NOSONAR
    var t = Wa(Ja); return t.angle = t.x, delete t.x, t.radius = t.y, delete t.y, t; // NOSONAR
  }, t.symbol = function() { // NOSONAR
    function t() { // NOSONAR
      var t; if (r || (r = t = ve()), n.apply(this, arguments).draw(r, +e.apply(this, arguments)), t) { // NOSONAR
        return r = null, t + '' || null; // NOSONAR
      } // NOSONAR
    } var n = ly(Ry), e = ly(64), r = null; return t.type = function(e) { // NOSONAR
      return arguments.length ? (n = typeof e === 'function' ? e : ly(e), t) : n; // NOSONAR
    }, t.size = function(n) { // NOSONAR
      return arguments.length ? (e = typeof n === 'function' ? n : ly(+n), t) : e; // NOSONAR
    }, t.context = function(n) { // NOSONAR
      return arguments.length ? (r = n == null ? null : n, t) : r; // NOSONAR
    }, t; // NOSONAR
  }, t.symbols = Gy, t.symbolCircle = Ry, t.symbolCross = Ly, t.symbolDiamond = Dy, t.symbolSquare = By, t.symbolStar = Yy, t.symbolTriangle = Hy, t.symbolWye = Zy, t.curveBasisClosed = function(t) { // NOSONAR
    return new tc(t); // NOSONAR
  }, t.curveBasisOpen = function(t) { // NOSONAR
    return new nc(t); // NOSONAR
  }, t.curveBasis = function(t) { // NOSONAR
    return new Ka(t); // NOSONAR
  }, t.curveBundle = Qy, t.curveCardinalClosed = tm, t.curveCardinalOpen = nm, t.curveCardinal = Ky, t.curveCatmullRomClosed = rm, t.curveCatmullRomOpen = im, t.curveCatmullRom = em, t.curveLinearClosed = function(t) { // NOSONAR
    return new lc(t); // NOSONAR
  }, t.curveLinear = My, t.curveMonotoneX = function(t) { // NOSONAR
    return new _c(t); // NOSONAR
  }, t.curveMonotoneY = function(t) { // NOSONAR
    return new gc(t); // NOSONAR
  }, t.curveNatural = function(t) { // NOSONAR
    return new mc(t); // NOSONAR
  }, t.curveStep = function(t) { // NOSONAR
    return new bc(t, .5); // NOSONAR
  }, t.curveStepAfter = function(t) { // NOSONAR
    return new bc(t, 1); // NOSONAR
  }, t.curveStepBefore = function(t) { // NOSONAR
    return new bc(t, 0); // NOSONAR
  }, t.stack = function() { // NOSONAR
    function t(t) { // NOSONAR
      var o, u, a = n.apply(this, arguments), c = t.length, s = a.length, f = new Array(s); for (o = 0; o < s; ++o) { // NOSONAR
        for (var l, h = a[o], p = f[o] = new Array(c), d = 0; d < c; ++d) { // NOSONAR
          p[d] = l = [0, +i(t[d], h, d, t)], l.data = t[d]; // NOSONAR
        }p.key = h; // NOSONAR
      } for (o = 0, u = e(f); o < s; ++o) { // NOSONAR
        f[u[o]].index = o; // NOSONAR
      } return r(f, u), f; // NOSONAR
    } var n = ly([]), e = um, r = om, i = wc; return t.keys = function(e) { // NOSONAR
      return arguments.length ? (n = typeof e === 'function' ? e : ly(Py.call(e)), t) : n; // NOSONAR
    }, t.value = function(n) { // NOSONAR
      return arguments.length ? (i = typeof n === 'function' ? n : ly(+n), t) : i; // NOSONAR
    }, t.order = function(n) { // NOSONAR
      return arguments.length ? (e = n == null ? um : typeof n === 'function' ? n : ly(Py.call(n)), t) : e; // NOSONAR
    }, t.offset = function(n) { // NOSONAR
      return arguments.length ? (r = n == null ? om : n, t) : r; // NOSONAR
    }, t; // NOSONAR
  }, t.stackOffsetExpand = function(t, n) { // NOSONAR
    if ((r = t.length) > 0) { // NOSONAR
      for (var e, r, i, o = 0, u = t[0].length; o < u; ++o) { // NOSONAR
        for (i = e = 0; e < r; ++e) { // NOSONAR
          i += t[e][o][1] || 0; // NOSONAR
        } if (i) { // NOSONAR
          for (e = 0; e < r; ++e) { // NOSONAR
            t[e][o][1] /= i; // NOSONAR
          } // NOSONAR
        } // NOSONAR
      }om(t, n); // NOSONAR
    } // NOSONAR
  }, t.stackOffsetDiverging = function(t, n) { // NOSONAR
    if ((a = t.length) > 1) { // NOSONAR
      for (var e, r, i, o, u, a, c = 0, s = t[n[0]].length; c < s; ++c) { // NOSONAR
        for (o = u = 0, e = 0; e < a; ++e) { // NOSONAR
          (i = (r = t[n[e]][c])[1] - r[0]) >= 0 ? (r[0] = o, r[1] = o += i) : i < 0 ? (r[1] = u, r[0] = u += i) : r[0] = o; // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } // NOSONAR
  }, t.stackOffsetNone = om, t.stackOffsetSilhouette = function(t, n) { // NOSONAR
    if ((e = t.length) > 0) { // NOSONAR
      for (var e, r = 0, i = t[n[0]], o = i.length; r < o; ++r) { // NOSONAR
        for (var u = 0, a = 0; u < e; ++u) { // NOSONAR
          a += t[u][r][1] || 0; // NOSONAR
        }i[r][1] += i[r][0] = -a / 2; // NOSONAR
      }om(t, n); // NOSONAR
    } // NOSONAR
  }, t.stackOffsetWiggle = function(t, n) { // NOSONAR
    if ((i = t.length) > 0 && (r = (e = t[n[0]]).length) > 0) { // NOSONAR
      for (var e, r, i, o = 0, u = 1; u < r; ++u) { // NOSONAR
        for (var a = 0, c = 0, s = 0; a < i; ++a) { // NOSONAR
          for (var f = t[n[a]], l = f[u][1] || 0, h = (l - (f[u - 1][1] || 0)) / 2, p = 0; p < a; ++p) { // NOSONAR
            var d = t[n[p]]; h += (d[u][1] || 0) - (d[u - 1][1] || 0); // NOSONAR
          }c += l, s += h * l; // NOSONAR
        }e[u - 1][1] += e[u - 1][0] = o, c && (o -= s / c); // NOSONAR
      }e[u - 1][1] += e[u - 1][0] = o, om(t, n); // NOSONAR
    } // NOSONAR
  }, t.stackOrderAscending = am, t.stackOrderDescending = function(t) { // NOSONAR
    return am(t).reverse(); // NOSONAR
  }, t.stackOrderInsideOut = function(t) { // NOSONAR
    var n, e, r = t.length, i = t.map(Mc), o = um(t).sort(function(t, n) { // NOSONAR
        return i[n] - i[t]; // NOSONAR
      }), u = 0, a = 0, c = [], s = []; for (n = 0; n < r; ++n) { // NOSONAR
      e = o[n], u < a ? (u += i[e], c.push(e)) : (a += i[e], s.push(e)); // NOSONAR
    } return s.reverse().concat(c); // NOSONAR
  }, t.stackOrderNone = um, t.stackOrderReverse = function(t) { // NOSONAR
    return um(t).reverse(); // NOSONAR
  }, t.timeInterval = Nu, t.timeMillisecond = O_, t.timeMilliseconds = F_, t.utcMillisecond = O_, t.utcMilliseconds = F_, t.timeSecond = B_, t.timeSeconds = j_, t.utcSecond = B_, t.utcSeconds = j_, t.timeMinute = H_, t.timeMinutes = X_, t.timeHour = $_, t.timeHours = V_, t.timeDay = W_, t.timeDays = Z_, t.timeWeek = G_, t.timeWeeks = rg, t.timeSunday = G_, t.timeSundays = rg, t.timeMonday = J_, t.timeMondays = ig, t.timeTuesday = Q_, t.timeTuesdays = og, t.timeWednesday = K_, t.timeWednesdays = ug, t.timeThursday = tg, t.timeThursdays = ag, t.timeFriday = ng, t.timeFridays = cg, t.timeSaturday = eg, t.timeSaturdays = sg, t.timeMonth = fg, t.timeMonths = lg, t.timeYear = hg, t.timeYears = pg, t.utcMinute = dg, t.utcMinutes = vg, t.utcHour = _g, t.utcHours = gg, t.utcDay = yg, t.utcDays = mg, t.utcWeek = xg, t.utcWeeks = Sg, t.utcSunday = xg, t.utcSundays = Sg, t.utcMonday = bg, t.utcMondays = Eg, t.utcTuesday = wg, t.utcTuesdays = Ag, t.utcWednesday = Mg, t.utcWednesdays = Cg, t.utcThursday = Tg, t.utcThursdays = zg, t.utcFriday = Ng, t.utcFridays = Pg, t.utcSaturday = kg, t.utcSaturdays = Rg, t.utcMonth = Lg, t.utcMonths = qg, t.utcYear = Ug, t.utcYears = Og, t.timeFormatDefaultLocale = Na, t.timeFormatLocale = zu, t.isoFormat = jg, t.isoParse = Hg, t.now = ln, t.timer = dn, t.timerFlush = vn, t.timeout = Ll, t.interval = function(t, n, e) { // NOSONAR
    var r = new pn, i = n; return n == null ? (r.restart(t, n, e), r) : (n = +n, e = e == null ? ln() : +e, r.restart(function o(u) { // NOSONAR
      u += i, r.restart(o, i += n, e), t(u); // NOSONAR
    }, n, e), r); // NOSONAR
  }, t.transition = Jn, t.active = function(t, n) { // NOSONAR
    var e, r, i = t.__transition; if (i) { // NOSONAR
      n = n == null ? null : n + ''; for (r in i) { // NOSONAR
        if ((e = i[r]).state > Ol && e.name === n) { // NOSONAR
          return new Gn([ [ t ] ], mh, n, +r); // NOSONAR
        } // NOSONAR
      } // NOSONAR
    } return null; // NOSONAR
  }, t.interrupt = Xl, t.voronoi = function() { // NOSONAR
    function t(t) { // NOSONAR
      return new ns(t.map(function(r, i) { // NOSONAR
        var o = [Math.round(n(r, i, t) / _m) * _m, Math.round(e(r, i, t) / _m) * _m]; return o.index = i, o.data = r, o; // NOSONAR
      }), r); // NOSONAR
    } var n = Tc, e = Nc, r = null; return t.polygons = function(n) { // NOSONAR
      return t(n).polygons(); // NOSONAR
    }, t.links = function(n) { // NOSONAR
      return t(n).links(); // NOSONAR
    }, t.triangles = function(n) { // NOSONAR
      return t(n).triangles(); // NOSONAR
    }, t.x = function(e) { // NOSONAR
      return arguments.length ? (n = typeof e === 'function' ? e : cm(+e), t) : n; // NOSONAR
    }, t.y = function(n) { // NOSONAR
      return arguments.length ? (e = typeof n === 'function' ? n : cm(+n), t) : e; // NOSONAR
    }, t.extent = function(n) { // NOSONAR
      return arguments.length ? (r = n == null ? null : [[+n[0][0], +n[0][1]], [+n[1][0], +n[1][1]]], t) : r && [[r[0][0], r[0][1]], [r[1][0], r[1][1]]]; // NOSONAR
    }, t.size = function(n) { // NOSONAR
      return arguments.length ? (r = n == null ? null : [[0, 0], [+n[0], +n[1]]], t) : r && [r[1][0] - r[0][0], r[1][1] - r[0][1]]; // NOSONAR
    }, t; // NOSONAR
  }, t.zoom = function() { // NOSONAR
    function n(t) { // NOSONAR
      t.property('__zoom', cs).on('wheel.zoom', s).on('mousedown.zoom', f).on('dblclick.zoom', l).filter(b).on('touchstart.zoom', p).on('touchmove.zoom', d).on('touchend.zoom touchcancel.zoom', v).style('touch-action', 'none').style('-webkit-tap-highlight-color', 'rgba(0,0,0,0)'); // NOSONAR
    } function e(t, n) { // NOSONAR
      return (n = Math.max(w, Math.min(M, n))) === t.k ? t : new rs(n, t.x, t.y); // NOSONAR
    } function r(t, n, e) { // NOSONAR
      var r = n[0] - e[0] * t.k, i = n[1] - e[1] * t.k; return r === t.x && i === t.y ? t : new rs(t.k, r, i); // NOSONAR
    } function i(t, n) { // NOSONAR
      var e = t.invertX(n[0][0]) - T, r = t.invertX(n[1][0]) - N, i = t.invertY(n[0][1]) - S, o = t.invertY(n[1][1]) - E; return t.translate(r > e ? (e + r) / 2 : Math.min(0, e) || Math.max(0, r), o > i ? (i + o) / 2 : Math.min(0, i) || Math.max(0, o)); // NOSONAR
    } function o(t) { // NOSONAR
      return [(+t[0][0] + +t[1][0]) / 2, (+t[0][1] + +t[1][1]) / 2]; // NOSONAR
    } function u(t, n, e) { // NOSONAR
      t.on('start.zoom', function() { // NOSONAR
        a(this, arguments).start(); // NOSONAR
      }).on('interrupt.zoom end.zoom', function() { // NOSONAR
        a(this, arguments).end(); // NOSONAR
      }).tween('zoom', function() { // NOSONAR
        var t = this, r = arguments, i = a(t, r), u = m.apply(t, r), c = e || o(u), s = Math.max(u[1][0] - u[0][0], u[1][1] - u[0][1]), f = t.__zoom, l = typeof n === 'function' ? n.apply(t, r) : n, h = C(f.invert(c).concat(s / f.k), l.invert(c).concat(s / l.k)); return function(t) { // NOSONAR
          if (t === 1) { // NOSONAR
            t = l; // NOSONAR
          } else { // NOSONAR
            var n = h(t), e = s / n[2]; t = new rs(e, c[0] - n[0] * e, c[1] - n[1] * e); // NOSONAR
          }i.zoom(null, t); // NOSONAR
        }; // NOSONAR
      }); // NOSONAR
    } function a(t, n) { // NOSONAR
      for (var e, r = 0, i = z.length; r < i; ++r) { // NOSONAR
        if ((e = z[r]).that === t) { // NOSONAR
          return e; // NOSONAR
        } // NOSONAR
      } return new c(t, n); // NOSONAR
    } function c(t, n) { // NOSONAR
      this.that = t, this.args = n, this.index = -1, this.active = 0, this.extent = m.apply(t, n); // NOSONAR
    } function s() { // NOSONAR
      if (y.apply(this, arguments)) { // NOSONAR
        var t = a(this, arguments), n = this.__zoom, o = Math.max(w, Math.min(M, n.k * Math.pow(2, x.apply(this, arguments)))), u = nf(this); if (t.wheel) { // NOSONAR
          t.mouse[0][0] === u[0] && t.mouse[0][1] === u[1] || (t.mouse[1] = n.invert(t.mouse[0] = u)), clearTimeout(t.wheel); // NOSONAR
        } else { // NOSONAR
          if (n.k === o) { // NOSONAR
            return; // NOSONAR
          } t.mouse = [u, n.invert(u)], Xl(this), t.start(); // NOSONAR
        }xm(), t.wheel = setTimeout(function() { // NOSONAR
          t.wheel = null, t.end(); // NOSONAR
        }, L), t.zoom('mouse', i(r(e(n, o), t.mouse[0], t.mouse[1]), t.extent)); // NOSONAR
      } // NOSONAR
    } function f() { // NOSONAR
      if (!g && y.apply(this, arguments)) { // NOSONAR
        var n = a(this, arguments), e = ff(t.event.view).on('mousemove.zoom', function() { // NOSONAR
            if (xm(), !n.moved) { // NOSONAR
              var e = t.event.clientX - u, o = t.event.clientY - c; n.moved = e * e + o * o > q; // NOSONAR
            }n.zoom('mouse', i(r(n.that.__zoom, n.mouse[0] = nf(n.that), n.mouse[1]), n.extent)); // NOSONAR
          }, !0).on('mouseup.zoom', function() { // NOSONAR
            e.on('mousemove.zoom mouseup.zoom', null), _t(t.event.view, n.moved), xm(), n.end(); // NOSONAR
          }, !0), o = nf(this), u = t.event.clientX, c = t.event.clientY; pf(t.event.view), os(), n.mouse = [o, this.__zoom.invert(o)], Xl(this), n.start(); // NOSONAR
      } // NOSONAR
    } function l() { // NOSONAR
      if (y.apply(this, arguments)) { // NOSONAR
        var o = this.__zoom, a = nf(this), c = o.invert(a), s = i(r(e(o, o.k * (t.event.shiftKey ? .5 : 2)), a, c), m.apply(this, arguments)); xm(), A > 0 ? ff(this).transition().duration(A).call(u, s, a) : ff(this).call(n.transform, s); // NOSONAR
      } // NOSONAR
    } function p() { // NOSONAR
      if (y.apply(this, arguments)) { // NOSONAR
        var n, e, r, i, o = a(this, arguments), u = t.event.changedTouches, c = u.length; for (os(), e = 0; e < c; ++e) { // NOSONAR
          r = u[e], i = [i = lf(this, u, r.identifier), this.__zoom.invert(i), r.identifier], o.touch0 ? o.touch1 || (o.touch1 = i) : (o.touch0 = i, n = !0); // NOSONAR
        } if (_ && (_ = clearTimeout(_), !o.touch1)) { // NOSONAR
          return o.end(), void((i = ff(this).on('dblclick.zoom')) && i.apply(this, arguments)); // NOSONAR
        } n && (_ = setTimeout(function() { // NOSONAR
          _ = null; // NOSONAR
        }, R), Xl(this), o.start()); // NOSONAR
      } // NOSONAR
    } function d() { // NOSONAR
      var n, o, u, c, s = a(this, arguments), f = t.event.changedTouches, l = f.length; for (xm(), _ && (_ = clearTimeout(_)), n = 0; n < l; ++n) { // NOSONAR
        o = f[n], u = lf(this, f, o.identifier), s.touch0 && s.touch0[2] === o.identifier ? s.touch0[0] = u : s.touch1 && s.touch1[2] === o.identifier && (s.touch1[0] = u); // NOSONAR
      } if (o = s.that.__zoom, s.touch1) { // NOSONAR
        var h = s.touch0[0], p = s.touch0[1], d = s.touch1[0], v = s.touch1[1], g = (g = d[0] - h[0]) * g + (g = d[1] - h[1]) * g, y = (y = v[0] - p[0]) * y + (y = v[1] - p[1]) * y; o = e(o, Math.sqrt(g / y)), u = [(h[0] + d[0]) / 2, (h[1] + d[1]) / 2], c = [(p[0] + v[0]) / 2, (p[1] + v[1]) / 2]; // NOSONAR
      } else { // NOSONAR
        if (!s.touch0) { // NOSONAR
          return; // NOSONAR
        } u = s.touch0[0], c = s.touch0[1]; // NOSONAR
      }s.zoom('touch', i(r(o, u, c), s.extent)); // NOSONAR
    } function v() { // NOSONAR
      var n, e, r = a(this, arguments), i = t.event.changedTouches, o = i.length; for (os(), g && clearTimeout(g), g = setTimeout(function() { // NOSONAR
        g = null; // NOSONAR
      }, R), n = 0; n < o; ++n) { // NOSONAR
        e = i[n], r.touch0 && r.touch0[2] === e.identifier ? delete r.touch0 : r.touch1 && r.touch1[2] === e.identifier && delete r.touch1; // NOSONAR
      }r.touch1 && !r.touch0 && (r.touch0 = r.touch1, delete r.touch1), r.touch0 ? r.touch0[1] = this.__zoom.invert(r.touch0[0]) : r.end(); // NOSONAR
    } var _, g, y = us, m = as, x = ss, b = fs, w = 0, M = 1 / 0, T = -M, N = M, S = T, E = N, A = 250, C = yl, z = [], P = h('start', 'zoom', 'end'), R = 500, L = 150, q = 0; return n.transform = function(t, n) { // NOSONAR
      var e = t.selection ? t.selection() : t; e.property('__zoom', cs), t !== e ? u(t, n) : e.interrupt().each(function() { // NOSONAR
        a(this, arguments).start().zoom(null, typeof n === 'function' ? n.apply(this, arguments) : n).end(); // NOSONAR
      }); // NOSONAR
    }, n.scaleBy = function(t, e) { // NOSONAR
      n.scaleTo(t, function() { // NOSONAR
        return this.__zoom.k * (typeof e === 'function' ? e.apply(this, arguments) : e); // NOSONAR
      }); // NOSONAR
    }, n.scaleTo = function(t, u) { // NOSONAR
      n.transform(t, function() { // NOSONAR
        var t = m.apply(this, arguments), n = this.__zoom, a = o(t), c = n.invert(a); return i(r(e(n, typeof u === 'function' ? u.apply(this, arguments) : u), a, c), t); // NOSONAR
      }); // NOSONAR
    }, n.translateBy = function(t, e, r) { // NOSONAR
      n.transform(t, function() { // NOSONAR
        return i(this.__zoom.translate(typeof e === 'function' ? e.apply(this, arguments) : e, typeof r === 'function' ? r.apply(this, arguments) : r), m.apply(this, arguments)); // NOSONAR
      }); // NOSONAR
    }, n.translateTo = function(t, e, r) { // NOSONAR
      n.transform(t, function() { // NOSONAR
        var t = m.apply(this, arguments), n = this.__zoom, u = o(t); return i(mm.translate(u[0], u[1]).scale(n.k).translate(typeof e === 'function' ? -e.apply(this, arguments) : -e, typeof r === 'function' ? -r.apply(this, arguments) : -r), t); // NOSONAR
      }); // NOSONAR
    }, c.prototype = {start: function() { // NOSONAR
      return ++this.active == 1 && (this.index = z.push(this) - 1, this.emit('start')), this; // NOSONAR
    }, zoom: function(t, n) { // NOSONAR
      return this.mouse && t !== 'mouse' && (this.mouse[1] = n.invert(this.mouse[0])), this.touch0 && t !== 'touch' && (this.touch0[1] = n.invert(this.touch0[0])), this.touch1 && t !== 'touch' && (this.touch1[1] = n.invert(this.touch1[0])), this.that.__zoom = n, this.emit('zoom'), this; // NOSONAR
    }, end: function() { // NOSONAR
      return --this.active == 0 && (z.splice(this.index, 1), this.index = -1, this.emit('end')), this; // NOSONAR
    }, emit: function(t) { // NOSONAR
      k(new es(n, t, this.that.__zoom), P.apply, P, [t, this.that, this.args]); // NOSONAR
    }}, n.wheelDelta = function(t) { // NOSONAR
      return arguments.length ? (x = typeof t === 'function' ? t : ym(+t), n) : x; // NOSONAR
    }, n.filter = function(t) { // NOSONAR
      return arguments.length ? (y = typeof t === 'function' ? t : ym(!!t), n) : y; // NOSONAR
    }, n.touchable = function(t) { // NOSONAR
      return arguments.length ? (b = typeof t === 'function' ? t : ym(!!t), n) : b; // NOSONAR
    }, n.extent = function(t) { // NOSONAR
      return arguments.length ? (m = typeof t === 'function' ? t : ym([[+t[0][0], +t[0][1]], [+t[1][0], +t[1][1]]]), n) : m; // NOSONAR
    }, n.scaleExtent = function(t) { // NOSONAR
      return arguments.length ? (w = +t[0], M = +t[1], n) : [w, M]; // NOSONAR
    }, n.translateExtent = function(t) { // NOSONAR
      return arguments.length ? (T = +t[0][0], N = +t[1][0], S = +t[0][1], E = +t[1][1], n) : [[T, S], [N, E]]; // NOSONAR
    }, n.duration = function(t) { // NOSONAR
      return arguments.length ? (A = +t, n) : A; // NOSONAR
    }, n.interpolate = function(t) { // NOSONAR
      return arguments.length ? (C = t, n) : C; // NOSONAR
    }, n.on = function() { // NOSONAR
      var t = P.on.apply(P, arguments); return t === P ? n : t; // NOSONAR
    }, n.clickDistance = function(t) { // NOSONAR
      return arguments.length ? (q = (t = +t) * t, n) : Math.sqrt(q); // NOSONAR
    }, n; // NOSONAR
  }, t.zoomTransform = is, t.zoomIdentity = mm, Object.defineProperty(t, '__esModule', {value: !0}); // NOSONAR
}));