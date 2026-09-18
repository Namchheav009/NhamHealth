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
    if (plannerPreviewMeta) plannerPreviewMeta.textContent = meta || "Ready to save";
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
      const scale = Math.min(1, maxDimension / Math.max(image.naturalWidth, image.naturalHeight));
      const canvas = document.createElement("canvas");
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
      canvas.getContext("2d").drawImage(image, 0, 0, canvas.width, canvas.height);
      const blob = await new Promise(resolve => canvas.toBlob(resolve, "image/webp", 0.82));
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
    if (!response.ok) throw new Error(body.message || "Unable to upload meal image.");
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
      const matches = option.dataset.categoryId === categoryId;
      option.hidden = !matches;
      option.disabled = !matches;
    });
    if (plannerMeal) {
      plannerMeal.disabled = !categoryId;
      plannerMeal.value = selectedMealId && plannerMeal.querySelector(
        `option[value="${selectedMealId}"]:not([disabled])`,
      ) ? selectedMealId : "";
    }
  }

  function openCreate(prefillDay) {
    editingId = null;
    form.reset();
    filterPlannerMeals();
    form.elements.dayOfWeek.value =
      prefillDay || days[(new Date().getDay() + 6) % 7];
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
    form.elements.dayOfWeek.value = row.dataset.day;
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
    const payload = {
      plannerMealId: Number(data.plannerMealId),
      dayOfWeek: data.dayOfWeek,
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
      await request(
        editingId
          ? `/admin/meal-planner/recommendations/${editingId}`
          : "/admin/meal-planner/recommendations",
        editingId ? "PUT" : "POST",
        payload,
      );
      closeModal();
      await alerts.success(
        wasEditing ? "Recommendation updated" : "Recommendation added",
        `${mealLabel} is saved for the weekly planner.`,
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

  function openMealCreate() {
    editingMealId = null;
    mealForm.reset();
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
      mealForm.elements[field].value = card.dataset[attribute] || "";
    });

    const currentImg = card.dataset.imageUrl;
    if (currentImg) {
      showPreview(currentImg, currentImg.split("/").pop() || "Meal Image", "Current image");
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
    clearImageState();
  }

  mealForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (!mealForm.checkValidity()) return mealForm.reportValidity();
    const data = Object.fromEntries(new FormData(mealForm).entries());
    let finalImageUrl = (data.imageUrl || "").trim();

    mealSaveButton.disabled = true;
    const originalSaveText = mealSaveButton.innerHTML;

    try {
      // If a local image was picked to upload, upload it first
      if (pendingImageFile) {
        mealSaveButton.innerHTML = '<i class="bi bi-cloud-arrow-up"></i> Uploading Image...';
        finalImageUrl = await uploadImageFile(pendingImageFile);
      }

      mealSaveButton.innerHTML = '<i class="bi bi-hourglass-split"></i> Saving Meal...';

      const payload = {
        nameEn: (data.nameEn || "").trim(),
        nameKm: (data.nameKm || "").trim(),
        categoryId: Number(data.categoryId),
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
      title: "Delete recommendation?",
      text: `"${row.dataset.meal}" will be removed from ${titleCase(row.dataset.day)} ${titleCase(row.dataset.slot)}.`,
      confirmButtonText: "Delete",
    });
    if (!confirmed) return;

    button.disabled = true;
    try {
      await request(
        `/admin/meal-planner/recommendations/${row.dataset.id}`,
        "DELETE",
      );
      await alerts.success(
        "Recommendation deleted",
        "The meal was removed from the weekly schedule.",
        "Deleted!",
        `Recommendation for "${row.dataset.meal}" has been removed.`,
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
  mealLibrary?.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-action]");
    if (!button) return;
    const card = button.closest(".planner-meal-card");
    if (button.dataset.action === "edit-meal") return openMealEdit(card);
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
    showPreview(previewObjectUrl, file.name, `${Math.round(file.size / 1024)} KB · Ready to upload`);
    if (mealImageUrlInput) mealImageUrlInput.value = "";
  }

  // URL Input Live Preview
  mealImageUrlInput?.addEventListener("input", () => {
    const url = (mealImageUrlInput.value || "").trim();
    if (url) {
      pendingImageFile = null;
      if (mealImageFileInput) mealImageFileInput.value = "";
      showPreview(url, url.split("/").pop() || "Web Image", "External URL preview");
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
