(() => {
    const byId = (id) => document.getElementById(id);
    const rowsBox = byId('reviewRows');
    const search = byId('reviewSearch');
    const sentiment = byId('sentimentFilter');
    const rating = byId('ratingFilter');
    const pageNumbers = byId('pageNumbers');
    const previous = byId('pagePrev');
    const next = byId('pageNext');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    const pageSize = 10;
    let currentPage = 1;
    let filteredRows = [];
    const modal = byId('reviewModal');
    const form = byId('reviewForm');
    const saveButton = byId('saveReviewButton');

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];

    function filterRows() {
        const term = (search?.value || '').trim().toLowerCase();
        filteredRows = rows().filter((row) =>
            (!term || (row.dataset.search || '').includes(term))
            && (sentiment.value === 'all' || row.dataset.sentiment === sentiment.value)
            && (rating.value === 'all' || row.dataset.rating === rating.value));
    }

    function render() {
        filterRows();
        const pages = Math.max(1, Math.ceil(filteredRows.length / pageSize));
        currentPage = Math.min(currentPage, pages);
        const start = (currentPage - 1) * pageSize;
        const pageRows = new Set(filteredRows.slice(start, start + pageSize));
        rows().forEach((row) => { row.hidden = !pageRows.has(row); });

        byId('pageStart').textContent = filteredRows.length ? String(start + 1) : '0';
        byId('pageEnd').textContent = String(Math.min(start + pageSize, filteredRows.length));
        byId('visibleReviewCount').textContent = String(filteredRows.length);
        byId('filteredReviewTotal').textContent = String(filteredRows.length);
        previous.disabled = currentPage === 1;
        next.disabled = currentPage === pages || filteredRows.length === 0;

        pageNumbers.replaceChildren();
        for (let page = 1; page <= pages; page += 1) {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = `page-btn${page === currentPage ? ' active' : ''}`;
            button.textContent = String(page);
            button.setAttribute('aria-label', `Page ${page}`);
            if (page === currentPage) button.setAttribute('aria-current', 'page');
            button.addEventListener('click', () => { currentPage = page; render(); });
            pageNumbers.appendChild(button);
        }
    }

    function updateSummary() {
        const allRows = rows();
        const ratings = allRows.map((row) => Number(row.dataset.rating));
        const positive = ratings.filter((value) => value >= 4).length;
        const low = ratings.filter((value) => value < 3).length;
        const average = ratings.length ? ratings.reduce((sum, value) => sum + value, 0) / ratings.length : 0;
        const meals = new Set(allRows.map((row) => row.dataset.mealId));
        byId('totalReviewCount').textContent = String(allRows.length);
        byId('positiveReviewCount').textContent = String(positive);
        byId('lowReviewCount').textContent = String(low);
        byId('positiveReviewPercentage').textContent = `${(allRows.length ? positive * 100 / allRows.length : 0).toFixed(1)}% of total`;
        byId('averageReviewRating').textContent = `${average.toFixed(1)} / 5`;
        byId('reviewedMealCount').textContent = `${meals.size} unique ${meals.size === 1 ? 'meal' : 'meals'} reviewed`;
    }

    function addEmptyState() {
        if (rows().length || byId('emptyReviewRow')) return;
        const empty = document.createElement('tr');
        empty.id = 'emptyReviewRow';
        const cell = document.createElement('td');
        cell.colSpan = 7;
        cell.className = 'empty-state';
        const icon = document.createElement('i');
        icon.className = 'bi bi-chat-square-heart';
        const title = document.createElement('strong');
        title.textContent = 'No meal reviews yet';
        const text = document.createElement('span');
        text.textContent = 'User reviews will appear here after meals receive feedback.';
        cell.append(icon, title, text);
        empty.appendChild(cell);
        rowsBox.appendChild(empty);
    }

    async function deleteRequest(id) {
        const response = await fetch(`/admin/reviews/${id}`, {
            method: 'DELETE',
            headers: {
                ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
                Accept: 'application/json'
            },
            credentials: 'same-origin'
        });
        const body = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) throw new Error(body.message || body.detail || 'The review could not be deleted.');
    }

    function showModal(row = null) {
        form.reset();
        const editing = Boolean(row);
        form.dataset.reviewId = row?.dataset.id || '';
        byId('reviewModalTitle').textContent = editing ? 'Edit Review' : 'Add Review';
        saveButton.textContent = editing ? 'Save Changes' : 'Save Review';
        if (editing) {
            byId('reviewUser').value = row.dataset.userId;
            byId('reviewMeal').value = row.dataset.mealId;
            byId('reviewRating').value = row.dataset.rating;
            byId('reviewText').value = row.dataset.reviewText || '';
        }
        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
    }

    function hideModal() {
        modal.classList.remove('show');
        modal.setAttribute('aria-hidden', 'true');
        form.reset();
        form.dataset.reviewId = '';
    }

    async function saveReview(event) {
        event.preventDefault();
        if (!form.checkValidity()) return form.reportValidity();
        const id = form.dataset.reviewId;
        const payload = {
            userId: Number(byId('reviewUser').value),
            mealId: Number(byId('reviewMeal').value),
            rating: Number(byId('reviewRating').value),
            reviewText: byId('reviewText').value.trim()
        };
        saveButton.disabled = true;
        try {
            const response = await fetch(id ? `/admin/reviews/${id}` : '/admin/reviews', {
                method: id ? 'PUT' : 'POST',
                headers: {
                    ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
                    'Content-Type': 'application/json', Accept: 'application/json'
                },
                credentials: 'same-origin',
                body: JSON.stringify(payload)
            });
            const body = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
            if (!response.ok) throw new Error(body.message || body.detail || 'The review could not be saved.');
            hideModal();
            await alerts.success(id ? 'Review updated' : 'Review added', `The review has been ${id ? 'updated' : 'added'} successfully.`);
            window.location.reload();
        } catch (error) {
            await alerts.error(error.message || 'The review could not be saved.');
        } finally {
            saveButton.disabled = false;
        }
    }

    async function deleteReview(button) {
        const row = button.closest('tr[data-id]');
        if (!row) return;
        const meal = row.querySelector('.meal-cell strong')?.textContent.trim() || 'this meal';
        const user = row.querySelector('.user-cell strong')?.textContent.trim() || 'this user';
        const confirmed = await alerts.confirmDelete({
            title: 'Delete review?',
            text: `${user}'s review of ${meal} will be permanently removed.`,
            confirmButtonText: 'Yes, delete it!'
        });
        if (!confirmed) return;
        button.disabled = true;
        try {
            await deleteRequest(row.dataset.id);
            row.remove();
            addEmptyState();
            updateSummary();
            render();
            await alerts.success('Review deleted', `${user}'s review of ${meal} has been deleted.`);
        } catch (error) {
            button.disabled = false;
            await alerts.error(error.message || 'The review could not be deleted.');
        }
    }

    [search, sentiment, rating].forEach((control) => control?.addEventListener(control === search ? 'input' : 'change', () => {
        currentPage = 1;
        render();
    }));
    byId('clearReviewFilters')?.addEventListener('click', () => {
        search.value = '';
        sentiment.value = 'all';
        rating.value = 'all';
        currentPage = 1;
        render();
        search.focus();
    });
    previous?.addEventListener('click', () => { if (currentPage > 1) { currentPage -= 1; render(); } });
    next?.addEventListener('click', () => { if (currentPage * pageSize < filteredRows.length) { currentPage += 1; render(); } });
    byId('exportReviews')?.addEventListener('click', () => {
        filterRows();
        const headings = ['Meal', 'User', 'Rating', 'Review', 'Submitted', 'Rating group'];
        const values = filteredRows.map((row) => [...row.cells].slice(0, 6).map((cell) => cell.innerText.trim()));
        const quote = (value) => `"${String(value).replaceAll('"', '""')}"`;
        const csv = [headings, ...values].map((line) => line.map(quote).join(',')).join('\r\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-meal-reviews.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });
    document.addEventListener('click', (event) => {
        const edit = event.target.closest('.edit-review');
        if (edit) {
            showModal(edit.closest('tr[data-id]'));
            return;
        }
        const button = event.target.closest('.delete-review');
        if (button) deleteReview(button);
    });
    byId('openReviewModal')?.addEventListener('click', () => showModal());
    byId('closeReviewModal')?.addEventListener('click', hideModal);
    byId('cancelReviewModal')?.addEventListener('click', hideModal);
    form?.addEventListener('submit', saveReview);
    modal?.addEventListener('click', (event) => { if (event.target === modal) hideModal(); });

    updateSummary();
    render();
})();
