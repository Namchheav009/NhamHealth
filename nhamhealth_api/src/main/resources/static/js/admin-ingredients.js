(() => {
    const searchInput = document.getElementById('ingredientSearch');
    const categoryFilter = document.getElementById('categoryFilter');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearIngredientFilter');
    const modal = document.getElementById('ingredientModal');
    const openModal = document.getElementById('openIngredientModal');
    const closeModal = document.getElementById('closeIngredientModal');
    const cancelModal = document.getElementById('cancelIngredientModal');
    const form = document.getElementById('ingredientForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-name]'));

    function applyFilters() {
        const keyword = (searchInput?.value || '').trim().toLowerCase();
        const category = (categoryFilter?.value || 'all').toLowerCase();
        const status = (statusFilter?.value || 'all').toLowerCase();

        rows.forEach((row) => {
            const name = (row.dataset.name || '').toLowerCase();
            const rowCategory = (row.dataset.category || '').toLowerCase();
            const rowStatus = (row.dataset.status || '').toLowerCase();

            const matchesKeyword = !keyword || name.includes(keyword);
            const matchesCategory = category === 'all' || rowCategory === category;
            const matchesStatus = status === 'all' || rowStatus === status;

            row.hidden = !(matchesKeyword && matchesCategory && matchesStatus);
        });
    }

    function showModal() {
        modal?.classList.add('show');
        form?.querySelector('input')?.focus();
    }

    function hideModal() {
        modal?.classList.remove('show');
        form?.reset();
    }

    searchInput?.addEventListener('input', applyFilters);
    categoryFilter?.addEventListener('change', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearButton?.addEventListener('click', () => {
        searchInput.value = '';
        categoryFilter.value = 'all';
        statusFilter.value = 'all';
        applyFilters();
    });

    openModal?.addEventListener('click', showModal);
    closeModal?.addEventListener('click', hideModal);
    cancelModal?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => {
        if (event.target === modal) {
            hideModal();
        }
    });

    form?.addEventListener('submit', (event) => {
        event.preventDefault();
        alert('This form is ready for your Spring controller. Connect it to your save endpoint to persist ingredients.');
        hideModal();
    });
})();
