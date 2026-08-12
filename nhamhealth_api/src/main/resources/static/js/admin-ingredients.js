(() => {
    const searchInput = document.getElementById('ingredientSearch');
    const typeFilter = document.getElementById('categoryFilter');
    const clearButton = document.getElementById('clearIngredientFilter');
    const rowsBox = document.getElementById('ingredientRows');
    const modal = document.getElementById('ingredientModal');
    const form = document.getElementById('ingredientForm');
    const imageFile = document.getElementById('ingredientImageFile');
    const imageHelp = document.getElementById('ingredientImageHelp');
    const saveButton = document.getElementById('saveIngredientButton');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    let editingIngredientId = null;
    let currentImageUrl = null;

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const csrfHeaders = () => csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {};

    function populateTypes() {
        const types = [...new Set(rows().map((row) => row.dataset.type).filter(Boolean))]
            .sort((a, b) => a.localeCompare(b));
        const selected = typeFilter.value;
        typeFilter.replaceChildren(new Option('All Types', 'all'));
        const datalist = document.getElementById('ingredientTypes');
        datalist.replaceChildren();
        types.forEach((type) => {
            typeFilter.add(new Option(type, type.toLowerCase()));
            datalist.appendChild(new Option(type));
        });
        typeFilter.value = [...typeFilter.options].some((option) => option.value === selected) ? selected : 'all';
    }

    function applyFilters() {
        const keyword = searchInput.value.trim().toLowerCase();
        const type = typeFilter.value;
        rows().forEach((row) => {
            const matchesName = !keyword || row.dataset.name.toLowerCase().includes(keyword);
            const matchesType = type === 'all' || (row.dataset.type || '').toLowerCase() === type;
            row.hidden = !(matchesName && matchesType);
        });
    }

    function setModalOpen(isOpen) {
        modal.classList.toggle('show', isOpen);
        modal.setAttribute('aria-hidden', String(!isOpen));
    }

    function openCreateModal() {
        editingIngredientId = null;
        currentImageUrl = null;
        form.reset();
        imageFile.required = false;
        imageHelp.textContent = 'Optional. JPG, PNG, or WebP; maximum 5 MB.';
        document.getElementById('ingredientModalTitle').textContent = 'Add Ingredient';
        document.getElementById('ingredientModalText').textContent = 'Enter ingredient information for your catalog.';
        saveButton.textContent = 'Save Ingredient';
        setModalOpen(true);
        form.elements.ingredientName.focus();
    }

    function openEditModal(row) {
        editingIngredientId = row.dataset.id;
        currentImageUrl = row.dataset.imageUrl || null;
        form.reset();
        form.elements.ingredientName.value = row.dataset.name;
        form.elements.ingredientType.value = row.dataset.type || '';
        form.elements.defaultUnit.value = row.dataset.unit || '';
        form.elements.description.value = row.dataset.description || '';
        imageFile.required = false;
        imageHelp.textContent = 'Leave empty to keep the current image. JPG, PNG, or WebP; maximum 5 MB.';
        document.getElementById('ingredientModalTitle').textContent = 'Edit Ingredient';
        document.getElementById('ingredientModalText').textContent = 'Update this ingredient in the catalog.';
        saveButton.textContent = 'Save Changes';
        setModalOpen(true);
        form.elements.ingredientName.focus();
    }

    function closeModal() {
        setModalOpen(false);
        form.reset();
        editingIngredientId = null;
        currentImageUrl = null;
    }

    async function request(url, method, payload) {
        const response = await fetch(url, {
            method,
            headers: {
                Accept: 'application/json',
                ...(payload ? { 'Content-Type': 'application/json' } : {}),
                ...csrfHeaders()
            },
            body: payload ? JSON.stringify(payload) : undefined
        });
        if (!response.ok) {
            const body = await response.json().catch(() => ({}));
            throw new Error(body.message || 'Unable to save ingredient.');
        }
        return response.status === 204 ? null : response.json();
    }

    async function uploadIngredientImage(file) {
        const data = new FormData();
        data.append('file', file);
        const response = await fetch('/admin/ingredient-images', {
            method: 'POST',
            headers: csrfHeaders(),
            body: data
        });
        const body = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(body.message || 'Unable to upload ingredient image.');
        return body.imageUrl;
    }

    async function saveIngredient(event) {
        event.preventDefault();
        if (!form.checkValidity()) {
            form.reportValidity();
            return;
        }

        const formData = new FormData(form);
        const selectedImage = formData.get('imageFile');
        const payload = {
            ingredientName: formData.get('ingredientName').trim(),
            ingredientType: formData.get('ingredientType').trim(),
            defaultUnit: formData.get('defaultUnit').trim(),
            description: formData.get('description').trim(),
            imageUrl: currentImageUrl
        };

        saveButton.disabled = true;
        try {
            if (selectedImage?.size) payload.imageUrl = await uploadIngredientImage(selectedImage);
            await request(
                editingIngredientId ? `/admin/ingredients/${editingIngredientId}` : '/admin/ingredients',
                editingIngredientId ? 'PUT' : 'POST',
                payload
            );
            const wasEditing = Boolean(editingIngredientId);
            closeModal();
            await alerts.success(
                wasEditing ? 'Ingredient updated' : 'Ingredient added',
                `${payload.ingredientName} has been ${wasEditing ? 'updated' : 'added'} successfully.`
            );
            window.location.reload();
        } catch (error) {
            await alerts.error(error.message || 'Unable to save ingredient.');
        } finally {
            saveButton.disabled = false;
        }
    }

    async function deleteIngredient(row, button) {
        const ingredientName = row.dataset.name || 'this ingredient';
        const confirmed = await alerts.confirmDelete({
            title: 'Delete ingredient?',
            text: `${ingredientName} will be permanently removed.`,
            confirmButtonText: 'Yes, delete it!'
        });
        if (!confirmed) return;

        button.disabled = true;
        try {
            await request(`/admin/ingredients/${row.dataset.id}`, 'DELETE');
            await alerts.success('Ingredient deleted', `${ingredientName} has been deleted.`);
            window.location.reload();
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'Unable to delete ingredient.');
        }
    }

    function exportIngredients() {
        const header = ['Ingredient', 'Type', 'Default unit', 'Description', 'Image URL'];
        const data = rows().filter((row) => !row.hidden)
            .map((row) => [row.dataset.name, row.dataset.type, row.dataset.unit, row.dataset.description, row.dataset.imageUrl]);
        const csv = [header, ...data]
            .map((line) => line.map((value) => `"${String(value || '').replaceAll('"', '""')}"`).join(','))
            .join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-ingredients.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    }

    searchInput.addEventListener('input', applyFilters);
    typeFilter.addEventListener('change', applyFilters);
    clearButton.addEventListener('click', () => {
        searchInput.value = '';
        typeFilter.value = 'all';
        applyFilters();
    });
    document.getElementById('openIngredientModal').addEventListener('click', openCreateModal);
    document.getElementById('closeIngredientModal').addEventListener('click', closeModal);
    document.getElementById('cancelIngredientModal').addEventListener('click', closeModal);
    modal.addEventListener('click', (event) => {
        if (event.target === modal) closeModal();
    });
    form.addEventListener('submit', saveIngredient);
    document.getElementById('exportIngredients').addEventListener('click', exportIngredients);
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && modal.classList.contains('show')) closeModal();
    });
    rowsBox.addEventListener('click', (event) => {
        const button = event.target.closest('button[data-action]');
        if (!button) return;
        const row = button.closest('tr[data-id]');
        if (!row) return;
        if (button.dataset.action === 'edit') openEditModal(row);
        if (button.dataset.action === 'delete') deleteIngredient(row, button);
    });

    populateTypes();
})();
