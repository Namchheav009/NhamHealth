(() => {
    const searchInput = document.getElementById("ingredientSearch");
    const typeFilter = document.getElementById("categoryFilter");
    const clearButton = document.getElementById("clearIngredientFilter");
    const rowsBox = document.getElementById("ingredientRows");
    const modal = document.getElementById("ingredientModal");
    const form = document.getElementById("ingredientForm");
    const imageFile = document.getElementById("ingredientImageFile");
    const imageHelp = document.getElementById("ingredientImageHelp");
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    let editingIngredientId = null;
    let currentImageUrl = null;

    function rows() {
        return [...rowsBox.querySelectorAll("tr[data-id]")];
    }

    function populateTypes() {
        const types = [...new Set(rows().map(row => row.dataset.type).filter(Boolean))].sort((a, b) => a.localeCompare(b));
        const selected = typeFilter.value;
        typeFilter.replaceChildren(new Option("All Types", "all"));
        const datalist = document.getElementById("ingredientTypes");
        datalist.replaceChildren();
        types.forEach(type => {
            typeFilter.add(new Option(type, type.toLowerCase()));
            datalist.appendChild(new Option(type));
        });
        typeFilter.value = [...typeFilter.options].some(option => option.value === selected) ? selected : "all";
    }

    function applyFilters() {
        const keyword = searchInput.value.trim().toLowerCase();
        const type = typeFilter.value;
        rows().forEach(row => {
            const matchesName = !keyword || row.dataset.name.toLowerCase().includes(keyword);
            const matchesType = type === "all" || (row.dataset.type || "").toLowerCase() === type;
            row.hidden = !(matchesName && matchesType);
        });
    }

    function openCreateModal() {
        editingIngredientId = null;
        currentImageUrl = null;
        form.reset();
        imageFile.required = true;
        imageHelp.textContent = "JPG, PNG, or WebP. Maximum 5 MB.";
        document.getElementById("ingredientModalTitle").textContent = "Add Ingredient";
        document.getElementById("ingredientModalText").textContent = "Enter ingredient information for your catalog.";
        document.getElementById("saveIngredientButton").textContent = "Save Ingredient";
        modal.classList.add("show");
        document.getElementById("ingredientName").focus();
    }

    function openEditModal(row) {
        editingIngredientId = row.dataset.id;
        currentImageUrl = row.dataset.imageUrl || null;
        form.reset();
        form.elements.ingredientName.value = row.dataset.name;
        form.elements.ingredientType.value = row.dataset.type || "";
        form.elements.defaultUnit.value = row.dataset.unit || "";
        form.elements.description.value = row.dataset.description || "";
        imageFile.required = false;
        imageHelp.textContent = "Leave empty to keep the current ingredient image. JPG, PNG, or WebP; maximum 5 MB.";
        document.getElementById("ingredientModalTitle").textContent = "Edit Ingredient";
        document.getElementById("ingredientModalText").textContent = "Update this ingredient in the catalog.";
        document.getElementById("saveIngredientButton").textContent = "Update Ingredient";
        modal.classList.add("show");
        document.getElementById("ingredientName").focus();
    }

    function closeModal() {
        modal.classList.remove("show");
        form.reset();
        editingIngredientId = null;
        currentImageUrl = null;
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
            throw new Error(body.message || "Unable to save ingredient");
        }
        return response.status === 204 ? null : response.json();
    }

    async function uploadIngredientImage(file) {
        const data = new FormData();
        data.append("file", file);
        const response = await fetch("/admin/ingredient-images", {
            method: "POST",
            headers: csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {},
            body: data
        });
        const body = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(body.message || "Unable to upload ingredient image");
        return body.imageUrl;
    }

    searchInput.addEventListener("input", applyFilters);
    typeFilter.addEventListener("change", applyFilters);
    clearButton.addEventListener("click", () => {
        searchInput.value = "";
        typeFilter.value = "all";
        applyFilters();
    });
    document.getElementById("openIngredientModal").addEventListener("click", openCreateModal);
    document.getElementById("closeIngredientModal").addEventListener("click", closeModal);
    document.getElementById("cancelIngredientModal").addEventListener("click", closeModal);
    modal.addEventListener("click", event => {
        if (event.target === modal) closeModal();
    });

    rowsBox.addEventListener("click", async event => {
        const button = event.target.closest("button[data-action]");
        if (!button) return;
        const row = button.closest("tr[data-id]");
        if (button.dataset.action === "edit") return openEditModal(row);
        if (!window.confirm(`Delete the ${row.dataset.name} ingredient?`)) return;
        try {
            await request(`/admin/ingredients/${row.dataset.id}`, "DELETE");
            window.location.reload();
        } catch (error) {
            window.alert(error.message);
        }
    });

    form.addEventListener("submit", async event => {
        event.preventDefault();
        const formData = new FormData(form);
        const selectedImage = formData.get("imageFile");
        const payload = {
            ingredientName: formData.get("ingredientName").trim(),
            ingredientType: formData.get("ingredientType").trim(),
            defaultUnit: formData.get("defaultUnit").trim(),
            description: formData.get("description").trim(),
            imageUrl: currentImageUrl
        };
        try {
            if (selectedImage?.size) payload.imageUrl = await uploadIngredientImage(selectedImage);
            await request(
                editingIngredientId ? `/admin/ingredients/${editingIngredientId}` : "/admin/ingredients",
                editingIngredientId ? "PUT" : "POST",
                payload);
            window.location.reload();
        } catch (error) {
            window.alert(error.message);
        }
    });

    document.getElementById("exportIngredients").addEventListener("click", () => {
        const header = ["Ingredient", "Type", "Default unit", "Description", "Image URL"];
        const data = rows().map(row => [row.dataset.name, row.dataset.type, row.dataset.unit, row.dataset.description, row.dataset.imageUrl]);
        const csv = [header, ...data].map(row => row.map(value => `"${String(value || "").replaceAll('"', '""')}"`).join(",")).join("\n");
        const link = document.createElement("a");
        link.href = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
        link.download = "nham-health-ingredients.csv";
        link.click();
        URL.revokeObjectURL(link.href);
    });

    populateTypes();
})();
