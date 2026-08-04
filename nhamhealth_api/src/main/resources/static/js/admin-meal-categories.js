(() => {
    const searchInput = document.getElementById('categorySearch');
    const statusFilter = document.getElementById('statusFilter');
    const clearFiltersButton = document.getElementById('clearCategoryFilter');
    const modal = document.getElementById('categoryModal');
    const openModal = document.getElementById('openCategoryModal');
    const closeModal = document.getElementById('closeCategoryModal');
    const cancelModal = document.getElementById('cancelCategoryModal');
    const form = document.getElementById('categoryForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-name]'));

    function applyFilters() {
        const keyword = (searchInput?.value || '').trim().toLowerCase();
        const status = (statusFilter?.value || 'all').toLowerCase();

        rows.forEach((row) => {
            const name = (row.dataset.name || '').toLowerCase();
            const state = (row.dataset.status || '').toLowerCase();
            const matchesKeyword = !keyword || name.includes(keyword);
            const matchesStatus = status === 'all' || state === status;
            row.hidden = !(matchesKeyword && matchesStatus);
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
    statusFilter?.addEventListener('change', applyFilters);
    clearFiltersButton?.addEventListener('click', () => {
        searchInput.value = '';
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
        alert('This form is ready for your Spring controller. Connect it to your save endpoint to persist categories.');
        hideModal();
    });
})();
