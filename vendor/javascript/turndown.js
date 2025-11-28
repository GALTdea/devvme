// turndown@7.2.2 downloaded from https://ga.jspm.io/npm:turndown@7.2.2/lib/turndown.browser.es.js

function e(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)t.hasOwnProperty(r)&&(e[r]=t[r])}return e}function n(e,n){return Array(n+1).join(e)}function t(e){return e.replace(/^\n*/,"")}function r(e){var n=e.length;while(n>0&&e[n-1]==="\n")n--;return e.substring(0,n)}function i(e){return r(t(e))}var a=["ADDRESS","ARTICLE","ASIDE","AUDIO","BLOCKQUOTE","BODY","CANVAS","CENTER","DD","DIR","DIV","DL","DT","FIELDSET","FIGCAPTION","FIGURE","FOOTER","FORM","FRAMESET","H1","H2","H3","H4","H5","H6","HEADER","HGROUP","HR","HTML","ISINDEX","LI","MAIN","MENU","NAV","NOFRAMES","NOSCRIPT","OL","OUTPUT","P","PRE","SECTION","TABLE","TBODY","TD","TFOOT","TH","THEAD","TR","UL"];function o(e){return p(e,a)}var l=["AREA","BASE","BR","COL","COMMAND","EMBED","HR","IMG","INPUT","KEYGEN","LINK","META","PARAM","SOURCE","TRACK","WBR"];function u(e){return p(e,l)}function c(e){return h(e,l)}var f=["A","TABLE","THEAD","TBODY","TFOOT","TH","TD","IFRAME","SCRIPT","AUDIO","VIDEO"];function s(e){return p(e,f)}function d(e){return h(e,f)}function p(e,n){return n.indexOf(e.nodeName)>=0}function h(e,n){return e.getElementsByTagName&&n.some((function(n){return e.getElementsByTagName(n).length}))}var g={};g.paragraph={filter:"p",replacement:function(e){return"\n\n"+e+"\n\n"}};g.lineBreak={filter:"br",replacement:function(e,n,t){return t.br+"\n"}};g.heading={filter:["h1","h2","h3","h4","h5","h6"],replacement:function(e,t,r){var i=Number(t.nodeName.charAt(1));if(r.headingStyle==="setext"&&i<3){var a=n(i===1?"=":"-",e.length);return"\n\n"+e+"\n"+a+"\n\n"}return"\n\n"+n("#",i)+" "+e+"\n\n"}};g.blockquote={filter:"blockquote",replacement:function(e){e=i(e).replace(/^/gm,"> ");return"\n\n"+e+"\n\n"}};g.list={filter:["ul","ol"],replacement:function(e,n){var t=n.parentNode;return t.nodeName==="LI"&&t.lastElementChild===n?"\n"+e:"\n\n"+e+"\n\n"}};g.listItem={filter:"li",replacement:function(e,n,t){var r=t.bulletListMarker+"   ";var a=n.parentNode;if(a.nodeName==="OL"){var o=a.getAttribute("start");var l=Array.prototype.indexOf.call(a.children,n);r=(o?Number(o)+l:l+1)+".  "}var u=/\n$/.test(e);e=i(e)+(u?"\n":"");e=e.replace(/\n/gm,"\n"+" ".repeat(r.length));return r+e+(n.nextSibling?"\n":"")}};g.indentedCodeBlock={filter:function(e,n){return n.codeBlockStyle==="indented"&&e.nodeName==="PRE"&&e.firstChild&&e.firstChild.nodeName==="CODE"},replacement:function(e,n,t){return"\n\n    "+n.firstChild.textContent.replace(/\n/g,"\n    ")+"\n\n"}};g.fencedCodeBlock={filter:function(e,n){return n.codeBlockStyle==="fenced"&&e.nodeName==="PRE"&&e.firstChild&&e.firstChild.nodeName==="CODE"},replacement:function(e,t,r){var i=t.firstChild.getAttribute("class")||"";var a=(i.match(/language-(\S+)/)||[null,""])[1];var o=t.firstChild.textContent;var l=r.fence.charAt(0);var u=3;var c=new RegExp("^"+l+"{3,}","gm");var f;while(f=c.exec(o))f[0].length>=u&&(u=f[0].length+1);var s=n(l,u);return"\n\n"+s+a+"\n"+o.replace(/\n$/,"")+"\n"+s+"\n\n"}};g.horizontalRule={filter:"hr",replacement:function(e,n,t){return"\n\n"+t.hr+"\n\n"}};g.inlineLink={filter:function(e,n){return n.linkStyle==="inlined"&&e.nodeName==="A"&&e.getAttribute("href")},replacement:function(e,n){var t=n.getAttribute("href");t&&(t=t.replace(/([()])/g,"\\$1"));var r=m(n.getAttribute("title"));r&&(r=' "'+r.replace(/"/g,'\\"')+'"');return"["+e+"]("+t+r+")"}};g.referenceLink={filter:function(e,n){return n.linkStyle==="referenced"&&e.nodeName==="A"&&e.getAttribute("href")},replacement:function(e,n,t){var r=n.getAttribute("href");var i=m(n.getAttribute("title"));i&&(i=' "'+i+'"');var a;var o;switch(t.linkReferenceStyle){case"collapsed":a="["+e+"][]";o="["+e+"]: "+r+i;break;case"shortcut":a="["+e+"]";o="["+e+"]: "+r+i;break;default:var l=this.references.length+1;a="["+e+"]["+l+"]";o="["+l+"]: "+r+i}this.references.push(o);return a},references:[],append:function(e){var n="";if(this.references.length){n="\n\n"+this.references.join("\n")+"\n\n";this.references=[]}return n}};g.emphasis={filter:["em","i"],replacement:function(e,n,t){return e.trim()?t.emDelimiter+e+t.emDelimiter:""}};g.strong={filter:["strong","b"],replacement:function(e,n,t){return e.trim()?t.strongDelimiter+e+t.strongDelimiter:""}};g.code={filter:function(e){var n=e.previousSibling||e.nextSibling;var t=e.parentNode.nodeName==="PRE"&&!n;return e.nodeName==="CODE"&&!t},replacement:function(e){if(!e)return"";e=e.replace(/\r?\n|\r/g," ");var n=/^`|^ .*?[^ ].* $|`$/.test(e)?" ":"";var t="`";var r=e.match(/`+/gm)||[];while(r.indexOf(t)!==-1)t+="`";return t+n+e+n+t}};g.image={filter:"img",replacement:function(e,n){var t=m(n.getAttribute("alt"));var r=n.getAttribute("src")||"";var i=m(n.getAttribute("title"));var a=i?' "'+i+'"':"";return r?"!["+t+"]("+r+a+")":""}};function m(e){return e?e.replace(/(\n+\s*)+/g,"\n"):""}function v(e){this.options=e;this._keep=[];this._remove=[];this.blankRule={replacement:e.blankReplacement};this.keepReplacement=e.keepReplacement;this.defaultRule={replacement:e.defaultReplacement};this.array=[];for(var n in e.rules)this.array.push(e.rules[n])}v.prototype={add:function(e,n){this.array.unshift(n)},keep:function(e){this._keep.unshift({filter:e,replacement:this.keepReplacement})},remove:function(e){this._remove.unshift({filter:e,replacement:function(){return""}})},forNode:function(e){return e.isBlank?this.blankRule:(n=A(this.array,e,this.options))||(n=A(this._keep,e,this.options))||(n=A(this._remove,e,this.options))?n:this.defaultRule;var n},forEach:function(e){for(var n=0;n<this.array.length;n++)e(this.array[n],n)}};function A(e,n,t){for(var r=0;r<e.length;r++){var i=e[r];if(y(i,n,t))return i}}function y(e,n,t){var r=e.filter;if(typeof r==="string"){if(r===n.nodeName.toLowerCase())return true}else if(Array.isArray(r)){if(r.indexOf(n.nodeName.toLowerCase())>-1)return true}else{if(typeof r!=="function")throw new TypeError("`filter` needs to be a string, array, or function");if(r.call(e,n,t))return true}}
/**
 * collapseWhitespace(options) removes extraneous whitespace from an the given element.
 *
 * @param {Object} options
 */function N(e){var n=e.element;var t=e.isBlock;var r=e.isVoid;var i=e.isPre||function(e){return e.nodeName==="PRE"};if(n.firstChild&&!i(n)){var a=null;var o=false;var l=null;var u=T(l,n,i);while(u!==n){if(u.nodeType===3||u.nodeType===4){var c=u.data.replace(/[ \r\n\t]+/g," ");a&&!/ $/.test(a.data)||o||c[0]!==" "||(c=c.substr(1));if(!c){u=E(u);continue}u.data=c;a=u}else{if(u.nodeType!==1){u=E(u);continue}if(t(u)||u.nodeName==="BR"){a&&(a.data=a.data.replace(/ $/,""));a=null;o=false}else if(r(u)||i(u)){a=null;o=true}else a&&(o=false)}var f=T(l,u,i);l=u;u=f}if(a){a.data=a.data.replace(/ $/,"");a.data||E(a)}}}
/**
 * remove(node) removes the given node from the DOM and returns the
 * next node in the sequence.
 *
 * @param {Node} node
 * @return {Node} node
 */function E(e){var n=e.nextSibling||e.parentNode;e.parentNode.removeChild(e);return n}
/**
 * next(prev, current, isPre) returns the next node in the sequence, given the
 * current and previous nodes.
 *
 * @param {Node} prev
 * @param {Node} current
 * @param {Function} isPre
 * @return {Node}
 */function T(e,n,t){return e&&e.parentNode===n||t(n)?n.nextSibling||n.parentNode:n.firstChild||n.nextSibling||n.parentNode}var R=typeof window!=="undefined"?window:{};function C(){var e=R.DOMParser;var n=false;try{(new e).parseFromString("","text/html")&&(n=true)}catch(e){}return n}function k(){var e=function(){};b()?e.prototype.parseFromString=function(e){var n=new window.ActiveXObject("htmlfile");n.designMode="on";n.open();n.write(e);n.close();return n}:e.prototype.parseFromString=function(e){var n=document.implementation.createHTMLDocument("");n.open();n.write(e);n.close();return n};return e}function b(){var e=false;try{document.implementation.createHTMLDocument("").open()}catch(n){R.ActiveXObject&&(e=true)}return e}var O=C()?R.DOMParser:k();function D(e,n){var t;if(typeof e==="string"){var r=w().parseFromString('<x-turndown id="turndown-root">'+e+"</x-turndown>","text/html");t=r.getElementById("turndown-root")}else t=e.cloneNode(true);N({element:t,isBlock:o,isVoid:u,isPre:n.preformattedCode?B:null});return t}var S;function w(){S=S||new O;return S}function B(e){return e.nodeName==="PRE"||e.nodeName==="CODE"}function x(e,n){e.isBlock=o(e);e.isCode=e.nodeName==="CODE"||e.parentNode.isCode;e.isBlank=I(e);e.flankingWhitespace=L(e,n);return e}function I(e){return!u(e)&&!s(e)&&/^\s*$/i.test(e.textContent)&&!c(e)&&!d(e)}function L(e,n){if(e.isBlock||n.preformattedCode&&e.isCode)return{leading:"",trailing:""};var t=M(e.textContent);t.leadingAscii&&H("left",e,n)&&(t.leading=t.leadingNonAscii);t.trailingAscii&&H("right",e,n)&&(t.trailing=t.trailingNonAscii);return{leading:t.leading,trailing:t.trailing}}function M(e){var n=e.match(/^(([ \t\r\n]*)(\s*))(?:(?=\S)[\s\S]*\S)?((\s*?)([ \t\r\n]*))$/);return{leading:n[1],leadingAscii:n[2],leadingNonAscii:n[3],trailing:n[4],trailingNonAscii:n[5],trailingAscii:n[6]}}function H(e,n,t){var r;var i;var a;if(e==="left"){r=n.previousSibling;i=/ $/}else{r=n.nextSibling;i=/^ /}r&&(r.nodeType===3?a=i.test(r.nodeValue):t.preformattedCode&&r.nodeName==="CODE"?a=false:r.nodeType!==1||o(r)||(a=i.test(r.textContent)));return a}var P=Array.prototype.reduce;var F=[[/\\/g,"\\\\"],[/\*/g,"\\*"],[/^-/g,"\\-"],[/^\+ /g,"\\+ "],[/^(=+)/g,"\\$1"],[/^(#{1,6}) /g,"\\$1 "],[/`/g,"\\`"],[/^~~~/g,"\\~~~"],[/\[/g,"\\["],[/\]/g,"\\]"],[/^>/g,"\\>"],[/_/g,"\\_"],[/^(\d+)\. /g,"$1\\. "]];function $(n){if(!(this instanceof $))return new $(n);var t={rules:g,headingStyle:"setext",hr:"* * *",bulletListMarker:"*",codeBlockStyle:"indented",fence:"```",emDelimiter:"_",strongDelimiter:"**",linkStyle:"inlined",linkReferenceStyle:"full",br:"  ",preformattedCode:false,blankReplacement:function(e,n){return n.isBlock?"\n\n":""},keepReplacement:function(e,n){return n.isBlock?"\n\n"+n.outerHTML+"\n\n":n.outerHTML},defaultReplacement:function(e,n){return n.isBlock?"\n\n"+e+"\n\n":e}};this.options=e({},t,n);this.rules=new v(this.options)}$.prototype={
/**
   * The entry point for converting a string or DOM node to Markdown
   * @public
   * @param {String|HTMLElement} input The string or DOM node to convert
   * @returns A Markdown representation of the input
   * @type String
   */
turndown:function(e){if(!j(e))throw new TypeError(e+" is not a string, or an element/document/fragment node.");if(e==="")return"";var n=U.call(this,new D(e,this.options));return V.call(this,n)},
/**
   * Add one or more plugins
   * @public
   * @param {Function|Array} plugin The plugin or array of plugins to add
   * @returns The Turndown instance for chaining
   * @type Object
   */
use:function(e){if(Array.isArray(e))for(var n=0;n<e.length;n++)this.use(e[n]);else{if(typeof e!=="function")throw new TypeError("plugin must be a Function or an Array of Functions");e(this)}return this},
/**
   * Adds a rule
   * @public
   * @param {String} key The unique key of the rule
   * @param {Object} rule The rule
   * @returns The Turndown instance for chaining
   * @type Object
   */
addRule:function(e,n){this.rules.add(e,n);return this},
/**
   * Keep a node (as HTML) that matches the filter
   * @public
   * @param {String|Array|Function} filter The unique key of the rule
   * @returns The Turndown instance for chaining
   * @type Object
   */
keep:function(e){this.rules.keep(e);return this},
/**
   * Remove a node that matches the filter
   * @public
   * @param {String|Array|Function} filter The unique key of the rule
   * @returns The Turndown instance for chaining
   * @type Object
   */
remove:function(e){this.rules.remove(e);return this},
/**
   * Escapes Markdown syntax
   * @public
   * @param {String} string The string to escape
   * @returns A string with Markdown syntax escaped
   * @type String
   */
escape:function(e){return F.reduce((function(e,n){return e.replace(n[0],n[1])}),e)}};
/**
 * Reduces a DOM node down to its Markdown string equivalent
 * @private
 * @param {HTMLElement} parentNode The node to convert
 * @returns A Markdown representation of the node
 * @type String
 */function U(e){var n=this;return P.call(e.childNodes,(function(e,t){t=new x(t,n.options);var r="";t.nodeType===3?r=t.isCode?t.nodeValue:n.escape(t.nodeValue):t.nodeType===1&&(r=_.call(n,t));return G(e,r)}),"")}
/**
 * Appends strings as each rule requires and trims the output
 * @private
 * @param {String} output The conversion output
 * @returns A trimmed version of the ouput
 * @type String
 */function V(e){var n=this;this.rules.forEach((function(t){typeof t.append==="function"&&(e=G(e,t.append(n.options)))}));return e.replace(/^[\t\r\n]+/,"").replace(/[\t\r\n\s]+$/,"")}
/**
 * Converts an element node to its Markdown equivalent
 * @private
 * @param {HTMLElement} node The node to convert
 * @returns A Markdown representation of the node
 * @type String
 */function _(e){var n=this.rules.forNode(e);var t=U.call(this,e);var r=e.flankingWhitespace;(r.leading||r.trailing)&&(t=t.trim());return r.leading+n.replacement(t,e,this.options)+r.trailing}
/**
 * Joins replacement to the current output with appropriate number of new lines
 * @private
 * @param {String} output The current conversion output
 * @param {String} replacement The string to append to the output
 * @returns Joined output
 * @type String
 */function G(e,n){var i=r(e);var a=t(n);var o=Math.max(e.length-i.length,n.length-a.length);var l="\n\n".substring(0,o);return i+l+a}
/**
 * Determines whether an input can be converted
 * @private
 * @param {String|HTMLElement} input Describe this parameter
 * @returns Describe what it returns
 * @type String|Object|Array|Boolean|Number
 */function j(e){return e!=null&&(typeof e==="string"||e.nodeType&&(e.nodeType===1||e.nodeType===9||e.nodeType===11))}export{$ as default};

