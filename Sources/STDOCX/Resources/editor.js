// STKit DOCX Web Editor — JS Bridge
// Handles formatting commands, state tracking, DOM→JSON conversion

(function() {
    'use strict';

    var editor = document.getElementById('editor');
    var isContentDirty = false;
    var currentPageIndex = 0;
    var isNavigating = false;
    var targetPageCount = 0;
    var _isSelectMode = false;
    var _activeCellEdit = null; // Currently focused table cell (nested editable)

    // Debug logging — sends to Swift via message handler
    function jsLog(msg) {
        try { webkit.messageHandlers.jsLog.postMessage(msg); } catch(e) {}
    }

    // ============================================================
    // FORMATTING COMMANDS (called from Swift via evaluateJavaScript)
    // ============================================================

    window.toggleBold = function() {
        document.execCommand('bold', false, null);
        updateFormattingState();
    };

    window.toggleItalic = function() {
        document.execCommand('italic', false, null);
        updateFormattingState();
    };

    window.toggleUnderline = function() {
        document.execCommand('underline', false, null);
        updateFormattingState();
    };

    window.toggleStrikethrough = function() {
        document.execCommand('strikeThrough', false, null);
        updateFormattingState();
    };

    window.setAlignLeft = function() {
        document.execCommand('justifyLeft', false, null);
        updateFormattingState();
    };

    window.setAlignCenter = function() {
        document.execCommand('justifyCenter', false, null);
        updateFormattingState();
    };

    window.setAlignRight = function() {
        document.execCommand('justifyRight', false, null);
        updateFormattingState();
    };

    window.setAlignJustify = function() {
        document.execCommand('justifyFull', false, null);
        updateFormattingState();
    };

    window.increaseFontSize = function() {
        adjustFontSize(1);
    };

    window.decreaseFontSize = function() {
        adjustFontSize(-1);
    };

    window.editorUndo = function() {
        document.execCommand('undo', false, null);
        updateFormattingState();
    };

    window.editorRedo = function() {
        document.execCommand('redo', false, null);
        updateFormattingState();
    };

    window.selectAll = function() {
        document.execCommand('selectAll', false, null);
        updateFormattingState();
    };

    // ============================================================
    // TEXT COLOR & HIGHLIGHT
    // ============================================================

    window.setTextColor = function(hex) {
        document.execCommand('foreColor', false, hex);
        updateFormattingState();
    };

    window.setHighlightColor = function(hex) {
        if (!hex || hex === 'none') {
            document.execCommand('removeFormat', false, 'hiliteColor');
        } else {
            document.execCommand('hiliteColor', false, hex);
        }
        updateFormattingState();
    };

    // ============================================================
    // LISTS
    // ============================================================

    window.toggleBulletList = function() {
        document.execCommand('insertUnorderedList', false, null);
        updateFormattingState();
    };

    window.toggleNumberedList = function() {
        document.execCommand('insertOrderedList', false, null);
        updateFormattingState();
    };

    // ============================================================
    // INDENTATION
    // ============================================================

    window.increaseIndent = function() {
        document.execCommand('indent', false, null);
        updateFormattingState();
    };

    window.decreaseIndent = function() {
        document.execCommand('outdent', false, null);
        updateFormattingState();
    };

    // ============================================================
    // SUBSCRIPT / SUPERSCRIPT
    // ============================================================

    window.toggleSubscript = function() {
        document.execCommand('subscript', false, null);
        updateFormattingState();
    };

    window.toggleSuperscript = function() {
        document.execCommand('superscript', false, null);
        updateFormattingState();
    };

    // ============================================================
    // FONT FAMILY
    // ============================================================

    window.setFontFamily = function(name) {
        document.execCommand('fontName', false, name);
        updateFormattingState();
    };

    // ============================================================
    // LINE SPACING
    // ============================================================

    window.setLineSpacing = function(value) {
        var sel = window.getSelection();
        if (!sel.rangeCount) return;
        var node = sel.anchorNode;
        if (node && node.nodeType === Node.TEXT_NODE) node = node.parentElement;
        // Walk up to block element
        while (node && node !== editor && !isBlockElement(node)) {
            node = node.parentElement;
        }
        if (node && node !== editor) {
            node.style.lineHeight = value;
            notifyContentChanged();
        }
    };

    // ============================================================
    // INSERT TABLE
    // ============================================================

    window.insertTable = function(rows, cols) {
        var html = '<table style="border-collapse:collapse;width:100%;margin:6pt 0;">';
        for (var r = 0; r < rows; r++) {
            html += '<tr>';
            for (var c = 0; c < cols; c++) {
                html += '<td style="border:1px solid #999;padding:4px 8px;min-width:40px;"><p><br></p></td>';
            }
            html += '</tr>';
        }
        html += '</table>';

        var page = getActivePage();
        var sel = window.getSelection();
        var temp = document.createElement('div');
        temp.innerHTML = html;
        var table = temp.firstChild;

        if (sel.rangeCount) {
            var range = sel.getRangeAt(0);
            var block = range.startContainer;
            while (block && block.parentNode !== page && block !== page) {
                block = block.parentNode;
            }
            if (block && block !== page && block.parentNode === page) {
                page.insertBefore(table, block.nextSibling);
            } else {
                page.appendChild(table);
            }
        } else {
            page.appendChild(table);
        }
        // Place cursor in first cell and scroll into view
        var firstCell = table.querySelector('td');
        if (firstCell) {
            var range2 = document.createRange();
            range2.selectNodeContents(firstCell);
            range2.collapse(true);
            sel.removeAllRanges();
            sel.addRange(range2);
            // Scroll table into view with margin for keyboard
            setTimeout(function() {
                table.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }, 100);
        }
        notifyContentChanged();
    };

    // ============================================================
    // TABLE TEMPLATES
    // ============================================================

    var tableTemplates = {
        // --- Basic styled tables ---
        'header-blue': {
            name: 'Blue Header',
            headerBg: '#4472C4', headerFg: '#FFFFFF',
            stripeBg: '#D6E4F0', bodyBg: '#FFFFFF',
            borderColor: '#4472C4', rows: 4, cols: 3
        },
        'header-green': {
            name: 'Green Header',
            headerBg: '#548235', headerFg: '#FFFFFF',
            stripeBg: '#E2EFDA', bodyBg: '#FFFFFF',
            borderColor: '#548235', rows: 4, cols: 3
        },
        'header-orange': {
            name: 'Orange Header',
            headerBg: '#ED7D31', headerFg: '#FFFFFF',
            stripeBg: '#FCE4D6', bodyBg: '#FFFFFF',
            borderColor: '#ED7D31', rows: 4, cols: 3
        },
        'header-purple': {
            name: 'Purple Header',
            headerBg: '#7030A0', headerFg: '#FFFFFF',
            stripeBg: '#E4DFEC', bodyBg: '#FFFFFF',
            borderColor: '#7030A0', rows: 4, cols: 3
        },
        'header-red': {
            name: 'Red Header',
            headerBg: '#C00000', headerFg: '#FFFFFF',
            stripeBg: '#F4CCCC', bodyBg: '#FFFFFF',
            borderColor: '#C00000', rows: 4, cols: 3
        },
        'header-dark': {
            name: 'Dark Header',
            headerBg: '#333333', headerFg: '#FFFFFF',
            stripeBg: '#F2F2F2', bodyBg: '#FFFFFF',
            borderColor: '#999999', rows: 4, cols: 3
        },
        // --- Grid (no header highlight) ---
        'grid-light': {
            name: 'Light Grid',
            headerBg: '#F2F2F2', headerFg: '#000000',
            stripeBg: '#F9F9F9', bodyBg: '#FFFFFF',
            borderColor: '#D9D9D9', rows: 4, cols: 3
        },
        'grid-blue': {
            name: 'Blue Grid',
            headerBg: '#D6E4F0', headerFg: '#1F3864',
            stripeBg: '#EAF0F7', bodyBg: '#FFFFFF',
            borderColor: '#B4C6E7', rows: 4, cols: 3
        },
        // --- Additional styles ---
        'plain': {
            name: 'Plain',
            headerBg: '#FFFFFF', headerFg: '#000000',
            stripeBg: '#F2F2F2', bodyBg: '#FFFFFF',
            borderColor: '#999999', rows: 4, cols: 3
        },
        'header-gold': {
            name: 'Gold Header',
            headerBg: '#BF8F00', headerFg: '#FFFFFF',
            stripeBg: '#FFF2CC', bodyBg: '#FFFFFF',
            borderColor: '#BF8F00', rows: 4, cols: 3
        },
        'header-teal': {
            name: 'Teal Header',
            headerBg: '#2E75B6', headerFg: '#FFFFFF',
            stripeBg: '#DAEEF3', bodyBg: '#FFFFFF',
            borderColor: '#2E75B6', rows: 4, cols: 3
        },
        'grid-green': {
            name: 'Green Grid',
            headerBg: '#E2EFDA', headerFg: '#375623',
            stripeBg: '#F0F7EC', bodyBg: '#FFFFFF',
            borderColor: '#A9D18E', rows: 4, cols: 3
        },
        'grid-orange': {
            name: 'Orange Grid',
            headerBg: '#FCE4D6', headerFg: '#833C0B',
            stripeBg: '#FDF0E8', bodyBg: '#FFFFFF',
            borderColor: '#F4B183', rows: 4, cols: 3
        }
    };

    /// Build styled table HTML from a template config
    function buildTemplateTableHTML(tmpl, rows, cols) {
        rows = rows || tmpl.rows;
        cols = cols || tmpl.cols;
        var html = '<table style="border-collapse:collapse;width:100%;margin:6pt 0;" data-template-header="' + tmpl.headerBg + '" data-template-stripe="' + tmpl.stripeBg + '" data-template-border="' + tmpl.borderColor + '">';
        for (var r = 0; r < rows; r++) {
            html += '<tr>';
            for (var c = 0; c < cols; c++) {
                var bg, fg, fw;
                if (r === 0) {
                    bg = tmpl.headerBg; fg = tmpl.headerFg; fw = 'bold';
                } else if (r % 2 === 0) {
                    bg = tmpl.stripeBg; fg = '#000000'; fw = 'normal';
                } else {
                    bg = tmpl.bodyBg; fg = '#000000'; fw = 'normal';
                }
                var tag = r === 0 ? 'th' : 'td';
                html += '<' + tag + ' style="border:1px solid ' + tmpl.borderColor + ';padding:6px 10px;min-width:40px;background:' + bg + ';color:' + fg + ';font-weight:' + fw + ';"><p><br></p></' + tag + '>';
            }
            html += '</tr>';
        }
        html += '</table>';
        return html;
    }

    /// Insert a pre-styled table template
    window.insertTableTemplate = function(templateId, rows, cols) {
        var tmpl = tableTemplates[templateId];
        if (!tmpl) { jsLog('Unknown template: ' + templateId); return; }

        var html = buildTemplateTableHTML(tmpl, rows, cols);
        var page = getActivePage();
        var sel = window.getSelection();
        var temp = document.createElement('div');
        temp.innerHTML = html;
        var table = temp.firstChild;

        if (sel.rangeCount) {
            var range = sel.getRangeAt(0);
            var block = range.startContainer;
            while (block && block.parentNode !== page && block !== page) {
                block = block.parentNode;
            }
            if (block && block !== page && block.parentNode === page) {
                page.insertBefore(table, block.nextSibling);
            } else {
                page.appendChild(table);
            }
        } else {
            page.appendChild(table);
        }
        // Place cursor in first body cell (skip header) and scroll into view
        var firstBody = table.querySelector('td') || table.querySelector('th');
        if (firstBody) {
            var r2 = document.createRange();
            r2.selectNodeContents(firstBody);
            r2.collapse(true);
            sel.removeAllRanges();
            sel.addRange(r2);
            setTimeout(function() {
                table.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }, 100);
        }
        notifyContentChanged();
    };

    /// Get available template IDs and names
    window.getTableTemplates = function() {
        var result = [];
        for (var id in tableTemplates) {
            result.push({ id: id, name: tableTemplates[id].name,
                headerBg: tableTemplates[id].headerBg,
                stripeBg: tableTemplates[id].stripeBg,
                borderColor: tableTemplates[id].borderColor });
        }
        return JSON.stringify(result);
    };

    /// Change the theme color of the active (selected) table
    window.setTableThemeColor = function(headerBg, stripeBg, borderColor) {
        var table = _activeTable;
        if (!table) {
            jsLog('setTableThemeColor: no active table');
            return;
        }
        var headerFg = isLightColor(headerBg) ? '#000000' : '#FFFFFF';

        // Update data attributes
        table.setAttribute('data-template-header', headerBg);
        table.setAttribute('data-template-stripe', stripeBg);
        table.setAttribute('data-template-border', borderColor);

        var rows = table.rows;
        for (var r = 0; r < rows.length; r++) {
            var cells = rows[r].cells;
            for (var c = 0; c < cells.length; c++) {
                var cell = cells[c];
                cell.style.borderColor = borderColor;
                if (r === 0) {
                    cell.style.backgroundColor = headerBg;
                    cell.style.color = headerFg;
                    cell.style.fontWeight = 'bold';
                } else if (r % 2 === 0) {
                    cell.style.backgroundColor = stripeBg;
                    cell.style.color = '#000000';
                } else {
                    cell.style.backgroundColor = '#FFFFFF';
                    cell.style.color = '#000000';
                }
            }
        }
        notifyContentChanged();
        jsLog('setTableThemeColor applied: header=' + headerBg);
    };

    /// Helper: check if a hex color is light (for text contrast)
    function isLightColor(hex) {
        hex = hex.replace('#', '');
        if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
        var r = parseInt(hex.substring(0,2), 16);
        var g = parseInt(hex.substring(2,4), 16);
        var b = parseInt(hex.substring(4,6), 16);
        var luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        return luminance > 0.6;
    }

    // ============================================================
    // INSERT LINK
    // ============================================================

    window.insertLink = function(url) {
        var sel = window.getSelection();
        if (!sel.rangeCount) return;
        if (sel.isCollapsed) {
            // No selection — insert link text
            var a = document.createElement('a');
            a.href = url;
            a.textContent = url;
            a.style.color = '#0563C1';
            a.style.textDecoration = 'underline';
            var range = sel.getRangeAt(0);
            range.insertNode(a);
            range.setStartAfter(a);
            range.collapse(true);
            sel.removeAllRanges();
            sel.addRange(range);
        } else {
            document.execCommand('createLink', false, url);
        }
        notifyContentChanged();
    };

    // ============================================================
    // INSERT PAGE BREAK
    // ============================================================

    window.insertPageBreak = function() {
        var page = getActivePage();
        var sel = window.getSelection();
        var br = document.createElement('div');
        br.className = 'st-page-break';
        br.contentEditable = 'false';
        br.style.cssText = 'page-break-after:always;border-top:1px dashed #ccc;margin:16px 0;height:0;';

        if (sel.rangeCount) {
            var range = sel.getRangeAt(0);
            var block = range.startContainer;
            while (block && block.parentNode !== page && block !== page) {
                block = block.parentNode;
            }
            if (block && block !== page && block.parentNode === page) {
                page.insertBefore(br, block.nextSibling);
            } else {
                page.appendChild(br);
            }
        } else {
            page.appendChild(br);
        }
        notifyContentChanged();
    };

    // ============================================================
    // INSERT HORIZONTAL RULE
    // ============================================================

    window.insertHorizontalRule = function() {
        document.execCommand('insertHorizontalRule', false, null);
        notifyContentChanged();
    };

    // ============================================================
    // BOOKMARKS
    // ============================================================

    window.insertBookmark = function(id, name) {
        var sel = window.getSelection();
        if (!sel.rangeCount) return false;
        var range = sel.getRangeAt(0);

        var bookmark = document.createElement('span');
        bookmark.className = 'st-bookmark';
        bookmark.setAttribute('data-bookmark-id', id);
        bookmark.setAttribute('data-bookmark-name', name);
        bookmark.contentEditable = 'false';
        bookmark.innerHTML = '\u200B';

        range.collapse(true);
        range.insertNode(bookmark);

        range.setStartAfter(bookmark);
        range.collapse(true);
        sel.removeAllRanges();
        sel.addRange(range);

        notifyContentChanged();
        return true;
    };

    window.getBookmarks = function() {
        var bookmarks = [];
        var markers = editor.querySelectorAll('.st-bookmark');
        for (var i = 0; i < markers.length; i++) {
            var m = markers[i];
            bookmarks.push({
                id: m.getAttribute('data-bookmark-id'),
                name: m.getAttribute('data-bookmark-name')
            });
        }
        return JSON.stringify(bookmarks);
    };

    window.scrollToBookmark = function(id) {
        var marker = editor.querySelector('.st-bookmark[data-bookmark-id="' + id + '"]');
        if (marker) {
            marker.scrollIntoView({ behavior: 'smooth', block: 'center' });
            marker.style.outline = '2px solid #2B579A';
            setTimeout(function() { marker.style.outline = ''; }, 1500);
            return true;
        }
        return false;
    };

    window.removeBookmark = function(id) {
        var marker = editor.querySelector('.st-bookmark[data-bookmark-id="' + id + '"]');
        if (marker) {
            marker.remove();
            notifyContentChanged();
            return true;
        }
        return false;
    };

    // ============================================================
    // COMMENTS
    // ============================================================

    window.insertComment = function(id, text) {
        var sel = window.getSelection();
        if (!sel.rangeCount || sel.isCollapsed) return false;

        var range = sel.getRangeAt(0);
        var mark = document.createElement('span');
        mark.className = 'st-comment-highlight';
        mark.setAttribute('data-comment-id', id);
        mark.setAttribute('data-comment-text', text);
        mark.setAttribute('data-comment-date', new Date().toISOString());

        try {
            range.surroundContents(mark);
        } catch(e) {
            // surroundContents fails if range crosses element boundaries
            var marker = document.createElement('span');
            marker.className = 'st-comment-highlight';
            marker.setAttribute('data-comment-id', id);
            marker.setAttribute('data-comment-text', text);
            marker.setAttribute('data-comment-date', new Date().toISOString());
            var fragment = range.extractContents();
            marker.appendChild(fragment);
            range.insertNode(marker);
        }

        notifyContentChanged();
        return true;
    };

    window.getComments = function() {
        var comments = [];
        var highlights = editor.querySelectorAll('.st-comment-highlight');
        for (var i = 0; i < highlights.length; i++) {
            var el = highlights[i];
            comments.push({
                id: el.getAttribute('data-comment-id'),
                text: el.getAttribute('data-comment-text'),
                date: el.getAttribute('data-comment-date') || '',
                contextText: el.textContent.substring(0, 50)
            });
        }
        return JSON.stringify(comments);
    };

    window.scrollToComment = function(id) {
        var el = editor.querySelector('[data-comment-id="' + id + '"]');
        if (el) {
            el.scrollIntoView({ behavior: 'smooth', block: 'center' });
            el.style.outline = '2px solid #FF9632';
            setTimeout(function() { el.style.outline = ''; }, 2000);
            return true;
        }
        return false;
    };

    window.deleteComment = function(id) {
        var el = editor.querySelector('[data-comment-id="' + id + '"]');
        if (!el) return false;
        var parent = el.parentNode;
        while (el.firstChild) {
            parent.insertBefore(el.firstChild, el);
        }
        parent.removeChild(el);
        parent.normalize();
        notifyContentChanged();
        return true;
    };

    // ============================================================
    // CONTENT OPERATIONS
    // ============================================================

    window.setContent = function(html) {
        // Load content flat first (for DOM measurement)
        editor.innerHTML = html;
        isContentDirty = false;
        currentPageIndex = 0;
        // Paginate after layout settles
        setTimeout(function() {
            initializeCharts();
            paginateContent();
        }, 200);
    };

    /// Set target page count from PDF — makes WKWebView pagination match PDF pages
    window.setTargetPageCount = function(count) {
        targetPageCount = count;
        // Re-paginate if content already loaded
        if (editor.innerHTML && editor.innerHTML.length > 0) {
            setTimeout(function() {
                paginateContent();
            }, 100);
        }
    };

    window.getContent = function() {
        // Return flat HTML without page wrappers
        var clone = editor.cloneNode(true);
        unwrapPagesIn(clone);
        return clone.innerHTML;
    };

    // ============================================================
    // IMAGE INSERTION
    // ============================================================

    window.insertImage = function(dataURL) {
        var el = document.createElement('div');
        el.className = 'st-shape st-shape-image';
        el.contentEditable = 'false';
        el.style.cssText = 'width:80%;max-width:400px;position:relative;';

        var img = document.createElement('img');
        img.src = dataURL;
        el.appendChild(img);

        var handle = document.createElement('div');
        handle.className = 'st-shape-handle';
        el.appendChild(handle);

        insertShapeAtCursor(el);
    };

    // ============================================================
    // SHAPE INSERTION — block-level, in document flow
    // ============================================================

    /// Insert shape at cursor position in document flow
    function insertShapeAtCursor(el) {
        var page = getActivePage();
        var sel = window.getSelection();

        if (sel.rangeCount) {
            var range = sel.getRangeAt(0);
            var block = range.startContainer;
            // Walk up to find direct child of page
            while (block && block.parentNode !== page && block !== page) {
                block = block.parentNode;
            }
            if (block && block !== page && block.parentNode === page) {
                page.insertBefore(el, block.nextSibling);
            } else {
                page.appendChild(el);
            }
        } else {
            page.appendChild(el);
        }

        deselectAllShapes();
        el.classList.add('st-shape-selected');
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        notifyContentChanged();
    }

    function getActivePage() {
        var pages = editor.querySelectorAll('.st-page');
        return pages.length > 0 ? pages[0] : editor;
    }

    function deselectAllShapes() {
        var shapes = editor.querySelectorAll('.st-shape');
        for (var i = 0; i < shapes.length; i++) {
            shapes[i].classList.remove('st-shape-selected');
        }
        removeShapeMenu();
    }

    window.insertRectangle = function() {
        var el = document.createElement('div');
        el.className = 'st-shape';
        el.contentEditable = 'false';
        el.style.cssText = 'width:200px;height:120px;border:2px solid #2B579A;background:rgba(43,87,154,0.05);';
        var handle = document.createElement('div');
        handle.className = 'st-shape-handle';
        el.appendChild(handle);
        insertShapeAtCursor(el);
    };

    window.insertCircle = function() {
        var el = document.createElement('div');
        el.className = 'st-shape';
        el.contentEditable = 'false';
        el.style.cssText = 'width:120px;height:120px;border:2px solid #2B579A;border-radius:50%;background:rgba(43,87,154,0.05);';
        var handle = document.createElement('div');
        handle.className = 'st-shape-handle';
        el.appendChild(handle);
        insertShapeAtCursor(el);
    };

    window.insertLine = function() {
        var el = document.createElement('div');
        el.className = 'st-shape st-shape-line';
        el.contentEditable = 'false';
        el.style.cssText = 'width:80%;height:0;border-top:2px solid #2B579A;';
        var handle = document.createElement('div');
        handle.className = 'st-shape-handle';
        el.appendChild(handle);
        insertShapeAtCursor(el);
    };

    window.insertArrow = function() {
        var el = document.createElement('div');
        el.className = 'st-shape st-shape-arrow';
        el.contentEditable = 'false';
        el.style.cssText = 'width:200px;height:40px;';
        el.setAttribute('data-stroke-color', '#2B579A');
        var svgNS = 'http://www.w3.org/2000/svg';
        var svg = document.createElementNS(svgNS, 'svg');
        svg.setAttribute('width', '100%');
        svg.setAttribute('height', '100%');
        svg.setAttribute('viewBox', '0 0 200 40');
        svg.setAttribute('preserveAspectRatio', 'none');
        var defs = document.createElementNS(svgNS, 'defs');
        var marker = document.createElementNS(svgNS, 'marker');
        var markerId = 'ah_' + Date.now();
        marker.setAttribute('id', markerId);
        marker.setAttribute('markerWidth', '10');
        marker.setAttribute('markerHeight', '7');
        marker.setAttribute('refX', '10');
        marker.setAttribute('refY', '3.5');
        marker.setAttribute('orient', 'auto');
        var polygon = document.createElementNS(svgNS, 'polygon');
        polygon.setAttribute('points', '0 0,10 3.5,0 7');
        polygon.setAttribute('fill', '#2B579A');
        marker.appendChild(polygon);
        defs.appendChild(marker);
        svg.appendChild(defs);
        var line = document.createElementNS(svgNS, 'line');
        line.setAttribute('x1', '0');
        line.setAttribute('y1', '20');
        line.setAttribute('x2', '180');
        line.setAttribute('y2', '20');
        line.setAttribute('stroke', '#2B579A');
        line.setAttribute('stroke-width', '2');
        line.setAttribute('marker-end', 'url(#' + markerId + ')');
        svg.appendChild(line);
        el.appendChild(svg);
        var handle = document.createElement('div');
        handle.className = 'st-shape-handle';
        el.appendChild(handle);
        insertShapeAtCursor(el);
    };

    // MARK: - Shape Styling

    window.setShapeBorderColor = function(color) {
        var sel = document.querySelector('.st-shape.st-shape-selected');
        if (!sel) return;
        if (sel.classList.contains('st-shape-line')) {
            sel.style.borderTopColor = color;
        } else if (sel.classList.contains('st-shape-arrow')) {
            sel.setAttribute('data-stroke-color', color);
            var svgLine = sel.querySelector('line');
            var svgPoly = sel.querySelector('polygon');
            if (svgLine) svgLine.setAttribute('stroke', color);
            if (svgPoly) svgPoly.setAttribute('fill', color);
        } else {
            sel.style.borderColor = color;
        }
        notifyContentChanged();
    };

    window.setShapeFillColor = function(color) {
        var sel = document.querySelector('.st-shape.st-shape-selected');
        if (!sel || sel.classList.contains('st-shape-line') || sel.classList.contains('st-shape-arrow') || sel.classList.contains('st-shape-image')) return;
        sel.style.backgroundColor = color;
        notifyContentChanged();
    };

    window.setShapeBorderWidth = function(width) {
        var sel = document.querySelector('.st-shape.st-shape-selected');
        if (!sel) return;
        if (sel.classList.contains('st-shape-line')) {
            sel.style.borderTopWidth = width + 'px';
        } else if (sel.classList.contains('st-shape-arrow')) {
            var svgLine = sel.querySelector('line');
            if (svgLine) svgLine.setAttribute('stroke-width', width);
        } else {
            sel.style.borderWidth = width + 'px';
        }
        notifyContentChanged();
    };

    window.setShapeBorderStyle = function(style) {
        var sel = document.querySelector('.st-shape.st-shape-selected');
        if (!sel || sel.classList.contains('st-shape-arrow')) return;
        if (sel.classList.contains('st-shape-line')) {
            sel.style.borderTopStyle = style;
        } else {
            sel.style.borderStyle = style;
        }
        notifyContentChanged();
    };

    // ============================================================
    // SHAPE INTERACTION — drag-to-reorder, resize, long-press menu
    // ============================================================

    var _dragShape = null;
    var _dragStartX = 0, _dragStartY = 0;
    var _dragOrigW = 0, _dragOrigH = 0;
    var _isResizing = false;
    var _isDragging = false;
    var _longPressTimer = null;
    var _longPressShape = null;
    var _dragPlaceholder = null;
    var _dragOffsetX = 0, _dragOffsetY = 0;
    var _dragOrigParent = null;

    function removeShapeMenu() {
        var existing = document.querySelector('.st-shape-menu');
        if (existing) existing.remove();
    }

    /// Show context menu above shape (DOM flow, before the shape)
    function showShapeMenu(shape) {
        removeShapeMenu();
        var menu = document.createElement('div');
        menu.className = 'st-shape-menu';
        menu.contentEditable = 'false';

        var delBtn = document.createElement('button');
        delBtn.textContent = 'Delete';
        delBtn.className = 'st-shape-menu-btn st-shape-menu-delete';
        delBtn.addEventListener('touchend', function(ev) {
            ev.stopPropagation();
            ev.preventDefault();
            removeShapeMenu();
            shape.remove();
            notifyContentChanged();
        });

        var dupBtn = document.createElement('button');
        dupBtn.textContent = 'Duplicate';
        dupBtn.className = 'st-shape-menu-btn';
        dupBtn.addEventListener('touchend', function(ev) {
            ev.stopPropagation();
            ev.preventDefault();
            removeShapeMenu();
            var clone = shape.cloneNode(true);
            clone.classList.remove('st-shape-selected');
            if (shape.nextSibling) {
                shape.parentNode.insertBefore(clone, shape.nextSibling);
            } else {
                shape.parentNode.appendChild(clone);
            }
            deselectAllShapes();
            clone.classList.add('st-shape-selected');
            clone.scrollIntoView({ behavior: 'smooth', block: 'center' });
            notifyContentChanged();
        });

        menu.appendChild(dupBtn);
        menu.appendChild(delBtn);

        // Insert menu in flow before shape
        if (shape.parentNode) {
            shape.parentNode.insertBefore(menu, shape);
        }
    }

    /// Lift shape for drag-to-reorder
    function startDragReorder(shape, touchX, touchY) {
        _isDragging = true;
        _longPressShape = null;
        _dragOrigParent = shape.parentNode;

        // Create placeholder
        _dragPlaceholder = document.createElement('div');
        _dragPlaceholder.className = 'st-drag-placeholder';
        _dragPlaceholder.contentEditable = 'false';
        _dragPlaceholder.style.height = shape.offsetHeight + 'px';
        _dragPlaceholder.style.width = shape.style.width || shape.offsetWidth + 'px';
        shape.parentNode.insertBefore(_dragPlaceholder, shape);

        // Lift shape with fixed positioning
        var rect = shape.getBoundingClientRect();
        _dragOffsetX = touchX - rect.left;
        _dragOffsetY = touchY - rect.top;

        shape.classList.add('st-shape-lifting');
        shape.style.left = rect.left + 'px';
        shape.style.top = rect.top + 'px';
        shape.style.width = rect.width + 'px';
        document.body.appendChild(shape);

        // Disable scroll
        try { webkit.messageHandlers.shapeDrag.postMessage({ dragging: true }); } catch(ex) {}
    }

    /// Find best drop position based on touch Y
    function findDropPosition(touchY) {
        var page = getActivePage();
        var children = page.children;
        var best = null;

        for (var i = 0; i < children.length; i++) {
            var child = children[i];
            if (child === _dragPlaceholder || child.classList.contains('st-shape-menu')) continue;
            var rect = child.getBoundingClientRect();
            if (touchY < rect.top + rect.height / 2) {
                best = child;
                break;
            }
        }
        return { page: page, before: best };
    }

    /// Move placeholder to show drop position
    function updatePlaceholder(touchY) {
        if (!_dragPlaceholder) return;
        var drop = findDropPosition(touchY);
        if (drop.before) {
            if (drop.before !== _dragPlaceholder && drop.before !== _dragPlaceholder.nextSibling) {
                drop.page.insertBefore(_dragPlaceholder, drop.before);
            }
        } else {
            drop.page.appendChild(_dragPlaceholder);
        }
    }

    /// Finish drag — drop shape at placeholder position
    function finishDragReorder() {
        if (!_dragShape || !_dragPlaceholder) return;

        // Remove lifting styles
        _dragShape.classList.remove('st-shape-lifting');
        _dragShape.style.left = '';
        _dragShape.style.top = '';
        _dragShape.style.width = '';

        // Insert shape where placeholder is
        _dragPlaceholder.parentNode.insertBefore(_dragShape, _dragPlaceholder);
        _dragPlaceholder.remove();
        _dragPlaceholder = null;
        _dragOrigParent = null;

        _dragShape.scrollIntoView({ behavior: 'smooth', block: 'center' });
        notifyContentChanged();

        // Re-enable scroll
        try { webkit.messageHandlers.shapeDrag.postMessage({ dragging: false }); } catch(ex) {}
    }

    document.addEventListener('touchstart', function(e) {
        if (e.touches.length !== 1) return;
        var touch = e.touches[0];
        var target = document.elementFromPoint(touch.clientX, touch.clientY);

        // Tap on menu — ignore
        if (target && target.closest && target.closest('.st-shape-menu')) return;

        // Remove menu on any touch outside
        removeShapeMenu();

        // Clear timers
        if (_longPressTimer) { clearTimeout(_longPressTimer); _longPressTimer = null; }

        // Resize handle
        if (target && target.classList && target.classList.contains('st-shape-handle')) {
            _isResizing = true;
            _isDragging = false;
            _dragShape = target.parentElement;
            _dragStartX = touch.clientX;
            _dragStartY = touch.clientY;
            _dragOrigW = _dragShape.offsetWidth;
            _dragOrigH = _dragShape.offsetHeight;
            try { webkit.messageHandlers.shapeDrag.postMessage({ dragging: true }); } catch(ex) {}
            e.preventDefault();
            return;
        }

        // Shape body tap
        var el = target;
        while (el && el !== document.body) {
            if (el.classList && el.classList.contains('st-shape')) {
                _dragShape = el;
                _dragStartX = touch.clientX;
                _dragStartY = touch.clientY;
                _isResizing = false;
                _isDragging = false;
                deselectAllShapes();
                el.classList.add('st-shape-selected');
                // Long press (500ms)
                _longPressShape = el;
                _longPressTimer = setTimeout(function() {
                    if (_longPressShape && !_isDragging) {
                        showShapeMenu(_longPressShape);
                    }
                    _longPressTimer = null;
                }, 500);
                e.preventDefault();
                return;
            }
            el = el.parentElement;
        }
        deselectAllShapes();
        _dragShape = null;
    }, { passive: false });

    document.addEventListener('touchmove', function(e) {
        if (e.touches.length !== 1) return;
        var touch = e.touches[0];

        // Cancel long press
        if (_longPressTimer) {
            if (Math.abs(touch.clientX - _dragStartX) > 5 || Math.abs(touch.clientY - _dragStartY) > 5) {
                clearTimeout(_longPressTimer);
                _longPressTimer = null;
                _longPressShape = null;
            }
        }

        if (!_dragShape) return;

        var dx = touch.clientX - _dragStartX;
        var dy = touch.clientY - _dragStartY;

        // Resize
        if (_isResizing) {
            var newW = Math.max(40, _dragOrigW + dx);
            _dragShape.style.width = newW + 'px';
            if (!_dragShape.classList.contains('st-shape-line') &&
                !_dragShape.classList.contains('st-shape-image')) {
                var newH = Math.max(20, _dragOrigH + dy);
                _dragShape.style.height = newH + 'px';
            }
            e.preventDefault();
            return;
        }

        // Drag-to-reorder (start after 8px threshold)
        if (!_isDragging && (Math.abs(dx) > 8 || Math.abs(dy) > 8)) {
            startDragReorder(_dragShape, touch.clientX, touch.clientY);
        }

        if (_isDragging) {
            _dragShape.style.left = (touch.clientX - _dragOffsetX) + 'px';
            _dragShape.style.top = (touch.clientY - _dragOffsetY) + 'px';
            updatePlaceholder(touch.clientY);
            e.preventDefault();
        }
    }, { passive: false });

    document.addEventListener('touchend', function(e) {
        if (_longPressTimer) { clearTimeout(_longPressTimer); _longPressTimer = null; }
        _longPressShape = null;

        if (_dragShape) {
            if (_isDragging) {
                finishDragReorder();
            } else if (_isResizing) {
                notifyContentChanged();
                try { webkit.messageHandlers.shapeDrag.postMessage({ dragging: false }); } catch(ex) {}
            }
        }
        _dragShape = null;
        _isResizing = false;
        _isDragging = false;
    }, { passive: true });

    // ============================================================
    // TABLE OPERATIONS
    // ============================================================

    /// Helper: set .st-active-cell on a specific cell, clearing previous
    function setActiveCell(cell) {
        if (!cell) return;
        var prev = editor.querySelectorAll('.st-active-cell');
        for (var i = 0; i < prev.length; i++) prev[i].classList.remove('st-active-cell');
        cell.classList.add('st-active-cell');
        jsLog('setActiveCell → ' + cell.tagName + '[' + cell.textContent.substring(0, 15) + ']');
    }

    window.addTableRow = function() {
        jsLog('addTableRow called');
        var cell = getActiveTableCell();
        if (!cell) return;
        var row = cell.parentElement;
        var tbody = row.parentElement;
        var newRow = row.cloneNode(true);
        // Clear cell contents and active-cell class
        var cells = newRow.querySelectorAll('td, th');
        for (var i = 0; i < cells.length; i++) {
            cells[i].innerHTML = '<br>';
            cells[i].classList.remove('st-active-cell');
        }
        // Insert after current row
        if (row.nextSibling) {
            tbody.insertBefore(newRow, row.nextSibling);
        } else {
            tbody.appendChild(newRow);
        }
        // Set active cell to first cell of new row
        setActiveCell(newRow.cells[0]);
        notifyContentChanged();
    };

    window.deleteTableRow = function() {
        jsLog('deleteTableRow called');
        var cell = getActiveTableCell();
        if (!cell) return;
        var row = cell.parentElement;
        var colIdx = cell.cellIndex;
        var table = cell.closest('table');
        if (!table || table.rows.length <= 1) return;
        // Find adjacent row to move active cell to
        var nextRow = row.nextElementSibling || row.previousElementSibling;
        row.remove();
        // Set active cell on the adjacent row, same column
        if (nextRow) {
            var newIdx = Math.min(colIdx, nextRow.cells.length - 1);
            setActiveCell(nextRow.cells[newIdx]);
        }
        notifyContentChanged();
    };

    window.addTableColumn = function() {
        jsLog('addTableColumn called');
        var cell = getActiveTableCell();
        if (!cell) return;
        var colIdx = cell.cellIndex;
        var rowIdx = cell.parentElement.rowIndex;
        var table = cell.closest('table');
        if (!table) return;
        var rows = table.rows;
        var newActiveCell = null;
        for (var i = 0; i < rows.length; i++) {
            var newCell = document.createElement(rows[i].cells[0].tagName);
            newCell.innerHTML = '<br>';
            if (rows[i].cells[colIdx]) {
                newCell.style.cssText = rows[i].cells[colIdx].style.cssText;
            }
            if (colIdx + 1 < rows[i].cells.length) {
                rows[i].insertBefore(newCell, rows[i].cells[colIdx + 1]);
            } else {
                rows[i].appendChild(newCell);
            }
            // Track the new cell in the active row
            if (i === rowIdx) newActiveCell = newCell;
        }
        // Set active cell to new column in same row
        setActiveCell(newActiveCell || cell);
        notifyContentChanged();
    };

    window.deleteTableColumn = function() {
        jsLog('deleteTableColumn called');
        var cell = getActiveTableCell();
        if (!cell) return;
        var colIdx = cell.cellIndex;
        var rowIdx = cell.parentElement.rowIndex;
        var table = cell.closest('table');
        if (!table) return;
        var rows = table.rows;
        if (rows[0].cells.length <= 1) return;
        for (var i = 0; i < rows.length; i++) {
            if (colIdx < rows[i].cells.length) {
                rows[i].deleteCell(colIdx);
            }
        }
        // Set active cell on adjacent column in same row
        var activeRow = table.rows[rowIdx];
        if (activeRow) {
            var newIdx = Math.min(colIdx, activeRow.cells.length - 1);
            setActiveCell(activeRow.cells[newIdx]);
        }
        notifyContentChanged();
    };

    window.setCellBackgroundColor = function(color) {
        jsLog('setCellBackgroundColor(' + color + ')');
        var cell = getActiveTableCell();
        if (!cell) { jsLog('setCellBackgroundColor: no active cell'); return; }
        cell.style.backgroundColor = color;
        jsLog('setCellBackgroundColor applied to ' + cell.tagName);
        notifyContentChanged();
    };

    window.setCellBorderColor = function(color) {
        jsLog('setCellBorderColor(' + color + ')');
        var cell = getActiveTableCell();
        if (!cell) { jsLog('setCellBorderColor: no active cell'); return; }
        cell.style.border = '1px solid ' + color;
        jsLog('setCellBorderColor applied to ' + cell.tagName);
        notifyContentChanged();
    };

    // ============================================================
    // TABLE SELECTION & RESIZE UX
    // ============================================================

    var _activeTable = null;       // currently selected table element
    var _tableWrapper = null;      // wrapper div around active table
    var _colResizeIdx = -1;        // column being resized (-1 = none)
    var _colResizeStartX = 0;      // touch start X for column resize
    var _colResizeStartW = 0;      // original column width
    var _colResizeNextW = 0;       // original next column width
    var _tableResizing = false;    // whole-table resize in progress
    var _tableResizeStartX = 0;
    var _tableResizeStartW = 0;

    /// Activate a table: in normal mode just adds CSS outline,
    /// in select/hand mode also wraps with resize handles.
    function activateTable(table) {
        if (_activeTable === table) return;
        deactivateTable();
        _activeTable = table;

        // Blue outline (both modes)
        table.classList.add('st-table-selected');

        if (_isSelectMode) {
            // SELECT MODE: create wrapper with resize/column handles
            var savedScrollY = window.scrollY || window.pageYOffset;
            var wrapper = document.createElement('div');
            wrapper.className = 'st-table-wrapper st-table-active';
            wrapper.contentEditable = 'false';
            table.parentNode.insertBefore(wrapper, table);
            wrapper.appendChild(table);
            _tableWrapper = wrapper;
            // Restore scroll position after DOM restructure (WKWebView resets to top)
            if (savedScrollY > 0) {
                requestAnimationFrame(function() { window.scrollTo(0, savedScrollY); });
            }

            // Bottom-right resize handle
            var handle = document.createElement('div');
            handle.className = 'st-table-resize-handle';
            wrapper.appendChild(handle);
            buildColIndicators(table, wrapper);

            handle.addEventListener('touchstart', function(e) {
                e.preventDefault();
                e.stopPropagation();
                _tableResizing = true;
                _tableResizeStartX = e.touches[0].clientX;
                _tableResizeStartW = table.offsetWidth;
            }, { passive: false });

            // Set first cell as active for table operations
            var firstCell = table.querySelector('td, th');
            if (firstCell) setActiveCell(firstCell);

            // Notify Swift: table selected → show Table tab
            try {
                webkit.messageHandlers.formattingState.postMessage({
                    isBold: false, isItalic: false, isUnderline: false,
                    isStrikethrough: false, isSubscript: false, isSuperscript: false,
                    isBulletList: false, isNumberedList: false,
                    fontSize: 11, fontName: 'Calibri', alignment: 'left',
                    isInTable: true
                });
            } catch(e) {}
        }
        // NORMAL MODE: no DOM changes, cursor stays intact.
        // updateFormattingState() handles Table tab visibility via selection.
    }

    /// Build thin vertical indicators on column borders for drag-to-resize
    function buildColIndicators(table, wrapper) {
        // Remove old ones
        var old = wrapper.querySelectorAll('.st-col-resize-indicator');
        for (var i = 0; i < old.length; i++) old[i].remove();

        if (!table.rows || table.rows.length === 0) return;
        var firstRow = table.rows[0];
        var cells = firstRow.cells;
        // indicator between each pair of columns + right edge
        for (var c = 0; c < cells.length; c++) {
            var cell = cells[c];
            var left = cell.offsetLeft + cell.offsetWidth - 1;
            var ind = document.createElement('div');
            ind.className = 'st-col-resize-indicator';
            ind.style.left = left + 'px';
            ind.style.height = table.offsetHeight + 'px';
            ind.setAttribute('data-col', c);
            wrapper.appendChild(ind);

            // Touch events for column resize
            (function(colIdx, indicator) {
                indicator.addEventListener('touchstart', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    _colResizeIdx = colIdx;
                    _colResizeStartX = e.touches[0].clientX;
                    var row = table.rows[0];
                    _colResizeStartW = row.cells[colIdx].offsetWidth;
                    _colResizeNextW = (colIdx + 1 < row.cells.length)
                        ? row.cells[colIdx + 1].offsetWidth : 0;
                    indicator.classList.add('st-col-dragging');
                }, { passive: false });
            })(c, ind);
        }
    }

    /// Remove table selection, restore DOM if wrapper exists
    /// Force text cursor into a table cell using nested-editable trick (iOS-reliable)
    /// touchX/touchY: original touch coordinates to place cursor at the tapped position
    function forceCursorIntoCell(cell, touchX, touchY) {
        // Remove nested-editable from previous cell
        if (_activeCellEdit && _activeCellEdit !== cell) {
            _activeCellEdit.removeAttribute('contenteditable');
        }
        _activeCellEdit = cell;

        // Make THIS cell a nested editable — iOS routes keyboard input here
        cell.setAttribute('contenteditable', 'true');

        try {
            var sel = window.getSelection();

            // Try to place cursor at the exact touch position using caretRangeFromPoint
            if (touchX && touchY && document.caretRangeFromPoint) {
                var caretRange = document.caretRangeFromPoint(touchX, touchY);
                if (caretRange && cell.contains(caretRange.startContainer)) {
                    sel.removeAllRanges();
                    sel.addRange(caretRange);
                    return;
                }
            }

            // Fallback: place cursor at start of cell content
            var target = cell.querySelector('p') || cell;
            var range = document.createRange();
            if (target.firstChild) {
                range.setStart(target.firstChild, 0);
            } else {
                range.selectNodeContents(target);
            }
            range.collapse(true);
            sel.removeAllRanges();
            sel.addRange(range);
        } catch(ex) {
            jsLog('forceCursorIntoCell error: ' + ex.message);
        }
    }

    /// Exit per-cell edit mode — restore normal editor editability
    function exitCellEdit() {
        if (_activeCellEdit) {
            _activeCellEdit.removeAttribute('contenteditable');
            _activeCellEdit = null;
        }
    }

    // Scroll to top / bottom of document
    window.scrollToTop = function() {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    window.scrollToBottom = function() {
        window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
    };

    // Save / restore selection (used before alerts/sheets that lose focus)
    var _savedRange = null;

    window.saveSelection = function() {
        var sel = window.getSelection();
        if (sel && sel.rangeCount > 0) {
            try { _savedRange = sel.getRangeAt(0).cloneRange(); } catch(e) {}
        }
    };

    window.restoreSelection = function() {
        if (!_savedRange) return;
        try {
            editor.focus();
            var sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(_savedRange);
        } catch(e) {}
    };

    // MARK: - Track Changes

    var _trackChanges = false;

    function _onTrackedInput(e) {
        if (!_trackChanges) return;
        if (e.inputType === 'insertText' && e.data) {
            e.preventDefault();
            // Use insertHTML instead of range.insertNode to avoid WKWebView
            // layout flash that briefly positions the new node at (0,0).
            var escaped = e.data
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');
            document.execCommand('insertHTML', false,
                '<span class="st-insertion">' + escaped + '</span>');
        }
    }

    window.setTrackChanges = function(enabled) {
        _trackChanges = enabled;
        if (enabled) {
            editor.addEventListener('beforeinput', _onTrackedInput);
            editor.style.caretColor = '#00B050';
        } else {
            editor.removeEventListener('beforeinput', _onTrackedInput);
            editor.style.caretColor = '';
        }
        return enabled;
    };

    window.acceptAllChanges = function() {
        document.querySelectorAll('.st-insertion').forEach(function(el) {
            var frag = document.createDocumentFragment();
            while (el.firstChild) frag.appendChild(el.firstChild);
            el.parentNode.replaceChild(frag, el);
        });
        document.querySelectorAll('.st-deletion').forEach(function(el) {
            el.parentNode.removeChild(el);
        });
    };

    window.rejectAllChanges = function() {
        document.querySelectorAll('.st-insertion').forEach(function(el) {
            el.parentNode.removeChild(el);
        });
        document.querySelectorAll('.st-deletion').forEach(function(el) {
            var frag = document.createDocumentFragment();
            while (el.firstChild) frag.appendChild(el.firstChild);
            el.parentNode.replaceChild(frag, el);
        });
    };

    /// Called from Swift before any formatting command (bold, font, color…)
    /// Restores focus + cursor to the active cell so formatting applies there, not outside
    window.prepareForFormat = function() {
        if (!_activeCellEdit) return;
        var sel = window.getSelection();
        // If the selection is already inside the active cell, leave it alone
        // (handles bold/italic on selected text inside the cell)
        if (sel && sel.rangeCount > 0) {
            try {
                var r = sel.getRangeAt(0);
                if (_activeCellEdit.contains(r.commonAncestorContainer)) return;
            } catch(e) {}
        }
        // Selection is missing or outside the cell — restore cursor to end of cell
        editor.focus();
        _activeCellEdit.setAttribute('contenteditable', 'true');
        var target = _activeCellEdit.querySelector('p') || _activeCellEdit;
        try {
            var range = document.createRange();
            var walker = document.createTreeWalker(target, NodeFilter.SHOW_TEXT, null, false);
            var lastText = null;
            while (walker.nextNode()) lastText = walker.currentNode;
            if (lastText) {
                range.setStart(lastText, lastText.length);
            } else {
                range.selectNodeContents(target);
                range.collapse(false);
            }
            var sel2 = window.getSelection();
            sel2.removeAllRanges();
            sel2.addRange(range);
        } catch(ex) {
            jsLog('prepareForFormat error: ' + ex.message);
        }
    };

    function deactivateTable() {
        if (!_activeTable) return;
        exitCellEdit();
        _activeTable.classList.remove('st-table-selected');
        if (_tableWrapper && _tableWrapper.parentNode) {
            var savedScrollY = window.scrollY || window.pageYOffset;
            _tableWrapper.parentNode.insertBefore(_activeTable, _tableWrapper);
            _tableWrapper.remove();
            if (savedScrollY > 0) {
                requestAnimationFrame(function() { window.scrollTo(0, savedScrollY); });
            }
        }
        _activeTable = null;
        _tableWrapper = null;
        _colResizeIdx = -1;
        _tableResizing = false;

        // In select mode, explicitly notify Swift (normal mode uses updateFormattingState)
        if (_isSelectMode) {
            try {
                webkit.messageHandlers.formattingState.postMessage({
                    isBold: false, isItalic: false, isUnderline: false,
                    isStrikethrough: false, isSubscript: false, isSuperscript: false,
                    isBulletList: false, isNumberedList: false,
                    fontSize: 11, fontName: 'Calibri', alignment: 'left',
                    isInTable: false
                });
            } catch(e) {}
        }
    }

    // Global touch move for table/column resize
    document.addEventListener('touchmove', function(e) {
        if (_tableResizing && _activeTable) {
            var dx = e.touches[0].clientX - _tableResizeStartX;
            var newW = Math.max(100, _tableResizeStartW + dx);
            _activeTable.style.width = newW + 'px';
            // Rebuild indicators on resize
            if (_tableWrapper) buildColIndicators(_activeTable, _tableWrapper);
            e.preventDefault();
        }
        if (_colResizeIdx >= 0 && _activeTable) {
            var dx = e.touches[0].clientX - _colResizeStartX;
            var rows = _activeTable.rows;
            var newW = Math.max(30, _colResizeStartW + dx);
            for (var r = 0; r < rows.length; r++) {
                if (_colResizeIdx < rows[r].cells.length) {
                    rows[r].cells[_colResizeIdx].style.width = newW + 'px';
                }
                // Shrink next column to compensate
                if (_colResizeNextW > 0 && _colResizeIdx + 1 < rows[r].cells.length) {
                    var nextW = Math.max(30, _colResizeNextW - dx);
                    rows[r].cells[_colResizeIdx + 1].style.width = nextW + 'px';
                }
            }
            // Update indicator positions
            if (_tableWrapper) buildColIndicators(_activeTable, _tableWrapper);
            e.preventDefault();
        }
    }, { passive: false });

    // Global touch end for table/column resize
    document.addEventListener('touchend', function(e) {
        if (_tableResizing) {
            _tableResizing = false;
            notifyContentChanged();
        }
        if (_colResizeIdx >= 0) {
            var dragging = document.querySelector('.st-col-dragging');
            if (dragging) dragging.classList.remove('st-col-dragging');
            _colResizeIdx = -1;
            notifyContentChanged();
        }
    }, { passive: true });

    // Detect table activation: when cursor enters a table, activate it
    // This is called from the existing cell touch/click handlers below
    function checkTableActivation() {
        var cell = getActiveTableCell();
        if (cell) {
            var table = cell.closest('table');
            if (table && table !== _activeTable) {
                activateTable(table);
            }
        } else {
            // Cursor is outside any table — deactivate
            deactivateTable();
        }
    }

    // ============================================================
    // CHART OPERATIONS
    // ============================================================

    // Office-inspired color palette for chart series
    var chartColors = [
        '#4472C4', '#ED7D31', '#A5A5A5', '#FFC000', '#5B9BD5',
        '#70AD47', '#264478', '#9B57A0', '#636363', '#EB6E1F'
    ];

    // Store Chart.js instances keyed by chartId
    var chartInstances = {};

    /// Initialize all charts found in the DOM after content load
    function initializeCharts() {
        var containers = editor.querySelectorAll('.st-chart-container');
        for (var i = 0; i < containers.length; i++) {
            var container = containers[i];
            var chartId = container.getAttribute('data-chart-id');
            var jsonStr = container.getAttribute('data-chart-json');
            if (chartId && jsonStr) {
                try {
                    var data = JSON.parse(jsonStr);
                    renderChart(chartId, data);
                } catch(e) {
                    console.log('[Chart] Failed to parse chart JSON: ' + e.message);
                }
            }
        }
    }

    /// Render a Chart.js chart into the container with the given chartId
    window.renderChart = function(chartId, chartData) {
        if (typeof Chart === 'undefined') {
            console.log('[Chart] Chart.js not loaded');
            return;
        }

        var container = editor.querySelector('.st-chart-container[data-chart-id="' + chartId + '"]');
        if (!container) return;

        var canvas = container.querySelector('canvas');
        if (!canvas) return;

        // Destroy existing instance
        if (chartInstances[chartId]) {
            chartInstances[chartId].destroy();
        }

        var ctx = canvas.getContext('2d');
        var type = chartData.chartType || 'bar';
        var labels = (chartData.series && chartData.series.length > 0) ? chartData.series[0].categories : [];

        var datasets = [];
        for (var i = 0; i < (chartData.series || []).length; i++) {
            var s = chartData.series[i];
            var color = chartColors[i % chartColors.length];
            var ds = {
                label: s.name || ('Series ' + (i + 1)),
                data: s.values || [],
                backgroundColor: (type === 'pie' || type === 'doughnut')
                    ? chartColors.slice(0, (s.values || []).length)
                    : color,
                borderColor: (type === 'pie' || type === 'doughnut')
                    ? '#fff'
                    : color,
                borderWidth: (type === 'pie' || type === 'doughnut') ? 2 : 2
            };
            if (type === 'line') {
                ds.fill = chartData.chartType === 'line' && chartData.barGrouping === 'stacked';
                ds.tension = 0.3;
            }
            datasets.push(ds);
        }

        var config = {
            type: type,
            data: {
                labels: labels,
                datasets: datasets
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    title: {
                        display: !!chartData.title,
                        text: chartData.title || '',
                        font: { size: 14, weight: 'bold' }
                    },
                    legend: {
                        display: chartData.legendPosition !== 'none',
                        position: chartData.legendPosition || 'bottom'
                    }
                },
                animation: { duration: 300 }
            }
        };

        // Horizontal bar
        if (type === 'bar' && chartData.barDirection === 'bar') {
            config.options.indexAxis = 'y';
        }

        // Stacked
        if (chartData.barGrouping === 'stacked' || chartData.barGrouping === 'percentStacked') {
            config.options.scales = {
                x: { stacked: true },
                y: { stacked: true }
            };
        }

        chartInstances[chartId] = new Chart(ctx, config);
    };

    /// Update chart data and re-render
    window.updateChartData = function(chartId, jsonStr) {
        try {
            var data = JSON.parse(jsonStr);
            // Update the data-chart-json attribute
            var container = editor.querySelector('.st-chart-container[data-chart-id="' + chartId + '"]');
            if (container) {
                container.setAttribute('data-chart-json', jsonStr);
            }
            // Re-render
            renderChart(chartId, data);
            notifyContentChanged();
        } catch(e) {
            console.log('[Chart] updateChartData error: ' + e.message);
        }
    };

    /// Get chart data JSON for a specific chart
    window.getChartData = function(chartId) {
        var container = editor.querySelector('.st-chart-container[data-chart-id="' + chartId + '"]');
        if (!container) return null;
        return container.getAttribute('data-chart-json');
    };

    // ============================================================
    // DOCUMENT STRUCTURE EXTRACTION (for save)
    // ============================================================

    window.getDocumentStructure = function() {
        var elements = [];

        // Collect content nodes — may be inside .st-page wrappers
        var pages = editor.querySelectorAll('.st-page');
        var containers = pages.length > 0 ? Array.from(pages) : [editor];

        for (var c = 0; c < containers.length; c++) {
            var children = containers[c].childNodes;
            for (var i = 0; i < children.length; i++) {
                var node = children[i];
                if (node.nodeType === Node.TEXT_NODE) {
                    var text = node.textContent;
                    if (text.trim()) {
                        elements.push({ type: 'paragraph', runs: [{ text: text }] });
                    }
                    continue;
                }
                if (node.nodeType !== Node.ELEMENT_NODE) continue;

                // Skip page infrastructure
                if (node.classList && (node.classList.contains('st-page') ||
                    node.classList.contains('st-page-gap') ||
                    node.classList.contains('st-page-break'))) continue;

                var tag = node.tagName.toLowerCase();

                // Chart container
                if (node.classList && node.classList.contains('st-chart-container')) {
                    var chartId = node.getAttribute('data-chart-id');
                    var chartJson = node.getAttribute('data-chart-json');
                    if (chartId && chartJson) {
                        try {
                            var chartData = JSON.parse(chartJson);
                            elements.push({
                                type: 'chart',
                                chartId: chartData.chartId || chartId,
                                chartType: chartData.chartType || 'bar',
                                title: chartData.title || null,
                                legendPosition: chartData.legendPosition || 'bottom',
                                barDirection: chartData.barDirection || null,
                                barGrouping: chartData.barGrouping || null,
                                series: chartData.series || []
                            });
                        } catch(e) {}
                    }
                    continue;
                }

                // Shape elements
                if (node.classList && node.classList.contains('st-shape')) {
                    var shapeData = {
                        type: 'shape',
                        shapeType: 'rectangle',
                        width: node.style.width || '200px',
                        height: node.style.height || '120px',
                        border: node.style.border || '',
                        backgroundColor: node.style.backgroundColor || '',
                        borderRadius: node.style.borderRadius || ''
                    };
                    if (node.classList.contains('st-shape-line')) {
                        shapeData.shapeType = 'line';
                        shapeData.border = node.style.borderTop || node.style.border || '2px solid #2B579A';
                    } else if (node.classList.contains('st-shape-arrow')) {
                        shapeData.shapeType = 'arrow';
                        shapeData.strokeColor = node.getAttribute('data-stroke-color') || '#2B579A';
                    } else if (node.classList.contains('st-shape-image')) {
                        shapeData.shapeType = 'image';
                        var img = node.querySelector('img');
                        if (img) shapeData.imageSrc = img.src;
                    } else if (node.style.borderRadius && node.style.borderRadius.indexOf('50') >= 0) {
                        shapeData.shapeType = 'circle';
                    }
                    elements.push(shapeData);
                    continue;
                }

                if (tag === 'table') {
                    elements.push(parseTable(node));
                } else if (tag === 'ul' || tag === 'ol') {
                    var listItems = parseList(node, tag === 'ol' ? 'numbered' : 'bullet');
                    elements = elements.concat(listItems);
                } else if (/^h[1-6]$/.test(tag)) {
                    var level = parseInt(tag.charAt(1));
                    var para = parseParagraph(node);
                    para.type = 'heading';
                    para.level = level;
                    elements.push(para);
                } else {
                    elements.push(parseParagraph(node));
                }
            }
        }

        return JSON.stringify({ elements: elements });
    };

    // ============================================================
    // FORMATTING STATE TRACKING
    // ============================================================

    function updateFormattingState() {
        var state = {
            isBold: document.queryCommandState('bold'),
            isItalic: document.queryCommandState('italic'),
            isUnderline: document.queryCommandState('underline'),
            isStrikethrough: document.queryCommandState('strikeThrough'),
            isSubscript: document.queryCommandState('subscript'),
            isSuperscript: document.queryCommandState('superscript'),
            isBulletList: document.queryCommandState('insertUnorderedList'),
            isNumberedList: document.queryCommandState('insertOrderedList'),
            fontSize: getCurrentFontSize(),
            fontName: getCurrentFontName(),
            alignment: getCurrentAlignment(),
            isInTable: !!getActiveTableCell()
        };

        try {
            webkit.messageHandlers.formattingState.postMessage(state);
        } catch(e) {}
    }

    function getCurrentFontSize() {
        var sel = window.getSelection();
        if (!sel.rangeCount) return 11;
        var node = sel.anchorNode;
        if (node && node.nodeType === Node.TEXT_NODE) node = node.parentElement;
        if (!node) return 11;
        var computed = window.getComputedStyle(node);
        return Math.round(parseFloat(computed.fontSize) * 72 / 96); // px to pt
    }

    function getCurrentFontName() {
        var sel = window.getSelection();
        if (!sel.rangeCount) return 'Calibri';
        var node = sel.anchorNode;
        if (node && node.nodeType === Node.TEXT_NODE) node = node.parentElement;
        if (!node) return 'Calibri';
        var computed = window.getComputedStyle(node);
        var family = computed.fontFamily;
        // Remove quotes and take first font
        return family.replace(/['"]/g, '').split(',')[0].trim();
    }

    function getCurrentAlignment() {
        var sel = window.getSelection();
        if (!sel.rangeCount) return 'left';
        var node = sel.anchorNode;
        if (node && node.nodeType === Node.TEXT_NODE) node = node.parentElement;
        if (!node) return 'left';
        // Walk up to find block element
        while (node && node !== editor && !isBlockElement(node)) {
            node = node.parentElement;
        }
        if (!node || node === editor) return 'left';
        var computed = window.getComputedStyle(node);
        var align = computed.textAlign;
        if (align === 'start') return 'left';
        if (align === 'end') return 'right';
        return align; // left, center, right, justify
    }

    function isBlockElement(node) {
        var blocks = ['P', 'DIV', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'LI', 'TD', 'TH', 'BLOCKQUOTE'];
        return blocks.indexOf(node.tagName) >= 0;
    }

    function getActiveTableCell() {
        // In select mode, always use .st-active-cell (browser selection is stale/empty)
        if (_isSelectMode) {
            var ac = _activeTable
                ? _activeTable.querySelector('.st-active-cell')
                : editor.querySelector('.st-active-cell');
            jsLog('getActiveTableCell [select] → ' + (ac ? ac.tagName : 'null') +
                  ', _activeTable=' + (!!_activeTable));
            return ac || null;
        }
        // Normal mode: use browser selection
        var sel = window.getSelection();
        if (sel.rangeCount) {
            var node = sel.anchorNode;
            while (node && node !== editor) {
                if (node.nodeType === Node.ELEMENT_NODE &&
                    (node.tagName === 'TD' || node.tagName === 'TH')) {
                    return node;
                }
                node = node.parentNode;
            }
        }
        // Fallback for normal mode
        return editor.querySelector('.st-active-cell') || null;
    }

    // ============================================================
    // FONT SIZE ADJUSTMENT
    // ============================================================

    function adjustFontSize(delta) {
        var sel = window.getSelection();
        if (!sel.rangeCount) return;

        var range = sel.getRangeAt(0);
        if (range.collapsed) return;

        var container = range.commonAncestorContainer;
        if (container.nodeType === Node.TEXT_NODE) container = container.parentElement;
        var computed = window.getComputedStyle(container);
        var currentSize = parseFloat(computed.fontSize) * 72 / 96;
        var newSize = Math.max(8, Math.min(72, currentSize + delta));

        document.execCommand('fontSize', false, '7');
        // Replace the font size=7 with actual pt size
        var fonts = editor.querySelectorAll('font[size="7"]');
        for (var i = 0; i < fonts.length; i++) {
            fonts[i].removeAttribute('size');
            fonts[i].style.fontSize = newSize + 'pt';
        }

        updateFormattingState();
    }

    // ============================================================
    // DOM PARSING HELPERS (for getDocumentStructure)
    // ============================================================

    function parseParagraph(node) {
        var runs = parseRuns(node);
        var style = node.style || {};
        var computed = node.nodeType === Node.ELEMENT_NODE ? window.getComputedStyle(node) : null;
        var para = {
            type: 'paragraph',
            runs: runs
        };

        // Alignment
        if (style.textAlign) {
            para.alignment = style.textAlign;
        } else if (computed && computed.textAlign !== 'start') {
            para.alignment = computed.textAlign;
        }

        // Spacing
        if (style.marginTop) para.marginTop = parseFloat(style.marginTop);
        if (style.marginBottom) para.marginBottom = parseFloat(style.marginBottom);
        if (style.lineHeight && style.lineHeight !== 'normal') {
            para.lineHeight = parseFloat(style.lineHeight);
        }

        // Indentation
        if (style.marginLeft) para.marginLeft = parseFloat(style.marginLeft);
        if (style.marginRight) para.marginRight = parseFloat(style.marginRight);
        if (style.textIndent) para.textIndent = parseFloat(style.textIndent);

        // Background color
        if (style.backgroundColor && style.backgroundColor !== 'transparent' && style.backgroundColor !== 'rgba(0, 0, 0, 0)') {
            para.backgroundColor = rgbToHex(style.backgroundColor);
        }

        // Paragraph borders
        if (style.borderTop && style.borderTop !== 'none') para.borderTop = style.borderTop;
        if (style.borderBottom && style.borderBottom !== 'none') para.borderBottom = style.borderBottom;
        if (style.borderLeft && style.borderLeft !== 'none') para.borderLeft = style.borderLeft;
        if (style.borderRight && style.borderRight !== 'none') para.borderRight = style.borderRight;

        return para;
    }

    function parseRuns(node) {
        var runs = [];
        var childNodes = node.childNodes;

        for (var i = 0; i < childNodes.length; i++) {
            var child = childNodes[i];

            if (child.nodeType === Node.TEXT_NODE) {
                var text = child.textContent;
                if (text) {
                    runs.push({ text: text });
                }
            } else if (child.nodeType === Node.ELEMENT_NODE) {
                var tag = child.tagName.toLowerCase();

                if (tag === 'br') {
                    // Skip trailing <br> in empty elements
                    continue;
                }

                if (tag === 'img') {
                    runs.push({
                        text: '',
                        isImage: true,
                        src: child.src || '',
                        width: child.width || child.naturalWidth || 200,
                        height: child.height || child.naturalHeight || 200,
                        alt: child.alt || ''
                    });
                    continue;
                }

                if (tag === 'a') {
                    var linkRuns = parseRuns(child);
                    for (var j = 0; j < linkRuns.length; j++) {
                        linkRuns[j].href = child.href || '';
                        linkRuns[j].title = child.title || '';
                    }
                    runs = runs.concat(linkRuns);
                    continue;
                }

                // Inline formatting elements
                var inlineRuns = parseRuns(child);
                var formatting = getInlineFormatting(child);

                for (var k = 0; k < inlineRuns.length; k++) {
                    var run = inlineRuns[k];
                    // Merge formatting
                    if (formatting.bold) run.bold = true;
                    if (formatting.italic) run.italic = true;
                    if (formatting.underline) run.underline = true;
                    if (formatting.strikethrough) run.strikethrough = true;
                    if (formatting.superscript) run.superscript = true;
                    if (formatting.subscript) run.subscriptText = true;
                    if (formatting.fontSize) run.fontSize = formatting.fontSize;
                    if (formatting.fontFamily) run.fontFamily = formatting.fontFamily;
                    if (formatting.color) run.color = formatting.color;
                    if (formatting.backgroundColor) run.backgroundColor = formatting.backgroundColor;
                    if (formatting.allCaps) run.allCaps = true;
                    if (formatting.smallCaps) run.smallCaps = true;
                    runs.push(run);
                }
            }
        }

        return runs;
    }

    function getInlineFormatting(element) {
        var fmt = {};
        var tag = element.tagName.toLowerCase();
        var style = element.style;

        if (tag === 'b' || tag === 'strong') fmt.bold = true;
        if (tag === 'i' || tag === 'em') fmt.italic = true;
        if (tag === 'u') fmt.underline = true;
        if (tag === 's' || tag === 'strike' || tag === 'del') fmt.strikethrough = true;
        if (tag === 'sup') fmt.superscript = true;
        if (tag === 'sub') fmt.subscript = true;

        // Check computed/inline styles
        if (style.fontWeight === 'bold' || parseInt(style.fontWeight) >= 700) fmt.bold = true;
        if (style.fontStyle === 'italic') fmt.italic = true;
        if (style.textDecoration && style.textDecoration.indexOf('underline') >= 0) fmt.underline = true;
        if (style.textDecoration && style.textDecoration.indexOf('line-through') >= 0) fmt.strikethrough = true;
        if (style.textTransform === 'uppercase') fmt.allCaps = true;
        if (style.fontVariant === 'small-caps') fmt.smallCaps = true;

        if (style.fontSize) {
            var size = parseFloat(style.fontSize);
            if (style.fontSize.indexOf('pt') >= 0) {
                fmt.fontSize = size;
            } else {
                fmt.fontSize = Math.round(size * 72 / 96); // px to pt
            }
        }
        if (style.fontFamily) {
            fmt.fontFamily = style.fontFamily.replace(/['"]/g, '').split(',')[0].trim();
        }
        if (style.color && style.color !== 'rgb(0, 0, 0)') {
            fmt.color = rgbToHex(style.color);
        }
        if (style.backgroundColor && style.backgroundColor !== 'transparent' && style.backgroundColor !== 'rgba(0, 0, 0, 0)') {
            fmt.backgroundColor = rgbToHex(style.backgroundColor);
        }

        return fmt;
    }

    function parseTable(tableNode) {
        var table = {
            type: 'table',
            rows: []
        };

        var rows = tableNode.rows;
        for (var i = 0; i < rows.length; i++) {
            var row = { cells: [], isHeader: rows[i].parentElement.tagName === 'THEAD' };
            var cells = rows[i].cells;
            for (var j = 0; j < cells.length; j++) {
                var cell = parseTableCell(cells[j]);
                row.cells.push(cell);
            }
            table.rows.push(row);
        }

        return table;
    }

    function parseTableCell(cellNode) {
        var cell = {
            paragraphs: [],
            colspan: cellNode.colSpan || 1,
            rowspan: cellNode.rowSpan || 1
        };

        // Background color
        if (cellNode.style.backgroundColor && cellNode.style.backgroundColor !== 'transparent') {
            cell.backgroundColor = rgbToHex(cellNode.style.backgroundColor);
        }

        // Borders
        if (cellNode.style.borderTop) cell.borderTop = cellNode.style.borderTop;
        if (cellNode.style.borderBottom) cell.borderBottom = cellNode.style.borderBottom;
        if (cellNode.style.borderLeft) cell.borderLeft = cellNode.style.borderLeft;
        if (cellNode.style.borderRight) cell.borderRight = cellNode.style.borderRight;

        // Width
        if (cellNode.style.width) cell.width = parseFloat(cellNode.style.width);

        // Vertical alignment
        if (cellNode.style.verticalAlign) cell.verticalAlign = cellNode.style.verticalAlign;

        // Parse cell content as paragraphs
        var children = cellNode.childNodes;
        for (var i = 0; i < children.length; i++) {
            var child = children[i];
            if (child.nodeType === Node.TEXT_NODE) {
                var text = child.textContent;
                if (text.trim()) {
                    cell.paragraphs.push({ type: 'paragraph', runs: [{ text: text }] });
                }
            } else if (child.nodeType === Node.ELEMENT_NODE) {
                cell.paragraphs.push(parseParagraph(child));
            }
        }

        if (cell.paragraphs.length === 0) {
            cell.paragraphs.push({ type: 'paragraph', runs: [{ text: '' }] });
        }

        return cell;
    }

    function parseList(listNode, listType) {
        var items = [];
        var lis = listNode.querySelectorAll(':scope > li');
        for (var i = 0; i < lis.length; i++) {
            var para = parseParagraph(lis[i]);
            para.listType = listType;
            para.listLevel = 0;
            items.push(para);
        }
        return items;
    }

    // ============================================================
    // UTILITY
    // ============================================================

    function rgbToHex(rgb) {
        if (!rgb) return null;
        if (rgb.charAt(0) === '#') return rgb;
        var match = rgb.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
        if (!match) return null;
        var r = parseInt(match[1]).toString(16).padStart(2, '0');
        var g = parseInt(match[2]).toString(16).padStart(2, '0');
        var b = parseInt(match[3]).toString(16).padStart(2, '0');
        return '#' + r + g + b;
    }

    function notifyContentChanged() {
        isContentDirty = true;
        try {
            webkit.messageHandlers.contentChanged.postMessage(true);
        } catch(e) {}
    }

    // ============================================================
    // PAGINATION SYSTEM — wraps content in .st-page divs
    // ============================================================

    var isPaginating = false;
    var paginateTimer = null;

    function createPageDiv() {
        var page = document.createElement('div');
        page.className = 'st-page';
        return page;
    }

    function createGapDiv() {
        var gap = document.createElement('div');
        gap.className = 'st-page-gap';
        gap.contentEditable = 'false';
        gap.setAttribute('data-st-ignore', 'true');
        return gap;
    }

    /// Remove .st-page wrappers from a container, flattening to raw content
    function unwrapPagesIn(container) {
        var pages = container.querySelectorAll('.st-page');
        for (var i = 0; i < pages.length; i++) {
            var page = pages[i];
            var parent = page.parentNode;
            while (page.firstChild) {
                parent.insertBefore(page.firstChild, page);
            }
            parent.removeChild(page);
        }
        var gaps = container.querySelectorAll('.st-page-gap');
        for (var i = gaps.length - 1; i >= 0; i--) gaps[i].remove();
        var breaks = container.querySelectorAll('.st-page-break');
        for (var i = breaks.length - 1; i >= 0; i--) breaks[i].remove();
    }

    /// Wrap content in a single .st-page div (continuous scroll — no page splitting)
    function paginateContent() {
        isPaginating = true;

        // Fast-path: if editor already has exactly one .st-page and nothing else,
        // the structure is correct — skip the flatten+rewrap entirely.
        // This prevents the visual flash caused by temporarily removing .st-page.
        var childNodes = editor.childNodes;
        if (childNodes.length === 1 &&
            childNodes[0].nodeType === Node.ELEMENT_NODE &&
            childNodes[0].classList.contains('st-page')) {
            isPaginating = false;
            notifyPageChange();
            return;
        }

        // 1. Flatten: remove existing page wrappers (preserves child nodes in DOM)
        var existingPages = editor.querySelectorAll('.st-page');
        for (var i = 0; i < existingPages.length; i++) {
            var pg = existingPages[i];
            while (pg.firstChild) {
                editor.insertBefore(pg.firstChild, pg);
            }
            pg.remove();
        }
        var existingGaps = editor.querySelectorAll('.st-page-gap');
        for (var i = existingGaps.length - 1; i >= 0; i--) existingGaps[i].remove();
        var oldBreaks = editor.querySelectorAll('.st-page-break');
        for (var i = oldBreaks.length - 1; i >= 0; i--) oldBreaks[i].remove();

        // 2. If editor is empty, create a single empty page
        if (!editor.firstChild || (editor.textContent || '').trim() === '') {
            editor.innerHTML = '';
            var emptyPage = createPageDiv();
            emptyPage.innerHTML = '<p><br></p>';
            editor.appendChild(emptyPage);
            requestAnimationFrame(function() { isPaginating = false; });
            return;
        }

        // 3. Continuous mode: wrap ALL content into a single page div (no splitting)
        var singlePage = createPageDiv();
        while (editor.firstChild) {
            singlePage.appendChild(editor.firstChild);
        }
        editor.appendChild(singlePage);

        currentPageIndex = 0;

        console.log('[STPage] paginateContent: continuous mode, 1 page');

        // 4. Notify Swift
        isPaginating = false;
        notifyPageChange();
    }

    function schedulePagination() {
        if (paginateTimer) clearTimeout(paginateTimer);
        paginateTimer = setTimeout(paginateContent, 1500);
    }

    // ============================================================
    // PAGE NAVIGATION — show one page at a time
    // ============================================================

    /// Find which page div contains the current cursor/selection
    function findCursorPage() {
        var sel = window.getSelection();
        if (!sel.rangeCount) return currentPageIndex;
        var node = sel.anchorNode;
        while (node && node !== editor) {
            if (node.nodeType === Node.ELEMENT_NODE &&
                node.classList && node.classList.contains('st-page')) {
                var pages = editor.querySelectorAll('.st-page');
                for (var i = 0; i < pages.length; i++) {
                    if (pages[i] === node) return i;
                }
                return currentPageIndex;
            }
            node = node.parentNode;
        }
        return currentPageIndex;
    }

    /// Scroll to the current page and notify Swift
    function scrollToCurrentPage() {
        var pages = editor.querySelectorAll('.st-page');
        if (pages.length <= 1) {
            notifyPageChange();
            return;
        }

        // Clamp page index
        if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1;
        if (currentPageIndex < 0) currentPageIndex = 0;

        // Scroll the current page into view
        pages[currentPageIndex].scrollIntoView({ behavior: 'instant', block: 'start' });

        notifyPageChange();
    }

    /// Notify Swift of page change and send page offsets for native scroll paging
    function notifyPageChange() {
        var pages = editor.querySelectorAll('.st-page');
        var total = pages.length;
        var offsets = [];
        for (var i = 0; i < pages.length; i++) {
            offsets.push(pages[i].offsetTop);
        }
        console.log('[STPage] pageChanged: current=' + currentPageIndex + ' total=' + total);
        try {
            webkit.messageHandlers.pageChanged.postMessage({
                current: currentPageIndex,
                total: total,
                offsets: offsets
            });
        } catch(e) {
            console.log('[STPage] pageChanged message failed: ' + e.message);
        }
    }

    /// Navigate to a specific page (0-indexed)
    window.goToPage = function(index) {
        var pages = editor.querySelectorAll('.st-page');
        if (index < 0 || index >= pages.length) return;
        currentPageIndex = index;
        scrollToCurrentPage();
    };

    /// Navigate to next page
    window.nextPage = function() {
        window.goToPage(currentPageIndex + 1);
    };

    /// Navigate to previous page
    window.prevPage = function() {
        window.goToPage(currentPageIndex - 1);
    };

    /// Get the scroll offset of a specific page (for Swift scrollView control)
    window.getPageTop = function(index) {
        var pages = editor.querySelectorAll('.st-page');
        if (index < 0 || index >= pages.length) return 0;
        return pages[index].offsetTop;
    };

    /// Get page info as JSON string
    window.getPageInfo = function() {
        var pages = editor.querySelectorAll('.st-page');
        return JSON.stringify({
            current: currentPageIndex,
            total: pages.length
        });
    };

    // ============================================================
    // EVENT LISTENERS
    // ============================================================

    // Fix: iOS WKWebView selects the entire .st-page container when the user
    // taps on its padding area (not directly on text). Intercept these taps
    // by saving the intended caret position, then restoring it if a
    // non-collapsed selection appears immediately after.
    var _tapCaretRange = null;
    editor.addEventListener('touchstart', function(e) {
        if (_isSelectMode) return;
        var target = e.target;
        if (target === editor || (target.classList && target.classList.contains('st-page'))) {
            if (e.touches.length === 1 && document.caretRangeFromPoint) {
                var t = e.touches[0];
                var range = document.caretRangeFromPoint(t.clientX, t.clientY);
                // Only save if the resolved caret is inside actual content (not the page/editor itself)
                if (range && range.startContainer !== editor &&
                    !(range.startContainer.nodeType === Node.ELEMENT_NODE &&
                      range.startContainer.classList &&
                      range.startContainer.classList.contains('st-page'))) {
                    _tapCaretRange = range;
                } else {
                    _tapCaretRange = null;
                }
            }
        } else {
            _tapCaretRange = null;
        }
    }, { passive: true });

    // Track selection changes for formatting state
    document.addEventListener('selectionchange', function() {
        // If we saved a caret position from a container tap, restore it now
        // (prevents the whole-document selection caused by tapping empty space)
        if (_tapCaretRange) {
            var sel = window.getSelection();
            if (sel && !sel.isCollapsed) {
                var savedRange = _tapCaretRange;
                _tapCaretRange = null;
                sel.removeAllRanges();
                sel.addRange(savedRange);
                return;
            }
            _tapCaretRange = null;
        }
        updateFormattingState();
    });

    // Track content changes for dirty flag and re-pagination
    var observer = new MutationObserver(function() {
        if (isPaginating || isNavigating) return;
        notifyContentChanged();
        schedulePagination();
    });
    observer.observe(editor, {
        childList: true,
        subtree: true,
        characterData: true,
        attributes: true
    });

    // Track scroll position to detect current page (for scroll-snap)
    var _scrollDebounce = null;
    window.addEventListener('scroll', function() {
        if (isPaginating || isNavigating) return;
        if (_scrollDebounce) clearTimeout(_scrollDebounce);
        _scrollDebounce = setTimeout(function() {
            var pages = editor.querySelectorAll('.st-page');
            if (pages.length <= 1) return;
            var scrollY = window.scrollY || window.pageYOffset;
            var viewportMid = scrollY + (window.innerHeight / 2);
            var bestPage = 0;
            for (var i = 0; i < pages.length; i++) {
                var top = pages[i].offsetTop;
                var bottom = top + pages[i].offsetHeight;
                if (viewportMid >= top && viewportMid < bottom) {
                    bestPage = i;
                    break;
                }
                if (top > viewportMid) break;
                bestPage = i;
            }
            if (bestPage !== currentPageIndex) {
                currentPageIndex = bestPage;
                notifyPageChange();
            }
        }, 150);
    }, { passive: true });

    // Track chart taps
    editor.addEventListener('click', function(e) {
        var target = e.target;
        // Walk up to find chart container
        while (target && target !== editor) {
            if (target.classList && target.classList.contains('st-chart-container')) {
                var chartId = target.getAttribute('data-chart-id');
                if (chartId) {
                    try {
                        webkit.messageHandlers.chartTapped.postMessage({ chartId: chartId });
                    } catch(ex) {}
                    e.preventDefault();
                    e.stopPropagation();
                    return;
                }
            }
            target = target.parentElement;
        }
    });

    // Track comment taps — show comment text popup
    editor.addEventListener('click', function(e) {
        var target = e.target;
        while (target && target !== editor) {
            if (target.classList && target.classList.contains('st-comment-highlight')) {
                var commentId = target.getAttribute('data-comment-id');
                var commentText = target.getAttribute('data-comment-text');
                var contextText = (target.textContent || '').substring(0, 80);
                try {
                    webkit.messageHandlers.commentTapped.postMessage({
                        commentId: commentId,
                        text: commentText,
                        contextText: contextText
                    });
                } catch(ex) {}
                e.stopPropagation();
                return;
            }
            target = target.parentElement;
        }
    });

    // Track active table cell and fix cursor placement on iOS using touch events
    var _pendingTouchCell = null;
    var _pendingTouchX = 0;
    var _pendingTouchY = 0;

    editor.addEventListener('touchstart', function(e) {
        _pendingTouchCell = null;
        if (e.touches.length !== 1) return;
        var touch = e.touches[0];
        _pendingTouchX = touch.clientX;
        _pendingTouchY = touch.clientY;
        var el = document.elementFromPoint(touch.clientX, touch.clientY);
        while (el && el !== editor) {
            if (el.nodeType === Node.ELEMENT_NODE &&
                (el.tagName === 'TD' || el.tagName === 'TH')) {
                _pendingTouchCell = el;
                return;
            }
            el = el.parentNode;
        }
    }, { passive: true });

    editor.addEventListener('touchend', function(e) {
        var cell = _pendingTouchCell;
        var touchX = _pendingTouchX;
        var touchY = _pendingTouchY;
        _pendingTouchCell = null;
        if (!cell) return;
        jsLog('touchend: cell=' + cell.tagName + ', selectMode=' + _isSelectMode);

        setTimeout(function() {
            // Update cell highlight (works in both modes)
            var prev = editor.querySelectorAll('.st-active-cell');
            for (var i = 0; i < prev.length; i++) prev[i].classList.remove('st-active-cell');
            cell.classList.add('st-active-cell');
            jsLog('touchend: set .st-active-cell, text=' + cell.textContent.substring(0, 20));
            updateFormattingState();
            checkTableActivation();

            // In normal mode: force cursor INTO the tapped cell at the touch position
            if (!_isSelectMode) {
                forceCursorIntoCell(cell, touchX, touchY);
            }
        }, 50);
    }, { passive: true });

    // Fallback click handler for cell highlight (desktop/non-touch)
    editor.addEventListener('click', function(e) {
        if (_pendingTouchCell) return;
        // Find cell from click target (works in both modes)
        var cell = null;
        var el = e.target;
        while (el && el !== editor) {
            if (el.nodeType === Node.ELEMENT_NODE &&
                (el.tagName === 'TD' || el.tagName === 'TH')) {
                cell = el;
                break;
            }
            el = el.parentNode;
        }
        // Fallback to selection-based lookup
        if (!cell) cell = getActiveTableCell();

        var prev = editor.querySelectorAll('.st-active-cell');
        for (var i = 0; i < prev.length; i++) prev[i].classList.remove('st-active-cell');
        if (cell) cell.classList.add('st-active-cell');
        checkTableActivation();

        // In select mode, if clicked outside any table, deactivate
        if (_isSelectMode && !cell) {
            deactivateTable();
        }
    });

    // Deactivate table when clicking outside any table (only in edit mode)
    document.addEventListener('selectionchange', function() {
        if (_isSelectMode) return; // In select mode, table is managed by touch/click handlers
        setTimeout(function() {
            if (_tableResizing || _colResizeIdx >= 0) return;
            var cell = getActiveTableCell();
            if (!cell) {
                exitCellEdit();
                deactivateTable();
            }
        }, 50);
    });

    // ============================================================
    // SCROLL TO CURSOR — keeps cursor visible when keyboard appears
    // ============================================================

    window.scrollToCursor = function() {
        var sel = window.getSelection();
        if (!sel.rangeCount) return;
        var range = sel.getRangeAt(0);
        var rect = range.getBoundingClientRect();
        // If cursor rect is near bottom of viewport, scroll it into view
        var viewH = window.innerHeight;
        if (rect.bottom > viewH - 40 || rect.top < 0) {
            var node = range.startContainer;
            if (node.nodeType === Node.TEXT_NODE) node = node.parentElement;
            if (node && node.scrollIntoView) {
                node.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        }
    };

    // Auto-scroll when keyboard opens (iOS fires resize)
    var _lastViewportH = window.innerHeight;
    window.addEventListener('resize', function() {
        var newH = window.innerHeight;
        if (newH < _lastViewportH - 100) {
            // Keyboard likely opened — scroll cursor into view
            setTimeout(function() { window.scrollToCursor(); }, 300);
        }
        _lastViewportH = newH;
    });

    // ============================================================
    // WORD COUNT — extract plain text for Swift-side stats
    // ============================================================

    window.getTextContent = function() {
        return editor.innerText || editor.textContent || '';
    };

    // ============================================================
    // FIND / REPLACE — DOM-based search with highlight
    // ============================================================

    var _findMatches = [];      // array of Range objects
    var _findCurrentIdx = -1;   // currently focused match index
    var _findHighlights = [];   // array of <mark> elements

    /// Clear all find highlights and reset state
    window.clearFindHighlights = function() {
        for (var i = 0; i < _findHighlights.length; i++) {
            var mark = _findHighlights[i];
            var parent = mark.parentNode;
            if (parent) {
                while (mark.firstChild) {
                    parent.insertBefore(mark.firstChild, mark);
                }
                parent.removeChild(mark);
                parent.normalize();
            }
        }
        _findHighlights = [];
        _findMatches = [];
        _findCurrentIdx = -1;
    };

    /// Find all occurrences of term, highlight them, return count
    window.findInContent = function(term, caseSensitive) {
        clearFindHighlights();
        if (!term || term.length === 0) return 0;

        var flags = caseSensitive ? 'g' : 'gi';
        var regex = new RegExp(term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), flags);

        // Walk all text nodes in editor
        var walker = document.createTreeWalker(editor, NodeFilter.SHOW_TEXT, null, false);
        var textNodes = [];
        var node;
        while (node = walker.nextNode()) {
            // Skip nodes inside shape menus or chart containers
            if (node.parentNode.closest && (
                node.parentNode.closest('.st-shape-menu') ||
                node.parentNode.closest('.st-chart-container')
            )) continue;
            textNodes.push(node);
        }

        // Find matches in each text node
        var matchRanges = [];
        for (var i = 0; i < textNodes.length; i++) {
            var textNode = textNodes[i];
            var text = textNode.nodeValue;
            var match;
            regex.lastIndex = 0;
            while ((match = regex.exec(text)) !== null) {
                matchRanges.push({
                    node: textNode,
                    start: match.index,
                    length: match[0].length
                });
            }
        }

        // Wrap matches in <mark> elements (reverse order to preserve offsets)
        for (var j = matchRanges.length - 1; j >= 0; j--) {
            var m = matchRanges[j];
            var range = document.createRange();
            range.setStart(m.node, m.start);
            range.setEnd(m.node, m.start + m.length);

            var mark = document.createElement('mark');
            mark.className = 'st-find-highlight';
            mark.style.cssText = 'background:#FFFF00;color:#000;padding:0;';
            range.surroundContents(mark);
            _findHighlights.unshift(mark);
        }

        _findMatches = _findHighlights.slice();
        if (_findMatches.length > 0) {
            _findCurrentIdx = 0;
            _highlightCurrent();
        }
        return _findMatches.length;
    };

    function _highlightCurrent() {
        // Reset all to yellow
        for (var i = 0; i < _findMatches.length; i++) {
            _findMatches[i].style.background = '#FFFF00';
        }
        // Current match orange
        if (_findCurrentIdx >= 0 && _findCurrentIdx < _findMatches.length) {
            var current = _findMatches[_findCurrentIdx];
            current.style.background = '#FF9632';
            current.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    /// Move to next match, return new index (0-based)
    window.findNext = function() {
        if (_findMatches.length === 0) return -1;
        _findCurrentIdx = (_findCurrentIdx + 1) % _findMatches.length;
        _highlightCurrent();
        return _findCurrentIdx;
    };

    /// Move to previous match, return new index (0-based)
    window.findPrevious = function() {
        if (_findMatches.length === 0) return -1;
        _findCurrentIdx = (_findCurrentIdx - 1 + _findMatches.length) % _findMatches.length;
        _highlightCurrent();
        return _findCurrentIdx;
    };

    /// Replace current match with replacement text, return remaining count
    window.replaceCurrent = function(replacement) {
        if (_findCurrentIdx < 0 || _findCurrentIdx >= _findMatches.length) return _findMatches.length;
        var mark = _findMatches[_findCurrentIdx];
        var textNode = document.createTextNode(replacement);
        mark.parentNode.replaceChild(textNode, mark);
        textNode.parentNode.normalize();

        // Remove from arrays
        var hIdx = _findHighlights.indexOf(mark);
        if (hIdx >= 0) _findHighlights.splice(hIdx, 1);
        _findMatches.splice(_findCurrentIdx, 1);

        // Adjust index
        if (_findMatches.length === 0) {
            _findCurrentIdx = -1;
        } else {
            if (_findCurrentIdx >= _findMatches.length) _findCurrentIdx = 0;
            _highlightCurrent();
        }
        notifyContentChanged();
        return _findMatches.length;
    };

    /// Replace all matches, return count of replacements made
    window.replaceAll = function(replacement) {
        var count = _findMatches.length;
        for (var i = _findMatches.length - 1; i >= 0; i--) {
            var mark = _findMatches[i];
            var textNode = document.createTextNode(replacement);
            mark.parentNode.replaceChild(textNode, mark);
            textNode.parentNode.normalize();
        }
        _findHighlights = [];
        _findMatches = [];
        _findCurrentIdx = -1;
        if (count > 0) notifyContentChanged();
        return count;
    };

    /// Get current find state as object
    window.getFindState = function() {
        return {
            total: _findMatches.length,
            current: _findCurrentIdx
        };
    };

    // ============================================================
    // SETTINGS — editor appearance
    // ============================================================

    window.setEditorFontSize = function(sizePt) {
        editor.style.fontSize = sizePt + 'pt';
    };

    window.setEditorBackgroundColor = function(color) {
        document.body.style.backgroundColor = color;
        var pages = editor.querySelectorAll('.st-page');
        for (var i = 0; i < pages.length; i++) {
            pages[i].style.backgroundColor = color;
        }
    };

    // ============================================================
    // SELECT MODE — hand/pointer mode for table selection & resize
    // ============================================================

    window.setSelectMode = function(enabled) {
        _isSelectMode = !!enabled;
        if (_isSelectMode) {
            // Disable editing → keyboard won't open
            editor.contentEditable = 'false';
            editor.style.webkitUserSelect = 'none';
            editor.style.cursor = 'default';
            // Block editing in active wrapper too
            if (_tableWrapper) _tableWrapper.contentEditable = 'false';
        } else {
            // Re-enable editing
            editor.contentEditable = 'true';
            editor.style.webkitUserSelect = 'auto';
            editor.style.cursor = 'text';
            deactivateTable();
        }
    };

    // In select mode, tap on a table to select it (instead of editing)
    editor.addEventListener('touchstart', function(e) {
        if (!_isSelectMode) return;
        // Don't intercept resize handle touches — let them through
        var target = e.target;
        if (target.classList && (
            target.classList.contains('st-table-resize-handle') ||
            target.classList.contains('st-col-resize-indicator')
        )) return;

        // Walk up from touched element to find a table and/or cell
        var el = document.elementFromPoint(e.touches[0].clientX, e.touches[0].clientY);
        var tappedCell = null;
        var tappedTable = null;
        while (el && el !== editor) {
            if (!tappedCell && el.nodeType === Node.ELEMENT_NODE &&
                (el.tagName === 'TD' || el.tagName === 'TH')) {
                tappedCell = el;
            }
            if (el.tagName === 'TABLE') {
                tappedTable = el;
                break;
            }
            el = el.parentNode;
        }

        if (tappedTable) {
            e.preventDefault();
            activateTable(tappedTable);
            // Update active cell to the tapped cell (not just first cell)
            if (tappedCell) {
                var prev = editor.querySelectorAll('.st-active-cell');
                for (var i = 0; i < prev.length; i++) prev[i].classList.remove('st-active-cell');
                tappedCell.classList.add('st-active-cell');
                jsLog('selectMode touch: set active cell=' + tappedCell.textContent.substring(0, 20));
            }
            return;
        }
        // Tapped outside any table → deactivate
        deactivateTable();
    }, { passive: false });

    // Notify Swift that editor is ready
    try {
        webkit.messageHandlers.editorReady.postMessage(true);
    } catch(e) {}

})();
