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
    const detailsModal = byId('suggestionDetailsModal');
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
    let detailsTrigger = null;

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
        setText('totalSuggestionCount', allRows.length);
        setText('sourceAnalysisCount', new Set(allRows.map((row) => row.dataset.analysisId).filter(Boolean)).size);
        setText('learnedCorrectionCount', allRows.filter((row) => row.dataset.learnedCorrection === 'true').length);
        setText('highPrioritySuggestionCount', priorities.filter((value) => value >= 8).length);
    }

    function createRow(item) {
        const row = document.createElement('tr');
        const priority = Number(item.priority);
        Object.assign(row.dataset, {
            id: String(item.id), analysisId: String(item.analysisId), priorityValue: String(priority),
            type: item.suggestionType.toLowerCase(), priority: priorityGroup(priority),
            search: `${item.title} ${item.suggestionType} ${item.description} ${item.reason} ${item.sourceName}`.toLowerCase(),
            title: item.title, description: item.description, reason: item.reason || 'No reason provided',
            learnedCorrection: String(Boolean(item.learnedCorrection)),
            detectedName: item.detectedName || item.sourceName,
            correctedName: item.correctedName || item.title,
            correctedServing: item.correctedServing || 'Not recorded',
            analysisStatus: item.analysisStatus || 'Unknown', feedbackAt: item.feedbackAt || '',
            modelName: item.modelName || 'Not recorded', promptVersion: item.promptVersion || 'Not recorded'
        });
        const sourceCell = document.createElement('td'); const source = document.createElement('div'); source.className = 'source-cell';
        const sourceIcon = document.createElement('span'); sourceIcon.className = 'source-icon'; sourceIcon.innerHTML = '<i class="bi bi-robot"></i>';
        const sourceText = document.createElement('span'); const sourceName = document.createElement('strong'); sourceName.textContent = item.sourceName; const sourceId = document.createElement('small'); sourceId.textContent = `Analysis #${item.analysisId}`; sourceText.append(sourceName, sourceId); source.append(sourceIcon, sourceText); sourceCell.appendChild(source);
        const typeCell = document.createElement('td'); const type = document.createElement('span'); type.className = `type-badge${item.learnedCorrection ? ' learned' : ''}`; type.textContent = item.suggestionType; typeCell.appendChild(type);
        const titleCell = document.createElement('td'); const title = document.createElement('strong'); title.className = 'suggestion-title'; title.textContent = item.title; titleCell.appendChild(title);
        const descriptionCell = document.createElement('td'); const description = document.createElement('p'); description.className = 'copy'; description.textContent = item.description; descriptionCell.appendChild(description);
        const reasonCell = document.createElement('td'); const reason = document.createElement('p'); reason.className = 'copy muted'; reason.textContent = item.reason || 'No reason provided'; reasonCell.appendChild(reason);
        const priorityCell = document.createElement('td'); const badge = document.createElement('span'); badge.className = `priority-badge ${priorityGroup(priority)}`; const value = document.createElement('b'); value.textContent = String(priority); const scale = document.createElement('small'); scale.textContent = '/10'; badge.append(value, scale); priorityCell.appendChild(badge);
        const actionCell = document.createElement('td'); actionCell.className = 'row-actions';
        const view = document.createElement('button'); view.type = 'button'; view.className = 'icon-button view-suggestion'; view.title = 'View suggestion details'; view.setAttribute('aria-label', 'View suggestion details'); view.innerHTML = '<i class="bi bi-eye"></i>';
        const action = document.createElement('button'); action.type = 'button'; action.className = 'icon-button danger delete-suggestion'; action.title = 'Delete suggestion'; action.setAttribute('aria-label', 'Delete suggestion'); action.innerHTML = '<i class="bi bi-trash3"></i>'; actionCell.append(view, action);
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

    function formatTimestamp(value) {
        if (!value) return 'Not recorded';
        const parsed = new Date(value);
        if (Number.isNaN(parsed.getTime())) return value;
        return new Intl.DateTimeFormat(undefined, {
            dateStyle: 'medium', timeStyle: 'short'
        }).format(parsed);
    }

    function showDetails(button) {
        const row = button.closest('tr[data-id]'); if (!row || !detailsModal) return;
        detailsTrigger = button;
        const learned = row.dataset.learnedCorrection === 'true';
        const type = row.querySelector('.type-badge')?.textContent.trim() || 'Suggestion';
        const typeBadge = byId('detailType');
        typeBadge.textContent = type;
        typeBadge.className = `type-badge${learned ? ' learned' : ''}`;
        setText('detailTitle', row.dataset.title || 'Suggestion details');
        setText('detailAnalysisReference', row.dataset.analysisId ? `Analysis #${row.dataset.analysisId}` : 'Analysis unavailable');
        setText('detailDetectedName', row.dataset.detectedName || 'Not recorded');
        setText('detailCorrectedName', row.dataset.correctedName || row.dataset.title || 'Not recorded');
        setText('detailServing', row.dataset.correctedServing || 'Not recorded');
        setText('detailStatus', (row.dataset.analysisStatus || 'Unknown').replaceAll('_', ' '));
        setText('detailPriority', `${row.dataset.priorityValue || '0'}/10`);
        setText('detailFeedbackAt', formatTimestamp(row.dataset.feedbackAt));
        setText('detailModel', row.dataset.modelName || 'Not recorded');
        setText('detailPromptVersion', row.dataset.promptVersion || 'Not recorded');
        setText('detailDescription', row.dataset.description || 'No description provided.');
        setText('detailReason', row.dataset.reason || 'No reason provided.');
        const journeyLabels = byId('correctionJourney')?.querySelectorAll('article span');
        if (journeyLabels?.length === 2) {
            journeyLabels[0].textContent = learned ? 'Original AI result' : 'Source food';
            journeyLabels[1].textContent = learned ? 'Corrected result' : 'Suggestion';
        }
        byId('detailLearningNote').hidden = !learned;
        detailsModal.classList.add('show');
        detailsModal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        byId('closeSuggestionDetails')?.focus();
    }

    function hideDetails() {
        if (!detailsModal) return;
        detailsModal.classList.remove('show');
        detailsModal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        detailsTrigger?.focus();
        detailsTrigger = null;
    }

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
    byId('closeSuggestionDetails')?.addEventListener('click', hideDetails); byId('closeSuggestionDetailsFooter')?.addEventListener('click', hideDetails);
    modal.addEventListener('click', (event) => { if (event.target === modal) hideModal(); }); detailsModal?.addEventListener('click', (event) => { if (event.target === detailsModal) hideDetails(); }); document.addEventListener('keydown', (event) => { if (event.key !== 'Escape') return; if (detailsModal?.classList.contains('show')) hideDetails(); else if (modal.classList.contains('show')) hideModal(); }); form.addEventListener('submit', saveSuggestion);
    document.addEventListener('click', (event) => { const view = event.target.closest('.view-suggestion'); if (view) { showDetails(view); return; } const button = event.target.closest('.delete-suggestion'); if (button) deleteSuggestion(button); });
    byId('exportSuggestions')?.addEventListener('click', () => { filterRows(); const headings = ['Source analysis', 'Type', 'Suggestion', 'Description', 'Reason', 'Priority']; const data = filtered.map((row) => [...row.cells].slice(0, 6).map((cell) => cell.innerText.trim())); const quote = (value) => `"${String(value).replaceAll('"', '""')}"`; const csv = [headings, ...data].map((line) => line.map(quote).join(',')).join('\r\n'); const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })); link.download = 'nham-health-ai-food-suggestions.csv'; link.click(); URL.revokeObjectURL(link.href); });

    updateSummary(); render();
})();
