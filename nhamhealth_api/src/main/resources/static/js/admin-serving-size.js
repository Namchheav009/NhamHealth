(() => {
    const byId = (id) => document.getElementById(id);
    const modal = byId('servingModal');
    const form = byId('servingForm');
    const saveButton = byId('saveServingButton');
    const formError = byId('servingFormError');
    const rowsBox = byId('servingSizeRows');
    const searchInput = byId('servingSearch');
    const statusFilter = byId('statusFilter');
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const pageSize = 10;
    let currentPage = 1;
    let editingId = null;

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const headers = (json = false) => ({
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
        ...(json ? { 'Content-Type': 'application/json' } : {}),
        Accept: 'application/json'
    });

    async function request(url, method, payload) {
        const response = await fetch(url, {
            method, headers: headers(Boolean(payload)), credentials: 'same-origin',
            body: payload ? JSON.stringify(payload) : undefined
        });
        const body = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) {
            const validationMessage = Array.isArray(body.errors) ? body.errors[0]?.defaultMessage : null;
            throw new Error(body.message || body.detail || validationMessage || body.title || 'Unable to complete this request.');
        }
        return body;
    }

    function filteredRows() {
        const query = searchInput?.value.trim().toLowerCase() || '';
        const status = statusFilter?.value || 'all';
        return rows().filter((row) => (!query || row.dataset.name.includes(query)
            || (row.dataset.description || '').toLowerCase().includes(query))
            && (status === 'all' || row.dataset.status === status));
    }

    function renderPage() {
        const filtered = filteredRows();
        const pages = Math.max(1, Math.ceil(filtered.length / pageSize));
        currentPage = Math.min(currentPage, pages);
        rows().forEach((row) => { row.hidden = true; });
        const start = (currentPage - 1) * pageSize;
        filtered.slice(start, start + pageSize).forEach((row) => { row.hidden = false; });
        const numbers = byId('pageNumbers');
        numbers.replaceChildren();
        for (let page = 1; page <= pages; page += 1) {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = `page-number${page === currentPage ? ' active' : ''}`;
            button.textContent = String(page);
            button.setAttribute('aria-label', `Page ${page}`);
            button.addEventListener('click', () => { currentPage = page; renderPage(); });
            numbers.appendChild(button);
        }
        byId('pagePrev').disabled = currentPage === 1;
        byId('pageNext').disabled = currentPage === pages || filtered.length === 0;
        byId('pageStart').textContent = filtered.length ? String(start + 1) : '0';
        byId('pageEnd').textContent = String(Math.min(start + pageSize, filtered.length));
        byId('pageTotal').textContent = String(filtered.length);
    }

    function updateSummary() {
        const allRows = rows();
        const active = allRows.filter((row) => row.dataset.status === 'active').length;
        byId('totalServingSizeCount').textContent = String(allRows.length);
        byId('activeServingSizeCount').textContent = String(active);
        byId('inactiveServingSizeCount').textContent = String(allRows.length - active);
        byId('activeServingSizePercentage').textContent = allRows.length
            ? `${((active / allRows.length) * 100).toFixed(1)}% active` : 'No records yet';
    }

    function makeButton(className, title, iconClass) {
        const button = document.createElement('button');
        button.type = 'button'; button.className = className; button.title = title;
        button.setAttribute('aria-label', title);
        const icon = document.createElement('i'); icon.className = iconClass; button.appendChild(icon);
        return button;
    }

    function createRow(item) {
        const row = document.createElement('tr');
        const active = Boolean(item.active);
        Object.assign(row.dataset, {
            id: String(item.id), name: item.servingSizeName.toLowerCase(),
            description: item.description || '', multiplier: String(item.multiplier),
            status: active ? 'active' : 'inactive'
        });
        const nameCell = document.createElement('td');
        const name = document.createElement('span'); name.className = 'pill tag-green'; name.textContent = item.servingSizeName; nameCell.appendChild(name);
        const multiplierCell = document.createElement('td');
        const multiplier = document.createElement('strong'); multiplier.className = 'multiplier'; multiplier.textContent = String(item.multiplier); multiplierCell.appendChild(multiplier);
        const descriptionCell = document.createElement('td'); descriptionCell.textContent = item.description || '-';
        const statusCell = document.createElement('td');
        const badge = document.createElement('span'); badge.className = `status-badge ${active ? 'active-status' : 'inactive-status'}`; badge.textContent = active ? 'Active' : 'Inactive'; statusCell.appendChild(badge);
        const actionCell = document.createElement('td');
        const actions = document.createElement('div'); actions.className = 'action-group';
        actions.append(makeButton('icon-button small edit-serving', 'Edit serving size', 'bi bi-pencil-square'), makeButton('icon-button small danger delete-serving', 'Delete serving size', 'bi bi-trash'));
        actionCell.appendChild(actions);
        row.append(nameCell, multiplierCell, descriptionCell, statusCell, actionCell);
        return row;
    }

    function upsertRow(item) {
        rows().find((row) => row.dataset.id === String(item.id))?.remove();
        byId('emptyServingSizeRow')?.remove();
        const newRow = createRow(item);
        const next = rows().find((row) => row.dataset.name.localeCompare(newRow.dataset.name) > 0);
        if (next) rowsBox.insertBefore(newRow, next); else rowsBox.appendChild(newRow);
        updateSummary(); renderPage();
    }

    function removeRow(row) {
        row.remove();
        if (!rows().length) {
            const empty = document.createElement('tr'); empty.id = 'emptyServingSizeRow';
            const cell = document.createElement('td'); cell.colSpan = 5; cell.className = 'empty-state';
            cell.textContent = 'No serving sizes yet. Add one to make it available for meal selections.';
            empty.appendChild(cell); rowsBox.appendChild(empty);
        }
        updateSummary(); renderPage();
    }

    function showModal(row) {
        form.reset(); editingId = row?.dataset.id || null; formError.hidden = true;
        if (editingId) {
            form.elements.servingId.value = editingId;
            form.elements.servingSizeName.value = row.querySelector('.tag-green')?.textContent.trim() || '';
            form.elements.multiplier.value = row.dataset.multiplier || '';
            form.elements.description.value = row.dataset.description || '';
            form.elements.status.value = row.dataset.status || 'active';
            byId('servingModalTitle').textContent = 'Edit serving size';
            byId('servingModalDescription').textContent = 'Update this measurement everywhere it is used.';
            saveButton.textContent = 'Save changes';
        } else {
            form.elements.status.value = 'active';
            byId('servingModalTitle').textContent = 'Add serving size';
            byId('servingModalDescription').textContent = 'Define a reusable measurement multiplier.';
            saveButton.textContent = 'Save serving size';
        }
        modal.classList.add('show'); modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open'); form.elements.servingSizeName.focus();
    }

    function hideModal() {
        modal.classList.remove('show'); modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open'); editingId = null; form.reset();
    }

    async function save(event) {
        event.preventDefault();
        if (!form.checkValidity()) {
            const invalid = form.querySelector(':invalid');
            await alerts.error(invalid?.validationMessage || 'Complete all required fields.', 'Missing serving-size information');
            invalid?.focus(); return;
        }
        const data = new FormData(form);
        const payload = { servingSizeName: data.get('servingSizeName').trim(), multiplier: Number(data.get('multiplier')), description: data.get('description').trim(), active: data.get('status') === 'active' };
        const isEditing = Boolean(editingId); const label = saveButton.textContent;
        saveButton.disabled = true; saveButton.textContent = 'Saving...'; formError.hidden = true;
        try {
            const item = await request(isEditing ? `/admin/serving-sizes/${editingId}` : '/admin/serving-sizes', isEditing ? 'PUT' : 'POST', payload);
            upsertRow(item); hideModal();
            await alerts.success(isEditing ? 'Serving size updated' : 'Serving size added', `${payload.servingSizeName} has been ${isEditing ? 'updated' : 'added'} successfully.`);
        } catch (error) {
            formError.textContent = error.message; formError.hidden = false;
            await alerts.error(error.message || 'Unable to save this serving size.');
        } finally { saveButton.disabled = false; saveButton.textContent = label; }
    }

    async function remove(row, button) {
        const name = row.querySelector('.tag-green')?.textContent.trim() || 'this serving size';
        if (!await alerts.confirmDelete({ title: 'Delete serving size?', text: `${name} will be permanently removed.`, confirmButtonText: 'Yes, delete it!' })) return;
        button.disabled = true;
        try {
            await request(`/admin/serving-sizes/${row.dataset.id}`, 'DELETE'); removeRow(row);
            await alerts.success('Serving size deleted', `${name} has been deleted.`);
        } catch (error) { button.disabled = false; await alerts.error(error.message || 'Unable to delete this serving size.'); }
    }

    byId('openServingModal')?.addEventListener('click', () => showModal());
    byId('closeServingModal')?.addEventListener('click', hideModal);
    byId('cancelServingModal')?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => { if (event.target === modal) hideModal(); });
    form?.addEventListener('submit', save);
    searchInput?.addEventListener('input', () => { currentPage = 1; renderPage(); });
    statusFilter?.addEventListener('change', () => { currentPage = 1; renderPage(); });
    byId('clearServingFilter')?.addEventListener('click', () => { searchInput.value = ''; statusFilter.value = 'all'; currentPage = 1; renderPage(); });
    byId('pagePrev')?.addEventListener('click', () => { if (currentPage > 1) { currentPage -= 1; renderPage(); } });
    byId('pageNext')?.addEventListener('click', () => { if (currentPage < Math.ceil(filteredRows().length / pageSize)) { currentPage += 1; renderPage(); } });
    document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal?.classList.contains('show')) hideModal(); });
    document.addEventListener('click', (event) => {
        const edit = event.target.closest('.edit-serving');
        if (edit) { const row = edit.closest('tr[data-id]'); if (row) showModal(row); return; }
        const deleteButton = event.target.closest('.delete-serving');
        if (deleteButton) { const row = deleteButton.closest('tr[data-id]'); if (row) remove(row, deleteButton); }
    });
    byId('exportServingSizes')?.addEventListener('click', () => {
        const quote = (value) => `"${String(value || '').replaceAll('"', '""')}"`;
        const data = filteredRows().map((row) => [row.querySelector('.tag-green')?.textContent.trim(), row.dataset.multiplier, row.dataset.description, row.dataset.status]);
        const csv = [['Serving size', 'Multiplier', 'Description', 'Status'], ...data].map((line) => line.map(quote).join(',')).join('\r\n');
        const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })); link.download = 'nham-health-serving-sizes.csv'; link.click(); URL.revokeObjectURL(link.href);
    });

    updateSummary(); renderPage();
})();
