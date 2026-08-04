(() => {
    const searchInput = document.getElementById('moodSearch');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearMoodFilter');
    const modal = document.getElementById('moodModal');
    const openModal = document.getElementById('openMoodModal');
    const closeModal = document.getElementById('closeMoodModal');
    const cancelModal = document.getElementById('cancelMoodModal');
    const form = document.getElementById('moodForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-name]'));

    function applyFilters() {
        const keyword = (searchInput?.value || '').trim().toLowerCase();
        const status = (statusFilter?.value || 'all').toLowerCase();

        rows.forEach((row) => {
            const name = (row.dataset.name || '').toLowerCase();
            const rowStatus = (row.dataset.status || '').toLowerCase();

            const matchesKeyword = !keyword || name.includes(keyword);
            const matchesStatus = status === 'all' || rowStatus === status;

            row.hidden = !(matchesKeyword && matchesStatus);
        });
    }

    function showModal() { modal?.classList.add('show'); form?.querySelector('input')?.focus(); }
    function hideModal() { modal?.classList.remove('show'); form?.reset(); }

    openModal?.addEventListener('click', showModal);
    closeModal?.addEventListener('click', hideModal);
    cancelModal?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => { if (event.target === modal) hideModal(); });

    searchInput?.addEventListener('input', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearButton?.addEventListener('click', () => { searchInput.value = ''; statusFilter.value = 'all'; applyFilters(); });

    form?.addEventListener('submit', (event) => {
        event.preventDefault();
        alert('Save endpoint not implemented yet.');
        hideModal();
    });
})();
