(() => {
    const searchInput = document.getElementById('nutrientSearch');
    const typeFilter = document.getElementById('typeFilter');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearNutrientFilter');
    const modal = document.getElementById('nutrientModal');
    const openModal = document.getElementById('openNutrientModal');
    const closeModal = document.getElementById('closeNutrientModal');
    const cancelModal = document.getElementById('cancelNutrientModal');
    const form = document.getElementById('nutrientForm');
    const title = document.getElementById('nutrientModalTitle');
    const description = document.getElementById('nutrientModalDescription');
    const saveButton = document.getElementById('saveNutrientButton');

    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (heading, text) => Promise.resolve(window.alert(text || heading)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    const getRows = () => Array.from(document.querySelectorAll('tbody tr[data-id]'));

    function applyFilters() {
        const keyword = (searchInput?.value || '').trim().toLowerCase();
        const type = (typeFilter?.value || 'all').toLowerCase();
        const status = (statusFilter?.value || 'all').toLowerCase();

        getRows().forEach((row) => {
            const name = (row.dataset.name || '').toLowerCase();
            const rowType = (row.dataset.type || '').toLowerCase();
            const rowStatus = (row.dataset.status || '').toLowerCase();
            row.hidden = !((!keyword || name.includes(keyword))
                && (type === 'all' || rowType === type)
                && (status === 'all' || rowStatus === status));
        });
    }

    function showModal(nutrient = null) {
        if (!modal || !form) return;
        const isEditing = Boolean(nutrient);
        form.reset();
        form.dataset.nutrientId = nutrient?.id || '';
        title.textContent = isEditing ? 'Edit Nutrient' : 'Add Nutrient';
        description.textContent = isEditing
            ? 'Update the nutrient information in the nutrition catalog.'
            : 'Enter nutrient information for the nutrition catalog.';
        saveButton.textContent = isEditing ? 'Save Changes' : 'Save Nutrient';

        if (isEditing) {
            form.elements.nutrientName.value = nutrient.name;
            form.elements.nutrientUnit.value = nutrient.unit;
            form.elements.nutrientType.value = nutrient.type;
            form.elements.nutrientStatus.value = nutrient.status;
            form.elements.nutrientDisplayOrder.value = nutrient.displayOrder;
        }

        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
        form.elements.nutrientName.focus();
    }

    function hideModal() {
        modal?.classList.remove('show');
        modal?.setAttribute('aria-hidden', 'true');
        form?.reset();
        if (form) form.dataset.nutrientId = '';
    }

    function csrfHeaders() {
        const token = document.querySelector('meta[name="_csrf"]')?.content;
        const header = document.querySelector('meta[name="_csrf_header"]')?.content;
        return token && header ? { [header]: token } : {};
    }

    async function readError(response, fallback = 'The nutrient request could not be completed.') {
        try {
            const body = await response.json();
            return body.message || fallback;
        } catch (_) {
            return fallback;
        }
    }

    async function saveNutrient(event) {
        event.preventDefault();
        if (!form.checkValidity()) {
            form.reportValidity();
            return;
        }

        const nutrientId = form.dataset.nutrientId;
        const payload = {
            nutrientName: form.elements.nutrientName.value.trim(),
            unit: form.elements.nutrientUnit.value.trim(),
            core: form.elements.nutrientType.value === 'macronutrient',
            active: form.elements.nutrientStatus.value === 'active',
            displayOrder: Number(form.elements.nutrientDisplayOrder.value)
        };

        saveButton.disabled = true;
        try {
            const response = await fetch(nutrientId ? `/admin/nutrients/${nutrientId}` : '/admin/nutrients', {
                method: nutrientId ? 'PUT' : 'POST',
                headers: { 'Content-Type': 'application/json', ...csrfHeaders() },
                body: JSON.stringify(payload)
            });
            if (!response.ok) throw new Error(await readError(response, 'The nutrient could not be saved.'));

            hideModal();
            await alerts.success(
                nutrientId ? 'Nutrient updated' : 'Nutrient added',
                `${payload.nutrientName} has been ${nutrientId ? 'updated' : 'added'} successfully.`
            );
            window.location.reload();
        } catch (error) {
            await alerts.error(error.message || 'The nutrient could not be saved.');
        } finally {
            saveButton.disabled = false;
        }
    }

    async function deleteNutrient(button) {
        const row = button.closest('tr[data-id]');
        if (!row) return;
        const nutrientName = row.dataset.name || 'this nutrient';
        const confirmed = await alerts.confirmDelete({
            title: 'Delete nutrient?',
            text: `${nutrientName} will be permanently removed.`,
            confirmButtonText: 'Yes, delete it!'
        });
        if (!confirmed) return;

        button.disabled = true;
        try {
            const response = await fetch(`/admin/nutrients/${row.dataset.id}`, {
                method: 'DELETE',
                headers: csrfHeaders()
            });
            if (!response.ok) throw new Error(await readError(response, 'The nutrient could not be deleted.'));

            await alerts.success('Nutrient deleted', `${nutrientName} has been deleted.`);
            window.location.reload();
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'The nutrient could not be deleted.');
        }
    }

    function exportNutrients() {
        const visibleRows = getRows().filter((row) => !row.hidden);
        const headings = ['Nutrient Name', 'Type', 'Unit', 'Display Order', 'Status'];
        const values = visibleRows.map((row) => [
            row.dataset.name,
            row.dataset.type === 'macronutrient' ? 'Macronutrient' : 'Micronutrient',
            row.dataset.unit,
            row.dataset.displayOrder,
            row.dataset.status === 'active' ? 'Active' : 'Inactive'
        ]);
        const escape = (value) => `"${String(value ?? '').replaceAll('"', '""')}"`;
        const csv = [headings, ...values].map((line) => line.map(escape).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nutrients.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    }

    searchInput?.addEventListener('input', applyFilters);
    typeFilter?.addEventListener('change', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearButton?.addEventListener('click', () => {
        searchInput.value = '';
        typeFilter.value = 'all';
        statusFilter.value = 'all';
        applyFilters();
    });
    openModal?.addEventListener('click', () => showModal());
    closeModal?.addEventListener('click', hideModal);
    cancelModal?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => {
        if (event.target === modal) hideModal();
    });
    form?.addEventListener('submit', saveNutrient);
    document.getElementById('exportNutrients')?.addEventListener('click', exportNutrients);
    document.addEventListener('click', (event) => {
        const editButton = event.target.closest('.edit-nutrient');
        if (editButton) {
            const row = editButton.closest('tr[data-id]');
            if (row) {
                showModal({
                    id: row.dataset.id,
                    name: row.dataset.name,
                    unit: row.dataset.unit,
                    type: row.dataset.type,
                    status: row.dataset.status,
                    displayOrder: row.dataset.displayOrder
                });
            }
            return;
        }

        const deleteButton = event.target.closest('.delete-nutrient');
        if (deleteButton) deleteNutrient(deleteButton);
    });
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') hideModal();
    });
})();
