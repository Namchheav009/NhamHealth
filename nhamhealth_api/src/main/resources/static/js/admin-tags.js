(() => {
    const searchInput = document.getElementById('tagSearch');
    const scopeFilter = document.getElementById('scopeFilter');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearTagFilter');
    const exportButton = document.getElementById('exportTags');
    const visibleCount = document.getElementById('visibleTagCount');
    const modal = document.getElementById('tagModal');
    const openButton = document.getElementById('openTagModal');
    const closeButton = document.getElementById('closeTagModal');
    const cancelButton = document.getElementById('cancelTagModal');
    const form = document.getElementById('tagForm');
    const formError = document.getElementById('tagFormError');
    const saveButton = document.getElementById('saveTagButton');
    const modalTitle = document.getElementById('tagModalTitle');
    const modalDescription = document.getElementById('tagModalDescription');
    const rows = [...document.querySelectorAll('tbody tr[data-id]')];
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    let editingId = null;

    const requestHeaders = (json = false) => ({
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
        ...(json ? { 'Content-Type': 'application/json' } : {})
    });
    const readBody = async response => (response.headers.get('content-type') || '').includes('application/json')
        ? response.json() : {};

    const applyFilters = () => {
        const keyword = searchInput?.value.trim().toLowerCase() || '';
        const scope = scopeFilter?.value.toLowerCase() || 'all';
        const status = statusFilter?.value.toLowerCase() || 'all';
        let count = 0;
        rows.forEach(row => {
            const matchesKeyword = !keyword || row.dataset.name.includes(keyword)
                || (row.dataset.description || '').toLowerCase().includes(keyword);
            const show = matchesKeyword
                && (scope === 'all' || row.dataset.scope === scope)
                && (status === 'all' || row.dataset.status === status);
            row.hidden = !show;
            if (show) count += 1;
        });
        if (visibleCount) visibleCount.textContent = String(count);
    };

    const showModal = row => {
        form?.reset();
        editingId = row?.dataset.id || null;
        if (formError) formError.hidden = true;
        if (editingId) {
            form.elements.tagId.value = editingId;
            form.elements.tagName.value = row.querySelector('.tag-pink')?.textContent.trim() || '';
            form.elements.tagScope.value = (row.dataset.scope || '').toUpperCase();
            form.elements.description.value = row.dataset.description || '';
            form.elements.status.value = row.dataset.status || 'active';
            modalTitle.textContent = 'Edit tag';
            modalDescription.textContent = 'Update this tag everywhere it is used.';
            saveButton.textContent = 'Save changes';
        } else {
            form.elements.tagId.value = '';
            form.elements.status.value = 'active';
            modalTitle.textContent = 'Add tag';
            modalDescription.textContent = 'Create a reusable tag for meals and posts.';
            saveButton.textContent = 'Save tag';
        }
        modal?.classList.add('show');
        modal?.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        form?.elements.tagName.focus();
    };

    const hideModal = () => {
        modal?.classList.remove('show');
        modal?.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        editingId = null;
    };

    [searchInput, scopeFilter, statusFilter].filter(Boolean).forEach(control =>
        control.addEventListener(control === searchInput ? 'input' : 'change', applyFilters));
    clearButton?.addEventListener('click', () => {
        searchInput.value = '';
        scopeFilter.value = 'all';
        statusFilter.value = 'all';
        applyFilters();
    });
    openButton?.addEventListener('click', () => showModal());
    closeButton?.addEventListener('click', hideModal);
    cancelButton?.addEventListener('click', hideModal);
    modal?.addEventListener('click', event => { if (event.target === modal) hideModal(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape') hideModal(); });

    document.querySelectorAll('.edit-tag').forEach(button =>
        button.addEventListener('click', () => showModal(button.closest('tr[data-id]'))));

    form?.addEventListener('submit', async event => {
        event.preventDefault();
        if (formError) formError.hidden = true;
        saveButton.disabled = true;
        const originalLabel = saveButton.textContent;
        saveButton.textContent = 'Saving…';
        try {
            const data = new FormData(form);
            const payload = {
                tagName: data.get('tagName'),
                tagScope: data.get('tagScope'),
                description: data.get('description'),
                active: data.get('status') === 'active'
            };
            const response = await fetch(editingId ? `/admin/tags/${editingId}` : '/admin/tags', {
                method: editingId ? 'PUT' : 'POST',
                headers: requestHeaders(true),
                body: JSON.stringify(payload)
            });
            const body = await readBody(response);
            if (!response.ok) throw new Error(body.message || 'Unable to save this tag.');
            window.location.reload();
        } catch (error) {
            if (formError) { formError.textContent = error.message; formError.hidden = false; }
        } finally {
            saveButton.disabled = false;
            saveButton.textContent = originalLabel;
        }
    });

    document.querySelectorAll('.delete-tag').forEach(button => button.addEventListener('click', async () => {
        const row = button.closest('tr[data-id]');
        const name = row?.querySelector('.tag-pink')?.textContent.trim() || 'this tag';
        if (!row || !window.confirm(`Delete ${name}?`)) return;
        const response = await fetch(`/admin/tags/${row.dataset.id}`, { method: 'DELETE', headers: requestHeaders() });
        const body = await readBody(response);
        if (!response.ok) { window.alert(body.message || 'Unable to delete this tag.'); return; }
        window.location.reload();
    }));

    exportButton?.addEventListener('click', () => {
        const quote = value => `"${String(value || '').replaceAll('"', '""')}"`;
        const records = rows.filter(row => !row.hidden).map(row => [
            row.querySelector('.tag-pink')?.textContent.trim(),
            row.dataset.scope,
            row.dataset.description,
            row.dataset.status
        ]);
        const csv = [['Tag name', 'Type', 'Description', 'Status'], ...records]
            .map(columns => columns.map(quote).join(',')).join('\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-tags.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });

    applyFilters();
})();
