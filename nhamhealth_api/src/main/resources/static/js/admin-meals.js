const rowsBox = document.getElementById("mealRows");
const resultText = document.getElementById("resultText");
const showingText = document.getElementById("showingText");
const totalMeals = document.getElementById("totalMeals");
const averageRating = document.getElementById("averageRating");
const favoritesSaved = document.getElementById("favoritesSaved");
const modal = document.getElementById("mealModal");
const form = document.getElementById("mealForm");
const recipeStepsBox = document.getElementById("recipeSteps");
const mealImageFile = document.getElementById("mealImageFile");
const mealImageHelp = document.getElementById("mealImageHelp");
const mealImagePreview = document.getElementById("mealImagePreview");
const mealImagePreviewImage = document.getElementById("mealImagePreviewImage");
const mealImagePreviewTitle = document.getElementById("mealImagePreviewTitle");
const mealImagePreviewText = document.getElementById("mealImagePreviewText");
const openMealImageViewer = document.getElementById("openMealImageViewer");
const mealImageViewer = document.getElementById("mealImageViewer");
const mealImageViewerImage = document.getElementById("mealImageViewerImage");
const ingredientSearchInput = document.getElementById("ingredientSearchInput");
const ingredientSearchResults = document.getElementById("ingredientSearchResults");
const selectedMealIngredients = document.getElementById("selectedMealIngredients");
const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;

const pagination = document.getElementById("mealPagination");
pagination.innerHTML = `
    <button id="previousMealPage" class="admin-page-button admin-page-previous" type="button" aria-label="Previous page">Previous</button>
    <div id="mealPageNumbers" class="admin-page-numbers"></div>
    <button id="nextMealPage" class="admin-page-button admin-page-next" type="button" aria-label="Next page">Next</button>
    <label class="admin-page-jump">Page <select id="mealPageJump" aria-label="Select meal page"></select><span id="mealPageTotal"></span></label>`;
const previousMealPage = document.getElementById("previousMealPage");
const nextMealPage = document.getElementById("nextMealPage");
const mealPageNumbers = document.getElementById("mealPageNumbers");
const mealPageJump = document.getElementById("mealPageJump");
const mealPageTotal = document.getElementById("mealPageTotal");

let meals = [];
let mealPage = 0;
let mealPageData = null;
let mealSummary = null;
let editingMealId = null;
let currentMainImageUrl = null;
let previewObjectUrl = null;
let ingredientSearchMatches = [];
let selectedIngredients = [];
let ingredientSearchTimer = null;
let mealFilterTimer = null;

const escapeHtml = value => String(value ?? "").replace(/[&<>'"]/g, character => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", "\"": "&quot;"
}[character]));

const tagClass = tag => {
    const name = tag.toLowerCase();
    if (["high protein", "high fiber"].includes(name)) return "tag-orange";
    if (["gluten-free", "vegan", "vegetarian"].includes(name)) return "tag-green";
    if (["low carb", "omega-3"].includes(name)) return "tag-blue";
    return "tag-purple";
};

const statusClass = status => status.toLowerCase() === "published" ? "status-published" : "status-draft";

function clearImagePreview() {
    if (previewObjectUrl) {
        URL.revokeObjectURL(previewObjectUrl);
        previewObjectUrl = null;
    }
    mealImagePreview.hidden = true;
    mealImagePreviewImage.removeAttribute("src");
}

function showImagePreview(imageUrl, title, text) {
    clearImagePreview();
    if (!imageUrl) return;
    mealImagePreviewImage.src = imageUrl;
    mealImagePreviewTitle.textContent = title;
    mealImagePreviewText.textContent = text;
    mealImagePreview.hidden = false;
}

function openImageViewer() {
    if (!mealImagePreviewImage.src) return;
    mealImageViewerImage.src = mealImagePreviewImage.src;
    mealImageViewer.hidden = false;
    mealImageViewer.setAttribute("aria-hidden", "false");
}

function closeImageViewer() {
    mealImageViewer.hidden = true;
    mealImageViewer.setAttribute("aria-hidden", "true");
    mealImageViewerImage.removeAttribute("src");
}

