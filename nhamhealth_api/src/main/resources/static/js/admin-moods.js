(() => {
    const searchInput = document.getElementById('moodSearch');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearMoodFilter');
    const exportButton = document.getElementById('exportMoods');
    const visibleCount = document.getElementById('visibleMoodCount');
    const modal = document.getElementById('moodModal');
    const form = document.getElementById('moodForm');
    const openButton = document.getElementById('openMoodModal');
    const closeButton = document.getElementById('closeMoodModal');
    const cancelButton = document.getElementById('cancelMoodModal');
    const saveButton = document.getElementById('saveMoodButton');
    const formError = document.getElementById('moodFormError');
    const modalTitle = document.getElementById('moodModalTitle');
    const modalDescription = document.getElementById('moodModalDescription');
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
        const query = searchInput?.value.trim().toLowerCase() || '';
        const status = statusFilter?.value || 'all';
        let count = 0;
        rows.forEach(row => {
            const show = (!query || row.dataset.name.includes(query))
                && (status === 'all' || row.dataset.status === status);
            row.hidden = !show;
            if (show) count += 1;
        });
        if (visibleCount) visibleCount.textContent = String(count);
    };

    const showModal = row => {
        form.reset();
        editingId = row?.dataset.id || null;
        formError.hidden = true;
        if (editingId) {
            form.elements.moodId.value = editingId;
            form.elements.moodName.value = row.querySelector('.mood-name strong')?.textContent.trim() || '';
            form.elements.emojiCode.value = row.dataset.emoji || '';
            form.elements.status.value = row.dataset.status || 'active';
            modalTitle.textContent = 'Edit mood';
            modalDescription.textContent = 'Update this mood everywhere it is referenced.';
            saveButton.textContent = 'Save changes';
        } else {
            form.elements.moodId.value = '';
            form.elements.status.value = 'active';
            modalTitle.textContent = 'Add mood';
            modalDescription.textContent = 'Create an emotion option for wellness tracking.';
            saveButton.textContent = 'Save mood';
        }
        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        form.elements.moodName.focus();
    };
    const hideModal = () => {
        modal.classList.remove('show');
        modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        editingId = null;
    };

    searchInput?.addEventListener('input', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearButton?.addEventListener('click', () => {
        searchInput.value = '';
        statusFilter.value = 'all';
        applyFilters();
    });
    openButton?.addEventListener('click', () => showModal());
    closeButton?.addEventListener('click', hideModal);
    cancelButton?.addEventListener('click', hideModal);
    modal?.addEventListener('click', event => { if (event.target === modal) hideModal(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape') hideModal(); });
    document.querySelectorAll('.edit-mood').forEach(button =>
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
                moodName: data.get('moodName'),
                emojiCode: data.get('emojiCode'),
                active: data.get('status') === 'active'
            };
            const response = await fetch(editingId ? `/admin/moods/${editingId}` : '/admin/moods', {
                method: editingId ? 'PUT' : 'POST', headers: requestHeaders(true), body: JSON.stringify(payload)
            });
            const body = await readBody(response);
            if (!response.ok) throw new Error(body.message || 'Unable to save this mood.');
            window.location.reload();
        } catch (error) {
            formError.textContent = error.message;
            formError.hidden = false;
        } finally {
            saveButton.disabled = false;
            saveButton.textContent = originalLabel;
        }
    });

    document.querySelectorAll('.delete-mood').forEach(button => button.addEventListener('click', async () => {
        const row = button.closest('tr[data-id]');
        const name = row?.querySelector('.mood-name strong')?.textContent.trim() || 'this mood';
        if (!row || !window.confirm(`Delete ${name}?`)) return;
        const response = await fetch(`/admin/moods/${row.dataset.id}`, { method: 'DELETE', headers: requestHeaders() });
        const body = await readBody(response);
        if (!response.ok) { window.alert(body.message || 'Unable to delete this mood.'); return; }
        window.location.reload();
    }));

    exportButton?.addEventListener('click', () => {
        const quote = value => `"${String(value || '').replaceAll('"', '""')}"`;
        const records = rows.filter(row => !row.hidden).map(row => [
            row.querySelector('.mood-name strong')?.textContent.trim(), row.dataset.emoji, row.dataset.status
        ]);
        const csv = [['Mood name', 'Emoji', 'Status'], ...records]
            .map(columns => columns.map(quote).join(',')).join('\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-moods.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });

    applyFilters();
})();
