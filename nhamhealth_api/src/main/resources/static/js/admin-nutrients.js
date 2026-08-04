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
    const rows = Array.from(document.querySelectorAll('tbody tr[data-name]'));

    function applyFilters() {
        const keyword = (searchInput?.value || '').trim().toLowerCase();
        const type = (typeFilter?.value || 'all').toLowerCase();
        const status = (statusFilter?.value || 'all').toLowerCase();

        rows.forEach((row) => {
            const name = (row.dataset.name || '').toLowerCase();
            const rowType = (row.dataset.type || '').toLowerCase();
            const rowStatus = (row.dataset.status || '').toLowerCase();

            const matchesKeyword = !keyword || name.includes(keyword);
            const matchesType = type === 'all' || rowType === type;
            const matchesStatus = status === 'all' || rowStatus === status;

            row.hidden = !(matchesKeyword && matchesType && matchesStatus);
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
    typeFilter?.addEventListener('change', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearButton?.addEventListener('click', () => {
        searchInput.value = '';
        typeFilter.value = 'all';
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
        alert('This form is ready for your Spring controller. Connect it to your save endpoint to persist nutrients.');
        hideModal();
    });
})();
