(() => {
    const rows = [...document.querySelectorAll('tbody tr[data-id]')];
    const search = document.getElementById('mealLogSearch');
    const type = document.getElementById('typeFilter');
    const method = document.getElementById('methodFilter');
    const pageNumbers = document.getElementById('pageNumbers');
    const prev = document.getElementById('pagePrev');
    const next = document.getElementById('pageNext');
    const pageSize = 10;
    let page = 1;
    let filtered = rows;

    const setText = (id, value) => { const node = document.getElementById(id); if (node) node.textContent = String(value); };
    function applyFilters() {
        const term = (search?.value || '').trim().toLowerCase();
        filtered = rows.filter(row => (!term || (row.dataset.search || '').includes(term)) &&
            (!type || type.value === 'all' || row.dataset.type === type.value) &&
            (!method || method.value === 'all' || row.dataset.method === method.value));
    }
    function render() {
        applyFilters();
        const pages = Math.max(1, Math.ceil(filtered.length / pageSize));
        page = Math.min(page, pages);
        const start = (page - 1) * pageSize;
        const displayed = new Set(filtered.slice(start, start + pageSize));
        rows.forEach(row => { row.hidden = !displayed.has(row); });
        setText('pageStart', filtered.length ? start + 1 : 0); setText('pageEnd', Math.min(start + pageSize, filtered.length));
        setText('visibleLogCount', filtered.length); setText('filteredLogTotal', filtered.length);
        if (prev) prev.disabled = page === 1; if (next) next.disabled = page === pages || !filtered.length;
        if (pageNumbers) { pageNumbers.replaceChildren(); for (let n=1;n<=pages;n+=1) { const button=document.createElement('button'); button.type='button'; button.className=`page-btn${n===page?' active':''}`; button.textContent=String(n); button.addEventListener('click',()=>{page=n;render();}); pageNumbers.appendChild(button); } }
    }
    [search,type,method].forEach(control => control?.addEventListener(control===search?'input':'change',()=>{page=1;render();}));
    document.getElementById('clearMealLogFilters')?.addEventListener('click',()=>{ if(search)search.value='';if(type)type.value='all';if(method)method.value='all';page=1;render(); });
    prev?.addEventListener('click',()=>{if(page>1){page-=1;render();}}); next?.addEventListener('click',()=>{if(page*pageSize<filtered.length){page+=1;render();}});
    document.getElementById('refreshMealLogs')?.addEventListener('click',()=>window.location.reload());
    document.getElementById('exportMealLogs')?.addEventListener('click',()=>{ applyFilters(); const headings=['Food','User','Meal type','Quantity','Entry method','Logged at','Notes']; const values=filtered.map(row=>[...row.cells].slice(0,7).map(cell=>cell.innerText.trim())); const escape=value=>`"${String(value).replaceAll('"','""')}"`; const csv=[headings,...values].map(line=>line.map(escape).join(',')).join('\r\n'); const link=document.createElement('a');link.href=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'}));link.download='meal-logs.csv';link.click();URL.revokeObjectURL(link.href); });
    document.addEventListener('click',async event=>{ const button=event.target.closest('.delete-meal-log');if(!button)return;const row=button.closest('tr[data-id]');if(!row||!confirm('Delete this meal log permanently?'))return;const token=document.querySelector('meta[name="_csrf"]')?.content;const header=document.querySelector('meta[name="_csrf_header"]')?.content;button.disabled=true;try{const headers=header&&token?{[header]:token}:{};const response=await fetch(`/admin/meal-logs/${row.dataset.id}`,{method:'DELETE',headers});if(!response.ok)throw new Error('The meal log could not be deleted.');location.reload();}catch(error){button.disabled=false;alert(error.message||'The meal log could not be deleted.');}});
    render();
})();
