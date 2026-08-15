(() => {
    const byId = (id) => document.getElementById(id);
    const rowsBox = byId('mealLogRows');
    const search = byId('mealLogSearch');
    const type = byId('typeFilter');
    const method = byId('methodFilter');
    const pageNumbers = byId('pageNumbers');
    const prev = byId('pagePrev');
    const next = byId('pageNext');
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

    function applyFilters() {
        const term = (search?.value || '').trim().toLowerCase();
        filtered = rows().filter((row) => (!term || (row.dataset.search || '').includes(term))
            && (type.value === 'all' || row.dataset.type === type.value)
            && (method.value === 'all' || row.dataset.method === method.value));
    }

    function render() {
        applyFilters();
        const pages = Math.max(1, Math.ceil(filtered.length / pageSize));
        page = Math.min(page, pages);
        const start = (page - 1) * pageSize;
        const displayed = new Set(filtered.slice(start, start + pageSize));
        rows().forEach((row) => { row.hidden = !displayed.has(row); });
        setText('pageStart', filtered.length ? start + 1 : 0);
        setText('pageEnd', Math.min(start + pageSize, filtered.length));
        setText('visibleLogCount', filtered.length);
        setText('filteredLogTotal', filtered.length);
        prev.disabled = page === 1;
        next.disabled = page === pages || !filtered.length;
        pageNumbers.replaceChildren();
        for (let number = 1; number <= pages; number += 1) {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = `page-btn${number === page ? ' active' : ''}`;
            button.textContent = String(number);
            button.setAttribute('aria-label', `Page ${number}`);
            if (number === page) button.setAttribute('aria-current', 'page');
            button.addEventListener('click', () => { page = number; render(); });
            pageNumbers.appendChild(button);
        }
    }

    function updateSummary() {
        const allRows = rows();
        const users = new Set(allRows.map((row) => row.dataset.userId).filter(Boolean));
        setText('totalMealLogCount', allRows.length);
        setText('uniqueMealLogUserCount', users.size);
        setText('customFoodLogCount', allRows.filter((row) => row.dataset.custom === 'true').length);
        setText('todayMealLogCount', allRows.filter((row) => row.dataset.today === 'true').length);
    }

    function addEmptyState() {
        if (rows().length || byId('emptyMealLogRow')) return;
        const empty = document.createElement('tr');
        empty.id = 'emptyMealLogRow';
        const cell = document.createElement('td');
        cell.colSpan = 8;
        cell.className = 'empty-state';
        const icon = document.createElement('i');
        icon.className = 'bi bi-journal-x';
        const title = document.createElement('strong');
        title.textContent = 'No meal logs yet';
        const text = document.createElement('span');
        text.textContent = 'Meal activity will appear here when users record food.';
        cell.append(icon, title, text);
        empty.appendChild(cell);
        rowsBox.appendChild(empty);
    }

    async function deleteRequest(id) {
        const response = await fetch(`/admin/meal-logs/${id}`, {
            method: 'DELETE',
            headers: {
                ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
                Accept: 'application/json'
            },
            credentials: 'same-origin'
        });
        const body = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) throw new Error(body.message || body.detail || 'The meal log could not be deleted.');
    }

    async function deleteMealLog(button) {
        const row = button.closest('tr[data-id]');
        if (!row) return;
        const food = row.querySelector('.food-cell strong')?.textContent.trim() || 'this food';
        const user = row.querySelector('.user-cell strong')?.textContent.trim() || 'the user';
        const confirmed = await alerts.confirmDelete({
            title: 'Delete meal log?',
            text: `${user}'s ${food} entry and its nutrient details will be permanently removed.`,
            confirmButtonText: 'Yes, delete it!'
        });
        if (!confirmed) return;
        button.disabled = true;
        try {
            await deleteRequest(row.dataset.id);
            row.remove();
            addEmptyState();
            updateSummary();
            render();
            await alerts.success('Meal log deleted', `${user}'s ${food} entry has been deleted.`);
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'The meal log could not be deleted.');
        }
    }

    [search, type, method].forEach((control) => control?.addEventListener(control === search ? 'input' : 'change', () => {
        page = 1;
        render();
    }));
    byId('clearMealLogFilters')?.addEventListener('click', () => {
        search.value = '';
        type.value = 'all';
        method.value = 'all';
        page = 1;
        render();
        search.focus();
    });
    prev?.addEventListener('click', () => { if (page > 1) { page -= 1; render(); } });
    next?.addEventListener('click', () => { if (page * pageSize < filtered.length) { page += 1; render(); } });
    byId('refreshMealLogs')?.addEventListener('click', () => window.location.reload());
    byId('exportMealLogs')?.addEventListener('click', () => {
        applyFilters();
        const headings = ['Food', 'User', 'Meal type', 'Quantity', 'Entry method', 'Logged at', 'Notes'];
        const values = filtered.map((row) => [...row.cells].slice(0, 7).map((cell) => cell.innerText.trim()));
        const quote = (value) => `"${String(value).replaceAll('"', '""')}"`;
        const csv = [headings, ...values].map((line) => line.map(quote).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-meal-logs.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });
    document.addEventListener('click', (event) => {
        const button = event.target.closest('.delete-meal-log');
        if (button) deleteMealLog(button);
    });

    updateSummary();
    render();
})();
