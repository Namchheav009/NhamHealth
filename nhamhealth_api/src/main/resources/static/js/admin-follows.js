(function(){
    const search = document.getElementById('followSearch');
    const status = document.getElementById('followStatus');
    const clearBtn = document.getElementById('clearFollowFilters');
    const openBtn = document.getElementById('openFollowModal');
    const modal = document.getElementById('followModal');
    const closeBtn = document.getElementById('closeFollowModal');
    const cancelBtn = document.getElementById('cancelFollowModal');
    const form = document.getElementById('followForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-follower]'));

    const apply = () => {
        const q = (search?.value || '').trim().toLowerCase();
        const s = (status?.value || '').toLowerCase();
        rows.forEach(r => {
            const a = (r.dataset.follower || '').toLowerCase();
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
    // let the form submit normally to the server (no client-side interception)
    apply();
})();
