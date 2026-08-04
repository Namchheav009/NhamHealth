document.addEventListener('DOMContentLoaded', function(){
  const openBtn = document.getElementById('openServingModal');
  const closeBtn = document.getElementById('closeServingModal');
  const cancelBtn = document.getElementById('cancelServingModal');
  const modal = document.getElementById('servingModal');
  function showModal(){ modal?.classList.add('show'); form?.querySelector('input')?.focus(); }
  function hideModal(){ modal?.classList.remove('show'); form?.reset(); }

  if(openBtn) openBtn.addEventListener('click', showModal);
  if(closeBtn) closeBtn.addEventListener('click', hideModal);
  if(cancelBtn) cancelBtn.addEventListener('click', hideModal);
  modal?.addEventListener('click', (e)=>{ if(e.target === modal) hideModal(); });

  // Filtering/search + client-side pagination
  const rows = Array.from(document.querySelectorAll('tbody tr'));
  const typeFilter = document.getElementById('typeFilter');
  const statusFilter = document.getElementById('statusFilter');
  const searchInput = document.getElementById('servingSearch');
  const clearBtn = document.getElementById('clearServingFilter');

  const pagePrev = document.getElementById('pagePrev');
  const pageNext = document.getElementById('pageNext');
  const pageNumbers = document.getElementById('pageNumbers');
  const pageStart = document.getElementById('pageStart');
  const pageEnd = document.getElementById('pageEnd');
  const pageTotal = document.getElementById('pageTotal');

  let currentPage = 1;
  const pageSize = 10;

  function matchesFilter(r, type, status, q){
    const name = (r.dataset.name||'').toLowerCase();
    const rowType = (r.dataset.type||'').toLowerCase();
    const rowStatus = (r.dataset.status||'').toLowerCase();
    if(type !== 'all'){
      if(type === 'volume' && (rowType.includes('g') || rowType.includes('gram') || rowType.includes('kg'))) return false;
      if(type === 'weight' && !(rowType.includes('g') || rowType.includes('gram') || rowType.includes('kg') || rowType.includes('kg'))) return false;
    }
    if(status !== 'all' && rowStatus !== status) return false;
    if(q && !name.includes(q)) return false;
    return true;
  }

  function getFilteredRows(){
    const type = typeFilter ? typeFilter.value : 'all';
    const status = statusFilter ? statusFilter.value : 'all';
    const q = searchInput ? searchInput.value.trim().toLowerCase() : '';
    return rows.filter(r => matchesFilter(r, type, status, q));
  }

  function renderPagination(filtered){
    const total = filtered.length;
    const totalPages = Math.max(1, Math.ceil(total / pageSize));
    if(currentPage > totalPages) currentPage = totalPages;

    // build page numbers
    pageNumbers.innerHTML = '';
    for(let i=1;i<=totalPages;i++){
      const btn = document.createElement('button');
      btn.className = 'page-number' + (i===currentPage ? ' active' : '');
      btn.textContent = i;
      btn.addEventListener('click', ()=>{ currentPage = i; renderPage(); });
      pageNumbers.appendChild(btn);
    }

    pagePrev.disabled = currentPage === 1;
    pageNext.disabled = currentPage === totalPages;

    const start = (currentPage-1)*pageSize + 1;
    const end = Math.min(total, currentPage*pageSize);
    pageStart.textContent = total===0?0:start;
    pageEnd.textContent = end;
    pageTotal.textContent = total;
  }

  function renderPage(){
    const filtered = getFilteredRows();
    renderPagination(filtered);

    // hide all rows first
    rows.forEach(r=> r.style.display = 'none');

    const startIdx = (currentPage-1)*pageSize;
    const pageRows = filtered.slice(startIdx, startIdx + pageSize);
    pageRows.forEach(r=> r.style.display = '');
  }

  function applyFilters(){ currentPage = 1; renderPage(); }

  if(typeFilter) typeFilter.addEventListener('change', applyFilters);
  if(statusFilter) statusFilter.addEventListener('change', applyFilters);

  // debounce helper
  function debounce(fn, wait){ let t; return function(...args){ clearTimeout(t); t = setTimeout(()=>fn.apply(this,args), wait); }; }
  if(searchInput) searchInput.addEventListener('input', debounce(applyFilters, 250));
  if(clearBtn) clearBtn.addEventListener('click', function(){ if(typeFilter) typeFilter.value='all'; if(statusFilter) statusFilter.value='all'; if(searchInput) searchInput.value=''; applyFilters(); });

  if(pagePrev) pagePrev.addEventListener('click', ()=>{ if(currentPage>1){ currentPage--; renderPage(); }});
  if(pageNext) pageNext.addEventListener('click', ()=>{ const filtered = getFilteredRows(); const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize)); if(currentPage<totalPages){ currentPage++; renderPage(); }});


  // initial render
  renderPage();

  // Placeholder submit handler
  const form = document.getElementById('servingForm');
  if(form) form.addEventListener('submit', function(e){ e.preventDefault(); alert('Save endpoint not implemented yet.'); hideModal(); });
});