function drawRows(list) {
    rowsBox.innerHTML = "";
    if (!list.length) {
        rowsBox.innerHTML = '<tr><td colspan="11" style="padding:40px;text-align:center">No meals found.</td></tr>';
    } else {
        list.forEach(meal => {
            const tags = (meal.tags || []).map(tag => `<span class="pill ${tagClass(tag)}">${escapeHtml(tag)}</span>`).join(" ");
            const thumbnail = meal.mainImageUrl
                ? `<img src="${escapeHtml(meal.thumbnailUrl || meal.mainImageUrl)}" alt="${escapeHtml(meal.mealName)}" loading="lazy" width="50" height="50">`
                : `<i class="bi ${escapeHtml(meal.iconClass || "bi-egg-fried")}"></i>`;
            rowsBox.insertAdjacentHTML("beforeend", `
                <tr>
                    <td><div class="meal-cell"><div class="meal-thumb">${thumbnail}</div><div><strong>${escapeHtml(meal.mealName)}</strong><small>${escapeHtml(meal.category)} meal</small></div></div></td>
                    <td>${escapeHtml(meal.category)}</td>
                    <td>${escapeHtml(meal.calories)}</td>
                    <td>${escapeHtml(meal.servingSize)}</td>
                    <td>${tags}</td>
                    <td><i class="bi bi-star-fill" style="color:#f5a623"></i> ${escapeHtml(meal.rating)}</td>
                    <td>${Number(meal.reviewCount || 0).toLocaleString()}</td>
                    <td>${Number(meal.favorites || 0).toLocaleString()}</td>
                    <td><span class="pill ${statusClass(meal.status)}">${escapeHtml(meal.status)}</span></td>
                    <td>${escapeHtml(meal.updatedDate)}</td>
                    <td class="image-url-cell" title="${escapeHtml(meal.mainImageUrl)}">${escapeHtml(meal.mainImageUrl || "—")}</td>
                    <td><div class="meal-actions"><button class="action" data-action="edit" data-meal-id="${meal.mealId}" type="button" aria-label="Edit meal"><i class="bi bi-pencil"></i></button><button class="action danger-action" data-action="delete" data-meal-id="${meal.mealId}" type="button" aria-label="Delete meal"><i class="bi bi-trash3"></i></button></div></td>
                </tr>`);
        });
    }
    const totalMeals = mealPageData?.totalElements ?? meals.length;
    const firstResult = list.length ? mealPage * 10 + 1 : 0;
    const lastResult = list.length ? firstResult + list.length - 1 : 0;
    resultText.textContent = `${totalMeals} meal${totalMeals === 1 ? "" : "s"}`;
    showingText.textContent = list.length
        ? `Showing ${firstResult} to ${lastResult} of ${totalMeals} meals`
        : "No meals to show";
}

function updateSummary() {
    totalMeals.textContent = Number(mealSummary?.totalMeals ?? mealPageData?.totalElements ?? meals.length).toLocaleString();
    averageRating.textContent = `${Number(mealSummary?.averageRating ?? 0).toFixed(1)} / 5`;
    favoritesSaved.textContent = Number(mealSummary?.favoriteCount ?? 0).toLocaleString();
}

function filterMeals() {
    mealPage = 0;
    loadMeals(0);
}

function updatePagination() {
    const totalPages = mealPageData?.totalPages ?? 0;
    const currentPage = totalPages ? mealPage + 1 : 1;
    const pagesToShow = totalPages <= 5
        ? Array.from({ length: totalPages }, (_, index) => index + 1)
        : currentPage <= 3 ? [1, 2, 3, totalPages]
            : currentPage >= totalPages - 2 ? [1, totalPages - 2, totalPages - 1, totalPages]
                : [1, currentPage - 1, currentPage, currentPage + 1, totalPages];
    mealPageNumbers.replaceChildren();
    let previousPage = 0;
    pagesToShow.forEach(pageNumber => {
        if (pageNumber > previousPage + 1) {
            const ellipsis = document.createElement("span");
            ellipsis.className = "admin-pagination-ellipsis";
            ellipsis.textContent = "\u2026";
            mealPageNumbers.appendChild(ellipsis);
        }
        const button = document.createElement("button");
        button.type = "button";
        button.className = `admin-page-button${pageNumber === currentPage ? " active" : ""}`;
        button.textContent = String(pageNumber);
        button.setAttribute("aria-label", `Page ${pageNumber}`);
        if (pageNumber === currentPage) button.setAttribute("aria-current", "page");
        button.addEventListener("click", () => loadMeals(pageNumber - 1));
        mealPageNumbers.appendChild(button);
        previousPage = pageNumber;
    });
    mealPageJump.replaceChildren();
    for (let pageNumber = 1; pageNumber <= totalPages; pageNumber += 1) {
        const option = document.createElement("option");
        option.value = String(pageNumber - 1);
        option.textContent = String(pageNumber);
        option.selected = pageNumber === currentPage;
        mealPageJump.appendChild(option);
    }
    mealPageJump.disabled = totalPages <= 1;
    mealPageTotal.textContent = `of ${totalPages}`;
    previousMealPage.disabled = !mealPageData || mealPageData.first;
    nextMealPage.disabled = !mealPageData || mealPageData.last;
}

