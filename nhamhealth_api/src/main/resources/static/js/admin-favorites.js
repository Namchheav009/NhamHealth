(() => {
    const tabFood = document.getElementById('tabFood');
    const tabPost = document.getElementById('tabPost');
    const foodPanel = document.getElementById('foodPanel');
    const postPanel = document.getElementById('postPanel');

    function showFood() {
        foodPanel.style.display = '';
        postPanel.style.display = 'none';
        tabFood.classList.add('btn-primary');
        tabPost.classList.remove('btn-primary');
    }

    function showPost() {
        foodPanel.style.display = 'none';
        postPanel.style.display = '';
        tabPost.classList.add('btn-primary');
        tabFood.classList.remove('btn-primary');
    }

    tabFood?.addEventListener('click', (e) => { e.preventDefault(); showFood(); });
    tabPost?.addEventListener('click', (e) => { e.preventDefault(); showPost(); });

    // default: show post favorites
    document.addEventListener('DOMContentLoaded', () => { showPost(); });
})();
