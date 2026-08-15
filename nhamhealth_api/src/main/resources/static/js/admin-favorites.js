(() => {
    const byId = (id) => document.getElementById(id);
    const tabFood = byId('tabFood');
    const tabPost = byId('tabPost');
    const foodPanel = byId('foodPanel');
    const postPanel = byId('postPanel');
    const searchInput = byId('favoriteSearch');
    const visibleCount = byId('visibleFavoriteCount');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    let activeType = 'meals';

    const rowsFor = (type) => [...document.querySelectorAll(`#${type === 'meals' ? 'foodPanel' : 'postPanel'} tbody tr[data-id]`)];
    const requestHeaders = () => ({
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
        Accept: 'application/json'
    });

    async function removeRequest(type, id) {
        const response = await fetch(`/admin/favorites/${type}/${id}`, {
            method: 'DELETE',
            headers: requestHeaders(),
            credentials: 'same-origin'
        });
        const body = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) throw new Error(body.message || body.detail || 'Unable to remove this favorite.');
    }

    function applySearch() {
        const query = searchInput?.value.trim().toLowerCase() || '';
        let count = 0;
        rowsFor(activeType).forEach((row) => {
            row.hidden = Boolean(query) && !(row.dataset.search || '').includes(query);
            if (!row.hidden) count += 1;
        });
        visibleCount.textContent = String(count);
    }

    function selectTab(type) {
        activeType = type;
        const mealsSelected = type === 'meals';
        foodPanel.hidden = !mealsSelected;
        postPanel.hidden = mealsSelected;
        tabFood.classList.toggle('btn-primary', mealsSelected);
        tabPost.classList.toggle('btn-primary', !mealsSelected);
        tabFood.setAttribute('aria-selected', String(mealsSelected));
        tabPost.setAttribute('aria-selected', String(!mealsSelected));
        tabFood.tabIndex = mealsSelected ? 0 : -1;
        tabPost.tabIndex = mealsSelected ? -1 : 0;
        applySearch();
    }

    function updateSummary() {
        const mealRows = rowsFor('meals');
        const postRows = rowsFor('posts');
        const mealUsers = new Set(mealRows.map((row) => row.dataset.userId));
        const allUsers = new Set([...mealRows, ...postRows].map((row) => row.dataset.userId));
        byId('totalFavoriteCount').textContent = String(mealRows.length + postRows.length);
        byId('mealFavoriteCount').textContent = String(mealRows.length);
        byId('postFavoriteCount').textContent = String(postRows.length);
        byId('mealTabCount').textContent = String(mealRows.length);
        byId('postTabCount').textContent = String(postRows.length);
        byId('mealFavoriteUserCount').textContent = `${mealUsers.size} ${mealUsers.size === 1 ? 'user' : 'users'} saved meals`;
        byId('overallFavoriteUserCount').textContent = `${allUsers.size} unique ${allUsers.size === 1 ? 'user' : 'users'} overall`;
    }

    function addEmptyState(type) {
        if (rowsFor(type).length) return;
        const isMeal = type === 'meals';
        const tbody = byId(isMeal ? 'mealFavoriteRows' : 'postFavoriteRows');
        const empty = document.createElement('tr');
        empty.id = isMeal ? 'emptyMealFavoriteRow' : 'emptyPostFavoriteRow';
        const cell = document.createElement('td');
        cell.colSpan = 5;
        cell.className = 'empty-state';
        const icon = document.createElement('i');
        icon.className = isMeal ? 'bi bi-heart' : 'bi bi-bookmark';
        const title = document.createElement('strong');
        title.textContent = isMeal ? 'No meal favorites' : 'No post favorites';
        const text = document.createElement('span');
        text.textContent = `${isMeal ? 'Meal' : 'Post'} favorites will appear here when users save ${isMeal ? 'meals' : 'community posts'}.`;
        cell.append(icon, title, text);
        empty.appendChild(cell);
        tbody.appendChild(empty);
    }

    async function removeFavorite(button) {
        const row = button.closest('tr[data-id]');
        if (!row) return;
        const type = button.dataset.kind;
        const contentName = row.querySelector('.content-cell strong')?.textContent.trim() || 'this item';
        const userName = row.querySelector('.user-cell strong')?.textContent.trim() || 'the user';
        const confirmed = await alerts.confirmDelete({
            title: 'Remove favorite?',
            text: `${contentName} will be removed from ${userName}'s favorites.`,
            confirmButtonText: 'Yes, remove it!'
        });
        if (!confirmed) return;

        button.disabled = true;
        try {
            await removeRequest(type, row.dataset.id);
            row.remove();
            addEmptyState(type);
            updateSummary();
            applySearch();
            await alerts.success('Favorite removed', `${contentName} was removed from ${userName}'s favorites.`);
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'Unable to remove this favorite.');
        }
    }

    function exportFavorites() {
        const quote = (value) => `"${String(value || '').replaceAll('"', '""')}"`;
        const records = rowsFor(activeType).filter((row) => !row.hidden).map((row) => {
            const cells = [...row.querySelectorAll('td')];
            return [cells[0]?.innerText.trim(), cells[1]?.innerText.trim(), cells[2]?.innerText.trim(), cells[3]?.innerText.trim()];
        });
        const headings = activeType === 'meals'
            ? ['Meal', 'Category', 'Saved by', 'Saved at']
            : ['Post', 'Post author', 'Saved by', 'Saved at'];
        const csv = [headings, ...records].map((columns) => columns.map(quote).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = `nham-health-${activeType}-favorites.csv`;
        link.click();
        URL.revokeObjectURL(link.href);
    }

    tabFood?.addEventListener('click', () => selectTab('meals'));
    tabPost?.addEventListener('click', () => selectTab('posts'));
    document.querySelector('.tab-buttons')?.addEventListener('keydown', (event) => {
        if (!['ArrowLeft', 'ArrowRight'].includes(event.key)) return;
        event.preventDefault();
        const nextType = activeType === 'meals' ? 'posts' : 'meals';
        selectTab(nextType);
        (nextType === 'meals' ? tabFood : tabPost).focus();
    });
    searchInput?.addEventListener('input', applySearch);
    byId('clearFavoriteSearch')?.addEventListener('click', () => {
        searchInput.value = '';
        applySearch();
        searchInput.focus();
    });
    document.addEventListener('click', (event) => {
        const button = event.target.closest('.remove-favorite');
        if (button) removeFavorite(button);
    });
    byId('exportFavorites')?.addEventListener('click', exportFavorites);

    updateSummary();
    selectTab('meals');
})();