async function loadMeals(page = mealPage) {
    try {
        const params = new URLSearchParams({ page: String(Math.max(page, 0)) });
        const filters = {
            search: document.getElementById("searchInput").value.trim(),
            category: document.getElementById("categoryFilter").value,
            status: document.getElementById("statusFilter").value,
            tag: document.getElementById("tagFilter").value
        };
        Object.entries(filters).forEach(([name, value]) => {
            if (value) params.set(name, value);
        });
        const response = await fetch(`/admin/meals/data?${params}`);
        if (!response.ok) throw new Error("Unable to load meals");
        mealPageData = await response.json();
        const summaryResponse = await fetch("/admin/meals/summary");
        if (!summaryResponse.ok) throw new Error("Unable to load meal summary");
        mealSummary = await summaryResponse.json();
        if (!mealPageData.content.length && mealPageData.totalPages && page >= mealPageData.totalPages) {
            return loadMeals(mealPageData.totalPages - 1);
        }
        mealPage = mealPageData.number;
        meals = mealPageData.content;
        updateSummary();
        drawRows(meals);
        updatePagination();
    } catch (error) {
        rowsBox.innerHTML = '<tr><td colspan="11" style="padding:40px;text-align:center">Unable to load meals from the API.</td></tr>';
        console.error(error);
    }
}

function recipeStepMarkup(number) {
    return `<article class="recipe-step" data-recipe-step><div class="recipe-step-title"><strong>Step ${number}</strong><button class="step-remove" type="button" aria-label="Remove cooking step"><i class="bi bi-trash3"></i></button></div><input data-step-title type="text" maxlength="150" placeholder="Step title (optional)"><textarea data-step-instruction maxlength="255" required placeholder="Describe what to do in this step..."></textarea><input data-step-image type="file" accept="image/jpeg,image/png,image/webp" required aria-label="Image for step ${number}"><div class="recipe-step-image-preview" data-step-image-preview hidden><img data-step-image-preview-image alt="Cooking step image preview"><div><strong data-step-image-preview-title>Current step image</strong><span data-step-image-preview-text>This image is currently shown to users.</span></div></div></article>`;
}

function clearStepImagePreview(step) {
    if (step.dataset.previewObjectUrl) {
        URL.revokeObjectURL(step.dataset.previewObjectUrl);
        delete step.dataset.previewObjectUrl;
    }
    const preview = step.querySelector("[data-step-image-preview]");
    if (!preview) return;
    preview.hidden = true;
    preview.querySelector("[data-step-image-preview-image]").removeAttribute("src");
}

function showStepImagePreview(step, imageUrl, title, text) {
    clearStepImagePreview(step);
    if (!imageUrl) return;
    const preview = step.querySelector("[data-step-image-preview]");
    if (!preview) return;
    preview.querySelector("[data-step-image-preview-image]").src = imageUrl;
    preview.querySelector("[data-step-image-preview-title]").textContent = title;
    preview.querySelector("[data-step-image-preview-text]").textContent = text;
    preview.hidden = false;
}

function clearAllStepImagePreviews() {
    recipeStepsBox.querySelectorAll("[data-recipe-step]").forEach(clearStepImagePreview);
}

function updateRecipeStepLabels() {
    const steps = [...recipeStepsBox.querySelectorAll("[data-recipe-step]")];
    steps.forEach((step, index) => {
        step.querySelector("strong").textContent = `Step ${index + 1}`;
        step.querySelector(".step-remove").disabled = steps.length === 1;
    });
}

