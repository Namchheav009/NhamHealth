(() => {
    const searchInput = document.getElementById('goalSearch');
    const nutrientFilter = document.getElementById('nutrientFilter');
    const statusFilter = document.getElementById('statusFilter');
    const clearFilters = document.getElementById('clearFilters');
    const openModal = document.getElementById('openGoalModal');
    const modal = document.getElementById('goalModal');
    const closeModal = document.getElementById('closeGoalModal');
    const cancelModal = document.getElementById('cancelGoalModal');
    const form = document.getElementById('goalForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-user]'));

    function applyFilters() {
        const query = (searchInput?.value || '').trim().toLowerCase();
        const nutrient = (nutrientFilter?.value || '').toLowerCase();
        const status = (statusFilter?.value || '').toLowerCase();

        rows.forEach((row) => {
            const user = (row.dataset.user || '').toLowerCase();
            const nutrientValue = (row.dataset.nutrient || '').toLowerCase();
            const rowStatus = (row.dataset.status || '').toLowerCase();

            const matchesQuery = !query || user.includes(query) || nutrientValue.includes(query);
            const matchesNutrient = !nutrient || nutrientValue === nutrient;
            const matchesStatus = !status || rowStatus === status;

            row.hidden = !(matchesQuery && matchesNutrient && matchesStatus);
        });
    }

    function showModal() {
        modal?.classList.add('show');
        form?.querySelector('input, select, textarea')?.focus();
    }

    function hideModal() {
        modal?.classList.remove('show');
        form?.reset();
    }

    searchInput?.addEventListener('input', applyFilters);
    nutrientFilter?.addEventListener('change', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearFilters?.addEventListener('click', () => {
        if (!searchInput || !nutrientFilter || !statusFilter) return;
        searchInput.value = '';
        nutrientFilter.value = '';
        statusFilter.value = '';
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
        alert('This form is configured for your nutrient goal save flow. Connect it to your backend endpoint to persist changes.');
        hideModal();
    });

    applyFilters();
})();
