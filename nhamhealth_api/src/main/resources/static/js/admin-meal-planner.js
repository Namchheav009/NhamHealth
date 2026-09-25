(() => {
  // DOM Elements - Table & Board
  const rowsBox = document.getElementById("recommendationRows");
  const board = document.getElementById("scheduleBoard");
  const emptyRow = document.getElementById("emptyRecommendationRow");

  // DOM Elements - Schedule Modal
  const modal = document.getElementById("recommendationModal");
  const form = document.getElementById("recommendationForm");
  const modalTitle = document.getElementById("recommendationModalTitle");
  const saveButton = document.getElementById("saveRecommendationButton");
  const plannerCategory = document.getElementById("plannerCategory");
  const plannerMeal = document.getElementById("plannerMeal");
  const plannerDays = [...document.querySelectorAll(".planner-day")];

  // DOM Elements - Table Filters
  const search = document.getElementById("recommendationSearch");
  const dayFilter = document.getElementById("dayFilter");
  const slotFilter = document.getElementById("slotFilter");
  const statusFilter = document.getElementById("statusFilter");
  const clearFiltersBtn = document.getElementById("clearRecommendationFilters");

  // DOM Elements - Planner Meal Library & Modal
  const mealLibrary = document.getElementById("plannerMealLibrary");
  const librarySearch = document.getElementById("librarySearch");
  const libraryStatusFilter = document.getElementById("libraryStatusFilter");
  const libraryCountText = document.getElementById("libraryCountText");
  const libraryEmpty = document.getElementById("plannerLibraryEmpty");
  const mealModal = document.getElementById("plannerMealModal");
  const mealForm = document.getElementById("plannerMealForm");
  const mealModalTitle = document.getElementById("plannerMealModalTitle");
  const mealSaveButton = document.getElementById("savePlannerMealButton");
  const ingredientSearchInput = document.getElementById("plannerIngredientSearch");
  const ingredientSearchResults = document.getElementById("plannerIngredientSearchResults");
  const selectedPlannerIngredients = document.getElementById("selectedPlannerIngredients");

  // DOM Elements - Meal Image Uploader & Preview
  const tabUploadImage = document.getElementById("tabUploadImage");
  const tabUrlImage = document.getElementById("tabUrlImage");
  const panelUploadImage = document.getElementById("panelUploadImage");
  const panelUrlImage = document.getElementById("panelUrlImage");
  const mealImageDropzone = document.getElementById("plannerImageDropzone");
  const mealImageFileInput = document.getElementById("mealImageFileInput");
  const mealImageUrlInput = document.getElementById("mealImageUrl");
  const plannerImagePreview = document.getElementById("plannerImagePreview");
  const plannerPreviewImg = document.getElementById("plannerPreviewImg");
  const plannerPreviewName = document.getElementById("plannerPreviewName");
  const plannerPreviewMeta = document.getElementById("plannerPreviewMeta");
  const btnClearMealImage = document.getElementById("btnClearMealImage");

  let pendingImageFile = null;
  let previewObjectUrl = null;
  let plannerIngredients = [];
  let ingredientMatches = [];
  let ingredientSearchTimer = null;

  // CSRF Tokens
  const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
  const csrfHeader = document.querySelector(
    'meta[name="_csrf_header"]',
  )?.content;

  const days = [
    "MONDAY",
    "TUESDAY",
    "WEDNESDAY",
    "THURSDAY",
    "FRIDAY",
    "SATURDAY",
    "SUNDAY",
  ];
  const alerts = window.adminAlerts ?? {
    confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
    success: (title, text) => Promise.resolve(window.alert(text || title)),
    error: (text) => Promise.resolve(window.alert(text)),
  };

  let editingId = null;
  let editingMealId = null;

  const rows = () => [...(rowsBox?.querySelectorAll("tr[data-id]") || [])];
  const libraryCards = () => [
    ...(mealLibrary?.querySelectorAll(".planner-meal-card") || []),
  ];
  const titleCase = (value) =>
    value ? value.charAt(0) + value.slice(1).toLowerCase() : "";
  const csrfHeaders = () =>
    csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {};

  function escapeHtml(value) {
    const element = document.createElement("span");
    element.textContent = value || "";
    return element.innerHTML;
  }

  function renderPlannerIngredients() {
    if (!selectedPlannerIngredients) return;
    if (!plannerIngredients.length) {
      selectedPlannerIngredients.innerHTML = '<p class="no-planner-ingredients">No ingredients selected yet.</p>';
      return;
    }
    selectedPlannerIngredients.innerHTML = plannerIngredients.map((ingredient, index) => `
      <article class="selected-planner-ingredient" data-index="${index}">
        <div class="selected-planner-ingredient-name"><strong>${escapeHtml(ingredient.name)}</strong><span>Type: ${escapeHtml(ingredient.type || "Ingredient")} · Default unit: ${escapeHtml(ingredient.defaultUnit || "Not set")}</span></div>
        <label>Quantity<input data-field="quantity" type="number" min="0" step="0.01" value="${escapeHtml(ingredient.quantity)}" placeholder="Optional" aria-label="Quantity for ${escapeHtml(ingredient.name)}" /></label>
        <label>Measurement unit<input data-field="unit" value="${escapeHtml(ingredient.unit)}" placeholder="Optional" aria-label="Unit for ${escapeHtml(ingredient.name)}" /></label>
        <label>Ingredient name (ខ្មែរ)<input data-field="nameKm" lang="km" value="${escapeHtml(ingredient.nameKm)}" placeholder="Optional Khmer name" aria-label="Khmer name for ${escapeHtml(ingredient.name)}" /></label>
        <button type="button" class="planner-remove-ingredient" data-remove-index="${index}" aria-label="Remove ${escapeHtml(ingredient.name)}"><i class="bi bi-trash3"></i></button>
      </article>`).join("");
  }

  function parsePlannerIngredients(english = "", khmer = "") {
    const splitIngredients = value => String(value || "").split(/[;\r\n]+/).map(item => item.trim()).filter(Boolean);
    const amountPattern = /^\s*(\d+(?:\.\d+)?)\s*(kg|mg|g|ml|l|tsp|tbsp|cups?|pieces?|pcs?)?\s+(.+?)\s*$/i;
    const kmLines = splitIngredients(khmer);
    return splitIngredients(english).map((line, index) => {
      const [name = "", quantity = "", unit = "", inlineKm = ""] = line.split("|").map(part => part.trim());
      const [kmName = ""] = (kmLines[index] || "").split("|").map(part => part.trim());
      if (line.includes("|")) return { name, quantity, unit, nameKm: inlineKm || kmName, type: "", defaultUnit: unit };
      const match = line.match(amountPattern);
      const kmMatch = kmName.match(amountPattern);
      return match
        ? { name: match[3].trim(), quantity: match[1], unit: match[2] || "", nameKm: kmMatch ? kmMatch[3].trim() : kmName, type: "", defaultUnit: match[2] || "" }
        : { name: line, quantity: "", unit: "", nameKm: kmMatch ? kmMatch[3].trim() : kmName, type: "", defaultUnit: "" };
    }).filter(ingredient => ingredient.name);
  }

  function ingredientTextPayload() {
    const ingredients = [...selectedPlannerIngredients.querySelectorAll(".selected-planner-ingredient")].map(row => {
      const item = plannerIngredients[Number(row.dataset.index)];
      return {
        ...item,
        quantity: row.querySelector('[data-field="quantity"]').value.trim(),
        unit: row.querySelector('[data-field="unit"]').value.trim(),
        nameKm: row.querySelector('[data-field="nameKm"]').value.trim(),
      };
    });
    return {
      english: ingredients.map(item => [item.name, item.quantity, item.unit, item.nameKm].join(" | ")).join("\n"),
      khmer: ingredients.filter(item => item.nameKm).map(item => [item.nameKm, item.quantity, item.unit].join(" | ")).join("\n"),
    };
  }

  async function searchPlannerIngredients(query) {
    const value = query.trim();
    if (value.length < 1) { ingredientMatches = []; ingredientSearchResults.innerHTML = ""; return; }
    try {
      const response = await fetch(`/admin/ingredients/search?q=${encodeURIComponent(value)}`);
      if (!response.ok) throw new Error();
      ingredientMatches = await response.json();
      ingredientSearchResults.innerHTML = ingredientMatches.map(item => {
        const added = plannerIngredients.some(ingredient => ingredient.id === item.ingredientId);
        return `<button type="button" class="planner-ingredient-result" data-ingredient-id="${item.ingredientId}" ${added ? "disabled" : ""}><strong>${escapeHtml(item.ingredientName)}</strong><span>${escapeHtml(item.ingredientType || "Ingredient")}${item.defaultUnit ? ` · ${escapeHtml(item.defaultUnit)}` : ""}</span></button>`;
      }).join("") || '<p class="planner-ingredient-search-empty">No ingredients found.</p>';
    } catch (_) { ingredientSearchResults.innerHTML = '<p class="planner-ingredient-search-empty">Unable to load ingredients.</p>'; }
  }

  // --------------------------------------------------------------------------
  // Image Uploader & Optimization Helpers
  // --------------------------------------------------------------------------
  function switchImageMode(mode) {
    const isUpload = mode === "upload";
    tabUploadImage?.classList.toggle("active", isUpload);
    tabUrlImage?.classList.toggle("active", !isUpload);
    panelUploadImage?.classList.toggle("hidden", !isUpload);
    panelUrlImage?.classList.toggle("hidden", isUpload);
  }

  function clearImageState() {
    if (previewObjectUrl) {
      URL.revokeObjectURL(previewObjectUrl);
      previewObjectUrl = null;
    }
    pendingImageFile = null;
    if (mealImageFileInput) mealImageFileInput.value = "";
    if (mealImageUrlInput) mealImageUrlInput.value = "";
    if (plannerImagePreview) plannerImagePreview.hidden = true;
    if (plannerPreviewImg) plannerPreviewImg.removeAttribute("src");
  }

  function showPreview(url, name, meta) {
    if (previewObjectUrl && previewObjectUrl !== url) {
      URL.revokeObjectURL(previewObjectUrl);
      previewObjectUrl = null;
    }
    if (!url) {
      if (plannerImagePreview) plannerImagePreview.hidden = true;
      return;
    }
    if (plannerPreviewImg) plannerPreviewImg.src = url;
    if (plannerPreviewName) plannerPreviewName.textContent = name || "image";
    if (plannerPreviewMeta)
      plannerPreviewMeta.textContent = meta || "Ready to save";
    if (plannerImagePreview) plannerImagePreview.hidden = false;
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
      const scale = Math.min(
        1,
        maxDimension / Math.max(image.naturalWidth, image.naturalHeight),
      );
      const canvas = document.createElement("canvas");
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
      canvas
        .getContext("2d")
        .drawImage(image, 0, 0, canvas.width, canvas.height);
      const blob = await new Promise((resolve) =>
        canvas.toBlob(resolve, "image/webp", 0.82),
      );
      if (!blob) return file;
      return new File([blob], file.name.replace(/\.[^.]+$/, ".webp"), {
        type: "image/webp",
        lastModified: file.lastModified,
      });
    } catch (_) {
      return file;
    } finally {
      URL.revokeObjectURL(objectUrl);
    }
  }

  async function uploadImageFile(file) {
    const optimized = await optimizeImage(file);
    const data = new FormData();
    data.append("file", optimized);
    const response = await fetch("/admin/meal-planner/upload-image", {
      method: "POST",
      headers: csrfHeaders(),
      body: data,
    });
    const body = await response.json().catch(() => ({}));
    if (!response.ok)
      throw new Error(body.message || "Unable to upload meal image.");
    return body.imageUrl || body.mainImageUrl;
  }

  // --------------------------------------------------------------------------
  // Weekly Schedule Board
  // --------------------------------------------------------------------------
  function renderBoard() {
    if (!board) return;
    const activeRows = rows().filter(
      (row) =>
        row.dataset.active === "true" && row.dataset.mealActive === "true",
    );

    board.innerHTML = days
      .map((day) => {
        const dayRows = activeRows.filter((row) => row.dataset.day === day);
        const count = dayRows.length;

        const cards = dayRows
          .map((row) => {
            const slot = row.dataset.slot || "BREAKFAST";
            const calories = row.dataset.calories || "0";
            const protein = row.dataset.protein || "0";
            const order = Number(row.dataset.order || 0);

            return `
                    <button class="schedule-meal ${slot.toLowerCase()}" type="button" data-edit-id="${row.dataset.id}">
                        <div class="schedule-meal-header">
                            <span class="slot-name">${titleCase(slot)}</span>
                            ${order > 0 ? `<span class="priority-pill" title="Order priority">${order}</span>` : ""}
                        </div>
                        <strong>${escapeHtml(row.dataset.meal)}</strong>
                        <div class="schedule-meal-meta">
                            <span><i class="bi bi-fire"></i> ${Math.round(Number(calories))} kcal</span>
                            <span><i class="bi bi-lightning-charge"></i> ${Math.round(Number(protein))}g P</span>
                        </div>
                    </button>
                `;
          })
          .join("");

        const emptyState = `
                <div class="schedule-day-empty">
                    <span>No meals scheduled</span>
                    <button class="schedule-day-add-btn" type="button" data-schedule-day="${day}">
                        <i class="bi bi-plus"></i> Add meal
                    </button>
                </div>
            `;

        return `
                <section class="schedule-day">
                    <header>
                        <span class="day-name">${titleCase(day)}</span>
                        <span class="day-badge">${count} ${count === 1 ? "meal" : "meals"}</span>
                    </header>
                    <div class="schedule-day-meals">
                        ${cards || emptyState}
                    </div>
                </section>
            `;
      })
      .join("");
  }

  // --------------------------------------------------------------------------
  // Table Filtering
  // --------------------------------------------------------------------------
  function applyTableFilters() {
    const keyword = (search?.value || "").trim().toLowerCase();
    const selectedDay = dayFilter?.value || "";
    const selectedSlot = slotFilter?.value || "";
    const selectedStatus = statusFilter?.value || "";

    let visibleCount = 0;
    rows().forEach((row) => {
      const mealName = (row.dataset.meal || "").toLowerCase();
      const note = (row.dataset.note || "").toLowerCase();
      const matchesSearch =
        !keyword || mealName.includes(keyword) || note.includes(keyword);
      const matchesDay = !selectedDay || row.dataset.day === selectedDay;
      const matchesSlot = !selectedSlot || row.dataset.slot === selectedSlot;

      const isActive =
        row.dataset.active === "true" && row.dataset.mealActive === "true";
      const matchesStatus =
        !selectedStatus ||
        (selectedStatus === "active" && isActive) ||
        (selectedStatus === "inactive" && !isActive);

      const visible =
        matchesSearch && matchesDay && matchesSlot && matchesStatus;
      row.hidden = !visible;
      if (visible) visibleCount++;
    });

    if (emptyRow) {
      emptyRow.hidden = visibleCount > 0;
    }
  }

  function clearTableFilters() {
    if (search) search.value = "";
    if (dayFilter) dayFilter.value = "";
    if (slotFilter) slotFilter.value = "";
    if (statusFilter) statusFilter.value = "";
    applyTableFilters();
  }

  // --------------------------------------------------------------------------
  // Planner Meal Library Filtering
  // --------------------------------------------------------------------------
  function applyLibraryFilters() {
    const keyword = (librarySearch?.value || "").trim().toLowerCase();
    const selectedStatus = libraryStatusFilter?.value || "";

    const cards = libraryCards();
    let visibleCount = 0;

    cards.forEach((card) => {
      const nameEn = (card.dataset.nameEn || "").toLowerCase();
      const nameKm = (card.dataset.nameKm || "").toLowerCase();
      const categoryEn = (card.dataset.categoryEn || "").toLowerCase();
      const tags = (card.dataset.tags || "").toLowerCase();
      const isActive = card.dataset.active === "true";

      const matchesSearch =
        !keyword ||
        nameEn.includes(keyword) ||
        nameKm.includes(keyword) ||
        categoryEn.includes(keyword) ||
        tags.includes(keyword);
      const matchesStatus =
        !selectedStatus ||
        (selectedStatus === "active" && isActive) ||
        (selectedStatus === "archived" && !isActive);

      const visible = matchesSearch && matchesStatus;
      card.style.display = visible ? "" : "none";
      if (visible) visibleCount++;
    });

    if (libraryCountText) {
      libraryCountText.textContent =
        cards.length === visibleCount
          ? `${cards.length} meals`
          : `${visibleCount} of ${cards.length} meals`;
    }

    if (libraryEmpty) {
      libraryEmpty.style.display = visibleCount === 0 ? "" : "none";
    }
  }

  // --------------------------------------------------------------------------
  // Recommendation Modal (Schedule)
  // --------------------------------------------------------------------------
  function setModal(open) {
    modal.classList.toggle("show", open);
    modal.setAttribute("aria-hidden", String(!open));
    document.body.classList.toggle("planner-modal-open", open);
  }

  function filterPlannerMeals(selectedMealId = "") {
    const categoryId = plannerCategory?.value || "";
    [...(plannerMeal?.options || [])].forEach((option) => {
      if (!option.value) return;
      const ids = (
        option.dataset.categoryIds ||
        option.dataset.categoryId ||
        ""
      )
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean);
      const matches = !categoryId || ids.includes(categoryId);
      option.hidden = !matches;
      option.disabled = !matches;
    });
    if (plannerMeal) {
      plannerMeal.disabled = !categoryId;
      plannerMeal.value =
        selectedMealId &&
        plannerMeal.querySelector(
          `option[value="${selectedMealId}"]:not([disabled])`,
        )
          ? selectedMealId
          : "";
    }
  }

  function openCreate(prefillDay) {
    editingId = null;
    form.reset();
    filterPlannerMeals();
    const selectedDay = prefillDay || days[(new Date().getDay() + 6) % 7];
    plannerDays.forEach((input) => {
      input.checked = input.value === selectedDay;
    });
    form.elements.mealSlot.value = "BREAKFAST";
    form.elements.active.value = "true";
    form.elements.sortOrder.value = "0";
    modalTitle.textContent = "Schedule Meal";
    saveButton.innerHTML = '<i class="bi bi-check-lg"></i> Save Recommendation';
    setModal(true);
    form.elements.plannerMealId.focus();
  }

  function openEdit(row) {
    if (!row) return;
    editingId = row.dataset.id;
    if (
      !form.elements.plannerMealId.querySelector(
        `option[value="${row.dataset.mealId}"]`,
      )
    ) {
      const option = new Option(
        `${row.dataset.meal} · archived`,
        row.dataset.mealId,
      );
      option.disabled = true;
      form.elements.plannerMealId.add(option);
    }
    form.elements.categoryId.value = row.dataset.categoryId || "";
    filterPlannerMeals(row.dataset.mealId);
    form.elements.plannerMealId.value = row.dataset.mealId;
    plannerDays.forEach((input) => {
      input.checked = input.value === row.dataset.day;
    });
    form.elements.mealSlot.value = row.dataset.slot;
    form.elements.note.value = row.dataset.note || "";
    form.elements.active.value = row.dataset.active;
    form.elements.sortOrder.value = row.dataset.order || "0";
    modalTitle.textContent = "Edit Meal Recommendation";
    saveButton.innerHTML = '<i class="bi bi-check-lg"></i> Save Changes';
    setModal(true);
  }

  function closeModal() {
    setModal(false);
    editingId = null;
    form.reset();
  }

  function openScheduleForMeal({ id, name, categoryId }) {
    openCreate();
    form.elements.categoryId.value = String(categoryId);
    filterPlannerMeals(String(id));
    form.elements.plannerMealId.value = String(id);
    modalTitle.textContent = `Schedule ${name}`;
  }

  function reloadAtScheduledRecommendations() {
    window.location.hash = "scheduledRecommendations";
    window.location.reload();
  }

  async function request(url, method, payload) {
    const response = await fetch(url, {
      method,
      headers: {
        Accept: "application/json",
        ...(payload ? { "Content-Type": "application/json" } : {}),
        ...csrfHeaders(),
      },
      body: payload ? JSON.stringify(payload) : undefined,
    });
    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      const message =
        body.message ||
        body.error ||
        (body.errors &&
          body.errors.map((e) => e.defaultMessage || e.field).join(", ")) ||
        `Unable to update the weekly planner (HTTP ${response.status}).`;
      throw new Error(message);
    }
    return response.status === 204 ? null : response.json();
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (!form.checkValidity()) return form.reportValidity();
    const data = Object.fromEntries(new FormData(form).entries());
    const selectedDays = plannerDays
      .filter((input) => input.checked)
      .map((input) => input.value);
    if (selectedDays.length === 0) {
      await alerts.error("Select at least one weekday.");
      return;
    }
    if (editingId && selectedDays.length !== 1) {
      await alerts.error("Select one weekday when editing a recommendation.");
      return;
    }
    const basePayload = {
      plannerMealId: Number(data.plannerMealId),
      mealSlot: data.mealSlot,
      note: (data.note || "").trim() || null,
      active: data.active === "true",
      sortOrder: Number(data.sortOrder || 0),
    };
    saveButton.disabled = true;
    try {
      const wasEditing = Boolean(editingId);
      const mealLabel =
        form.elements.plannerMealId.selectedOptions[0]?.text || "Meal";
      if (editingId) {
        await request(
          `/admin/meal-planner/recommendations/${editingId}`,
          "PUT",
          { ...basePayload, dayOfWeek: selectedDays[0] },
        );
      } else {
        await request(
          "/admin/meal-planner/recommendations/bulk",
          "POST",
          selectedDays.map((dayOfWeek) => ({ ...basePayload, dayOfWeek })),
        );
      }
      closeModal();
      await alerts.success(
        wasEditing ? "Recommendation updated" : "Recommendation added",
        `${mealLabel} is saved for ${selectedDays.length} day${selectedDays.length === 1 ? "" : "s"}.`,
      );
      reloadAtScheduledRecommendations();
    } catch (error) {
      await alerts.error(error.message);
    } finally {
      saveButton.disabled = false;
    }
  });

  // --------------------------------------------------------------------------
  // Planner Meal Modal (Create/Edit)
  // --------------------------------------------------------------------------
  function setMealModal(open) {
    mealModal.classList.toggle("show", open);
    mealModal.setAttribute("aria-hidden", String(!open));
    document.body.classList.toggle("planner-modal-open", open);
  }

  function getSelectedCategoryIds() {
    return [...mealForm.querySelectorAll(".meal-category-cb:checked")].map(
      (cb) => Number(cb.value),
    );
  }

  function setSelectedCategoryIds(ids = []) {
    const idSet = new Set(ids.map(Number));
    mealForm.querySelectorAll(".meal-category-cb").forEach((cb) => {
      cb.checked = idSet.has(Number(cb.value));
    });
    const first = ids[0] || "";
    if (mealForm.elements.categoryId) {
      mealForm.elements.categoryId.value = first;
    }
  }

  const allWeightGoals = ["LOSE_WEIGHT", "MAINTAIN_HEALTH", "GAIN_WEIGHT"];

  function getSelectedWeightGoals() {
    return [...mealForm.querySelectorAll(".meal-weight-goal-cb:checked")].map(
      (cb) => cb.value,
    );
  }

  function setSelectedWeightGoals(goals = allWeightGoals) {
    const selected = new Set(goals.length ? goals : allWeightGoals);
    mealForm.querySelectorAll(".meal-weight-goal-cb").forEach((cb) => {
      cb.checked = selected.has(cb.value);
    });
  }

  mealForm?.querySelectorAll(".meal-category-cb").forEach((cb) => {
    cb.addEventListener("change", () => {
      const selected = getSelectedCategoryIds();
      const err = document.getElementById("mealCategoryError");
      if (err && selected.length > 0) err.style.display = "none";
      if (mealForm.elements.categoryId) {
        mealForm.elements.categoryId.value = selected[0] || "";
      }
    });
  });

  mealForm?.querySelectorAll(".meal-weight-goal-cb").forEach((cb) => {
    cb.addEventListener("change", () => {
      if (getSelectedWeightGoals().length > 0) {
        document
          .getElementById("mealWeightGoalError")
          ?.style?.setProperty("display", "none");
      }
    });
  });

  function openMealCreate() {
    editingMealId = null;
    mealForm.reset();
    plannerIngredients = [];
    renderPlannerIngredients();
    setSelectedCategoryIds([]);
    setSelectedWeightGoals();
    document
      .getElementById("mealCategoryError")
      ?.style?.setProperty("display", "none");
    clearImageState();
    switchImageMode("upload");
    ["calories", "proteinGrams", "carbsGrams", "fatGrams"].forEach((name) => {
      mealForm.elements[name].value = "0";
    });
    mealForm.elements.active.value = "true";
    mealModalTitle.textContent = "Create Planner Meal";
    mealSaveButton.innerHTML = '<i class="bi bi-check-lg"></i> Save Meal';
    setMealModal(true);
    mealForm.elements.nameEn.focus();
  }

  function openMealEdit(card) {
    if (!card) return;
    editingMealId = card.dataset.id;
    clearImageState();
    const fields = {
      nameEn: "nameEn",
      nameKm: "nameKm",
      categoryId: "categoryId",
      descriptionEn: "descriptionEn",
      descriptionKm: "descriptionKm",
      imageUrl: "imageUrl",
      calories: "calories",
      proteinGrams: "protein",
      carbsGrams: "carbs",
      fatGrams: "fat",
      cookingTimeMinutes: "time",
      ingredientsText: "ingredients",
      ingredientsTextKm: "ingredientsKm",
      instructionsText: "instructions",
      instructionsTextKm: "instructionsKm",
      tagsText: "tags",
      tagsTextKm: "tagsKm",
      active: "active",
    };
    Object.entries(fields).forEach(([field, attribute]) => {
      if (mealForm.elements[field]) {
        mealForm.elements[field].value = card.dataset[attribute] || "";
      }
    });
    plannerIngredients = parsePlannerIngredients(card.dataset.ingredients || "", card.dataset.ingredientsKm || "");
    renderPlannerIngredients();

    const rawCategoryIds = (
      card.dataset.categoryIds ||
      card.dataset.categoryId ||
      ""
    )
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
    setSelectedCategoryIds(rawCategoryIds);
    const rawWeightGoals = (card.dataset.weightGoals || "")
      .split(",")
      .map((goal) => goal.trim())
      .filter(Boolean);
    setSelectedWeightGoals(rawWeightGoals);
    document
      .getElementById("mealCategoryError")
      ?.style?.setProperty("display", "none");

    const currentImg = card.dataset.imageUrl;
    if (currentImg) {
      showPreview(
        currentImg,
        currentImg.split("/").pop() || "Meal Image",
        "Current image",
      );
      switchImageMode("url");
    } else {
      switchImageMode("upload");
    }

    mealModalTitle.textContent = "Edit Planner Meal";
    mealSaveButton.innerHTML = '<i class="bi bi-check-lg"></i> Save Changes';
    setMealModal(true);
  }

  function closeMealModal() {
    setMealModal(false);
    editingMealId = null;
    mealForm.reset();
    plannerIngredients = [];
    renderPlannerIngredients();
    setSelectedCategoryIds([]);
    setSelectedWeightGoals();
    document
      .getElementById("mealCategoryError")
      ?.style?.setProperty("display", "none");
    clearImageState();
  }

  mealForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (!mealForm.checkValidity()) return mealForm.reportValidity();

    const selectedCategoryIds = getSelectedCategoryIds();
    const categoryError = document.getElementById("mealCategoryError");
    if (selectedCategoryIds.length === 0) {
      if (categoryError) categoryError.style.display = "block";
      categoryError?.scrollIntoView({ behavior: "smooth", block: "nearest" });
      return;
    }
    if (categoryError) categoryError.style.display = "none";

    const selectedWeightGoals = getSelectedWeightGoals();
    const weightGoalError = document.getElementById("mealWeightGoalError");
    if (selectedWeightGoals.length === 0) {
      if (weightGoalError) weightGoalError.style.display = "block";
      weightGoalError?.scrollIntoView({ behavior: "smooth", block: "nearest" });
      return;
    }
    if (weightGoalError) weightGoalError.style.display = "none";

    const ingredientText = ingredientTextPayload();
    if (!plannerIngredients.length) {
      await alerts.error("Add at least one ingredient to this planner meal.");
      return;
    }
    mealForm.elements.ingredientsText.value = ingredientText.english;
    mealForm.elements.ingredientsTextKm.value = ingredientText.khmer;
    const data = Object.fromEntries(new FormData(mealForm).entries());
    let finalImageUrl = (data.imageUrl || "").trim();

    mealSaveButton.disabled = true;
    const originalSaveText = mealSaveButton.innerHTML;

    try {
      // If a local image was picked to upload, upload it first
      if (pendingImageFile) {
        mealSaveButton.innerHTML =
          '<i class="bi bi-cloud-arrow-up"></i> Uploading Image...';
        finalImageUrl = await uploadImageFile(pendingImageFile);
      }

      mealSaveButton.innerHTML =
        '<i class="bi bi-hourglass-split"></i> Saving Meal...';

      const payload = {
        nameEn: (data.nameEn || "").trim(),
        nameKm: (data.nameKm || "").trim(),
        categoryId: selectedCategoryIds[0],
        categoryIds: selectedCategoryIds,
        weightGoals: selectedWeightGoals,
        descriptionEn: (data.descriptionEn || "").trim(),
        descriptionKm: (data.descriptionKm || "").trim(),
        imageUrl: finalImageUrl || null,
        calories: Number(data.calories || 0),
        proteinGrams: Number(data.proteinGrams || 0),
        carbsGrams: Number(data.carbsGrams || 0),
        fatGrams: Number(data.fatGrams || 0),
        cookingTimeMinutes: data.cookingTimeMinutes
          ? Number(data.cookingTimeMinutes)
          : null,
        ingredientsText: (data.ingredientsText || "").trim(),
        ingredientsTextKm: (data.ingredientsTextKm || "").trim(),
        instructionsText: (data.instructionsText || "").trim(),
        instructionsTextKm: (data.instructionsTextKm || "").trim(),
        tagsText: (data.tagsText || "").trim(),
        tagsTextKm: (data.tagsTextKm || "").trim(),
        active: data.active === "true",
      };

      const wasEditing = Boolean(editingMealId);
      const savedMeal = await request(
        editingMealId
          ? `/admin/meal-planner/meals/${editingMealId}`
          : "/admin/meal-planner/meals",
        wasEditing ? "PUT" : "POST",
        payload,
      );
      closeMealModal();
      await alerts.success(
        wasEditing ? "Planner meal updated" : "Planner meal created",
        wasEditing
          ? "Your changes have been saved."
          : "The meal is now available for all seven days.",
      );
      if (!wasEditing && savedMeal.active) {
        reloadAtScheduledRecommendations();
      } else {
        window.location.reload();
      }
    } catch (error) {
      await alerts.error(error.message);
    } finally {
      mealSaveButton.disabled = false;
      mealSaveButton.innerHTML = originalSaveText;
    }
  });

  ingredientSearchInput?.addEventListener("input", () => {
    window.clearTimeout(ingredientSearchTimer);
    ingredientSearchTimer = window.setTimeout(() => searchPlannerIngredients(ingredientSearchInput.value), 200);
  });
  ingredientSearchResults?.addEventListener("click", (event) => {
    const button = event.target.closest("[data-ingredient-id]");
    if (!button) return;
    const ingredient = ingredientMatches.find(item => String(item.ingredientId) === button.dataset.ingredientId);
    if (!ingredient || plannerIngredients.some(item => item.id === ingredient.ingredientId)) return;
    plannerIngredients.push({ id: ingredient.ingredientId, name: ingredient.ingredientName, quantity: "", unit: ingredient.defaultUnit || "", nameKm: ingredient.ingredientNameKm || "", type: ingredient.ingredientType || "", defaultUnit: ingredient.defaultUnit || "" });
    ingredientSearchInput.value = "";
    ingredientMatches = [];
    ingredientSearchResults.innerHTML = "";
    renderPlannerIngredients();
    ingredientSearchInput.focus();
  });
  selectedPlannerIngredients?.addEventListener("click", (event) => {
    const button = event.target.closest("[data-remove-index]");
    if (!button) return;
    plannerIngredients.splice(Number(button.dataset.removeIndex), 1);
    renderPlannerIngredients();
  });

  // --------------------------------------------------------------------------
  // Event Listeners
  // --------------------------------------------------------------------------
  // Recommendation Rows (Edit & Delete)
  rowsBox?.addEventListener("click", async (event) => {
    const button = event.target.closest("button[data-action]");
    if (!button) return;
    const row = button.closest("tr[data-id]");
    if (button.dataset.action === "edit-meal") {
      const card = mealLibrary?.querySelector(
        `.planner-meal-card[data-id="${row.dataset.mealId}"]`,
      );
      return openMealEdit(card);
    }
    if (button.dataset.action === "edit") return openEdit(row);

    const confirmed = await alerts.confirmDelete({
      title: "Delete planner meal?",
      text: `"${row.dataset.meal}" and all of its saved meal-plan entries will be permanently deleted from the database.`,
      confirmButtonText: "Delete",
    });
    if (!confirmed) return;

    button.disabled = true;
    try {
      const result = await request(
        `/admin/meal-planner/recommendations/${row.dataset.id}`,
        "DELETE",
      );
      await alerts.success(
        "Planner meal deleted",
        result.message,
        "Deleted!",
        `"${row.dataset.meal}" has been permanently removed.`,
      );
      reloadAtScheduledRecommendations();
    } catch (error) {
      await alerts.error(error.message);
      button.disabled = false;
    }
  });

  plannerCategory?.addEventListener("change", () => filterPlannerMeals());

  // Schedule Board Click (Edit & Quick-Add)
  board?.addEventListener("click", (event) => {
    const editBtn = event.target.closest("[data-edit-id]");
    if (editBtn) {
      const row = rowsBox?.querySelector(
        `tr[data-id="${editBtn.dataset.editId}"]`,
      );
      return openEdit(row);
    }

    const addBtn = event.target.closest("[data-schedule-day]");
    if (addBtn) {
      return openCreate(addBtn.dataset.scheduleDay);
    }
  });

  // Planner Meal Library Card Actions (Edit & Schedule)
  mealLibrary?.addEventListener("click", async (event) => {
    const button = event.target.closest("button[data-action]");
    if (!button) return;
    const card = button.closest(".planner-meal-card");
    if (button.dataset.action === "edit-meal") return openMealEdit(card);
    if (button.dataset.action === "delete-meal") {
      const confirmed = await alerts.confirmDelete({
        title: "Delete planner meal?",
        text: `"${card.dataset.nameEn}" and its saved meal-plan entries will be permanently deleted from the database.`,
        confirmButtonText: "Delete",
      });
      if (!confirmed) return;

      button.disabled = true;
      try {
        const result = await request(
          `/admin/meal-planner/meals/${card.dataset.id}`,
          "DELETE",
        );
        await alerts.success(
          "Planner meal deleted",
          result.message,
        );
        window.location.reload();
      } catch (error) {
        await alerts.error(error.message);
        button.disabled = false;
      }
      return;
    }
    if (button.dataset.action === "schedule-meal") {
      openScheduleForMeal({
        id: card.dataset.id,
        name: card.dataset.nameEn,
        categoryId: card.dataset.categoryId,
      });
    }
  });

  // Image Upload / URL Tab Switching
  tabUploadImage?.addEventListener("click", () => switchImageMode("upload"));
  tabUrlImage?.addEventListener("click", () => switchImageMode("url"));

  // Dropzone File Select & Drag-and-Drop
  mealImageDropzone?.addEventListener("click", () => {
    mealImageFileInput?.click();
  });

  mealImageDropzone?.addEventListener("dragover", (e) => {
    e.preventDefault();
    mealImageDropzone.classList.add("dragover");
  });

  mealImageDropzone?.addEventListener("dragleave", () => {
    mealImageDropzone.classList.remove("dragover");
  });

  mealImageDropzone?.addEventListener("drop", (e) => {
    e.preventDefault();
    mealImageDropzone.classList.remove("dragover");
    const file = e.dataTransfer?.files?.[0];
    if (file && file.type.startsWith("image/")) {
      handleImageFile(file);
    }
  });

  mealImageFileInput?.addEventListener("change", () => {
    const file = mealImageFileInput.files?.[0];
    if (file) {
      handleImageFile(file);
    }
  });

  function handleImageFile(file) {
    if (file.size > 5 * 1024 * 1024) {
      alerts.error("Image too large. Please select an image under 5MB.");
      return;
    }
    pendingImageFile = file;
    if (previewObjectUrl) URL.revokeObjectURL(previewObjectUrl);
    previewObjectUrl = URL.createObjectURL(file);
    showPreview(
      previewObjectUrl,
      file.name,
      `${Math.round(file.size / 1024)} KB · Ready to upload`,
    );
    if (mealImageUrlInput) mealImageUrlInput.value = "";
  }

  // URL Input Live Preview
  mealImageUrlInput?.addEventListener("input", () => {
    const url = (mealImageUrlInput.value || "").trim();
    if (url) {
      pendingImageFile = null;
      if (mealImageFileInput) mealImageFileInput.value = "";
      showPreview(
        url,
        url.split("/").pop() || "Web Image",
        "External URL preview",
      );
    } else if (!pendingImageFile) {
      showPreview(null);
    }
  });

  // Clear Image Button
  btnClearMealImage?.addEventListener("click", clearImageState);

  // Library Filtering
  librarySearch?.addEventListener("input", applyLibraryFilters);
  libraryStatusFilter?.addEventListener("change", applyLibraryFilters);

  // Table Filtering
  search?.addEventListener("input", applyTableFilters);
  dayFilter?.addEventListener("change", applyTableFilters);
  slotFilter?.addEventListener("change", applyTableFilters);
  statusFilter?.addEventListener("change", applyTableFilters);
  clearFiltersBtn?.addEventListener("click", clearTableFilters);

  document.getElementById("backfillPlannerIngredients")?.addEventListener("click", async (event) => {
    const button = event.currentTarget;
    const confirmed = await alerts.confirmDelete({
      title: "Generate missing ingredients?",
      text: "Only planner meals without ingredients will be sent to Gemini. NVIDIA is used automatically if Gemini fails.",
      confirmButtonText: "Generate",
    });
    if (!confirmed) return;
    button.disabled = true;
    const label = button.innerHTML;
    button.innerHTML = '<i class="bi bi-hourglass-split"></i> Generating...';
    try {
      const result = await request("/admin/meal-planner/meals/backfill-ingredients", "POST");
      const failed = result.failed?.length ? ` ${result.failed.length} meals could not be generated.` : "";
      await alerts.success("Ingredient generation complete", `${result.updatedCount} meals updated; ${result.skipped} already had ingredients.${failed}`);
      window.location.reload();
    } catch (error) {
      await alerts.error(error.message);
      button.disabled = false;
      button.innerHTML = label;
    }
  });

  document.getElementById("normalizePlannerIngredients")?.addEventListener("click", async (event) => {
    const button = event.currentTarget;
    const confirmed = await alerts.confirmDelete({
      title: "Organize all planner ingredients?",
      text: "Combined ingredient text will be split into individual ingredients, linked to the ingredient catalog, and saved in a structured format.",
      confirmButtonText: "Organize all",
    });
    if (!confirmed) return;
    button.disabled = true;
    const label = button.innerHTML;
    button.innerHTML = '<i class="bi bi-hourglass-split"></i> Organizing...';
    try {
      const result = await request("/admin/meal-planner/meals/normalize-ingredients", "POST");
      await alerts.success("Ingredients organized", `${result.mealsUpdated} meals updated, ${result.ingredientRows} ingredient links saved, and ${result.ingredientsCreated} catalog ingredients created.`);
      window.location.reload();
    } catch (error) {
      await alerts.error(error.message);
      button.disabled = false;
      button.innerHTML = label;
    }
  });

  // Modals Open/Close
  document
    .getElementById("openRecommendationModal")
    ?.addEventListener("click", () => openCreate());
  document
    .getElementById("closeRecommendationModal")
    ?.addEventListener("click", closeModal);
  document
    .getElementById("cancelRecommendationModal")
    ?.addEventListener("click", closeModal);
  modal?.addEventListener("click", (event) => {
    if (event.target === modal) closeModal();
  });

  document
    .getElementById("openPlannerMealModal")
    ?.addEventListener("click", openMealCreate);
  document
    .getElementById("createFirstPlannerMeal")
    ?.addEventListener("click", openMealCreate);
  document
    .getElementById("closePlannerMealModal")
    ?.addEventListener("click", closeMealModal);
  document
    .getElementById("cancelPlannerMealModal")
    ?.addEventListener("click", closeMealModal);
  mealModal?.addEventListener("click", (event) => {
    if (event.target === mealModal) closeMealModal();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      if (modal?.classList.contains("show")) closeModal();
      if (mealModal?.classList.contains("show")) closeMealModal();
    }
  });

  // Initialize UI
  renderBoard();
  applyLibraryFilters();
})();
