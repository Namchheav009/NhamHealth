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
const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;

document.querySelector(".pagination")?.remove();

let meals = [];
let editingMealId = null;
let currentMainImageUrl = null;

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

function drawRows(list) {
    rowsBox.innerHTML = "";
    if (!list.length) {
        rowsBox.innerHTML = '<tr><td colspan="10" style="padding:40px;text-align:center">No meals found.</td></tr>';
    } else {
        list.forEach(meal => {
            const tags = (meal.tags || []).map(tag => `<span class="pill ${tagClass(tag)}">${escapeHtml(tag)}</span>`).join(" ");
            const thumbnail = meal.mainImageUrl
                ? `<img src="${escapeHtml(meal.mainImageUrl)}" alt="${escapeHtml(meal.mealName)}">`
                : `<i class="fa-solid ${escapeHtml(meal.iconClass || "fa-utensils")}"></i>`;
            rowsBox.insertAdjacentHTML("beforeend", `
                <tr>
                    <td><div class="meal-cell"><div class="meal-thumb">${thumbnail}</div><div><strong>${escapeHtml(meal.mealName)}</strong><small>${escapeHtml(meal.category)} meal</small></div></div></td>
                    <td>${escapeHtml(meal.category)}</td>
                    <td>${escapeHtml(meal.calories)}</td>
                    <td>${escapeHtml(meal.servingSize)}</td>
                    <td>${tags}</td>
                    <td><i class="fa-solid fa-star" style="color:#f5a623"></i> ${escapeHtml(meal.reviews)}</td>
                    <td>${Number(meal.favorites || 0).toLocaleString()}</td>
                    <td><span class="pill ${statusClass(meal.status)}">${escapeHtml(meal.status)}</span></td>
                    <td>${escapeHtml(meal.updatedDate)}</td>
                    <td><div class="meal-actions"><button class="action" data-action="edit" data-meal-id="${meal.mealId}" type="button" aria-label="Edit meal"><i class="fa-solid fa-pen"></i></button><button class="action danger-action" data-action="delete" data-meal-id="${meal.mealId}" type="button" aria-label="Delete meal"><i class="fa-solid fa-trash"></i></button></div></td>
                </tr>`);
        });
    }
    resultText.textContent = `${list.length} meal${list.length === 1 ? "" : "s"}`;
    showingText.textContent = list.length ? `Showing 1 to ${list.length} of ${meals.length} meals` : "No meals to show";
}

function populateFilter(id, values, label) {
    const select = document.getElementById(id);
    const selected = select.value;
    select.replaceChildren(new Option(`All ${label}`, ""));
    [...new Set(values.filter(Boolean))].sort((a, b) => a.localeCompare(b))
        .forEach(value => select.add(new Option(value, value.toLowerCase())));
    select.value = [...select.options].some(option => option.value === selected) ? selected : "";
}

function updateSummary() {
    const favorites = meals.reduce((total, meal) => total + (Number(meal.favorites) || 0), 0);
    const ratings = meals.flatMap(meal => {
        const match = String(meal.reviews || "").match(/^([\d.]+) \((\d+)\)$/);
        return match && Number(match[2]) ? Array(Number(match[2])).fill(Number(match[1])) : [];
    });
    const rating = ratings.length ? ratings.reduce((total, value) => total + value, 0) / ratings.length : 0;
    totalMeals.textContent = meals.length.toLocaleString();
    averageRating.textContent = `${rating.toFixed(1)} / 5`;
    favoritesSaved.textContent = favorites.toLocaleString();
}

function filterMeals() {
    const search = document.getElementById("searchInput").value.toLowerCase();
    const category = document.getElementById("categoryFilter").value.toLowerCase();
    const status = document.getElementById("statusFilter").value.toLowerCase();
    const tag = document.getElementById("tagFilter").value.toLowerCase();
    drawRows(meals.filter(meal => meal.mealName.toLowerCase().includes(search)
        && (!category || meal.category.toLowerCase() === category)
        && (!status || meal.status.toLowerCase() === status)
        && (!tag || (meal.tags || []).some(item => item.toLowerCase() === tag))));
}

async function loadMeals() {
    try {
        const response = await fetch("/admin/meals/data");
        if (!response.ok) throw new Error("Unable to load meals");
        meals = await response.json();
        populateFilter("categoryFilter", meals.map(meal => meal.category), "Categories");
        populateFilter("tagFilter", meals.flatMap(meal => meal.tags || []), "Tags");
        updateSummary();
        filterMeals();
    } catch (error) {
        rowsBox.innerHTML = '<tr><td colspan="10" style="padding:40px;text-align:center">Unable to load meals from the API.</td></tr>';
        console.error(error);
    }
}

