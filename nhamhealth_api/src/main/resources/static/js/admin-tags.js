(() => {
    const searchInput = document.getElementById('tagSearch');
    const scopeFilter = document.getElementById('scopeFilter');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearTagFilter');
    const exportButton = document.getElementById('exportTags');
    const visibleCount = document.getElementById('visibleTagCount');
    const rowsBox = document.getElementById('tagRows');
    const totalTagCount = document.getElementById('totalTagCount');
    const activeTagCount = document.getElementById('activeTagCount');
    const inactiveTagCount = document.getElementById('inactiveTagCount');
    const activeTagPercentage = document.getElementById('activeTagPercentage');
    const modal = document.getElementById('tagModal');
    const openButton = document.getElementById('openTagModal');
    const closeButton = document.getElementById('closeTagModal');
    const cancelButton = document.getElementById('cancelTagModal');
    const form = document.getElementById('tagForm');
    const formError = document.getElementById('tagFormError');
    const saveButton = document.getElementById('saveTagButton');
    const modalTitle = document.getElementById('tagModalTitle');
    const modalDescription = document.getElementById('tagModalDescription');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    let editingId = null;

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const requestHeaders = (json = false) => ({
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
        ...(json ? { 'Content-Type': 'application/json' } : {}),
        Accept: 'application/json'
    });

    async function readBody(response) {
        return (response.headers.get('content-type') || '').includes('json')
            ? response.json()
            : {};
    }

    function applyFilters() {
        const keyword = searchInput?.value.trim().toLowerCase() || '';
        const scope = scopeFilter?.value.toLowerCase() || 'all';
        const status = statusFilter?.value.toLowerCase() || 'all';
        let count = 0;
        rows().forEach((row) => {
            const matchesKeyword = !keyword || row.dataset.name.includes(keyword)
                || (row.dataset.description || '').toLowerCase().includes(keyword);
            const show = matchesKeyword
                && (scope === 'all' || row.dataset.scope === scope)
                && (status === 'all' || row.dataset.status === status);
            row.hidden = !show;
            if (show) count += 1;
        });
        if (visibleCount) visibleCount.textContent = String(count);
    }

    function createActionButton(className, title, iconClass) {
        const button = document.createElement('button');
        button.className = className;
        button.type = 'button';
        button.title = title;
        button.setAttribute('aria-label', title);
        const icon = document.createElement('i');
        icon.className = iconClass;
        button.appendChild(icon);
        return button;
    }

    function createTagRow(tag) {
        const row = document.createElement('tr');
        const scope = String(tag.tagScope).toLowerCase();
        const isActive = Boolean(tag.active);
        row.dataset.id = String(tag.id);
        row.dataset.name = tag.tagName.toLowerCase();
        row.dataset.scope = scope;
        row.dataset.description = tag.description || '';
        row.dataset.status = isActive ? 'active' : 'inactive';

        const nameCell = document.createElement('td');
        const namePill = document.createElement('span');
        namePill.className = 'pill tag-pink';
        namePill.textContent = tag.tagName;
        nameCell.appendChild(namePill);

        const scopeCell = document.createElement('td');
        const scopePill = document.createElement('span');
        scopePill.className = 'pill tag-blue';
        scopePill.textContent = scope;
        scopeCell.appendChild(scopePill);

        const descriptionCell = document.createElement('td');
        descriptionCell.textContent = tag.description || '-';

        const statusCell = document.createElement('td');
        const statusBadge = document.createElement('span');
        statusBadge.className = `status-badge ${isActive ? 'active-status' : 'inactive-status'}`;
        statusBadge.textContent = isActive ? 'Active' : 'Inactive';
        statusCell.appendChild(statusBadge);

        const actionsCell = document.createElement('td');
        const actions = document.createElement('div');
        actions.className = 'action-group';
        actions.append(
            createActionButton('icon-button small edit-tag', 'Edit tag', 'bi bi-pencil-square'),
            createActionButton('icon-button small danger delete-tag', 'Delete tag', 'bi bi-trash')
        );
        actionsCell.appendChild(actions);
        row.append(nameCell, scopeCell, descriptionCell, statusCell, actionsCell);
        return row;
    }

    function updateTagSummary() {
        const tagRows = rows();
        const activeCount = tagRows.filter((row) => row.dataset.status === 'active').length;
        const inactiveCount = tagRows.length - activeCount;
        if (totalTagCount) totalTagCount.textContent = String(tagRows.length);
        if (activeTagCount) activeTagCount.textContent = String(activeCount);
        if (inactiveTagCount) inactiveTagCount.textContent = String(inactiveCount);
        if (activeTagPercentage) {
            activeTagPercentage.textContent = tagRows.length
                ? `${((activeCount / tagRows.length) * 100).toFixed(1)}% active`
                : 'No tags yet';
        }
    }

    function upsertTag(tag) {
        const existingRow = rows().find((row) => row.dataset.id === String(tag.id));
        existingRow?.remove();
        document.getElementById('emptyTagRow')?.remove();
        const newRow = createTagRow(tag);
        const nextRow = rows().find((row) => row.dataset.name.localeCompare(newRow.dataset.name) > 0);
        if (nextRow) rowsBox.insertBefore(newRow, nextRow);
        else rowsBox.appendChild(newRow);
        updateTagSummary();
        applyFilters();
    }

    function removeTag(row) {
        row.remove();
        if (!rows().length) {
            const emptyRow = document.createElement('tr');
            emptyRow.id = 'emptyTagRow';
            const cell = document.createElement('td');
            cell.colSpan = 5;
            cell.className = 'empty-state';
            cell.textContent = 'No tags yet. Add a tag to organize meals and community content.';
            emptyRow.appendChild(cell);
            rowsBox.appendChild(emptyRow);
        }
        updateTagSummary();
        applyFilters();
    }

    function showModal(row) {
        form.reset();
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

        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        form.elements.tagName.focus();
    }

    function hideModal() {
        modal.classList.remove('show');
        modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        editingId = null;
        form.reset();
    }

    async function request(url, method, payload) {
        const response = await fetch(url, {
            method,
            headers: requestHeaders(Boolean(payload)),
            credentials: 'same-origin',
            body: payload ? JSON.stringify(payload) : undefined
        });
        const body = await readBody(response);
        if (!response.ok) {
            const fieldError = Array.isArray(body.errors) ? body.errors[0]?.defaultMessage : null;
            throw new Error(body.message || body.detail || fieldError || body.title || 'Unable to save this tag.');
        }
        return body;
    }

    async function saveTag(event) {
        event.preventDefault();
        if (!form.checkValidity()) {
            const invalidField = form.querySelector(':invalid');
            await alerts.error(
                invalidField?.validationMessage || 'Complete all required tag fields before saving.',
                'Missing tag information'
            );
            invalidField?.focus();
            return;
        }

        if (formError) formError.hidden = true;
        const data = new FormData(form);
        const payload = {
            tagName: data.get('tagName').trim(),
            tagScope: data.get('tagScope'),
            description: data.get('description').trim(),
            active: data.get('status') === 'active'
        };
        const isEditing = Boolean(editingId);
        const originalLabel = saveButton.textContent;
        saveButton.disabled = true;
        saveButton.textContent = 'Saving…';

        try {
            const savedTag = await request(
                isEditing ? `/admin/tags/${editingId}` : '/admin/tags',
                isEditing ? 'PUT' : 'POST',
                payload
            );
            upsertTag(savedTag);
            hideModal();
            await alerts.success(
                isEditing ? 'Tag updated' : 'Tag added',
                `${payload.tagName} has been ${isEditing ? 'updated' : 'added'} successfully.`
            );
        } catch (error) {
            if (formError) {
                formError.textContent = error.message;
                formError.hidden = false;
            }
            await alerts.error(error.message || 'Unable to save this tag.');
        } finally {
            saveButton.disabled = false;
            saveButton.textContent = originalLabel;
        }
    }

    async function deleteTag(row, button) {
        const name = row.querySelector('.tag-pink')?.textContent.trim() || 'this tag';
        const confirmed = await alerts.confirmDelete({
            title: 'Delete tag?',
            text: `${name} will be permanently removed.`,
            confirmButtonText: 'Yes, delete it!'
        });
        if (!confirmed) return;

        button.disabled = true;
        try {
            await request(`/admin/tags/${row.dataset.id}`, 'DELETE');
            removeTag(row);
            await alerts.success('Tag deleted', `${name} has been deleted.`);
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'Unable to delete this tag.');
        }
    }

    function exportTags() {
        const quote = (value) => `"${String(value || '').replaceAll('"', '""')}"`;
        const records = rows().filter((row) => !row.hidden).map((row) => [
            row.querySelector('.tag-pink')?.textContent.trim(),
            row.dataset.scope,
            row.dataset.description,
            row.dataset.status
        ]);
        const csv = [['Tag name', 'Type', 'Description', 'Status'], ...records]
            .map((columns) => columns.map(quote).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-tags.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    }

    [searchInput, scopeFilter, statusFilter].filter(Boolean).forEach((control) =>
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
    form?.addEventListener('submit', saveTag);
    modal?.addEventListener('click', (event) => { if (event.target === modal) hideModal(); });
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && modal?.classList.contains('show')) hideModal();
    });
    document.addEventListener('click', (event) => {
        const editButton = event.target.closest('.edit-tag');
        if (editButton) {
            const row = editButton.closest('tr[data-id]');
            if (row) showModal(row);
            return;
        }
        const deleteButton = event.target.closest('.delete-tag');
        if (deleteButton) {
            const row = deleteButton.closest('tr[data-id]');
            if (row) deleteTag(row, deleteButton);
        }
    });
    exportButton?.addEventListener('click', exportTags);

    applyFilters();
})();
