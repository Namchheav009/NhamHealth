(() => {
    const rows = Array.from(document.querySelectorAll('tbody tr[data-id]'));
    const search = document.getElementById('reviewSearch');
    const sentiment = document.getElementById('sentimentFilter');
    const rating = document.getElementById('ratingFilter');
    const clear = document.getElementById('clearReviewFilters');
    const pageNumbers = document.getElementById('pageNumbers');
    const previous = document.getElementById('pagePrev');
    const next = document.getElementById('pageNext');
    const pageStart = document.getElementById('pageStart');
    const pageEnd = document.getElementById('pageEnd');
    const visibleCount = document.getElementById('visibleReviewCount');
    const filteredTotal = document.getElementById('filteredReviewTotal');
    const pageSize = 10;
    let currentPage = 1;
    let filteredRows = rows;

    function filterRows() {
        const term = (search?.value || '').trim().toLowerCase();
        filteredRows = rows.filter(row =>
            (!term || (row.dataset.search || '').includes(term)) &&
            (!sentiment || sentiment.value === 'all' || row.dataset.sentiment === sentiment.value) &&
            (!rating || rating.value === 'all' || row.dataset.rating === rating.value)
        );
    }

    function render() {
        filterRows();
        const pages = Math.max(1, Math.ceil(filteredRows.length / pageSize));
        currentPage = Math.min(currentPage, pages);
        const start = (currentPage - 1) * pageSize;
        const pageRows = new Set(filteredRows.slice(start, start + pageSize));
        rows.forEach(row => { row.hidden = !pageRows.has(row); });

        const shownStart = filteredRows.length ? start + 1 : 0;
        const shownEnd = Math.min(start + pageSize, filteredRows.length);
        if (pageStart) pageStart.textContent = String(shownStart);
        if (pageEnd) pageEnd.textContent = String(shownEnd);
        if (visibleCount) visibleCount.textContent = String(filteredRows.length);
        if (filteredTotal) filteredTotal.textContent = String(filteredRows.length);
        if (previous) previous.disabled = currentPage === 1;
        if (next) next.disabled = currentPage === pages || filteredRows.length === 0;

        if (pageNumbers) {
            pageNumbers.replaceChildren();
            for (let page = 1; page <= pages; page += 1) {
                const button = document.createElement('button');
                button.type = 'button';
                button.className = `page-btn${page === currentPage ? ' active' : ''}`;
                button.textContent = String(page);
                button.setAttribute('aria-label', `Page ${page}`);
                button.addEventListener('click', () => { currentPage = page; render(); });
                pageNumbers.appendChild(button);
            }
        }
    }

    [search, sentiment, rating].forEach(control => control?.addEventListener(control === search ? 'input' : 'change', () => {
        currentPage = 1;
        render();
    }));
    clear?.addEventListener('click', () => {
        if (search) search.value = '';
        if (sentiment) sentiment.value = 'all';
        if (rating) rating.value = 'all';
        currentPage = 1;
        render();
    });
    previous?.addEventListener('click', () => { if (currentPage > 1) { currentPage -= 1; render(); } });
    next?.addEventListener('click', () => { if (currentPage * pageSize < filteredRows.length) { currentPage += 1; render(); } });

    document.getElementById('exportReviews')?.addEventListener('click', () => {
        filterRows();
        const headings = ['Meal', 'User', 'Rating', 'Review', 'Submitted', 'Rating group'];
        const values = filteredRows.map(row => Array.from(row.cells).slice(0, 6).map(cell => cell.innerText.trim()));
        const escape = value => `"${String(value).replaceAll('"', '""')}"`;
        const csv = [headings, ...values].map(line => line.map(escape).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'meal-reviews.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });

    document.addEventListener('click', async event => {
        const button = event.target.closest('.delete-review');
        if (!button) return;
        const row = button.closest('tr[data-id]');
        if (!row || !window.confirm('Delete this review permanently?')) return;
        const token = document.querySelector('meta[name="_csrf"]')?.content;
        const header = document.querySelector('meta[name="_csrf_header"]')?.content;
        button.disabled = true;
        try {
            const headers = header && token ? { [header]: token } : {};
            const response = await fetch(`/admin/reviews/${row.dataset.id}`, { method: 'DELETE', headers });
            if (!response.ok) throw new Error('The review could not be deleted.');
            window.location.reload();
        } catch (error) {
            button.disabled = false;
            window.alert(error.message || 'The review could not be deleted.');
        }
    });

    render();
})();
