(() => {
  const $ = id => document.getElementById(id);
  const csrf = document.querySelector('meta[name="_csrf"]')?.content;
  const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
  const headers = (json = false) => ({ ...(csrf && csrfHeader ? { [csrfHeader]: csrf } : {}), ...(json ? { 'Content-Type': 'application/json' } : {}) });
  const alertError = message => window.adminAlerts?.error(message) ?? window.Swal?.fire('Unable to complete request', message, 'error') ?? window.alert(message);
  const alertSuccess = (title, message) => window.adminAlerts?.success(title, message) ?? window.Swal?.fire({ icon: 'success', title, text: message, timer: 1100, showConfirmButton: false }) ?? Promise.resolve();

  const postModal = $('mealPostModal'), postForm = $('mealPostForm');
  let editingId = null;
  const closePost = () => { postModal.classList.remove('show'); postModal.setAttribute('aria-hidden', 'true'); postForm.reset(); editingId = null; };
  $('openMealPostModal').onclick = () => { editingId = null; $('mealPostModalTitle').textContent = 'New Meal Post'; document.querySelectorAll('.create-only').forEach(element => element.hidden = false); postModal.classList.add('show'); postModal.setAttribute('aria-hidden', 'false'); };
  $('closeMealPost').onclick = $('cancelMealPost').onclick = closePost;
  document.querySelectorAll('.edit-recipe').forEach(button => button.onclick = () => {
    const row = button.closest('tr'); editingId = row.dataset.id; $('mealPostModalTitle').textContent = 'Edit Meal Post';
    $('postName').value = row.dataset.name || ''; $('postDescription').value = row.dataset.description || '';
    $('postTime').value = row.dataset.time || ''; $('postServings').value = row.dataset.servings || '';
    $('postDifficulty').value = row.dataset.difficulty || ''; $('postStatus').value = row.dataset.status || 'DRAFT';
    document.querySelectorAll('.create-only').forEach(element => element.hidden = true); postModal.classList.add('show'); postModal.setAttribute('aria-hidden', 'false');
  });
  postForm.onsubmit = async event => {
    event.preventDefault(); const numberOrNull = id => $(id).value === '' ? null : Number($(id).value);
    const body = { authorId: editingId ? null : numberOrNull('postAuthor'), recipeName: $('postName').value.trim(), description: $('postDescription').value.trim(), cookingTimeMinutes: numberOrNull('postTime'), servings: numberOrNull('postServings'), difficulty: $('postDifficulty').value, status: $('postStatus').value };
    const response = await fetch(editingId ? `/admin/community-recipes/${editingId}` : '/admin/community-recipes', { method: editingId ? 'PUT' : 'POST', headers: headers(true), body: JSON.stringify(body) });
    const responseBody = await response.json().catch(() => ({})); if (!response.ok) return alertError(responseBody.message || 'The meal post could not be saved.');
    await alertSuccess('Meal post saved', 'Your changes have been saved.'); window.location.reload();
  };
  document.querySelectorAll('.delete-recipe').forEach(button => button.onclick = async () => {
    const row = button.closest('tr'); const result = await (window.Swal?.fire({ title: 'Delete meal post?', text: `“${row.dataset.name}” and its related Community data will be removed.`, icon: 'warning', showCancelButton: true, confirmButtonColor: '#d92d20', confirmButtonText: 'Delete' }) ?? Promise.resolve({ isConfirmed: window.confirm('Delete this meal post?') }));
    if (!result.isConfirmed) return; const response = await fetch(`/admin/community-recipes/${row.dataset.id}`, { method: 'DELETE', headers: headers() }); const responseBody = await response.json().catch(() => ({}));
    if (!response.ok) return alertError(responseBody.message || 'The meal post could not be deleted.'); await alertSuccess('Meal post deleted', 'The meal post was removed.'); window.location.reload();
  });

  const promoteModal = $('promoteModal'), promoteForm = $('promoteForm'); let recipeId = null;
  const closePromote = () => { promoteModal.classList.remove('show'); promoteModal.setAttribute('aria-hidden', 'true'); recipeId = null; promoteForm.reset(); };
  $('recipeSearch').addEventListener('input', event => { const term = event.target.value.trim().toLowerCase(); document.querySelectorAll('#recipeRows tr[data-search]').forEach(row => row.hidden = Boolean(term && !row.dataset.search.includes(term))); });
  document.querySelectorAll('.promote-button').forEach(button => button.addEventListener('click', () => { recipeId = button.dataset.recipeId; $('promoteText').textContent = `Add “${button.dataset.recipeName}” to the Meal catalog.`; promoteModal.classList.add('show'); promoteModal.setAttribute('aria-hidden', 'false'); }));
  $('closePromote').onclick = $('cancelPromote').onclick = closePromote;
  promoteForm.addEventListener('submit', async event => { event.preventDefault(); const categoryId = $('promoteCategory').value; if (!categoryId) return; const response = await fetch(`/admin/community-recipes/${recipeId}/promote?categoryId=${encodeURIComponent(categoryId)}`, { method: 'POST', headers: headers() }); const body = await response.json().catch(() => ({})); if (!response.ok) return alertError(body.message || 'Promotion failed.'); await alertSuccess('Recipe promoted', 'The recipe is now available in Meals.'); window.location.reload(); });
})();
