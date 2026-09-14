(() => {
    const form = document.getElementById('settingsForm');
    const save = document.getElementById('saveSettings');
    const reset = document.getElementById('resetSettings');
    if (!form || !save) return;

    const url = new URL(window.location.href);
    if (url.searchParams.get('saved') === 'true') {
        if (window.Swal) {
            Swal.fire({ icon: 'success', title: 'Settings saved', text: 'Preferences saved successfully.', timer: 1700, showConfirmButton: false });
        }
        url.searchParams.delete('saved');
        window.history.replaceState({}, document.title, `${url.pathname}${url.search}${url.hash}`);
    }

    const token = document.querySelector('meta[name="_csrf"]')?.content;
    const header = document.querySelector('meta[name="_csrf_header"]')?.content;

    const initial = {
        languageCode: form.languageCode ? form.languageCode.value : 'en',
        theme: form.theme ? form.theme.value : 'system',
        emailNotifications: form.emailNotifications ? form.emailNotifications.checked : true,
        pushNotifications: form.pushNotifications ? form.pushNotifications.checked : true
    };

    const restore = () => {
        if (form.languageCode) form.languageCode.value = initial.languageCode;
        if (form.theme) form.theme.value = initial.theme;
        if (form.emailNotifications) form.emailNotifications.checked = initial.emailNotifications;
        if (form.pushNotifications) form.pushNotifications.checked = initial.pushNotifications;
        window.adminTheme?.apply(initial.theme, false);
    };

    form.theme?.addEventListener('change', () => {
        window.adminTheme?.apply(form.theme.value, false);
    });

    reset?.addEventListener('click', async () => {
        if (window.Swal) {
            const result = await Swal.fire({
                icon: 'question',
                title: 'Reset unsaved changes?',
                showCancelButton: true,
                confirmButtonText: 'Reset',
                confirmButtonColor: '#078f4a'
            });
            if (result.isConfirmed) {
                restore();
                Swal.fire({ icon: 'success', title: 'Changes reset', timer: 1100, showConfirmButton: false });
            }
        } else if (window.confirm('Reset unsaved changes?')) {
            restore();
        }
    });

    form.addEventListener('submit', async (event) => {
        event.preventDefault();
        save.disabled = true;

        const data = new FormData();
        data.set('languageCode', form.languageCode ? form.languageCode.value : 'en');
        data.set('theme', form.theme ? form.theme.value : 'system');
        data.set('emailNotifications', form.emailNotifications ? form.emailNotifications.checked : true);
        data.set('pushNotifications', form.pushNotifications ? form.pushNotifications.checked : true);

        try {
            const headers = { Accept: 'application/json' };
            if (token && header) headers[header] = token;

            const response = await fetch(form.action, {
                method: 'POST',
                headers,
                body: data
            });

            const result = await response.json().catch(() => ({}));
            if (!response.ok) {
                throw new Error(result.message || 'Your preferences could not be saved.');
            }

            Object.assign(initial, {
                languageCode: form.languageCode ? form.languageCode.value : 'en',
                theme: form.theme ? form.theme.value : 'system',
                emailNotifications: form.emailNotifications ? form.emailNotifications.checked : true,
                pushNotifications: form.pushNotifications ? form.pushNotifications.checked : true
            });

            window.adminTheme?.apply(initial.theme, false);

            const lastUpdatedEl = document.getElementById('lastUpdated');
            if (lastUpdatedEl && result.updatedAt) {
                lastUpdatedEl.textContent = `Last saved ${new Intl.DateTimeFormat(undefined, {
                    day: '2-digit',
                    month: 'short',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }).format(new Date(result.updatedAt))}`;
            }

            if (window.Swal) {
                Swal.fire({
                    icon: 'success',
                    title: 'Settings saved',
                    text: result.message || 'Preferences saved successfully.',
                    timer: 1700,
                    showConfirmButton: false
                });
            } else {
                alert('Settings saved.');
            }
        } catch (error) {
            if (window.Swal) {
                Swal.fire({
                    icon: 'error',
                    title: 'Save failed',
                    text: error.message,
                    confirmButtonColor: '#078f4a'
                });
            } else {
                alert(`Save failed: ${error.message}`);
            }
        } finally {
            save.disabled = false;
        }
    });
})();
