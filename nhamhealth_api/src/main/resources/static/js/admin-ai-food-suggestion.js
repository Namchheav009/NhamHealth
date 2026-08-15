(() => {
    const byId = (id) => document.getElementById(id);
    const rowsBox = byId('suggestionRows');
    const search = byId('suggestionSearch');
    const typeFilter = byId('typeFilter');
    const priorityFilter = byId('priorityFilter');
    const numbers = byId('pageNumbers');
    const prev = byId('pagePrev');
    const next = byId('pageNext');
    const modal = byId('suggestionModal');
    const form = byId('suggestionForm');
    const saveButton = form?.querySelector('button[type="submit"]');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    const pageSize = 10;
    let page = 1;
    let filtered = [];

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const setText = (id, value) => { const node = byId(id); if (node) node.textContent = String(value); };
    const priorityGroup = (value) => value >= 8 ? 'high' : value >= 4 ? 'medium' : 'low';

    rows().forEach((row) => {
        row.dataset.priorityValue = row.querySelector('.priority-badge b')?.textContent.trim() || '0';
        row.dataset.analysisId = row.querySelector('.source-cell small')?.textContent.match(/\d+/)?.[0] || '';
    });

    async function request(url, method, body) {
        const response = await fetch(url, {
            method,
            headers: {
                ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
                ...(body ? { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' } : {}),
                Accept: 'application/json'
            },
            credentials: 'same-origin', body
        });
        const data = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) throw new Error(data.message || data.detail || 'Unable to complete this request.');
        return data;
    }

    function filterRows() {
        const term = search.value.trim().toLowerCase();
        filtered = rows().filter((row) => (!term || row.dataset.search.includes(term))
            && (typeFilter.value === 'all' || row.dataset.type === typeFilter.value)
            && (priorityFilter.value === 'all' || row.dataset.priority === priorityFilter.value));
    }

    function render() {
        filterRows();
        const pages = Math.max(1, Math.ceil(filtered.length / pageSize));
        page = Math.min(page, pages);
        const start = (page - 1) * pageSize;
        const shown = new Set(filtered.slice(start, start + pageSize));
        rows().forEach((row) => { row.hidden = !shown.has(row); });
        setText('pageStart', filtered.length ? start + 1 : 0);
        setText('pageEnd', Math.min(start + pageSize, filtered.length));
        setText('visibleSuggestionCount', filtered.length);
        setText('filteredSuggestionTotal', filtered.length);
        prev.disabled = page === 1; next.disabled = page === pages || !filtered.length;
        numbers.replaceChildren();
        for (let number = 1; number <= pages; number += 1) {
            const button = document.createElement('button');
            button.type = 'button'; button.className = `page-btn${number === page ? ' active' : ''}`; button.textContent = String(number);
            button.setAttribute('aria-label', `Page ${number}`); if (number === page) button.setAttribute('aria-current', 'page');
            button.addEventListener('click', () => { page = number; render(); }); numbers.appendChild(button);
        }
    }

    function updateSummary() {
        const allRows = rows();
        const priorities = allRows.map((row) => Number(row.dataset.priorityValue));
        const average = priorities.length ? priorities.reduce((sum, value) => sum + value, 0) / priorities.length : 0;
        setText('totalSuggestionCount', allRows.length);
        setText('sourceAnalysisCount', new Set(allRows.map((row) => row.dataset.analysisId).filter(Boolean)).size);
        setText('highPrioritySuggestionCount', priorities.filter((value) => value >= 8).length);
        setText('averageSuggestionPriority', average.toFixed(1));
    }

    function createRow(item) {
        const row = document.createElement('tr');
        const priority = Number(item.priority);
        Object.assign(row.dataset, {
            id: String(item.id), analysisId: String(item.analysisId), priorityValue: String(priority),
            type: item.suggestionType.toLowerCase(), priority: priorityGroup(priority),
            search: `${item.title} ${item.suggestionType} ${item.description} ${item.reason} ${item.sourceName}`.toLowerCase()
        });
        const sourceCell = document.createElement('td'); const source = document.createElement('div'); source.className = 'source-cell';
        const sourceIcon = document.createElement('span'); sourceIcon.className = 'source-icon'; sourceIcon.innerHTML = '<i class="bi bi-robot"></i>';
        const sourceText = document.createElement('span'); const sourceName = document.createElement('strong'); sourceName.textContent = item.sourceName; const sourceId = document.createElement('small'); sourceId.textContent = `Analysis #${item.analysisId}`; sourceText.append(sourceName, sourceId); source.append(sourceIcon, sourceText); sourceCell.appendChild(source);
        const typeCell = document.createElement('td'); const type = document.createElement('span'); type.className = 'type-badge'; type.textContent = item.suggestionType; typeCell.appendChild(type);
        const titleCell = document.createElement('td'); const title = document.createElement('strong'); title.className = 'suggestion-title'; title.textContent = item.title; titleCell.appendChild(title);
        const descriptionCell = document.createElement('td'); const description = document.createElement('p'); description.className = 'copy'; description.textContent = item.description; descriptionCell.appendChild(description);
        const reasonCell = document.createElement('td'); const reason = document.createElement('p'); reason.className = 'copy muted'; reason.textContent = item.reason || 'No reason provided'; reasonCell.appendChild(reason);
        const priorityCell = document.createElement('td'); const badge = document.createElement('span'); badge.className = `priority-badge ${priorityGroup(priority)}`; const value = document.createElement('b'); value.textContent = String(priority); const scale = document.createElement('small'); scale.textContent = '/10'; badge.append(value, scale); priorityCell.appendChild(badge);
        const actionCell = document.createElement('td'); const action = document.createElement('button'); action.type = 'button'; action.className = 'icon-button danger delete-suggestion'; action.title = 'Delete suggestion'; action.setAttribute('aria-label', 'Delete suggestion'); action.innerHTML = '<i class="bi bi-trash3"></i>'; actionCell.appendChild(action);
        row.append(sourceCell, typeCell, titleCell, descriptionCell, reasonCell, priorityCell, actionCell);
        return row;
    }

    function addSuggestion(item) {
        rowsBox.querySelector('tr:not([data-id])')?.remove(); rowsBox.prepend(createRow(item));
        if (![...typeFilter.options].some((option) => option.value === item.suggestionType.toLowerCase())) { const option = document.createElement('option'); option.value = item.suggestionType.toLowerCase(); option.textContent = item.suggestionType; typeFilter.appendChild(option); }
        updateSummary(); render();
    }

    function addEmptyState() {
        if (rows().length || rowsBox.querySelector('tr:not([data-id])')) return;
        const empty = document.createElement('tr'); const cell = document.createElement('td'); cell.colSpan = 7; cell.className = 'empty-state'; cell.textContent = 'No AI food suggestions yet. Suggestions linked to food analyses will appear here.'; empty.appendChild(cell); rowsBox.appendChild(empty);
    }

    function showModal() { modal.classList.add('show'); modal.setAttribute('aria-hidden', 'false'); document.body.classList.add('modal-open'); form.elements.analysisId.focus(); }
    function hideModal() { modal.classList.remove('show'); modal.setAttribute('aria-hidden', 'true'); document.body.classList.remove('modal-open'); form.reset(); }

    async function saveSuggestion(event) {
        event.preventDefault();
        if (!form.checkValidity()) { const invalid = form.querySelector(':invalid'); await alerts.error(invalid?.validationMessage || 'Complete all required fields.', 'Missing suggestion information'); invalid?.focus(); return; }
        const data = new FormData(form); const csrfName = form.querySelector('input[type="hidden"]')?.name; if (csrfName) data.delete(csrfName);
        const label = saveButton.innerHTML; saveButton.disabled = true; saveButton.textContent = 'Saving...';
        try { const item = await request('/admin/ai-food-suggestions', 'POST', new URLSearchParams(data)); addSuggestion(item); hideModal(); await alerts.success('Suggestion added', `${item.title} has been added.`); }
        catch (error) { await alerts.error(error.message || 'The suggestion could not be saved.'); }
        finally { saveButton.disabled = false; saveButton.innerHTML = label; }
    }

    async function deleteSuggestion(button) {
        const row = button.closest('tr[data-id]'); if (!row) return;
        const title = row.querySelector('.suggestion-title')?.textContent.trim() || 'this suggestion';
        if (!await alerts.confirmDelete({ title: 'Delete AI food suggestion?', text: `${title} will be permanently removed.`, confirmButtonText: 'Yes, delete it!' })) return;
        button.disabled = true;
        try { await request(`/admin/ai-food-suggestions/${row.dataset.id}`, 'DELETE'); row.remove(); addEmptyState(); updateSummary(); render(); await alerts.success('Suggestion deleted', `${title} has been deleted.`); }
        catch (error) { button.disabled = false; await alerts.error(error.message || 'The suggestion could not be deleted.'); }
    }

    [search, typeFilter, priorityFilter].forEach((control) => control.addEventListener(control === search ? 'input' : 'change', () => { page = 1; render(); }));
    byId('clearFilters')?.addEventListener('click', () => { search.value = ''; typeFilter.value = 'all'; priorityFilter.value = 'all'; page = 1; render(); search.focus(); });
    prev.addEventListener('click', () => { if (page > 1) { page -= 1; render(); } }); next.addEventListener('click', () => { if (page * pageSize < filtered.length) { page += 1; render(); } });
    byId('refreshSuggestions')?.addEventListener('click', () => window.location.reload()); byId('openSuggestionModal')?.addEventListener('click', showModal); byId('closeSuggestionModal')?.addEventListener('click', hideModal); byId('cancelSuggestionModal')?.addEventListener('click', hideModal);
    modal.addEventListener('click', (event) => { if (event.target === modal) hideModal(); }); document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal.classList.contains('show')) hideModal(); }); form.addEventListener('submit', saveSuggestion);
    document.addEventListener('click', (event) => { const button = event.target.closest('.delete-suggestion'); if (button) deleteSuggestion(button); });
    byId('exportSuggestions')?.addEventListener('click', () => { filterRows(); const headings = ['Source analysis', 'Type', 'Suggestion', 'Description', 'Reason', 'Priority']; const data = filtered.map((row) => [...row.cells].slice(0, 6).map((cell) => cell.innerText.trim())); const quote = (value) => `"${String(value).replaceAll('"', '""')}"`; const csv = [headings, ...data].map((line) => line.map(quote).join(',')).join('\r\n'); const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })); link.download = 'nham-health-ai-food-suggestions.csv'; link.click(); URL.revokeObjectURL(link.href); });

    updateSummary(); render();
})();
