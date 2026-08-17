(() => {
    const byId = (id) => document.getElementById(id);
    const searchInput = byId('moodSearch');
    const statusFilter = byId('statusFilter');
    const visibleCount = byId('visibleMoodCount');
    const rowsBox = byId('moodRows');
    const modal = byId('moodModal');
    const form = byId('moodForm');
    const saveButton = byId('saveMoodButton');
    const formError = byId('moodFormError');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    let editingId = null;

    const emojiPresets = () => [...document.querySelectorAll('[data-mood-preset]')];

    function updateEmojiPresetSelection() {
        const selectedEmoji = form?.elements.emojiCode?.value.trim() || '';
        emojiPresets().forEach((preset) => {
            const selected = preset.dataset.emoji === selectedEmoji;
            preset.classList.toggle('selected', selected);
            preset.setAttribute('aria-pressed', String(selected));
        });
    }

    function chooseEmojiPreset(preset) {
        if (!form) return;
        form.elements.emojiCode.value = preset.dataset.emoji || '';
        if (!form.elements.moodName.value.trim()) {
            form.elements.moodName.value = preset.dataset.name || '';
        }
        updateEmojiPresetSelection();
        form.elements.moodName.focus();
    }

    function setEmojiFromMoodName() {
        if (!form || form.elements.emojiCode.value.trim()) return;
        const moodName = form.elements.moodName.value.trim().toLocaleLowerCase();
        const matchingPreset = emojiPresets().find(
            (preset) => preset.dataset.name.toLocaleLowerCase() === moodName
        );
        if (!matchingPreset) return;
        form.elements.emojiCode.value = matchingPreset.dataset.emoji || '';
        updateEmojiPresetSelection();
    }

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const headers = (json = false) => ({
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
        ...(json ? { 'Content-Type': 'application/json' } : {}),
        Accept: 'application/json'
    });

    async function request(url, method, payload) {
        const response = await fetch(url, {
            method,
            headers: headers(Boolean(payload)),
            credentials: 'same-origin',
            body: payload ? JSON.stringify(payload) : undefined
        });
        const body = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) {
            const validationMessage = Array.isArray(body.errors) ? body.errors[0]?.defaultMessage : null;
            throw new Error(body.message || body.detail || validationMessage || body.title || 'Unable to complete this request.');
        }
        return body;
    }

    function applyFilters() {
        const query = searchInput?.value.trim().toLowerCase() || '';
        const status = statusFilter?.value || 'all';
        let count = 0;
        rows().forEach((row) => {
            const show = (!query || row.dataset.name.includes(query) || (row.dataset.emoji || '').includes(query))
                && (status === 'all' || row.dataset.status === status);
            row.hidden = !show;
            if (show) count += 1;
        });
        visibleCount.textContent = String(count);
    }

    function updateSummary() {
        const allRows = rows();
        const active = allRows.filter((row) => row.dataset.status === 'active').length;
        byId('totalMoodCount').textContent = String(allRows.length);
        byId('activeMoodCount').textContent = String(active);
        byId('inactiveMoodCount').textContent = String(allRows.length - active);
        byId('activeMoodPercentage').textContent = allRows.length
            ? `${((active / allRows.length) * 100).toFixed(1)}% active`
            : 'No moods yet';
    }

    function makeButton(className, title, iconClass) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = className;
        button.title = title;
        button.setAttribute('aria-label', title);
        const icon = document.createElement('i');
        icon.className = iconClass;
        button.appendChild(icon);
        return button;
    }

    function createRow(item) {
        const row = document.createElement('tr');
        const active = Boolean(item.active);
        Object.assign(row.dataset, {
            id: String(item.id),
            name: item.moodName.toLowerCase(),
            emoji: item.emojiCode || '',
            status: active ? 'active' : 'inactive'
        });

        const nameCell = document.createElement('td');
        const nameBox = document.createElement('div');
        nameBox.className = 'mood-name';
        const avatar = document.createElement('span');
        avatar.className = 'mood-avatar';
        avatar.textContent = item.emojiCode || '•';
        const name = document.createElement('strong');
        name.textContent = item.moodName;
        nameBox.append(avatar, name);
        nameCell.appendChild(nameBox);

        const emojiCell = document.createElement('td');
        const emoji = document.createElement('span');
        emoji.className = 'emoji-code';
        emoji.textContent = item.emojiCode || '—';
        emojiCell.appendChild(emoji);

        const statusCell = document.createElement('td');
        const badge = document.createElement('span');
        badge.className = `status-badge ${active ? 'active-status' : 'inactive-status'}`;
        badge.textContent = active ? 'Active' : 'Inactive';
        statusCell.appendChild(badge);

        const actionCell = document.createElement('td');
        const actions = document.createElement('div');
        actions.className = 'action-group';
        actions.append(
            makeButton('icon-button small edit-mood', 'Edit mood', 'bi bi-pencil-square'),
            makeButton('icon-button small danger delete-mood', 'Delete mood', 'bi bi-trash')
        );
        actionCell.appendChild(actions);
        row.append(nameCell, emojiCell, statusCell, actionCell);
        return row;
    }

    function upsertRow(item) {
        rows().find((row) => row.dataset.id === String(item.id))?.remove();
        byId('emptyMoodRow')?.remove();
        const newRow = createRow(item);
        const next = rows().find((row) => row.dataset.name.localeCompare(newRow.dataset.name) > 0);
        if (next) rowsBox.insertBefore(newRow, next);
        else rowsBox.appendChild(newRow);
        updateSummary();
        applyFilters();
    }

    function removeRow(row) {
        row.remove();
        if (!rows().length) {
            const empty = document.createElement('tr');
            empty.id = 'emptyMoodRow';
            const cell = document.createElement('td');
            cell.colSpan = 4;
            cell.className = 'empty-state';
            cell.textContent = 'No moods yet. Add a mood for wellness tracking and AI recommendations.';
            empty.appendChild(cell);
            rowsBox.appendChild(empty);
        }
        updateSummary();
        applyFilters();
    }

    function showModal(row) {
        form.reset();
        editingId = row?.dataset.id || null;
        formError.hidden = true;
        if (editingId) {
            form.elements.moodId.value = editingId;
            form.elements.moodName.value = row.querySelector('.mood-name strong')?.textContent.trim() || '';
            form.elements.emojiCode.value = row.dataset.emoji || '';
            form.elements.status.value = row.dataset.status || 'active';
            byId('moodModalTitle').textContent = 'Edit mood';
            byId('moodModalDescription').textContent = 'Update this mood everywhere it is referenced.';
            saveButton.textContent = 'Save changes';
        } else {
            form.elements.status.value = 'active';
            byId('moodModalTitle').textContent = 'Add mood';
            byId('moodModalDescription').textContent = 'Create an emotion option for wellness tracking.';
            saveButton.textContent = 'Save mood';
        }
        updateEmojiPresetSelection();
        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        form.elements.moodName.focus();
    }

    function hideModal() {
        modal.classList.remove('show');
        modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        editingId = null;
        form.reset();
        updateEmojiPresetSelection();
    }

    async function saveMood(event) {
        event.preventDefault();
        if (!form.checkValidity()) {
            const invalid = form.querySelector(':invalid');
            await alerts.error(invalid?.validationMessage || 'Complete all required fields.', 'Missing mood information');
            invalid?.focus();
            return;
        }
        const data = new FormData(form);
        const payload = {
            moodName: data.get('moodName').trim(),
            emojiCode: data.get('emojiCode').trim(),
            active: data.get('status') === 'active'
        };
        const isEditing = Boolean(editingId);
        const originalLabel = saveButton.textContent;
        saveButton.disabled = true;
        saveButton.textContent = 'Saving...';
        formError.hidden = true;
        try {
            const item = await request(isEditing ? `/admin/moods/${editingId}` : '/admin/moods', isEditing ? 'PUT' : 'POST', payload);
            upsertRow(item);
            hideModal();
            await alerts.success(isEditing ? 'Mood updated' : 'Mood added', `${payload.moodName} has been ${isEditing ? 'updated' : 'added'} successfully.`);
        } catch (error) {
            formError.textContent = error.message;
            formError.hidden = false;
            await alerts.error(error.message || 'Unable to save this mood.');
        } finally {
            saveButton.disabled = false;
            saveButton.textContent = originalLabel;
        }
    }

    async function deleteMood(row, button) {
        const name = row.querySelector('.mood-name strong')?.textContent.trim() || 'this mood';
        const confirmed = await alerts.confirmDelete({
            title: 'Delete mood?',
            text: `${name} will be permanently removed.`,
            confirmButtonText: 'Yes, delete it!'
        });
        if (!confirmed) return;
        button.disabled = true;
        try {
            await request(`/admin/moods/${row.dataset.id}`, 'DELETE');
            removeRow(row);
            await alerts.success('Mood deleted', `${name} has been deleted.`);
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'Unable to delete this mood.');
        }
    }

    searchInput?.addEventListener('input', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    byId('clearMoodFilter')?.addEventListener('click', () => {
        searchInput.value = '';
        statusFilter.value = 'all';
        applyFilters();
    });
    byId('openMoodModal')?.addEventListener('click', () => showModal());
    byId('closeMoodModal')?.addEventListener('click', hideModal);
    byId('cancelMoodModal')?.addEventListener('click', hideModal);
    form?.elements.moodName?.addEventListener('change', setEmojiFromMoodName);
    form?.elements.moodName?.addEventListener('blur', setEmojiFromMoodName);
    form?.elements.emojiCode?.addEventListener('input', updateEmojiPresetSelection);
    document.addEventListener('click', (event) => {
        const preset = event.target.closest('[data-mood-preset]');
        if (preset) chooseEmojiPreset(preset);
    });
    modal?.addEventListener('click', (event) => { if (event.target === modal) hideModal(); });
    form?.addEventListener('submit', saveMood);
    document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal?.classList.contains('show')) hideModal(); });
    document.addEventListener('click', (event) => {
        const edit = event.target.closest('.edit-mood');
        if (edit) {
            const row = edit.closest('tr[data-id]');
            if (row) showModal(row);
            return;
        }
        const remove = event.target.closest('.delete-mood');
        if (remove) {
            const row = remove.closest('tr[data-id]');
            if (row) deleteMood(row, remove);
        }
    });
    byId('exportMoods')?.addEventListener('click', () => {
        const quote = (value) => `"${String(value || '').replaceAll('"', '""')}"`;
        const records = rows().filter((row) => !row.hidden).map((row) => [
            row.querySelector('.mood-name strong')?.textContent.trim(), row.dataset.emoji, row.dataset.status
        ]);
        const csv = [['Mood name', 'Emoji', 'Status'], ...records]
            .map((columns) => columns.map(quote).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-moods.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });

    updateSummary();
    applyFilters();
})();