function appendRecipeStep(step = {}) {
    recipeStepsBox.insertAdjacentHTML("beforeend", recipeStepMarkup(recipeStepsBox.children.length + 1));
    const element = recipeStepsBox.lastElementChild;
    element.querySelector("[data-step-title]").value = step.title || "";
    element.querySelector("[data-step-instruction]").value = step.instruction || "";
    const imageInput = element.querySelector("[data-step-image]");
    element.dataset.imageUrl = step.imageUrl || "";
    imageInput.required = !step.imageUrl;
    if (step.imageUrl) {
        imageInput.title = "Choose a new file only to replace the current step image.";
        showStepImagePreview(element, step.imageUrl, "Current step image", "This image is currently shown to users.");
    }
    updateRecipeStepLabels();
}

function resetRecipeSteps() {
    clearAllStepImagePreviews();
    recipeStepsBox.innerHTML = "";
    appendRecipeStep();
}

function renderSelectedIngredients() {
    if (!selectedIngredients.length) {
        selectedMealIngredients.innerHTML = '<p class="no-selected-ingredients">No ingredients selected yet.</p>';
        return;
    }
    selectedMealIngredients.innerHTML = selectedIngredients.map((ingredient, index) => `
        <article class="selected-ingredient" data-ingredient-id="${ingredient.ingredientId}">
            <div class="selected-ingredient-name"><strong>${escapeHtml(ingredient.ingredientName)}</strong><span>${escapeHtml(ingredient.ingredientType || "Ingredient")}</span></div>
            <label>Quantity<input data-ingredient-quantity type="number" min="0" step="0.01" value="${ingredient.quantity ?? ""}" placeholder="Optional"></label>
            <label>Unit<input data-ingredient-unit type="text" maxlength="30" value="${escapeHtml(ingredient.unit ?? ingredient.defaultUnit ?? "")}" placeholder="e.g. g"></label>
            <label class="ingredient-note">Preparation note<input data-ingredient-note type="text" maxlength="150" value="${escapeHtml(ingredient.preparationNote ?? "")}" placeholder="e.g. finely chopped"></label>
            <button class="step-remove remove-ingredient" data-remove-ingredient="${index}" type="button" aria-label="Remove ${escapeHtml(ingredient.ingredientName)}"><i class="bi bi-trash3"></i></button>
        </article>`).join("");
}

function renderIngredientSearchResults() {
    if (!ingredientSearchMatches.length) {
        ingredientSearchResults.innerHTML = '<p class="ingredient-search-empty">No ingredients found.</p>';
        return;
    }
    ingredientSearchResults.innerHTML = ingredientSearchMatches.map(ingredient => {
        const alreadySelected = selectedIngredients.some(item => item.ingredientId === ingredient.ingredientId);
        return `<button type="button" role="option" class="ingredient-search-result" data-ingredient-id="${ingredient.ingredientId}" ${alreadySelected ? "disabled" : ""}><strong>${escapeHtml(ingredient.ingredientName)}</strong><span>${escapeHtml(ingredient.ingredientType || "Ingredient")}${ingredient.defaultUnit ? ` · ${escapeHtml(ingredient.defaultUnit)}` : ""}${alreadySelected ? " · Added" : ""}</span></button>`;
    }).join("");
}

async function loadIngredientSearchResults(query = "") {
    try {
        const response = await fetch(`/admin/ingredients/search?q=${encodeURIComponent(query)}`);
        if (!response.ok) throw new Error("Unable to search ingredients");
        ingredientSearchMatches = await response.json();
        renderIngredientSearchResults();
    } catch (error) {
        ingredientSearchResults.innerHTML = '<p class="ingredient-search-empty">Unable to load ingredients.</p>';
        console.error(error);
    }
}

function resetMealIngredients() {
    selectedIngredients = [];
    ingredientSearchMatches = [];
    ingredientSearchInput.value = "";
    renderSelectedIngredients();
    loadIngredientSearchResults();
}