function recipeStepMarkup(number) {
    return `<article class="recipe-step" data-recipe-step><div class="recipe-step-title"><strong>Step ${number}</strong><button class="step-remove" type="button" aria-label="Remove cooking step"><i class="fa-solid fa-trash-can"></i></button></div><input data-step-title type="text" maxlength="150" placeholder="Step title (optional)"><textarea data-step-instruction maxlength="255" required placeholder="Describe what to do in this step..."></textarea><input data-step-image type="file" accept="image/jpeg,image/png,image/webp" required aria-label="Image for step ${number}"></article>`;
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
    if (step.imageUrl) imageInput.title = "Choose a new file only to replace the current step image.";
    updateRecipeStepLabels();
}

function resetRecipeSteps() {
    recipeStepsBox.innerHTML = "";
    appendRecipeStep();
}

function openCreateModal() {
    editingMealId = null;
    currentMainImageUrl = null;
    form.reset();
    form.elements.categoryId.querySelector("option[data-inactive-category]")?.remove();
    mealImageFile.required = true;
    mealImageHelp.textContent = "JPG, PNG, or WebP. Maximum 5 MB.";
    resetRecipeSteps();
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
        form.elements.description.value = meal.description ?? "";
        mealImageFile.required = false;
        mealImageHelp.textContent = "Leave empty to keep the current meal image. JPG, PNG, or WebP; maximum 5 MB.";
        recipeStepsBox.innerHTML = "";
        meal.recipeSteps.forEach(appendRecipeStep);
        document.getElementById("mealModalTitle").textContent = "Edit Meal";
        document.getElementById("mealModalText").textContent = "Update the meal and its cooking steps.";
        document.getElementById("saveMealButton").textContent = "Update Meal";
        modal.classList.add("show");
    } catch (error) {
        window.alert(error.message);
    }
}

function closeModal() {
    modal.classList.remove("show");
}

async function uploadImage(endpoint, file, responseField) {
    const data = new FormData();
    data.append("file", file);
    const response = await fetch(endpoint, { method: "POST", headers: csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}, body: data });
    const body = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(body.message || "Unable to upload image");
    return body[responseField];
}

async function saveMeal(event) {
    event.preventDefault();
    const data = new FormData(form);
    const imageFile = data.get("imageFile");
    data.delete("imageFile");
    const payload = Object.fromEntries(data.entries());
    ["calories", "cookingTimeMinutes", "difficulty", "description"].forEach(key => {
        if (payload[key] === "") delete payload[key];
    });
    payload.published = payload.published === "true";
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
        const response = await fetch(editingMealId ? `/admin/meals/${editingMealId}` : "/admin/meals", {
            method: editingMealId ? "PUT" : "POST",
            headers: { "Content-Type": "application/json", "Accept": "application/json", ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}) },
            body: JSON.stringify(payload)
        });
        if (!response.ok) {
            const body = await response.json().catch(() => ({}));
            throw new Error(body.message || "Unable to save meal");
        }
        closeModal();
        await loadMeals();
    } catch (error) {
        window.alert(error.message);
        console.error(error);
    }
}

rowsBox.addEventListener("click", async event => {
    const button = event.target.closest("button[data-action]");
    if (!button) return;
    const mealId = button.dataset.mealId;
    if (button.dataset.action === "edit") return openEditModal(mealId);
    if (!window.confirm("Delete this meal? Its recipe details and related saved data will be removed.")) return;
    try {
        const response = await fetch(`/admin/meals/${mealId}`, { method: "DELETE", headers: csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {} });
        if (!response.ok) {
            const body = await response.json().catch(() => ({}));
            throw new Error(body.message || "Unable to delete meal");
        }
        await loadMeals();
    } catch (error) {
        window.alert(error.message);
    }
});

["searchInput", "categoryFilter", "statusFilter", "tagFilter"].forEach(id => {
    const element = document.getElementById(id);
    element.addEventListener(element.tagName === "INPUT" ? "input" : "change", filterMeals);
});
document.getElementById("clearFilters").onclick = () => {
    document.getElementById("searchInput").value = "";
    document.getElementById("categoryFilter").value = "";
    document.getElementById("statusFilter").value = "";
    document.getElementById("tagFilter").value = "";
    filterMeals();
};
document.getElementById("openModal").onclick = openCreateModal;
document.getElementById("closeModal").onclick = closeModal;
document.getElementById("cancelModal").onclick = closeModal;
document.getElementById("addRecipeStep").onclick = () => appendRecipeStep();
recipeStepsBox.addEventListener("click", event => {
    const button = event.target.closest(".step-remove");
    if (!button || recipeStepsBox.children.length === 1) return;
    button.closest("[data-recipe-step]").remove();
    updateRecipeStepLabels();
});
form.addEventListener("submit", saveMeal);
updateRecipeStepLabels();
loadMeals();
