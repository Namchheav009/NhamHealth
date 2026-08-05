(function(){
    const search = document.getElementById('notifSearch');
    const status = document.getElementById('notifStatus');
    const clearBtn = document.getElementById('clearNotifFilters');
    const openBtn = document.getElementById('openNotificationModal');
    const modal = document.getElementById('notificationModal');
    const closeBtn = document.getElementById('closeNotificationModal');
    const cancelBtn = document.getElementById('cancelNotificationModal');
    const form = document.getElementById('notificationForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-user]'));

    const apply = () => {
        const q = (search?.value || '').trim().toLowerCase();
        const s = (status?.value || '').toLowerCase();
        rows.forEach(r => {
            const a = (r.dataset.user || '').toLowerCase();
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
