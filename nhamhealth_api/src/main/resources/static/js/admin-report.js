(() => {
    const search = document.getElementById('reportSearch');
    const status = document.getElementById('reportStatus');
    const clearBtn = document.getElementById('clearReportFilters');
    const openBtn = document.getElementById('openReportModal');
    const modal = document.getElementById('reportModal');
    const closeBtn = document.getElementById('closeReportModal');
    const cancelBtn = document.getElementById('cancelReportModal');
    const form = document.getElementById('reportForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-reporter]'));

    const apply = () => {
        const q = (search?.value || '').trim().toLowerCase();
        const s = (status?.value || '').toLowerCase();
        rows.forEach(r => {
            const a = (r.dataset.reporter || '').toLowerCase();
            const st = (r.dataset.status || '').toLowerCase();
            const match = (!q || a.includes(q) || r.innerText.toLowerCase().includes(q)) && (!s || st===s);
            r.hidden = !match;
        });
    };

    search?.addEventListener('input', apply);
    status?.addEventListener('change', apply);
    clearBtn?.addEventListener('click', () => { if (!search||!status) return; search.value=''; status.value=''; apply(); });
    openBtn?.addEventListener('click', ()=> modal?.classList.add('show'));
    closeBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    cancelBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    modal?.addEventListener('click', (e)=> { if (e.target===modal) modal.classList.remove('show'); });
    form?.addEventListener('submit', e=>{ e.preventDefault(); alert('Create endpoint not implemented yet.'); modal?.classList.remove('show'); });
    apply();
})();
