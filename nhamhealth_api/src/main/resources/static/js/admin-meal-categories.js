(() => {
    const searchInput = document.getElementById('categorySearch');
    const statusFilter = document.getElementById('statusFilter');
    const clearFiltersButton = document.getElementById('clearCategoryFilter');
    const rowsBox = document.getElementById('categoryRows');
    const modal = document.getElementById('categoryModal');
    const form = document.getElementById('categoryForm');
    const title = document.getElementById('categoryModalTitle');
    const subtitle = document.getElementById('categoryModalText');
    const saveButton = document.getElementById('saveCategoryButton');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (heading, text) => Promise.resolve(window.alert(text || heading)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    let editingCategoryId = null;

    const categoryRows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const csrfHeaders = () => csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {};

    function applyFilters() {
        const keyword = (searchInput.value || '').trim().toLowerCase();
        const status = statusFilter.value;
        categoryRows().forEach((row) => {
            const matchesName = !keyword || row.dataset.name.toLowerCase().includes(keyword);
            const matchesStatus = status === 'all' || row.dataset.status === status;
            row.hidden = !(matchesName && matchesStatus);
        });
    }

    function nextDisplayOrder() {
        return categoryRows().reduce((maximum, row) => Math.max(maximum, Number(row.dataset.order) || 0), 0) + 1;
    }

    function setModalOpen(isOpen) {
        modal.classList.toggle('show', isOpen);
        modal.setAttribute('aria-hidden', String(!isOpen));
    }

    function openCreateModal() {
        editingCategoryId = null;
        form.reset();
        form.elements.categoryStatus.value = 'true';
        form.elements.sortOrder.value = nextDisplayOrder();
        title.textContent = 'Add Meal Category';
        subtitle.textContent = 'Enter category information for your menu catalog.';
        saveButton.textContent = 'Save Category';
        setModalOpen(true);
        form.elements.categoryName.focus();
    }

    function openEditModal(row) {
        editingCategoryId = row.dataset.id;
        form.reset();
        form.elements.categoryName.value = row.dataset.name;
        form.elements.categoryStatus.value = row.dataset.status === 'active' ? 'true' : 'false';
        form.elements.sortOrder.value = row.dataset.order;
        form.elements.description.value = row.dataset.description || '';
        title.textContent = 'Edit Meal Category';
        subtitle.textContent = 'Update the category shown in your meal catalog.';
        saveButton.textContent = 'Save Changes';
        setModalOpen(true);
        form.elements.categoryName.focus();
    }

    function closeModal() {
        setModalOpen(false);
        editingCategoryId = null;
        form.reset();
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
            throw new Error(body.message || 'Unable to save meal category.');
        }
        return response.status === 204 ? null : response.json();
    }

    async function saveCategory(event) {
        event.preventDefault();
        if (!form.checkValidity()) {
            form.reportValidity();
            return;
        }

        const data = Object.fromEntries(new FormData(form).entries());
        const payload = {
            categoryName: data.categoryName.trim(),
            description: data.description.trim(),
            active: data.categoryStatus === 'true',
            sortOrder: Number(data.sortOrder)
        };

        saveButton.disabled = true;
        try {
            await request(
                editingCategoryId ? `/admin/meal-categories/${editingCategoryId}` : '/admin/meal-categories',
                editingCategoryId ? 'PUT' : 'POST',
                payload
            );
            const wasEditing = Boolean(editingCategoryId);
            closeModal();
            await alerts.success(
                wasEditing ? 'Category updated' : 'Category added',
                `${payload.categoryName} has been ${wasEditing ? 'updated' : 'added'} successfully.`
            );
            window.location.reload();
        } catch (error) {
            await alerts.error(error.message || 'Unable to save meal category.');
        } finally {
            saveButton.disabled = false;
        }
    }

    async function deleteCategory(row, button) {
        const categoryName = row.dataset.name || 'this category';
        const confirmed = await alerts.confirmDelete({
            title: 'Delete meal category?',
            text: `${categoryName} will be permanently removed.`,
            confirmButtonText: 'Yes, delete it!'
        });
        if (!confirmed) return;

        button.disabled = true;
        try {
            await request(`/admin/meal-categories/${row.dataset.id}`, 'DELETE');
            await alerts.success('Category deleted', `${categoryName} has been deleted.`);
            window.location.reload();
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'Unable to delete meal category.');
        }
    }

    searchInput.addEventListener('input', applyFilters);
    statusFilter.addEventListener('change', applyFilters);
    clearFiltersButton.addEventListener('click', () => {
        searchInput.value = '';
        statusFilter.value = 'all';
        applyFilters();
    });
    document.getElementById('openCategoryModal').addEventListener('click', openCreateModal);
    document.getElementById('closeCategoryModal').addEventListener('click', closeModal);
    document.getElementById('cancelCategoryModal').addEventListener('click', closeModal);
    modal.addEventListener('click', (event) => {
        if (event.target === modal) closeModal();
    });
    form.addEventListener('submit', saveCategory);
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && modal.classList.contains('show')) closeModal();
    });
    rowsBox.addEventListener('click', (event) => {
        const button = event.target.closest('button[data-action]');
        if (!button) return;
        const row = button.closest('tr[data-id]');
        if (!row) return;
        if (button.dataset.action === 'edit') openEditModal(row);
        if (button.dataset.action === 'delete') deleteCategory(row, button);
    });
})();
