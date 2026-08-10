(() => {
    const tabFood = document.getElementById('tabFood');
    const tabPost = document.getElementById('tabPost');
    const foodPanel = document.getElementById('foodPanel');
    const postPanel = document.getElementById('postPanel');
    const searchInput = document.getElementById('favoriteSearch');
    const clearButton = document.getElementById('clearFavoriteSearch');
    const exportButton = document.getElementById('exportFavorites');
    const visibleCount = document.getElementById('visibleFavoriteCount');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    let activeType = 'meals';

    const rowsFor = type => [...document.querySelectorAll(`#${type === 'meals' ? 'foodPanel' : 'postPanel'} tbody tr[data-id]`)];
    const requestHeaders = () => csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {};

    const applySearch = () => {
        const query = searchInput?.value.trim().toLowerCase() || '';
        let count = 0;
        rowsFor(activeType).forEach(row => {
            row.hidden = Boolean(query) && !(row.dataset.search || '').includes(query);
            if (!row.hidden) count += 1;
        });
        if (visibleCount) visibleCount.textContent = String(count);
    };

    const selectTab = type => {
        activeType = type;
        const mealsSelected = type === 'meals';
        foodPanel.hidden = !mealsSelected;
        postPanel.hidden = mealsSelected;
        tabFood.classList.toggle('btn-primary', mealsSelected);
        tabPost.classList.toggle('btn-primary', !mealsSelected);
        tabFood.setAttribute('aria-selected', String(mealsSelected));
        tabPost.setAttribute('aria-selected', String(!mealsSelected));
        applySearch();
    };

    tabFood?.addEventListener('click', () => selectTab('meals'));
    tabPost?.addEventListener('click', () => selectTab('posts'));
    searchInput?.addEventListener('input', applySearch);
    clearButton?.addEventListener('click', () => { searchInput.value = ''; applySearch(); });

    document.querySelectorAll('.remove-favorite').forEach(button => button.addEventListener('click', async () => {
        const row = button.closest('tr[data-id]');
        if (!row || !window.confirm('Remove this item from the user’s favorites?')) return;
        button.disabled = true;
        try {
            const response = await fetch(`/admin/favorites/${button.dataset.kind}/${row.dataset.id}`, {
                method: 'DELETE', headers: requestHeaders()
            });
            if (!response.ok) throw new Error('Unable to remove this favorite.');
            window.location.reload();
        } catch (error) {
            button.disabled = false;
            window.alert(error.message);
        }
    }));

    exportButton?.addEventListener('click', () => {
        const quote = value => `"${String(value || '').replaceAll('"', '""')}"`;
        const records = rowsFor(activeType).filter(row => !row.hidden).map(row => {
            const cells = [...row.querySelectorAll('td')];
            return activeType === 'meals'
                ? [cells[0]?.innerText, cells[1]?.innerText, cells[2]?.innerText, cells[3]?.innerText]
                : [cells[0]?.innerText, cells[1]?.innerText, cells[2]?.innerText, cells[3]?.innerText];
        });
        const headers = activeType === 'meals'
            ? ['Meal', 'Category', 'Saved by', 'Saved at']
            : ['Post', 'Post author', 'Saved by', 'Saved at'];
        const csv = [headers, ...records].map(columns => columns.map(quote).join(',')).join('\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = `nham-health-${activeType}-favorites.csv`;
        link.click();
        URL.revokeObjectURL(link.href);
    });

    selectTab('meals');
})();
