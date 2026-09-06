(() => {
    const byId = (id) => document.getElementById(id);
    const rowsBox = byId('analysisRows');
    const search = byId('analysisSearch');
    const statusFilter = byId('statusFilter');
    const confidenceFilter = byId('confidenceFilter');
    const numbers = byId('pageNumbers');
    const prev = byId('pagePrev');
    const next = byId('pageNext');
    const modal = byId('analysisModal');
    const form = byId('analysisForm');
    const saveButton = byId('saveAnalysisButton');
    const formError = byId('analysisFormError');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    const pageSize = 10;
    let page = 1;
    let filtered = [];

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const setText = (id, value) => { const node = byId(id); if (node) node.textContent = String(value); };
    const confidenceGroup = (score) => score === null ? 'unscored' : score >= .8 ? 'high' : score >= .5 ? 'medium' : 'low';
    const formatDateTime = (value) => new Intl.DateTimeFormat(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }).format(new Date(value));

    async function createRequest(data) {
        const csrfName = form.querySelector('input[type="hidden"]')?.name;
        if (csrfName) data.delete(csrfName);
        const response = await fetch('/admin/ai-food-analyses', {
            method: 'POST',
            headers: {
                ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
                'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                Accept: 'application/json'
            },
            credentials: 'same-origin',
            body: new URLSearchParams(data)
        });
        const body = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) throw new Error(body.message || body.detail || 'The analysis could not be saved.');
        return body;
    }

    function filterRows() {
        const term = search.value.trim().toLowerCase();
        filtered = rows().filter((row) => (!term || row.dataset.search.includes(term))
            && (statusFilter.value === 'all' || row.dataset.status === statusFilter.value)
            && (confidenceFilter.value === 'all' || row.dataset.confidence === confidenceFilter.value));
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
        setText('visibleAnalysisCount', filtered.length);
        setText('filteredAnalysisTotal', filtered.length);
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
        const scores = allRows.filter((row) => row.dataset.score !== '').map((row) => Number(row.dataset.score)).filter((score) => Number.isFinite(score));
        const average = scores.length ? scores.reduce((sum, score) => sum + score, 0) / scores.length : 0;
        setText('totalAnalysisCount', allRows.length);
        setText('analysisUserCount', new Set(allRows.map((row) => row.dataset.userId).filter(Boolean)).size);
        setText('averageAnalysisConfidence', `${(average * 100).toFixed(1)}%`);
        setText('pendingAnalysisCount', allRows.filter((row) => row.dataset.status === 'pending').length);
        setText('todayAnalysisCount', `${allRows.filter((row) => row.dataset.today === 'true').length} created today`);
    }

    function createRow(analysis) {
        const row = document.createElement('tr');
        const score = analysis.confidenceScore === '' ? null : Number(analysis.confidenceScore);
        Object.assign(row.dataset, {
            id: String(analysis.id), userId: String(analysis.userId), today: 'true', score: score === null ? '' : String(score),
            status: analysis.status, confidence: confidenceGroup(score),
            search: `${analysis.userName} ${analysis.userEmail} ${analysis.inputText} ${analysis.detectedFoodName} ${analysis.detectedServingText}`.toLowerCase()
        });
        const userCell = document.createElement('td'); const userBox = document.createElement('div'); userBox.className = 'user-cell';
        const avatar = document.createElement('span'); avatar.className = 'user-avatar'; avatar.textContent = analysis.userInitials || 'U';
        const userText = document.createElement('span'); const userName = document.createElement('strong'); userName.textContent = analysis.userName || 'User'; const email = document.createElement('small'); email.textContent = analysis.userEmail; userText.append(userName, email); userBox.append(avatar, userText); userCell.appendChild(userBox);
        const inputCell = document.createElement('td'); const input = document.createElement('p'); input.className = 'input-copy'; input.textContent = analysis.inputText; inputCell.appendChild(input);
        const foodCellBox = document.createElement('td'); const foodBox = document.createElement('div'); foodBox.className = 'food-cell'; foodBox.innerHTML = '<span class="food-icon"><i class="bi bi-egg-fried"></i></span>'; const food = document.createElement('strong'); food.textContent = analysis.detectedFoodName || 'Not detected'; foodBox.appendChild(food); foodCellBox.appendChild(foodBox);
        const servingCell = document.createElement('td'); servingCell.textContent = analysis.detectedServingText || '—';
        const confidenceCell = document.createElement('td');
        if (score === null) confidenceCell.textContent = 'Unscored';
        else { const box = document.createElement('div'); box.className = 'confidence'; const track = document.createElement('span'); track.className = 'confidence-track'; const fill = document.createElement('i'); fill.style.width = `${score * 100}%`; track.appendChild(fill); const value = document.createElement('strong'); value.textContent = `${Math.round(score * 100)}%`; box.append(track, value); confidenceCell.appendChild(box); }
        const statusCell = document.createElement('td'); const badge = document.createElement('span'); badge.className = `status-badge status-${analysis.status}`; badge.textContent = analysis.status.charAt(0).toUpperCase() + analysis.status.slice(1); statusCell.appendChild(badge);
        const createdCell = document.createElement('td'); const created = document.createElement('time'); created.dateTime = analysis.createdAt; created.textContent = formatDateTime(analysis.createdAt); createdCell.appendChild(created);
        row.append(userCell, inputCell, foodCellBox, servingCell, confidenceCell, statusCell, createdCell);
        return row;
    }

    function addAnalysis(analysis) {
        byId('emptyAnalysisRow')?.remove(); rowsBox.prepend(createRow(analysis));
        if (![...statusFilter.options].some((option) => option.value === analysis.status)) {
            const option = document.createElement('option'); option.value = analysis.status; option.textContent = analysis.status.charAt(0).toUpperCase() + analysis.status.slice(1); statusFilter.appendChild(option);
        }
        updateSummary(); render();
    }

    function showModal() { formError.hidden = true; modal.classList.add('show'); modal.setAttribute('aria-hidden', 'false'); document.body.classList.add('modal-open'); form.elements.userId.focus(); }
    function hideModal() { modal.classList.remove('show'); modal.setAttribute('aria-hidden', 'true'); document.body.classList.remove('modal-open'); form.reset(); formError.hidden = true; }

    async function saveAnalysis(event) {
        event.preventDefault();
        if (!form.checkValidity()) { const invalid = form.querySelector(':invalid'); await alerts.error(invalid?.validationMessage || 'Complete all required fields.', 'Missing analysis information'); invalid?.focus(); return; }
        const label = saveButton.innerHTML; saveButton.disabled = true; saveButton.textContent = 'Saving...'; formError.hidden = true;
        try {
            const analysis = await createRequest(new FormData(form));
            await alerts.success('Analysis added', `${analysis.userName}'s food analysis has been added.`);
            window.location.assign('/admin/ai-food-analyses');
        }
        catch (error) { formError.textContent = error.message; formError.hidden = false; await alerts.error(error.message || 'The analysis could not be saved.'); }
        finally { saveButton.disabled = false; saveButton.innerHTML = label; }
    }

    [search, statusFilter, confidenceFilter].forEach((control) => control.addEventListener(control === search ? 'input' : 'change', () => { page = 1; render(); }));
    byId('clearFilters')?.addEventListener('click', () => { search.value = ''; statusFilter.value = 'all'; confidenceFilter.value = 'all'; page = 1; render(); search.focus(); });
    prev.addEventListener('click', () => { if (page > 1) { page -= 1; render(); } }); next.addEventListener('click', () => { if (page * pageSize < filtered.length) { page += 1; render(); } });
    byId('refreshAnalyses')?.addEventListener('click', () => window.location.reload());
    byId('openAnalysisModal')?.addEventListener('click', showModal); byId('closeAnalysisModal')?.addEventListener('click', hideModal); byId('cancelAnalysisModal')?.addEventListener('click', hideModal);
    modal.addEventListener('click', (event) => { if (event.target === modal) hideModal(); }); document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal.classList.contains('show')) hideModal(); }); form.addEventListener('submit', saveAnalysis);
    byId('exportAnalyses')?.addEventListener('click', () => { filterRows(); const headings = ['User', 'Input', 'Detected food', 'Serving', 'Confidence', 'Status', 'Created']; const data = filtered.map((row) => [...row.cells].map((cell) => cell.innerText.trim())); const quote = (value) => `"${String(value).replaceAll('"', '""')}"`; const csv = [headings, ...data].map((line) => line.map(quote).join(',')).join('\r\n'); const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })); link.download = 'nham-health-ai-food-analyses.csv'; link.click(); URL.revokeObjectURL(link.href); });

    updateSummary(); render();
})();
