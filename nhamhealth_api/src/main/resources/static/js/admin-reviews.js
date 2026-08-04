(() => {
    const searchInput = document.getElementById('reviewSearch');
    const statusFilter = document.getElementById('statusFilter');
    const ratingFilter = document.getElementById('ratingFilter');
    const applyButton = document.getElementById('applyReviewFilter');
    const rows = Array.from(document.querySelectorAll('tbody tr'));

    function applyFilters() {
        const keyword = (searchInput?.value || '').trim().toLowerCase();
        const status = (statusFilter?.value || 'all').toLowerCase();
        const rating = (ratingFilter?.value || 'all').toLowerCase();

        rows.forEach((row) => {
            const reviewText = (row.querySelector('td:nth-child(5)')?.textContent || '').toLowerCase();
            const mealName = (row.dataset.meal || '').toLowerCase();
            const rowStatus = (row.dataset.status || 'approved').toLowerCase();
            const rowRating = (row.dataset.rating || '').toLowerCase();

            const matchesKeyword = !keyword || mealName.includes(keyword) || reviewText.includes(keyword);
            const matchesStatus = status === 'all' || rowStatus === status;
            const matchesRating = rating === 'all' || rowRating === rating;

            row.hidden = !(matchesKeyword && matchesStatus && matchesRating);
        });
    }

    applyButton?.addEventListener('click', applyFilters);
    searchInput?.addEventListener('input', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    ratingFilter?.addEventListener('change', applyFilters);
})();