function selectedIngredientPayload() {
    return [...selectedMealIngredients.querySelectorAll(".selected-ingredient")].map(row => ({
        ingredientId: Number(row.dataset.ingredientId),
        quantity: row.querySelector("[data-ingredient-quantity]").value || null,
        unit: row.querySelector("[data-ingredient-unit]").value.trim(),
        preparationNote: row.querySelector("[data-ingredient-note]").value.trim()
    }));
}

function openCreateModal() {
    editingMealId = null;
    currentMainImageUrl = null;
    form.reset();
    clearImagePreview();
    form.elements.categoryId.querySelector("option[data-inactive-category]")?.remove();
    mealImageFile.required = true;
    mealImageHelp.textContent = "JPG, PNG, or WebP. Maximum 5 MB.";
    resetMealIngredients();
    resetRecipeSteps();
    document.getElementById("mealRelatedData").hidden = true;
    document.getElementById("mealModalTitle").textContent = "Add Meal";
    document.getElementById("mealModalText").textContent = "Enter meal information for your catalog.";
    document.getElementById("saveMealButton").textContent = "Save Meal";
    modal.classList.add("show");
}

async function openEditModal(mealId) {
    try {
        const response = await fetch(`/admin/meals/${mealId}`);
        if (!response.ok) throw new Error("Unable to load this meal");
        const meal = await response.json();
        editingMealId = meal.mealId;
        currentMainImageUrl = meal.mainImageUrl;
        form.reset();
        form.elements.mealName.value = meal.mealName;
        const categorySelect = form.elements.categoryId;
        if (![...categorySelect.options].some(option => option.value === String(meal.categoryId))) {
            const option = new Option("Current category (inactive)", meal.categoryId, false, false);
            option.dataset.inactiveCategory = "true";
            categorySelect.add(option);
        }
        form.elements.categoryId.value = meal.categoryId;
        form.elements.calories.value = meal.calories ?? "";
        form.elements.servings.value = meal.servings;
        form.elements.cookingTimeMinutes.value = meal.cookingTimeMinutes ?? "";
        form.elements.difficulty.value = meal.difficulty ?? "";
        form.elements.published.value = String(meal.published);
        selectedIngredients = meal.ingredients || [];
        renderSelectedIngredients();
        ingredientSearchInput.value = "";
        loadIngredientSearchResults();
        mealImageFile.required = false;
        mealImageHelp.textContent = "Leave empty to keep the current meal image. JPG, PNG, or WebP; maximum 5 MB.";
        showImagePreview(meal.mainImageUrl, "Current meal image", "This is the image currently shown to users.");
        clearAllStepImagePreviews();
        recipeStepsBox.innerHTML = "";
        meal.recipeSteps.forEach(appendRecipeStep);
        const relatedData = document.getElementById("mealRelatedData");
        relatedData.hidden = false;
        ["ingredients", "nutrition", "recipeSteps", "reviews"].forEach(key => {
            relatedData.querySelector(`[data-related-count="${key}"]`).textContent = (meal[key] || []).length;
        });
        document.getElementById("mealModalTitle").textContent = "Edit Meal";
        document.getElementById("mealModalText").textContent = "Update the meal and its cooking steps.";
        document.getElementById("saveMealButton").textContent = "Update Meal";
        modal.classList.add("show");
    } catch (error) {
        window.adminAlerts?.error(error.message) ?? window.alert(error.message);
    }
}

function closeModal() {
    closeImageViewer();
    clearImagePreview();
    clearAllStepImagePreviews();
    modal.classList.remove("show");
}

async function uploadImage(endpoint, file, responseField) {
    const optimizedFile = await optimizeImage(file);
    const data = new FormData();
    data.append("file", optimizedFile);
    const response = await fetch(endpoint, { method: "POST", headers: csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}, body: data });
    const body = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(body.message || "Unable to upload image");
    return body[responseField];
}

async function optimizeImage(file) {
    if (!file || file.type === "image/webp") return file;
    const objectUrl = URL.createObjectURL(file);
    try {
        const image = await new Promise((resolve, reject) => {
            const element = new Image();
            element.onload = () => resolve(element);
            element.onerror = reject;
            element.src = objectUrl;
        });
        const maxDimension = 1600;
        const scale = Math.min(1, maxDimension / Math.max(image.naturalWidth, image.naturalHeight));
        const canvas = document.createElement("canvas");
        canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
        canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
        canvas.getContext("2d").drawImage(image, 0, 0, canvas.width, canvas.height);
        const blob = await new Promise(resolve => canvas.toBlob(resolve, "image/webp", 0.82));
        if (!blob) return file;
        return new File([blob], file.name.replace(/\.[^.]+$/, ".webp"), {
            type: "image/webp",
            lastModified: file.lastModified
        });
    } catch (_) {
        return file;
    } finally {
        URL.revokeObjectURL(objectUrl);
    }
}

