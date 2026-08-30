(() => {
    const byId = (id) => document.getElementById(id);
    const rowsBox = byId('wellnessRows');
    const search = byId('summarySearch');
    const moodFilter = byId('moodFilter');
    const balanceFilter = byId('balanceFilter');
    const numbers = byId('pageNumbers');
    const prev = byId('pagePrev');
    const next = byId('pageNext');
    const modal = byId('wellnessModal');
    const form = byId('wellnessForm');
    const saveButton = byId('saveWellnessButton');
    const formError = byId('wellnessFormError');
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
    let editingSummaryId = null;

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const setText = (id, value) => { const node = byId(id); if (node) node.textContent = String(value); };
    const today = () => {
        const date = new Date();
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    };
    const formatDate = (value) => value ? new Intl.DateTimeFormat(undefined, { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' }).format(new Date(`${value}T00:00:00Z`)) : '—';
    const formatDateTime = (value) => value ? new Intl.DateTimeFormat(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }).format(new Date(value)) : '—';

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
            && (moodFilter.value === 'all' || row.dataset.mood === moodFilter.value)
            && (balanceFilter.value === 'all' || row.dataset.balance === balanceFilter.value));
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
        setText('visibleSummaryCount', filtered.length);
        setText('filteredSummaryTotal', filtered.length);
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
        setText('totalWellnessCount', allRows.length);
        setText('wellnessUserCount', new Set(allRows.map((row) => row.dataset.userId).filter(Boolean)).size);
        setText('wellnessInsightCount', allRows.filter((row) => row.dataset.insight === 'true').length);
        setText('todayWellnessCount', allRows.filter((row) => row.dataset.today === 'true').length);
    }

    function createRow(summary, existingNutritionCell) {
        const row = document.createElement('tr');
        Object.assign(row.dataset, {
            id: String(summary.id), userId: String(summary.userId), summaryDate: summary.summaryDate,
            moodId: summary.moodId || '', balanceStatus: summary.balanceStatus || '', insightText: summary.aiInsightText || '',
            today: String(summary.summaryDate === today()),
            insight: String(Boolean(summary.aiInsightText)), mood: summary.moodName.toLowerCase(),
            balance: summary.balanceStatus.toLowerCase(),
            search: `${summary.userName} ${summary.userEmail} ${summary.moodName} ${summary.balanceStatus} ${summary.aiInsightText}`.toLowerCase()
        });
        const userCell = document.createElement('td');
        const userBox = document.createElement('div'); userBox.className = 'user-cell';
        const avatar = document.createElement('span'); avatar.className = 'user-avatar'; avatar.textContent = summary.userInitials || 'U';
        const userText = document.createElement('span'); const userName = document.createElement('strong'); userName.textContent = summary.userName || 'User';
        const email = document.createElement('small'); email.textContent = summary.userEmail; userText.append(userName, email); userBox.append(avatar, userText); userCell.appendChild(userBox);
        const dateCell = document.createElement('td'); const date = document.createElement('time'); date.className = 'date-cell'; date.dateTime = summary.summaryDate; date.textContent = formatDate(summary.summaryDate); dateCell.appendChild(date);
        const moodCell = document.createElement('td'); const mood = document.createElement('span'); mood.className = 'mood-badge';
        const emoji = document.createElement('span'); emoji.textContent = summary.moodEmoji || '●'; const moodName = document.createElement('b'); moodName.textContent = summary.moodName || 'Not recorded'; mood.append(emoji, moodName); moodCell.appendChild(mood);
        const balanceCell = document.createElement('td'); const balance = document.createElement('span');
        balance.className = `balance-badge ${summary.balanceStatus.toLowerCase() === 'balanced' ? 'balanced' : 'other'}`; balance.textContent = summary.balanceStatus || 'Not recorded'; balanceCell.appendChild(balance);
        const nutritionCell = existingNutritionCell || document.createElement('td');
        if (!existingNutritionCell) {
            const nutrition = document.createElement('div'); nutrition.className = 'nutrition-values';
            const nutritionText = document.createElement('small'); nutritionText.textContent = 'No nutrition logged';
            nutrition.appendChild(nutritionText); nutritionCell.appendChild(nutrition);
        }
        const insightCell = document.createElement('td'); const insight = document.createElement('p'); insight.className = 'insight-copy'; insight.textContent = summary.aiInsightText || 'No wellness insight'; insightCell.appendChild(insight);
        const updatedCell = document.createElement('td'); const updated = document.createElement('time'); updated.dateTime = summary.updatedAt; updated.textContent = formatDateTime(summary.updatedAt); updatedCell.appendChild(updated);
        const actionCell = document.createElement('td'); const actions = document.createElement('div'); actions.className = 'wellness-actions';
        const edit = document.createElement('button'); edit.type = 'button'; edit.className = 'icon-button edit-summary'; edit.title = 'Edit wellness summary'; edit.setAttribute('aria-label', 'Edit wellness summary'); edit.innerHTML = '<i class="bi bi-pencil"></i>';
        const action = document.createElement('button'); action.type = 'button'; action.className = 'icon-button danger delete-summary'; action.title = 'Delete wellness summary'; action.setAttribute('aria-label', 'Delete wellness summary'); action.innerHTML = '<i class="bi bi-trash3"></i>'; actions.append(edit, action); actionCell.appendChild(actions);
        row.append(userCell, dateCell, moodCell, balanceCell, nutritionCell, insightCell, updatedCell, actionCell);
        return row;
    }

    function addSummary(summary) {
        byId('emptyWellnessRow')?.remove(); rowsBox.prepend(createRow(summary)); updateSummary(); render();
    }

    function addEmptyState() {
        if (rows().length || byId('emptyWellnessRow')) return;
        const empty = document.createElement('tr'); empty.id = 'emptyWellnessRow';
        const cell = document.createElement('td'); cell.colSpan = 7; cell.className = 'empty-state'; cell.textContent = 'No wellness summaries yet. Daily mood and balance records will appear here.';
        empty.appendChild(cell); rowsBox.appendChild(empty);
    }

    function showModal() {
        formError.hidden = true; modal.classList.add('show'); modal.setAttribute('aria-hidden', 'false'); document.body.classList.add('modal-open');
        form.elements.userId.focus();
    }
    function hideModal() { modal.classList.remove('show'); modal.setAttribute('aria-hidden', 'true'); document.body.classList.remove('modal-open'); form.reset(); formError.hidden = true; editingSummaryId = null; }

    function openCreateModal() {
        editingSummaryId = null; form.reset(); form.elements.summaryDate.value = today();
        byId('wellnessModalTitle').textContent = 'Add wellness summary';
        byId('saveWellnessButton').innerHTML = '<i class="bi bi-check-lg"></i> Save summary';
        showModal();
    }

    function editSummary(button) {
        const row = button.closest('tr[data-id]'); if (!row) return;
        editingSummaryId = row.dataset.id; form.reset();
        form.elements.userId.value = row.dataset.userId || '';
        form.elements.summaryDate.value = row.dataset.summaryDate || '';
        form.elements.moodId.value = row.dataset.moodId || '';
        form.elements.balanceStatus.value = row.dataset.balanceStatus || '';
        form.elements.aiInsightText.value = row.dataset.insightText || '';
        byId('wellnessModalTitle').textContent = 'Edit wellness summary';
        byId('saveWellnessButton').innerHTML = '<i class="bi bi-check-lg"></i> Update summary';
        showModal();
    }

    async function saveSummary(event) {
        event.preventDefault();
        if (!form.checkValidity()) { const invalid = form.querySelector(':invalid'); await alerts.error(invalid?.validationMessage || 'Complete all required fields.', 'Missing wellness information'); invalid?.focus(); return; }
        const data = new FormData(form); const csrfName = form.querySelector('input[type="hidden"]')?.name; if (csrfName) data.delete(csrfName);
        const label = saveButton.innerHTML; saveButton.disabled = true; saveButton.textContent = 'Saving...'; formError.hidden = true;
        try {
            const isUpdate = Boolean(editingSummaryId);
            const summary = await request(isUpdate ? `/admin/daily-wellness/${editingSummaryId}` : '/admin/daily-wellness', isUpdate ? 'PUT' : 'POST', new URLSearchParams(data));
            if (isUpdate) {
                const currentRow = rows().find((row) => row.dataset.id === String(summary.id));
                if (currentRow) currentRow.replaceWith(createRow(summary, currentRow.cells[4].cloneNode(true)));
                updateSummary(); render();
            } else {
                addSummary(summary);
            }
            hideModal();
            await alerts.success(isUpdate ? 'Wellness summary updated' : 'Wellness summary added', `${summary.userName}'s ${formatDate(summary.summaryDate)} summary has been ${isUpdate ? 'updated' : 'added'}.`);
        } catch (error) { formError.textContent = error.message; formError.hidden = false; await alerts.error(error.message || 'The wellness summary could not be saved.'); }
        finally { saveButton.disabled = false; saveButton.innerHTML = label; }
    }

    async function deleteSummary(button) {
        const row = button.closest('tr[data-id]'); if (!row) return;
        const user = row.querySelector('.user-cell strong')?.textContent.trim() || 'the user'; const date = row.querySelector('.date-cell')?.textContent.trim() || 'this date';
        if (!await alerts.confirmDelete({ title: 'Delete wellness summary?', text: `${user}'s ${date} summary and its nutrient totals will be permanently removed.`, confirmButtonText: 'Yes, delete it!' })) return;
        button.disabled = true;
        try { await request(`/admin/daily-wellness/${row.dataset.id}`, 'DELETE'); row.remove(); addEmptyState(); updateSummary(); render(); await alerts.success('Wellness summary deleted', `${user}'s ${date} summary has been deleted.`); }
        catch (error) { button.disabled = false; await alerts.error(error.message || 'The wellness summary could not be deleted.'); }
    }

    [search, moodFilter, balanceFilter].forEach((control) => control.addEventListener(control === search ? 'input' : 'change', () => { page = 1; render(); }));
    byId('clearFilters')?.addEventListener('click', () => { search.value = ''; moodFilter.value = 'all'; balanceFilter.value = 'all'; page = 1; render(); search.focus(); });
    prev.addEventListener('click', () => { if (page > 1) { page -= 1; render(); } }); next.addEventListener('click', () => { if (page * pageSize < filtered.length) { page += 1; render(); } });
    byId('openWellnessModal')?.addEventListener('click', openCreateModal); byId('closeWellnessModal')?.addEventListener('click', hideModal); byId('cancelWellnessModal')?.addEventListener('click', hideModal);
    modal.addEventListener('click', (event) => { if (event.target === modal) hideModal(); }); document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal.classList.contains('show')) hideModal(); });
    form.addEventListener('submit', saveSummary); document.addEventListener('click', (event) => { const editButton = event.target.closest('.edit-summary'); if (editButton) editSummary(editButton); const deleteButton = event.target.closest('.delete-summary'); if (deleteButton) deleteSummary(deleteButton); });
    byId('exportWellness')?.addEventListener('click', () => { filterRows(); const headings = ['User', 'Date', 'Mood', 'Balance', 'Insight', 'Updated']; const data = filtered.map((row) => [...row.cells].slice(0, 6).map((cell) => cell.innerText.trim())); const quote = (value) => `"${String(value).replaceAll('"', '""')}"`; const csv = [headings, ...data].map((line) => line.map(quote).join(',')).join('\r\n'); const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })); link.download = 'nham-health-daily-wellness.csv'; link.click(); URL.revokeObjectURL(link.href); });

    updateSummary(); render();
})();
