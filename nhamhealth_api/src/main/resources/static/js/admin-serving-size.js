(() => {
    const modal = document.getElementById('servingModal');
    const form = document.getElementById('servingForm');
    const openButton = document.getElementById('openServingModal');
    const closeButton = document.getElementById('closeServingModal');
    const cancelButton = document.getElementById('cancelServingModal');
    const saveButton = document.getElementById('saveServingButton');
    const formError = document.getElementById('servingFormError');
    const modalTitle = document.getElementById('servingModalTitle');
    const modalDescription = document.getElementById('servingModalDescription');
    const searchInput = document.getElementById('servingSearch');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearServingFilter');
    const exportButton = document.getElementById('exportServingSizes');
    const pagePrev = document.getElementById('pagePrev');
    const pageNext = document.getElementById('pageNext');
    const pageNumbers = document.getElementById('pageNumbers');
    const pageStart = document.getElementById('pageStart');
    const pageEnd = document.getElementById('pageEnd');
    const pageTotal = document.getElementById('pageTotal');
    const rows = [...document.querySelectorAll('tbody tr[data-id]')];
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const pageSize = 10;
    let currentPage = 1;
    let editingId = null;

    const requestHeaders = (json = false) => ({
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
        ...(json ? { 'Content-Type': 'application/json' } : {})
    });
    const readBody = async response => (response.headers.get('content-type') || '').includes('application/json')
        ? response.json() : {};

    const filteredRows = () => {
        const query = searchInput?.value.trim().toLowerCase() || '';
        const status = statusFilter?.value || 'all';
        return rows.filter(row => {
            const matchesText = !query || row.dataset.name.includes(query)
                || (row.dataset.description || '').toLowerCase().includes(query);
            return matchesText && (status === 'all' || row.dataset.status === status);
        });
    };

    const renderPage = () => {
        const filtered = filteredRows();
        const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
        currentPage = Math.min(currentPage, totalPages);
        rows.forEach(row => { row.hidden = true; });
        const startIndex = (currentPage - 1) * pageSize;
        filtered.slice(startIndex, startIndex + pageSize).forEach(row => { row.hidden = false; });

        pageNumbers.innerHTML = '';
        for (let page = 1; page <= totalPages; page += 1) {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = `page-number${page === currentPage ? ' active' : ''}`;
            button.textContent = String(page);
            button.addEventListener('click', () => { currentPage = page; renderPage(); });
            pageNumbers.appendChild(button);
        }
        pagePrev.disabled = currentPage === 1;
        pageNext.disabled = currentPage === totalPages || filtered.length === 0;
        pageStart.textContent = filtered.length ? String(startIndex + 1) : '0';
        pageEnd.textContent = String(Math.min(startIndex + pageSize, filtered.length));
        pageTotal.textContent = String(filtered.length);
    };

    const showModal = row => {
        form.reset();
        editingId = row?.dataset.id || null;
        formError.hidden = true;
        if (editingId) {
            form.elements.servingId.value = editingId;
            form.elements.servingSizeName.value = row.querySelector('.tag-green')?.textContent.trim() || '';
            form.elements.multiplier.value = row.dataset.multiplier || '';
            form.elements.description.value = row.dataset.description || '';
            form.elements.status.value = row.dataset.status || 'active';
            modalTitle.textContent = 'Edit serving size';
            modalDescription.textContent = 'Update this measurement everywhere it is used.';
            saveButton.textContent = 'Save changes';
        } else {
            form.elements.servingId.value = '';
            form.elements.status.value = 'active';
            modalTitle.textContent = 'Add serving size';
            modalDescription.textContent = 'Define a reusable multiplier for meal logs.';
            saveButton.textContent = 'Save serving size';
        }
        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        form.elements.servingSizeName.focus();
    };
    const hideModal = () => {
        modal.classList.remove('show');
        modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        editingId = null;
    };

    openButton?.addEventListener('click', () => showModal());
    closeButton?.addEventListener('click', hideModal);
    cancelButton?.addEventListener('click', hideModal);
    modal?.addEventListener('click', event => { if (event.target === modal) hideModal(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape') hideModal(); });
    searchInput?.addEventListener('input', () => { currentPage = 1; renderPage(); });
    statusFilter?.addEventListener('change', () => { currentPage = 1; renderPage(); });
    clearButton?.addEventListener('click', () => {
        searchInput.value = '';
        statusFilter.value = 'all';
        currentPage = 1;
        renderPage();
    });
    pagePrev?.addEventListener('click', () => { if (currentPage > 1) { currentPage -= 1; renderPage(); } });
    pageNext?.addEventListener('click', () => {
        if (currentPage < Math.ceil(filteredRows().length / pageSize)) { currentPage += 1; renderPage(); }
    });

    document.querySelectorAll('.edit-serving').forEach(button =>
        button.addEventListener('click', () => showModal(button.closest('tr[data-id]'))));

    form?.addEventListener('submit', async event => {
        event.preventDefault();
        formError.hidden = true;
        saveButton.disabled = true;
        const originalLabel = saveButton.textContent;
        saveButton.textContent = 'Saving…';
        try {
            const data = new FormData(form);
            const payload = {
                servingSizeName: data.get('servingSizeName'),
                multiplier: Number(data.get('multiplier')),
                description: data.get('description'),
                active: data.get('status') === 'active'
            };
            const response = await fetch(editingId ? `/admin/serving-sizes/${editingId}` : '/admin/serving-sizes', {
                method: editingId ? 'PUT' : 'POST', headers: requestHeaders(true), body: JSON.stringify(payload)
            });
            const body = await readBody(response);
            if (!response.ok) throw new Error(body.message || 'Unable to save this serving size.');
            window.location.reload();
        } catch (error) {
            formError.textContent = error.message;
            formError.hidden = false;
        } finally {
            saveButton.disabled = false;
            saveButton.textContent = originalLabel;
        }
    });

    document.querySelectorAll('.delete-serving').forEach(button => button.addEventListener('click', async () => {
        const row = button.closest('tr[data-id]');
        const name = row?.querySelector('.tag-green')?.textContent.trim() || 'this serving size';
        if (!row || !window.confirm(`Delete ${name}?`)) return;
        const response = await fetch(`/admin/serving-sizes/${row.dataset.id}`, { method: 'DELETE', headers: requestHeaders() });
        const body = await readBody(response);
        if (!response.ok) { window.alert(body.message || 'Unable to delete this serving size.'); return; }
        window.location.reload();
    }));

    exportButton?.addEventListener('click', () => {
        const quote = value => `"${String(value || '').replaceAll('"', '""')}"`;
        const records = filteredRows().map(row => [
            row.querySelector('.tag-green')?.textContent.trim(), row.dataset.multiplier,
            row.dataset.description, row.dataset.status
        ]);
        const csv = [['Serving size', 'Multiplier', 'Description', 'Status'], ...records]
            .map(columns => columns.map(quote).join(',')).join('\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-serving-sizes.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });

    renderPage();
})();
