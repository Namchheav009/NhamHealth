(() => {
    const $ = id => document.getElementById(id);
    const tbody = $('postRows'), search = $('postSearch'), statusFilter = $('postStatus');
    const modal = $('postModal'), form = $('postForm');
    const token = document.querySelector('meta[name="_csrf"]')?.content;
    const header = document.querySelector('meta[name="_csrf_header"]')?.content;
    const rows = () => [...tbody.querySelectorAll('tr[data-id]')];
    const csrfHeaders = () => token && header ? { [header]: token } : {};
    const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'})[c]);
    const notify = (icon, title, text) => Swal.fire({icon,title,text,confirmButtonColor:'#078f4a'});

    function applyFilters() {
        const query = search.value.trim().toLowerCase(), status = statusFilter.value;
        rows().forEach(row => { row.hidden = !((!query || row.textContent.toLowerCase().includes(query)) && (!status || row.dataset.status === status)); });
    }
    function updateMetrics() {
        const all = rows(); $('totalPosts').textContent = all.length;
        $('activeAuthors').textContent = new Set(all.map(row => row.dataset.userId).filter(Boolean)).size;
        $('pendingReports').textContent = all.reduce((sum,row) => sum + Number(row.dataset.reports || 0), 0);
        all.forEach((row,index) => { row.cells[0].textContent = index + 1; });
    }
    const statusClass = status => `status-${status}`;
    function closeModal() { modal.classList.remove('show'); form.reset(); }
    function addRow(post) {
        tbody.querySelector('.empty-state')?.closest('tr')?.remove();
        const row = document.createElement('tr');
        Object.assign(row.dataset,{id:post.id,userId:post.userId,author:post.authorName,status:post.status,reports:post.reportCount});
        const updated = new Intl.DateTimeFormat(undefined,{day:'2-digit',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit'}).format(new Date(post.updatedAt));
        row.innerHTML = `<td></td><td><strong>${escapeHtml(post.authorName)}</strong><small>${escapeHtml(post.authorEmail)}</small></td><td class="caption-cell">${escapeHtml(post.caption)}</td><td><span class="visibility-pill">${escapeHtml(post.visibility)}</span></td><td><span class="status-pill ${statusClass(post.status)}">${escapeHtml(post.status)}</span></td><td>${post.commentCount}</td><td>${post.favoriteCount}</td><td>${post.reportCount}</td><td>${updated}</td><td><button class="btn-small moderate-post" type="button"><i class="fa-solid fa-shield-halved"></i> Status</button></td>`;
        tbody.prepend(row); updateMetrics(); applyFilters();
    }
    form.addEventListener('submit', async event => {
        event.preventDefault(); const submit=form.querySelector('[type="submit"]'); submit.disabled=true;
        try {
            const response=await fetch(form.action,{method:'POST',headers:csrfHeaders(),body:new FormData(form)});
            const data=await response.json().catch(()=>({})); if(!response.ok) throw new Error(data.message||'The post could not be created.');
            addRow(data); closeModal(); Swal.fire({icon:'success',title:'Post created',timer:1600,showConfirmButton:false});
        } catch(error) { notify('error','Create failed',error.message); } finally { submit.disabled=false; }
    });
    tbody.addEventListener('click', async event => {
        const button=event.target.closest('.moderate-post'); if(!button) return;
        const row=button.closest('tr[data-id]');
        const result=await Swal.fire({title:'Update post status',input:'select',inputOptions:{published:'Published',draft:'Draft',flagged:'Flagged'},inputValue:row.dataset.status,showCancelButton:true,confirmButtonText:'Update',confirmButtonColor:'#078f4a'});
        if(!result.isConfirmed) return;
        const body=new URLSearchParams({status:result.value});
        try {
            const response=await fetch(`/admin/posts/${row.dataset.id}/status`,{method:'PATCH',headers:{...csrfHeaders(),'Content-Type':'application/x-www-form-urlencoded'},body});
            const data=await response.json().catch(()=>({})); if(!response.ok) throw new Error(data.message||'The status could not be updated.');
            row.dataset.status=data.status; const pill=row.querySelector('.status-pill'); pill.className=`status-pill ${statusClass(data.status)}`; pill.textContent=data.status; applyFilters();
            Swal.fire({icon:'success',title:'Status updated',timer:1400,showConfirmButton:false});
        } catch(error) { notify('error','Update failed',error.message); }
    });
    $('openPostModal').addEventListener('click',()=>{modal.classList.add('show');$('postAuthor').focus();});
    $('closePostModal').addEventListener('click',closeModal); $('cancelPostModal').addEventListener('click',closeModal);
    modal.addEventListener('click',event=>{if(event.target===modal)closeModal();}); document.addEventListener('keydown',event=>{if(event.key==='Escape'&&modal.classList.contains('show'))closeModal();});
    search.addEventListener('input',applyFilters); statusFilter.addEventListener('change',applyFilters);
    $('clearPostFilters').addEventListener('click',()=>{search.value='';statusFilter.value='';applyFilters();}); $('refreshPosts').addEventListener('click',()=>location.reload());
    $('exportPosts').addEventListener('click',()=>{
        const data=[['Author','Post','Visibility','Status','Comments','Favorites','Reports','Updated'],...rows().filter(row=>!row.hidden).map(row=>[...row.cells].slice(1,9).map(cell=>cell.innerText.trim()))];
        const csv=data.map(values=>values.map(value=>`"${value.replace(/"/g,'""')}"`).join(',')).join('\n'); const link=document.createElement('a'); link.href=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'})); link.download=`posts-${new Date().toISOString().slice(0,10)}.csv`; link.click(); URL.revokeObjectURL(link.href); Swal.fire({icon:'success',title:'Export ready',timer:1200,showConfirmButton:false});
    });
    updateMetrics(); applyFilters();
})();