async function saveMeal(event) {
    event.preventDefault();
    const isUpdate = Boolean(editingMealId);
    const data = new FormData(form);
    const imageFile = data.get("imageFile");
    data.delete("imageFile");
    const payload = Object.fromEntries(data.entries());
    ["calories", "cookingTimeMinutes", "difficulty"].forEach(key => {
        if (payload[key] === "") delete payload[key];
    });
    payload.published = payload.published === "true";
    payload.ingredients = selectedIngredientPayload();
    if (!payload.ingredients.length) {
        window.adminAlerts?.error("Add an ingredient", "Select at least one ingredient for this meal.") ?? window.alert("Select at least one ingredient for this meal.");
        return;
    }
    try {
        payload.mainImageUrl = imageFile?.size
            ? await uploadImage("/admin/meal-images", imageFile, "mainImageUrl")
            : currentMainImageUrl;
        payload.recipeSteps = await Promise.all([...recipeStepsBox.querySelectorAll("[data-recipe-step]")].map(async step => {
            const stepImage = step.querySelector("[data-step-image]").files[0];
            return {
                title: step.querySelector("[data-step-title]").value.trim(),
                instruction: step.querySelector("[data-step-instruction]").value.trim(),
                imageUrl: stepImage ? await uploadImage("/admin/recipe-step-images", stepImage, "imageUrl") : step.dataset.imageUrl
            };
        }));
        const response = await fetch(isUpdate ? `/admin/meals/${editingMealId}` : "/admin/meals", {
            method: isUpdate ? "PUT" : "POST",
            headers: { "Content-Type": "application/json", "Accept": "application/json", ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}) },
            body: JSON.stringify(payload)
        });
        if (!response.ok) {
            const body = await response.json().catch(() => ({}));
            throw new Error(body.message || "Unable to save meal");
        }
        await (window.adminAlerts?.success(
            isUpdate ? "Updated!" : "Added!",
            isUpdate ? "The meal has been updated successfully." : "The new meal has been added successfully."
        ) ?? Promise.resolve(window.alert(isUpdate ? "The meal has been updated successfully." : "The new meal has been added successfully.")));
        closeModal();
        mealSummary = null;
        await loadMeals();
    } catch (error) {
        window.adminAlerts?.error(error.message) ?? window.alert(error.message);
        console.error(error);
    }
}

rowsBox.addEventListener("click", async event => {
    const button = event.target.closest("button[data-action]");
    if (!button) return;
    const mealId = button.dataset.mealId;
    if (button.dataset.action === "edit") return openEditModal(mealId);
    const meal = meals.find(item => String(item.mealId) === String(mealId));
    const confirmed = await (window.adminAlerts?.confirmDelete({
        title: "Delete this meal?",
        text: `${meal?.mealName || "This meal"} and its recipe details, saved data, and related records will be removed.`
    }) ?? Promise.resolve(window.confirm("Delete this meal? Its recipe details and related saved data will be removed.")));
    if (!confirmed) return;
    try {
        const response = await fetch(`/admin/meals/${mealId}`, { method: "DELETE", headers: csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {} });
        if (!response.ok) {
            const body = await response.json().catch(() => ({}));
            throw new Error(body.message || "Unable to delete meal");
        }
        await window.adminAlerts?.success("Deleted!", "The meal has been deleted.");
        mealSummary = null;
        await loadMeals();
    } catch (error) {
        window.adminAlerts?.error(error.message) ?? window.alert(error.message);
    }
});

