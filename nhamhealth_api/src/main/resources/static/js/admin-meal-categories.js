(() => {
    const searchInput = document.getElementById("categorySearch");
    const statusFilter = document.getElementById("statusFilter");
    const clearFiltersButton = document.getElementById("clearCategoryFilter");
    const rowsBox = document.getElementById("categoryRows");
    const modal = document.getElementById("categoryModal");
    const form = document.getElementById("categoryForm");
    const title = document.getElementById("categoryModalTitle");
    const subtitle = document.getElementById("categoryModalText");
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    let editingCategoryId = null;

    function categoryRows() {
        return [...rowsBox.querySelectorAll("tr[data-id]")];
    }

    function applyFilters() {
        const keyword = (searchInput.value || "").trim().toLowerCase();
        const status = statusFilter.value;
        categoryRows().forEach(row => {
            const matchesName = !keyword || row.dataset.name.toLowerCase().includes(keyword);
            const matchesStatus = status === "all" || row.dataset.status === status;
            row.hidden = !(matchesName && matchesStatus);
        });
    }

    function nextDisplayOrder() {
        return categoryRows().reduce((maximum, row) => Math.max(maximum, Number(row.dataset.order) || 0), 0) + 1;
    }

    function openCreateModal() {
        editingCategoryId = null;
        form.reset();
        document.getElementById("categoryStatus").value = "true";
        document.getElementById("categoryOrder").value = nextDisplayOrder();
        title.textContent = "Add Meal Category";
        subtitle.textContent = "Enter category information for your menu catalog.";
        modal.classList.add("show");
        document.getElementById("categoryName").focus();
    }

    function openEditModal(row) {
        editingCategoryId = row.dataset.id;
        form.reset();
        document.getElementById("categoryName").value = row.dataset.name;
        document.getElementById("categoryStatus").value = row.dataset.status === "active" ? "true" : "false";
        document.getElementById("categoryOrder").value = row.dataset.order;
        document.getElementById("categoryDescription").value = row.dataset.description || "";
        title.textContent = "Edit Meal Category";
        subtitle.textContent = "Update the category shown in your meal catalog.";
        modal.classList.add("show");
        document.getElementById("categoryName").focus();
    }

    function closeModal() {
        modal.classList.remove("show");
        editingCategoryId = null;
        form.reset();
    }

    async function request(url, method, payload) {
        const response = await fetch(url, {
            method,
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {})
            },
            body: payload ? JSON.stringify(payload) : undefined
        });
        if (!response.ok) {
            const body = await response.json().catch(() => ({}));
            throw new Error(body.message || "Unable to save meal category");
        }
        return response.status === 204 ? null : response.json();
    }

    searchInput.addEventListener("input", applyFilters);
    statusFilter.addEventListener("change", applyFilters);
    clearFiltersButton.addEventListener("click", () => {
        searchInput.value = "";
        statusFilter.value = "all";
        applyFilters();
    });

    document.getElementById("openCategoryModal").addEventListener("click", openCreateModal);
    document.getElementById("closeCategoryModal").addEventListener("click", closeModal);
    document.getElementById("cancelCategoryModal").addEventListener("click", closeModal);
    modal.addEventListener("click", event => {
        if (event.target === modal) closeModal();
    });

    rowsBox.addEventListener("click", async event => {
        const button = event.target.closest("button[data-action]");
        if (!button) return;
        const row = button.closest("tr[data-id]");
        if (button.dataset.action === "edit") {
            openEditModal(row);
            return;
        }
        if (!window.confirm(`Delete the ${row.dataset.name} category?`)) return;
        try {
            await request(`/admin/meal-categories/${row.dataset.id}`, "DELETE");
            window.location.reload();
        } catch (error) {
            window.alert(error.message);
        }
    });

    form.addEventListener("submit", async event => {
        event.preventDefault();
        const data = Object.fromEntries(new FormData(form).entries());
        const payload = {
            categoryName: data.categoryName.trim(),
            description: data.description.trim(),
            active: data.categoryStatus === "true",
            sortOrder: Number(data.sortOrder)
        };
        try {
            await request(
                editingCategoryId ? `/admin/meal-categories/${editingCategoryId}` : "/admin/meal-categories",
                editingCategoryId ? "PUT" : "POST",
                payload);
            window.location.reload();
        } catch (error) {
            window.alert(error.message);
        }
    });
})();
