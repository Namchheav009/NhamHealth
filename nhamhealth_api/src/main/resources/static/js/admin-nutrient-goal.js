(() => {
    const byId = (id) => document.getElementById(id);
    const rowsBox = byId('goalRows');
    const search = byId('goalSearch');
    const nutrient = byId('nutrientFilter');
    const status = byId('statusFilter');
    const numbers = byId('pageNumbers');
    const prev = byId('pagePrev');
    const next = byId('pageNext');
    const modal = byId('goalModal');
    const form = byId('goalForm');
    const saveButton = byId('saveGoalButton');
    const formError = byId('goalFormError');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    const alerts = window.adminAlerts ?? {
        confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
        success: (title, text) => Promise.resolve(window.alert(text || title)),
        error: (text) => Promise.resolve(window.alert(text))
    };
    const pageSize = 10;
    let page = 1;
    let filtered = [];

    const rows = () => [...(rowsBox?.querySelectorAll('tr[data-id]') || [])];
    const setText = (id, value) => { const node = byId(id); if (node) node.textContent = String(value); };
    const localToday = () => {
        const date = new Date();
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    };
    const isCurrent = (active, from, to) => active && from <= localToday() && (!to || to >= localToday());
    const formatDate = (value) => value
        ? new Intl.DateTimeFormat(undefined, { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' }).format(new Date(`${value}T00:00:00Z`))
        : 'Ongoing';

    async function request(url, method, body) {
        const response = await fetch(url, {
            method,
            headers: {
                ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
                ...(body ? { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' } : {}),
                Accept: 'application/json'
            },
            credentials: 'same-origin',
            body
        });
        const data = (response.headers.get('content-type') || '').includes('json') ? await response.json() : {};
        if (!response.ok) throw new Error(data.message || data.detail || 'Unable to complete this request.');
        return data;
    }

    function filterRows() {
        const term = (search?.value || '').trim().toLowerCase();
        filtered = rows().filter((row) => (!term || (row.dataset.search || '').includes(term))
            && (nutrient.value === 'all' || row.dataset.nutrient === nutrient.value)
            && (status.value === 'all' || row.dataset.status === status.value));
    }

    function render() {
        filterRows();
        const pages = Math.max(1, Math.ceil(filtered.length / pageSize));
        page = Math.min(page, pages);
        const start = (page - 1) * pageSize;
        const shown = new Set(filtered.slice(start, start + pageSize));
        rows().forEach((row) => { row.hidden = !shown.has(row); });
        setText('pageStart', filtered.length ? start + 1 : 0);
        setText('pageEnd', Math.min(start + pageSize, filtered.length));
        setText('visibleGoalCount', filtered.length);
        setText('filteredGoalTotal', filtered.length);
        prev.disabled = page === 1;
        next.disabled = page === pages || !filtered.length;
        numbers.replaceChildren();
        for (let number = 1; number <= pages; number += 1) {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = `page-btn${number === page ? ' active' : ''}`;
            button.textContent = String(number);
            button.setAttribute('aria-label', `Page ${number}`);
            if (number === page) button.setAttribute('aria-current', 'page');
            button.addEventListener('click', () => { page = number; render(); });
            numbers.appendChild(button);
        }
    }

    function updateSummary() {
        const allRows = rows();
        setText('totalGoalCount', allRows.length);
        setText('activeGoalCount', allRows.filter((row) => row.dataset.status === 'active').length);
        setText('currentGoalCount', `${allRows.filter((row) => row.dataset.current === 'true').length} currently effective`);
        setText('trackedNutrientCount', new Set(allRows.map((row) => row.dataset.nutrientId).filter(Boolean)).size);
        setText('goalUserCount', new Set(allRows.map((row) => row.dataset.userId).filter(Boolean)).size);
    }

    function actionButton() {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'icon-button danger delete-goal';
        button.title = 'Delete nutrient goal';
        button.setAttribute('aria-label', 'Delete nutrient goal');
        const icon = document.createElement('i');
        icon.className = 'bi bi-trash3';
        button.appendChild(icon);
        return button;
    }

    function createRow(goal) {
        const row = document.createElement('tr');
        const active = Boolean(goal.active);
        Object.assign(row.dataset, {
            id: String(goal.id), userId: String(goal.userId), nutrientId: String(goal.nutrientId),
            current: String(isCurrent(active, goal.effectiveFrom, goal.effectiveTo)),
            nutrient: goal.nutrientName.toLowerCase(), status: active ? 'active' : 'inactive',
            search: `${goal.userName} ${goal.userEmail} ${goal.nutrientName}`.toLowerCase()
        });
        const userCell = document.createElement('td');
        const userBox = document.createElement('div'); userBox.className = 'user-cell';
        const avatar = document.createElement('span'); avatar.className = 'user-avatar'; avatar.textContent = goal.userInitials || 'U';
        const userText = document.createElement('span');
        const userName = document.createElement('strong'); userName.textContent = goal.userName || 'User';
        const email = document.createElement('small'); email.textContent = goal.userEmail;
        userText.append(userName, email); userBox.append(avatar, userText); userCell.appendChild(userBox);
        const nutrientCell = document.createElement('td');
        const nutrientBox = document.createElement('div'); nutrientBox.className = 'nutrient-cell';
        const nutrientIcon = document.createElement('span'); nutrientIcon.className = 'nutrient-icon'; nutrientIcon.innerHTML = '<i class="bi bi-lightning-charge-fill"></i>';
        const nutrientText = document.createElement('span');
        const nutrientName = document.createElement('strong'); nutrientName.textContent = goal.nutrientName;
        const unit = document.createElement('small'); unit.textContent = goal.unit || 'No unit';
        nutrientText.append(nutrientName, unit); nutrientBox.append(nutrientIcon, nutrientText); nutrientCell.appendChild(nutrientBox);
        const amountCell = document.createElement('td');
        const amount = document.createElement('span'); amount.className = 'amount';
        const amountValue = document.createElement('strong'); amountValue.textContent = String(goal.goalAmount);
        const amountUnit = document.createElement('small'); amountUnit.textContent = goal.unit;
        amount.append(amountValue, document.createTextNode(' '), amountUnit); amountCell.appendChild(amount);
        const fromCell = document.createElement('td'); const from = document.createElement('time'); from.textContent = formatDate(goal.effectiveFrom); from.dateTime = goal.effectiveFrom; fromCell.appendChild(from);
        const toCell = document.createElement('td'); const to = document.createElement('time'); to.textContent = formatDate(goal.effectiveTo); if (goal.effectiveTo) to.dateTime = goal.effectiveTo; toCell.appendChild(to);
        const statusCell = document.createElement('td');
        const badge = document.createElement('span'); badge.className = `status-pill ${active ? 'status-active' : 'status-inactive'}`; badge.textContent = active ? 'Active' : 'Inactive'; statusCell.appendChild(badge);
        const actionCell = document.createElement('td'); actionCell.appendChild(actionButton());
        row.append(userCell, nutrientCell, amountCell, fromCell, toCell, statusCell, actionCell);
        return row;
    }

    function addGoal(goal) {
        byId('emptyGoalRow')?.remove();
        rowsBox.prepend(createRow(goal));
        updateSummary();
        render();
    }

    function addEmptyState() {
        if (rows().length || byId('emptyGoalRow')) return;
        const empty = document.createElement('tr'); empty.id = 'emptyGoalRow';
        const cell = document.createElement('td'); cell.colSpan = 7; cell.className = 'empty-state';
        cell.textContent = 'No nutrient goals yet. Add a goal to begin tracking a user’s nutrient target.';
        empty.appendChild(cell); rowsBox.appendChild(empty);
    }

    function showModal() {
        formError.hidden = true;
        modal.classList.add('show'); modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        form.elements.effectiveFrom.value ||= localToday();
        form.elements.userId.focus();
    }

    function hideModal() {
        modal.classList.remove('show'); modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open'); form.reset(); formError.hidden = true;
    }

    async function saveGoal(event) {
        event.preventDefault();
        if (!form.checkValidity()) {
            const invalid = form.querySelector(':invalid');
            await alerts.error(invalid?.validationMessage || 'Complete all required fields.', 'Missing goal information');
            invalid?.focus(); return;
        }
        const data = new FormData(form);
        if (data.get('effectiveTo') && data.get('effectiveTo') < data.get('effectiveFrom')) {
            await alerts.error('Effective-to date cannot be before the effective-from date.', 'Invalid date range');
            form.elements.effectiveTo.focus(); return;
        }
        const label = saveButton.innerHTML;
        saveButton.disabled = true; saveButton.textContent = 'Saving...'; formError.hidden = true;
        try {
            data.delete(document.querySelector('#goalForm input[type="hidden"]')?.name || '_csrf');
            const goal = await request('/admin/nutrient-goals', 'POST', new URLSearchParams(data));
            addGoal(goal); hideModal();
            await alerts.success('Nutrient goal added', `${goal.userName}'s ${goal.nutrientName} goal has been added.`);
        } catch (error) {
            formError.textContent = error.message; formError.hidden = false;
            await alerts.error(error.message || 'The nutrient goal could not be saved.');
        } finally { saveButton.disabled = false; saveButton.innerHTML = label; }
    }

    async function deleteGoal(button) {
        const row = button.closest('tr[data-id]'); if (!row) return;
        const user = row.querySelector('.user-cell strong')?.textContent.trim() || 'the user';
        const nutrientName = row.querySelector('.nutrient-cell strong')?.textContent.trim() || 'nutrient';
        if (!await alerts.confirmDelete({ title: 'Delete nutrient goal?', text: `${user}'s ${nutrientName} target will be permanently removed.`, confirmButtonText: 'Yes, delete it!' })) return;
        button.disabled = true;
        try {
            await request(`/admin/nutrient-goals/${row.dataset.id}`, 'DELETE');
            row.remove(); addEmptyState(); updateSummary(); render();
            await alerts.success('Nutrient goal deleted', `${user}'s ${nutrientName} goal has been deleted.`);
        } catch (error) { button.disabled = false; await alerts.error(error.message || 'The nutrient goal could not be deleted.'); }
    }

    [search, nutrient, status].forEach((control) => control?.addEventListener(control === search ? 'input' : 'change', () => { page = 1; render(); }));
    byId('clearFilters')?.addEventListener('click', () => { search.value = ''; nutrient.value = 'all'; status.value = 'all'; page = 1; render(); search.focus(); });
    prev?.addEventListener('click', () => { if (page > 1) { page -= 1; render(); } });
    next?.addEventListener('click', () => { if (page * pageSize < filtered.length) { page += 1; render(); } });
    byId('openGoalModal')?.addEventListener('click', showModal); byId('closeGoalModal')?.addEventListener('click', hideModal); byId('cancelGoalModal')?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => { if (event.target === modal) hideModal(); });
    document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal?.classList.contains('show')) hideModal(); });
    form?.addEventListener('submit', saveGoal);
    document.addEventListener('click', (event) => { const button = event.target.closest('.delete-goal'); if (button) deleteGoal(button); });
    byId('exportGoals')?.addEventListener('click', () => {
        filterRows(); const headings = ['User', 'Nutrient', 'Goal amount', 'Effective from', 'Effective to', 'Status'];
        const data = filtered.map((row) => [...row.cells].slice(0, 6).map((cell) => cell.innerText.trim()));
        const quote = (value) => `"${String(value).replaceAll('"', '""')}"`;
        const csv = [headings, ...data].map((line) => line.map(quote).join(',')).join('\r\n');
        const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })); link.download = 'nham-health-nutrient-goals.csv'; link.click(); URL.revokeObjectURL(link.href);
    });

    updateSummary(); render();
})();