["searchInput", "categoryFilter", "statusFilter", "tagFilter"].forEach(id => {
    const element = document.getElementById(id);
    element.addEventListener(element.tagName === "INPUT" ? "input" : "change", () => {
        window.clearTimeout(mealFilterTimer);
        mealFilterTimer = window.setTimeout(filterMeals, element.tagName === "INPUT" ? 400 : 0);
    });
});
document.getElementById("clearFilters").onclick = () => {
    document.getElementById("searchInput").value = "";
    document.getElementById("categoryFilter").value = "";
    document.getElementById("statusFilter").value = "";
    document.getElementById("tagFilter").value = "";
    filterMeals();
};
previousMealPage.addEventListener("click", () => {
    if (!mealPageData?.first) loadMeals(mealPage - 1);
});
nextMealPage.addEventListener("click", () => {
    if (!mealPageData?.last) loadMeals(mealPage + 1);
});
mealPageJump.addEventListener("change", () => loadMeals(Number(mealPageJump.value)));
document.getElementById("openModal").onclick = openCreateModal;
document.getElementById("closeModal").onclick = closeModal;
document.getElementById("cancelModal").onclick = closeModal;
document.getElementById("addRecipeStep").onclick = () => appendRecipeStep();
openMealImageViewer.addEventListener("click", openImageViewer);
document.getElementById("closeMealImageViewer").addEventListener("click", closeImageViewer);
document.getElementById("closeMealImageViewerButton").addEventListener("click", closeImageViewer);
ingredientSearchInput.addEventListener("input", () => {
    window.clearTimeout(ingredientSearchTimer);
    ingredientSearchTimer = window.setTimeout(() => loadIngredientSearchResults(ingredientSearchInput.value), 200);
});
ingredientSearchResults.addEventListener("click", event => {
    const button = event.target.closest("[data-ingredient-id]");
    if (!button || button.disabled) return;
    const ingredient = ingredientSearchMatches.find(item => String(item.ingredientId) === button.dataset.ingredientId);
    if (!ingredient || selectedIngredients.some(item => item.ingredientId === ingredient.ingredientId)) return;
    selectedIngredients.push(ingredient);
    renderSelectedIngredients();
    renderIngredientSearchResults();
    ingredientSearchInput.focus();
});
selectedMealIngredients.addEventListener("click", event => {
    const button = event.target.closest("[data-remove-ingredient]");
    if (!button) return;
    selectedIngredients.splice(Number(button.dataset.removeIngredient), 1);
    renderSelectedIngredients();
    renderIngredientSearchResults();
});
mealImageFile.addEventListener("change", () => {
    const file = mealImageFile.files[0];
    if (!file) {
        if (editingMealId && currentMainImageUrl) {
            showImagePreview(currentMainImageUrl, "Current meal image", "This is the image currently shown to users.");
        } else {
            clearImagePreview();
        }
        return;
    }
    clearImagePreview();
    previewObjectUrl = URL.createObjectURL(file);
    mealImagePreviewImage.src = previewObjectUrl;
    mealImagePreviewTitle.textContent = "New meal image preview";
    mealImagePreviewText.textContent = "This image will replace the current one after you save.";
    mealImagePreview.hidden = false;
});
recipeStepsBox.addEventListener("click", event => {
    const button = event.target.closest(".step-remove");
    if (!button || recipeStepsBox.children.length === 1) return;
    const step = button.closest("[data-recipe-step]");
    clearStepImagePreview(step);
    step.remove();
    updateRecipeStepLabels();
});
recipeStepsBox.addEventListener("change", event => {
    if (!event.target.matches("[data-step-image]")) return;
    const step = event.target.closest("[data-recipe-step]");
    const file = event.target.files[0];
    if (!file) {
        showStepImagePreview(step, step.dataset.imageUrl, "Current step image", "This image is currently shown to users.");
        return;
    }
    clearStepImagePreview(step);
    const previewUrl = URL.createObjectURL(file);
    step.dataset.previewObjectUrl = previewUrl;
    step.querySelector("[data-step-image-preview-image]").src = previewUrl;
    step.querySelector("[data-step-image-preview-title]").textContent = "New step image preview";
    step.querySelector("[data-step-image-preview-text]").textContent = "This image will replace the current one after you save.";
    step.querySelector("[data-step-image-preview]").hidden = false;
});
form.addEventListener("submit", saveMeal);
document.addEventListener("keydown", event => {
    if (event.key === "Escape" && !mealImageViewer.hidden) closeImageViewer();
});
updateRecipeStepLabels();
loadMeals();
